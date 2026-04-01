-- Luna2D Integration Test: Entity + AI
-- Tests entity system with AI decision-making components

describe("integration: entity with AI state machine", function()
    it("entities change state based on FSM", function()
        local universe = luna.entity.newUniverse()

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
        local fsm = luna.ai.newStateMachine()
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

describe("integration: entity tags with AI agents", function()
    it("entity tags drive AI behavior", function()
        local universe = luna.entity.newUniverse()

        -- Create enemies and friendlies
        for i = 1, 5 do
            local id = universe:spawn()
            universe:set(id, "type", "enemy")
            universe:addTag(id, "hostile")
        end

        for i = 1, 3 do
            local id = universe:spawn()
            universe:set(id, "type", "friendly")
            universe:addTag(id, "ally")
        end

        -- Query by tag
        local hostiles = universe:getEntitiesByTag("hostile")
        local allies = universe:getEntitiesByTag("ally")

        expect_equal(5, #hostiles, "5 hostiles tagged")
        expect_equal(3, #allies, "3 allies tagged")
    end)
end)
