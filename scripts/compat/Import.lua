local Enum            = require "system.utils.Enum"
local RemoteSettings  = require "necro.config.RemoteSettings"
local Settings        = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"

local SwEnum = require "Switcheroo.Enum"

local NixLib = require "NixLib.NixLib"

local imported = {}

local function importSettings()
  local serialized = SettingsStorage.getSerializedSettings(Settings.Layer.REMOTE_OVERRIDE)
  imported = {}
  for k, v in pairs(serialized) do
    if string.len(k) >= 15 and string.sub(k, 1, 15) == "mod.Switcheroo." then
      imported[k] = v
    end
  end
end

local function getSetting(name)
  local settingName = "mod.Switcheroo." .. name
  local settingValue = imported[settingName]
  return settingValue
end

local function setSetting(name, value)
  SettingsStorage.set("mod.Switcheroo." .. name, value, Settings.Layer.REMOTE_PENDING)
end

local function clearSettings(prefix, settings)
  for i, v in ipairs(settings) do
    SettingsStorage.set("mod.Switcheroo." .. prefix .. v, nil, Settings.Layer.REMOTE_PENDING)
  end
end

local enumGenType = Enum.sequence {
  UNWEIGHTED   = Enum.entry(0, {}),
  CHEST        = Enum.entry(1, { flag = "itemPoolChest" }),
  LOCKED_CHEST = Enum.entry(2, { flag = "itemPoolLockedChest" }),
  SHOP         = Enum.entry(3, { flag = "itemPoolShop" }),
  LOCKED_SHOP  = Enum.entry(4, { flag = "itemPoolLockedShop" }),
  URN          = Enum.entry(5, { flag = "itemPoolUrn" }),
  RED_CHEST    = Enum.entry(6, { flag = "itemPoolRedChest" }),
  PURPLE_CHEST = Enum.entry(7, { flag = "itemPoolPurpleChest" }),
  BLACK_CHEST  = Enum.entry(8, { flag = "itemPoolBlackChest" }),
  CONJURER     = Enum.entry(9, { flag = "itemPoolSecret" })
}

local enumSlotType = Enum.sequence {
  NO = 0,
  YES = 1,
  UNLOCKED = 2,
  ONCE = 3,
  UNLOCKED_ONCE_THEN_YES = 4,
  UNLOCKED_ONCE_THEN_NO = 5
}

local module = {}

function module.ImportV1Settings()
  importSettings()

  -- Clear all new settings first, just to be sure
  clearSettings("", {
    "advanced",
    "allowedFloors",
    "charms.algorithm",
    "charms.diceAddPerFloor",
    "charms.diceAddStatic",
    "charms.diceCount",
    "charms.diceDrop",
    "charms.diceMultiplierPerFloor",
    "charms.diceSides",
    "charms.maxAdd",
    "charms.maxTotal",
    "dontGive.advanced",
    "dontGive.bannedItems",
    "dontGive.components",
    "dontGive.damageUps",
    "dontGive.deadlyItems",
    "dontGive.goldItems",
    "dontGive.items",
    "dontGive.magicFood",
    "dontGive.moveAmplifiers",
    "dontGive.visionReducers",
    "dontTake.advanced",
    "dontTake.alwaysLabel",
    "dontTake.componentsUnlessGiven",
    "dontTake.components",
    "dontTake.crownOfGreed",
    "dontTake.items",
    "dontTake.itemsUnlessGiven",
    "dontTake.locked",
    "dontTake.luckyCharm",
    "dontTake.potion",
    "dontTake.ringOfWonder",
    "dontTake.unlessGivenLabel",
    "generator",
    -- "guarantees", -- This is skipped because it's the same name in both versions.
    "replacement.advanced",
    "replacement.advancedEmptyChance",
    "replacement.advancedEmptyMinSlots",
    "replacement.advancedFullMinSlots",
    "replacement.advancedFullReplaceChance",
    "replacement.advancedFullSelectChance",
    "replacement.advancedMaxItems",
    "replacement.advancedMaxSlots",
    "replacement.advancedMinItems",
    "replacement.advancedMinSlots",
    "replacement.simpleChance",
    "replacement.simpleMode",
    "sellItems",
    "slots.allowed",
    "slots.capacity",
    "slots.oneTime",
    "slots.reduce",
    "slots.unlocked"
  })

  -- Import "chance" group first
  local chanceEmpty = getSetting("chance.empty") or 1
  local chanceFilled = getSetting("chance.filled") or 1
  local chanceNew = getSetting("chance.new") or 1
  local chanceMin = getSetting("chance.minimum") or 0
  local chanceMax = getSetting("chance.maximum") or -1

  if chanceMax == -1 then chanceMax = 20 end
  if chanceMin > chanceMax then chanceMin, chanceMax = chanceMax, chanceMin end

  local simpleChance = false

  -- Can we represent this with simple settings?
  if (chanceEmpty == 0 or chanceFilled == 0 or chanceEmpty == chanceFilled)
      and chanceNew == 1 and chanceMin == 0
      and (chanceMax == -1 or chanceMax >= 20) then
    clearSettings("replacement.advanced", { "", "EmptyChance", "EmptyMinSlots", "FullMinSlots", "FullReplaceChance", "FullSelectChance", "MinSlots", "FullMaxSlots" })

    if chanceEmpty == 0 then
      setSetting("replacement.simpleMode", SwEnum.EXISTING)
      setSetting("replacement.simpleChance", chanceFilled)
    elseif chanceFilled == 0 then
      setSetting("replacement.simpleMode", SwEnum.EMPTY)
      setSetting("replacement.simpleChance", chanceEmpty)
    else
      setSetting("replacement.simpleMode", nil)
      setSetting("replacement.simpleChance", chanceEmpty)
    end
  else
    setSetting("replacement.advanced", true)
    -- Because of changes to how empty slot filling works, the multiplication here mimics the old behavior.
    setSetting("replacement.advancedEmptyChance", chanceEmpty * chanceNew)
    setSetting("replacement.advancedFullSelectChance", chanceFilled)
    setSetting("replacement.advancedFullReplaceChance", chanceNew)
    setSetting("replacement.advancedMinItems", 0)
    setSetting("replacement.advancedMinSlots", chanceMin)
    setSetting("replacement.advancedMaxItems", -1)
    setSetting("replacement.advancedMaxSlots", chanceMax)
  end

  -- Import "charms" group next
  setSetting("advanced", true)

  local charmsMax = getSetting("charms.max") or 5
  local charmsAdd = getSetting("charms.new") or 1

  setSetting("charms.algorithm", SwEnum.CharmsAlgorithm.ADD_ONE)
  setSetting("charms.maxTotal", charmsMax)
  setSetting("charms.maxAdd", charmsAdd)

  -- Import "components" group next
  -- First, clear the existing (new version) no-give stuff
  setSetting("dontGive.damageUps", false)
  setSetting("dontGive.magicFood", false)
  setSetting("dontGive.moveAmplifiers", false)

  -- Then, import items not given.
  local itemsNoGive = NixLib.splitToList(getSetting("components.giveItem") or "")
  local itemsNotGiven = {}

  for i, v in ipairs(itemsNoGive) do
    setSetting("dontGive.advanced", true)
    itemsNotGiven[#itemsNotGiven + 1] = v
  end

  setSetting("dontGive.items", itemsNotGiven)

  -- Then, import components not given.
  local componentsNoGive = NixLib.splitToList(getSetting("components.giveComponent") or "itemIncomingDamageIncrease itemBanInnateSpell")
  local componentsNotGiven = {}

  for i, v in ipairs(componentsNoGive) do
    if v == "Switcheroo_noGive"
        -- haha, think you're clever? :P
        -- we'll just ignore that one
        or v == "itemBanInnateSpell" then
      -- This is ignored because of legacy defaults
    elseif v == "itemIncomingDamageIncrease" or v == "itemIncomingDamageMultiplier" then
      setSetting("dontGive.damageUps", nil)
    elseif v == "itemBanPoverty" then
      setSetting("dontGive.goldItems", true)
    elseif v == "itemMoveAmplifier" then
      setSetting("dontGive.moveAmplifiers", nil)
    elseif v == "itemLimitTileVisionRadius" then
      setSetting("dontGive.visionReducers", true)
    else
      componentsNotGiven[#componentsNotGiven + 1] = v
    end
  end

  if #componentsNotGiven >= 1 then
    setSetting("dontGive.advanced", true)
    setSetting("dontGive.components", componentsNotGiven)
  end

  -- Now, clear the existing (new version) no-take stuff
  clearSettings("dontTake.", { "advanced", "componentsUnlessGiven", "components", "itemsUnlessGiven", "items", "locked" })
  setSetting("dontTake.crownOfGreed", SwEnum.DontTake.TAKE)
  setSetting("dontTake.luckyCharm", SwEnum.DontTake.TAKE)
  setSetting("dontTake.potion", SwEnum.DontTake.TAKE)
  setSetting("dontTake.ringOfWonder", SwEnum.DontTake.TAKE)

  -- Then, import items not taken.
  local itemsNoTake = NixLib.splitToList(getSetting("components.takeItem") or "MiscPotion CharmLuck RingWonder HeadCrownOfGreed")
  local itemsNotTaken = {}

  for i, v in ipairs(itemsNoTake) do
    if v == "HeadCrownOfGreed" then
      setSetting("dontTake.crownOfGreed", SwEnum.DontTake.DONT_TAKE)
    elseif v == "CharmLuck" then
      setSetting("dontTake.luckyCharm", SwEnum.DontTake.DONT_TAKE)
    elseif v == "MiscPotion" then
      setSetting("dontTake.potion", SwEnum.DontTake.DONT_TAKE)
    elseif v == "RingWonder" then
      setSetting("dontTake.ringOfWonder", SwEnum.DontTake.DONT_TAKE)
    else
      itemsNotTaken[#itemsNotTaken + 1] = v
    end
  end

  if #itemsNotTaken >= 1 then
    setSetting("dontTake.advanced", true)
    setSetting("dontTake.items", itemsNotTaken)
  end

  -- And lastly import components not taken.
  local componentsNoTake = NixLib.splitToList(getSetting("components.takeComponent") or "itemBanInnateSpell")
  local componentsNotTaken = {}

  for i, v in ipairs(componentsNoTake) do
    if v == "itemBanInnateSpell" then
      -- Do nothing because of legacy defaults.
    else
      componentsNotTaken[#componentsNotTaken + 1] = v
    end
  end

  if #componentsNotTaken >= 1 then
    setSetting("dontTake.advanced", true)
    setSetting("dontTake.components", componentsNotTaken)
  end

  -- One more thing that had its own node before for some reason?
  if getSetting("deadly") then
    setSetting("dontGive.deadlyItems", true)
  end

  -- Now we need to import the floors settings.
  local floorMask = 0
  local useFloorMask = false

  for d = 1, 5 do
    for l = 1, 4 do
      local exp = d * 4 + l
      local val = 2 ^ exp
      local stg = getSetting("floors.l" .. d .. l)

      if stg ~= nil then
        useFloorMask = true
      end

      if stg ~= false then
        floorMask = floorMask + val
      end
    end
  end

  -- Including the little extra bits
  if getSetting("floors.l55") ~= false then
    useFloorMask = true
    floorMask = floorMask + 2 ^ 24
  end

  if useFloorMask then
    setSetting("allowedFloors", floorMask)
  end

  -- The "guarantees" setting node is unchanged.
  -- "sell" became "sellItems", with no other effect.
  setSetting("sellItems", getSetting("sell"))

  -- Now the slots!
  local slotMask = 0
  local unlockMask = 0
  local onceMask = 0

  for k, v in pairs(SwEnum.SlotsBitmask) do
    if k ~= "HOLSTER" then
      local val = getSetting("slots." .. k:lower())

      if val == nil or val ~= enumSlotType.NO then
        slotMask = slotMask + v
      end

      if val == enumSlotType.UNLOCKED or val == enumSlotType.UNLOCKED_ONCE_THEN_NO then
        unlockMask = unlockMask + v
      end

      if val == enumSlotType.ONCE or val == enumSlotType.UNLOCKED_ONCE_THEN_YES or val == enumSlotType.UNLOCKED_ONCE_THEN_NO then
        onceMask = onceMask + v
      end
    end
  end

  setSetting("slots.allowed", slotMask)
  setSetting("slots.oneTime", onceMask)
  setSetting("slots.unlocked", unlockMask)
  setSetting("slots.capacity", 2)
  setSetting("slots.reduce", false)

  -- Finally, the generator type.
  local type = getSetting("type") or enumGenType.CONJURER
  setSetting("generator", enumGenType.data[type])

  -- Let's not forget to delete all the old settings!
  clearSettings("", {
    "chance.empty",
    "chance.filled",
    "chance.maximum",
    "chance.minimum",
    "chance.new",
    "charms.max",
    "charms.new",
    "components.check",
    "components.giveComponent",
    "components.giveItem",
    "components.takeComponent",
    "components.takeItem",
    "deadly",
    "floors.l11",
    "floors.l12",
    "floors.l13",
    "floors.l14",
    "floors.l21",
    "floors.l22",
    "floors.l23",
    "floors.l24",
    "floors.l31",
    "floors.l32",
    "floors.l33",
    "floors.l34",
    "floors.l41",
    "floors.l42",
    "floors.l43",
    "floors.l44",
    "floors.l51",
    "floors.l52",
    "floors.l53",
    "floors.l54",
    "floors.l55",
    -- "guarantees", -- This is skipped because it's the same name in both versions.
    "sell",
    "slots.body",
    "slots.feet",
    "slots.head",
    "slots.misc",
    "slots.ring",
    "slots.shovel",
    "slots.spell",
    "slots.torch",
    "slots.weapon",
    "type"
  })

  -- Nor should we forget to commit everything
  RemoteSettings.upload()
end

return module
