local Event     = require "necro.event.Event"
local Utitilies = require "system.utils.Utilities"

local SwEnum = require "Switcheroo.Enum"
local SEDontTake = SwEnum.DontTake
local SwSettings = require "Switcheroo.Settings"

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
local componentsNotTakenUnlessGiven
local componentsNeverTaken

Event.entitySchemaGenerate.add("checks", { order = "components", sequence = -1 }, function()
  -- Items to not give
  itemNamesNotGiven = {}
  componentsNotGiven = {}

  if SwSettings.get("dontGive.advanced") then
    itemNamesNotGiven = copyToSet(SwSettings.get("dontGive.items"))
    componentsNotGiven = copyToSet(SwSettings.get("dontGive.components"))
  end

  if SwSettings.get("dontGive.damageUps") then
    componentsNotGiven.itemIncomingDamageMultiplier = true
    componentsNotGiven.itemIncomingDamageIncrease = true
  end

  if SwSettings.get("dontGive.goldItems") then
    componentsNotGiven.itemBanPoverty = true
  end

  if SwSettings.get("dontGive.moveAmplifiers") then
    componentsNotGiven.itemMoveAmplifier = true
  end

  if SwSettings.get("dontGive.visionReducers") then
    componentsNotGiven.itemLimitTileVisionRadius = true
  end

  -- Items to not take
  itemNamesNotTakenUnlessGiven = {}
  itemNamesNeverTaken = {}
  componentsNotTakenUnlessGiven = {}
  componentsNeverTaken = {}

  if SwSettings.get("dontTake.advanced") then
    itemNamesNotTakenUnlessGiven = copyToSet(SwSettings.get("dontTake.itemsUnlessGiven"))
    itemNamesNeverTaken = copyToSet(SwSettings.get("dontTake.items"))
    componentsNotTakenUnlessGiven = copyToSet(SwSettings.get("dontTake.componentsUnlessGiven"))
    componentsNeverTaken = copyToSet(SwSettings.get("dontTake.components"))
  end

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
    if entity.consumableHeal and entity.consumableHeal.overheal and SwSettings.get("dontGive.magicFood") then
      entity.Switcheroo_noGive = {}
      goto noTake
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
end

local function addPlayerComponents(entity)
  entity.Switcheroo_randomizer = {}
end

Event.entitySchemaLoadEntity.add("addComponents", { order = "overrides" }, function(ev)
  local entity = ev.entity

  if entity.item then
    addItemComponents(entity)
  elseif entity.playableCharacter then
    addPlayerComponents(entity)
  end
end)
