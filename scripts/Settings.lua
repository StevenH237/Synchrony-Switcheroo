--#region Imports
local GameDLC         = require "necro.game.data.resource.GameDLC"
local Menu            = require "necro.menu.Menu"
local Settings        = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"

local PowerSettings = require "PowerSettings.PowerSettings"

local SwEnum = require "Switcheroo.Enum"
--#endregion Imports

---------------
-- FUNCTIONS --
--#region------

local function get(setting)
  return PowerSettings.get("mod.Switcheroo." .. setting)
end

--#endregion

----------------
-- FORMATTERS --
--#region-------

local function sellPrice(value)
  if value == 0 then
    return "No"
  else
    return (value * 100) .. "% of purchase price (" .. (value * 200) .. "% sale price)"
  end
end

local function itemBanFormat(value)
  if value then
    return "Ban"
  else
    return "Don't ban"
  end
end

local function maxSlotsFormat(value)
  if value == 20 then
    return "(No limit)"
  else
    return value
  end
end

--#endregion

--------------
-- ENABLERS --
--#region-----

local function isAdvanced()
  return SettingsStorage.get("config.showAdvanced")
end

local function isSectionAdvanced(section, target)
  local secAdv = get(section .. ".advanced")

  if target == true then return secAdv
  elseif target == false then return not secAdv
  elseif isAdvanced() then return not secAdv
  else return false end
end

local function isAmplified()
  return GameDLC.isAmplifiedLoaded()
end

--#endregion Enablers

-------------
-- ACTIONS --
--#region----

local function setSectionAdvanced(section, target)
  SettingsStorage.set("mod.Switcheroo." .. section .. ".advanced", target, Settings.Layer.REMOTE_PENDING)
  Menu.update()
end

--#endregion

--------------
-- SETTINGS --
--#region-----

Replacement = PowerSettings.group {
  name = "Replacement mode/chances",
  desc = "Settings for what and when should be replaced",
  id = "replacement",
  order = 0
}

--#region Replacement settings

-- Hidden setting controlling advanced mode
Replacement_Advanced = PowerSettings.entitySchema.bool {
  id = "replacement.advanced",
  default = false,
  visibleIf = false,
  ignoredIf = false
}

--#region Replacement settings (simple)

Replacement_SwitchToAdvanced = PowerSettings.entitySchema.action {
  name = "Switch to advanced",
  desc = "Switch to advanced mode for these settings.",
  id = "replacement.switchToAdvanced",
  order = 0,
  visibleIf = function() return isSectionAdvanced("replacement", nil) end,
  action = function() setSectionAdvanced("replacement", true) end
}

Replacement_SimpleMode = PowerSettings.entitySchema.enum {
  name = "Replace mode",
  desc = "Whether to replace existing items, generate new items, or both",
  id = "replacement.simpleMode",
  order = 1,
  visibleIf = function() return isSectionAdvanced("replacement", false) end,
  enum = SwEnum.ReplaceMode,
  default = SwEnum.ReplaceMode.EVERYTHING
}

Replacement_SimpleChance = PowerSettings.entitySchema.percent {
  name = "Replace chance",
  desc = "Chance to replace items in selected inventory slots",
  id = "replacement.simpleChance",
  order = 2,
  visibleIf = function() return isSectionAdvanced("replacement", false) end,
  default = 1,
  step = 0.05,
  editAsString = true
}

--#endregion Replacement settings (simple)

--#region Replacement settings (advanced)

Replacement_SwitchToSimple = PowerSettings.entitySchema.action {
  name = "Switch to simple",
  desc = "Switch to simple mode for these settings.",
  id = "replacement.switchToSimple",
  order = 0,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  action = function() setSectionAdvanced("replacement", false) end
}

Replacement_AdvancedEmptyChance = PowerSettings.entitySchema.percent {
  name = "Empty slot fill chance",
  desc = "The chance an empty slot is selected and filled.",
  id = "replacement.advancedEmptyChance",
  order = 1,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  default = 1,
  step = 0.05,
  editAsString = true
}

Replacement_AdvancedEmptyMinSlots = PowerSettings.entitySchema.number {
  name = "Minimum empty slots",
  desc = "The number of empty slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedEmptyMinSlots",
  order = 2,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  default = 0,
  minimum = 0,
  upperBound = function()
    return get("replacement.advancedMaxSlots") - get("replacement.advancedFullMinSlots")
  end
}

Replacement_AdvancedFullSelectChance = PowerSettings.entitySchema.percent {
  name = "Full slot selection chance",
  desc = "The chance a filled slot is selected and emptied.",
  id = "replacement.advancedFullSelectChance",
  order = 3,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  default = 1,
  step = 0.05,
  editAsString = true
}

Replacement_AdvancedFullReplaceChance = PowerSettings.entitySchema.percent {
  name = "Selected slot replacement chance",
  desc = "The chance a selected (filled) slot is replaced.",
  id = "replacement.advancedFullReplaceChance",
  order = 4,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  default = 1,
  step = 0.05,
  editAsString = true
}

Replacement_AdvancedFullMinSlots = PowerSettings.entitySchema.number {
  name = "Minimum full slots",
  desc = "The number of full slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedFullMinSlots",
  order = 5,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  default = 0,
  minimum = 0,
  upperBound = function()
    return get("replacement.advancedMaxSlots") - get("replacement.advancedEmptyMinSlots")
  end
}

Replacement_AdvancedMaxSlots = PowerSettings.entitySchema.number {
  name = "Maximum slots",
  desc = "The highest number of slots that must be picked.",
  id = "replacement.advancedMaxSlots",
  order = 6,
  visibleIf = function() return isSectionAdvanced("replacement", true) end,
  default = 20,
  lowerBound = function()
    return get("replacement.advancedFullMinSlots") + get("replacement.advancedEmptyMinSlots")
  end,
  maximum = 20,
  format = maxSlotsFormat
}

--#endregion Replacement settings (advanced)

--#endregion Replacement settings

AllowedFloors = PowerSettings.entitySchema.bitflag {
  name = "Allowed floors",
  desc = "The floors on which the mod can activate.",
  id = "allowedFloors",
  order = 2,
  default = SwEnum.FloorPresets.ALL_FLOORS,
  flags = SwEnum.AllowedFloors,
  presets = SwEnum.FloorPresets
}

SellItems = PowerSettings.entitySchema.percent {
  name = "Sell items",
  desc = "Price for which to sell removed items.",
  id = "sellItems",
  order = 3,
  step = 0.05,
  editAsString = true,
  format = sellPrice
}

Guarantees = PowerSettings.entitySchema.bool {
  name = "Honor guaranteed transmutations",
  desc = "Whether or not transmutes/transmogs with fixed outcomes should be honored.",
  id = "guarantees",
  order = 4,
  default = true
}

DontGive = PowerSettings.group {
  name = "Don't give...",
  desc = "Categories of items that shouldn't be given by the mod.",
  id = "dontGive",
  order = 5
}

--#region Don't Give items...

DontGive_MagicFood = PowerSettings.entitySchema.bool {
  name = "Magic food",
  desc = "Whether or not magic food should be banned from the item pool.",
  id = "dontGive.magicFood",
  order = 0,
  default = true,
  format = itemBanFormat
}

DontGive_MoveAmplifiers = PowerSettings.entitySchema.bool {
  name = "Movement amplifiers",
  desc = "Whether or not movement amplifiers should be banned from the item pool.",
  id = "dontGive.moveAmplifiers",
  order = 1,
  default = true,
  format = itemBanFormat
}

DontGive_DamageUps = PowerSettings.entitySchema.bool {
  name = "Incoming-damage increasers",
  desc = "Whether or not items that increase incoming damage should be banned from the item pool.",
  id = "dontGive.damageUps",
  order = 2,
  default = true,
  format = itemBanFormat
}

DontGive_GoldItems = PowerSettings.entitySchema.bool {
  name = "Gold-related items",
  desc = "Whether or not items that affect the collection of gold should be banned from the item pool.",
  id = "dontGive.goldItems",
  order = 3,
  default = false,
  format = itemBanFormat
}

DontGive_VisionReducers = PowerSettings.entitySchema.bool {
  name = "Vision-reducing items",
  desc = "Whether or not items that reduce vision should be banned from the item pool.",
  id = "dontGive.visionReducers",
  order = 4,
  default = false,
  format = itemBanFormat
}

DontGive_DeadlyItems = PowerSettings.entitySchema.bool {
  name = "Deadly items",
  desc = "Whether or not items that are only banned as \"kill player on pickup\" should be banned from the item pool.",
  id = "dontGive.deadlyItems",
  order = 5,
  default = true,
  format = itemBanFormat
}

DontGive_BannedItems = PowerSettings.entitySchema.bool {
  name = "Banned items",
  desc = "Whether or not items normally banned for a character should be banned from the item pool.",
  id = "dontGive.bannedItems",
  order = 6,
  default = true,
  format = itemBanFormat
}

-- Hidden setting controlling advanced mode
DontGive_Advanced = PowerSettings.entitySchema.bool {
  id = "dontGive.advanced",
  default = false,
  visibleIf = false,
  ignoredIf = false
}

DontGive_ShowAdvanced = PowerSettings.entitySchema.action {
  name = "Show advanced options",
  desc = "Show the advanced options for items not being given.",
  id = "dontGive.showAdvanced",
  order = 7,
  visibleIf = function() return isSectionAdvanced("dontGive") end,
  action = function() setSectionAdvanced("dontGive", true) end
}

--#region Don't give advanced
DontGive_HideAdvancedLabel = PowerSettings.entitySchema.label {
  name = "By hiding the below advanced options, they will also be deactivated.",
  id = "dontGive.hideAdvancedLabel",
  order = 7,
  visibleIf = function() return isSectionAdvanced("dontGive", true) end
}

DontGive_HideAdvanced = PowerSettings.entitySchema.action {
  name = "Hide advanced options",
  desc = "Hide the advanced options for items not being given.",
  id = "dontGive.hideAdvanced",
  order = 8,
  visibleIf = function() return isSectionAdvanced("dontGive", true) end,
  action = function() setSectionAdvanced("dontGive", false) end
}

DontGive_Components = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be given.",
  id = "dontGive.components",
  order = 9,
  visibleIf = function() return isSectionAdvanced("dontGive", true) end,
  default = {},
  itemDefault = "item"
}

DontGive_Items = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be given.",
  id = "dontGive.items",
  order = 10,
  visibleIf = function() return isSectionAdvanced("dontGive", true) end,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}
--#endregion Don't give advanced

--#endregion Don't Give items...

DontTake = PowerSettings.group {
  name = "Don't take...",
  desc = "Items that shouldn't be taken by the mod.",
  id = "dontTake",
  order = 6
}

--#region Don't take items...

DontTake_Potion = PowerSettings.entitySchema.enum {
  name = "Potion",
  desc = "Whether or not the Potion should be taken by the mod.",
  id = "dontTake.potion",
  order = 0,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

DontTake_LuckyCharm = PowerSettings.entitySchema.enum {
  name = "Lucky Charm",
  desc = "Whether or not the Lucky Charm should be taken by the mod.",
  id = "dontTake.luckyCharm",
  order = 1,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

DontTake_CrownOfGreed = PowerSettings.entitySchema.enum {
  name = "Crown of Greed",
  desc = "Whether or not the Crown of Greed should be taken by the mod.",
  id = "dontTake.crownOfGreed",
  order = 2,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

DontTake_RingOfWonder = PowerSettings.entitySchema.enum {
  name = "Ring of Wonder",
  desc = "Whether or not the Ring of Wonder should be taken by the mod.",
  id = "dontTake.ringOfWonder",
  order = 3,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

DontTake_Locked = PowerSettings.entitySchema.enum {
  name = "Items locked to character",
  desc = "Whether or not items that have a ban on being taken from the character should be taken by the mod.",
  id = "dontTake.locked",
  order = 4,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.DONT_TAKE
}

-- Hidden setting controlling advanced mode
DontTake_Advanced = PowerSettings.entitySchema.bool {
  id = "dontTake.advanced",
  default = false,
  visibleIf = false,
  ignoredIf = false
}

DontGive_ShowAdvanced = PowerSettings.entitySchema.action {
  name = "Show advanced options",
  desc = "Show the advanced options for items not being taken.",
  id = "dontTake.showAdvanced",
  order = 5,
  visibleIf = function() return isSectionAdvanced("dontTake") end,
  action = function() setSectionAdvanced("dontTake", true) end
}

--#region Don't take advanced
DontTake_HideAdvancedLabel = PowerSettings.entitySchema.label {
  name = "By hiding the below advanced options, they will also be deactivated.",
  id = "dontTake.hideAdvancedLabel",
  order = 5,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end
}

DontTake_HideAdvanced = PowerSettings.entitySchema.action {
  name = "Hide advanced options",
  desc = "Hide the advanced options for items not being taken.",
  id = "dontTake.hideAdvanced",
  order = 6,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end,
  action = function() setSectionAdvanced("dontTake", false) end
}

DontTake_UnlessGivenLabel = PowerSettings.entitySchema.label {
  name = "Items below can be taken if, and only if, given by the mod.",
  id = "dontTake.unlessGivenLabel",
  order = 7,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end
}

DontTake_ItemsUnlessGiven = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be taken (unless given).",
  id = "dontTake.itemsUnlessGiven",
  order = 8,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

DontTake_ComponentsUnlessGiven = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be taken (unless given).",
  id = "dontTake.componentsUnlessGiven",
  order = 9,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end,
  default = {},
  itemDefault = "item"
}

DontTake_AlwaysLabel = PowerSettings.entitySchema.label {
  name = "Items below cannot be taken by the mod at all.",
  id = "dontTake.alwaysLabel",
  order = 10,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end
}

DontTake_Items = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be taken.",
  id = "dontTake.items",
  order = 11,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

DontTake_Components = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be taken.",
  id = "dontTake.components",
  order = 12,
  visibleIf = function() return isSectionAdvanced("dontTake", true) end,
  default = {},
  itemDefault = "item"
}
--#endregion Don't take (advanced)

--#endregion Don't take items...

-- Is hidden because it's accessed through an action that always turns it on.
Other = PowerSettings.group {
  name = function()
    if isSectionAdvanced("other", true) then
      return "Advanced..."
    else
      return "Advanced (inactive)..."
    end
  end,
  desc = "Other, advanced, options.",
  id = "other",
  order = 7,
  visibleIf = function()
    return isSectionAdvanced("other") or isSectionAdvanced("other", true)
  end,
  openAction = function()
    setSectionAdvanced("other", true)
  end
}

--#region Other

Other_Advanced = PowerSettings.entitySchema.bool {
  id = "other.advanced",
  default = false,
  visibleIf = false,
  ignoredIf = false
}

Other_HideAdvancedLabel = PowerSettings.entitySchema.label {
  name = "Note: Disabling these options closes this menu. Reopening this menu re-enables these options.",
  id = "other.hideAdvancedLabel",
  order = 0
}

Other_HideAdvanced = PowerSettings.entitySchema.action {
  name = "Disable advanced options",
  desc = "Disable and hide these options.",
  id = "other.hideAdvanced",
  order = 1,
  action = function()
    setSectionAdvanced("other", false)
    Menu.close()
    Menu.update()
  end
}

Other_Slots = PowerSettings.group {
  name = "Slot settings",
  desc = "Settings that modify slots.",
  id = "other.slots",
  order = 2
}

--#region Slot settings

Other_Slots_Allowed = PowerSettings.entitySchema.bitflag {
  name = "Allowed slots",
  desc = "Which slots can the mod alter?",
  id = "other.slots.allowed",
  order = 0,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.ALL_SLOTS
}

Other_Slots_Unlocked = PowerSettings.entitySchema.bitflag {
  name = "Unlocked slots",
  desc = "Which slots can the mod ignore item bans within?",
  id = "other.slots.unlocked",
  order = 0,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.ALL_SLOTS
}

Other_Slots_OneTime = PowerSettings.entitySchema.bitflag {
  name = "One-time slots",
  desc = "Which slots can the mod only alter once?",
  id = "other.slots.oneTime",
  order = 0,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.ALL_SLOTS
}

--#endregion Slot settings

Other_Charms = PowerSettings.group {
  name = "Charms settings",
  desc = "Settings related to the Misc (Charms) slots",
  id = "other.charms",
  order = 3
}

--#region Charms settings

Other_Charms_MaxAdd = PowerSettings.entitySchema.number {
  name = "Maximum added charms",
  desc = "How many charms can the mod add per floor?",
  id = "other.charms.maxAdd",
  order = 0,
  minimum = 0,
  default = 1,
  editAsString = true
}

Other_Charms_MaxTotal = PowerSettings.entitySchema.number {
  name = "Maximum total charms",
  desc = "How many charms can you have before the mod stops adding?",
  id = "other.charms.maxTotal",
  order = 1,
  minimum = 0,
  default = 5,
  editAsString = true
}

--#endregion Charms settings

Other_Generator = PowerSettings.entitySchema.enum {
  name = "Generator type",
  desc = "Which generator should be used for the mod?",
  id = "other.generator",
  order = 4,
  enum = SwEnum.Generators,
  default = SwEnum.Generators.CONJURER
}

--#endregion Other

--#endregion
return { get = get }
