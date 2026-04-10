-- Lurek2D Stress Test: Savegame Collect/Restore Cycles
-- Measures serialization throughput for large game state.
-- @stress lurek.savegame.newSaveManager

describe("stress: savegame collect cycles", function()
    it("100 savegame collect cycles in <10s", function()
        local COUNT = 100
        local sm    = lurek.savegame.newSaveManager()

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

    it("summary set/get 1000 times in <5s", function()
        local COUNT = 1000
        local sm    = lurek.savegame.newSaveManager()

        local elapsed = measure("savegame:setSummary+getSummary x" .. COUNT, COUNT, function()
            sm:setSummary("iteration", math.random())
            local _ = sm:getSummary("iteration")
        end)

        expect_true(elapsed < 5.0, "summary r/w budget: " .. elapsed .. "s")
    end)
end)

test_summary()
