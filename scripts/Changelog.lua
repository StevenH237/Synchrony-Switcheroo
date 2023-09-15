local Menu     = require "necro.menu.Menu"
local Settings = require "necro.config.Settings"

Settings.user.action {
  name = "View Switcheroo changelog",
  desc = "View changelogs for Switcheroo mod",
  id = "changelog",
  order = 0,
  autoRegister = true,
  action = function()
    Menu.open("changeLog", {
      fileNames = { "latest.md", "3.3.x.md", "3.x.x.md", "2.0.0.md", "1.x.x.md" },
      basePath = "mods/Switcheroo/changelogs/",
      index = 1
    })
  end
}