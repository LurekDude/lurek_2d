-- Global blackboard on the world — all agents can read these
world:blackboard():set("playerX", player.x)
world:blackboard():set("playerY", player.y)
world:blackboard():set("alertLevel", 0)

-- Agent-local blackboard (parent = world blackboard)
local bb = guard:blackboard()
bb:set("waypointIndex", 1)
bb:set("lastSeenX", nil)

-- Read: walks parent chain if not found locally
local px = bb:get("playerX")   -- reads from global blackboard

-- Update global facts each frame
function lurek.process(dt)
    world:blackboard():set("playerX", player.x)
    world:blackboard():set("playerY", player.y)
    world:update(dt)
end
