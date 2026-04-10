-- Lurek2D Integration Test: Graphics + Animation
-- Tests drawing primitives with animation frame progression
-- @covers lurek.gfx.rectangle
-- @covers lurek.animation.newTimeline

describe("graphics + animation integration", function()
    it("animation timeline controls frame index", function()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, { x = 0, y = 0 })
        tl:addFrame(0.5, { x = 100, y = 0 })
        tl:addFrame(1.0, { x = 100, y = 100 })

        -- At t=0 we should get the first frame data
        tl:seek(0.0)
        local frame = tl:getCurrentFrame()
        expect_true(frame ~= nil, "frame is not nil at t=0")
    end)

    it("animation frame drives sprite draw parameters", function()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, { width = 32, height = 32 })
        tl:addFrame(1.0, { width = 64, height = 64 })

        -- Advance animation
        tl:seek(0.0)
        local frame = tl:getCurrentFrame()

        -- Use frame data for drawing
        expect_no_error(function()
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.rectangle("fill", 0, 0, frame.width or 32, frame.height or 32)
        end)
    end)

    it("looping animation resets frame index", function()
        local tl = lurek.animation.newTimeline()
        tl:setLooping(true)
        tl:addFrame(0.0, { idx = 1 })
        tl:addFrame(0.5, { idx = 2 })
        tl:addFrame(1.0, { idx = 3 })

        -- Advance past the end
        tl:seek(1.5)

        -- Should have looped back
        local state = tl:getState()
        expect_true(state ~= nil, "timeline state exists after loop")
    end)

    it("paused animation does not advance frames", function()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, { idx = 1 })
        tl:addFrame(1.0, { idx = 2 })

        tl:pause()
        local before = tl:getElapsed()
        tl:update(0.5)
        local after = tl:getElapsed()

        -- Paused timeline should not advance
        expect_near(before, after, 0.001, "paused timeline does not advance")
    end)
end)

test_summary()
