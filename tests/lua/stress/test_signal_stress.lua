-- Lurek2D Stress Test: Signal Dispatch Throughput
-- Measures signal emit performance under high listener counts.
-- @stress lurek.signal.new

describe("stress: signal emit to many listeners", function()
    it("1 signal × 1000 listeners × 100 emits: <5s", function()
        local sig      = lurek.signal.new()
        local LISTENERS = 100
        local EMITS     = 1000
        local count     = 0

        for _ = 1, LISTENERS do
            sig:connect(function()
                count = count + 1
            end)
        end

        local start = os.clock()
        for _ = 1, EMITS do
            sig:emit()
        end
        local elapsed = os.clock() - start
        local dispatches = LISTENERS * EMITS
        print(string.format("[STRESS] signal: %d dispatches in %.4fs (%.0f/sec)",
            dispatches, elapsed, dispatches / elapsed))

        expect_true(elapsed < 5.0, "signal dispatch budget: " .. elapsed .. "s")
        expect_equal(dispatches, count, "all listeners fired")
    end)

    it("signal connect/disconnect 5000 times in <5s", function()
        local sig   = lurek.signal.new()
        local COUNT = 5000

        local elapsed = measure("signal connect+disconnect x" .. COUNT, COUNT, function()
            local conn = sig:connect(function() end)
            conn:disconnect()
        end)

        expect_true(elapsed < 5.0, "connect/disconnect budget: " .. elapsed .. "s")
    end)

    it("10 signals × 100 listeners × 1000 emits each: <10s", function()
        local N_SIGS    = 10
        local N_LISTEN  = 100
        local N_EMITS   = 1000
        local total     = 0
        local sigs      = {}

        for _ = 1, N_SIGS do
            local s = lurek.signal.new()
            for _ = 1, N_LISTEN do
                s:connect(function() total = total + 1 end)
            end
            sigs[#sigs + 1] = s
        end

        local start = os.clock()
        for _, s in ipairs(sigs) do
            for _ = 1, N_EMITS do s:emit() end
        end
        local elapsed = os.clock() - start
        print(string.format("[STRESS] 10 sigs × 100×1000: elapsed=%.4fs", elapsed))

        expect_true(elapsed < 10.0, "multi-signal budget: " .. elapsed .. "s")
        expect_equal(N_SIGS * N_LISTEN * N_EMITS, total, "all dispatches fired")
    end)
end)

test_summary()
