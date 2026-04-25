---@diagnostic disable: undefined-global
-- BAD: creates a new table every frame (200+ KB/s GC pressure)
function lurek.process(dt)
    local args = { x = player.x, y = player.y }  -- heap allocation
    processArgs(args)
end

-- GOOD: pre-allocate and reuse
local _args = {}
function lurek.process(dt)
    _args.x = player.x
    _args.y = player.y
    processArgs(_args)
end
