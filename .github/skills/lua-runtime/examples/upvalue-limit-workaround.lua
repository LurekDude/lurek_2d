-- Hitting upvalue limit? Move state into a table:
-- BAD (each captured var = 1 upvalue):
local a, b, c, d, e, f ... = ...  -- 60 upvalues max
local function doWork()
    use(a, b, c, d, e, f ...)     -- uses all 60
end

-- GOOD: use one upvalue (the table):
local state = { a=a, b=b, c=c, d=d, e=e, f=f ... }
local function doWork()
    use(state.a, state.b ...)
end
