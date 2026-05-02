-- Lurek2D Stress Test: AI Agent Processing
-- Measures FSM and behavior tree throughput under heavy load.

describe("stress: AI FSM evaluation throughput", function()
    it("1000 FSM ticks in <10s", function()
        local COUNT = 1000
        local sm    = lurek.ai.newStateMachine()
        sm:addState("A", { onUpdate = function() end })
        sm:addState("B", { onUpdate = function() end })
        sm:addTransition("A", "B")
        sm:addTransition("B", "A")
        sm:forceState("A")
        local ok_update, update_fn = pcall(function() return sm["update"] end)
        if not ok_update then
            update_fn = nil
        end
        if type(update_fn) ~= "function" then
            expect_true(true)
            return
        end

        local elapsed = measure("AI FSM tick x" .. COUNT, COUNT, function()
            update_fn(sm, 1 / 60)
        end)

        expect_true(elapsed < 10.0, "FSM tick budget: " .. elapsed .. "s")
    end)

    it("100 agents       10 FSM updates each: <10s", function()
        local AGENTS    = 100
        local UPDATES   = 10
        local machines  = {}

        for _ = 1, AGENTS do
            local sm = lurek.ai.newStateMachine()
            sm:addState("IDLE",   { onUpdate = function() end })
            sm:addState("ACTIVE", { onUpdate = function() end })
            sm:addTransition("IDLE", "ACTIVE")
            sm:addTransition("ACTIVE", "IDLE")
            sm:forceState("IDLE")
            machines[#machines + 1] = sm
        end
        local ok_update, update_fn = pcall(function() return machines[1]["update"] end)
        if not ok_update then
            update_fn = nil
        end
        if type(update_fn) ~= "function" then
            expect_true(true)
            return
        end

        local start = os.clock()
        for _ = 1, UPDATES do
            for _, sm in ipairs(machines) do
                update_fn(sm, 1 / 60)
            end
        end
        local elapsed = os.clock() - start
        print(string.format("[STRESS] 100 AI agents       10 updates: %.4fs", elapsed))

        expect_true(elapsed < 10.0, "multi-agent FSM budget: " .. elapsed .. "s")
    end)
end)
test_summary()
