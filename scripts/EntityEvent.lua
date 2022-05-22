local Event     = require "necro.event.Event"
local Utitilies = require "system.utils.Utilities"

local SwSettings = require "Switcheroo.Settings"

local function copyToSet(table)
  local out = {}
  for i, v in ipairs(table) do
    out[v] = true
  end
  return out
end

-- These variables should save on some function calls...
local itemNamesNotGiven
local itemNamesNotTakenIfGiven
local itemNamesNeverTaken
local componentsNotGiven
local componentsNotTakenIfGiven
local componentsNeverTaken

Event.entitySchemaGenerate.add("checks", { order = "components", sequence = -1 }, function()
  itemNamesNotGiven = {}
  componentsNotGiven = {}

  if SwSettings.get("dontGive.advanced") then
    itemNamesNotGiven = copyToSet(SwSettings.get("dontGive.items"))
    componentsNotGiven = copyToSet(SwSettings.get("dontGive.components"))
  end

  if SwSettings.get("dontGive.damageUps") then
    componentsNotGiven.itemIncomingDamageMultiplier = true
    componentsNotGiven.itemIncomingDamageIncrease = true
  end

  if SwSettings.get("dontGive.goldItems") then
    componentsNotGiven.itemBanPoverty = true
  end

  if SwSettings.get("dontGive.magicFood") then
  end
end)

Event.entitySchemaLoadEntity.add("addComponents", { order = "overrides" }, function(ev)
  if not ev.entity.item then return end

  -- Should the item be exempt from giving?

end)
