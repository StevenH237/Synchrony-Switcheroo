local Enum      = require "system.utils.Enum"
local GameDLC   = require "necro.game.data.resource.GameDLC"
local ItemBan   = require "necro.game.item.ItemBan"
local Utilities = require "system.utils.Utilities"

local Text = require "Switcheroo.i18n.Text"

local module = {}

local function entry(num, name, data)
  data = data or {}
  data.name = name
  return Enum.entry(num, data)
end

-----------
-- ENUMS --
--#region--

do
  local floors = {
    EXTRA_BOSS         = entry(25, Text.Floors.ExtraStoryBoss),
    RAW_FLOOR_NUMBERS  = entry(26, Text.Floors.RawFloorNumbers),
    TRAINING_FLOORS    = entry(27, Text.Floors.TrainingFloors),
    EXTRA_BOSS_FLOORS  = entry(29, Text.Floors.ExtraBossFloors),
    EXTRA_POST_BOSSES  = entry(30, Text.Floors.ExtraPostBosses),
    EXTRA_OTHER_FLOORS = entry(31, Text.Floors.ExtraOtherFloors)
  }

  for d = 1, 5 do
    for f = 1, 4 do
      local i = (d - 1) * 4 + f
      floors["DEPTH_" .. d .. "_LEVEL_" .. f] = entry(i, Text.Floors.DepthLevel(Text.Floors.Ordinal[i], d, f))
    end
  end

  module.AllowedFloors = Enum.bitmask(floors)
end

module.CharmsAlgorithm = Enum.sequence {
  ADD_ONE = entry(1, Text.CharmsAlgorithms.Simple)
}

module.DontGiveGold = Enum.sequence {
  DONT_BAN = entry(0, Text.Bans.Giving.Allow),
  BAN      = entry(1, Text.Bans.Giving.DontAllow),
  DYNAMIC  = entry(2, Text.Bans.Giving.DynamicGold)
}

module.DontTake = Enum.sequence {
  TAKE          = entry(0, Text.Bans.Taking.Take),
  TAKE_IF_GIVEN = entry(1, Text.Bans.Taking.TakeIfGiven),
  DONT_TAKE     = entry(2, Text.Bans.Taking.DontTake)
}

module.FloorPresets = Enum.sequence {
  ALL_FLOORS    = entry(0x750FFFFF, Text.FloorPresets.AllFloors),
  FIRST_OF_ZONE = entry(0x24011111, Text.FloorPresets.FirstOfZone),
  START_OF_RUN  = entry(0x04000001, Text.FloorPresets.StartOfRun),
  POST_BOSSES   = entry(0x20011110, Text.FloorPresets.PostBosses)
}

module.ReplaceMode = Enum.sequence {
  EXISTING   = entry(1, Text.ReplaceMode.Existing),
  EMPTY      = entry(2, Text.ReplaceMode.Empty),
  EVERYTHING = entry(3, Text.ReplaceMode.Everything)
}

do
  local slotTable = {
    ACTION  = entry(1, Text.Slots.Names.Action),
    SHOVEL  = entry(2, Text.Slots.Names.Shovel),
    WEAPON  = entry(3, Text.Slots.Names.Weapon),
    BODY    = entry(4, Text.Slots.Names.Body),
    HEAD    = entry(5, Text.Slots.Names.Head),
    FEET    = entry(6, Text.Slots.Names.Feet),
    TORCH   = entry(7, Text.Slots.Names.Torch),
    RING    = entry(8, Text.Slots.Names.Ring),
    MISC    = entry(9, Text.Slots.Names.Misc),
    SPELL   = entry(10, Text.Slots.Names.Spell),
    HOLSTER = entry(11, Text.Slots.Names.Holster)
  }

  local slotPresetsTable = {
    ALL_SLOTS       = entry(0xFFF, Text.Slots.Presets.AllSlots),
    ALL_BUT_WEAPON  = entry(0xBFB, Text.Slots.Presets.AllButWeapon),
    ALL_BUT_HOLSTER = entry(0xBFF, Text.Slots.Presets.AllButHolster),
    NO_SLOTS        = entry(0x000, Text.Slots.Presets.NoSlots)
  }

  if GameDLC.isSynchronyLoaded() then
    slotTable.SHIELD = entry(12, Text.Slots.Names.Shield)
    slotPresetsTable.ALL_BUT_SHIELD = entry(0x7FF, Text.Slots.Presets.AllButShield)
    slotPresetsTable.ALL_BUT_WEAPON_SHIELD = entry(0x3FB, Text.Slots.Presets.AllButWeaponShield)
    slotPresetsTable.ALL_BUT_HOLSTER_SHIELD = entry(0x3FF, Text.Slots.Presets.AllButHolsterShield)
  end

  module.Slots = Enum.sequence(Utilities.fastCopy(slotTable))
  module.SlotsBitmask = Enum.bitmask(Utilities.fastCopy(slotTable))
  module.SlotPresets = Enum.sequence(slotPresetsTable)
end
--#endregion

return module
