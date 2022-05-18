--#region Imports
local GameDLC = require "necro.game.data.resource.GameDLC"

local PowerSettings = require "PowerSettings.PowerSettings"

local SwEnum = require "Switcheroo.SwitcherooEnum"
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

--#endregion

--------------
-- ENABLERS --
--#region-----

local function isAmplified()
  return GameDLC.isAmplifiedLoaded()
end

--#endregion Enablers

-------------
-- ACTIONS --
--#region----

--#endregion

--------------
-- SETTINGS --
--#region-----

Replacemode = PowerSettings.entitySchema.enum {
  name = "Replace mode",
  desc = "Whether to replace existing items, generate new items, or both",
  id = "replaceMode",
  order = 0,
  enum = SwEnum.ReplaceMode,
  default = SwEnum.ReplaceMode.EVERYTHING
}

Replacechance = PowerSettings.entitySchema.percent {
  name = "Replace chance",
  desc = "Chance to replace items in selected inventory slots",
  id = "replaceChance",
  order = 1,
  default = 1,
  step = 0.05,
  editAsString = true
}

Allowedfloors = PowerSettings.entitySchema.bitflag {
  name = "Allowed floors",
  desc = "The floors on which the mod can activate.",
  id = "allowedFloors",
  order = 2,
  default = SwEnum.FloorPresets.ALL_FLOORS,
  flags = SwEnum.AllowedFloors,
  presets = SwEnum.FloorPresets
}

Sellitems = PowerSettings.entitySchema.percent {
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

Dontgive = PowerSettings.group {
  name = "Don't give...",
  desc = "Categories of items that shouldn't be given by the mod.",
  id = "dontGive",
  order = 5
}

--#region Don't Give items...

DontgiveMagicfood = PowerSettings.entitySchema.bool {
  name = "Magic food",
  desc = "Whether or not magic food should be banned from the item pool.",
  id = "dontGive.magicFood",
  order = 0,
  default = true,
  format = itemBanFormat
}

DontgiveMoveamplifiers = PowerSettings.entitySchema.bool {
  name = "Movement amplifiers",
  desc = "Whether or not movement amplifiers should be banned from the item pool.",
  id = "dontGive.moveAmplifiers",
  order = 1,
  default = true,
  format = itemBanFormat
}

DontgiveDamageups = PowerSettings.entitySchema.bool {
  name = "Incoming-damage increasers",
  desc = "Whether or not items that increase incoming damage should be banned from the item pool.",
  id = "dontGive.damageUps",
  order = 2,
  default = true,
  format = itemBanFormat
}

DontgiveGolditems = PowerSettings.entitySchema.bool {
  name = "Gold-related items",
  desc = "Whether or not items that affect the collection of gold should be banned from the item pool.",
  id = "dontGive.goldItems",
  order = 3,
  default = false,
  format = itemBanFormat
}

DontgiveVisionreducers = PowerSettings.entitySchema.bool {
  name = "Vision-reducing items",
  desc = "Whether or not items that reduce vision should be banned from the item pool.",
  id = "dontGive.visionReducers",
  order = 4,
  default = false,
  format = itemBanFormat
}

DontgiveDeadlyitems = PowerSettings.entitySchema.bool {
  name = "Deadly items",
  desc = "Whether or not items that are only banned as \"kill player on pickup\" should be banned from the item pool.",
  id = "dontGive.deadlyItems",
  order = 5,
  default = true,
  format = itemBanFormat
}

DontgiveBanneditems = PowerSettings.entitySchema.bool {
  name = "Banned items",
  desc = "Whether or not items normally banned for a character should be banned from the item pool.",
  id = "dontGive.bannedItems",
  order = 6,
  default = true,
  format = itemBanFormat
}

DontgiveOther = PowerSettings.group {
  name = "Other (advanced)...",
  desc = "Specify your own items to never give.",
  id = "dontGive.other",
  order = 7
}

--#region Don't give other

DontgiveOtherItems = PowerSettings.entitySchema.list.entity {
  name = "Items",
  desc = "Specific items that shouldn't be given.",
  id = "dontGive.other.items",
  order = 0,
  default = {},
  filter = "item",
  itemDefault = "MiscPotion"
}

DontgiveOtherComponents = PowerSettings.entitySchema.list.component {
  name = "Components",
  desc = "Specific components that shouldn't be given.",
  id = "dontGive.other.components",
  order = 1,
  default = {},
  itemDefault = "item"
}

--#enregion Don't give other

--#endregion Don't Give items...

--#region Don't take items...

Donttake = PowerSettings.group {
  name = "Don't take items..."
}

--#endregion Don't take items...

--#endregion
