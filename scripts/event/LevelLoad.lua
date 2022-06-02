local CurrentLevel = require "necro.game.level.CurrentLevel"
local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local GameSession  = require "necro.client.GameSession"
local Inventory    = require "necro.game.item.Inventory"
local ItemBan      = require "necro.game.item.ItemBan"
local Player       = require "necro.game.character.Player"
local RNG          = require "necro.game.system.RNG"
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
-- CONSTANTS --
--#region------

--#endregion (Constants)

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

-- Returns the RNG channel for a given player. If it doesn't exist yet, makes one.
local function channel(player)
  local ent = player.Switcheroo_randomizer.entity

  if ent == nil then
    ent = Entities.spawn("Switcheroo_RandomChannel")
    player.Switcheroo_randomizer.entity = ent
  end

  return ent
end

-- Returns the number of charms that should be generated on this floor.
local function getCharmCount(player)
  local algo = SwSettings.get("charms.algorithm")
  local chan = channel(player)
  local floor = CurrentLevel.getSequentialNumber()

  if algo == SwEnum.CharmsAlgorithm.DICE_BASED then
    local dice = math.floor(SwSettings.get("charms.diceCount") + SwSettings.get("charms.dicePerFloor") * floor)
    local sides = math.max(math.floor(SwSettings.get("charms.diceSides") + SwSettings.get("charms.diceSidesPerFloor") * floor), 2)
    local rolled = {}
    local sum = 0

    for i = 1, dice do
      rolled[#rolled + 1] = RNG.int(sides, chan) + 1
    end

    table.sort(rolled)

    -- Drop some dice
    local drop = SwSettings.get("charms.diceDrop")
    local dropHigh = drop > 0
    if dropHigh then
      for i = 1, dropHigh do
        table.remove(rolled)
      end
    else
      for i = -dropHigh, -1 do
        table.remove(rolled, 1)
      end
    end

    for i, v in ipairs(rolled) do
      sum = sum + v
    end

    -- Add a static amount
    sum = sum + SwSettings.get("charms.diceAddStatic") + math.floor(SwSettings.get("charms.diceAddPerFloor") * floor)

    return sum
  elseif algo == SwEnum.CharmsAlgorithm.ADD_ONE then
    local count = #(Inventory.getItemsInSlot(player, "misc"))

    return NixLib.median(count, count + SwSettings.get("charms.madAdd"), SwSettings.get("charms.maxTotal"))
  end

  return 0
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
    if slot == "holster" then
      goto nextSlot
    end

    -- If the slot is cursed and not unlocked, we'll move on
    if Inventory.isCursedSlot(player, slot) and not unlockedSlots[slot] then
      goto nextSlot
    end

    -- Now get subslots
    local cap

    if slot == "misc" then
      cap = getCharmCount(player)
    elseif (SwSettings.get("slots.reduce")) and slot ~= "misc" then
      cap = math.max(Inventory.getSlotCapacity(player, slot), SwSettings.get("slots.capacity"))
    else
      cap = NixLib.median(Inventory.getSlotCapacity(player, slot), SwSettings.get("slots.capacity"), #Inventory)
    end

    -- Get the filled subslots first
    local items = Inventory.getItemsInSlot(player, slot)
    local index = 0

    for i, item in ipairs(items) do
      index = i

      -- Is this an item we can remove?
      local sng = item.Switcheroo_noGive
      if sng and not (sng.unlessGiven and sng.wasGiven) then
        goto nextSubslot
      end

      if not unlockedSlots[slot] then
        if ItemBan.isBanned(player, item, ItemBan.Flag.LOSS_DROP) then
          goto nextSubslot
        end
      end

      out[#out + 1] = {
        slotName = slot,
        index = index,
        contents = item
      }

      if i > cap then
        out[#out].remove = true
      end

      ::nextSubslot::
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

    if allowedSlots.holster then
      -- Get hud item
      local hudItem = Inventory.getItemInSlot(player, "hud", 1)
      if hudItem.itemHolster then
        local content = hudItem.itemHolster.content
        if content == nil then
          out[#out + 1] = {
            slotName = "holster",
            container = hudItem
          }
        else
          local heldItem = Entities.getEntityByID(content)
          out[#out + 1] = {
            slotName = "holster",
            container = hudItem,
            contents = heldItem
          }
        end
      end
    end

    ::nextSlot::
  end

  return out
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
