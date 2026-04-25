-- BAD: global lookup every iteration (~5x slower in LuaJIT)
for i = 1, 10000 do
    local _ = math.sin(i)  -- result discarded intentionally (benchmark)
end

-- GOOD: cache the function reference once
local sin = math.sin
for i = 1, 10000 do
    local _ = sin(i)  -- result discarded intentionally (benchmark)
end
