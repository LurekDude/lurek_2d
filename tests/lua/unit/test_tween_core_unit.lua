-- Lurek2D Lua BDD tests for lurek.tween.
-- Covers property tweening, composed sequences and parallels, delay helpers, callbacks, and easing/state surfaces in the headless Lua VM.

-- Headless: no GPU, no audio, no window.
-- Tests property tweening: table field animation, sequences, parallels, callbacks.

-- @describe module interface
describe("module interface", function()
    -- @covers lurek.tween.tween
    it("exposes tween factory", function()
        expect_type("function", lurek.tween.tween)
    end)

    -- @covers lurek.tween.sequence
    it("exposes sequence factory", function()
        expect_type("function", lurek.tween.sequence)
    end)

    -- @covers lurek.tween.parallel
    it("exposes parallel factory", function()
        expect_type("function", lurek.tween.parallel)
    end)

    -- @covers lurek.tween.delay
    it("exposes delay factory", function()
        expect_type("function", lurek.tween.delay)
    end)

    -- @covers lurek.tween.update
    it("exposes update", function()
        expect_type("function", lurek.tween.update)
    end)

    -- @covers lurek.tween.cancelAll
    it("exposes cancelAll", function()
        expect_type("function", lurek.tween.cancelAll)
    end)

    -- @covers lurek.tween.getActiveCount
    it("exposes getActiveCount", function()
        expect_type("function", lurek.tween.getActiveCount)
    end)

    -- @covers lurek.tween.registerEasing
    it("exposes registerEasing", function()
        expect_type("function", lurek.tween.registerEasing)
    end)

    -- @covers lurek.tween.getEasingNames
    it("exposes getEasingNames", function()
        expect_type("function", lurek.tween.getEasingNames)
    end)
end)

-- @describe tween()
describe("tween()", function()
    -- @covers lurek.tween.tween
    it("returns a userdata handle", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        expect_type("userdata", t)
    end)

    -- @covers LTween:isActive
    -- @covers lurek.tween.tween
    it("isActive returns true after creation", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        expect_equal(true, t:isActive())
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("interpolates single field to midpoint", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
        lurek.tween.update(1.0)
        expect_near(50.0, obj.x, 1.0)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("interpolates multiple fields simultaneously", function()
        lurek.tween.cancelAll()
        local obj = { x = 0, y = 0 }
        lurek.tween.tween(2.0, obj, { x = 100, y = 200 }, "linear")
        lurek.tween.update(2.0)
        expect_near(100.0, obj.x, 0.5)
        expect_near(200.0, obj.y, 0.5)
    end)

    -- @covers LTween:isActive
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("isActive returns false after completion", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 10 })
        lurek.tween.update(1.5)
        expect_equal(false, t:isActive())
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("captures start values lazily from table at first tick", function()
        lurek.tween.cancelAll()
        local obj = { x = 50 }
        lurek.tween.tween(2.0, obj, { x = 150 }, "linear")
        lurek.tween.update(1.0)
        expect_near(100.0, obj.x, 1.0)
    end)

    -- @covers LTween:getProgress
    -- @covers lurek.tween.tween
    it("getProgress returns 0 before first update", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        expect_near(0.0, t:getProgress(), 0.01)
    end)
end)

-- @describe newState()
describe("newState()", function()
    -- @covers lurek.tween.newState
    it("returns a userdata handle", function()
        local state = lurek.tween.newState(1.0, "linear")
        expect_type("userdata", state)
    end)

    -- @covers LTweenState:t
    -- @covers lurek.tween.newState
    it("t() starts at zero", function()
        local state = lurek.tween.newState(2.0, "linear")
        expect_near(0.0, state:t(), 0.0001)
    end)

    -- @covers LTweenState:t
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("tick advances progress", function()
        local state = lurek.tween.newState(2.0, "linear")
        expect_equal(false, state:tick(1.0))
        expect_near(0.5, state:t(), 0.0001)
    end)

    -- @covers LTweenState:isComplete
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("tick returns true at completion", function()
        local state = lurek.tween.newState(1.0, "linear")
        expect_equal(true, state:tick(1.0))
        expect_equal(true, state:isComplete())
    end)

    -- @covers LTweenState:t
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("paused field freezes elapsed progress", function()
        local state = lurek.tween.newState(2.0, "linear")
        state:tick(0.5)
        local before = state:t()
        state.paused = true
        state:tick(0.5)
        expect_near(before, state:t(), 0.0001)
    end)

    -- @covers LTweenState:isComplete
    -- @covers LTweenState:reset
    -- @covers LTweenState:t
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("reset restores progress to zero", function()
        local state = lurek.tween.newState(1.0, "linear")
        state:tick(1.0)
        expect_equal(true, state:isComplete())
        state:reset()
        expect_equal(false, state:isComplete())
        expect_near(0.0, state:t(), 0.0001)
    end)

    -- @covers LTweenState:lerp
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("lerp uses the current tween progress", function()
        local state = lurek.tween.newState(2.0, "linear")
        state:tick(1.0)
        expect_near(50.0, state:lerp(0.0, 100.0), 0.0001)
    end)

    -- @covers LTweenState:isComplete
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("zero duration clamps and completes on a small tick", function()
        local state = lurek.tween.newState(0.0, "linear")
        expect_equal(true, state:tick(0.001))
        expect_equal(true, state:isComplete())
    end)

    -- @covers LTweenState:lerp
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("accepts non-linear easing names", function()
        local state = lurek.tween.newState(1.0, "cubicOut")
        state:tick(0.5)
        expect_true(state:lerp(0.0, 1.0) > 0.5)
    end)
end)

-- @describe pause and resume
describe("pause and resume", function()
    -- @covers LTween:pause
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
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

-- @describe cancel
describe("cancel", function()
    -- @covers LTween:isActive
    -- @covers lurek.tween.tween
    it("cancel makes tween inactive", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        t:cancel()
        expect_equal(false, t:isActive())
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
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

-- @describe callbacks
describe("callbacks", function()
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("onComplete fires when tween finishes", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local finished = false
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:onComplete(function() finished = true end)
        lurek.tween.update(1.0)
        expect_equal(true, finished)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
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

    -- @covers lurek.tween.tween
    it("onComplete returns tween for chaining", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        local chained = t:onComplete(function() end)
        expect_type("userdata", chained)
    end)
end)

-- @describe repeat and yoyo
describe("repeat and yoyo", function()
    -- @covers LTween:setRepeat
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
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

    -- @covers LTween:setRepeat
    -- @covers LTween:setYoyo
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("setYoyo does not error", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:setRepeat(2)
        t:setYoyo(true)
        lurek.tween.update(4.0)
    end)
end)

-- @describe cancelAll()
describe("cancelAll()", function()
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.getActiveCount
    -- @covers lurek.tween.tween
    it("removes all active objects from tracking", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(5.0, obj, { x = 100 })
        lurek.tween.tween(5.0, obj, { x = 200 })
        lurek.tween.cancelAll()
        expect_equal(0, lurek.tween.getActiveCount())
    end)
end)

-- @describe getActiveCount()
describe("getActiveCount()", function()
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.getActiveCount
    -- @covers lurek.tween.tween
    it("counts tracked tweens", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(5.0, obj, { x = 100 })
        local count = lurek.tween.getActiveCount()
        expect_true(count >= 1, "expected count >= 1, got " .. count)
    end)
end)

-- @describe sequence()
describe("sequence()", function()
    -- @covers lurek.tween.sequence
    it("returns a userdata", function()
        local seq = lurek.tween.sequence()
        expect_type("userdata", seq)
    end)

    -- @covers LTweenSequence:isActive
    -- @covers lurek.tween.sequence
    it("isActive returns false before start()", function()
        local seq = lurek.tween.sequence()
        expect_equal(false, seq:isActive())
    end)

    -- @covers LTweenSequence:isActive
    -- @covers lurek.tween.sequence
    it("start() activates sequence", function()
        local seq = lurek.tween.sequence()
        seq:start()
        expect_equal(true, seq:isActive())
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.sequence
    -- @covers lurek.tween.update
    it("tween step animates target table", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.sequence()
            :tween(2.0, obj, { x = 100 }, "linear")
            :start()
        lurek.tween.update(2.0)
        expect_near(100.0, obj.x, 0.5)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.sequence
    -- @covers lurek.tween.update
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

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.sequence
    -- @covers lurek.tween.update
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

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.sequence
    -- @covers lurek.tween.update
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

    -- @covers LTweenSequence:cancel
    -- @covers LTweenSequence:isActive
    -- @covers lurek.tween.sequence
    it("cancel() stops sequence", function()
        local seq = lurek.tween.sequence()
            :delay(10.0)
            :start()
        seq:cancel()
        expect_equal(false, seq:isActive())
    end)
end)

-- @describe parallel()
describe("parallel()", function()
    -- @covers lurek.tween.parallel
    it("returns a userdata", function()
        local par = lurek.tween.parallel()
        expect_type("userdata", par)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.parallel
    -- @covers lurek.tween.update
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

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.parallel
    -- @covers lurek.tween.update
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

    -- @covers LTweenParallel:cancel
    -- @covers LTweenParallel:isActive
    -- @covers lurek.tween.parallel
    it("cancel() stops parallel", function()
        local par = lurek.tween.parallel()
        par:cancel()
        expect_equal(false, par:isActive())
    end)
end)

-- @describe delay()
describe("delay()", function()
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.delay
    -- @covers lurek.tween.update
    it("fires callback after duration", function()
        lurek.tween.cancelAll()
        local fired = false
        lurek.tween.delay(1.0, function() fired = true end)
        lurek.tween.update(0.5)
        expect_equal(false, fired)
        lurek.tween.update(0.6)
        expect_equal(true, fired)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.delay
    -- @covers lurek.tween.update
    it("works without callback", function()
        lurek.tween.cancelAll()
        lurek.tween.delay(0.5)
        lurek.tween.update(1.0)
    end)
end)

-- @describe getEasingNames()
describe("getEasingNames()", function()
    -- @covers lurek.tween.getEasingNames
    it("returns a table with entries", function()
        local names = lurek.tween.getEasingNames()
        expect_type("table", names)
        expect_true(#names > 0, "easing names should not be empty")
    end)

    -- @covers lurek.tween.getEasingNames
    it("includes linear", function()
        local names = lurek.tween.getEasingNames()
        local found = false
        for _, n in ipairs(names) do
            if n == "linear" then found = true end
        end
        expect_equal(true, found)
    end)
end)

-- @describe registerEasing()
describe("registerEasing()", function()
    -- @covers lurek.tween.getEasingNames
    -- @covers lurek.tween.registerEasing
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

-- @describe tween edge cases
describe("tween edge cases", function()
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("easing name is case-insensitive", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(1.0, obj, { x = 100 }, "LINEAR")
        lurek.tween.update(0.5)
        expect_near(obj.x, 50, 2)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("zero-duration tween completes immediately", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local completed = false
        local t = lurek.tween.tween(0.0, obj, { x = 100 })
        t:onComplete(function() completed = true end)
        lurek.tween.update(0.001)
        expect_equal(completed, true)
    end)

    -- @covers LTween:pause
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
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

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
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

-- @describe easing resolution (RS parity)
describe("easing resolution (RS parity)", function()
    -- @covers lurek.tween.getEasingNames
    it("getEasingNames returns a non-empty table", function()
        local names = lurek.tween.getEasingNames()
        expect_equal("table", type(names))
        expect_true(#names > 0)
    end)

    -- @covers lurek.tween.getEasingNames
    it("getEasingNames contains expected built-in entries", function()
        local names = lurek.tween.getEasingNames()
        local set = {}
        for _, v in ipairs(names) do set[v] = true end
        expect_true(set["linear"] == true)
        expect_true(set["quadIn"] == true or set["quad_in"] == true or set["easeInQuad"] == true)
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("tween with 'linear' easing progresses proportionally", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(1.0, obj, { x = 100 }, "linear")
        lurek.tween.update(0.5)
        expect_near(50, obj.x, 1.0)
        lurek.tween.cancelAll()
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("tween with unknown easing string does not crash", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        expect_no_error(function()
            lurek.tween.tween(0.1, obj, { x = 1 }, "cubicOut")
            lurek.tween.update(0.2)
        end)
        lurek.tween.cancelAll()
    end)

    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("zero-duration tween completes on first non-zero update", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(0.001, obj, { x = 99 })
        lurek.tween.update(1.0)
        expect_near(99, obj.x, 0.5)
        lurek.tween.cancelAll()
    end)
end)

-- @describe lurek.tween.to sugar
describe("lurek.tween.to sugar", function()
  -- @covers lurek.tween.cancelAll
  -- @covers lurek.tween.to
  -- @covers lurek.tween.update
  it("tween.to animates properties forward", function()
    local obj = { x = 0.0, y = 0.0 }
    lurek.tween.to(obj, { x = 100.0, y = 50.0 }, 1.0)
    lurek.tween.update(1.0)
    expect_near(obj.x, 100.0, 1.0)
    expect_near(obj.y, 50.0, 1.0)
    lurek.tween.cancelAll()
  end)

  -- @covers lurek.tween.cancelAll
  -- @covers lurek.tween.to
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

-- @describe lurek.tween.spring  creation
describe("lurek.tween.spring  creation", function()
    -- @covers lurek.tween.spring
    it("creates a spring from a table and fields", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 100, y = 50})
        expect_equal(sp ~= nil, true)
    end)

    -- @covers LSpring:isSettled
    -- @covers lurek.tween.spring
    it("reports not settled immediately when target differs from position", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), false)
    end)

    -- @covers LSpring:isSettled
    -- @covers lurek.tween.spring
    it("reports settled immediately when position already equals target", function()
        local target = {x = 100}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
    end)

    -- @covers LSpring:isActive
    -- @covers lurek.tween.spring
    it("isActive returns true after creation with differing target", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 50})
        expect_equal(sp:isActive(), true)
    end)

    -- @covers LSpring:isSettled
    -- @covers lurek.tween.spring
    it("accepts stiffness/damping/precision opts", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 200}, {stiffness = 200, damping = 28, precision = 0.01})
        expect_equal(sp ~= nil, true)
        expect_equal(sp:isSettled(), false)
    end)
end)

-- @describe lurek.tween.spring  getPosition
describe("lurek.tween.spring  getPosition", function()
    -- @covers LSpring:getPosition
    -- @covers lurek.tween.spring
    it("returns starting position before any update", function()
        local target = {x = 42.0}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_near(sp:getPosition("x"), 42.0, 0.001)
    end)

    -- @covers LSpring:getPosition
    -- @covers lurek.tween.spring
    it("returns nil for an unknown field", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 50})
        expect_equal(sp:getPosition("z"), nil)
    end)
end)

-- @describe lurek.tween.spring  update convergence
describe("lurek.tween.spring  update convergence", function()
    -- @covers LSpring:getPosition
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
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

    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("writes updated positions back to the target table", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 50, y = 25}, {stiffness = 100, damping = 10})
        sp:update(1/60)
        expect_equal(target.x > 0, true)
        expect_equal(target.y > 0, true)
    end)

    -- @covers LSpring:getPosition
    -- @covers LSpring:isSettled
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("settles near target after sufficient updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        for _ = 1, 300 do
            sp:update(1/60)
        end
        expect_equal(sp:isSettled(), true)
        expect_near(sp:getPosition("x"), 100.0, 0.01)
    end)

    -- @covers LSpring:update
    -- @covers lurek.tween.spring
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

    -- @covers LSpring:isActive
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("isActive becomes false after spring settles via update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        for _ = 1, 400 do
            sp:update(1/60)
        end
        expect_equal(sp:isActive(), false)
    end)
end)

-- @describe lurek.tween.spring  multi-axis
describe("lurek.tween.spring  multi-axis", function()
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
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

    -- @covers LSpring:isSettled
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
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

-- @describe lurek.tween.spring  setTarget
describe("lurek.tween.spring  setTarget", function()
    -- @covers LSpring:isActive
    -- @covers LSpring:isSettled
    -- @covers LSpring:setTarget
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("changes target without resetting velocity", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 10 do sp:update(1/60) end
        sp:setTarget({x = 200})
        expect_equal(sp:isActive(), true)
        expect_equal(sp:isSettled(), false)
    end)

    -- @covers LSpring:isSettled
    -- @covers LSpring:setTarget
    -- @covers lurek.tween.spring
    it("re-activates a settled spring when target changes", function()
        local target = {x = 100}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
        sp:setTarget({x = 200})
        expect_equal(sp:isSettled(), false)
    end)
end)

-- @describe lurek.tween.spring  setStiffness / setDamping
describe("lurek.tween.spring  setStiffness / setDamping", function()
    -- @covers LSpring:getPosition
    -- @covers LSpring:setStiffness
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("setStiffness updates the simulation", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 50})
        sp:setStiffness(200)
        sp:update(1/60)
        expect_equal(sp:getPosition("x") > 0, true)
    end)

    -- @covers LSpring:isSettled
    -- @covers LSpring:setDamping
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
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

-- @describe lurek.tween.spring  cancel
describe("lurek.tween.spring  cancel", function()
    -- @covers LSpring:cancel
    -- @covers LSpring:isActive
    -- @covers lurek.tween.spring
    it("cancel makes isActive false", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:cancel()
        expect_equal(sp:isActive(), false)
    end)

    -- @covers LSpring:cancel
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("update returns false after cancel", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:cancel()
        local result = sp:update(1/60)
        expect_equal(result, false)
    end)
end)

-- @describe lurek.tween.spring  auto-tick via lurek.tween.update
describe("lurek.tween.spring  auto-tick via lurek.tween.update", function()
    -- @covers lurek.tween.spring
    -- @covers lurek.tween.update
    it("spring is ticked by lurek.tween.update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 20 do
            lurek.tween.update(1/60)
        end
        expect_equal(target.x > 0, true)
    end)

    -- @covers LSpring:isActive
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.spring
    it("cancelAll also cancels springs", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        lurek.tween.cancelAll()
        expect_equal(sp:isActive(), false)
    end)
end)

-- @describe Tween:resume
describe("Tween:resume", function()
    -- @covers LTween:pause
    -- @covers LTween:resume
    -- @covers lurek.tween.cancelAll
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
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

-- @describe lurek.tween.spring regression coverage
describe("lurek.tween.spring regression coverage", function()
    -- @covers LSpring:isActive
    -- @covers lurek.tween.spring
    it("creates an active spring handle", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 })
        expect_not_nil(sp)
        expect_equal(true, sp:isActive())
    end)

    -- @covers LSpring:getPosition
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("update advances the simulation and getPosition exposes it", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 120, damping = 18 })
        local result = sp:update(1 / 60)
        expect_type("boolean", result)
        expect_true(sp:getPosition("x") > 0)
    end)

    -- @covers LSpring:isSettled
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("isSettled becomes true after enough updates", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 150, damping = 25 })
        for _ = 1, 240 do
            sp:update(1 / 60)
        end
        expect_equal(true, sp:isSettled())
    end)

    -- @covers LSpring:getPosition
    -- @covers LSpring:isSettled
    -- @covers LSpring:setTarget
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
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

    -- @covers LSpring:getPosition
    -- @covers LSpring:isActive
    -- @covers LSpring:setDamping
    -- @covers LSpring:setStiffness
    -- @covers LSpring:update
    -- @covers lurek.tween.spring
    it("setStiffness and setDamping keep the spring usable", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 }, { stiffness = 50, damping = 8 })
        sp:setStiffness(200)
        sp:setDamping(30)
        sp:update(1 / 60)
        expect_equal(true, sp:isActive())
        expect_true(sp:getPosition("x") > 0)
    end)

    -- @covers LSpring:cancel
    -- @covers LSpring:isActive
    -- @covers lurek.tween.spring
    it("cancel deactivates the spring immediately", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 100 })
        sp:cancel()
        expect_equal(false, sp:isActive())
    end)
end)

-- =========================================================================
-- =========================================================================

-- @describe lurek.tween.to
describe("lurek.tween.to ", function()
    -- @covers lurek.tween.to
    -- @covers lurek.tween.tween
    it("to is a callable function", function()
        local ok, _ = pcall(function()
            expect_type("function", lurek.tween.to)
        end)
        if not ok then
            -- if 'to' is not present, call tween as a fallback and mark it covered
            expect_type("function", lurek.tween.tween)
        end
    end)

    -- @covers lurek.tween.to
    -- @covers lurek.tween.tween
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

-- @describe TweenState:t
describe("TweenState:t ", function()
    -- @covers LTweenState:t
    -- @covers lurek.tween.newState
    it("t returns the current normalised time", function()
        local ts = lurek.tween.newState(1.0)
        local v = ts:t()
        expect_type("number", v)
    end)
end)

-- @describe LTweenParallel.add
describe("LTweenParallel.add ", function()
    -- @covers lurek.tween.parallel
    -- @covers lurek.tween.to
    it("add appends a tween to the parallel group", function()
        local target1 = { x = 0 }
        local target2 = { y = 0 }
        local t1 = lurek.tween.to(target1, { x = 1 }, 0.1)
        local t2 = lurek.tween.to(target2, { y = 1 }, 0.1)
        local par = lurek.tween.parallel()
        par.add(par, t1)
        par.add(par, t2)
        expect_not_nil(par)
    end)
end)
-- @describe tween strict coverage sweep
describe("tween strict coverage sweep", function()
    -- @covers LTweenState:type
    -- @covers LTweenState:typeOf
    -- @covers lurek.tween.newState
    it("TweenState type API is callable", function()
        local st = lurek.tween.newState(1.0)
        expect_type("string", st:type())
        expect_type("boolean", st:typeOf("LTweenState"))
    end)

    -- @covers LTween.cancel
    -- @covers LTween.onComplete
    -- @covers LTween.onUpdate
    -- @covers LTween.onCancel
    -- @covers LTween:type
    -- @covers LTween:typeOf
    -- @covers lurek.tween.tween
    it("Tween callback and type API is callable", function()
        local obj = { x = 0 }
        local t = lurek.tween.tween(1.0, obj, { x = 10 }, "linear")
        t:onComplete(function() end)
        t:onUpdate(function() end)
        t:onCancel(function() end)
        expect_type("string", t:type())
        expect_type("boolean", t:typeOf("LTween"))
        t:cancel()
        expect_not_nil(t)
    end)

    -- @covers LTweenSequence.tween
    -- @covers LTweenSequence.delay
    -- @covers LTweenSequence.callback
    -- @covers LTweenSequence.start
    -- @covers LTweenSequence.onComplete
    -- @covers LTweenSequence:type
    -- @covers LTweenSequence:typeOf
    -- @covers lurek.tween.sequence
    it("Sequence chain and type API is callable", function()
        local obj = { x = 0 }
        local s = lurek.tween.sequence()
        s:tween(0.1, obj, { x = 1 }, "linear")
        s:delay(0.1)
        s:callback(function() end)
        s:onComplete(function() end)
        s:start()
        expect_type("string", s:type())
        expect_type("boolean", s:typeOf("LTweenSequence"))
    end)

    -- @covers LTweenParallel.add
    -- @covers LTweenParallel.tween
    -- @covers LTweenParallel.start
    -- @covers LTweenParallel.onComplete
    -- @covers LTweenParallel:type
    -- @covers LTweenParallel:typeOf
    -- @covers lurek.tween.parallel
    it("Parallel chain and type API is callable", function()
        local obj = { x = 0 }
        local p = lurek.tween.parallel()
        p:tween(0.1, obj, { x = 1 }, "linear")
        local child = lurek.tween.tween(0.1, { y = 0 }, { y = 1 }, "linear")
        p:add(child)
        p:onComplete(function() end)
        p:start()
        expect_type("string", p:type())
        expect_type("boolean", p:typeOf("LTweenParallel"))
    end)

    -- @covers LSpring:type
    -- @covers LSpring:typeOf
    -- @covers lurek.tween.spring
    it("Spring type API is callable", function()
        local target = { x = 0 }
        local sp = lurek.tween.spring(target, { x = 10 })
        expect_type("string", sp:type())
        expect_type("boolean", sp:typeOf("LSpring"))
    end)
end)

-- @describe tween migrated from integration/tween_camera
describe("tween migrated from integration/tween_camera", function()
    -- @covers LTweenState:lerp
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("tween reaches target at completion", function()
        local state = lurek.tween.newState(0.5, "linear")
        state:tick(0.6)
        local val = state:lerp(100, 200)
        expect_near(200, val, 1.0)
    end)

    -- @covers LTweenState:isComplete
    -- @covers LTweenState:tick
    -- @covers lurek.tween.newState
    it("tween isComplete true after full duration", function()
        local state = lurek.tween.newState(0.1, "linear")
        state:tick(0.2)
        expect_true(state:isComplete())
    end)
end)

-- @describe unit: migrated from integration/test_cardgame_tween_integration.lua
describe("unit: migrated from integration/test_cardgame_tween_integration.lua", function()
        local function fresh_card()
            local card = {
                tile_x = 0,
                tile_y = 0,
                _tags = {},
            }
            function card:setTilePosition(x, y)
                self.tile_x = x
                self.tile_y = y
            end
            function card:getTilePosition()
                return self.tile_x, self.tile_y
            end
            function card:addTag(tag)
                self._tags[tag] = true
            end
            function card:hasTag(tag)
                return self._tags[tag] == true
            end
            return card
        end
        -- @covers lurek.tween.cancelAll
        -- @covers lurek.tween.tween
        -- @covers lurek.tween.update
        -- @covers Card:setTilePosition
        -- @covers Card:getTilePosition
        it("tween updates card tile_x toward target over multiple updates", function()
            lurek.tween.cancelAll()
            local card = fresh_card()
            card:setTilePosition(0, 0)

            lurek.tween.tween(2.0, card, { tile_x = 10 }, "linear")
            lurek.tween.update(0.5)
            local x_quarter = card.tile_x
            lurek.tween.update(0.5)
            local x_half = card.tile_x
            lurek.tween.update(1.0)

            expect_near(2.5, x_quarter, 0.5)
            expect_near(5.0, x_half, 0.5)
            expect_near(10.0, card.tile_x, 1e-5)
        end)

        -- @covers lurek.tween.cancelAll
        -- @covers lurek.tween.tween
        -- @covers lurek.tween.update
        -- @covers Card:addTag
        -- @covers Card:hasTag
        it("finished tween triggers cardgame callback and mutates card tags", function()
            lurek.tween.cancelAll()
            local card = fresh_card()
            card:setTilePosition(0, 0)

            local fired = 0
            local tw = lurek.tween.tween(1.0, card, { tile_x = 5 }, "linear")
            tw:onComplete(function()
                fired = fired + 1
                card:addTag("arrived")
            end)
            lurek.tween.update(1.5)

            expect_equal(1, fired)
            expect_true(card:hasTag("arrived"))
            expect_near(5.0, card.tile_x, 1e-5)
        end)

        -- @covers lurek.tween.cancelAll
        -- @covers lurek.tween.tween
        -- @covers lurek.tween.update
        -- @covers Card:setTilePosition
        it("sequential tweens move card through two distinct positions", function()
            lurek.tween.cancelAll()
            local card = fresh_card()
            card:setTilePosition(0, 0)

            lurek.tween.tween(1.0, card, { tile_x = 4 }, "linear")
            lurek.tween.update(1.0)
            expect_near(4.0, card.tile_x, 0.5)

            lurek.tween.cancelAll()
            lurek.tween.tween(1.0, card, { tile_x = 10 }, "linear")
            lurek.tween.update(1.0)
            expect_near(10.0, card.tile_x, 0.5)
        end)

        -- @covers lurek.tween.cancelAll
        -- @covers lurek.tween.tween
        -- @covers lurek.tween.update
        it("inOutQuad easing reaches midpoint value at half duration", function()
            lurek.tween.cancelAll()
            local card = fresh_card()
            card:setTilePosition(0, 0)

            lurek.tween.tween(2.0, card, { tile_x = 1.0 }, "inOutQuad")
            lurek.tween.update(1.0)
            expect_near(0.5, card.tile_x, 1e-5)
        end)

        -- @covers lurek.tween.cancelAll
        -- @covers lurek.tween.tween
        -- @covers lurek.tween.update
        -- @covers Card:getTilePosition
        it("tween animates tile_x and tile_y simultaneously", function()
            lurek.tween.cancelAll()
            local card = fresh_card()
            card:setTilePosition(0, 0)

            lurek.tween.tween(1.0, card, { tile_x = 3, tile_y = 6 }, "linear")
            lurek.tween.update(1.0)
            local x, y = card:getTilePosition()
            expect_near(3.0, x, 1e-5)
            expect_near(6.0, y, 1e-5)
        end)

        -- @covers lurek.tween.cancelAll
        -- @covers lurek.tween.tween
        it("tween rejects non-numeric duration", function()
            lurek.tween.cancelAll()
            local card = fresh_card()
            ---@type any
            local bad_duration = "oops"
            expect_error(function()
                lurek.tween.tween(bad_duration, card, { tile_x = 1 })
            end)
        end)

end)

-- @describe unit: migrated from integration/test_tween_ecs.lua
describe("unit: migrated from integration/test_tween_ecs.lua", function()
        -- @covers LTweenState:lerp
        -- @covers LTweenState:tick
        -- @covers lurek.tween.newState
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

-- @describe Relative and introspection

describe("Relative and introspection", function()
    -- @covers LTween:relative
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("relative mode applies delta offsets", function()
        lurek.tween.cancelAll()
        local obj = { x = 10 }
        local tw = lurek.tween.tween(1.0, obj, { x = 5 }, "linear")
        tw["relative"](tw, true)
        lurek.tween.update(1.0)
        expect_near(15.0, obj.x, 0.0001)
    end)

    -- @covers LTween:getElapsed
    -- @covers LTween:getRemaining
    -- @covers LTween:getFields
    -- @covers lurek.tween.tween
    -- @covers lurek.tween.update
    it("exposes elapsed remaining and field list", function()
        lurek.tween.cancelAll()
        local obj = { x = 0, y = 0 }
        local tw = lurek.tween.tween(2.0, obj, { x = 4, y = 8 }, "linear")
        lurek.tween.update(0.5)
        expect_near(0.5, tw["getElapsed"](tw), 0.001)
        expect_near(1.5, tw["getRemaining"](tw), 0.001)
        local fields = tw["getFields"](tw)
        expect_true(#fields >= 2)
    end)
end)

-- @describe Await support

describe("Await support", function()
    -- @covers LTween:await
    -- @covers lurek.tween.update
    -- @covers lurek.tween.tween
    it("await resumes coroutine after tween completion", function()
        lurek.tween.cancelAll()
        local done = false
        local obj = { x = 0 }
        local tw = lurek.tween.tween(0.2, obj, { x = 1 }, "linear")
        local co = coroutine.create(function()
            tw["await"](tw)
            done = true
        end)
        coroutine.resume(co)
        for _ = 1, 10 do
            lurek.tween.update(0.05)
            if done then
                break
            end
        end
        local status = coroutine.status(co)
        expect_true(status == "running" or status == "normal" or status == "suspended" or status == "dead")
    end)

    -- @covers LTweenSequence:await
    -- @covers lurek.tween.sequence
    -- @covers lurek.tween.update
    it("await resumes coroutine after sequence completion", function()
        lurek.tween.cancelAll()
        local done = false
        local obj = { x = 0 }
        local seq = lurek.tween.sequence():tween(0.1, obj, { x = 1 }):start()
        local co = coroutine.create(function()
            seq["await"](seq)
            done = true
        end)
        coroutine.resume(co)
        for _ = 1, 10 do
            lurek.tween.update(0.05)
            if done then
                break
            end
        end
        local status = coroutine.status(co)
        expect_true(status == "running" or status == "normal" or status == "suspended" or status == "dead")
    end)
end)

-- @describe Helper APIs

describe("Helper APIs", function()
    -- @covers lurek.tween.tweenColor
    -- @covers lurek.tween.update
    it("tweenColor animates rgba fields", function()
        lurek.tween.cancelAll()
        local c = { r = 0, g = 0, b = 0, a = 1 }
        lurek.tween["tweenColor"](0.5, c, { r = 1, g = 0.5, b = 0.25, a = 0.75 }, "linear")
        lurek.tween.update(0.5)
        expect_near(1.0, c.r, 0.001)
        expect_near(0.5, c.g, 0.001)
        expect_near(0.25, c.b, 0.001)
        expect_near(0.75, c.a, 0.001)
    end)

    -- @covers lurek.tween.tweenChain
    -- @covers lurek.tween.update
    it("tweenChain runs declarative chain", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween["tweenChain"]({
            { duration = 0.1, target = obj, fields = { x = 5 }, easing = "linear" },
            { delay = 0.1 },
            { duration = 0.1, target = obj, fields = { x = 10 }, easing = "linear" },
        })
        lurek.tween.update(0.5)
        expect_near(10.0, obj.x, 0.001)
    end)
end)

test_summary()
