local Event = require "necro.event.Event"

Event.settingsPresetLoad.add("importOldSettings", { order = "editor", sequence = 1 }, function(ev)
  print(ev)
end)

Event.settingsPresetSave.add("importOldSettings", { order = "editor", sequence = 1 }, function(ev)
  print(ev)
end)
