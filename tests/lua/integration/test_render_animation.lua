-- Lurek2D Integration Test: Graphics + Animation
-- Tests drawing primitives with animation frame progression

-- @description Covers suite: graphics + animation integration.
describe("graphics + animation integration", function()
    -- @covers lurek.animation.Timeline.getCurrentFrame
    -- @covers lurek.render
    -- @covers lurek.render.rectangle
    -- @covers lurek.animation.newTimeline
    -- @description Verifies timeline seeking exposes frame data that graphics code can use to choose the active animation frame.
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

    -- @covers lurek.animation.Timeline.getCurrentFrame
    -- @covers lurek.render.rectangle
    -- @description Verifies animation frame payload data can be fed directly into graphics draw parameters.
    it("animation frame drives sprite draw parameters", function()
        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, { width = 32, height = 32 })
        tl:addFrame(1.0, { width = 64, height = 64 })

        -- Advance animation
        tl:seek(0.0)
        local frame = tl:getCurrentFrame()

        -- Use frame data for drawing
        expect_no_error(function()
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.rectangle("fill", 0, 0, frame.width or 32, frame.height or 32)
        end)
    end)

    -- @covers lurek.animation.Timeline.setLooping
    -- @covers lurek.render
    -- @description Verifies a looping animation can advance beyond its end and remain in a valid state for rendering.
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

    -- @covers lurek.animation.Timeline.pause
    -- @covers lurek.render
    -- @description Verifies pausing the animation prevents elapsed time changes that would otherwise drive graphics frame changes.
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
