local Enum = require "system.utils.Enum"

local module = {}

local function entry(num, name)
  return Enum.entry(num, { name = name })
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

--#endregion

return module
