local NSSettings = require "NixSettings.NSSettings"

-------------
-- PRESETS --
--#region----

local psPercent = {
  minimum=0,
  maximum=1,
  step=0.1,
  fixedStep=0.01,
  default=0,
  format=function(val) return (val / 100) .. "%" end,
  editAsString=true
}

local psNumNatural = function(val)
  local out = {
    minimum=0,
    step=1,
    fixedStep=1,
    default=0,
    editAsString=true
  }

  if val then
    out.minimum=-1
    out.default=-1
    out.format=function(val)
      if val == -1 then return "No limit"
      else return val end
    end
  end

  return out
end

local nodes = {
  chance={
    type="group",
    order=0,
    name="Slot chances",
    desc="Chances and min/max of slots being picked and filled",
    items={
      empty={
        type="number",
        order=0,
        name="Empty slot pick chance",
        desc="Chance that an empty slot is picked to receive an item.",
        preset=psPercent
      },
      filled={
        type="number",
        order=1,
        name="Filled slot pick chance",
        desc="Chance that an occupied slot is cleared and picked to receive an item.",
        preset=psPercent
      },
      new={
        type="number",
        order=2,
        name="Slot fill chance",
        desc="Chance that a selected slot receives an item; if it fails, the slot becomes blank.",
        preset=psPercent
      },
      minimum={
        type="range",
        order=3,
        name={"Minimum slots","Maximum slots"},
        desc={"Minimum number of slots to fill.","Maximum number of slots to fill."},
        preset=psNumNatural(false)
      },
      maximum={

      }
    }
  }
}