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

-----------
-- ENUMS --
--#region--

module.ReplaceMode = Enum.sequence {
  EXISTING   = entry(1, "Replace existing items"),
  EMPTY      = entry(2, "Fill empty slots"),
  EVERYTHING = entry(3, "Fill and replace")
}

do
  local floors = {
    EXTRA_BOSS         = entry(25, "Extra story boss"),
    RAW_FLOOR_NUMBERS  = entry(26, "Raw floor numbers above"),
    TRAINING_FLOORS    = entry(27, "Training floors"),
    EXTRA_BOSS_FLOORS  = entry(29, "Add extra/custom boss floors"),
    EXTRA_POST_BOSSES  = entry(30, "Add extra post-boss floors"),
    EXTRA_OTHER_FLOORS = entry(31, "Add other extra floors")
  }

  for d = 1, 5 do
    for f = 1, 4 do
      floors["DEPTH_" .. d .. "_LEVEL_" .. f] = entry((d - 1) * 4 + f, "Depth " .. d .. "-" .. f)
    end
  end

  module.AllowedFloors = Enum.bitmask(floors)
end

module.FloorPresets = Enum.sequence {
  ALL_FLOORS    = entry(0x750FFFFF, "All floors"),
  FIRST_OF_ZONE = entry(0x24011111, "First of each zone"),
  START_OF_RUN  = entry(0x04000001, "Start of run only"),
  POST_BOSSES   = entry(0x20011110, "After every boss")
}

module.DontTake = Enum.sequence {
  TAKE          = entry(0, "Take item"),
  TAKE_IF_GIVEN = entry(1, "Take if given by mod"),
  DONT_TAKE     = entry(2, "Don't take item")
}

module.DontGiveGold = Enum.sequence {
  DONT_BAN = entry(0, "Don't ban"),
  BAN      = entry(1, "Ban"),
  DYNAMIC  = entry(2, "Dynamic ban")
}

do
  local slotTable = {
    ACTION  = entry(1, "Item"),
    SHOVEL  = entry(2, "Shovel"),
    WEAPON  = entry(3, "Weapon"),
    BODY    = entry(4, "Body"),
    HEAD    = entry(5, "Head"),
    FEET    = entry(6, "Feet"),
    TORCH   = entry(7, "Torch"),
    RING    = entry(8, "Ring"),
    MISC    = entry(9, "Misc"),
    SPELL   = entry(10, "Spells"),
    HOLSTER = entry(11, "Holstered weapon")
  }

  local slotPresetsTable = {
    ALL_SLOTS       = entry(0xFFF, "All slots"),
    ALL_BUT_WEAPON  = entry(0xBFB, "All slots except weapons"),
    ALL_BUT_HOLSTER = entry(0xBFF, "All slots except holster"),
    NO_SLOTS        = entry(0x000, "No slots")
  }

  if GameDLC.isSynchronyLoaded() then
    slotTable.SHIELD = entry(12, "Shield")
    slotPresetsTable.ALL_BUT_SHIELD = entry(0x7FF, "All slots except shield")
    slotPresetsTable.ALL_BUT_WEAPON_SHIELD = entry(0x3FB, "All slots except shield and weapons")
    slotPresetsTable.ALL_BUT_HOLSTER_SHIELD = entry(0x3FF, "All slots except shield and holster")
  end

  module.Slots = Enum.sequence(slotTable)
  module.SlotsBitmask = Enum.bitmask(slotTable)
  module.SlotPresets = Enum.sequence(slotPresetsTable)
end

module.CharmsAlgorithm = Enum.sequence {
  ADD_ONE    = entry(1, "Simple"),
  DICE_BASED = entry(2, "Dice-based")
}
--#endregion

return module
