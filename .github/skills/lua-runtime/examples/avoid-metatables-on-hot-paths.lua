---@diagnostic disable: undefined-global
-- BAD: __index metamethod on every `obj.x` access prevents JIT optimization
local obj = setmetatable({}, { __index = function(t, k) return defaults[k] end })

-- GOOD: flatten into a plain table when performance matters
local obj = { x = 0, y = 0, vx = 0, vy = 0 }
