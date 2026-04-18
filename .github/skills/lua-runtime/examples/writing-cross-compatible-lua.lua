-- Bitwise ops: detect backend
local bit = bit or {}  -- LuaJIT: global `bit` table; Lua 5.4: not needed
local function band(a, b)
    if bit.band then return bit.band(a, b) end  -- LuaJIT
    return a & b                                  -- Lua 5.4
end

-- Integer division: compatible floor div
local function idiv(a, b) return math.floor(a / b) end
