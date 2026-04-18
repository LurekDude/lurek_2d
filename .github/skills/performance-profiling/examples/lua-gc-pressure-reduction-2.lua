-- BAD: per-frame table allocation
function lurek.process(dt)
    local pos = vector(player.x, player.y)   -- new table every frame
end

-- GOOD: pre-allocate, reuse
local _pos = { x = 0, y = 0 }
function lurek.process(dt)
    _pos.x = player.x
    _pos.y = player.y
    -- use _pos
end
