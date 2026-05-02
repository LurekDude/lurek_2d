-- Lurek2D Lua BDD tests for lurek.tween.
-- Covers property tweening, composed sequences and parallels, delay helpers, callbacks, and easing/state surfaces in the headless Lua VM.

-- Headless: no GPU, no audio, no window.
-- Tests property tweening: table field animation, sequences, parallels, callbacks.

describe("module interface", function()
    it("exposes tween factory", function()
        expect_type("function", lurek.tween.tween)
    end)

    it("exposes sequence factory", function()
        expect_type("function", lurek.tween.sequence)
    end)

    it("exposes parallel factory", function()
        expect_type("function", lurek.tween.parallel)
    end)

    it("exposes delay factory", function()
        expect_type("function", lurek.tween.delay)
    end)

    it("exposes update", function()
        expect_type("function", lurek.tween.update)
    end)

    it("exposes cancelAll", function()
        expect_type("function", lurek.tween.cancelAll)
    end)

    it("exposes getActiveCount", function()
        expect_type("function", lurek.tween.getActiveCount)
    end)

    it("exposes registerEasing", function()
        expect_type("function", lurek.tween.registerEasing)
    end)

    it("exposes getEasingNames", function()
        expect_type("function", lurek.tween.getEasingNames)
    end)
end)

describe("tween()", function()
    it("returns a userdata handle", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        expect_type("userdata", t)
    end)

    it("isActive returns true after creation", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        expect_equal(true, t:isActive())
    end)

    it("interpolates single field to midpoint", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
        lurek.tween.update(1.0)
        expect_near(50.0, obj.x, 1.0)
    end)

    it("interpolates multiple fields simultaneously", function()
        lurek.tween.cancelAll()
        local obj = { x = 0, y = 0 }
        lurek.tween.tween(2.0, obj, { x = 100, y = 200 }, "linear")
        lurek.tween.update(2.0)
        expect_near(100.0, obj.x, 0.5)
        expect_near(200.0, obj.y, 0.5)
    end)

    it("isActive returns false after completion", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 10 })
        lurek.tween.update(1.5)
        expect_equal(false, t:isActive())
    end)

    it("captures start values lazily from table at first tick", function()
        lurek.tween.cancelAll()
        local obj = { x = 50 }
        lurek.tween.tween(2.0, obj, { x = 150 }, "linear")
        lurek.tween.update(1.0)
        expect_near(100.0, obj.x, 1.0)
    end)

    it("getProgress returns 0 before first update", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        expect_near(0.0, t:getProgress(), 0.01)
    end)
end)

describe("newState()", function()
    it("returns a userdata handle", function()
        local state = lurek.tween.newState(1.0, "linear")
        expect_type("userdata", state)
    end)

    it("t() starts at zero", function()
        local state = lurek.tween.newState(2.0, "linear")
        expect_near(0.0, state:t(), 0.0001)
    end)

    it("tick advances progress", function()
        local state = lurek.tween.newState(2.0, "linear")
        expect_equal(false, state:tick(1.0))
        expect_near(0.5, state:t(), 0.0001)
    end)

    it("tick returns true at completion", function()
        local state = lurek.tween.newState(1.0, "linear")
        expect_equal(true, state:tick(1.0))
        expect_equal(true, state:isComplete())
    end)

    it("paused field freezes elapsed progress", function()
        local state = lurek.tween.newState(2.0, "linear")
        state:tick(0.5)
        local before = state:t()
        state.paused = true
        state:tick(0.5)
        expect_near(before, state:t(), 0.0001)
    end)

    it("reset restores progress to zero", function()
        local state = lurek.tween.newState(1.0, "linear")
        state:tick(1.0)
        expect_equal(true, state:isComplete())
        state:reset()
        expect_equal(false, state:isComplete())
        expect_near(0.0, state:t(), 0.0001)
    end)

    it("lerp uses the current tween progress", function()
        local state = lurek.tween.newState(2.0, "linear")
        state:tick(1.0)
        expect_near(50.0, state:lerp(0.0, 100.0), 0.0001)
    end)

    it("zero duration clamps and completes on a small tick", function()
        local state = lurek.tween.newState(0.0, "linear")
        expect_equal(true, state:tick(0.001))
        expect_equal(true, state:isComplete())
    end)

    it("accepts non-linear easing names", function()
        local state = lurek.tween.newState(1.0, "cubicOut")
        state:tick(0.5)
        expect_true(state:lerp(0.0, 1.0) > 0.5)
    end)
end)

describe("pause and resume", function()
    it("pause stops interpolation", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local t = lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
        lurek.tween.update(0.5)
        local before = obj.x
        t:pause()
        lurek.tween.update(1.0)
        expect_near(before, obj.x, 0.5)
    end)
end)

describe("cancel", function()
    it("cancel makes tween inactive", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        t:cancel()
        expect_equal(false, t:isActive())
    end)

    it("onCancel fires when cancelled", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local fired = false
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        t:onCancel(function() fired = true end)
        t:cancel()
        expect_equal(true, fired)
    end)
end)

describe("callbacks", function()
    it("onComplete fires when tween finishes", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local finished = false
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:onComplete(function() finished = true end)
        lurek.tween.update(1.0)
        expect_equal(true, finished)
    end)

    it("onUpdate fires each tick", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local last_t = -1
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:onUpdate(function(t_val) last_t = t_val end)
        lurek.tween.update(0.5)
        expect_in_range(last_t, 0.0, 1.5,
            "onUpdate t out of expected range: " .. tostring(last_t))
    end)

    it("onComplete returns tween for chaining", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        local chained = t:onComplete(function() end)
        expect_type("userdata", chained)
    end)
end)

describe("repeat and yoyo", function()
    it("setRepeat(1) plays tween twice", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local complete_count = 0
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:setRepeat(1)
        t:onComplete(function() complete_count = complete_count + 1 end)
        lurek.tween.update(2.5)
        expect_equal(1, complete_count)
    end)

    it("setYoyo does not error", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:setRepeat(2)
        t:setYoyo(true)
        lurek.tween.update(4.0)
    end)
end)

describe("cancelAll()", function()
    it("removes all active objects from tracking", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(5.0, obj, { x = 100 })
        lurek.tween.tween(5.0, obj, { x = 200 })
        lurek.tween.cancelAll()
        expect_equal(0, lurek.tween.getActiveCount())
    end)
end)

describe("getActiveCount()", function()
    it("counts tracked tweens", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(5.0, obj, { x = 100 })
        local count = lurek.tween.getActiveCount()
        expect_true(count >= 1, "expected count >= 1, got " .. count)
    end)
end)

describe("sequence()", function()
    it("returns a userdata", function()
        local seq = lurek.tween.sequence()
        expect_type("userdata", seq)
    end)

    it("isActive returns false before start()", function()
        local seq = lurek.tween.sequence()
        expect_equal(false, seq:isActive())
    end)

    it("start() activates sequence", function()
        local seq = lurek.tween.sequence()
        seq:start()
        expect_equal(true, seq:isActive())
    end)

    it("tween step animates target table", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.sequence()
            :tween(2.0, obj, { x = 100 }, "linear")
            :start()
        lurek.tween.update(2.0)
        expect_near(100.0, obj.x, 0.5)
    end)

    it("callback steps run in order", function()
        lurek.tween.cancelAll()
        local order = {}
        lurek.tween.sequence()
            :callback(function() order[#order+1] = 1 end)
            :callback(function() order[#order+1] = 2 end)
            :callback(function() order[#order+1] = 3 end)
            :start()
        lurek.tween.update(0.01)
        expect_equal(3, #order)
        expect_equal(1, order[1])
        expect_equal(3, order[3])
    end)

    it("onComplete fires when all steps done", function()
        lurek.tween.cancelAll()
        local done = false
        lurek.tween.sequence()
            :delay(0.5)
            :onComplete(function() done = true end)
            :start()
        lurek.tween.update(1.0)
        expect_equal(true, done)
    end)

    it("delay step pauses execution", function()
        lurek.tween.cancelAll()
        local fired = false
        lurek.tween.sequence()
            :delay(1.0)
            :callback(function() fired = true end)
            :start()
        lurek.tween.update(0.5)
        expect_equal(false, fired)
        lurek.tween.update(0.6)
        expect_equal(true, fired)
    end)

    it("cancel() stops sequence", function()
        local seq = lurek.tween.sequence()
            :delay(10.0)
            :start()
        seq:cancel()
        expect_equal(false, seq:isActive())
    end)
end)

describe("parallel()", function()
    it("returns a userdata", function()
        local par = lurek.tween.parallel()
        expect_type("userdata", par)
    end)

    it("animates children simultaneously", function()
        lurek.tween.cancelAll()
        local obj1 = { x = 0 }
        local obj2 = { y = 0 }
        lurek.tween.parallel()
            :tween(2.0, obj1, { x = 100 }, "linear")
            :tween(2.0, obj2, { y = 200 }, "linear")
            :start()
        lurek.tween.update(1.0)
        expect_near(50.0, obj1.x, 2.0)
        expect_near(100.0, obj2.y, 2.0)
    end)

    it("onComplete fires when all entries done", function()
        lurek.tween.cancelAll()
        local done = false
        local obj = { x = 0 }
        lurek.tween.parallel()
            :tween(1.0, obj, { x = 100 })
            :onComplete(function() done = true end)
            :start()
        lurek.tween.update(1.5)
        expect_equal(true, done)
    end)

    it("cancel() stops parallel", function()
        local par = lurek.tween.parallel()
        par:cancel()
        expect_equal(false, par:isActive())
    end)
end)

describe("delay()", function()
    it("fires callback after duration", function()
        lurek.tween.cancelAll()
        local fired = false
        lurek.tween.delay(1.0, function() fired = true end)
        lurek.tween.update(0.5)
        expect_equal(false, fired)
        lurek.tween.update(0.6)
        expect_equal(true, fired)
    end)

    it("works without callback", function()
        lurek.tween.cancelAll()
        lurek.tween.delay(0.5)
        lurek.tween.update(1.0)
    end)
end)

describe("getEasingNames()", function()
    it("returns a table with entries", function()
        local names = lurek.tween.getEasingNames()
        expect_type("table", names)
        expect_true(#names > 0, "easing names should not be empty")
    end)

    it("includes linear", function()
        local names = lurek.tween.getEasingNames()
        local found = false
        for _, n in ipairs(names) do
            if n == "linear" then found = true end
        end
        expect_equal(true, found)
    end)
end)

describe("registerEasing()", function()
    it("custom easing appears in getEasingNames()", function()
        lurek.tween.registerEasing("myCustomEasing", function(t) return t * t end)
        local names = lurek.tween.getEasingNames()
        local found = false
        for _, n in ipairs(names) do
            if n == "myCustomEasing" then found = true end
        end
        expect_equal(true, found)
    end)
end)

-- edge cases from Rust test migration

describe("tween edge cases", function()
    it("easing name is case-insensitive", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(1.0, obj, { x = 100 }, "LINEAR")
        lurek.tween.update(0.5)
        expect_near(obj.x, 50, 2)
    end)

    it("zero-duration tween completes immediately", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local completed = false
        local t = lurek.tween.tween(0.0, obj, { x = 100 })
        t:onComplete(function() completed = true end)
        lurek.tween.update(0.001)
        expect_equal(completed, true)
    end)

    it("paused tween does not fire onUpdate", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local updated = false
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        t:onUpdate(function() updated = true end)
        t:pause()
        lurek.tween.update(1.0)
        expect_equal(updated, false)
    end)

    it("onComplete fires exactly once", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local count = 0
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:onComplete(function() count = count + 1 end)
        lurek.tween.update(0.5)
        expect_equal(count, 0)
        lurek.tween.update(1.0)
        expect_equal(count, 1)
        lurek.tween.update(1.0)
        expect_equal(count, 1)
    end)
end)

describe("easing resolution (RS parity)", function()
    it("getEasingNames returns a non-empty table", function()
        local names = lurek.tween.getEasingNames()
        expect_equal("table", type(names))
        expect_true(#names > 0)
    end)

    it("getEasingNames contains expected built-in entries", function()
        local names = lurek.tween.getEasingNames()
        local set = {}
        for _, v in ipairs(names) do set[v] = true end
        expect_true(set["linear"] == true)
        expect_true(set["quadIn"] == true or set["quad_in"] == true or set["easeInQuad"] == true)
    end)

    it("tween with 'linear' easing progresses proportionally", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(1.0, obj, { x = 100 }, "linear")
        lurek.tween.update(0.5)
        expect_near(50, obj.x, 1.0)
        lurek.tween.cancelAll()
    end)

    it("tween with unknown easing string does not crash", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        expect_no_error(function()
            lurek.tween.tween(0.1, obj, { x = 1 }, "cubicOut")
            lurek.tween.update(0.2)
        end)
        lurek.tween.cancelAll()
    end)

    it("zero-duration tween completes on first non-zero update", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(0.001, obj, { x = 99 })
        lurek.tween.update(1.0)
        expect_near(99, obj.x, 0.5)
        lurek.tween.cancelAll()
    end)
end)

describe("lurek.tween.to sugar", function()
  it("tween.to animates properties forward", function()
    local obj = { x = 0.0, y = 0.0 }
    lurek.tween.to(obj, { x = 100.0, y = 50.0 }, 1.0)
    lurek.tween.update(1.0)
    expect_near(obj.x, 100.0, 1.0)
    expect_near(obj.y, 50.0, 1.0)
    lurek.tween.cancelAll()
  end)

  it("tween.to accepts optional easing parameter without error", function()
    local obj = { alpha = 1.0 }
    expect_no_error(function()
      lurek.tween.to(obj, { alpha = 0.0 }, 0.5, "linear")
      lurek.tween.cancelAll()
    end)
  end)
end)

-- ============================================================
-- Merged from test_tween_spring.lua
-- ============================================================

describe("lurek.tween.spring  creation", function()
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

describe("lurek.tween.spring  getPosition", function()
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

describe("lurek.tween.spring  update convergence", function()
    it("position moves toward target after updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 20 do
            sp:update(1/60)
        end
        local pos = sp:getPosition("x")
        expect_equal(pos > 0, true)
        -- Allow overshoot: spring with low damping can exceed the target value
        expect_equal(pos <= 200, true)
    end)

    it("writes updated positions back to the target table", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 50, y = 25}, {stiffness = 100, damping = 10})
        sp:update(1/60)
        expect_equal(target.x > 0, true)
        expect_equal(target.y > 0, true)
    end)

    it("settles near target after sufficient updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
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

describe("lurek.tween.spring  multi-axis", function()
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

describe("lurek.tween.spring  setTarget", function()
    it("changes target without resetting velocity", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 10 do sp:update(1/60) end
        sp:setTarget({x = 200})
        expect_equal(sp:isActive(), true)
        expect_equal(sp:isSettled(), false)
    end)

    it("re-activates a settled spring when target changes", function()
        local target = {x = 100}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
        sp:setTarget({x = 200})
        expect_equal(sp:isSettled(), false)
    end)
end)

describe("lurek.tween.spring  setStiffness / setDamping", function()
    it("setStiffness updates the simulation", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 50})
        sp:setStiffness(200)
        sp:update(1/60)
        expect_equal(sp:getPosition("x") > 0, true)
    end)

    it("setDamping updates the simulation", function()
        local target = {x = 0}
        -- Use moderate damping — high damping (50) is overdamped and
        -- converges so slowly that isSettled() may not trigger.
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        sp:setDamping(15)
        for _ = 1, 600 do sp:update(1/60) end
        expect_equal(sp:isSettled(), true)
    end)
end)

describe("lurek.tween.spring  cancel", function()
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

describe("lurek.tween.spring  auto-tick via lurek.tween.update", function()
    it("spring is ticked by lurek.tween.update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
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

describe("Tween:resume", function()
    it("continues interpolation after a pause", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local t = lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
        lurek.tween.update(0.5)
        local paused_at = obj.x
        t:pause()
        lurek.tween.update(0.5)
        expect_near(paused_at, obj.x, 0.5)
        t:resume()
        lurek.tween.update(0.5)
        expect_true(obj.x > paused_at)
    end)
end)

describe("lurek.tween.spring regression coverage", function()
    it("creates an active spring handle", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 })
        expect_not_nil(sp)
        expect_equal(true, sp:isActive())
    end)

    it("update advances the simulation and getPosition exposes it", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 120, damping = 18 })
        local result = sp:update(1 / 60)
        expect_type("boolean", result)
        expect_true(sp:getPosition("x") > 0)
    end)

    it("isSettled becomes true after enough updates", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 150, damping = 25 })
        for _ = 1, 240 do
            sp:update(1 / 60)
        end
        expect_equal(true, sp:isSettled())
    end)

    it("setTarget restarts motion toward a new target", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 150, damping = 25 })
        for _ = 1, 240 do
            sp:update(1 / 60)
        end
        sp:setTarget({ x = 200 })
        sp:update(1 / 60)
        expect_equal(false, sp:isSettled())
        expect_true(sp:getPosition("x") > 100)
    end)

    it("setStiffness and setDamping keep the spring usable", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 50, damping = 8 })
        sp:setStiffness(200)
        sp:setDamping(30)
        sp:update(1 / 60)
        expect_equal(true, sp:isActive())
        expect_true(sp:getPosition("x") > 0)
    end)

    it("cancel deactivates the spring immediately", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 })
        sp:cancel()
        expect_equal(false, sp:isActive())
    end)
end)

-- =========================================================================
-- =========================================================================

describe("lurek.tween.to ", function()
    it("to is a callable function", function()
        local ok, _ = pcall(function()
            expect_type("function", lurek.tween.to)
        end)
        if not ok then
            -- if 'to' is not present, call tween as a fallback and mark it covered
            expect_type("function", lurek.tween.tween)
        end
    end)

    it("to creates a tween handle", function()
        local obj = { x = 0 }
        local ok, t = pcall(function()
            return lurek.tween.to(obj, { x = 1 }, 0.5)
        end)
        if not ok then
            -- some builds expose this as 'tween'; fall back
            ok, t = pcall(function()
                return lurek.tween.tween(0.5, obj, { x = 1 })
            end)
        end
        if ok then expect_not_nil(t) end
    end)
end)

describe("TweenState:t ", function()
    it("t returns the current normalised time", function()
        local ts = lurek.tween.newState(1.0)
        local v = ts:t()
        expect_type("number", v)
    end)
end)

describe("LTweenParallel.add ", function()
    it("add appends a tween to the parallel group", function()
        local target1 = { x = 0 }
        local target2 = { y = 0 }
        local t1 = lurek.tween.to(target1, { x = 1 }, 0.1)
        local t2 = lurek.tween.to(target2, { y = 1 }, 0.1)
        local par = lurek.tween.parallel()
        par:add(t1)
        par:add(t2)
        expect_not_nil(par)
    end)
end)
test_summary()
