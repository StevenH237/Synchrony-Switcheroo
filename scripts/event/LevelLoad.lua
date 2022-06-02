local CurrentLevel   = require "necro.game.level.CurrentLevel"
local Entities       = require "system.game.Entities"
local Event          = require "necro.event.Event"
local GameSession    = require "necro.client.GameSession"
local Inventory      = require "necro.game.item.Inventory"
local ItemBan        = require "necro.game.item.ItemBan"
local ItemGeneration = require "necro.game.item.ItemGeneration"
local Player         = require "necro.game.character.Player"
local RNG            = require "necro.game.system.RNG"
local Snapshot       = require "necro.game.system.Snapshot"
local Try            = require "system.utils.Try"

local NixLib     = require "NixLib.NixLib"
local checkFlags = NixLib.checkFlags

local SwEnum     = require "Switcheroo.Enum"
local SwSettings = require "Switcheroo.Settings"

---------------
-- VARIABLES --
--#region------

local lastFloorBoss = Snapshot.runVariable(nil)
local firstGen      = Snapshot.runVariable(true)

-- Not snapshots, just temp variables
local chances

--#endregion (Variables)

---------------
-- CONSTANTS --
--#region------

--#endregion (Constants)

---------------
-- FUNCTIONS --
--#region------

-- Maps simple settings onto advanced.
local function mapChanceSettings()
  if SwSettings.get("replacement.advanced") then
    chances = {
      emptyChance = SwSettings.get("replacement.advancedEmptyChance"),
      emptyMinSlots = SwSettings.get("replacement.advancedEmptyMinSlots"),
      fullMinSlots = SwSettings.get("replacement.fullMinSlots"),
      fullReplaceChance = SwSettings.get("replacement.advancedFullReplaceChance"),
      fullSelectChance = SwSettings.get("replacement.advancedFullSelectChance"),
      maxItems = SwSettings.get("replacement.advancedMaxItems"),
      maxSlots = SwSettings.get("replacement.advancedMaxSlots"),
      minItems = SwSettings.get("replacement.advancedMinItems"),
      minSlots = SwSettings.get("replacement.advancedMinSlots")
    }
  else
    chances = {
      emptyChance = SwSettings.get("replacement.simpleChance"),
      emptyMinSlots = 0,
      fullMinSlots = 0,
      fullReplaceChance = 1,
      fullSelectChance = SwSettings.get("replacement.simpleChance"),
      maxItems = -1,
      maxSlots = -1,
      minItems = 0,
      minSlots = 0
    }

    if SwSettings.get("replacement.simpleMode") == SwEnum.ReplaceMode.EXISTING then
      chances.emptyChance = 0
    elseif SwSettings.get("replacement.simpleMode") == SwEnum.ReplaceMode.EMPTY then
      chances.fullSelectChance = 0
    end
  end

  if chances.maxSlots == -1 then
    chances.maxSlots = math.huge
  end

  if chances.maxItems == -1 then
    chances.maxItems = math.huge
  end
end

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
      for i = 1, drop do
        table.remove(rolled)
      end
    else
      for i = -drop, -1 do
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

  local outEmpty = {}
  local outFull = {}

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

      outFull[#outFull + 1] = {
        slotName = slot,
        index = index,
        contents = item
      }

      if i > cap then
        outFull[#outFull].remove = true
      end

      ::nextSubslot::
    end

    -- Now the empty subslots
    if index < cap then
      for i = index + 1, cap do
        outEmpty[#outEmpty + 1] = {
          slotName = slot,
          index = index
        }
      end
    end

    ::nextSlot::
  end

  if allowedSlots.holster then
    -- Get hud item
    local hudItem = Inventory.getItemInSlot(player, "hud", 1)
    if hudItem and hudItem.itemHolster then
      local content = hudItem.itemHolster.content
      if content == nil then
        outEmpty[#outEmpty + 1] = {
          slotName = "holster",
          container = hudItem
        }
      else
        -- Is this an item we can remove?
        local heldItem = Entities.getEntityByID(content)
        local sng = heldItem.Switcheroo_noGive
        if not (sng and not (sng.unlessGiven and sng.wasGiven)) then
          outFull[#outFull + 1] = {
            slotName = "holster",
            holster = hudItem,
            contents = heldItem
          }
        end
      end
    end
  end

  return outEmpty, outFull
end

-- Actually selects slots to be randomized
local function selectSlots(player, emptySlots, fullSlots)
  local out = {}
  local rngChan = channel(player)
  local mergedSlots = {}

  -- Guaranteed empty slots
  if chances.emptyMinSlots >= #emptySlots then
    while #emptySlots > 0 do
      table.insert(out, table.remove(emptySlots, 1))
    end
  elseif chances.emptyMinSlots > 0 then
    RNG.shuffle(emptySlots, rngChan)
    for i = 1, chances.emptyMinSlots do
      table.insert(out, table.remove(emptySlots, 1))
    end
  end

  -- And clear it if the other slots have no chance of being selected
  if chances.emptyChance == 0 then
    emptySlots = {}
  end

  -- Guaranteed full slots
  if chances.fullMinSlots >= #fullSlots then
    while #fullSlots > 0 do
      table.insert(out, table.remove(fullSlots, 1))
    end
  elseif chances.fullMinSlots > 0 then
    RNG.shuffle(fullSlots, rngChan)
    for i = 1, chances.fullMinSlots do
      table.insert(out, table.remove(fullSlots, 1))
    end
  end

  -- And clear it if the other slots have no chance of being selected
  if chances.fullSelectChance == 0 then
    fullSlots = {}
  end

  -- Shortcut 1: If the output matches or exceeds the maximum, stop here.
  if #out >= chances.maxSlots then
    return out
  end

  -- Shortcut 2: If both lists are empty, stop here.
  -- Also, if one list is empty, the merged list should be the other.
  -- Otherwise, merge the lists one by one.
  if #emptySlots == 0 then
    if #fullSlots == 0 then
      return out
    else
      mergedSlots = fullSlots
    end
  else
    mergedSlots = emptySlots
    while #fullSlots > 0 do
      table.insert(mergedSlots, table.remove(fullSlots, 1))
    end
  end

  -- Shuffle the merged list.
  RNG.shuffle(mergedSlots, rngChan)

  -- Now loop the remaining slots.
  while #mergedSlots > 0 do
    -- If we've hit the maximum, we again need to stop.
    if #out == chances.maxSlots then
      return out
    end

    -- If we're at the minimum, we don't calculate chances.
    -- Instead, just move all slots over.
    -- We can use another while loop outside this one because it checks conditions.
    if #out + #mergedSlots <= chances.minSlots then
      break
    end

    -- Otherwise, yeah, time to calculate chances.
    local slot = table.remove(mergedSlots, 1)
    local pass = false

    -- This is how we check if a slot is full.
    if slot.contents then
      pass = RNG.roll(chances.fullSelectChance, rngChan)
    else
      pass = RNG.roll(chances.emptyChance, rngChan)
    end

    if pass then
      table.insert(out, slot)
    end
  end

  -- If we hit the "break" above, this loop will run.
  -- It'll dump all remaining slots into the output.
  while #mergedSlots > 0 do
    table.insert(out, table.remove(mergedSlots, 1))
  end

  return out
end

-- This function generates a random item for a slot.
local function generateItem(player, slot)
  local choiceOpts = {
    -- banMask = see below,
    -- itemPool = TODO add support for this,
    -- default = see below,
    channel = channel(player),
    slot = slot,
    excludedComponents = { "Switcheroo_noGive" },
    chanceType = SwEnum.Generators.names[SwSettings.get("generator")]:lower(),
    depletionLimit = math.huge
  }

  -- Are we checking bans?
  choiceOpts.banMask = 0
  choiceOpts.player = player

  if not checkFlags(SwSettings.get("slots.unlocked"), SwEnum.SlotsBitmask[slot:upper()]) then
    choiceOpts.banMask = SwEnum.Generators.data[SwSettings.get("generator")].bans
  end

  if SwSettings.get("dontGive.deadlyItems") then
    choiceOpts.banMask = bit.bor(choiceOpts.banMask, ItemBan.Flag.PICKUP_DEATH)
  end

  -- And do we have a default?
  if SwSettings.get("defaults." .. slot) ~= "Switcheroo_NoneItem" then
    choiceOpts.default = SwSettings.get("defaults." .. slot)
  end

  return ItemGeneration.choice(choiceOpts)
end

-- This function actually (clears, if necessary, and re)stocks selected slots.
local function changeItemsInSlots(player, slots)
  local min = chances.minItems
  local max = chances.maxItems
  local chance = chances.fullReplaceChance
  local rngChan = channel(player)

  RNG.shuffle(slots, rngChan)

  while #slots > 0 do
    local slot = table.remove(slots, 1)
    local newItem = false

    -- Figure out if a new item should be generated.
    if max == 0 then
      -- We've hit the maximum:
      newItem = false
    elseif min >= (#slots + 1) then
      -- We have to give one to every remaining slot to meet the minimum:
      newItem = true
    elseif not slot.contents then
      -- The slot was empty:
      newItem = true
    else
      -- Otherwise:
      newItem = RNG.roll(chance, rngChan)
    end

    -- Now get rid of the old item.
    -- First, we should check if there's a guaranteed transmute outcome
    -- (and if we're honoring that).
    local oldItem = slot.contents
    local newItemType = nil
    if oldItem then
      if newItem and oldItem.itemTransmutableFixedOutcome and SwSettings.get("guarantees") then
        newItemType = oldItem.itemTransmutableFixedOutcome.target
      end

      -- Now delete old item.
      Entities.despawn(oldItem.id)
    end

    -- Now, if we're giving a new item, actually give it to them.
    if newItem then
      if newItemType then
        Inventory.grant(newItemType, player)
      else
        Inventory.grant(generateItem(player, slot.slotName), player)
      end
      min = min - 1
      max = max - 1
    else
      -- Is there a default for the slot?
      local default = SwSettings.get("defaults." .. slot)
      if default ~= "Switcheroo_NoneItem" then
        Inventory.grant(default, player)
      end
    end
  end
end

--#endregion (Functions)

-------------------
-- EVENT HANDLER --
--#region----------

Event.levelLoad.add("switchBuilds", { order = "entities", sequence = -2 }, function(ev)
  if not canRunHere() then goto noRun end

  mapChanceSettings()

  Try.catch(function()
    for i, p in ipairs(Player.getPlayerEntities()) do
      -- Stair immunity prevents pain-on-equip items from causing pain.
      p.descentDamageImmunity.active = true

      -- First, we need to figure out which slots *can be* selected.
      local emptySlots, fullSlots = getAllowedSlots(p)

      -- Let's take a shortcut if that resulted in nothing.
      if #emptySlots + #fullSlots == 0 then return end

      -- Now let's actually select the slots.
      -- Unlike in switcheroo v1, we won't handle clearing them here.
      local slots = selectSlots(p, emptySlots, fullSlots)

      -- And now let's deal with taking and giving items, as necessary.
      changeItemsInSlots(p, slots)

      p.descentDamageImmunity.active = false
    end
  end)

  firstGen = false

  ::noRun::
  lastFloorBoss = CurrentLevel.isBoss()
end)

--#endregion
