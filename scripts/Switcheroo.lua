local Currency        = require "necro.game.item.Currency"
local CurrentLevel    = require "necro.game.level.CurrentLevel"
local Entities        = require "system.game.Entities"
local Enum            = require "system.utils.Enum"
local Event           = require "necro.event.Event"
local Inventory       = require "necro.game.item.Inventory"
local ItemBan         = require "necro.game.item.ItemBan"
local ItemGeneration  = require "necro.game.item.ItemGeneration"
local Menu            = require "necro.menu.Menu"
local Player          = require "necro.game.character.Player"
local RNG             = require "necro.game.system.RNG"
local RunState        = require "necro.game.system.RunState"
local Settings        = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local Try             = require "system.utils.Try"
local Utilities       = require "system.utils.Utilities"

local Slots   = {"Head", "Shovel", "Feet", "Weapon", "Body", "Torch", "Ring", "Item", "Spells", "Charms"}
local SlotIDs = {"Head", "Shovel", "Feet", "Weapon", "Body", "Torch", "Ring", "Action", "Spell", "Misc"}

local GenTypes = {"chest", "lockedChest", "shop", "lockedShop", "urn", "redChest", "purpleChest", "blackChest", "secret"}
local GenFlags = {32768, 32768, 32768, 32768, 65536, 32768, 32768, 32768, 2359296}

local nonPool     = {RingWonder=true, CharmLuck=true, MiscPotion=true}
local neverDelete = {SpellTransform=true}
local instakill   = {RingBecoming=true, HeadGlassJaw=true}

-- NOTE: This mod adds the player number to this channel so that rolls can remain the same per player.
-- For example, player 1 uses channel 23701, player 2 uses 23702, etc.
local rngChannel = 23700
local function getChannel(playerNum)
  return rngChannel + playerNum -- TODO replace this with entity-based system
end

-----------
-- ENUMS --
-----------

local enumGenType = Enum.sequence {
  CHEST=1,
  LOCKED_CHEST=2,
  SHOP=3,
  LOCKED_SHOP=4,
  URN=5,
  RED_CHEST=6,
  PURPLE_CHEST=7,
  BLACK_CHEST=8,
  CONJURER=9
}

local slotType = Enum.sequence {
  NO=0,
  YES=1,
  UNLOCKED=2
}

----------------------
-- SETTINGS SECTION --
----------------------
do
  local function setFloors(data)
    for z, zdata in ipairs(data) do
      for l, v in ipairs(zdata) do
        SettingsStorage.set("mod.Switcheroo.floors.l" .. z .. l, v, Settings.Layer.REMOTE_PENDING)
      end
    end

    Menu.close()
  end

  local function noLimit(value)
    return value == -1 and "No limit" or value
  end

  GroupChance = Settings.group {
    name="Slot chances",
    id="chance",
    desc="Chances and min/max of slots being picked and filled",
    order=0
  }

  do
    EmptySlotChance = Settings.shared.percent {
      name="Empty slot pick chance",
      id="chance.empty",
      desc="Chance that an empty slot is picked to receive an item.",
      default=1,
      minimum=0,
      maximum=1,
      step=0.25,
      order=0
    }

    FilledSlotChance = Settings.shared.percent {
      name="Filled slot pick chance",
      id="chance.filled",
      desc="Chance that an occupied slot is cleared and picked to receive an item.",
      default=1,
      minimum=0,
      maximum=1,
      step=0.25,
      order=1
    }

    SlotFillChance = Settings.shared.percent {
      name="Slot fill chance",
      id="chance.new",
      desc="Chance that a selected slot receives an item; if it fails, the slot becomes blank.",
      default=1,
      minimum=-0.05,
      maximum=1,
      step=0.05,
      order=2
    }

    SlotMinimum = Settings.shared.number {
      name="Minimum slots",
      id="chance.minimum",
      desc="Minimum number of slots to fill.",
      default=0,
      minimum=0,
      maximum=10000,
      step=1,
      order=3
    }

    SlotMaximum = Settings.shared.number {
      name="Maximum slots",
      id="chance.maximum",
      desc="Maximum number of slots to fill, or -1 for no limit",
      default=-1,
      minimum=-1,
      maximum=10000,
      step=1,
      format=noLimit,
      order=4
    }
  end

  GroupSlots = Settings.group {
    name="Allowed slots",
    id="slots",
    desc="Which slots can be selected and overridden by the mod",
    order=1
  }

  -- This loop generates a toggle for every slot.
  for i, v in ipairs(SlotIDs) do
    _G["Slot" .. v .. "Allowed"] = Settings.shared.enum {
      name=Slots[i],
      id="slots." .. v:lower(),
      desc="Can the mod override the " .. Slots[i]:lower() .. "  slot",
      order=i,
      enum=slotType,
      default=slotType.YES
    }
  end

  GroupCharms = Settings.group {
    name="Charms settings",
    id="charms",
    desc="Settings relating to Misc (Charms) slots",
    order=1.5
  }

  do
    MaxNewCharms = Settings.shared.number {
      name="Max new charms",
      id="charms.new",
      desc="How many new charms can be added per floor?",
      default=1,
      minimum=0,
      maximum=100,
      order=1
    }

    MaxCharmsForNew = Settings.shared.number {
      name="Max charms from new",
      id="charms.max",
      desc="How many charms are allowed without collecting more outside the mod?",
      default=5,
      minimum=-1,
      maximum=100,
      format=noLimit,
      order=2
    }
  end

  GroupFloors = Settings.group {
    name="Allowed floors",
    id="floors",
    desc="On which floors should the mod activate?",
    order=2
  }

  do
    GroupFloorPresets = Settings.group {
      name="Select preset",
      id="floors.preset",
      desc="Select a preset for allowed floors",
      order=0
    }

    do
      PresetEveryFloor = Settings.shared.action {
        name="Every floor",
        id="floors.preset.every",
        desc="Switcheroo activates every floor",
        order=0,
        action=function()
          setFloors({
            {true, true, true, true},
            {true, true, true, true},
            {true, true, true, true},
            {true, true, true, true},
            {true, true, true, true, true}
          })
        end
      }

      PresetEveryOddFloor = Settings.shared.action {
        name="Every odd floor",
        id="floors.preset.everyodd",
        desc="Switcheroo activates every odd-numbered floor",
        order=1,
        action=function()
          setFloors({
            {true, false, true, false},
            {true, false, true, false},
            {true, false, true, false},
            {true, false, true, false},
            {true, false, true, false, true}
          })
        end
      }

      PresetEveryEvenFloor = Settings.shared.action {
        name="Every even floor",
        id="floors.preset.everyeven",
        desc="Switcheroo activates every even-numbered floor",
        order=2,
        action=function()
          setFloors({
            {false, true, false, true},
            {false, true, false, true},
            {false, true, false, true},
            {false, true, false, true},
            {false, true, false, true, false}
          })
        end
      }

      PresetEveryFirstAndBossFloors = Settings.shared.action {
        name="First and boss floors",
        id="floors.preset.firstandboss",
        desc="Switcheroo activates on depths 1 and 4 of each zone",
        order=3,
        action=function()
          setFloors({
            {true, false, false, true},
            {true, false, false, true},
            {true, false, false, true},
            {true, false, false, true},
            {true, false, false, true, false}
          })
        end
      }

      PresetEveryFirstFloor = Settings.shared.action {
        name="First floor of zone",
        id="floors.preset.firstofzone",
        desc="Switcheroo activates on depth 1 of each zone",
        order=4,
        action=function()
          setFloors({
            {true, false, false, false},
            {true, false, false, false},
            {true, false, false, false},
            {true, false, false, false},
            {true, false, false, false, false}
          })
        end
      }

      PresetEveryBossFloor = Settings.shared.action {
        name="Boss floor of zone",
        id="floors.preset.bossofzone",
        desc="Switcheroo activates on depth 4 of each zone",
        order=5,
        action=function()
          setFloors({
            {false, false, false, true},
            {false, false, false, true},
            {false, false, false, true},
            {false, false, false, true},
            {false, false, false, true, false}
          })
        end
      }

      PresetOnceARun = Settings.shared.action {
        name="At start of run",
        id="floors.preset.firstfloor",
        desc="Switcheroo activates only on 1-1",
        order=6,
        action=function()
          setFloors({
            {true,  false, false, false},
            {false, false, false, false},
            {false, false, false, false},
            {false, false, false, false},
            {false, false, false, false, false}
          })
        end
      }
    end

    -- This loop generates a toggle for every level, except 5-5 which is added separately.
    for z = 1, 5 do
      for l = 1, 4 do
        _G["Level" .. z .. l] = Settings.shared.bool {
          name="Level " .. z .. "-" .. l,
          id="floors.l" .. z .. l,
          desc="Allow activation on level " .. z .. "-" .. l .. "?",
          order=z*4+l,
          default=true
        }
      end
    end
    
    Level55 = Settings.shared.bool {
      name="Level 5-5",
      id="floors.l55",
      desc="Allow activation on level 5-5?",
      order=25,
      default=true
    }
  end

  GeneratorType = Settings.shared.enum {
    name="Generator type",
    id="type",
    desc="The type of generator to use for generated items.",
    order=3,
    enum=enumGenType,
    default=enumGenType.CONJURER
  }

  SellItems = Settings.shared.percent {
    name="Sell items",
    id="sell",
    desc="Should destroyed items be sold and the profits given to the player?",
    order=4,
    minimum=0,
    maximum=2,
    step=0.1,
    default=0
  }

  GuaranteedTransmute = Settings.shared.bool {
    name="Guaranteed transmutations",
    id="guarantees",
    desc="Should guaranteed transmutations be honoried, i.e. a Ring of Becoming always becomes a Ring of Wonder?",
    order=5,
    default=true
  }

  IgnoreNonPool = Settings.shared.bool {
    name="Ignore non-pool items",
    id="nonpool",
    desc="Should the mod ignore non-pooled items, such as a Potion or Lucky Charm? This doesn't apply to the base dagger or shovel.",
    order=6,
    default=true
  }

  ForbidInstakill = Settings.shared.bool {
    name="Forbid instakill items",
    id="instakill",
    desc="Should items that can cause instant death be banned from the mod?",
    order=7,
    default=true
  }
end

---------------
-- FUNCTIONS --
---------------

local function median(a, b, c)
  if (a >= b and b >= c) then return b
  elseif (a <= b and b <= c) then return b
  elseif (b <= a and a <= c) then return a
  elseif (b >= a and a >= c) then return a
  elseif (a >= c and c >= b) then return c
  elseif (a <= c and c <= b) then return b
  end
end

local function checkFlags(value, test, all)
  if all then return value & test == test
  else return value & test ~= 0 end
end

----------------
-- EVENT CODE --
----------------

local function getSelectableSlots(player)
  local slots = {}

  for i, v in ipairs(SlotIDs) do
    local slot = v:lower()

    -- Check that slot is allowed by mod settings
    local allowed = _G["Slot" .. v .. "Allowed"]
    if allowed == slotType.NO then goto gssContinue end

    -- Check that the slot is not cursed
    if Inventory.isCursedSlot(player, slot) then goto gssContinue end

    -- Now divide the slot into individual pieces, if necessary
    local topIndex = 1
    if slot == "spell" then topIndex = 2 end

    -- Get the current item(s) in the slot
    local items = Inventory.getItemsInSlot(player, slot)
    if slot == "misc" then
      -- For charms, we need to pick the median of the following:
      -- • The number of charms the player already holds
      -- • That plus MaxNewCharms
      -- • The value of MaxCharmsForNew
      topIndex = median(#items, #items + MaxNewCharms, MaxCharmsForNew)
    elseif #items > 1 then topIndex = #items end

    -- Iterate over the subslots
    for i2 = 1, topIndex do
      local item = items[i2]

      if not item then
        -- If the slot is empty, make sure we can pick empty slots
        -- A 0% chance overrides minimums
        if EmptySlotChance > 0 then
          table.insert(slots, {v, i2})
        end
      else
        -- If the slot is full, make sure we can pick full slots
        if FilledSlotChance == 0 then goto gssSlotContinue end

        -- Also make sure it's not an ignored item
        if neverDelete[item.name] or (nonPool[item.name] and IgnoreNonPool) then goto gssSlotContinue end

        local value = {v, i2, item}

        -- Or an item forbidden from dropping, if we're respecting bans
        if allowed ~= slotType.UNLOCKED then
          local bans = ItemBan.getBanFlags(player, item)

          if checkFlags(bans, ItemBan.Flag.LOSS_DROP | ItemBan.Flag.CONVERT_SHRINE | ItemBan.Flag.CONVERT_SPELL | ItemBan.Flag.CONVERT_TRANSACTION, false) then
            goto gssSlotContinue
          end

          if checkFlags(bans, ItemBan.Flag.LOSS_SELL) then
            value[4] = true
          end
        end

        table.insert(slots, value)
      end

      ::gssSlotContinue::
    end

    ::gssContinue::
  end

  return slots
end

local function getItemPrice(item)
  if item.itemPrice then return item.itemPrice.coins / 2
  else return 0 end
end

local function selectAndClearSlots(playerNum, player, slots)
  local rngSeed = getChannel(playerNum)
  RNG.shuffle(slots, rngSeed)
  local output = {}
  local skipped = 0
  local max = SlotMaximum

  if max == -1 then max = math.huge end

  for i, v in ipairs(slots) do
    if v[3] then
      if RNG.roll(FilledSlotChance, rngSeed) or (skipped + i <= SlotMinimum) then
        local newSlot = {v[1], v[2]}

        -- Are we selling items?
        if SellItems > 0 and not v[4] then
          local price = getItemPrice(v[3]) * SellItems
          Currency.add(player, Currency.Type.GOLD, price)
        end

        -- And are we guaranteeing a specific item in return?
        if GuaranteedTransmute and v[3].itemTransmutableFixedOutcome then
          newSlot[3] = v[3].itemTransmutableFixedOutcome.target
        end

        -- Now we should destroy it
        Inventory.destroy(Entities.getEntityByID(v[3]))

        table.insert(output, newSlot)
      else
        skipped = skipped + 1
      end
    else
      if RNG.roll(EmptySlotChance, rngSeed) or (skipped + i <= SlotMinimum) then
        table.insert(output, {v[1], v[2]})
      else
        skipped = skipped + 1
      end
    end

    if #output >= max then break end
  end

  return output
end

--[[
  local function genItemQuick(rngSeed, genStrs, slot, player)
    for i=1, 5 do
      local item
      for _, v in ipairs(genStrs) do
        item = ItemGeneration.weightedChoice(rngSeed, v, 0, slot)
        if item then break end
      end
      if not item then item = ItemGeneration.weightedChoice(rngSeed, "secret", 0, slot) end
      if not item then print("No item generated for " .. slot) return nil end
      if ForbidInstakill and instakill[item] then return genItemQuick(rngSeed, genStrs, slot) end

      return item
    end
  end

  local function generateItem(rngSeed, genType, slot)
    if genType == enumGenType.CHEST then return genItemQuick(rngSeed, {"chest"}, slot)
    elseif genType == enumGenType.LOCKED_CHEST then return genItemQuick(rngSeed, {"lockedChest", "chest"}, slot)
    elseif genType == enumGenType.SHOP then return genItemQuick(rngSeed, {"shop"}, slot)
    elseif genType == enumGenType.LOCKED_SHOP then return genItemQuick(rngSeed, {"lockedShop", "shop"}, slot)
    elseif genType == enumGenType.URN then return genItemQuick(rngSeed, {"urn", "chest"}, slot)
    elseif genType == enumGenType.RED_CHEST then return genItemQuick(rngSeed, {"redChest", "lockedChest", "chest"}, slot)
    elseif genType == enumGenType.PURPLE_CHEST then return genItemQuick(rngSeed, {"purpleChest", "lockedChest", "chest"}, slot)
    elseif genType == enumGenType.BLACK_CHEST then return genItemQuick(rngSeed, {"blackChest", "lockedChest", "chest"}, slot)
    end

    return genItemQuick(rngSeed, {}, slot)
  end
]]

local function generateItem(rngSeed, genType, slot, player)
  local item
  
  for i = 1, 5 do -- TODO replace "5" with a setting
    item = ItemGeneration.weightedChoice(rngSeed, GenTypes[GeneratorType], 0, slot:lower()) -- TODO replace "0" with a setting

    -- Does an item actually exist?
    if not item then goto genItemContinue end

    -- Are we checking bans?
    if _G["Slot" .. slot .. "Allowed"] == slotType.YES then
      local flags = ItemBan.getBanFlags(player, item)
      if checkFlags(flags | 4194304, GenFlags[GeneratorType], false) then goto genItemContinue end
    end

    if ForbidInstakill and instakill[item] then goto genItemContinue end

    if item then break end

    ::genItemContinue::
  end

  if not item then print("No item generated for " .. slot) return nil end
end

local function restockSlots(playerNum, player, slots)
  local rngSeed = getChannel(playerNum)

  for i, v in ipairs(slots) do
    -- Roll the spawn chance first
    if RNG.roll(SlotFillChance, rngSeed) then
      -- If we have a guaranteed item, use it.
      if v[3] then
        Inventory.grant(v[3], player)
      else
        local iType = generateItem(rngSeed, GeneratorType, v[1])
        if iType then Inventory.grant(iType, player) end
      end
    else
      if v[1] == "Shovel" then
        Inventory.grant("ShovelBasic", player)
      elseif v[1] == "Weapon" then
        Inventory.grant("WeaponDagger", player)
      end
    end
  end
end

Event.levelLoad.add("switchBuilds", {order="entities", sequence=2}, function(ev)
  Try.catch(function()
    -- Make sure the mod should activate on this level
    local z = CurrentLevel.getZone()
    local l = CurrentLevel.getFloor()
    if not _G["Level" .. z .. l] then return end

    -- Shortcut if maximum is zero
    if SlotMaximum == 0 then return end

    for i, p in ipairs(Player.getPlayerEntities()) do
      p.descentDamageImmunity.active = true
      local seenItems = Utilities.fastCopy(RunState.getState().seenItems)

      -- After this method, slots is {{"slot", index, containsItem|nil, banSell|nil}, {"slot", index, containsItem|nil, banSell|nil}}
      local slots = getSelectableSlots(p)

      -- Shortcut if no slots are selectable
      if #slots == 0 then return end

      -- After this method, slots is {{"slot", index, guaranteedItem|nil}, {"slot", index, guaranteedItem|nil}}
      slots = selectAndClearSlots(i, p, slots)
      restockSlots(i, p, slots)

      RunState.getState().seenItems = seenItems
      p.descentDamageImmunity.active = false
    end
  end)
end)