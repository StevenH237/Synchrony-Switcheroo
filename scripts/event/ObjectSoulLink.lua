local Event     = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local Object    = require "necro.game.object.Object"
local Utilities = require "system.utils.Utilities"

local SwEnum  = require "Switcheroo.Enum"
local SwUtils = require "Switcheroo.Utils"

---------------
-- VARIABLES --
--#region------

--#endregion (Variables)

---------------
-- CONSTANTS --
--#region------

--#endregion (Constants)

---------------
-- FUNCTIONS --
--#region------

--#endregion (Functions)

--------------------
-- EVENT HANDLERS --
--#region-----------

-- ev.entity: The entity of the actual soul link (the middle one)
-- ev.target: The entity *being* linked (the child one)

-- For example, let's take
-- Cadence#1 → SoulLinkDad#99 → SoulLinkDad#74
-- DorianDad#75 → SoulLinkDad#100 ↑

-- In this situation, the event will fire twice:
-- {entity: SoulLinkDad#99, target: Cadence#1}
-- {entity: SoulLinkDad#100, target: DorianDad#75}
-- In both cases, SwUtils.getTopSoulLink() will return SoulLinkDad#74.
Event.objectSoulLink.add("switcherooLink", { order = "inventory", sequence = -1 }, function(ev)
  local link = SwUtils.getTopSoulLink(ev.entity)

  local slots = link.Switcheroo_soulLinkItemGen.slots

  local slotsToClose = {}
  local itemsToDelete = {}

  for k, v in Utilities.sortedPairs(slots) do
    if v == SwEnum.SlotMark.OPEN then
      -- If the slot is open, close it iff it has any Switcheroo-given items in it.
      for i, v2 in ipairs(Inventory.getItemsInSlot(ev.target, k)) do
        if v2.Switcheroo_tracker.wasGiven then
          slotsToClose[k] = true
          break
        end
      end
    else
      -- If the slot is closed, delete any Switcheroo-given items from this player's inventory.
      for i, v2 in ipairs(Inventory.getItemsInSlot(ev.target, k)) do
        if v2.Switcheroo_tracker.wasGiven then
          itemsToDelete[v2] = true
        end
      end
    end
  end

  -- Actually close the slots and delete the items now
  -- Doing that now instead of above to avoid modifying tables mid-iteration
  for k in Utilities.sortedPairs(slotsToClose) do
    slots[k] = SwEnum.SlotMark.CLOSED
  end

  for k in Utilities.sortedPairs(itemsToDelete) do
    print(k)
    Inventory.drop(ev.target, k)
    Object.delete(k)
  end
end)

--#endregion (Event Handlers)
