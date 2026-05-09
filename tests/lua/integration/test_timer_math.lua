-- Integration: lurek.tween.newState easing output cross-checked against lurek.math easing functions

-- @integration lurek.tween.newState
-- @integration LTweenState:tick
-- @integration LTweenState:lerp
-- @integration lurek.math.inQuad
describe("timer + tween easing integration", function()

    it("tween inQuad output matches lurek.math.inQuad at t=0.5", function()
        local tw = lurek.tween.newState(1.0, "quadIn")
        tw:tick(0.5)
        -- tw:lerp(0,1) returns the eased value; tw:t() returns raw linear progress
        local engine_eased = tw:lerp(0.0, 1.0)
        local math_eased   = lurek.math.inQuad(0.5)
        expect_near(math_eased, engine_eased, 0.001, "tween quadIn == lurek.math.inQuad at 0.5")
    end)

    -- @integration LTweenState:tick
    -- @integration LTweenState:lerp
    -- @integration lurek.math.outQuad
    it("tween outQuad output matches lurek.math.outQuad at t=0.5", function()
        local tw = lurek.tween.newState(1.0, "quadOut")
        tw:tick(0.5)
        local engine_eased = tw:lerp(0.0, 1.0)
        local math_eased   = lurek.math.outQuad(0.5)
        expect_near(math_eased, engine_eased, 0.001, "tween quadOut == lurek.math.outQuad at 0.5")
    end)

    -- @integration LTweenState:tick
    -- @integration LTweenState:lerp
    -- @integration lurek.math.inOutCubic
    it("tween inOutCubic output matches lurek.math.inOutCubic at midpoint", function()
        local tw = lurek.tween.newState(1.0, "cubicInOut")
        tw:tick(0.5)
        local engine_eased = tw:lerp(0.0, 1.0)
        local math_eased   = lurek.math.inOutCubic(0.5)
        expect_near(math_eased, engine_eased, 0.001, "tween cubicInOut == lurek.math.inOutCubic at 0.5")
    end)

    -- @integration LTweenState:tick
    -- @integration LTweenState:isComplete
    -- @integration LTweenState:lerp
    -- @integration lurek.math.distance
    it("tween lerp drives a position tracked by lurek.math.distance", function()
        local tw = lurek.tween.newState(1.0, "linear")
        local start_x, end_x = 0.0, 100.0
        tw:tick(0.5)
        local pos_x = tw:lerp(start_x, end_x)
        -- Distance from origin to current position should be ~50
        local dist = lurek.math.distance(0, 0, pos_x, 0)
        expect_near(50.0, dist, 0.1, "tween lerp + math.distance agree at t=0.5")
        expect_false(tw:isComplete(), "tween not complete at t=0.5")

        tw:tick(0.5)
        expect_true(tw:isComplete(), "tween complete after full duration")
    end)

end)
test_summary()
