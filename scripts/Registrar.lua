local Components     = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"

local SwEnum = require "Switcheroo.Enum"

Components.register {
  Switcheroo_noGive = {},
  Switcheroo_noGiveIfBroke = {},
  Switcheroo_noTake = {
    Components.constant.bool("unlessGiven", false),
    Components.field.bool("wasGiven", false) -- DEPRECATED
  },
  Switcheroo_tracker = {
    Components.field.bool("wasGiven", false)
  },
  Switcheroo_randomizer = {
    Components.field.entityID("entity")
  },
  Switcheroo_itemPoolSwitcheroo = {
    Components.constant.table("weights", { 1 })
  },
  Switcheroo_soulLinkItemGen = {
    Components.field.table("slots", {}),
    Components.constant.enum("defaultMark", SwEnum.SlotMark, SwEnum.SlotMark.OPEN)
  }
}

CustomEntities.register {
  name = "Switcheroo_RandomChannel",
  random = {}
}

CustomEntities.register {
  name = "Switcheroo_NoneItem",
  friendlyName = {
    name = "(None)"
  }
}
