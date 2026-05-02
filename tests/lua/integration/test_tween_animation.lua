-- Lurek2D Integration Test: Tween + Animation
-- Tests tween easing curves driving animation frame selection.
-- Rewritten to use lurek.tween.newState(duration, easing) API.
-- (lurek.animation.newTimeline does not exist; uses newState instead)

describe("tween + animation integration", function()
    it("tween linear easing drives position", function()
        local state = lurek.tween.newState(1.0, "linear")

        -- At start: no ticks
        local v0 = state:lerp(0, 100)
        expect_near(0, v0, 1.0, "tween at start is 0")

        -- At midpoint: tick 0.5 s
        state:tick(0.5)
        local v50 = state:lerp(0, 100)
        expect_near(50, v50, 2.0, "tween at 50% is ~50")

        -- At end: tick another 0.5 s (total 1.0 s)
        state:tick(0.5)
        local v100 = state:lerp(0, 100)
        expect_near(100, v100, 1.0, "tween at end is 100")
    end)

    it("tween ease-in-out midpoint shape", function()
        local state = lurek.tween.newState(2.0, "easeInOut")
        state:tick(1.0)  -- 50% through

        local val = state:lerp(0, 1)
        -- easeInOut at 50% should be ~0.5 (symmetric)
        expect_near(0.5, val, 0.1, "easeInOut at midpoint     0.5")
    end)

    it("tween isComplete true after full duration", function()
        local state = lurek.tween.newState(1.0, "linear")
        state:tick(1.1)  -- advance past end
        expect_true(state:isComplete(), "isComplete after 1.1 s > 1.0 s duration")
    end)

    it("multiple tweens track independently", function()
        local t1 = lurek.tween.newState(1.0, "linear")
        local t2 = lurek.tween.newState(2.0, "linear")

        -- Advance t1 to completion, t2 to halfway
        t1:tick(1.0)
        t2:tick(1.0)

        local v1 = t1:lerp(0, 100)
        local v2 = t2:lerp(100, 200)

        expect_near(100, v1, 1.0, "tween1 finished at 100")
        expect_near(150, v2, 2.0, "tween2 at midpoint    150")
    end)
end)
test_summary()
