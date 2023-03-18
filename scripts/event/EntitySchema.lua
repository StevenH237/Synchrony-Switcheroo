local Attack    = require "necro.game.character.Attack"
local Event     = require "necro.event.Event"
local GameDLC   = require "necro.game.data.resource.GameDLC"
local Utilities = require "system.utils.Utilities"

local SwEnum     = require "Switcheroo.Enum"
local SwSettings = require "Switcheroo.Settings"

local NixLib = require "NixLib.NixLib"

local function copyToSet(table)
  local out = {}
  for i, v in ipairs(table) do
    out[v] = true
  end
  return out
end

-- These variables should save on some function calls...
local itemNamesNotGiven
local itemNamesNotTakenUnlessGiven
local itemNamesNeverTaken
local componentsNotGiven
local componentsNotGivenIfBroke = {}
local componentsNotTakenUnlessGiven
local componentsNeverTaken
local dynamicGoldBan = false

Event.entitySchemaGenerate.add("checks", { order = "components", sequence = -1 }, function()
  -- Items to not give
  itemNamesNotGiven = copyToSet(SwSettings.get("dontGive.items"))
  componentsNotGiven = copyToSet(SwSettings.get("dontGive.components"))

  if SwSettings.get("dontGive.damageUps") then
    componentsNotGiven.itemIncomingDamageMultiplier = true
    componentsNotGiven.itemIncomingDamageIncrease = true
  end

  if SwSettings.get("dontGive.goldItems") == SwEnum.DontGiveGold.BAN then
    componentsNotGiven.itemBanPoverty = true
    componentsNotGiven.itemBanKillPoverty = true
    componentsNotGiven.itemAutoCollectCurrencyOnMove = true
  elseif SwSettings.get("dontGive.goldItems") == SwEnum.DontGiveGold.DYNAMIC then
    componentsNotGivenIfBroke.itemBanPoverty = true
    componentsNotGivenIfBroke.itemBanKillPoverty = true
    componentsNotGivenIfBroke.itemAutoCollectCurrencyOnMove = true
  end

  if SwSettings.get("dontGive.moveAmplifiers") then
    componentsNotGiven.itemMoveAmplifier = true
    componentsNotGiven.quirks_leaping = true
  end

  if SwSettings.get("dontGive.visionReducers") then
    componentsNotGiven.itemLimitTileVisionRadius = true
  end

  if SwSettings.get("dontGive.rhythmIgnoringItems") then
    componentsNotGiven.consumableIgnoreRhythmTemporarily = true
  end

  -- using fake components here just so we have a marker without making an extra variable
  -- so that we don't need to make a Settings Get call every item
  -- I'll code in a special case for it in a sec
  if SwSettings.get("dontGive.magicFood") then
    componentsNotGiven.Switcheroo_magicFood = true
  end

  if SwSettings.get("dontGive.floatingItems") then
    componentsNotGiven.Switcheroo_levitation = true
  end

  if SwSettings.get("dontGive.breakableWeapons") then
    componentsNotGiven.Switcheroo_breakableWeapons = true
  end

  if SwSettings.get("dontGive.breakableShovels") then
    componentsNotGiven.Switcheroo_breakableShovels = true
  end

  -- Items to not take
  itemNamesNotTakenUnlessGiven = copyToSet(SwSettings.get("dontTake.itemsUnlessGiven"))
  itemNamesNeverTaken = copyToSet(SwSettings.get("dontTake.items"))
  componentsNotTakenUnlessGiven = copyToSet(SwSettings.get("dontTake.componentsUnlessGiven"))
  componentsNeverTaken = copyToSet(SwSettings.get("dontTake.components"))

  local NeverTake = SwEnum.DontTake.DONT_TAKE
  local TakeIfGiven = SwEnum.DontTake.TAKE_IF_GIVEN

  if SwSettings.get("dontTake.crownOfGreed") == NeverTake then
    itemNamesNeverTaken.HeadCrownOfGreed = true
  elseif SwSettings.get("dontTake.crownOfGreed") == TakeIfGiven then
    itemNamesNotTakenUnlessGiven.HeadCrownOfGreed = true
  end

  if SwSettings.get("dontTake.luckyCharm") == NeverTake then
    itemNamesNeverTaken.CharmLuck = true
  elseif SwSettings.get("dontTake.luckyCharm") == TakeIfGiven then
    itemNamesNotTakenUnlessGiven.CharmLuck = true
  end

  if SwSettings.get("dontTake.potion") == NeverTake then
    itemNamesNeverTaken.MiscPotion = true
  elseif SwSettings.get("dontTake.potion") == TakeIfGiven then
    itemNamesNotTakenUnlessGiven.MiscPotion = true
  end

  if SwSettings.get("dontTake.ringOfWonder") == NeverTake then
    itemNamesNeverTaken.RingWonder = true
  elseif SwSettings.get("dontTake.ringOfWonder") == TakeIfGiven then
    itemNamesNotTakenUnlessGiven.RingWonder = true
  end

  if SwSettings.get("dontTake.crystalShovel") == NeverTake then
    itemNamesNeverTaken.ShovelCrystal = true
  elseif SwSettings.get("dontTake.crystalShovel") == TakeIfGiven then
    itemNamesNotTakenUnlessGiven.ShovelCrystal = true
  end
end)

local function addItemComponents(entity)
  -- Should the item be exempt from giving?
  if itemNamesNotGiven[entity.name] then
    entity.Switcheroo_noGive = {}
    goto noTake
  else
    -- Are any of the components exempt from giving?
    for k, v in pairs(componentsNotGiven) do
      if entity[k] then
        entity.Switcheroo_noGive = {}
        goto noTake
      end
    end

    -- Is it magic food, and is magic food banned?
    if entity.consumableHeal and entity.consumableHeal.overheal and componentsNotGiven.Switcheroo_magicFood then
      entity.Switcheroo_noGive = {}
      goto noTake
    end

    -- Is it levitation, and is levitation banned?
    if entity.itemAttackableFlags and entity.itemAttackableFlags.remove and
        NixLib.checkFlags(entity.itemAttackableFlags.remove, Attack.Flag.TRAP) and
        componentsNotGiven.Switcheroo_levitation then
      entity.Switcheroo_noGive = {}
      goto noTake
    end

    -- Is it a breakable shovel, and are those banned?
    if entity.shovel and entity.itemConsumeOnIncomingDamage and componentsNotGiven.Switcheroo_breakableShovels then
      entity.Switcheroo_noGive = {}
      goto noTake
    end

    -- Is it a breakable weapon, and are those banned?
    if entity.weapon and entity.itemConsumeOnIncomingDamage and componentsNotGiven.Switcheroo_breakableWeapons then
      entity.Switcheroo_noGive = {}
      goto noTake
    end

    for k, v in pairs(componentsNotGivenIfBroke) do
      if entity[k] then
        entity.Switcheroo_noGiveIfBroke = {}
        goto noTake
      end
    end
  end

  entity.Switcheroo_noGive = false

  ::noTake::
  -- Should the item be exempt from taking?
  if itemNamesNeverTaken[entity.name] then
    entity.Switcheroo_noTake = {}
    goto endTake
  elseif itemNamesNotTakenUnlessGiven[entity.name] then
    entity.Switcheroo_noTake = { unlessGiven = true }
    goto endTake
  end

  for k, v in pairs(componentsNeverTaken) do
    if entity[k] then
      entity.Switcheroo_noTake = {}
      goto endTake
    end
  end

  for k, v in pairs(componentsNotTakenUnlessGiven) do
    if entity[k] then
      entity.Switcheroo_noTake = { unlessGiven = true }
      goto endTake
    end
  end

  entity.Switcheroo_noTake = false

  ::endTake::
  --
  -- Add item pool weights
  if entity.itemPoolSecret then
    -- If there's an itemPoolSecret chance, we'll use that first.
    entity.Switcheroo_itemPoolSwitcheroo = { weights = Utilities.fastCopy(entity.itemPoolSecret.weights) }
  elseif entity.itemSlot and entity.itemSlot.name == "shield" and entity.itemPoolBlackChest then
    -- Otherwise, is it a shield?
    entity.Switcheroo_itemPoolSwitcheroo = { weights = Utilities.fastCopy(entity.itemPoolBlackChest.weights) }
  end
end

local function addPlayerComponents(entity)
  entity.Switcheroo_randomizer = {}
end

local function addSoulLinkComponents(entity)
  entity.Switcheroo_soulLinkItemGen = {}
end

Event.entitySchemaLoadEntity.add("addComponents", { order = "overrides", sequence = 2 }, function(ev)
  local entity = ev.entity

  if entity.soulLinkInventory then
    addSoulLinkComponents(entity)
  elseif entity.item then
    addItemComponents(entity)
  elseif (entity.controllable and not (GameDLC.isSynchronyLoaded() and entity.Sync_possessable)) or entity.dad then
    addPlayerComponents(entity)
  end
end)
