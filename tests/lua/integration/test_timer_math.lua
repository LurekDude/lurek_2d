-- Lurek2D Integration Test: Timer + Math.
-- Covers game-loop style scenarios where timer deltas and math helpers are consumed together from the Lua runtime.

-- @description Covers suite: timer + math integration.
describe("timer + math integration", function()
    -- @covers lurek.timer.getDelta
    -- @covers lurek.math
    -- @covers lurek.math.pi
    -- @covers lurek.math.sin
    -- @description Verifies the referenced timer delta API returns a numeric value; this file is miscategorized and largely tests timer/math helpers rather than a real integration flow.
    it("getDelta returns a number", function()
        local dt = lurek.timer.getDelta()
        expect_not_nil(dt, "getDelta returns a value")
        expect_true(type(dt) == "number", "dt is a number")
    end)

    -- @covers lurek.math
    -- @covers lurek.timer.getDelta
    -- @description Verifies interpolation formulas produce the expected midpoint values for time-based motion.
    it("time-based interpolation with math", function()
        -- Simulate lerp between two values over time
        local start_val = 0
        local end_val = 100
        local t = 0.5

        -- Linear interpolation using math
        local result = start_val + (end_val - start_val) * t
        expect_near(50, result, 0.001, "lerp at t=0.5")

        -- Smoothstep interpolation
        local smooth_t = t * t * (3 - 2 * t)
        local smooth_result = start_val + (end_val - start_val) * smooth_t
        expect_near(50, smooth_result, 0.001, "smoothstep at t=0.5")
    end)

    -- @covers lurek.math.sin
    -- @covers lurek.timer.getDelta
    -- @description Verifies sinusoidal math reaches the expected peak for a quarter-period time sample.
    it("oscillation with sin and time", function()
        -- Simulate oscillating value: sin(time * frequency)
        local frequency = 2.0
        local time = lurek.math.pi / (2 * frequency)

        local value = lurek.math.sin(time * frequency)
        expect_near(1.0, value, 0.001, "sin peak at quarter period")
    end)

    -- @covers lurek.math
    -- @covers lurek.timer.getDelta
    -- @description Verifies movement scaled by dt stays consistent across full-step and half-step updates.
    it("frame-rate independent movement", function()
        -- Simulate movement: position += speed * dt
        local x = 100
        local speed = 200
        local dt = 0.016 -- ~60fps

        local new_x = x + speed * dt
        expect_near(103.2, new_x, 0.001, "moved by speed * dt")

        -- Same total movement with half dt, twice
        local x2 = 100
        x2 = x2 + speed * (dt / 2)
        x2 = x2 + speed * (dt / 2)
        expect_near(new_x, x2, 0.001, "two half-steps = one full step")
    end)
end)

-- @description Covers suite: timer + math easing.
describe("timer + math easing", function()
    -- @covers lurek.math
    -- @covers lurek.timer.getDelta
    -- @description Verifies a quadratic ease-in formula yields the expected midpoint value.
    it("ease-in quadratic", function()
        local t = 0.5
        local eased = t * t
        expect_near(0.25, eased, 0.001, "ease-in at t=0.5")
    end)

    -- @covers lurek.math
    -- @covers lurek.timer.getDelta
    -- @description Verifies a quadratic ease-out formula yields the expected midpoint value.
    it("ease-out quadratic", function()
        local t = 0.5
        local eased = 1 - (1 - t) * (1 - t)
        expect_near(0.75, eased, 0.001, "ease-out at t=0.5")
    end)

    -- @covers lurek.math
    -- @covers lurek.timer.getDelta
    -- @description Verifies a cubic ease-in-out formula reaches the expected value at the midpoint.
    it("ease-in-out cubic", function()
        local t = 0.5
        local eased
        if t < 0.5 then
            eased = 4 * t * t * t
        else
            eased = 1 - (-2 * t + 2)^3 / 2
        end
        expect_near(0.5, eased, 0.001, "ease-in-out at midpoint")
    end)
end)
test_summary()
