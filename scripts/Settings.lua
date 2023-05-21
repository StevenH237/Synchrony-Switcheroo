--#region Imports
local GameDLC         = require "necro.game.data.resource.GameDLC"
local Menu            = require "necro.menu.Menu"
local Settings        = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local StringUtilities = require "system.utils.StringUtilities"
local Utilities       = require "system.utils.Utilities"

local Text = require "Switcheroo.i18n.Text"

local PowerSettings = require "PowerSettings.PowerSettings"

local SwEnum   = require "Switcheroo.Enum"
local SwImport = require "Switcheroo.compat.Import"
--#endregion Imports

---------------
-- FUNCTIONS --
--#region------

local function get(setting)
  local val = PowerSettings.get("mod.Switcheroo." .. setting)
  -- print("Value of " .. setting .. ": " .. Utilities.inspect(val))
  return val
end

local function getRaw(setting, layers)
  return PowerSettings.getRaw("mod.Switcheroo." .. setting)
end

--#endregion

--------------
-- ENABLERS --
--#region-----

local function both(a, b)
  return function()
    return a() and b()
  end
end

local function either(a, b)
  return function()
    return a() or b()
  end
end

local function anti(a)
  return function()
    return not a()
  end
end

local function isAdvanced(exp)
  if exp == nil then exp = true end

  return function()
    return PowerSettings.get("config.showAdvanced") == exp
  end
end

local function isAmplified(exp)
  if exp == nil then exp = true end

  return function()
    return GameDLC.isAmplifiedLoaded() == exp
  end
end

local function isSynchrony(exp)
  if exp == nil then exp = true end

  return function()
    return GameDLC.isSynchronyLoaded()
  end
end

--#endregion Enablers

----------------
-- FORMATTERS --
--#region-------

local function sellPrice(value)
  if value == 0 then
    return Text.Formats.Sell.No
  else
    return Text.Formats.Sell.Yes(value * 100)
  end
end

local function itemBanFormat(value)
  if value then
    return Text.Bans.Giving.DontAllow
  else
    return Text.Bans.Giving.Allow
  end
end

local function maxItemsSlotsFormat(value)
  if value == -1 then
    return Text.Formats.NoLimit
  else
    return value
  end
end

local function itemPoolFormat(value)
  if Text.ItemPools[value] then
    if isAdvanced() then
      return Text.Formats.ItemPoolAdvanced(Text.ItemPools[value], value)
    else
      return Text.ItemPools[value]
    end
  else
    return value
  end
end

--#endregion

-------------
-- ACTIONS --
--#region----

--#endregion

-------------
-- FILTERS --
--#region----

local function itemSlotFilter(slot)
  return function(ent)
    return ent.name == "Switcheroo_NoneItem" or (ent.itemSlot and ent.itemSlot.name == slot)
  end
end

local function itemPoolComponentFilter(comp)
  for i, v in ipairs(comp.fields) do
    if v.name == "weights" and v.type == "table" then
      return true
    end
  end
  return false
end

--#endregion

--------------
-- SETTINGS --
--#region-----

PowerSettings.autoRegister()
PowerSettings.saveVersionNumber()

PowerSettings.group {
  name = "Replacement chances",
  desc = "Settings for what and when should be replaced",
  id = "replacement",
  order = 0
}

--#region Replacement settings

PowerSettings.shared.percent {
  name = "Empty slot fill chance",
  desc = "The chance an empty slot is selected and filled.",
  id = "replacement.advancedEmptyChance",
  order = 1,
  default = 1,
  step = 0.01
}

PowerSettings.shared.number {
  name = "Minimum empty slots",
  desc = "The number of empty slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedEmptyMinSlots",
  order = 2,
  visibleIf = isAdvanced(),
  default = 0,
  minimum = 0
}

PowerSettings.shared.percent {
  name = "Full slot selection chance",
  desc = "The chance a filled slot is selected and emptied.",
  id = "replacement.advancedFullSelectChance",
  order = 3,
  default = 1,
  step = 0.01
}

PowerSettings.shared.percent {
  name = "Selected slot replacement chance",
  desc = "The chance a selected (filled) slot is replaced.",
  id = "replacement.advancedFullReplaceChance",
  order = 4,
  visibleIf = isAdvanced(),
  default = 1,
  step = 0.01
}

PowerSettings.shared.number {
  name = "Minimum full slots",
  desc = "The number of full slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedFullMinSlots",
  order = 5,
  visibleIf = isAdvanced(),
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Minimum total slots",
  desc = "The number of slots that must be picked, if it's more than the two individual minimums.",
  id = "replacement.advancedMinSlots",
  order = 6,
  visibleIf = isAdvanced(),
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Maximum slots",
  desc = "The highest number of slots that must be picked.",
  id = "replacement.advancedMaxSlots",
  order = 7,
  visibleIf = isAdvanced(),
  default = -1,
  format = maxItemsSlotsFormat
}

PowerSettings.shared.number {
  name = "Minimum items given",
  desc = "The number of items that must be given, if that many slots are picked.",
  id = "replacement.advancedMinItems",
  order = 8,
  visibleIf = isAdvanced(),
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Maximum items given",
  desc = "The highest number of items that must be given.",
  id = "replacement.advancedMaxItems",
  order = 9,
  visibleIf = isAdvanced(),
  default = -1,
  format = maxItemsSlotsFormat
}

--#endregion Replacement settings

PowerSettings.shared.bitflag {
  name = "Allowed floors",
  desc = "The floors on which the mod can activate.",
  id = "allowedFloors",
  order = 2,
  default = SwEnum.FloorPresets.ALL_FLOORS,
  flags = SwEnum.AllowedFloors,
  presets = SwEnum.FloorPresets
}

PowerSettings.shared.percent {
  name = "Sell items",
  desc = "Price for which to sell removed items.",
  id = "sellItems",
  order = 3,
  step = 0.05,
  editAsString = true,
  format = sellPrice
}

PowerSettings.shared.bool {
  name = "Honor guaranteed transmutations",
  desc = "Whether or not transmutes/transmogs with fixed outcomes should be honored.",
  id = "guarantees",
  order = 4,
  default = true
}

PowerSettings.group {
  name = "Don't give...",
  desc = "Categories of items that shouldn't be given by the mod.",
  id = "dontGive",
  order = 5
}

--#region Don't Give items...

PowerSettings.entitySchema.bool {
  name = "Magic food",
  desc = "Whether or not magic food should be removed from Switcheroo's item pool.",
  id = "dontGive.magicFood",
  order = 0,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Movement amplifiers",
  desc = "Whether or not movement amplifiers should be removed from Switcheroo's item pool.",
  id = "dontGive.moveAmplifiers",
  order = 1,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Incoming-damage increasers",
  desc = "Whether or not items that increase incoming damage should be removed from Switcheroo's item pool.",
  id = "dontGive.damageUps",
  order = 2,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.enum {
  name = "Gold-related items",
  desc = "Whether or not items that affect the collection of gold should be removed from Switcheroo's item pool.",
  id = "dontGive.goldItems",
  order = 3,
  enum = SwEnum.DontGiveGold,
  default = SwEnum.DontGiveGold.DYNAMIC
}

PowerSettings.entitySchema.bool {
  name = "Vision-reducing items",
  desc = "Whether or not items that reduce vision should be removed from Switcheroo's item pool.",
  id = "dontGive.visionReducers",
  order = 4,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Floating items",
  desc = "Whether or not items that cause levitation should be removed from Switcheroo's item pool.",
  id = "dontGive.floatingItems",
  order = 5,
  default = false,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Rhythm-ignoring items",
  desc = "Whether or not items that allow temporarily ignoring the rhythm should be removed from Switcheroo's item pool.",
  id = "dontGive.rhythmIgnoringItems",
  order = 6,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Breakable weapons",
  desc = "Whether or not breakable weapons (such as glass) should be removed from Switcheroo's item pool.",
  id = "dontGive.breakableWeapons",
  order = 7,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Breakable shovels",
  desc = "Whether or not breakable shovels (such as glass) should be removed from Switcheroo's item pool.",
  id = "dontGive.breakableShovels",
  order = 8,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Deadly items",
  desc = "Whether or not items that are only banned as \"kill player on pickup\" should be removed from Switcheroo's item pool.",
  id = "dontGive.deadlyItems",
  order = 100,
  default = true,
  format = itemBanFormat
}

PowerSettings.shared.bool {
  name = "Banned items",
  desc = "Whether or not items normally banned for a character should be removed from Switcheroo's item pool.",
  id = "dontGive.bannedItems",
  order = 101,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.list.component {
  name = "Don't give components",
  desc = "Specific components that shouldn't be given.",
  id = "dontGive.components",
  order = 102,
  visibleIf = isAdvanced(),
  default = {},
  itemDefault = "item"
}

PowerSettings.entitySchema.list.entity {
  name = "Don't give items",
  desc = "Specific items that shouldn't be given.",
  id = "dontGive.items",
  order = 103,
  visibleIf = isAdvanced(),
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}
--#endregion Don't Give items...

PowerSettings.group {
  name = "Don't take...",
  desc = "Items that shouldn't be taken by the mod.",
  id = "dontTake",
  order = 6
}

--#region Don't take items...

PowerSettings.entitySchema.enum {
  name = "Potion",
  desc = "Whether or not the Potion should be taken by the mod.",
  id = "dontTake.potion",
  order = 0,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Lucky Charm",
  desc = "Whether or not the Lucky Charm should be taken by the mod.",
  id = "dontTake.luckyCharm",
  order = 1,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Crown of Greed",
  desc = "Whether or not the Crown of Greed should be taken by the mod.",
  id = "dontTake.crownOfGreed",
  order = 2,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Ring of Wonder",
  desc = "Whether or not the Ring of Wonder should be taken by the mod.",
  id = "dontTake.ringOfWonder",
  order = 3,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Crystal Shovel",
  desc = "Whether or not the Crystal Shovel should be taken by the mod.",
  id = "dontTake.crystalShovel",
  order = 4,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Items locked to character",
  desc = "Whether or not items that have a ban on being taken from the character should be taken by the mod.",
  id = "dontTake.locked",
  order = 100,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.DONT_TAKE
}

PowerSettings.entitySchema.label {
  name = "Items below can be taken if, and only if, given by the mod.",
  id = "dontTake.unlessGivenLabel",
  order = 101,
  visibleIf = isAdvanced()
}

PowerSettings.entitySchema.list.entity {
  name = "Don't take items unless given",
  desc = "Specific items that shouldn't be taken (unless given).",
  id = "dontTake.itemsUnlessGiven",
  order = 102,
  visibleIf = isAdvanced(),
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

PowerSettings.entitySchema.list.component {
  name = "Don't take components unless given",
  desc = "Specific components that shouldn't be taken (unless given).",
  id = "dontTake.componentsUnlessGiven",
  order = 103,
  visibleIf = isAdvanced(),
  default = {},
  itemDefault = "item"
}

PowerSettings.entitySchema.label {
  name = "Items below cannot be taken by the mod at all.",
  id = "dontTake.alwaysLabel",
  order = 104,
  visibleIf = isAdvanced()
}

PowerSettings.entitySchema.list.entity {
  name = "Don't take items",
  desc = "Specific items that shouldn't be taken.",
  id = "dontTake.items",
  order = 105,
  visibleIf = isAdvanced(),
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

PowerSettings.entitySchema.list.component {
  name = "Don't take components",
  desc = "Specific components that shouldn't be taken.",
  id = "dontTake.components",
  order = 106,
  visibleIf = isAdvanced(),
  default = {},
  itemDefault = "item"
}
--#endregion Don't take items...

--#region Advanced

PowerSettings.group {
  name = "Slot settings",
  desc = "Settings that modify slots.",
  id = "slots",
  order = 8,
  visibleIf = isAdvanced()
}

--#region Slot settings

PowerSettings.shared.bitflag {
  name = "Allowed slots",
  desc = "Which slots can the mod alter?",
  id = "slots.allowed",
  order = 0,
  visibleIf = isAdvanced(),
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.ALL_SLOTS
}

PowerSettings.shared.bitflag {
  name = "Unlocked slots",
  desc = "Which slots can the mod ignore item bans within?",
  id = "slots.unlocked",
  order = 1,
  visibleIf = isAdvanced(),
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.NO_SLOTS
}

PowerSettings.shared.bitflag {
  name = "One-time slots",
  desc = "Which slots can the mod only alter once?",
  id = "slots.oneTime",
  order = 2,
  visibleIf = isAdvanced(),
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.NO_SLOTS
}

PowerSettings.shared.number {
  name = "Slot capacity",
  desc = "How many items should be given per slot, even if it can hold more? Charms not included.",
  id = "slots.capacity",
  order = 3,
  visibleIf = isAdvanced(),
  default = 3,
  minimum = 1
}

PowerSettings.shared.bool {
  name = "Reduce over cap",
  desc = "If there are more items than the cap in a slot, should the items be downsized?",
  id = "slots.reduce",
  order = 4,
  visibleIf = isAdvanced(),
  default = true
}

--#endregion Slot settings

PowerSettings.group {
  name = "Charms settings",
  desc = "Settings related to the Misc (Charms) slots",
  id = "charms",
  order = 9,
  visibleIf = isAdvanced()
}

--#region Charms settings

PowerSettings.shared.enum {
  name = "Algorithm used",
  desc = "Which charms algorithm should be used?",
  id = "charms.algorithm",
  order = 0,
  visibleIf = isAdvanced(),
  enableIf = false,
  enum = SwEnum.CharmsAlgorithm,
  default = SwEnum.CharmsAlgorithm.ADD_ONE,
  refreshOnChange = true
}

--#region Charms algorithm settings

PowerSettings.shared.number {
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

PowerSettings.shared.number {
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

--#endregion Charms algorithm settings

--#endregion Charms settings

PowerSettings.shared.group {
  name = "Bomb settings",
  desc = "Change how Switcheroo plays with bombs",
  id = "bomb",
  order = 10,
  visibleIf = isAdvanced()
}

--#region Bomb settings
--#endregion

PowerSettings.group {
  name = "Defaults",
  desc = "Default items if generation fails or item is deleted",
  id = "defaults",
  order = 11,
  visibleIf = isAdvanced()
}

--#region Default items

PowerSettings.shared.entity {
  name = Text.Slots.Names.Action,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Action)),
  id = "defaults.action",
  order = 0,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("action"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Shovel,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Shovel)),
  id = "defaults.shovel",
  order = 1,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("shovel"),
  default = "ShovelBasic"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Weapon,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Weapon)),
  id = "defaults.weapon",
  order = 2,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("weapon"),
  default = "WeaponDagger"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Body,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Body)),
  id = "defaults.body",
  order = 3,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("body"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Head,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Head)),
  id = "defaults.head",
  order = 4,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("head"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Feet,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Feet)),
  id = "defaults.feet",
  order = 5,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("feet"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Torch,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Torch)),
  id = "defaults.torch",
  order = 6,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("torch"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Ring,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Ring)),
  id = "defaults.ring",
  order = 7,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("ring"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Spell,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Spell)),
  id = "defaults.spell",
  order = 8,
  visibleIf = isAdvanced(),
  filter = itemSlotFilter("spell"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Shield,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Shield)),
  id = "defaults.shield",
  order = 9,
  visibleIf = both(isAdvanced(), isSynchrony()),
  filter = itemSlotFilter("shield"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Holster,
  desc = "Default item for holsters",
  id = "defaults.holster",
  order = 9,
  visibleIf = isAdvanced(),
  filter = function(ent)
    return ent.name == "Switcheroo_NoneItem" or ent.item
  end,
  default = "Switcheroo_NoneItem"
}

--#endregion Default items

PowerSettings.shared.list.component {
  name = "Generator types",
  desc = "Which generator(s) should be used for the mod?",
  id = "generators",
  order = 12,
  visibleIf = isAdvanced(),
  default = { "Switcheroo_itemPoolSwitcheroo" },
  itemDefault = "itemPoolSecret",
  filter = itemPoolComponentFilter,
  itemFormat = itemPoolFormat
}

PowerSettings.shared.bool {
  name = "Fallback to unweighted generator",
  desc = "Should the unweighted generator be used if no item pool generates an item?",
  id = "generatorFallback",
  order = 13,
  visibleIf = isAdvanced(),
  default = false
}
--#endregion Advanced

--#endregion
return { get = get }
