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

local function setPreset(values)
  local keys = SettingsStorage.listKeys("mod.Switcheroo", PowerSettings.Layer.REMOTE_OVERRIDE)
  for i, v in ipairs(keys) do
    if values[v] ~= nil then
      SettingsStorage.set(v, values[v], PowerSettings.Layer.REMOTE_PENDING)
    else
      SettingsStorage.set(v, nil, PowerSettings.Layer.REMOTE_PENDING)
    end
  end
end

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

-- The settings below have been reorganized from their original
-- implementation. They are sorted and grouped below by their
-- treeKey.

PowerSettings.group {
  name = "Use a preset",
  desc = "Select some preset to play with!",
  id = "presets",
  order = -2
}

--#region Presets
PowerSettings.shared.action {
  name = "Switcheroo default rules",
  id = "presets.default",
  desc = "Switcheroo's default rules",
  order = 0,
  action = function()
    setPreset {}
    Menu.close()
  end
}

PowerSettings.shared.label {
  name = "Fun modes!",
  id = "presets.funModesLabel",
  order = 1,
  small = true
}

PowerSettings.shared.action {
  name = "Transmute only",
  id = "presets.transmute",
  desc = "Only existing items are changed! Empty slots are not filled.",
  order = 2,
  action = function()
    setPreset {
      ["mod.Switcheroo.replacement.advancedEmptyChance"] = 0,
      ["mod.Switcheroo.dontGive.magicFood"] = false
    }
    Menu.close()
  end
}

PowerSettings.shared.action {
  name = "Single build",
  id = "presets.single",
  desc = "Get given a single build at the start of the run!",
  order = 3,
  action = function()
    setPreset {
      ["mod.Switcheroo.allowedFloors"] = SwEnum.FloorPresets.START_OF_RUN
    }
    Menu.close()
  end
}

PowerSettings.shared.action {
  name = "One per floor",
  id = "presets.onePerFloor",
  desc = "Get given one random item per floor!",
  order = 4,
  action = function()
    setPreset {
      ["mod.Switcheroo.replacement.advancedMaxItems"] = 1
    }
  end
}

PowerSettings.shared.label {
  name = "Old versions",
  id = "presets.oldVersionsLabel",
  order = 100,
  small = true
}

PowerSettings.shared.action {
  name = "1.0.0 - 1.3.0",
  id = "presets.version1_0_0",
  desc = "Default rules in versions 1.0.0 to 1.3.0",
  order = 101,
  action = function()
    setPreset {
      ["mod.Switcheroo.dontGive.magicFood"] = false,
      ["mod.Switcheroo.dontGive.visionReducers"] = false,
      ["mod.Switcheroo.dontGive.moveAmplifiers"] = false,
      ["mod.Switcheroo.dontGive.goldItems"] = SwEnum.DontGiveGold.DONT_BAN,
      ["mod.Switcheroo.generators"] = { "itemPoolSecret" },
      ["mod.Switcheroo.slots.allowed"] = SwEnum.SlotPresets.ALL_BUT_SHIELD,
      ["mod.Switcheroo.dontGive.rhythmIgnoringItems"] = false,
      ["mod.Switcheroo.dontGive.breakableWeapons"] = false,
      ["mod.Switcheroo.dontGive.breakableShovels"] = false
    }
    Menu.close()
  end
}

PowerSettings.shared.action {
  name = "2.0.0",
  id = "presets.version2_0_0",
  desc = "Default rules in version 2.0.0",
  order = 102,
  action = function()
    setPreset {
      ["mod.Switcheroo.generators"] = { "itemPoolSecret" },
      ["mod.Switcheroo.slots.allowed"] = SwEnum.SlotPresets.ALL_BUT_SHIELD,
      ["mod.Switcheroo.dontGive.rhythmIgnoringItems"] = false,
      ["mod.Switcheroo.dontGive.breakableWeapons"] = false,
      ["mod.Switcheroo.dontGive.breakableShovels"] = false
    }
    Menu.close()
  end
}

PowerSettings.shared.action {
  name = "3.0.0 - 3.2.3",
  id = "presets.version3_0_0",
  desc = "Default rules in versions 3.0.0 to 3.2.3",
  order = 102,
  action = function()
    setPreset {
      ["mod.Switcheroo.dontGive.rhythmIgnoringItems"] = false,
      ["mod.Switcheroo.dontGive.breakableWeapons"] = false,
      ["mod.Switcheroo.dontGive.breakableShovels"] = false
    }
    Menu.close()
  end
}
--#endregion Presets

PowerSettings.shared.label {
  name = "",
  id = "blank1",
  order = -1
}

PowerSettings.group {
  name = "Item restrictions/defaults",
  desc = "Remove items from Switcheroo's default item pool or change default fallbacks",
  id = "restrictions",
  order = 0
}

--#region Item restrictions/defaults
PowerSettings.group {
  name = "Don't give...",
  desc = "Remove items from the item pool",
  id = "restrictions.dontGive",
  order = 0
}

--#region Don't give items
PowerSettings.group {
  name = "Defaults",
  desc = "Default items removed from the item pool",
  id = "restrictions.dontGive.defaults",
  order = 0
}

--#region Don't give defaults
PowerSettings.entitySchema.bool {
  name = "Magic food",
  desc = "Whether or not magic food should be removed from Switcheroo's item pool.",
  id = "dontGive.magicFood",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.magicFood",
  order = 0,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Movement amplifiers",
  desc = "Whether or not movement amplifiers should be removed from Switcheroo's item pool.",
  id = "dontGive.moveAmplifiers",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.moveAmplifiers",
  order = 1,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Incoming-damage increasers",
  desc = "Whether or not items that increase incoming damage should be removed from Switcheroo's item pool.",
  id = "dontGive.damageUps",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.damageUps",
  order = 2,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Vision-reducing items",
  desc = "Whether or not items that reduce vision should be removed from Switcheroo's item pool.",
  id = "dontGive.visionReducers",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.visionReducers",
  order = 4,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Floating items",
  desc = "Whether or not items that cause levitation should be removed from Switcheroo's item pool.",
  id = "dontGive.floatingItems",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.floatingItems",
  order = 5,
  default = false,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Rhythm-ignoring items",
  desc = "Whether or not items that allow temporarily ignoring the rhythm should be removed from Switcheroo's item pool.",
  id = "dontGive.rhythmIgnoringItems",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.rhythmItems",
  order = 6,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Breakable weapons",
  desc = "Whether or not breakable weapons (such as glass) should be removed from Switcheroo's item pool.",
  id = "dontGive.breakableWeapons",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.breakableWeapons",
  order = 7,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.bool {
  name = "Breakable shovels",
  desc = "Whether or not breakable shovels (such as glass) should be removed from Switcheroo's item pool.",
  id = "dontGive.breakableShovels",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.breakableShovels",
  order = 8,
  default = true,
  format = itemBanFormat
}

PowerSettings.entitySchema.enum {
  name = "Gold-related items",
  desc = "Whether or not items that affect the collection of gold should be removed from Switcheroo's item pool.",
  id = "dontGive.goldItems",
  treeKey = "mod.Switcheroo.restrictions.dontGive.defaults.goldItems",
  order = 100,
  enum = SwEnum.DontGiveGold,
  default = SwEnum.DontGiveGold.DYNAMIC
}
--#endregion Don't give defaults

PowerSettings.group {
  name = "Customs",
  desc = "Custom items to remove from the item pool",
  id = "restrictions.dontGive.customs",
  order = 1,
  visibility = Settings.Visibility.ADVANCED
}

--#region Don't give customs
PowerSettings.entitySchema.list.entity {
  name = "Don't give these items",
  desc = "These specific items shouldn't be given.",
  id = "dontGive.items",
  treeKey = "mod.Switcheroo.restrictions.dontGive.customs.items",
  order = 0,
  visibility = Settings.Visibility.ADVANCED,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

PowerSettings.entitySchema.list.component {
  name = "Don't give items with these components",
  desc = "Items with any of these components shouldn't be given.",
  id = "dontGive.components",
  treeKey = "mod.Switcheroo.restrictions.dontGive.customs.components",
  order = 1,
  visibility = Settings.Visibility.ADVANCED,
  default = {},
  itemDefault = "item"
}
--#endregion Don't give customs

PowerSettings.shared.bool {
  name = "Banned items",
  desc = "Whether or not items normally banned for a character should be removed from Switcheroo's item pool.",
  id = "dontGive.bannedItems",
  treeKey = "mod.Switcheroo.restrictions.dontGive.bannedItems",
  order = 101,
  default = true,
  format = itemBanFormat
}
--#endregion Don't give items

PowerSettings.group {
  name = "Don't take...",
  desc = "Items that shouldn't be taken by the mod",
  id = "restrictions.dontTake",
  order = 1
}

--#region Don't take items
PowerSettings.group {
  name = "Defaults",
  desc = "Default items the mod shouldn't take",
  id = "restrictions.dontTake.defaults",
  order = 0
}

--#region Don't take defaults
PowerSettings.entitySchema.enum {
  name = "Potion",
  desc = "Whether or not the Potion should be taken by the mod.",
  id = "dontTake.potion",
  treeKey = "mod.Switcheroo.restrictions.dontTake.defaults.potion",
  order = 0,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Lucky Charm",
  desc = "Whether or not the Lucky Charm should be taken by the mod.",
  id = "dontTake.luckyCharm",
  treeKey = "mod.Switcheroo.restrictions.dontTake.defaults.luckyCharm",
  order = 1,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Crown of Greed",
  desc = "Whether or not the Crown of Greed should be taken by the mod.",
  id = "dontTake.crownOfGreed",
  treeKey = "mod.Switcheroo.restrictions.dontTake.defaults.crownOfGreed",
  order = 2,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Ring of Wonder",
  desc = "Whether or not the Ring of Wonder should be taken by the mod.",
  id = "dontTake.ringOfWonder",
  treeKey = "mod.Switcheroo.restrictions.dontTake.defaults.ringOfWonder",
  order = 3,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}

PowerSettings.entitySchema.enum {
  name = "Crystal Shovel",
  desc = "Whether or not the Crystal Shovel should be taken by the mod.",
  id = "dontTake.crystalShovel",
  treeKey = "mod.Switcheroo.restrictions.dontTake.defaults.crystalShovel",
  order = 4,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.TAKE_IF_GIVEN
}
--#endregion Don't take defaults

PowerSettings.group {
  name = "Customs",
  desc = "Custom items the mod shouldn't take",
  id = "restrictions.dontTake.customs",
  order = 1,
  visibility = Settings.Visibility.ADVANCED
}

--#region Don't take customs
PowerSettings.entitySchema.label {
  name = "Items below can be taken if, and only if, given by the mod.",
  id = "dontTake.unlessGivenLabel",
  treeKey = "mod.Switcheroo.restrictions.dontTake.customs.unlessGivenLabel",
  order = 101,
  visibility = Settings.Visibility.ADVANCED
}

PowerSettings.entitySchema.list.entity {
  name = "Don't take items unless given",
  desc = "Specific items that shouldn't be taken (unless given).",
  id = "dontTake.itemsUnlessGiven",
  treeKey = "mod.Switcheroo.restrictions.dontTake.customs.itemsUnlessGiven",
  order = 102,
  visibility = Settings.Visibility.ADVANCED,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

PowerSettings.entitySchema.list.component {
  name = "Don't take components unless given",
  desc = "Specific components that shouldn't be taken (unless given).",
  id = "dontTake.componentsUnlessGiven",
  treeKey = "mod.Switcheroo.restrictions.dontTake.customs.componentsUnlessGiven",
  order = 103,
  visibility = Settings.Visibility.ADVANCED,
  default = {},
  itemDefault = "item"
}

PowerSettings.entitySchema.label {
  name = "Items below cannot be taken by the mod at all.",
  id = "dontTake.alwaysLabel",
  treeKey = "mod.Switcheroo.restrictions.dontTake.customs.alwaysLabel",
  order = 104,
  visibility = Settings.Visibility.ADVANCED
}

PowerSettings.entitySchema.list.entity {
  name = "Don't take items",
  desc = "Specific items that shouldn't be taken.",
  id = "dontTake.items",
  treeKey = "mod.Switcheroo.restrictions.dontTake.customs.items",
  order = 105,
  visibility = Settings.Visibility.ADVANCED,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

PowerSettings.entitySchema.list.component {
  name = "Don't take components",
  desc = "Specific components that shouldn't be taken.",
  id = "dontTake.components",
  treeKey = "mod.Switcheroo.restrictions.dontTake.customs.components",
  order = 106,
  visibility = Settings.Visibility.ADVANCED,
  default = {},
  itemDefault = "item"
}
--#endregion Don't take customs

PowerSettings.entitySchema.enum {
  name = "Items locked to character",
  desc = "Whether or not items that have a ban on being taken from the character should be taken by the mod.",
  id = "dontTake.locked",
  treeKey = "mod.Switcheroo.restrictions.dontTake.locked",
  order = 2,
  enum = SwEnum.DontTake,
  default = SwEnum.DontTake.DONT_TAKE
}
--#endregion Don't take items

PowerSettings.group {
  name = "Item defaults",
  desc = "Default items if generation fails",
  id = "restrictions.defaults",
  order = 2
}

--#region Item defaults
PowerSettings.shared.entity {
  name = Text.Slots.Names.Action,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Action)),
  id = "defaults.action",
  treeKey = "mod.Switcheroo.restrictions.defaults.action",
  order = 0,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("action"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Shovel,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Shovel)),
  id = "defaults.shovel",
  treeKey = "mod.Switcheroo.restrictions.defaults.shovel",
  order = 1,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("shovel"),
  default = "ShovelBasic"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Weapon,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Weapon)),
  id = "defaults.weapon",
  treeKey = "mod.Switcheroo.restrictions.defaults.weapon",
  order = 2,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("weapon"),
  default = "WeaponDagger"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Body,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Body)),
  id = "defaults.body",
  treeKey = "mod.Switcheroo.restrictions.defaults.body",
  order = 3,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("body"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Head,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Head)),
  id = "defaults.head",
  treeKey = "mod.Switcheroo.restrictions.defaults.head",
  order = 4,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("head"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Feet,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Feet)),
  id = "defaults.feet",
  treeKey = "mod.Switcheroo.restrictions.defaults.feet",
  order = 5,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("feet"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Torch,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Torch)),
  id = "defaults.torch",
  treeKey = "mod.Switcheroo.restrictions.defaults.torch",
  order = 6,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("torch"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Ring,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Ring)),
  id = "defaults.ring",
  treeKey = "mod.Switcheroo.restrictions.defaults.ring",
  order = 7,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("ring"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Spell,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Spell)),
  id = "defaults.spell",
  treeKey = "mod.Switcheroo.restrictions.defaults.spell",
  order = 8,
  visibility = Settings.Visibility.ADVANCED,
  filter = itemSlotFilter("spell"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Shield,
  desc = Text.Settings.DefaultItemDesc(Text.Func.NounCase(Text.Slots.Names.Shield)),
  id = "defaults.shield",
  treeKey = "mod.Switcheroo.restrictions.defaults.shield",
  order = 9,
  visibility = Settings.Visibility.ADVANCED,
  visibleIf = isSynchrony(),
  filter = itemSlotFilter("shield"),
  default = "Switcheroo_NoneItem"
}

PowerSettings.shared.entity {
  name = Text.Slots.Names.Holster,
  desc = "Default item for holsters",
  id = "defaults.holster",
  treeKey = "mod.Switcheroo.restrictions.defaults.holster",
  order = 9,
  visibility = Settings.Visibility.ADVANCED,
  filter = function(ent)
    return ent.name == "Switcheroo_NoneItem" or ent.item
  end,
  default = "Switcheroo_NoneItem"
}
--#endregion Item defaults
--#endregion Item restrictions/defaults

PowerSettings.group {
  name = "Activation settings",
  desc = "Change the chances or places Switcheroo can activate",
  id = "activation",
  order = 1
}

--#region Activation settings
PowerSettings.shared.percent {
  name = "Chance to grant new items",
  desc = "The chance an empty slot is selected and given an item.",
  id = "replacement.advancedEmptyChance",
  treeKey = "mod.Switcheroo.activation.empty",
  order = 0,
  default = 1,
  step = 0.01
}

PowerSettings.shared.percent {
  name = "Chance to replace existing items",
  desc = "The chance an existing item is replaced with a new item.",
  id = "replacement.advancedFullSelectChance",
  treeKey = "mod.Switcheroo.activation.full",
  order = 1,
  default = 1,
  step = 0.01
}

PowerSettings.group {
  name = "Advanced activation chances",
  desc = "More settings for number of activations",
  id = "activation.chances",
  order = 2,
  visibility = Settings.Visibility.ADVANCED
}

--#region Advanced activation chances
PowerSettings.shared.percent {
  name = "Selected slot replacement chance",
  desc = "The chance a selected (filled) slot is replaced.",
  id = "replacement.advancedFullReplaceChance",
  treeKey = "mod.Switcheroo.activation.chances.advancedFullReplaceChance",
  order = 0,
  visibility = Settings.Visibility.ADVANCED,
  default = 1,
  step = 0.01
}

PowerSettings.shared.number {
  name = "Minimum empty slots",
  desc = "The number of empty slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedEmptyMinSlots",
  treeKey = "mod.Switcheroo.activation.chances.advancedEmptyMinSlots",
  order = 2,
  visibility = Settings.Visibility.ADVANCED,
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Minimum full slots",
  desc = "The number of full slots that must be picked (if that many exist), even if 0% chance.",
  id = "replacement.advancedFullMinSlots",
  treeKey = "mod.Switcheroo.activation.chances.advancedFullMinSlots",
  order = 5,
  visibility = Settings.Visibility.ADVANCED,
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Minimum total slots",
  desc = "The number of slots that must be picked, if it's more than the two individual minimums.",
  id = "replacement.advancedMinSlots",
  treeKey = "mod.Switcheroo.activation.chances.advancedMinSlots",
  order = 6,
  visibility = Settings.Visibility.ADVANCED,
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Maximum slots",
  desc = "The highest number of slots that must be picked.",
  id = "replacement.advancedMaxSlots",
  treeKey = "mod.Switcheroo.activation.chances.advancedMaxSlots",
  order = 7,
  visibility = Settings.Visibility.ADVANCED,
  default = -1,
  format = maxItemsSlotsFormat
}

PowerSettings.shared.number {
  name = "Minimum items given",
  desc = "The number of items that must be given, if that many slots are picked.",
  id = "replacement.advancedMinItems",
  treeKey = "mod.Switcheroo.activation.chances.advancedMinItems",
  order = 8,
  visibility = Settings.Visibility.ADVANCED,
  default = 0,
  minimum = 0
}

PowerSettings.shared.number {
  name = "Maximum items given",
  desc = "The highest number of items that must be given.",
  id = "replacement.advancedMaxItems",
  treeKey = "mod.Switcheroo.activation.chances.advancedMaxItems",
  order = 9,
  visibility = Settings.Visibility.ADVANCED,
  default = -1,
  format = maxItemsSlotsFormat
}
--#endregion

PowerSettings.shared.bitflag {
  name = "Allowed floors",
  desc = "The floors on which the mod can activate.",
  id = "allowedFloors",
  treeKey = "mod.Switcheroo.activation.floors",
  order = 3,
  default = SwEnum.FloorPresets.ALL_FLOORS,
  flags = SwEnum.AllowedFloors,
  presets = SwEnum.FloorPresets
}

PowerSettings.shared.bitflag {
  name = "Allowed slots",
  desc = "Which slots can the mod alter?",
  id = "slots.allowed",
  treeKey = "mod.Switcheroo.activation.allowedSlots",
  order = 4,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.ALL_SLOTS
}

PowerSettings.group {
  name = "Advanced slot settings",
  desc = "More control over how the slots work",
  id = "activation.slots",
  order = 5,
  visibility = Settings.Visibility.ADVANCED
}

--#region Slot settings
PowerSettings.shared.bitflag {
  name = "Unlocked slots",
  desc = "Which slots can the mod ignore item bans within?",
  id = "slots.unlocked",
  treeKey = "mod.Switcheroo.activation.slots.unlocked",
  order = 1,
  visibility = Settings.Visibility.ADVANCED,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.NO_SLOTS
}

PowerSettings.shared.bitflag {
  name = "One-time slots",
  desc = "Which slots can the mod only alter once?",
  id = "slots.oneTime",
  treeKey = "mod.Switcheroo.activation.slots.oneTime",
  order = 2,
  visibility = Settings.Visibility.ADVANCED,
  flags = SwEnum.SlotsBitmask,
  presets = SwEnum.SlotPresets,
  default = SwEnum.SlotPresets.NO_SLOTS
}

PowerSettings.shared.number {
  name = "Slot capacity",
  desc = "How many items should be given per slot, even if it can hold more? Charms not included.",
  id = "slots.capacity",
  treeKey = "mod.Switcheroo.activation.slots.capacity",
  order = 3,
  visibility = Settings.Visibility.ADVANCED,
  default = 3,
  minimum = 1
}

PowerSettings.shared.bool {
  name = "Reduce over cap",
  desc = "If there are more items than the cap in a slot, should the items be downsized?",
  id = "slots.reduce",
  treeKey = "mod.Switcheroo.activation.slots.reduce",
  order = 4,
  visibility = Settings.Visibility.ADVANCED,
  default = true
}
--#endregion Slot settings
--#endregion Activation settings

PowerSettings.group {
  name = "Misc settings",
  desc = "Change other settings",
  id = "misc",
  order = 2
}

--#region Misc settings
PowerSettings.shared.percent {
  name = "Sell items",
  desc = "Price for which to sell removed items.",
  id = "sellItems",
  treeKey = "mod.Switcheroo.misc.sell",
  order = 0,
  step = 0.05,
  editAsString = true,
  format = sellPrice
}

PowerSettings.shared.bool {
  name = "Honor guaranteed transmutations",
  desc = "Whether or not transmutes/transmogs with fixed outcomes should be honored.",
  id = "guarantees",
  treeKey = "mod.Switcheroo.misc.guarantees",
  order = 1,
  default = true
}

PowerSettings.group {
  name = "Charms settings",
  desc = "Settings related to the Misc (Charms) slots",
  id = "misc.charms",
  order = 2,
  visibility = Settings.Visibility.ADVANCED
}

--#region Charms settings
PowerSettings.shared.enum {
  name = "Algorithm used",
  desc = "Which charms algorithm should be used?",
  id = "charms.algorithm",
  treeKey = "mod.Switcheroo.misc.charms.algorithm",
  order = 0,
  visibility = Settings.Visibility.ADVANCED,
  enableIf = false,
  enum = SwEnum.CharmsAlgorithm,
  default = SwEnum.CharmsAlgorithm.ADD_ONE
}

--#region Charms algorithm settings
PowerSettings.shared.label {
  name = "\"Add one\" settings",
  id = "misc.charms.addOneLabel",
  order = 1
}

PowerSettings.shared.number {
  name = "Maximum added charms",
  desc = "How many charms can the mod add per floor?",
  id = "charms.maxAdd",
  treeKey = "mod.Switcheroo.misc.charms.maxAdd",
  order = 2,
  minimum = 0,
  default = 1,
  editAsString = true,
  visibility = Settings.Visibility.ADVANCED
}

PowerSettings.shared.number {
  name = "Maximum total charms",
  desc = "How many charms can you have before the mod stops adding?",
  id = "charms.maxTotal",
  treeKey = "mod.Switcheroo.misc.charms.maxTotal",
  order = 3,
  minimum = 0,
  default = 5,
  editAsString = true,
  visibility = Settings.Visibility.ADVANCED
}
--#endregion Charms algorithm settings
--#endregion Charms settings

PowerSettings.shared.list.component {
  name = "Generator types",
  desc = "Which generator(s) should be used for the mod?",
  id = "generators",
  treeKey = "mod.Switcheroo.misc.generators",
  order = 3,
  visibility = Settings.Visibility.ADVANCED,
  default = { "Switcheroo_itemPoolSwitcheroo" },
  itemDefault = "itemPoolSecret",
  filter = itemPoolComponentFilter,
  itemFormat = itemPoolFormat
}

PowerSettings.shared.bool {
  name = "Fallback to unweighted generator",
  desc = "Should the unweighted generator be used if no item pool generates an item?",
  id = "generatorFallback",
  treeKey = "mod.Switcheroo.misc.fallback",
  order = 4,
  visibility = Settings.Visibility.ADVANCED,
  default = false
}
--#endregion
--#endregion

return { get = get }