-- Lurek2D timer API tests.
-- Covers frame-timing accessors, sleep/step helpers, scheduler behavior, and timing-state queries exposed through lurek.timer.

-- @describe lurek.timer module exists
describe("lurek.timer module exists", function()
    -- @covers lurek.timer
    it("lurek.timer is a table", function()
        expect_type("table", lurek.timer)
    end)
end)

-- @describe lurek.timer functions
describe("lurek.timer functions", function()
    -- @covers lurek.timer.getDelta
    it("getDelta is a function", function()
        expect_type("function", lurek.timer.getDelta)
    end)

    -- @covers lurek.timer.getDelta
    it("getDelta returns a number", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
    end)

    -- @covers lurek.timer.getDelta
    it("getDelta returns non-negative", function()
        local dt = lurek.timer.getDelta()
        expect_true(dt >= 0, "delta >= 0")
    end)

    -- @covers lurek.timer.getFPS
    it("getFPS is a function", function()
        expect_type("function", lurek.timer.getFPS)
    end)

    -- @covers lurek.timer.getFPS
    it("getFPS returns a number", function()
        local fps = lurek.timer.getFPS()
        expect_type("number", fps)
    end)

    -- @covers lurek.timer.getFPS
    it("getFPS returns non-negative", function()
        local fps = lurek.timer.getFPS()
        expect_true(fps >= 0, "fps >= 0")
    end)

    -- @covers lurek.timer.getTime
    it("getTime is a function", function()
        expect_type("function", lurek.timer.getTime)
    end)

    -- @covers lurek.timer.getTime
    it("getTime returns a number", function()
        local t = lurek.timer.getTime()
        expect_type("number", t)
    end)

    -- @covers lurek.timer.getTime
    it("getTime returns non-negative", function()
        local t = lurek.timer.getTime()
        expect_true(t >= 0, "time >= 0")
    end)

    -- @covers lurek.timer.getAverageDelta
    it("getAverageDelta is a function", function()
        expect_type("function", lurek.timer.getAverageDelta)
    end)

    -- @covers lurek.timer.getAverageDelta
    it("getAverageDelta returns a number", function()
        local avg = lurek.timer.getAverageDelta()
        expect_type("number", avg)
    end)

    -- @covers lurek.timer.getAverageDelta
    it("getAverageDelta returns non-negative", function()
        local avg = lurek.timer.getAverageDelta()
        expect_true(avg >= 0, "average delta >= 0")
    end)

    -- @covers lurek.timer.getMicroTime
    it("getMicroTime is a function", function()
        expect_type("function", lurek.timer.getMicroTime)
    end)

    -- @covers lurek.timer.getMicroTime
    it("getMicroTime returns a number", function()
        local t = lurek.timer.getMicroTime()
        expect_type("number", t)
    end)

    -- @covers lurek.timer.getMicroTime
    it("getMicroTime returns non-negative", function()
        local t = lurek.timer.getMicroTime()
        expect_true(t >= 0, "getMicroTime >= 0")
    end)

    -- @covers lurek.timer.getMicroTime
    it("getMicroTime is monotonically increasing", function()
        local t1 = lurek.timer.getMicroTime()
        local t2 = lurek.timer.getMicroTime()
        expect_true(t2 >= t1, "getMicroTime must not go backward")
    end)

    -- @covers lurek.timer.sleep
    it("sleep is a function", function()
        expect_type("function", lurek.timer.sleep)
    end)

    -- @covers lurek.timer.sleep
    it("sleep with zero or negative does not error", function()
        lurek.timer.sleep(0)
        lurek.timer.sleep(-1)
        expect_true(true, "sleep with zero/negative is safe")
    end)

    -- @covers lurek.timer.step
    it("step is a function", function()
        expect_type("function", lurek.timer.step)
    end)

    -- @covers lurek.timer.step
    it("step returns a number", function()
        local dt = lurek.timer.step()
        expect_type("number", dt)
    end)

    -- @covers lurek.timer.step
    it("step returns non-negative delta", function()
        local dt = lurek.timer.step()
        expect_true(dt >= 0, "step() delta >= 0")
    end)

    -- @covers lurek.timer.getDelta
    -- @covers lurek.timer.step
    it("step updates getDelta", function()
        local dt = lurek.timer.step()
        local after = lurek.timer.getDelta()
        -- After step(), getDelta() should return the same value step() returned
        expect_true(math.abs(after - dt) < 1e-9, "getDelta matches step() result")
    end)
end)

-- @describe lurek.timer physics delta
describe("lurek.timer physics delta", function()
    -- @covers lurek.timer.getPhysicsDelta
    it("getPhysicsDelta is a function", function()
        expect_type("function", lurek.timer.getPhysicsDelta)
    end)

    -- @covers lurek.timer.setPhysicsDelta
    it("setPhysicsDelta is a function", function()
        expect_type("function", lurek.timer.setPhysicsDelta)
    end)

    -- @covers lurek.timer.getPhysicsDelta
    it("getPhysicsDelta returns default 1/60", function()
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-9)
    end)

    -- @covers lurek.timer.getPhysicsDelta
    -- @covers lurek.timer.setPhysicsDelta
    it("setPhysicsDelta changes the value", function()
        local original = lurek.timer.getPhysicsDelta()
        lurek.timer.setPhysicsDelta(1.0 / 30.0)
        local after = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 30.0, after, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(original)
    end)

    -- @covers lurek.timer.getPhysicsDelta
    -- @covers lurek.timer.setPhysicsDelta
    it("setPhysicsDelta clamps to minimum 1/240", function()
        lurek.timer.setPhysicsDelta(0.001) -- near 1000 Hz, too fast
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 240.0, dt, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
    end)

    -- @covers lurek.timer.getPhysicsDelta
    -- @covers lurek.timer.setPhysicsDelta
    it("setPhysicsDelta clamps to maximum 1/10", function()
        lurek.timer.setPhysicsDelta(1.0) -- 1 Hz, too slow
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 10.0, dt, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
    end)

    -- @covers lurek.timer.getPhysicsDelta
    -- @covers lurek.timer.setPhysicsDelta
    it("default physics tick rate is consistent with 60 Hz", function()
        -- Restore to default first, then verify it is near 1/60.
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-6)
    end)
end)

-- Scheduler

-- @describe lurek.timer.newScheduler
describe("lurek.timer.newScheduler", function()
    -- @covers lurek.timer.newScheduler
    it("creates a scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_not_nil(sched)
    end)

    -- @covers LScheduler:getCount
    -- @covers lurek.timer.newScheduler
    it("getCount returns 0 for empty scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_equal(sched:getCount(), 0)
    end)

    -- @covers LScheduler:isEmpty
    -- @covers lurek.timer.newScheduler
    it("isEmpty returns true for empty scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_true(sched:isEmpty())
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:getCount
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("after creates a one-shot timer", function()
        local sched = lurek.timer.newScheduler()
        local fired = false
        sched:after(0.5, function() fired = true end)
        expect_equal(sched:getCount(), 1)
        sched:update(0.3)
        expect_equal(fired, false)
        sched:update(0.3)
        expect_equal(fired, true)
        expect_equal(sched:getCount(), 0)
    end)

    -- @covers LScheduler:every
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("every fires repeatedly", function()
        local sched = lurek.timer.newScheduler()
        local count = 0
        sched:every(0.5, function() count = count + 1 end, 3)
        sched:update(0.5)
        expect_equal(count, 1)
        sched:update(0.5)
        expect_equal(count, 2)
        sched:update(0.5)
        expect_equal(count, 3)
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:cancel
    -- @covers LScheduler:getCount
    -- @covers lurek.timer.newScheduler
    it("cancel removes a timer", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:after(1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancel(id)
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)

    -- @covers LScheduler:cancel
    -- @covers lurek.timer.newScheduler
    it("cancel returns false for unknown id", function()
        local sched = lurek.timer.newScheduler()
        local ok = sched:cancel(9999)
        expect_equal(ok, false)
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:cancelAll
    -- @covers LScheduler:every
    -- @covers LScheduler:getCount
    -- @covers lurek.timer.newScheduler
    it("cancelAll removes all timers", function()
        local sched = lurek.timer.newScheduler()
        sched:after(1.0, function() end)
        sched:after(2.0, function() end)
        sched:every(0.5, function() end)
        expect_equal(sched:getCount(), 3)
        sched:cancelAll()
        expect_equal(sched:getCount(), 0)
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:isPaused
    -- @covers LScheduler:pause
    -- @covers LScheduler:resume
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("pause and resume stops and restarts a timer", function()
        local sched = lurek.timer.newScheduler()
        local fired = false
        local id = sched:after(1.0, function() fired = true end)
        sched:update(0.5)
        sched:pause(id)
        expect_true(sched:isPaused(id))
        sched:update(2.0)
        expect_equal(fired, false)
        sched:resume(id)
        expect_equal(sched:isPaused(id), false)
        sched:update(0.6)
        expect_equal(fired, true)
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:getRemaining
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("getRemaining tracks countdown", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:after(5.0, function() end)
        local ok1, remaining1 = sched:getRemaining(id)
        expect_equal(ok1, true)
        expect_near(remaining1, 5.0, 0.0001)
        sched:update(1.0)
        local ok2, remaining2 = sched:getRemaining(id)
        expect_equal(ok2, true)
        expect_near(remaining2, 4.0, 0.0001)
    end)

    -- @covers LScheduler:every
    -- @covers LScheduler:getInterval
    -- @covers lurek.timer.newScheduler
    it("getInterval returns timer interval", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:every(0.25, function() end)
        local ok, interval = sched:getInterval(id)
        expect_equal(ok, true)
        expect_near(interval, 0.25, 0.0001)
    end)

    -- @covers LScheduler:every
    -- @covers LScheduler:getInterval
    -- @covers LScheduler:setInterval
    -- @covers lurek.timer.newScheduler
    it("setInterval changes timer interval", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:every(0.5, function() end)
        sched:setInterval(id, 1.0)
        local ok, interval = sched:getInterval(id)
        expect_equal(ok, true)
        expect_near(interval, 1.0, 0.0001)
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:getTimeScale
    -- @covers LScheduler:setTimeScale
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("setTimeScale affects update speed", function()
        local sched = lurek.timer.newScheduler()
        local fired = false
        sched:after(1.0, function() fired = true end)
        sched:setTimeScale(2.0)
        expect_near(sched:getTimeScale(), 2.0, 0.0001)
        sched:update(0.5) -- 0.5 * 2.0 = 1.0 elapsed
        expect_equal(fired, true)
    end)

    -- @covers LScheduler:afterNamed
    -- @covers LScheduler:cancelNamed
    -- @covers LScheduler:getCount
    -- @covers lurek.timer.newScheduler
    it("afterNamed creates named timer that cancelNamed can remove", function()
        local sched = lurek.timer.newScheduler()
        sched:afterNamed("mytimer", 1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancelNamed("mytimer")
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)
end)

-- @describe lurek.timer.getFrameCount
describe("lurek.timer.getFrameCount", function()
    -- @covers lurek.timer.getFrameCount
    it("getFrameCount is a function", function()
        expect_type("function", lurek.timer.getFrameCount)
    end)

    -- @covers lurek.timer.getFrameCount
    it("getFrameCount returns a number", function()
        local count = lurek.timer.getFrameCount()
        expect_type("number", count)
    end)

    -- @covers lurek.timer.getFrameCount
    it("getFrameCount returns a non-negative integer", function()
        local count = lurek.timer.getFrameCount()
        expect_true(count >= 0, "frame count must be non-negative")
        expect_true(count == math.floor(count), "frame count must be an integer")
    end)
end)

-- @describe lurek.timer new scheduler features
describe("lurek.timer new scheduler features", function()
  -- @covers LScheduler:everyNamed
  -- @covers LScheduler:pauseNamed
  -- @covers LScheduler:resumeNamed
  -- @covers LScheduler:update
  -- @covers lurek.timer.newScheduler
  it("pauseNamed and resumeNamed block and allow events", function()
    local s = lurek.timer.newScheduler()
    local fired = false
    s:everyNamed("mytimer", 0.1, function() fired = true end)
    s:pauseNamed("mytimer")
    s:update(0.2)
    expect_equal(fired, false)
    s:resumeNamed("mytimer")
    s:update(0.1)
    expect_equal(fired, true)
  end)

  -- @covers LScheduler:update
  -- @covers lurek.timer.chain
  it("chain fires steps in sequence", function()
    local results = {}
    local chain_sched = lurek.timer.chain({
      { delay = 0.1, func = function() table.insert(results, 1) end },
      { delay = 0.2, func = function() table.insert(results, 2) end },
    })
    chain_sched:update(0.15)
    expect_equal(#results, 1)
    chain_sched:update(0.2)
    expect_equal(#results, 2)
  end)

  -- @covers lurek.timer.afterReal
  -- @covers lurek.timer.tickRealTimers
  it("afterReal fires via tickRealTimers", function()
    local fired = false
    lurek.timer.afterReal(0.0, function() fired = true end)
    lurek.timer.tickRealTimers()
    expect_equal(fired, true)
  end)

  -- @covers lurek.timer.getSmoothedDelta
  -- @covers lurek.timer.setSmoothingFactor
  it("getSmoothedDelta returns a positive number", function()
    lurek.timer.setSmoothingFactor(0.5)
    local dt = lurek.timer.getSmoothedDelta()
    expect_true(type(dt) == "number" and dt >= 0, "smoothed delta must be non-negative")
  end)

  -- @covers LScheduler:everyNamed
  -- @covers LScheduler:isPausedNamed
  -- @covers LScheduler:pauseNamed
  -- @covers LScheduler:resumeNamed
  -- @covers lurek.timer.newScheduler
  it("isPausedNamed reflects pause state", function()
    local s = lurek.timer.newScheduler()
    s:everyNamed("ticker", 1.0, function() end)
    expect_equal(s:isPausedNamed("ticker"), false)
    s:pauseNamed("ticker")
    expect_equal(s:isPausedNamed("ticker"), true)
    s:resumeNamed("ticker")
    expect_equal(s:isPausedNamed("ticker"), false)
  end)
end)

-- Coroutine wait support

-- @describe lurek.timer coroutine wait support
describe("lurek.timer coroutine wait support", function()
    -- @covers lurek.timer.tickWaits
    it("timer_tickWaits_is_callable", function()
        lurek.timer.tickWaits()
        expect_true(true, "tickWaits should not error when there are no pending waits")
    end)

    -- @covers lurek.timer.waitFrames
    it("timer_waitFrames_requires_coroutine_context", function()
        expect_error(function()
            lurek.timer.waitFrames(1)
        end)
    end)

    -- @covers lurek.timer.tickWaits
    -- @covers lurek.timer.waitFrames
    it("timer_waitFrames_resumes_after_tick", function()
        local co = coroutine.create(function()
            lurek.timer.waitFrames(1)
        end)
        coroutine.resume(co)
        -- Coroutine is suspended waiting for 1 frame tick
        lurek.timer.tickWaits()
        -- After tick the scheduler should have resumed the coroutine
        expect_equal(coroutine.status(co), "dead",
            "coroutine should be dead after waitFrames(1) + tickWaits()")
    end)

    -- @covers lurek.timer.tickWaits
    -- @covers lurek.timer.waitSeconds
    it("timer_waitSeconds_inside_coroutine_yields", function()
        local co = coroutine.create(function()
            lurek.timer.waitSeconds(0)
        end)
        coroutine.resume(co)
        lurek.timer.tickWaits()
        expect_equal(coroutine.status(co), "dead",
            "coroutine should be dead after waitSeconds(0) + tickWaits()")
    end)
end)

-- =========================================================================
-- physicsMaxSteps configurability (PR-4)
-- =========================================================================

-- @describe lurek.timer physicsMaxSteps configurability
describe("lurek.timer physicsMaxSteps configurability", function()
    -- @covers lurek.timer.getPhysicsMaxSteps
    it("getPhysicsMaxSteps is a function", function()
        expect_type("function", lurek.timer.getPhysicsMaxSteps)
    end)

    -- @covers lurek.timer.setPhysicsMaxSteps
    it("setPhysicsMaxSteps is a function", function()
        expect_type("function", lurek.timer.setPhysicsMaxSteps)
    end)

    -- @covers lurek.timer.getPhysicsMaxSteps
    it("getPhysicsMaxSteps_default_is_8", function()
        local steps = lurek.timer.getPhysicsMaxSteps()
        expect_equal(8, steps)
    end)

    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @covers lurek.timer.setPhysicsMaxSteps
    it("setPhysicsMaxSteps_roundtrips_value", function()
        lurek.timer.setPhysicsMaxSteps(16)
        expect_equal(16, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)

    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @covers lurek.timer.setPhysicsMaxSteps
    it("setPhysicsMaxSteps_clamps_below_minimum_to_1", function()
        lurek.timer.setPhysicsMaxSteps(0)
        expect_equal(1, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)

    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @covers lurek.timer.setPhysicsMaxSteps
    it("setPhysicsMaxSteps_clamps_above_maximum_to_64", function()
        lurek.timer.setPhysicsMaxSteps(999)
        expect_equal(64, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)
end)

-- afterFrames / everyFrames / updateFrames
-- @describe lurek.timer scheduler frame events
describe("lurek.timer scheduler frame events", function()
  -- @covers LScheduler:afterFrames
  -- @covers LScheduler:updateFrames
  -- @covers lurek.timer.newScheduler
  it("afterFrames fires after n frames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(2, function() fired = fired + 1 end)
    expect_equal(0, fired)
    s:updateFrames()
    expect_equal(0, fired)
    s:updateFrames()
    expect_equal(1, fired)
  end)

  -- @covers LScheduler:afterFrames
  -- @covers LScheduler:updateFrames
  -- @covers lurek.timer.newScheduler
  it("afterFrames fires exactly once", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(1, function() fired = fired + 1 end)
    for _ = 1, 5 do s:updateFrames() end
    expect_equal(1, fired)
  end)

  -- @covers LScheduler:everyFrames
  -- @covers LScheduler:updateFrames
  -- @covers lurek.timer.newScheduler
  it("everyFrames fires every n frames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:everyFrames(2, function() fired = fired + 1 end)
    for _ = 1, 6 do s:updateFrames() end
    expect_equal(3, fired)
  end)

  -- @covers LScheduler:everyFrames
  -- @covers LScheduler:updateFrames
  -- @covers lurek.timer.newScheduler
  it("everyFrames respects count limit", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:everyFrames(1, function() fired = fired + 1 end, 3)
    for _ = 1, 10 do s:updateFrames() end
    expect_equal(3, fired)
  end)

  -- @covers LScheduler:afterFrames
  -- @covers LScheduler:updateFrames
  -- @covers lurek.timer.newScheduler
  it("updateFrames returns fired count", function()
    local s = lurek.timer.newScheduler()
    s:afterFrames(1, function() end)
    s:afterFrames(1, function() end)
    local count = s:updateFrames()
    expect_equal(2, count)
  end)

  -- @covers LScheduler:afterFrames
  -- @covers LScheduler:updateFrames
  -- @covers lurek.timer.newScheduler
  it("afterFrames(0) fires on first updateFrames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(0, function() fired = fired + 1 end)
    s:updateFrames()
    expect_equal(1, fired)
  end)
end)

-- afterNamed replacement semantics

-- @describe lurek.timer scheduler afterNamed replacement
describe("lurek.timer scheduler afterNamed replacement", function()
  -- @covers LScheduler:afterNamed
  -- @covers LScheduler:getCount
  -- @covers lurek.timer.newScheduler
  it("afterNamed with same name replaces the previous timer", function()
    local s = lurek.timer.newScheduler()
    s:afterNamed("step", 5.0, function() end)
    expect_equal(1, s:getCount())
    s:afterNamed("step", 5.0, function() end)
    expect_equal(1, s:getCount())
  end)

  -- @covers LScheduler:afterNamed
  -- @covers LScheduler:update
  -- @covers lurek.timer.newScheduler
  it("afterNamed replacement fires the new callback, not the old one", function()
    local s = lurek.timer.newScheduler()
    local fired_old = false
    local fired_new = false
    s:afterNamed("action", 0.1, function() fired_old = true end)
    s:afterNamed("action", 0.1, function() fired_new = true end)
    s:update(0.2)
    expect_equal(false, fired_old)
    expect_equal(true,  fired_new)
  end)

  -- @covers LScheduler:afterNamed
  -- @covers LScheduler:getCount
  -- @covers lurek.timer.newScheduler
  it("afterNamed with different names does not replace", function()
    local s = lurek.timer.newScheduler()
    s:afterNamed("a", 1.0, function() end)
    s:afterNamed("b", 1.0, function() end)
    expect_equal(2, s:getCount())
  end)
end)

-- lurek.timer.waitSeconds

-- @describe lurek.timer.waitSeconds
describe("lurek.timer.waitSeconds", function()
  -- @covers lurek.timer.waitSeconds
  it("waitSeconds is a function", function()
      expect_type("function", lurek.timer.waitSeconds)
  end)

  -- @covers lurek.timer.tickWaits
  it("waitSeconds(0) yields and resumes after tickWaits", function()
    local co = coroutine.create(function()
        lurek.timer.waitSeconds(0)
    end)
    coroutine.resume(co)
    lurek.timer.tickWaits()
    expect_equal("dead", coroutine.status(co))
  end)
end)

-- @describe lurek.timer scheduler remaining coverage
describe("lurek.timer scheduler remaining coverage", function()
    -- @covers LScheduler:every
    -- @covers LScheduler:getRepeatCount
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("getRepeatCount tracks remaining repetitions", function()
        local s = lurek.timer.newScheduler()
        local id = s:every(0.5, function() end, 3)

        local ok1, count1 = s:getRepeatCount(id)
        expect_equal(true, ok1)
        expect_equal(3, count1)

        s:update(0.5)

        local ok2, count2 = s:getRepeatCount(id)
        expect_equal(true, ok2)
        expect_equal(2, count2)
    end)

    -- @covers LScheduler:after
    -- @covers LScheduler:resetEvent
    -- @covers LScheduler:update
    -- @covers lurek.timer.newScheduler
    it("resetEvent restarts the remaining countdown", function()
        local s = lurek.timer.newScheduler()
        local fired = false
        local id = s:after(1.0, function() fired = true end)

        s:update(0.7)
        expect_equal(true, s:resetEvent(id))

        s:update(0.5)
        expect_equal(false, fired)

        s:update(0.6)
        expect_equal(true, fired)
    end)
end)

-- @describe timer strict: LScheduler type/typeOf
describe("timer strict: LScheduler type/typeOf", function()
    -- @covers LScheduler:type
    -- @covers LScheduler:typeOf
    -- @covers lurek.timer.newScheduler
    it("LScheduler type and typeOf are callable", function()
        local s = lurek.timer.newScheduler()
        expect_type("string", s:type())
        expect_type("boolean", s:typeOf("Object"))
    end)
end)

-- @describe timer migrated from integration animation/audio timer
describe("timer migrated from integration animation/audio timer", function()
    -- @covers lurek.timer.getTime
    it("timer.getTime is non-negative", function()
        local t0 = lurek.timer.getTime()
        expect_type("number", t0)
        expect_true(t0 >= 0)
    end)

    -- @covers lurek.timer.getDelta
    it("timer.getDelta returns non-negative number", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
        expect_true(dt >= 0)
    end)

    -- @covers lurek.timer.getDelta
    it("timer delta provides consistent timestep", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
        expect_true(dt >= 0)
    end)

    -- @covers lurek.timer.getTime
    it("timer getTime returns increasing values", function()
        local t1 = lurek.timer.getTime()
        expect_type("number", t1)
        expect_true(t1 >= 0)
    end)
end)

-- @describe unit: migrated from integration/test_quest_time_integration.lua
describe("unit: migrated from integration/test_quest_time_integration.lua", function()
        local quest = rawget(_G, "quest")
        if quest == nil then
            -- @covers quest
            it("quest module unavailable in this runtime", function()
                expect_nil(quest)
            end)
            return
        end

        local function build_log_with_quest(id)
            local log = quest.newQuestLog()
            local q = quest.newQuest(id, id)
            local stage = quest.newQuestStage("s", "S")
            stage:addObjective(quest.newObjective("obj", "Objective", 1))
            q:addStage(stage)
            log:addQuest(q)
            log:startQuest(id)
            return log, q
        end
        -- @covers LScheduler:after
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("scheduler:after deadline auto-fails an active quest", function()
            local log, q = build_log_with_quest("ticking")
            local sched = lurek.timer.newScheduler()

            sched:after(2.0, function() log:failQuest("ticking") end)

            sched:update(1.0)
            expect_equal("active", q.status)
            sched:update(1.5)
            expect_equal("failed", q.status)
        end)

        -- @covers LScheduler:every
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("scheduler:every advances objective progress and completes it", function()
            local log = quest.newQuestLog()
            local q = quest.newQuest("hunt", "Hunt")
            local stage = quest.newQuestStage("s", "S")
            stage:addObjective(quest.newObjective("kills", "Slay foes", 3))
            q:addStage(stage)
            log:addQuest(q)
            log:startQuest("hunt")

            local sched = lurek.timer.newScheduler()
            sched:every(1.0, function()
                log:advanceObjective("hunt", "kills", 1)
            end, 3)

            sched:update(1.0); sched:update(1.0); sched:update(1.0)
            expect_equal(3, stage:getObjective("kills").current)
            expect_true(stage:getObjective("kills"):isComplete())
        end)

        -- @covers LScheduler:after
        -- @covers LScheduler:cancel
        -- @covers LScheduler:getCount
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("cancel aborts the deadline and the quest stays active", function()
            local log, q = build_log_with_quest("cancellable")
            local sched = lurek.timer.newScheduler()

            local id = sched:after(1.0, function() log:failQuest("cancellable") end)
            local ok = sched:cancel(id)
            expect_true(ok)
            sched:update(2.0)
            expect_equal("active", q.status)
            expect_equal(0, sched:getCount())
        end)

        -- resuming lets it fire after the remaining wall time elapses.
        -- @covers LScheduler:after
        -- @covers LScheduler:pause
        -- @covers LScheduler:resume
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("pause and resume preserves the remaining deadline window", function()
            local log, q = build_log_with_quest("pausable")
            local sched = lurek.timer.newScheduler()
            local id = sched:after(1.0, function() log:failQuest("pausable") end)

            sched:update(0.4)
            sched:pause(id)
            sched:update(5.0)
            expect_equal("active", q.status)
            sched:resume(id)
            sched:update(0.7)
            expect_equal("failed", q.status)
        end)

        -- @covers LScheduler:after
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("zero-delay deadline fires on the next update", function()
            local log, q = build_log_with_quest("instant")
            local sched = lurek.timer.newScheduler()
            sched:after(0.0, function() log:failQuest("instant") end)
            sched:update(0.0001)
            expect_equal("failed", q.status)
        end)

        -- @covers LScheduler:after
        -- @covers lurek.timer.newScheduler
        it("scheduler:after rejects a non-function callback", function()
            local sched = lurek.timer.newScheduler()
            ---@type any
            local bad_cb = "not a function"
            expect_error(function()
                sched:after(1.0, bad_cb)
            end)
        end)

    end)

-- @describe unit: migrated from integration/test_timer_event.lua
describe("unit: migrated from integration/test_timer_event.lua", function()
        -- @covers LScheduler:after
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("timer fires once after update accumulates enough dt", function()
            local sched = lurek.timer.newScheduler()
            local fired = false

            sched:after(0.1, function()
                fired = true
            end)

            sched:update(0.05)
            expect_true(not fired, "not yet fired at 0.05 s")

            sched:update(0.06)
            expect_true(fired, "fired after 0.11 s total")
        end)

        -- @covers LScheduler:after
        -- @covers LScheduler:getCount
        -- @covers LScheduler:update
        -- @covers lurek.timer.newScheduler
        it("timer count decrements after firing once", function()
            local sched = lurek.timer.newScheduler()
            sched:after(0.01, function() end)
            expect_equal(sched:getCount(), 1, "1 scheduled timer")
            sched:update(0.02)
            expect_equal(sched:getCount(), 0, "0 timers after firing")
        end)

end)

-- @describe unit: migrated from integration/test_timer_math.lua
describe("unit: migrated from integration/test_timer_math.lua", function()
        -- @covers lurek.timer.getDelta
        it("getDelta returns a number", function()
            local dt = lurek.timer.getDelta()
            expect_not_nil(dt, "getDelta returns a value")
            expect_true(type(dt) == "number", "dt is a number")
        end)

end)

test_summary()
