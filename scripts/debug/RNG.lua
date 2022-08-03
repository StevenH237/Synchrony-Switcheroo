local RNG       = require "necro.game.system.RNG"
local Utilities = require "system.utils.Utilities"

local module = {}

local function RandomFunction(func, name, ...)
  local val = func(...)
  print(name .. " output: " .. Utilities.inspect(val))
  return val
end

for _, v in ipairs({ "shuffle", "roll" }) do
  module[v] = function(...) return RandomFunction(RNG[v], v, ...) end
end

return module
