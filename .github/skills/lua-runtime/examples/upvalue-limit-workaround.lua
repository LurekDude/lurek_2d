-- Hitting upvalue limit? Move state into a table:
-- BAD (each captured var = 1 upvalue):
local a, b, c, d, e, f  -- (... up to 60 variables = 60 upvalues)
local function doWork_bad()
    local _ = a  -- a, b, c, d, e, f ... each count as a separate upvalue
end

-- GOOD: use one upvalue (the table):
local state = { a = a, b = b, c = c, d = d, e = e, f = f }  -- (... etc.)
local function doWork()
    local _ = state.a  -- state.b, state.c ... all accessed via one upvalue
end
