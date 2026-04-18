-- State callbacks have access to dt and the agent
function onUpdatePatrol(agent, dt)
    local next = patrolPath[agent.waypointIndex]
    agent:seek(next.x, next.y, 80)   -- steering: move toward waypoint at speed 80
    if agent:distanceTo(next.x, next.y) < 8 then
        agent.waypointIndex = (agent.waypointIndex % #patrolPath) + 1
    end
end
