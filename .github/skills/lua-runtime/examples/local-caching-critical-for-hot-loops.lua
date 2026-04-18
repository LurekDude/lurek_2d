-- BAD: global lookup every iteration (~5x slower in LuaJIT)
for i = 1, 10000 do
    math.sin(i)
end

-- GOOD: cache the function reference once
local sin = math.sin
for i = 1, 10000 do
    sin(i)
end
