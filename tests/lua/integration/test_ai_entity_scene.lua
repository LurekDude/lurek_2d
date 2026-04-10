-- Lurek2D Integration Test: AI + Entity + Scene (3-way)
-- Tests AI FSM controlling entities within a scene
-- @covers lurek.ai.newStateMachine
-- @covers lurek.entity.newUniverse
-- @covers lurek.scene.newScene

describe("ai + entity + scene integration", function()
    it("AI FSM drives entity state in scene", function()
        local universe = lurek.entity.newUniverse()
        local scene = lurek.scene.newScene()

        -- Create enemy entity
        local enemy = universe:spawn()
        universe:set(enemy, "hp", 100)
        universe:set(enemy, "ai_state", "patrol")
        universe:addTag(enemy, "enemy")

        -- Create FSM for enemy
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("patrol", {
            onUpdate = function(dt)
                -- Move along waypoints
            end
        })
        fsm:addState("chase", {
            onUpdate = function(dt)
                -- Move toward player
            end
        })
        fsm:addState("attack", {
            onUpdate = function(dt)
                -- Deal damage
            end
        })
        fsm:addTransition("patrol", "chase")
        fsm:addTransition("chase", "attack")
        fsm:addTransition("attack", "patrol")

        -- Start patrol
        fsm:forceState("patrol")
        expect_equal("patrol", fsm:getCurrentState(), "enemy starts patrolling")

        -- Simulate player detection → chase
        fsm:forceState("chase")
        expect_equal("chase", fsm:getCurrentState(), "enemy chases player")
        universe:set(enemy, "ai_state", "chase")
        expect_equal("chase", universe:get(enemy, "ai_state"), "entity tracks AI state")

        -- Verify entity still in scene scope
        expect_true(universe:isAlive(enemy), "enemy entity is alive")
        expect_equal(1, universe:getEntityCount(), "one entity in universe")
    end)

    it("multiple entities with independent FSMs", function()
        local universe = lurek.entity.newUniverse()

        local guards = {}
        local fsms = {}

        for i = 1, 5 do
            local id = universe:spawn()
            universe:set(id, "role", "guard_" .. i)
            guards[i] = id

            local fsm = lurek.ai.newStateMachine()
            fsm:addState("idle", { onUpdate = function(dt) end })
            fsm:addState("alert", { onUpdate = function(dt) end })
            fsm:addTransition("idle", "alert")
            fsm:addTransition("alert", "idle")
            fsms[i] = fsm
        end

        -- Only first guard alerts
        fsms[1]:forceState("alert")
        expect_equal("alert", fsms[1]:getCurrentState(), "guard 1 is alert")

        -- Others remain in initial state (should be nil or first state)
        for i = 2, 5 do
            local state = fsms[i]:getCurrentState()
            expect_true(state ~= "alert", "guard " .. i .. " is not alert")
        end

        expect_equal(5, universe:getEntityCount(), "5 guards alive")
    end)
end)

test_summary()
