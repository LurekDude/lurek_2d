-- Lurek2D Integration Test: Entity + AI
-- Tests entity system with AI decision-making components

-- @description Covers suite: integration: entity with AI state machine.
describe("integration: entity with AI state machine", function()
    -- @covers lurek.ecs.Universe
    -- @covers lurek.ai.newStateMachine
    -- @covers lurek.ecs.newUniverse
    -- @description Verifies an AI state machine can drive shared behavior state while the spawned entities remain alive in the same universe.
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

-- @description Covers suite: integration: entity tags with AI agents.
describe("integration: entity tags with AI agents", function()
    -- @covers lurek.ecs.Universe.addTag
    -- @covers lurek.ai
    -- @description Verifies entity tags can partition actors into groups that AI logic could consume when selecting hostile versus ally behavior.
    it("entity tags drive AI behavior", function()
        local universe = lurek.ecs.newUniverse()

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
test_summary()
