local Components     = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"

Components.register {
  Switcheroo_noGive = {},
  Switcheroo_noTake = {
    Components.constant.bool("unlessGiven", false),
    Components.field.bool("wasGiven", false)
  },
  Switcheroo_randomizer = {
    Components.field.entityID("entity")
  },
  Switcheroo_itemPoolSwitcheroo = {
    Components.constant.table("weights", { 1 })
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
