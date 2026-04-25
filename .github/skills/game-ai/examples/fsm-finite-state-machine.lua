---@diagnostic disable: undefined-global, undefined-field
local guard = world:newAgent("guard", startX, startY)
local fsm   = guard:useFsm()

-- Define states
fsm:addState("patrol",  onEnterPatrol, onUpdatePatrol, onExitPatrol)
fsm:addState("alert",   nil,           onUpdateAlert,  nil)
fsm:addState("attack",  nil,           onUpdateAttack, nil)

-- Add transitions (higher priority number = checked first)
fsm:addTransition("patrol", "alert",  1, function() return canSeePlayer() end)
fsm:addTransition("alert",  "attack", 2, function() return isClose(32) end)
fsm:addTransition("alert",  "patrol", 1, function() return lostSight(5) end)

fsm:setState("patrol")

-- Per-frame update
function lurek.process(dt)
    world:update(dt)   -- updates all agents
end
