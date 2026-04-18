local npc = world:newAgent("merchant", x, y)
local ua  = npc:useUtility()

ua:addAction("sell_goods",  function(agent)
    return agent:blackboard():get("inventory_full") and 0.9 or 0.1
end)
ua:addAction("restock",     function(agent)
    local stock = agent:blackboard():get("stock_level")
    return 1.0 - stock   -- low stock = high score
end)
ua:addAction("take_break",  function(agent)
    local fatigue = agent:blackboard():get("fatigue")
    return fatigue > 0.7 and 0.8 or 0.0
end)

-- Returns the action name with highest score each frame
local action = ua:selectAction()
performAction(npc, action)
