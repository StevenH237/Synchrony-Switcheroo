local Enum    = require "system.utils.Enum"
local ItemBan = require "necro.game.item.ItemBan"

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

do
  local slotTable = {
    ACTION = entry(1, "Item"),
    SHOVEL = entry(2, "Shovel"),
    WEAPON = entry(3, "Weapon"),
    BODY   = entry(4, "Body"),
    HEAD   = entry(5, "Head"),
    FEET   = entry(6, "Feet"),
    TORCH  = entry(7, "Torch"),
    RING   = entry(8, "Ring"),
    MISC   = entry(9, "Misc"),
    SPELL  = entry(10, "Spells")
  }

  module.Slots = Enum.sequence(slotTable)
  module.SlotsBitmask = Enum.bitmask(slotTable)

  module.SlotPresets = Enum.sequence {
    ALL_SLOTS      = entry(0x3FF, "All slots"),
    ALL_BUT_WEAPON = entry(0x3FB, "All slots except weapon"),
    NO_SLOTS       = entry(0x000, "No slots")
  }
end

do
  local BanCombos = {
    ITEM_POOL   = ItemBan.Flag.PICKUP + ItemBan.Flag.GENERATE_ITEM_POOL,
    CRATE_POOL  = ItemBan.Flag.PICKUP + ItemBan.Flag.GENERATE_CRATE,
    SHRINE_POOL = ItemBan.Flag.PICKUP + ItemBan.Flag.GENERATE_SHRINE_POOL + ItemBan.Flag.GENERATE_TRANSACTION
  }

  module.Generators = Enum.sequence {
    UNWEIGHTED   = entry(0, "Unweighted", { bans = BanCombos.ITEM_POOL }),
    CHEST        = entry(1, "Chest", { bans = BanCombos.ITEM_POOL }),
    LOCKED_CHEST = entry(2, "Locked chest", { bans = BanCombos.ITEM_POOL }),
    SHOP         = entry(3, "Shop", { bans = BanCombos.ITEM_POOL }),
    LOCKED_SHOP  = entry(4, "Locked shop", { bans = BanCombos.ITEM_POOL }),
    URN          = entry(5, "Urn", { bans = BanCombos.CRATE_POOL }),
    RED_CHEST    = entry(6, "Red chest", { bans = BanCombos.ITEM_POOL }),
    PURPLE_CHEST = entry(7, "Purple chest", { bans = BanCombos.ITEM_POOL }),
    BLACK_CHEST  = entry(8, "Black chest", { bans = BanCombos.ITEM_POOL }),
    CONJURER     = entry(9, "Conjurer", { bans = BanCombos.SHRINE_POOL })
  }
end
--#endregion

return module
