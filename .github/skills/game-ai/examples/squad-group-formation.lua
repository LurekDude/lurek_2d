local squad = world:newSquad("alpha")
squad:addMember(agent1)
squad:addMember(agent2)
squad:addMember(agent3)

-- Formation types: "line", "wedge", "circle", "column", "none"
squad:setFormation("wedge")
squad:setLeader(agent1)
squad:moveTo(targetX, targetY)   -- all members offset from leader

-- Formation updates automatically in world:update(dt)
