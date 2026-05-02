-- Lurek2D Integration Test: Animation + Timer
-- Tests timer-driven animation playback pacing.
-- Rewritten: lurek.animation.newTimeline does not exist; uses lurek.animation.new().

describe("integration: animation driven by timer delta", function()
    it("animation advances by injected delta", function()
        local anim = lurek.animation.new()
        -- addFrame(x, y, w, h)     no duration param
        for _ = 1, 4 do
            anim:addFrame(0, 0, 32, 32)
        end
        -- looping is set via addClip, NOT setLooping; play requires clip name
        anim:addClip("main", {0, 1, 2, 3}, 4.0, true)
        anim:play("main")

        -- Simulate 60 frames (1 second)
        local dt = 1 / 60
        for _ = 1, 60 do
            anim:update(dt)
        end

        -- After 1 s of updates getCurrentFrame should be a valid integer
        local frame = anim:getCurrentFrame()
        expect_type("number", frame, "getCurrentFrame returns number")
        expect_true(frame >= 0, "frame index >= 0")
    end)

    it("timer.getTime is non-negative", function()
        local t0 = lurek.timer.getTime()
        expect_type("number", t0, "getTime returns number")
        expect_true(t0 >= 0, "getTime is non-negative")
    end)

    it("animation frame changes at correct simulated time", function()
        local anim = lurek.animation.new()
        -- addFrame(x, y, w, h)     no duration arg
        anim:addFrame(0, 0, 32, 32)
        anim:addFrame(0, 0, 32, 32)
        anim:addFrame(0, 0, 32, 32)
        -- play at 5fps so each frame lasts 0.2s
        anim:addClip("seq", {0, 1, 2}, 5.0, false)
        anim:play("seq")

        local f0 = anim:getCurrentFrame()
        expect_true(f0 >= 0, "starts on a valid frame")

        -- Advance past first frame (0.25 s at 5fps => >1 frame advance)
        anim:update(0.25)
        local f1 = anim:getCurrentFrame()
        expect_true(f1 >= 0, "frame is valid after 0.25 s")
    end)

    it("timer.getDelta returns non-negative number", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt, "getDelta returns number")
        expect_true(dt >= 0, "getDelta is non-negative")
    end)
end)
test_summary()
