-- Lurek2D timer API tests.
-- Covers frame-timing accessors, sleep/step helpers, scheduler behavior, and timing-state queries exposed through lurek.timer.

describe("lurek.timer module exists", function()
    it("lurek.timer is a table", function()
        expect_type("table", lurek.timer)
    end)
end)

describe("lurek.timer functions", function()
    it("getDelta is a function", function()
        expect_type("function", lurek.timer.getDelta)
    end)

    it("getDelta returns a number", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
    end)

    it("getDelta returns non-negative", function()
        local dt = lurek.timer.getDelta()
        expect_true(dt >= 0, "delta >= 0")
    end)

    it("getFPS is a function", function()
        expect_type("function", lurek.timer.getFPS)
    end)

    it("getFPS returns a number", function()
        local fps = lurek.timer.getFPS()
        expect_type("number", fps)
    end)

    it("getFPS returns non-negative", function()
        local fps = lurek.timer.getFPS()
        expect_true(fps >= 0, "fps >= 0")
    end)

    it("getTime is a function", function()
        expect_type("function", lurek.timer.getTime)
    end)

    it("getTime returns a number", function()
        local t = lurek.timer.getTime()
        expect_type("number", t)
    end)

    it("getTime returns non-negative", function()
        local t = lurek.timer.getTime()
        expect_true(t >= 0, "time >= 0")
    end)

    it("getAverageDelta is a function", function()
        expect_type("function", lurek.timer.getAverageDelta)
    end)

    it("getAverageDelta returns a number", function()
        local avg = lurek.timer.getAverageDelta()
        expect_type("number", avg)
    end)

    it("getAverageDelta returns non-negative", function()
        local avg = lurek.timer.getAverageDelta()
        expect_true(avg >= 0, "average delta >= 0")
    end)

    it("getMicroTime is a function", function()
        expect_type("function", lurek.timer.getMicroTime)
    end)

    it("getMicroTime returns a number", function()
        local t = lurek.timer.getMicroTime()
        expect_type("number", t)
    end)

    it("getMicroTime returns non-negative", function()
        local t = lurek.timer.getMicroTime()
        expect_true(t >= 0, "getMicroTime >= 0")
    end)

    it("getMicroTime is monotonically increasing", function()
        local t1 = lurek.timer.getMicroTime()
        local t2 = lurek.timer.getMicroTime()
        expect_true(t2 >= t1, "getMicroTime must not go backward")
    end)

    it("sleep is a function", function()
        expect_type("function", lurek.timer.sleep)
    end)

    it("sleep with zero or negative does not error", function()
        lurek.timer.sleep(0)
        lurek.timer.sleep(-1)
        expect_true(true, "sleep with zero/negative is safe")
    end)

    it("step is a function", function()
        expect_type("function", lurek.timer.step)
    end)

    it("step returns a number", function()
        local dt = lurek.timer.step()
        expect_type("number", dt)
    end)

    it("step returns non-negative delta", function()
        local dt = lurek.timer.step()
        expect_true(dt >= 0, "step() delta >= 0")
    end)

    it("step updates getDelta", function()
        local dt = lurek.timer.step()
        local after = lurek.timer.getDelta()
        -- After step(), getDelta() should return the same value step() returned
        expect_true(math.abs(after - dt) < 1e-9, "getDelta matches step() result")
    end)
end)

describe("lurek.timer physics delta", function()
    it("getPhysicsDelta is a function", function()
        expect_type("function", lurek.timer.getPhysicsDelta)
    end)

    it("setPhysicsDelta is a function", function()
        expect_type("function", lurek.timer.setPhysicsDelta)
    end)

    it("getPhysicsDelta returns default 1/60", function()
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-9)
    end)

    it("setPhysicsDelta changes the value", function()
        local original = lurek.timer.getPhysicsDelta()
        lurek.timer.setPhysicsDelta(1.0 / 30.0)
        local after = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 30.0, after, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(original)
    end)

    it("setPhysicsDelta clamps to minimum 1/240", function()
        lurek.timer.setPhysicsDelta(0.001) -- near 1000 Hz, too fast
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 240.0, dt, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
    end)

    it("setPhysicsDelta clamps to maximum 1/10", function()
        lurek.timer.setPhysicsDelta(1.0) -- 1 Hz, too slow
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 10.0, dt, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
    end)

    it("default physics tick rate is consistent with 60 Hz", function()
        -- Restore to default first, then verify it is near 1/60.
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-6)
    end)
end)

-- Scheduler

describe("lurek.timer.newScheduler", function()
    it("creates a scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_not_nil(sched)
    end)

    it("getCount returns 0 for empty scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_equal(sched:getCount(), 0)
    end)

    it("isEmpty returns true for empty scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_true(sched:isEmpty())
    end)

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

    it("cancel removes a timer", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:after(1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancel(id)
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)

    it("cancel returns false for unknown id", function()
        local sched = lurek.timer.newScheduler()
        local ok = sched:cancel(9999)
        expect_equal(ok, false)
    end)

    it("cancelAll removes all timers", function()
        local sched = lurek.timer.newScheduler()
        sched:after(1.0, function() end)
        sched:after(2.0, function() end)
        sched:every(0.5, function() end)
        expect_equal(sched:getCount(), 3)
        sched:cancelAll()
        expect_equal(sched:getCount(), 0)
    end)

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

    it("getInterval returns timer interval", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:every(0.25, function() end)
        local ok, interval = sched:getInterval(id)
        expect_equal(ok, true)
        expect_near(interval, 0.25, 0.0001)
    end)

    it("setInterval changes timer interval", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:every(0.5, function() end)
        sched:setInterval(id, 1.0)
        local ok, interval = sched:getInterval(id)
        expect_equal(ok, true)
        expect_near(interval, 1.0, 0.0001)
    end)

    it("setTimeScale affects update speed", function()
        local sched = lurek.timer.newScheduler()
        local fired = false
        sched:after(1.0, function() fired = true end)
        sched:setTimeScale(2.0)
        expect_near(sched:getTimeScale(), 2.0, 0.0001)
        sched:update(0.5) -- 0.5 * 2.0 = 1.0 elapsed
        expect_equal(fired, true)
    end)

    it("afterNamed creates named timer that cancelNamed can remove", function()
        local sched = lurek.timer.newScheduler()
        sched:afterNamed("mytimer", 1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancelNamed("mytimer")
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)
end)

describe("lurek.timer.getFrameCount", function()
    it("getFrameCount is a function", function()
        expect_type("function", lurek.timer.getFrameCount)
    end)

    it("getFrameCount returns a number", function()
        local count = lurek.timer.getFrameCount()
        expect_type("number", count)
    end)

    it("getFrameCount returns a non-negative integer", function()
        local count = lurek.timer.getFrameCount()
        expect_true(count >= 0, "frame count must be non-negative")
        expect_true(count == math.floor(count), "frame count must be an integer")
    end)
end)

describe("lurek.timer new scheduler features", function()
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

  it("afterReal fires via tickRealTimers", function()
    local fired = false
    lurek.timer.afterReal(0.0, function() fired = true end)
    lurek.timer.tickRealTimers()
    expect_equal(fired, true)
  end)

  it("getSmoothedDelta returns a positive number", function()
    lurek.timer.setSmoothingFactor(0.5)
    local dt = lurek.timer.getSmoothedDelta()
    expect_true(type(dt) == "number" and dt >= 0, "smoothed delta must be non-negative")
  end)

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

describe("lurek.timer coroutine wait support", function()
    it("timer_tickWaits_is_callable", function()
        lurek.timer.tickWaits()
        expect_true(true, "tickWaits should not error when there are no pending waits")
    end)

    it("timer_waitFrames_requires_coroutine_context", function()
        expect_error(function()
            lurek.timer.waitFrames(1)
        end)
    end)

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

describe("lurek.timer physicsMaxSteps configurability", function()
    it("getPhysicsMaxSteps is a function", function()
        expect_type("function", lurek.timer.getPhysicsMaxSteps)
    end)

    it("setPhysicsMaxSteps is a function", function()
        expect_type("function", lurek.timer.setPhysicsMaxSteps)
    end)

    it("getPhysicsMaxSteps_default_is_8", function()
        local steps = lurek.timer.getPhysicsMaxSteps()
        expect_equal(8, steps)
    end)

    it("setPhysicsMaxSteps_roundtrips_value", function()
        lurek.timer.setPhysicsMaxSteps(16)
        expect_equal(16, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)

    it("setPhysicsMaxSteps_clamps_below_minimum_to_1", function()
        lurek.timer.setPhysicsMaxSteps(0)
        expect_equal(1, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)

    it("setPhysicsMaxSteps_clamps_above_maximum_to_64", function()
        lurek.timer.setPhysicsMaxSteps(999)
        expect_equal(64, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)
end)

-- afterFrames / everyFrames / updateFrames
describe("lurek.timer scheduler frame events", function()
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

  it("afterFrames fires exactly once", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(1, function() fired = fired + 1 end)
    for _ = 1, 5 do s:updateFrames() end
    expect_equal(1, fired)
  end)

  it("everyFrames fires every n frames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:everyFrames(2, function() fired = fired + 1 end)
    for _ = 1, 6 do s:updateFrames() end
    expect_equal(3, fired)
  end)

  it("everyFrames respects count limit", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:everyFrames(1, function() fired = fired + 1 end, 3)
    for _ = 1, 10 do s:updateFrames() end
    expect_equal(3, fired)
  end)

  it("updateFrames returns fired count", function()
    local s = lurek.timer.newScheduler()
    s:afterFrames(1, function() end)
    s:afterFrames(1, function() end)
    local count = s:updateFrames()
    expect_equal(2, count)
  end)

  it("afterFrames(0) fires on first updateFrames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(0, function() fired = fired + 1 end)
    s:updateFrames()
    expect_equal(1, fired)
  end)
end)

-- afterNamed replacement semantics

describe("lurek.timer scheduler afterNamed replacement", function()
  it("afterNamed with same name replaces the previous timer", function()
    local s = lurek.timer.newScheduler()
    s:afterNamed("step", 5.0, function() end)
    expect_equal(1, s:getCount())
    s:afterNamed("step", 5.0, function() end)
    expect_equal(1, s:getCount())
  end)

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

  it("afterNamed with different names does not replace", function()
    local s = lurek.timer.newScheduler()
    s:afterNamed("a", 1.0, function() end)
    s:afterNamed("b", 1.0, function() end)
    expect_equal(2, s:getCount())
  end)
end)

-- lurek.timer.delay

describe("lurek.timer.delay", function()
  it("delay is a function", function()
        expect_type("function", lurek.timer["delay"])
  end)

  it("delay(0) yields and resumes after tickWaits", function()
    local co = coroutine.create(function()
            lurek.timer["delay"](0)
    end)
    coroutine.resume(co)
    lurek.timer.tickWaits()
    expect_equal("dead", coroutine.status(co))
  end)
end)

describe("lurek.timer scheduler remaining coverage", function()
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
test_summary()
