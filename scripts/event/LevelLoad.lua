local CurrentLevel = require "necro.game.level.CurrentLevel"
local Event        = require "necro.event.Event"
local GameSession  = require "necro.client.GameSession"
local Inventory    = require "necro.game.item.Inventory"
local Player       = require "necro.game.character.Player"
local Snapshot     = require "necro.game.system.Snapshot"
local Try          = require "system.utils.Try"

local NixLib     = require "NixLib.NixLib"
local checkFlags = NixLib.checkFlags

local SwEnum     = require "Switcheroo.Enum"
local SwSettings = require "Switcheroo.Settings"

---------------
-- VARIABLES --
--#region------

local lastFloorBoss = Snapshot.runVariable(nil)
local firstGen      = Snapshot.runVariable(true)

--#endregion (Variables)

---------------
-- FUNCTIONS --
--#region------

-- Returns whether or not the mod can run on the present floor.
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

-- Converts a bitmask to its individual components as keys
local function slotsToSet(enum, value)
  local ret = {}
  for i, v in pairs(NixLib.bitSplit(value)) do
    ret[enum.names[v]:lower()] = true
  end
  return ret
end

-- Returns the allowed slots for changes
local function getAllowedSlots(player)
  -- Start with a list of the slots we can use
  local allowedSlotsVal = SwSettings.get("slots.allowed")
  local oneTimeSlotsVal = SwSettings.get("slots.once")
  local unlockedSlotsVal = SwSettings.get("slots.unlocked")

  if not firstGen then
    allowedSlotsVal = bit.band(allowedSlotsVal, bit.bnot(oneTimeSlotsVal))
    unlockedSlotsVal = bit.band(unlockedSlotsVal, bit.bnot(oneTimeSlotsVal))
  end

  local allowedSlots = slotsToSet(SwEnum.SlotsBitmask, allowedSlotsVal)
  local unlockedSlots = slotsToSet(SwEnum.SlotsBitmask, unlockedSlotsVal)

  local out = {}

  -- Now let's run down through those slots.
  for slot in pairs(allowedSlots) do
    -- We'll do some special handling for misc/holster
    if slot == "misc" or slot == "holster" then
      goto nextSlot
    end

    -- If the slot is cursed and not unlocked, we'll move on
    if Inventory.isCursedSlot(player, slot) then
      goto nextSlot
    end

    -- Now get subslots
    local cap
    if (SwSettings.get("slots.reduce")) then
      cap = math.max(Inventory.getSlotCapacity(), SwSettings.get("slots.capacity"))
    else
      cap = NixLib.median(Inventory.getSlotCapacity(), SwSettings.get("slots.capacity"), #Inventory)
    end

    -- Get the filled subslots first
    local items = Inventory.getItemsInSlot(player, slot)
    local index = 0

    for i, item in ipairs(items) do
      index = i
      out[#out + 1] = {
        slotName = slot,
        index = index,
        contents = item
      }
    end

    -- Now the empty subslots
    if index < cap then
      for i = index + 1, cap do
        out[#out + 1] = {
          slotName = slot,
          index = index
        }
      end
    end

    ::nextSlot::
  end
end

--#endregion (Functions)

-------------------
-- EVENT HANDLER --
--#region----------

Event.levelLoad.add("switchBuilds", { order = "entities", sequence = -2 }, function(ev)
  if not canRunHere() then goto noRun end

  Try.catch(function()
    for i, p in ipairs(Player.getPlayerEntities()) do
      -- Stair immunity prevents pain-on-equip items from causing pain.
      p.descentDamageImmunity.active = true

      -- First, we need to figure out which slots *can be* selected.
      local slots = getAllowedSlots(p)

      p.descentDamageImmunity.active = false
    end
  end)

  firstGen = false

  ::noRun::
  lastFloorBoss = CurrentLevel.isBoss()
end)

--#endregion
