-- BAD: creates a new string object on every frame
local key = "player_" .. tostring(id)   -- new allocation each frame

-- GOOD: pre-build the string table as a lookup
local KEYS = {}
for i = 1, 100 do KEYS[i] = "player_" .. tostring(i) end
-- Then in hot loop:
local key = KEYS[id]   -- no allocation
