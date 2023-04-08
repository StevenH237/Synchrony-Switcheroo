local Entities = require "system.game.Entities"

local module = {}

-- Gets the topmost soul link from a given soul link.
function module.getTopSoulLink(ent)
  -- Only soulLink entities are allowed here.
  if not ent.soulLink then
    return nil
  end

  -- A soulLink without a target is itself the topmost soul link.
  if ent.soulLink.target == nil or ent.soulLink.target == 0 then
    return ent
  end

  -- Otherwise, check for this target's target.
  return module.getTopSoulLink(Entities.getEntityByID(ent.soulLink.target))
end

return module
