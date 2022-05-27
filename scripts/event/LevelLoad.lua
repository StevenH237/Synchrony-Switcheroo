local Event       = require "necro.event.Event"
local GameSession = require "necro.client.GameSession"

local NixLib = require "NixLib.NixLib"

local SwSettings = require "Switcheroo.Settings"

---------------
-- VARIABLES --
--#region------

local lastFloor = nil

--#endregion (Variables)

---------------
-- FUNCTIONS --
--#region------

local function canRunHere()
  -- This function determines whether or not Switcheroo can run on the current floor.

  -- There are several factors that determine this.
end

--#endregion (Functions)

-------------------
-- EVENT HANDLER --
--#region----------

Event.levelload.add("switchBuilds", { order = "entities", sequence = -2 }, function(ev)
  if not canRunHere() then return end
end)

--#endregion
