-- Lurek2D Stress Test: Savegame Collect/Restore Cycles
-- Measures serialization throughput for large game state.

-- @description Covers suite: stress: savegame collect cycles.
describe("stress: savegame collect cycles", function()
    -- @covers lurek.save.newSaveManager
    -- @covers SaveManager:register
    -- @covers SaveManager:collect
    -- @stress Performs 100 savegame collection cycles over a registered 100-key snapshot handler.
    -- @description Stresses snapshot serialization throughput by cloning a moderately sized Lua table into save data on every measured collect call.
    it("100 savegame collect cycles in <10s", function()
        local COUNT = 100
        local sm    = lurek.save.newSaveManager()

        -- Register a handler that serializes 100 values
        local game_state = {}
        for i = 1, 100 do
            game_state["key_" .. i] = i * math.pi
        end

        sm:register("data", function()
            local snapshot = {}
            for k, v in pairs(game_state) do
                snapshot[k] = v
            end
            return snapshot
        end, function(data)
            if data then
                for k, v in pairs(data) do
                    game_state[k] = v
                end
            end
        end)

        local elapsed = measure("savegame:collect x" .. COUNT, COUNT, function()
            sm:collect()
        end)

        expect_true(elapsed < 10.0, "savegame collect budget: " .. elapsed .. "s")
    end)

    -- @covers lurek.save.newSaveManager
    -- @covers SaveManager:setSummary
    -- @covers SaveManager:getSummary
    -- @stress Performs 1000 summary write-read pairs on one save manager.
    -- @description Stresses lightweight metadata churn by repeatedly setting and immediately fetching a summary entry with randomized content.
    it("summary set/get 1000 times in <5s", function()
        local COUNT = 1000
        local sm    = lurek.save.newSaveManager()

        local elapsed = measure("savegame:setSummary+getSummary x" .. COUNT, COUNT, function()
            sm:setSummary("iteration", math.random())
            local _ = sm:getSummary("iteration")
        end)

        expect_true(elapsed < 5.0, "summary r/w budget: " .. elapsed .. "s")
    end)
end)
test_summary()
