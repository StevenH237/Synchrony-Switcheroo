local Enum      = require "system.utils.Enum"
local GameDLC   = require "necro.game.data.resource.GameDLC"
local ItemBan   = require "necro.game.item.ItemBan"
local Utilities = require "system.utils.Utilities"

local module = {}

local function entry(num, name, data)
  data = data or {}
  data.name = name
  return Enum.entry(num, data)
end

-----------------
-- TRANSLATION --
--#region--------
local T = {
  -- Defined here for consistency:
  DYNAMIC = L("Dynamic ban", "dontBan.dynamic"),

  -- Defined here to also be usable elsewhere in the mod:
  DONT_BAN = L("Don't ban", "dontBan.dontBan"),
  BAN      = L("Ban", "dontBan.ban"),

  -- Defined here to always be loaded:
  SHIELD                 = L("Shield", "slots.shield"),
  ALL_BUT_SHIELD         = L("All slots except shield", "slotPresets.allButShield"),
  ALL_BUT_WEAPON_SHIELD  = L("All slots except shield and weapons", "slotPresets.allButWeaponShield"),
  ALL_BUT_HOLSTER_SHIELD = L("All slots except shield and holster", "slotPresets.allButHolsterShield")
}

module.Text = T
--#endregion

-----------
-- ENUMS --
--#region--

module.ReplaceMode = Enum.sequence {
  EXISTING   = entry(1, L("Replace existing items", "replaceMode.existing")),
  EMPTY      = entry(2, L("Fill empty slots", "replaceMode.empty")),
  EVERYTHING = entry(3, L("Fill and replace", "replaceMode.everything"))
}

do
  local floors = {
    EXTRA_BOSS         = entry(25, L("Extra story boss", "floors.extraBoss")),
    RAW_FLOOR_NUMBERS  = entry(26, L("Raw floor numbers above", "floors.rawFloorNumbers")),
    TRAINING_FLOORS    = entry(27, L("Training floors", "floors.trainingFloors")),
    EXTRA_BOSS_FLOORS  = entry(29, L("Add extra/custom boss floors", "floors.extraBossFloors")),
    EXTRA_POST_BOSSES  = entry(30, L("Add extra post-boss floors", "floors.extraPostBosses")),
    EXTRA_OTHER_FLOORS = entry(31, L("Add other extra floors", "floors.extraOtherFloors"))
  }

  for d = 1, 5 do
    for f = 1, 4 do
      floors["DEPTH_" .. d .. "_LEVEL_" .. f] = entry((d - 1) * 4 + f, L.formatKey("Depth %d-%d", "floors.depth", d, f))
    end
  end

  module.AllowedFloors = Enum.bitmask(floors)
end

module.FloorPresets = Enum.sequence {
  ALL_FLOORS    = entry(0x750FFFFF, L("All floors", "floorPresets.allFloors")),
  FIRST_OF_ZONE = entry(0x24011111, L("First of each zone", "floorPresets.firstOfZone")),
  START_OF_RUN  = entry(0x04000001, L("Start of run only", "floorPresets.startOfRun")),
  POST_BOSSES   = entry(0x20011110, L("After every boss", "floorPresets.postBosses"))
}

module.DontTake = Enum.sequence {
  TAKE          = entry(0, L("Take item", "dontTake.take")),
  TAKE_IF_GIVEN = entry(1, L("Take if given by mod", "dontTake.takeIfGiven")),
  DONT_TAKE     = entry(2, L("Don't take item", "dontTake.dontTake"))
}

module.DontGiveGold = Enum.sequence {
  DONT_BAN = entry(0, T.DONT_BAN),
  BAN      = entry(1, T.BAN),
  DYNAMIC  = entry(2, T.DYNAMIC)
}

do
  local slotTable = {
    ACTION  = entry(1, L("Item", "slots.action")),
    SHOVEL  = entry(2, L("Shovel", "slots.shovel")),
    WEAPON  = entry(3, L("Weapon", "slots.weapon")),
    BODY    = entry(4, L("Body", "slots.body")),
    HEAD    = entry(5, L("Head", "slots.head")),
    FEET    = entry(6, L("Feet", "slots.feet")),
    TORCH   = entry(7, L("Torch", "slots.torch")),
    RING    = entry(8, L("Ring", "slots.ring")),
    MISC    = entry(9, L("Charms", "slots.misc")),
    SPELL   = entry(10, L("Spells", "slots.spell")),
    HOLSTER = entry(11, L("Holstered weapon", "slots.holster"))
  }

  local slotPresetsTable = {
    ALL_SLOTS       = entry(0xFFF, L("All slots", "slotPresets.all")),
    ALL_BUT_WEAPON  = entry(0xBFB, L("All slots except weapons", "slotPresets.allButWeapon")),
    ALL_BUT_HOLSTER = entry(0xBFF, L("All slots except holster", "slotPresets.allButHolster")),
    NO_SLOTS        = entry(0x000, L("No slots", "slotPresets.noSlots"))
  }

  if GameDLC.isSynchronyLoaded() then
    slotTable.SHIELD = entry(12, T.SHIELD)
    slotPresetsTable.ALL_BUT_SHIELD = entry(0x7FF, T.ALL_BUT_SHIELD)
    slotPresetsTable.ALL_BUT_WEAPON_SHIELD = entry(0x3FB, T.ALL_BUT_WEAPON_SHIELD)
    slotPresetsTable.ALL_BUT_HOLSTER_SHIELD = entry(0x3FF, T.ALL_BUT_HOLSTER_SHIELD)
  end

  module.Slots = Enum.sequence(slotTable)
  module.SlotsBitmask = Enum.bitmask(slotTable)
  module.SlotPresets = Enum.sequence(slotPresetsTable)
end

module.CharmsAlgorithm = Enum.sequence {
  ADD_ONE = entry(1, L("Simple", "charmsAlgorithm.addOne"))
}
--#endregion

return module
