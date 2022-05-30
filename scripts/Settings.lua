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

local function getRaw(setting, layers)
  return PowerSettings.getRaw("mod.Switcheroo." .. setting)
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
Replacement_Advanced = PowerSettings.shared.bool {
  name = "Use advanced settings",
  desc = "Use the advanced settings in this section",
  id = "replacement.advanced",
  order = 0,
  default = false,
  visibleIf = function() return isAdvanced() or getRaw("replacement.advanced") end,
  refreshOnChange = true
}

--#region Replacement settings (simple)

Replacement_SimpleMode = PowerSettings.shared.enum {
  name = "Replace mode",
  desc = "Whether to replace existing items, generate new items, or both",
  id = "replacement.simpleMode",
  order = 1,
  visibleIf = function() return not get("replacement.advanced") end,
  enum = SwEnum.ReplaceMode,
  default = SwEnum.ReplaceMode.EVERYTHING
}

Replacement_SimpleChance = PowerSettings.shared.percent {
  name = "Replace chance",
  desc = "Chance to replace items in selected inventory slots",
  id = "replacement.simpleChance",
  order = 2,
  visibleIf = function() return not get("replacement.advanced") end,
  default = 1,
  step = 0.05,
  editAsString = true
}

--#endregion Replacement settings (simple)

--#region Replacement settings (advanced)

Replacement_AdvancedEmptyChance = PowerSettings.shared.percent {
  name = "Empty slot fill chance",
  desc = "The chance an empty slot is selected and filled.",
  id = "replacement.advancedEmptyChance",
  order = 1,
  visibleIf = function() return get("replacement.advanced") end,
  default = 1,
  step = 0.05,
  editAsString = true
}

Replacement_AdvancedEmptyMinSlots = PowerSettings.shared.number {
  name = "Minimum empty slots",
  desc = "The number of empty slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedEmptyMinSlots",
  order = 2,
  visibleIf = function() return get("replacement.advanced") end,
  default = 0,
  minimum = 0,
  upperBound = function()
    return get("replacement.advancedMaxSlots") - get("replacement.advancedFullMinSlots")
  end
}

Replacement_AdvancedFullSelectChance = PowerSettings.shared.percent {
  name = "Full slot selection chance",
  desc = "The chance a filled slot is selected and emptied.",
  id = "replacement.advancedFullSelectChance",
  order = 3,
  visibleIf = function() return get("replacement.advanced") end,
  default = 1,
  step = 0.05,
  editAsString = true
}

Replacement_AdvancedFullReplaceChance = PowerSettings.shared.percent {
  name = "Selected slot replacement chance",
  desc = "The chance a selected (filled) slot is replaced.",
  id = "replacement.advancedFullReplaceChance",
  order = 4,
  visibleIf = function() return get("replacement.advanced") end,
  default = 1,
  step = 0.05,
  editAsString = true
}

Replacement_AdvancedFullMinSlots = PowerSettings.shared.number {
  name = "Minimum full slots",
  desc = "The number of full slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedFullMinSlots",
  order = 5,
  visibleIf = function() return get("replacement.advanced") end,
  default = 0,
  minimum = 0,
  upperBound = function()
    return get("replacement.advancedMaxSlots") - get("replacement.advancedEmptyMinSlots")
  end
}

Replacement_AdvancedMinSlots = PowerSettings.shared.number {
  name = "Minimum total slots",
  desc = "The number of slots that must be picked, if it's more than the two individual minimums.",
  id = "replacement.advancedMinSlots",
  order = 6,
  visibleIf = function() return get("replacement.advanced") end,
  default = 0,
  minimum = 0,
  upperBound = "replacement.advancedMaxSlots"
}

Replacement_AdvancedMaxSlots = PowerSettings.shared.number {
  name = "Maximum slots",
  desc = "The highest number of slots that must be picked.",
  id = "replacement.advancedMaxSlots",
  order = 7,
  visibleIf = function() return get("replacement.advanced") end,
  default = 20,
  lowerBound = function()
    return math.max(get("replacement.advancedFullMinSlots") + get("replacement.advancedEmptyMinSlots"), get("replacement.advancedMinSlots"), 1)
  end,
  format = maxSlotsFormat
}

--#endregion Replacement settings (advanced)

--#endregion Replacement settings

AllowedFloors = PowerSettings.shared.bitflag {
  name = "Allowed floors",
  desc = "The floors on which the mod can activate.",
  id = "allowedFloors",
  order = 2,
  default = SwEnum.FloorPresets.ALL_FLOORS,
  flags = SwEnum.AllowedFloors,
  presets = SwEnum.FloorPresets
}

SellItems = PowerSettings.shared.percent {
  name = "Sell items",
  desc = "Price for which to sell removed items.",
  id = "sellItems",
  order = 3,
  step = 0.05,
  editAsString = true,
  format = sellPrice
}

Guarantees = PowerSettings.shared.bool {
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
  name = "Use advanced options",
  desc = "Show and use advanced options in this section.",
  id = "dontGive.advanced",
  order = 7,
  default = false,
  visibleIf = function() return isAdvanced() or getRaw("dontGive.advanced") end,
  refreshOnChange = true
}

--#region Don't give advanced
DontGive_Components = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be given.",
  id = "dontGive.components",
  order = 8,
  visibleIf = function() return get("dontGive.advanced") end,
  default = {},
  itemDefault = "item"
}

DontGive_Items = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be given.",
  id = "dontGive.items",
  order = 9,
  visibleIf = function() return get("dontGive.advanced") end,
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
  name = "Use advanced options",
  desc = "Show and use the advanced options in this section.",
  id = "dontTake.advanced",
  order = 5,
  default = false,
  visibleIf = function() return isAdvanced() or getRaw("dontTake.advanced") end,
  refreshOnChange = true
}

--#region Don't take advanced
DontTake_UnlessGivenLabel = PowerSettings.entitySchema.label {
  name = "Items below can be taken if, and only if, given by the mod.",
  id = "dontTake.unlessGivenLabel",
  order = 6,
  visibleIf = function() return get("dontTake.advanced") end
}

DontTake_ItemsUnlessGiven = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be taken (unless given).",
  id = "dontTake.itemsUnlessGiven",
  order = 7,
  visibleIf = function() return get("dontTake.advanced") end,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

DontTake_ComponentsUnlessGiven = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be taken (unless given).",
  id = "dontTake.componentsUnlessGiven",
  order = 8,
  visibleIf = function() return get("dontTake.advanced") end,
  default = {},
  itemDefault = "item"
}

DontTake_AlwaysLabel = PowerSettings.entitySchema.label {
  name = "Items below cannot be taken by the mod at all.",
  id = "dontTake.alwaysLabel",
  order = 9,
  visibleIf = function() return get("dontTake.advanced") end
}

DontTake_Items = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be taken.",
  id = "dontTake.items",
  order = 10,
  visibleIf = function() return get("dontTake.advanced") end,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

DontTake_Components = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be taken.",
  id = "dontTake.components",
  order = 11,
  visibleIf = function() return get("dontTake.advanced") end,
  default = {},
  itemDefault = "item"
}
--#endregion Don't take (advanced)

--#endregion Don't take items...

--#region Advanced

Advanced = PowerSettings.shared.bool {
  name = "Use advanced settings",
  desc = "Show and use advanced settings in the main section.",
  id = "advanced",
  order = 7,
  default = false,
  visibleIf = function() return isAdvanced() or getRaw("advanced") end,
  refreshOnChange = true
}

Slots = PowerSettings.group {
  name = "Slot settings",
  desc = "Settings that modify slots.",
  id = "slots",
  order = 8,
  visibleIf = function() return get("advanced") end
}

--#region Slot settings

Slots_Allowed = PowerSettings.shared.bitflag {
  name = "Allowed slots",
  desc = "Which slots can the mod alter?",
  id = "slots.allowed",
  order = 0,
  visibleIf = function() return get("advanced") end,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.ALL_SLOTS
}

Slots_Unlocked = PowerSettings.shared.bitflag {
  name = "Unlocked slots",
  desc = "Which slots can the mod ignore item bans within?",
  id = "slots.unlocked",
  order = 1,
  visibleIf = function() return get("advanced") end,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.NO_SLOTS
}

Slots_OneTime = PowerSettings.shared.bitflag {
  name = "One-time slots",
  desc = "Which slots can the mod only alter once?",
  id = "slots.oneTime",
  order = 2,
  visibleIf = function() return get("advanced") end,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.NO_SLOTS
}

--#endregion Slot settings

Charms = PowerSettings.group {
  name = "Charms settings",
  desc = "Settings related to the Misc (Charms) slots",
  id = "charms",
  order = 9,
  visibleIf = function() return get("advanced") end
}

--#region Charms settings

Charms_Algorithm = PowerSettings.shared.enum {
  name = "Algorithm used",
  desc = "Which charms algorithm should be used?",
  id = "charms.algorithm",
  order = 0,
  visibleIf = function() return get("advanced") end,
  enum = SwEnum.CharmsAlgorithm,
  default = SwEnum.CharmsAlgorithm.DICE_BASED,
  refreshOnChange = true
}

--#region Charms algorithm settings

Charms_MaxAdd = PowerSettings.shared.number {
  name = "Maximum added charms",
  desc = "How many charms can the mod add per floor?",
  id = "charms.maxAdd",
  order = 0,
  minimum = 0,
  default = 1,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.ADD_ONE
  end
}

Charms_MaxTotal = PowerSettings.shared.number {
  name = "Maximum total charms",
  desc = "How many charms can you have before the mod stops adding?",
  id = "charms.maxTotal",
  order = 1,
  minimum = 0,
  default = 5,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.ADD_ONE
  end
}

Charms_DiceCount = PowerSettings.shared.number {
  name = "Dice to roll",
  desc = "Dice to roll for charm counts.",
  id = "charms.diceCount",
  order = 0,
  lowerBound = function()
    return math.abs(get("charms.diceDrop")) + 1
  end,
  maximum = 10,
  default = 3,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.DICE_BASED
  end
}

Charms_DiceSides = PowerSettings.shared.number {
  name = "Sides on dice",
  desc = "Sides on the dice to roll for charm counts.",
  id = "charms.diceSides",
  order = 1,
  minimum = 2,
  maximum = 10,
  default = 4,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.DICE_BASED
  end
}

Charms_DiceDrop = PowerSettings.shared.number {
  name = "Dice to drop",
  desc = "Drop some rolled dice, either the highest or lowest.",
  id = "charms.diceDrop",
  order = 2,
  lowerBound = function()
    return -get("charms.diceCount") + 1
  end,
  upperBound = function()
    return get("charms.diceCount") - 1
  end,
  default = 0,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.DICE_BASED
  end
}

Charms_DiceAddStatic = PowerSettings.shared.number {
  name = "Plus",
  desc = "Add a static number of charms to the roll.",
  id = "charms.diceAddStatic",
  order = 3,
  default = 0,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.DICE_BASED
  end
}

Charms_DiceAddPerFloor = PowerSettings.shared.number {
  name = "Plus per floor",
  desc = "Add a static number of charms to the roll per floor.",
  id = "charms.diceAddPerFloor",
  order = 4,
  default = 0,
  step = 0.01,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.DICE_BASED
  end
}

Charms_MultiplierPerFloor = PowerSettings.shared.number {
  name = "Multiplier per floor",
  desc = "Multiply the whole thing by this amount per floor (plus one).",
  id = "charms.multiplierPerFloor",
  order = 5,
  default = 0.005,
  step = 0.005,
  editAsString = true,
  visibleIf = function()
    return get("advanced") and get("charms.algorithm") == SwEnum.CharmsAlgorithm.DICE_BASED
  end
}

--#endregion Charms algorithm settings

--#endregion Charms settings

Generator = PowerSettings.shared.enum {
  name = "Generator type",
  desc = "Which generator should be used for the mod?",
  id = "generator",
  order = 10,
  visibleIf = function() return get("advanced") end,
  enum = SwEnum.Generators,
  default = SwEnum.Generators.CONJURER
}

--#endregion Advanced

--#endregion
return { get = get }
