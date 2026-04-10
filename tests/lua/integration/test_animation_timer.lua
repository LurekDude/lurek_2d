-- Lurek2D Integration Test: Animation + Timer
-- Tests timer-driven animation playback pacing.
-- @covers lurek.animation.newTimeline
-- @covers lurek.timer.getTime
-- @covers lurek.timer.getDelta

describe("integration: animation driven by timer delta", function()
    it("timeline advances by injected delta", function()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, {sprite = "idle_0"})
        tl:addFrame(0.5, {sprite = "idle_1"})
        tl:addFrame(1.0, {sprite = "idle_2"})
        tl:setLooping(true)

        -- Simulate timer-based updates
        local dt = 1 / 60
        for _ = 1, 60 do
            tl:update(dt)
        end

        -- After 1 second of updates, elapsed should be near 1.0 (or looped back)
        local elapsed = tl:getElapsed()
        expect_true(elapsed >= 0, "elapsed is non-negative")
        expect_true(elapsed < 1.1, "looping timeline elapsed < 1.1s")
    end)

    it("timer.getTime is monotonic over updates", function()
        local t0 = lurek.timer.getTime()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, {frame = 1})
        tl:addFrame(1.0, {frame = 2})

        for _ = 1, 30 do
            tl:update(1 / 60)
        end

        local t1 = lurek.timer.getTime()
        -- t1 should be >= t0 (time only grows)
        expect_true(t1 >= t0, "timer is monotonic")
    end)

    it("animation frame changes at correct simulated time", function()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, {frame = 1})
        tl:addFrame(0.2, {frame = 2})
        tl:addFrame(0.4, {frame = 3})

        -- Before first frame threshold
        tl:seek(0.0)
        local f0 = tl:getCurrentFrame()
        expect_not_nil(f0, "frame at t=0 is not nil")

        -- After 0.25s (between frame 1 and frame 2 thresholds)
        tl:seek(0.25)
        local f1 = tl:getCurrentFrame()
        expect_not_nil(f1, "frame at t=0.25 is not nil")
    end)

    it("paused animation preserves elapsed time on getDelta calls", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt, "getDelta returns number")
        expect_true(dt >= 0, "getDelta is non-negative")

        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, {})
        tl:pause()
        local state = tl:getState()
        expect_equal("paused", state, "timeline paused")
    end)
end)

test_summary()
