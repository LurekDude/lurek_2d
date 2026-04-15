-- tests/lua/unit/test_tween_spring.lua
-- BDD tests for lurek.tween.spring (LuaSpring / SpringSystem).
-- No GPU, audio, or window APIs used.

describe("lurek.tween.spring — creation", function()
    it("creates a spring from a table and fields", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 100, y = 50})
        expect_equal(sp ~= nil, true)
    end)

    it("reports not settled immediately when target differs from position", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), false)
    end)

    it("reports settled immediately when position already equals target", function()
        local target = {x = 100}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
    end)

    it("isActive returns true after creation with differing target", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 50})
        expect_equal(sp:isActive(), true)
    end)

    it("accepts stiffness/damping/precision opts", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 200}, {stiffness = 200, damping = 28, precision = 0.01})
        expect_equal(sp ~= nil, true)
        expect_equal(sp:isSettled(), false)
    end)
end)

describe("lurek.tween.spring — getPosition", function()
    it("returns starting position before any update", function()
        local target = {x = 42.0}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_near(sp:getPosition("x"), 42.0, 0.001)
    end)

    it("returns nil for an unknown field", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 50})
        expect_equal(sp:getPosition("z"), nil)
    end)
end)

describe("lurek.tween.spring — update convergence", function()
    it("position moves toward target after updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        -- advance 20 frames at 60 fps
        for _ = 1, 20 do
            sp:update(1/60)
        end
        local pos = sp:getPosition("x")
        -- position should have moved toward 100
        expect_equal(pos > 0, true)
        expect_equal(pos <= 100.5, true)  -- allow small overshoot
    end)

    it("writes updated positions back to the target table", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 50, y = 25}, {stiffness = 100, damping = 10})
        sp:update(1/60)
        -- table should be updated too
        expect_equal(target.x > 0, true)
        expect_equal(target.y > 0, true)
    end)

    it("settles near target after sufficient updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        -- simulate ~5 seconds at 60 fps
        for _ = 1, 300 do
            sp:update(1/60)
        end
        expect_equal(sp:isSettled(), true)
        expect_near(sp:getPosition("x"), 100.0, 0.01)
    end)

    it("update returns true while moving, false when settled", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        local still_moving = sp:update(1/60)
        expect_equal(still_moving, true)

        -- run until settled
        for _ = 1, 400 do
            sp:update(1/60)
        end
        local after = sp:update(1/60)
        expect_equal(after, false)
    end)

    it("isActive becomes false after spring settles via update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        for _ = 1, 400 do
            sp:update(1/60)
        end
        expect_equal(sp:isActive(), false)
    end)
end)

describe("lurek.tween.spring — multi-axis", function()
    it("animates multiple fields simultaneously", function()
        local target = {x = 0, y = 0, alpha = 0}
        local sp = lurek.tween.spring(target, {x = 100, y = 200, alpha = 1},
            {stiffness = 100, damping = 10})
        for _ = 1, 30 do
            sp:update(1/60)
        end
        expect_equal(target.x > 0, true)
        expect_equal(target.y > 0, true)
        expect_equal(target.alpha > 0, true)
    end)

    it("all axes settle together", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 50, y = 80}, {stiffness = 120, damping = 22})
        for _ = 1, 500 do
            sp:update(1/60)
        end
        expect_equal(sp:isSettled(), true)
        expect_near(target.x, 50, 0.01)
        expect_near(target.y, 80, 0.01)
    end)
end)

describe("lurek.tween.spring — setTarget", function()
    it("changes target without resetting velocity", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        -- build up some velocity toward 100
        for _ = 1, 10 do sp:update(1/60) end
        -- redirect to 200
        sp:setTarget({x = 200})
        expect_equal(sp:isActive(), true)
        expect_equal(sp:isSettled(), false)
    end)

    it("re-activates a settled spring when target changes", function()
        local target = {x = 100}
        -- starts settled (position == target)
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
        sp:setTarget({x = 200})
        -- settled flag should be cleared
        expect_equal(sp:isSettled(), false)
    end)
end)

describe("lurek.tween.spring — setStiffness / setDamping", function()
    it("setStiffness updates the simulation", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 50})
        sp:setStiffness(200)
        -- after stiffness increase, movement should be faster;
        -- just verify no error is thrown and position moves
        sp:update(1/60)
        expect_equal(sp:getPosition("x") > 0, true)
    end)

    it("setDamping updates the simulation", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:setDamping(50)  -- heavy damping
        for _ = 1, 200 do sp:update(1/60) end
        expect_equal(sp:isSettled(), true)
    end)
end)

describe("lurek.tween.spring — cancel", function()
    it("cancel makes isActive false", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:cancel()
        expect_equal(sp:isActive(), false)
    end)

    it("update returns false after cancel", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:cancel()
        local result = sp:update(1/60)
        expect_equal(result, false)
    end)
end)

describe("lurek.tween.spring — auto-tick via lurek.tween.update", function()
    it("spring is ticked by lurek.tween.update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        -- auto-tick via the engine
        for _ = 1, 20 do
            lurek.tween.update(1/60)
        end
        expect_equal(target.x > 0, true)
    end)

    it("cancelAll also cancels springs", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        lurek.tween.cancelAll()
        expect_equal(sp:isActive(), false)
    end)
end)

test_summary()
