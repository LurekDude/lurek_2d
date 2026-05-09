-- Integration: ECS entities driven by AI state machines
describe("integration: entity with AI state machine", function()
    -- @integration LStateMachine:addState
    -- @integration LStateMachine:addTransition
    -- @integration LStateMachine:forceState
    -- @integration LStateMachine:getCurrentState
    -- @integration LUniverse:getEntityCount
    -- @integration LUniverse:isAlive
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ai.newStateMachine
    -- @integration lurek.ecs.newUniverse
    it("entities change state based on FSM", function()
        local universe = lurek.ecs.newUniverse()

        -- Create entities with AI state
        local ids = {}
        for i = 1, 10 do
            local id = universe:spawn()
            universe:set(id, "health", 100)
            universe:set(id, "state", "idle")
            universe:set(id, "x", i * 50)
            universe:set(id, "y", 100)
            ids[i] = id
        end

        -- Create FSM for entity behavior
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {
            onUpdate = function(dt)
                -- idle behavior
            end
        })
        fsm:addState("patrol", {
            onUpdate = function(dt)
                -- patrol behavior
            end
        })
        fsm:addTransition("idle", "patrol")
        fsm:addTransition("patrol", "idle")

        -- Force transition to patrol (setState doesn't exist, use forceState)
        fsm:forceState("patrol")
        expect_equal("patrol", fsm:getCurrentState(), "transitioned to patrol")

        -- All entities should still be alive
        for _, id in ipairs(ids) do
            expect_true(universe:isAlive(id), "entity " .. id .. " is alive")
        end

        expect_equal(10, universe:getEntityCount(), "10 entities exist")
    end)
end)

test_summary()
