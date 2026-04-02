-- -------------------------------------------------------------------
describe("Tween creation", function()
    it("creates a Tween with duration and default easing", function()
        local tw = luna.math.newTween(1.0)
        expect_type("userdata", tw)
    end)

    it("creates a Tween with duration and explicit easing", function()
        local tw = luna.math.newTween(2.0, "inQuad")
        expect_type("userdata", tw)
    end)

    it("getDuration returns the set duration", function()
        local tw = luna.math.newTween(3.5)
        expect_near(3.5, tw:getDuration())
    end)

    it("starts with clock at 0", function()
        local tw = luna.math.newTween(1.0)
        expect_near(0.0, tw:getClock())
    end)

    it("starts not complete", function()
        local tw = luna.math.newTween(1.0)
        expect_equal(false, tw:isComplete())
    end)

    it("starts with 0 values", function()
        local tw = luna.math.newTween(1.0)
        expect_equal(0, tw:getValueCount())
    end)
end)

-- -------------------------------------------------------------------
describe("Tween addValue", function()
    it("addValue returns 1-based index", function()
        local tw = luna.math.newTween(1.0)
        local idx1 = tw:addValue(0, 100)
        local idx2 = tw:addValue(50, 200)
        expect_equal(1, idx1)
        expect_equal(2, idx2)
    end)

    it("getValueCount increases with addValue", function()
        local tw = luna.math.newTween(1.0)
        tw:addValue(0, 100)
        expect_equal(1, tw:getValueCount())
        tw:addValue(10, 20)
        expect_equal(2, tw:getValueCount())
    end)
end)

-- -------------------------------------------------------------------
describe("Tween linear interpolation", function()
    it("at t=0 returns start value", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)
        expect_near(0.0, tw:getValue(1))
    end)

    it("at t=0.5 returns midpoint", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)
        tw:set(0.5)
        expect_near(50.0, tw:getValue(1))
    end)

    it("at t=1.0 returns target value", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)
        tw:set(1.0)
        expect_near(100.0, tw:getValue(1))
    end)

    it("negative start and target work", function()
        local tw = luna.math.newTween(2.0, "linear")
        tw:addValue(-50, 50)
        tw:set(1.0) -- halfway
        expect_near(0.0, tw:getValue(1))
    end)
end)

-- -------------------------------------------------------------------
describe("Tween update", function()
    it("update advances the clock", function()
        local tw = luna.math.newTween(2.0, "linear")
        tw:addValue(0, 100)
        tw:update(0.5)
        expect_near(0.5, tw:getClock())
    end)

    it("update returns false when not complete", function()
        local tw = luna.math.newTween(2.0)
        tw:addValue(0, 100)
        local done = tw:update(0.5)
        expect_equal(false, done)
    end)

    it("update returns true when complete", function()
        local tw = luna.math.newTween(1.0)
        tw:addValue(0, 100)
        local done = tw:update(1.5)
        expect_equal(true, done)
    end)

    it("value clamps at target after completion", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)
        tw:update(5.0) -- way past duration
        expect_near(100.0, tw:getValue(1))
    end)
end)

-- -------------------------------------------------------------------
describe("Tween set and reset", function()
    it("set moves clock to specific time", function()
        local tw = luna.math.newTween(4.0, "linear")
        tw:addValue(0, 200)
        tw:set(2.0)
        expect_near(2.0, tw:getClock())
        expect_near(100.0, tw:getValue(1))
    end)

    it("set clamps to duration", function()
        local tw = luna.math.newTween(1.0)
        tw:set(5.0)
        expect_near(1.0, tw:getClock())
    end)

    it("set clamps to 0 for negative", function()
        local tw = luna.math.newTween(1.0)
        tw:set(-1.0)
        expect_near(0.0, tw:getClock())
    end)

    it("reset moves clock back to 0", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)
        tw:update(0.5)
        tw:reset()
        expect_near(0.0, tw:getClock())
        expect_near(0.0, tw:getValue(1))
    end)

    it("isComplete false after reset", function()
        local tw = luna.math.newTween(1.0)
        tw:update(2.0)
        expect_equal(true, tw:isComplete())
        tw:reset()
        expect_equal(false, tw:isComplete())
    end)
end)

-- -------------------------------------------------------------------
describe("Tween multiple values", function()
    it("interpolates multiple values independently", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)   -- value 1
        tw:addValue(100, 0)   -- value 2 (reverse)
        tw:set(0.5)
        expect_near(50.0, tw:getValue(1))
        expect_near(50.0, tw:getValue(2))
    end)

    it("getValue() with no index returns table of all values", function()
        local tw = luna.math.newTween(1.0, "linear")
        tw:addValue(0, 100)
        tw:addValue(200, 400)
        tw:set(0.5)
        local vals = tw:getValue()
        expect_type("table", vals)
        expect_equal(2, #vals)
        expect_near(50.0, vals[1])
        expect_near(300.0, vals[2])
    end)
end)

-- -------------------------------------------------------------------
describe("Tween easing functions", function()
    it("inQuad easing produces different curve than linear", function()
        local lin = luna.math.newTween(1.0, "linear")
        lin:addValue(0, 100)
        lin:set(0.5)
        local lin_val = lin:getValue(1)

        local quad = luna.math.newTween(1.0, "inQuad")
        quad:addValue(0, 100)
        quad:set(0.5)
        local quad_val = quad:getValue(1)

        -- inQuad at t=0.5 should be 0.25 (t^2) → 25, not 50
        expect_near(50.0, lin_val)
        expect_near(25.0, quad_val)
    end)

    it("outQuad easing at midpoint", function()
        local tw = luna.math.newTween(1.0, "outQuad")
        tw:addValue(0, 100)
        tw:set(0.5)
        -- outQuad at t=0.5 should be ~75
        expect_near(75.0, tw:getValue(1))
    end)

    it("all easings start at 0 and end at target", function()
        local easings = {"linear", "inQuad", "outQuad", "inCubic", "outCubic",
                         "inSine", "outSine", "inExpo", "outExpo"}
        for _, name in ipairs(easings) do
            local tw = luna.math.newTween(1.0, name)
            tw:addValue(0, 100)

            tw:set(0.0)
            expect_near(0.0, tw:getValue(1), 1.0)

            tw:set(1.0)
            expect_near(100.0, tw:getValue(1), 1.0)
        end
    end)

    it("unknown easing falls back to linear", function()
        local tw = luna.math.newTween(1.0, "nonexistent")
        tw:addValue(0, 100)
        tw:set(0.5)
        expect_near(50.0, tw:getValue(1))
    end)
end)

-- -------------------------------------------------------------------
describe("Tween zero duration", function()
    it("zero duration tween is immediately complete", function()
        local tw = luna.math.newTween(0.0, "linear")
        tw:addValue(0, 100)
        expect_equal(true, tw:isComplete())
    end)

    it("zero duration returns target value", function()
        local tw = luna.math.newTween(0.0, "linear")
        tw:addValue(0, 100)
        expect_near(100.0, tw:getValue(1))
    end)
end)

test_summary()
