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
