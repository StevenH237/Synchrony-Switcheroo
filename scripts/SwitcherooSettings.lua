--#region Imports
local GameDLC = require "necro.game.data.resource.GameDLC"

local PowerSettings = require "PowerSettings.PowerSettings"
--#endregion Imports

---------------
-- FUNCTIONS --
--#region------

local function get(setting)
  return PowerSettings.get("mod.Switcheroo." .. setting)
end

--#endregion

----------------
-- FORMATTERS --
--#region-------

--#endregion

--------------
-- ENABLERS --
--#region-----

local function isAmplified()
  return GameDLC.isAmplifiedLoaded()
end

--#endregion Enablers

-------------
-- ACTIONS --
--#region----

--#endregion

--------------
-- SETTINGS --
--#region-----
