local Weapon = require(script.Parent)
local Karambit = setmetatable({}, Weapon)
Karambit.__index = Karambit

function Karambit.new()
    local config = {slot = "ternary"}
    local self = Weapon.new("Karambit", config)
    setmetatable(self, Karambit)
    return self
end

return Karambit