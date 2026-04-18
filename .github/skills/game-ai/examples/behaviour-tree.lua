local npc = world:newAgent("npc", x, y)
local bt  = npc:useBt()

-- Build tree with composite nodes
local root = bt:sequence({
    bt:condition(function(a) return not a:blackboard("alert") end),
    bt:action(doPatrol),
    bt:selector({
        bt:sequence({
            bt:condition(canSeePlayer),
            bt:action(facePlayer),
            bt:action(shootAtPlayer),
        }),
        bt:action(resumePatrol),
    }),
})
bt:setRoot(root)

-- Node return values: "success", "failure", "running"
function doPatrol(agent)
    agent:seek(nextWaypoint())
    return "running"
end
