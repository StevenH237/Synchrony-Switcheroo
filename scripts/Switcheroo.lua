local Components      = require "necro.game.data.Components"
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
local Snapshot        = require "necro.game.system.Snapshot"
local Try             = require "system.utils.Try"
local Utilities       = require "system.utils.Utilities"

local Slots    = {"Head", "Shovel", "Feet", "Weapon", "Body", "Torch", "Ring", "Item", "Spells", "Charms"}
local SlotIDs  = {"Head", "Shovel", "Feet", "Weapon", "Body", "Torch", "Ring", "Action", "Spell", "Misc"}
local Defaults = {Shovel="ShovelBasic", Weapon="WeaponDagger"}

local GenTypes = {[0]=nil, "chest", "lockedChest", "shop", "lockedShop", "urn", "redChest", "purpleChest", "blackChest", "secret"}
local GenCombo = {
  ItemPool = ItemBan.Flag.PICKUP + ItemBan.Flag.GENERATE_ITEM_POOL,
  CratePool = ItemBan.Flag.PICKUP + ItemBan.Flag.GENERATE_CRATE,
  ShrinePool = ItemBan.Flag.PICKUP + ItemBan.Flag.GENERATE_SHRINE_POOL + ItemBan.Flag.GENERATE_TRANSACTION
}
local GenFlags = {
  [0]=GenCombo.ItemPool,
  GenCombo.ItemPool,
  GenCombo.ItemPool,
  GenCombo.ItemPool,
  GenCombo.ItemPool,
  GenCombo.CratePool,
  GenCombo.ItemPool,
  GenCombo.ItemPool,
  GenCombo.ItemPool,
  GenCombo.ShrinePool
}

-- NOTE: This mod adds the player number to this channel so that rolls can remain the same per player.
-- For example, player 1 uses channel 23701, player 2 uses 23702, etc.
local rngChannel = 23700
local function getChannel(playerNum)
  return rngChannel + playerNum -- TODO replace this with entity-based system
end

---------------
-- SNAPSHOTS --
---------------

FirstGen = Snapshot.runVariable(true)

-----------------
-- SCRIPT VARS --
-----------------

local itemsNotGivenTable = {}
local itemsNotTakenTable = {}

-----------
-- ENUMS --
-----------

local enumGenType = Enum.sequence {
  UNWEIGHTED=0,
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

local enumSlotType = Enum.sequence {
  NO=0,
  YES=1,
  UNLOCKED=2,
  ONCE=3,
  UNLOCKED_ONCE_THEN_YES=4,
  UNLOCKED_ONCE_THEN_NO=5
}

local enumSeenItems = Enum.sequence {
  IGNORED=0,
  RESET_AFTER_EACH=1,
  UNAFFECTED=2
}

----------------
-- COMPONENTS --
----------------

Components.register {
  Switcheroo_noGive = {},
  Switcheroo_noTake = {},
  Switcheroo_noChance = {}
}

----------------------
-- SETTINGS SECTION --
----------------------
do
  -- Settings Functions --
  local function setFloors(data)
    for z, zdata in ipairs(data) do
      for l, v in ipairs(zdata) do
        SettingsStorage.set("mod.Switcheroo.floors.l" .. z .. l, v, Settings.Layer.REMOTE_PENDING)
      end
    end

    Menu.close()
  end

  local function setSlots(data)
    for i, v in ipairs(SlotIDs) do
      SettingsStorage.set("mod.Switcheroo.slots." .. v:lower(), data, Settings.Layer.REMOTE_PENDING)
    end

    Menu.close()
  end

  local function noLimit(value)
    return value == -1 and "No limit" or value
  end

  local function checkComponents(item)
    print(Entities.getEntityPrototype(item))
  end

  -- Settings nodes--
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
      step=0.1,
      editAsString=true,
      order=0
    }

    FilledSlotChance = Settings.shared.percent {
      name="Filled slot pick chance",
      id="chance.filled",
      desc="Chance that an occupied slot is cleared and picked to receive an item.",
      default=1,
      minimum=0,
      maximum=1,
      step=0.1,
      editAsString=true,
      order=1
    }

    SlotFillChance = Settings.shared.percent {
      name="Slot fill chance",
      id="chance.new",
      desc="Chance that a selected slot receives an item; if it fails, the slot becomes blank.",
      default=1,
      minimum=-0.05,
      maximum=1,
      step=0.1,
      editAsString=true,
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
      editAsString=true,
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
      editAsString=true,
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

  GroupSlotSet = Settings.group {
    name="Set all...",
    id="slots.all",
    desc="Select a value and set all slots to that value",
    order=0
  }

  do
    PresetSlotsNo = Settings.shared.action {
      name="No",
      id="slots.all.no",
      desc="Disables every slot for Switcheroo",
      order=0,
      action=function()
        setSlots(enumSlotType.NO)
      end
    }

    PresetSlotsYes = Settings.shared.action {
      name="Yes",
      id="slots.all.yes",
      desc="Enables every slot for Switcheroo",
      order=1,
      action=function()
        setSlots(enumSlotType.YES)
      end
    }

    PresetSlotsNo = Settings.shared.action {
      name="Unlocked",
      id="slots.all.unlock",
      desc="Unlocks every slot for Switcheroo",
      order=2,
      action=function()
        setSlots(enumSlotType.UNLOCKED)
      end
    }

    PresetSlotsOnce = Settings.shared.action {
      name="Once",
      id="slots.all.once",
      desc="Enables every slot for Switcheroo once",
      order=3,
      action=function()
        setSlots(enumSlotType.ONCE)
      end
    }

    PresetSlotsUnlockedYes = Settings.shared.action {
      name="Unlocked once, then Yes",
      id="slots.all.unlock_yes",
      desc="Unlocks every slot for Switcheroo once, then leaves them enabled",
      order=4,
      action=function()
        setSlots(enumSlotType.UNLOCKED)
      end
    }

    PresetSlotsUnlockedNo = Settings.shared.action {
      name="Unlocked once, then No",
      id="slots.all.unlock_no",
      desc="Unlocks every slot for Switcheroo once, then leaves them disabled",
      order=5,
      action=function()
        setSlots(enumSlotType.UNLOCKED)
      end
    }
  end

  -- This loop generates a toggle for every slot.
  for i, v in ipairs(SlotIDs) do
    _G["Slot" .. v .. "Allowed"] = Settings.shared.enum {
      name=Slots[i],
      id="slots." .. v:lower(),
      desc="Can the mod override the " .. Slots[i]:lower() .. "  slot",
      order=i,
      enum=enumSlotType,
      default=enumSlotType.YES
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
      editAsString=true,
      order=1
    }

    MaxCharmsForNew = Settings.shared.number {
      name="Max charms from new",
      id="charms.max",
      desc="How many charms are allowed without collecting more outside the mod?",
      default=5,
      minimum=-1,
      maximum=100,
      editAsString=true,
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

  GroupComponents = Settings.group {
    name="Components settings",
    id="components",
    desc="Settings that influence how item components affect generation",
    order=3
  }

  do
    ComponentsNotTaken = Settings.shared.string {
      name="Don't take components",
      id="components.takeComponent",
      desc="Space-separated list of components whose items shouldn't be taken.",
      order=1,
      default="itemBanInnateSpell"
    }

    ComponentsNotGiven = Settings.shared.string {
      name="Don't give components",
      id="components.giveComponent",
      desc="Space-separated list of components whose items shouldn't be given.",
      order=2,
      default="itemIncomingDamageIncrease itemBanInnateSpell"
    }

    ItemsNotTaken = Settings.entitySchema.string {
      name="Don't take items",
      id="components.takeItem",
      desc="Space-separated list of items shouldn't be taken.",
      order=3,
      default="MiscPotion CharmLuck RingWonder HeadCrownOfGreed"
    }

    ItemsNotGiven = Settings.entitySchema.string {
      name="Don't give items",
      id="components.giveItem",
      desc="Space-separated list of items shouldn't be given.",
      order=4,
      default=""
    }

    ComponentChecker = Settings.shared.string {
      name="Check components of",
      id="components.check",
      desc="Item for which components should be checked",
      order=5,
      default=""
    }

    ComponentCheck = Settings.shared.action {
      name="Check",
      id="components.checkexecute",
      desc="Check the components",
      order=6,
      action=checkComponents
    }
  end

  --[[]]

  GeneratorType = Settings.shared.enum {
    name="Generator type",
    id="type",
    desc="The type of generator to use for generated items.",
    order=4,
    enum=enumGenType,
    default=enumGenType.CONJURER
  }

  SellItems = Settings.shared.percent {
    name="Sell items",
    id="sell",
    desc="Should destroyed items be sold and the profits given to the player?",
    order=5,
    minimum=0,
    maximum=2,
    step=0.1,
    default=0
  }

  GuaranteedTransmute = Settings.shared.bool {
    name="Guaranteed transmutations",
    id="guarantees",
    desc="Should guaranteed transmutations be honoried, i.e. a Ring of Becoming always becomes a Ring of Wonder?",
    order=6,
    default=true
  }

  AllowDeath = Settings.shared.bool {
    name="Allow deadly items",
    id="deadly",
    desc="Should items that are *only* PICKUP_DEATH banned be allowed? They won't kill from the mod.",
    order=7,
    default=false
  }

  SeenItems = Settings.shared.enum {
    name="Seen items",
    id="seen",
    desc="How should the seen item log affect mod items?",
    order=8,
    default=2,
    enum=enumSeenItems
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
  if all then return bit.band(value, test) == test
  else return bit.band(value, test) ~= 0 end
end

---------------------
-- EVENT FUNCTIONS --
---------------------

local function splitToList(str)
  if not str then return {} end

  local out = {}

  for token in str:gmatch("[^%s]+") do
    table.insert(out, token)
  end

  return out
end

local function splitToSet(str)
  if not str then return {} end

  local out = {}

  for token in str:gmatch("[^%s]+") do
    out[token] = true
  end

  return out
end

local function itemHasBannedTag(item)
  for i,v in ipairs(splitToList("Switcheroo_noTake " .. ComponentsNotTaken)) do
    if item[v] then return true end
  end
  return false
end

local function skipSlot(player, v)
  local slot = v:lower()

  -- Check that slot is allowed by mod settings
  local allowed = _G["Slot" .. v .. "Allowed"]
  if allowed == enumSlotType.NO then return true end
  if (not FirstGen) and (allowed == enumSlotType.ONCE or allowed == enumSlotType.UNLOCKED_ONCE_THEN_NO) then return true end

  -- Check that the slot is not cursed
  if Inventory.isCursedSlot(player, slot) then return true end

  return false
end

local function skipSubslot(item)
  -- If the slot is full, make sure we can pick full slots
  if FilledSlotChance == 0 then return true end

  -- Or an item banned from removal
  if itemHasBannedTag(item) then return true end

  return false
end

local function getSelectableSlots(player)
  local slots = {}

  for i, v in ipairs(SlotIDs) do
    local slot = v:lower()

    if not skipSlot(player, v) then
      local allowed = _G["Slot" .. v .. "Allowed"]
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
          if not skipSubslot(item) then
            local value = {v, i2, item}
            
            -- Or an item forbidden from dropping, if we're respecting bans
            if allowed == enumSlotType.YES or ((not FirstGen) and allowed == enumSlotType.UNLOCKED_ONCE_THEN_YES) then
              local bans = ItemBan.getBanFlags(player, item)
              
              if not checkFlags(bans, ItemBan.Flag.PICKUP + ItemBan.Flag.LOSS_DROP + ItemBan.Flag.CONVERT_SHRINE + ItemBan.Flag.CONVERT_SPELL + ItemBan.Flag.CONVERT_TRANSACTION, false) then              
                if checkFlags(bans, ItemBan.Flag.LOSS_SELL) then
                  value[4] = true
                end
              end
            end
            
            table.insert(slots, value)
          end
        end
      end
    end
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

local function generateItem(rngSeed, slot, player)
  local choiceOpts = {
    channel = rngSeed,
    slot = slot:lower(),
    chanceType = GenTypes[GeneratorType],
    default = Defaults[slot],
    excludedComponents = splitToList("Switcheroo_noGive " .. ComponentsNotGiven)
  }

  -- Exclude seen items?
  if slot == "Misc" then
    choiceOpts.seenItems = {}
  end

  -- Are we checking bans?
  choiceOpts.banMask = 0
  choiceOpts.player = player

  if _G["Slot" .. slot .. "Allowed"] == enumSlotType.YES or ((not FirstGen) and _G["Slot" .. slot .. "Allowed"] == enumSlotType.UNLOCKED_ONCE_THEN_YES) then
    choiceOpts.banMask = GenFlags[GeneratorType]
  end

  if not AllowDeath then
    choiceOpts.banMask = choiceOpts.banMask + ItemBan.Flag.PICKUP_DEATH
  end

  local item = ItemGeneration.choice(choiceOpts)

  return item
end

local function restockSlots(playerNum, player, slots)
  local rngSeed = getChannel(playerNum)

  for i, v in ipairs(slots) do
    local success = false
    -- Roll the spawn chance first
    if RNG.roll(SlotFillChance, rngSeed) then
      -- If we have a guaranteed item, use it.
      if v[3] then
        Inventory.grant(v[3], player)
      else
        local iType = generateItem(rngSeed, v[1], player)
        if iType then
          Inventory.grant(iType, player)
          success = true
        end
      end
    end

    if not success then
      if v[1] == "Shovel" then
        Inventory.grant("ShovelBasic", player)
      elseif v[1] == "Weapon" then
        Inventory.grant("WeaponDagger", player)
      end
    end
  end
end

--------------------
-- EVENT HANDLERS --
--------------------

Event.levelLoad.add("switchBuilds", {order="entities", sequence=2}, function(ev)
  local d = CurrentLevel.getDepth()
  local l = CurrentLevel.getFloor()

  if CurrentLevel.isLobby() then return end

  Try.catch(function()
    -- Make sure the mod should activate on this level
    if not _G["Level" .. d .. l] then return end

    -- Shortcut if maximum is zero
    if SlotMaximum == 0 then return end

    -- Save current seen items
    local seenItemsBackup = Utilities.fastCopy(RunState.getState().seenItems)
    local seenItems

    if SeenItems == 0 then
      seenItems = {}
    elseif SeenItems == 1 then
      seenItems = Utilities.fastCopy(seenItemsBackup)
    end

    for i, p in ipairs(Player.getPlayerEntities()) do
      p.descentDamageImmunity.active = true

      -- After this method, slots is {{"slot", index, containsItem|nil, banSell|nil}, {"slot", index, containsItem|nil, banSell|nil}}
      local slots = getSelectableSlots(p)

      -- Shortcut if no slots are selectable
      if #slots == 0 then return end

      -- After this method, slots is {{"slot", index, guaranteedItem|nil}, {"slot", index, guaranteedItem|nil}}
      slots = selectAndClearSlots(i, p, slots)
      restockSlots(i, p, slots)

      p.descentDamageImmunity.active = false

      if SeenItems ~= 2 then
        RunState.getState().seenItems = Utilities.fastCopy(seenItems)
      end
    end

    RunState.getState().seenItems = seenItemsBackup

    FirstGen = false
  end)
end)

Event.entitySchemaGenerate.add("switcherooFunctions", {order="components", sequence=-1}, function ()
  itemsNotGivenTable = splitToSet(ItemsNotGiven)
  itemsNotTakenTable = splitToSet(ItemsNotTaken)
end)

Event.entitySchemaLoadEntity.add("addComponent", {order="overrides"}, function(ev)
  if not ev.entity.item then return end

  if itemsNotGivenTable[ev.entity.name] then
    ev.entity.Switcheroo_noGive = {}
  else
    ev.entity.Switcheroo_noGive = nil
  end

  if itemsNotTakenTable[ev.entity.name] then
    ev.entity.Switcheroo_noTake = {}
  else
    ev.entity.Switcheroo_noTake = nil
  end
end)