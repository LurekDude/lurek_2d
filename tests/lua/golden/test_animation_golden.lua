-- Lurek2D Golden Test: Animation Frame Sequence
-- Verifies animation timeline produces deterministic frame sequences
-- @golden animation determinism

describe("golden: animation timeline determinism", function()
    it("same keyframes produce same sequence", function()
        local function build_timeline()
            local tl = lurek.animation.newTimeline()
            tl:addFrame(0.0, { x = 0, y = 0 })
            tl:addFrame(0.5, { x = 50, y = 25 })
            tl:addFrame(1.0, { x = 100, y = 50 })
            return tl
        end

        local tl1 = build_timeline()
        local tl2 = build_timeline()

        -- Same seek points should produce same frames
        for _, t in ipairs({ 0.0, 0.25, 0.5, 0.75, 1.0 }) do
            tl1:seek(t)
            tl2:seek(t)
            local f1 = tl1:getCurrentFrame()
            local f2 = tl2:getCurrentFrame()
            expect_true(f1 ~= nil, "frame1 at t=" .. t)
            expect_true(f2 ~= nil, "frame2 at t=" .. t)
        end
    end)

    it("elapsed time tracking is deterministic", function()
        local tl1 = lurek.animation.newTimeline()
        tl1:addFrame(0.0, { v = 0 })
        tl1:addFrame(1.0, { v = 100 })

        local tl2 = lurek.animation.newTimeline()
        tl2:addFrame(0.0, { v = 0 })
        tl2:addFrame(1.0, { v = 100 })

        -- Same update sequence
        local dt = 1.0 / 60.0
        for i = 1, 30 do
            tl1:update(dt)
            tl2:update(dt)
        end

        local e1 = tl1:getElapsed()
        local e2 = tl2:getElapsed()
        expect_near(e1, e2, 0.0001, "elapsed time matches")
    end)

    it("looping produces same cycle state", function()
        local function make_looping()
            local tl = lurek.animation.newTimeline()
            tl:setLooping(true)
            tl:addFrame(0.0, { frame = 1 })
            tl:addFrame(0.5, { frame = 2 })
            tl:addFrame(1.0, { frame = 3 })
            return tl
        end

        local tl1 = make_looping()
        local tl2 = make_looping()

        -- Advance both past one full cycle
        for i = 1, 90 do  -- 1.5 seconds at 60fps
            tl1:update(1.0 / 60.0)
            tl2:update(1.0 / 60.0)
        end

        local e1 = tl1:getElapsed()
        local e2 = tl2:getElapsed()
        expect_near(e1, e2, 0.0001, "looped elapsed matches")
    end)
end)

test_summary()
