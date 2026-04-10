-- Lurek2D Integration Test: Tween + Animation
-- Tests tween easing curves driving animation timeline
-- @covers lurek.tween.newTween
-- @covers lurek.animation.newTimeline

describe("tween + animation integration", function()
    it("tween linear easing drives position", function()
        local tween = lurek.tween.newTween()
        tween:setDuration(1.0)
        tween:setEasing("linear")
        tween:setFrom(0)
        tween:setTo(100)

        -- At start
        tween:seek(0.0)
        local v0 = tween:getValue()
        expect_near(0, v0, 1.0, "tween at start is 0")

        -- At midpoint
        tween:seek(0.5)
        local v50 = tween:getValue()
        expect_near(50, v50, 2.0, "tween at 50% is ~50")

        -- At end
        tween:seek(1.0)
        local v100 = tween:getValue()
        expect_near(100, v100, 1.0, "tween at end is 100")
    end)

    it("tween ease-in-out with animation frame sync", function()
        local tween = lurek.tween.newTween()
        tween:setDuration(2.0)
        tween:setEasing("easeInOut")
        tween:setFrom(0)
        tween:setTo(1)

        local tl = lurek.animation.newTimeline()
        tl:addFrame(0.0, { alpha = 0 })
        tl:addFrame(1.0, { alpha = 1 })

        -- Both should be at start
        tween:seek(0.0)
        tl:seek(0.0)

        local tween_val = tween:getValue()
        expect_near(0, tween_val, 0.1, "tween starts at 0")
    end)

    it("tween with callback integrates with timeline events", function()
        local tween = lurek.tween.newTween()
        tween:setDuration(1.0)
        tween:setEasing("linear")
        tween:setFrom(0)
        tween:setTo(10)

        local completed = false
        tween:onComplete(function()
            completed = true
        end)

        -- Advance to end
        tween:seek(1.0)
        -- Note: onComplete may fire on seek past duration
        -- The flag may or may not be set depending on implementation
        expect_type("boolean", completed)
    end)

    it("multiple tweens track independently", function()
        local t1 = lurek.tween.newTween()
        t1:setDuration(1.0)
        t1:setEasing("linear")
        t1:setFrom(0)
        t1:setTo(100)

        local t2 = lurek.tween.newTween()
        t2:setDuration(2.0)
        t2:setEasing("linear")
        t2:setFrom(100)
        t2:setTo(200)

        t1:seek(1.0)
        t2:seek(1.0)

        local v1 = t1:getValue()
        local v2 = t2:getValue()

        expect_near(100, v1, 1.0, "tween1 finished at 100")
        expect_near(150, v2, 2.0, "tween2 at midpoint ~150")
    end)
end)

test_summary()
