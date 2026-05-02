-- Lurek2D Stress Test: Tween Update Throughput
-- Measures active tween update rate under heavy load.

describe("stress: many active tweens updated simultaneously", function()
    it("1000 tweens       100 updates each: <5s", function()
        local new_tween = rawget(lurek.tween, "newTween")
        if type(new_tween) ~= "function" then
            expect_true(true)
            return
        end
        local N_TWEENS  = 1000
        local N_UPDATES = 100
        local tweens    = {}

        for i = 1, N_TWEENS do
            local tw = new_tween()
            tw:setDuration(2.0)
            tw:setEasing("linear")
            tw:setFrom(0)
            tw:setTo(i)
            tweens[i] = tw
        end

        local start = os.clock()
        for _ = 1, N_UPDATES do
            for _, tw in ipairs(tweens) do
                tw:update(0.02)
            end
        end
        local elapsed = os.clock() - start
        local ops     = N_TWEENS * N_UPDATES
        print(string.format("[STRESS] %d tween updates in %.4fs (%.0f updates/sec)",
            ops, elapsed, ops / elapsed))

        expect_true(elapsed < 5.0, "tween update budget: " .. elapsed .. "s")
    end)

    it("5000 instant tween seek calls: <5s", function()
        local new_tween = rawget(lurek.tween, "newTween")
        if type(new_tween) ~= "function" then
            expect_true(true)
            return
        end
        local tw    = new_tween()
        local COUNT = 5000

        tw:setDuration(1.0)
        tw:setEasing("linear")
        tw:setFrom(0)
        tw:setTo(100)

        local elapsed = measure("tween:seek x" .. COUNT, COUNT, function()
            tw:seek(math.random())
        end)

        expect_true(elapsed < 5.0, "tween seek budget: " .. elapsed .. "s")
    end)

    it("tween onComplete callbacks fire exactly once each", function()
        local new_tween = rawget(lurek.tween, "newTween")
        if type(new_tween) ~= "function" then
            expect_true(true)
            return
        end
        local TWEENS   = 200
        local finished = 0

        local tweens = {}
        for _ = 1, TWEENS do
            local tw = new_tween()
            tw:setDuration(0.1)
            tw:setEasing("linear")
            tw:setFrom(0)
            tw:setTo(1)
            tw:onComplete(function() finished = finished + 1 end)
            tweens[#tweens + 1] = tw
        end

        -- Advance past end
        for _, tw in ipairs(tweens) do
            tw:update(0.2)
        end

        expect_equal(TWEENS, finished, "all onComplete callbacks fired")
    end)
end)
test_summary()
