---@diagnostic disable: need-check-nil
local CurrentLevel   = require "necro.game.level.CurrentLevel"
local Entities       = require "system.game.Entities"
local Event          = require "necro.event.Event"
local GameDLC        = require "necro.game.data.resource.GameDLC"
local GameSession    = require "necro.client.GameSession"
local Inventory      = require "necro.game.item.Inventory"
local ItemBan        = require "necro.game.item.ItemBan"
local ItemGeneration = require "necro.game.item.ItemGeneration"
local Object         = require "necro.game.object.Object"
local Player         = require "necro.game.character.Player"
local RNG            = require "necro.game.system.RNG"
local Snapshot       = require "necro.game.system.Snapshot"
local Try            = require "system.utils.Try"
local Utilities      = require "system.utils.Utilities"

local NixLib     = require "NixLib.NixLib"
local checkFlags = NixLib.checkFlags

-- local RNG        = require "Switcheroo.debug.RNG"
local SwEnum     = require "Switcheroo.Enum"
local SwSettings = require "Switcheroo.Settings"
local SwUtils    = require "Switcheroo.Utils"

---------------
-- VARIABLES --
--#region------

LastFloorBoss = Snapshot.runVariable(nil)
FirstGen      = Snapshot.runVariable(true)

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
  chances = {
    emptyChance = SwSettings.get("replacement.advancedEmptyChance"),
    emptyMinSlots = SwSettings.get("replacement.advancedEmptyMinSlots"),
    fullMinSlots = SwSettings.get("replacement.advancedFullMinSlots"),
    fullReplaceChance = SwSettings.get("replacement.advancedFullReplaceChance"),
    fullSelectChance = SwSettings.get("replacement.advancedFullSelectChance"),
    maxItems = SwSettings.get("replacement.advancedMaxItems"),
    maxSlots = SwSettings.get("replacement.advancedMaxSlots"),
    minItems = SwSettings.get("replacement.advancedMinItems"),
    minSlots = SwSettings.get("replacement.advancedMinSlots")
  }

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

  -- Are we on the fifth or greater floor of a zone, and it's a boss floor?
  if CurrentLevel.getFloor() >= 5 and CurrentLevel.isBoss() then
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
  elseif LastFloorBoss then
    return checkFlags(setting, SwEnum.AllowedFloors.EXTRA_POST_BOSSES)
  else
    return checkFlags(setting, SwEnum.AllowedFloors.EXTRA_OTHER_FLOORS)
  end
end

-- Resets soul link slot markers.
local function resetSoulLinkMarkers()
  -- Iterate over all existing soul link slot markers
  for ent in Entities.entitiesWithComponents({ "Switcheroo_soulLinkItemGen" }) do
    local slots = {}
    for slot in pairs(ent.soulLinkInventory.slots) do
      slots[slot] = ent.Switcheroo_soulLinkItemGen.defaultMark
    end
    ent.Switcheroo_soulLinkItemGen.slots = slots
  end
end

-- Gets all of the top-level soul link objects of which a given entity is a part.
local function getSoulLinks(ent)
  -- Soul links are part of an entity's equipment.
  if not ent.equipment then return nil end

  local links = {}
  -- For all entities in the equipment...
  for i, v in ipairs(Utilities.map(ent.equipment.items, Entities.getEntityByID)) do
    if v.soulLink then
      table.insert(links, SwUtils.getTopSoulLink(v))
    end
  end

  -- print(ent.name .. "#" .. ent.id .. " links:")
  -- print(links)

  return links
end

local function getCombinedMarkers(links)
  local slots = {}
  for i, marker in ipairs(links) do
    for slot, value in pairs(marker.Switcheroo_soulLinkItemGen.slots) do
      if value == SwEnum.SlotMark.CLOSED then
        slots[slot] = SwEnum.SlotMark.CLOSED
      elseif slots[slot] ~= SwEnum.SlotMark.CLOSED then
        slots[slot] = value
      end
    end
  end
  return slots
end

-- Converts a bitmask to its individual components as keys
local function slotsToSet(enum, value)
  local ret = {}
  for i, v in Utilities.sortedPairs(NixLib.bitSplit(value)) do
    if enum.names[v] then
      ret[enum.names[v]:lower()] = true
    end
  end
  return ret
end

-- Returns the RNG channel for a given player. If it doesn't exist yet, makes one.
local function channel(player)
  if GameDLC.isSynchronyLoaded() and player.Sync_possessable then
    player = Entities.getEntityByID(player.Sync_possessable.possessor)
  end

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

  -- This condition shouldn't fail, but I want to add more algorithms in
  -- the future, so I'm futureproofing for that.
  if algo == SwEnum.CharmsAlgorithm.ADD_ONE then
    local count = #(Inventory.getItemsInSlot(player, "misc"))

    return NixLib.median(count, count + SwSettings.get("charms.maxAdd"), SwSettings.get("charms.maxTotal"))
  end

  return 0
end

-- Closes TO_CLOSE slots in soul link item gen markers.
local function closeSoulLinkSlots(links, slots)
  for i, link in ipairs(links) do
    for slot, val in pairs(slots) do
      if val == SwEnum.SlotMark.TO_CLOSE then
        link.Switcheroo_soulLinkItemGen.slots[slot] = SwEnum.SlotMark.CLOSED
      end
    end
  end
end

-- Returns the allowed slots for changes
local function getAllowedSlots(player)
  -- Start with a list of the slots we can use
  local allowedSlotsVal = SwSettings.get("slots.allowed")
  local oneTimeSlotsVal = SwSettings.get("slots.oneTime")
  local unlockedSlotsVal = SwSettings.get("slots.unlocked")

  if not FirstGen then
    allowedSlotsVal = bit.band(allowedSlotsVal, bit.bnot(oneTimeSlotsVal))
    unlockedSlotsVal = bit.band(unlockedSlotsVal, bit.bnot(oneTimeSlotsVal))
  end

  local allowedSlots = slotsToSet(SwEnum.SlotsBitmask, allowedSlotsVal)
  local unlockedSlots = slotsToSet(SwEnum.SlotsBitmask, unlockedSlotsVal)

  local outEmpty = {}
  local outFull = {}

  -- Soul links! The slots may have already changed externally.
  -- So we should grab a list of links and the slots they affect.
  local soulLinks = getSoulLinks(player)
  local soulLinkSlots = getCombinedMarkers(soulLinks)

  -- Now let's run down through those slots.
  for slot in Utilities.sortedPairs(allowedSlots) do
    -- We'll do some special handling for misc/holster
    if slot == "holster" then
      goto nextSlot
    end

    -- If the slot is cursed and not unlocked, we'll move on
    if Inventory.isCursedSlot(player, slot) and not unlockedSlots[slot] then
      goto nextSlot
    end

    -- If the slot is synced and already closed, we'll also move on.
    if soulLinkSlots[slot] == SwEnum.SlotMark.CLOSED then
      goto nextSlot
    end

    -- Otherwise, if the slot is synced and open, we should mark it as "TO_CLOSE".
    if soulLinkSlots[slot] == SwEnum.SlotMark.OPEN then
      soulLinkSlots[slot] = SwEnum.SlotMark.TO_CLOSE
    end

    -- Now get subslots
    local cap

    if slot == "misc" then
      cap = getCharmCount(player)
    elseif (SwSettings.get("slots.reduce")) and slot ~= "misc" then
      cap = math.min(Inventory.getSlotCapacity(player, slot) or 999, SwSettings.get("slots.capacity"))
    else
      cap = NixLib.median(Inventory.getSlotCapacity(player, slot) or 999, SwSettings.get("slots.capacity"), #Inventory)
    end

    -- Get the filled subslots first
    local items = Inventory.getItemsInSlot(player, slot)
    local index = 0

    for i, item in ipairs(items) do
      index = i

      -- Is this an item we can remove?
      local snt = item.Switcheroo_noTake
      if snt and not (snt.unlessGiven and item.Switcheroo_tracker.wasGiven) then
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
      if content == 0 then
        outEmpty[#outEmpty + 1] = {
          slotName = "holster",
          holster = hudItem
        }
      else
        -- Is this an item we can remove?
        local heldItem = Entities.getEntityByID(content)
        if heldItem then
          local snt = heldItem.Switcheroo_noTake
          if not (snt and not (snt.unlessGiven and heldItem.Switcheroo_tracker.wasGiven)) then
            outFull[#outFull + 1] = {
              slotName = "holster",
              holster = hudItem,
              contents = heldItem
            }
          end
        end
      end
    end
  end

  -- Lastly, for soul links, close the TO_CLOSE slots.
  closeSoulLinkSlots(soulLinks, soulLinkSlots)

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

local function getChoiceOpts(player, slot)
  local choiceOpts = {
    -- banMask = see below,
    -- default = see below,
    channel = channel(player),
    slot = slot,
    excludedComponents = { "Switcheroo_noGive" },
    depletionLimit = math.huge
  }

  -- Are we checking bans?
  choiceOpts.banMask = 0
  choiceOpts.player = player

  -- Dynamic gold ban checking
  if player.goldCounter and player.goldCounter.amount == 0 then
    table.insert(choiceOpts.excludedComponents, "Switcheroo_noGiveIfBroke")
  end

  if not checkFlags(SwSettings.get("slots.unlocked"), SwEnum.SlotsBitmask[slot:upper()]) then
    choiceOpts.banMask = ItemBan.Flag.GENERATE_ITEM_POOL + ItemBan.Flag.GENERATE_TRANSACTION
  end

  if SwSettings.get("dontGive.deadlyItems") then
    choiceOpts.banMask = bit.bor(choiceOpts.banMask, ItemBan.Flag.PICKUP_DEATH)
  end

  return choiceOpts
end

-- This function generates a random item for a slot.
local function generateItem(player, slot, isHolster)
  -- Loop through all allowed item pools
  local pools = SwSettings.get("generators")

  for i, v in ipairs(pools) do
    local choiceOpts = getChoiceOpts(player, slot)
    choiceOpts.itemPool = v
    local item = ItemGeneration.choice(choiceOpts)
    if item ~= nil then
      return item
    end
  end

  -- Unweighted
  if SwSettings.get("generatorFallback") then
    local choiceOpts = getChoiceOpts(player, slot)
    choiceOpts.itemPool = nil
    choiceOpts.chanceFunction = function() return 1 end
    local item = ItemGeneration.choice(choiceOpts)
    if item ~= nil then
      return item
    end
  end

  -- And do we have a default?
  if not isHolster then
    local default = SwSettings.get("defaults." .. slot)
    if default ~= "Switcheroo_NoneItem" then
      return default
    end
  end

  return nil
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
    if slot.remove then
      -- We specifically indicated we'd be removing an item:
      newItem = false
    elseif max == 0 then
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

    local holsterSlot = nil
    local holster = nil
    -- If we're in a holster, swap it and deal with the original slot.
    if slot.slotName == "holster" then
      holsterSlot = slot
      holster = slot.holster
      slot = {
        slotName = holster.itemHolster.slot,
        index = 1,
        contents = holsterSlot.contents
      }
      Inventory.swapWithHolster(player, holster)
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

      -- Debug
      -- print(player.name .. " loses " .. oldItem.name)

      -- Now delete old item.
      Object.delete(oldItem)
    end

    -- Now, if we're giving a new item, actually give it to them.
    local newEntity
    if newItem then
      if newItemType then
        newEntity = Inventory.grant(newItemType, player)
      else
        newEntity = Inventory.grant(generateItem(player, slot.slotName), player)
      end
      min = min - 1
      max = max - 1
    else
      -- Is there a default for the slot?
      local default = SwSettings.get("defaults." .. slot.slotName)
      if default ~= "Switcheroo_NoneItem" and default ~= nil then
        newEntity = Inventory.grant(default, player)
      end
    end

    if newEntity then
      -- Debug
      -- print(player.name .. " gains " .. newEntity.name)
      if newEntity.Switcheroo_noTake then
        newEntity.Switcheroo_noTake.wasGiven = true
      end

      -- Always track whether given, too.
      newEntity.Switcheroo_tracker.wasGiven = true

      newEntity.itemNegateLowPercent.active = false
    end

    if holsterSlot then
      Inventory.swapWithHolster(player, holster)
    end
  end
end

-- This function actually handles everything!
local function switchBuild(p)
  -- Stair immunity prevents pain-on-equip items from causing pain.
  local ddi = p.descentDamageImmunity.active
  p.descentDamageImmunity.active = true

  Try.catch(function()
    -- First, we need to figure out which slots *can be* selected.
    local emptySlots, fullSlots = getAllowedSlots(p)

    -- Let's take a shortcut if that resulted in nothing.
    if #emptySlots + #fullSlots == 0 then return end

    -- Now let's actually select the slots.
    -- Unlike in switcheroo v1, we won't handle clearing them here.
    local slots = selectSlots(p, emptySlots, fullSlots)

    -- And now let's deal with taking and giving items, as necessary.
    changeItemsInSlots(p, slots)
  end)

  p.descentDamageImmunity.active = ddi
end

--#endregion (Functions)

-------------------
-- EVENT HANDLER --
--#region----------

Event.levelLoad.add("switchBuilds", { order = "enemySubstitutions", sequence = -1 }, function(ev)
  if not canRunHere() then goto noRun end

  -- Debug
  -- print("Starting for " .. CurrentLevel.getDepth() .. "-" .. CurrentLevel.getFloor())

  mapChanceSettings()

  -- This is some new code for soul links!
  -- We'll need to reset all the soul link slot markers.
  resetSoulLinkMarkers()

  for i, p in ipairs(Player.getPlayerEntities()) do
    switchBuild(p)
  end

  FirstGen = false

  ::noRun::
  LastFloorBoss = CurrentLevel.isBoss()
end)

Event.objectSpawn.add("giveDadBuild", { order = "merge", filter = "dad", sequence = 1 }, function(ev)
  if not canRunHere() then return end

  switchBuild(ev.entity)
end)

--#endregion