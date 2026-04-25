---@diagnostic disable: undefined-global, undefined-field
local npc    = world:newAgent("villager", x, y)
local planner = npc:useGoap()

-- World state (boolean facts)
local actions = {
    {
        name = "gather_food",
        preconditions = { has_tool = true },
        effects = { has_food = true },
        cost = 1,
        perform = function(agent) gatherAnimation(agent) end,
    },
    {
        name = "craft_tool",
        preconditions = { has_wood = true },
        effects = { has_tool = true },
        cost = 2,
        perform = function(agent) craftAnimation(agent) end,
    },
}
planner:setActions(actions)
planner:setGoal({ has_food = true })

-- GOAP searches for cheapest action sequence to reach goal
-- Call re-plan when the situation changes:
planner:replan({ has_tool = false, has_wood = true })
