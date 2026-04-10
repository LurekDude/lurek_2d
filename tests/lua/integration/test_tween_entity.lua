-- Lurek2D Integration Test: Tween + Entity
-- Tests tweening entity position and rotation properties.
-- @covers lurek.tween.newTween
-- @covers lurek.entity.newUniverse

describe("integration: tween drives entity transform", function()
    it("entity x position tweened from 0 to 300", function()
        local universe = lurek.entity.newUniverse()
        local tw       = lurek.tween.newTween()

        local id = universe:spawn()
        universe:set(id, "x", 0.0)
        universe:set(id, "y", 100.0)

        tw:setDuration(1.0)
        tw:setEasing("linear")
        tw:setFrom(0)
        tw:setTo(300)

        -- Simulate 60 frames (1 second)
        local dt = 1 / 60
        for _ = 1, 60 do
            tw:update(dt)
            universe:set(id, "x", tw:getValue())
        end

        local x = universe:get(id, "x")
        expect_near(300, x, 5.0, "entity x reached target after 1s")
    end)

    it("multiple entities tweened simultaneously", function()
        local universe = lurek.entity.newUniverse()
        local ids, tweens = {}, {}

        for i = 1, 5 do
            local id = universe:spawn()
            universe:set(id, "x", 0.0)
            ids[i] = id

            local tw = lurek.tween.newTween()
            tw:setDuration(1.0)
            tw:setEasing("linear")
            tw:setFrom(0)
            tw:setTo(i * 100)
            tweens[i] = tw
        end

        -- Advance all tweens to end
        for _, tw in ipairs(tweens) do
            tw:update(1.1)
        end

        -- Verify each entity gets its target value
        for i, id in ipairs(ids) do
            local val = tweens[i]:getValue()
            universe:set(id, "x", val)
            local x = universe:get(id, "x")
            expect_near(i * 100, x, 1.0, "entity " .. i .. " x = " .. (i*100))
        end
    end)

    it("ease-in tween moves slowly at start, fast at end", function()
        local tw_linear  = lurek.tween.newTween()
        local tw_ease_in = lurek.tween.newTween()

        for _, tw in ipairs({tw_linear, tw_ease_in}) do
            tw:setDuration(1.0)
            tw:setFrom(0)
            tw:setTo(100)
        end
        tw_linear:setEasing("linear")
        tw_ease_in:setEasing("quadIn")

        tw_linear:seek(0.1)
        tw_ease_in:seek(0.1)

        local v_linear  = tw_linear:getValue()
        local v_ease_in = tw_ease_in:getValue()

        -- At t=0.1, linear = 10, quadIn should be less (slow start)
        expect_near(10, v_linear,  1.0, "linear at 10% = 10")
        expect_true(v_ease_in < v_linear, "ease-in slower than linear at 10%")
    end)
end)

test_summary()
