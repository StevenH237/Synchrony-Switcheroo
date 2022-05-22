local Components = require "necro.game.data.Components"

Components.register {
  Switcheroo_noGive = {},
  Switcheroo_noTake = {
    Components.constant.bool("unlessGiven", false),
    Components.field.bool("wasGiven", false)
  }
}
