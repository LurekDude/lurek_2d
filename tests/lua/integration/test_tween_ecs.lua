-- Lurek2D Integration Test: Tween + Entity
-- Tests tweening entity position and rotation properties.
-- Rewritten to use lurek.tween.newState(duration, easing) API.

describe("integration: tween drives entity transform", function()
    it("entity x position tweened from 0 to 300", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:set(id, "x", 0.0)
        universe:set(id, "y", 100.0)

        local from_val, to_val = 0.0, 300.0
        local state = lurek.tween.newState(1.0, "linear")

        -- Simulate 60 frames (1 second)
        local dt = 1 / 60
        for _ = 1, 60 do
            state:tick(dt)
            universe:set(id, "x", state:lerp(from_val, to_val))
        end

        local x = universe:get(id, "x")
        expect_near(300, x, 5.0, "entity x reached target after 1s")
    end)

    it("multiple entities tweened simultaneously", function()
        local universe = lurek.ecs.newUniverse()
        local ids, states, targets = {}, {}, {}

        for i = 1, 5 do
            local id = universe:spawn()
            universe:set(id, "x", 0.0)
            ids[i] = id
            states[i] = lurek.tween.newState(1.0, "linear")
            targets[i] = i * 100
        end

        -- Advance all states to completion
        for _, st in ipairs(states) do
            st:tick(1.1)
        end

        -- Verify each entity gets its target value
        for i, id in ipairs(ids) do
            local val = states[i]:lerp(0, targets[i])
            universe:set(id, "x", val)
            local x = universe:get(id, "x")
            expect_near(targets[i], x, 1.0, "entity " .. i .. " x = " .. targets[i])
        end
    end)

    it("ease-in tween moves slowly at start, fast at end", function()
        local from_val, to_val = 0.0, 100.0
        local st_linear  = lurek.tween.newState(1.0, "linear")
        local st_ease_in = lurek.tween.newState(1.0, "quadIn")

        -- Advance both to 10% of their duration
        st_linear:tick(0.1)
        st_ease_in:tick(0.1)

        local v_linear  = st_linear:lerp(from_val, to_val)
        local v_ease_in = st_ease_in:lerp(from_val, to_val)

        -- At t=0.1, linear = ~10, quadIn should be less (slow start)
        expect_near(10, v_linear, 2.0, "linear at 10%     10")
        expect_true(v_ease_in < v_linear, "ease-in slower than linear at 10%")
    end)
end)
test_summary()
