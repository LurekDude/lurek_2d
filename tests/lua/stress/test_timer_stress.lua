-- Lurek2D Stress Test: Timer Operations
-- Measures timer query throughput under heavy polling.

describe("stress: timer query throughput", function()
    it("getTime called 100000 times in <5s", function()
        local COUNT   = 100000
        local elapsed = measure("timer.getTime x" .. COUNT, COUNT, function()
            local _ = lurek.timer.getTime()
        end)
        expect_true(elapsed < 5.0, "getTime budget: " .. elapsed .. "s")
    end)

    it("getDelta called 100000 times in <5s", function()
        local COUNT   = 100000
        local elapsed = measure("timer.getDelta x" .. COUNT, COUNT, function()
            local _ = lurek.timer.getDelta()
        end)
        expect_true(elapsed < 5.0, "getDelta budget: " .. elapsed .. "s")
    end)

    it("getFPS called 100000 times in <5s", function()
        local COUNT   = 100000
        local elapsed = measure("timer.getFPS x" .. COUNT, COUNT, function()
            local _ = lurek.timer.getFPS()
        end)
        expect_true(elapsed < 5.0, "getFPS budget: " .. elapsed .. "s")
    end)

    it("mixed timer queries 300000 total in <10s", function()
        local COUNT = 300000
        local start = os.clock()
        for i = 1, COUNT do
            if i % 3 == 0 then
                local _ = lurek.timer.getTime()
            elseif i % 3 == 1 then
                local _ = lurek.timer.getDelta()
            else
                local _ = lurek.timer.getFPS()
            end
        end
        local elapsed = os.clock() - start
        local ops_sec = COUNT / elapsed
        print(string.format("[STRESS] mixed timer queries: %d ops in %.4fs (%.0f ops/sec)",
            COUNT, elapsed, ops_sec))
        expect_true(elapsed < 10.0, "mixed timer budget: " .. elapsed .. "s")
    end)
end)
test_summary()
