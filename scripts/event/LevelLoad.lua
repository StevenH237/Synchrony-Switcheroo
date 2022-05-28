local CurrentLevel = require "necro.game.level.CurrentLevel"
local Event        = require "necro.event.Event"
local GameSession  = require "necro.client.GameSession"
local Try          = require "system.utils.Try"

local NixLib     = require "NixLib.NixLib"
local checkFlags = NixLib.checkFlags

local SwEnum     = require "Switcheroo.Enum"
local SwSettings = require "Switcheroo.Settings"

---------------
-- VARIABLES --
--#region------

local lastFloorBoss = nil

--#endregion (Variables)

---------------
-- FUNCTIONS --
--#region------

local function canRunHere()
  -- This function determines whether or not Switcheroo can run on the current floor.
  -- There are several factors that determine this.

  -- First of all, what mode are we in?
  local mode = GameSession.getCurrentModeID()

  -- Don't activate in the lobby.
  if mode == "Lobby" then return false end

  local setting = SwSettings.get("allowedFloors")

  -- In training, that specific flag must be on.
  if mode == "Training" then
    return checkFlags(setting, SwEnum.AllowedFloors.TRAINING_FLOORS)
  end

  -- Is this the first floor loaded?
  -- The 1-1 setting is always used for first floor, whether custom or not.
  local seq = CurrentLevel.getSequentialNumber()
  if seq == 1 then
    return checkFlags(setting, SwEnum.AllowedFloors.DEPTH_1_LEVEL_1)
  end

  -- Are we in the first 20 floors and using raw floor numbers?
  if seq <= 20 and checkFlags(setting, SwEnum.AllowedFloors.RAW_FLOOR_NUMBERS) then
    return checkFlags(setting, 2 ^ (seq - 1))
  end

  -- Are we in a custom dungeon or using random floors?
  if mode == "CustomDungeon" or NixLib.getModVersion("RandomFloors") then
    goto customDungeonRules
  end

  -- Are we on the final floor, being the fifth floor of a zone, *and* it's a boss floor?
  if CurrentLevel.getFloor() == 5
      and CurrentLevel.getNumber() == CurrentLevel.getDungeonLength()
      and CurrentLevel.isBoss() then
    return checkFlags(setting, SwEnum.AllowedFloors.EXTRA_BOSS)
  end

  -- Are we in one of the first five zones, and one of the first four floors of that zone?
  if CurrentLevel.getDepth() >= 1 and CurrentLevel.getDepth() <= 5
      and CurrentLevel.getFloor() >= 1 and CurrentLevel.getFloor() <= 4 then
    local floor = CurrentLevel.getDepth() * 4 + CurrentLevel.getFloor() - 5
    return checkFlags(setting, 2 ^ floor)
  end

  -- Otherwise, we should just use custom dungeon/extra zone rules.
  ::customDungeonRules::
  if CurrentLevel.isBoss() then
    return checkFlags(setting, SwEnum.AllowedFloors.EXTRA_BOSS_FLOORS)
  elseif lastFloorBoss then
    return checkFlags(setting, SwEnum.AllowedFloors.EXTRA_POST_BOSSES)
  else
    return checkFlags(setting, SwEnum.AllowedFloors.EXTRA_OTHER_FLOORS)
  end
end

--#endregion (Functions)

-------------------
-- EVENT HANDLER --
--#region----------

Event.levelload.add("switchBuilds", { order = "entities", sequence = -2 }, function(ev)
  if not canRunHere() then goto noRun end

  Try.catch(function()

  end)

  ::noRun::
  lastFloorBoss = CurrentLevel.isBoss()
end)

--#endregion
