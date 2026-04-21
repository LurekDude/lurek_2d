-- Lurek2D timer API tests.
-- Covers frame-timing accessors, sleep/step helpers, scheduler behavior, and timing-state queries exposed through lurek.timer.

-- @description Verifies the timer namespace is exposed on lurek as a Lua table.
describe("lurek.timer module exists", function()
    -- @covers lurek.timer.getAverageDelta
    -- @covers lurek.timer.getDelta
    -- @covers lurek.timer.getFrameCount
    -- @covers lurek.timer.getFPS
    -- @covers lurek.timer.getMicroTime
    -- @covers lurek.timer.getPhysicsDelta
    -- @covers lurek.timer.getTime
    -- @covers lurek.timer.setPhysicsDelta
    -- @covers lurek.timer.sleep
    -- @covers lurek.timer.step
    -- @covers lurek.timer.newScheduler
    -- @description Asserts that lurek.timer has Lua type table.
    it("lurek.timer is a table", function()
        expect_type("table", lurek.timer)
    end)
end)

-- @description Validates the core timer accessors return functions, numeric values, and non-negative timing data.
describe("lurek.timer functions", function()
    -- @description Asserts that getDelta is present and callable as a function.
    it("getDelta is a function", function()
        expect_type("function", lurek.timer.getDelta)
    end)

    -- @description Calls getDelta and checks that the returned value has Lua type number.
    it("getDelta returns a number", function()
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
    end)

    -- @description Calls getDelta and asserts the reported delta is greater than or equal to zero.
    it("getDelta returns non-negative", function()
        local dt = lurek.timer.getDelta()
        expect_true(dt >= 0, "delta >= 0")
    end)

    -- @description Asserts that getFPS is present and callable as a function.
    it("getFPS is a function", function()
        expect_type("function", lurek.timer.getFPS)
    end)

    -- @description Calls getFPS and checks that the returned value has Lua type number.
    it("getFPS returns a number", function()
        local fps = lurek.timer.getFPS()
        expect_type("number", fps)
    end)

    -- @description Calls getFPS and asserts the reported frames per second value is not negative.
    it("getFPS returns non-negative", function()
        local fps = lurek.timer.getFPS()
        expect_true(fps >= 0, "fps >= 0")
    end)

    -- @description Asserts that getTime is present and callable as a function.
    it("getTime is a function", function()
        expect_type("function", lurek.timer.getTime)
    end)

    -- @description Calls getTime and checks that the returned time value has Lua type number.
    it("getTime returns a number", function()
        local t = lurek.timer.getTime()
        expect_type("number", t)
    end)

    -- @description Calls getTime and asserts the elapsed time value is greater than or equal to zero.
    it("getTime returns non-negative", function()
        local t = lurek.timer.getTime()
        expect_true(t >= 0, "time >= 0")
    end)

    -- @description Asserts that getAverageDelta is present and callable as a function.
    it("getAverageDelta is a function", function()
        expect_type("function", lurek.timer.getAverageDelta)
    end)

    -- @description Calls getAverageDelta and checks that the averaged delta has Lua type number.
    it("getAverageDelta returns a number", function()
        local avg = lurek.timer.getAverageDelta()
        expect_type("number", avg)
    end)

    -- @description Calls getAverageDelta and asserts the averaged delta is not negative.
    it("getAverageDelta returns non-negative", function()
        local avg = lurek.timer.getAverageDelta()
        expect_true(avg >= 0, "average delta >= 0")
    end)

    -- @description Asserts that getMicroTime is present and callable as a function.
    it("getMicroTime is a function", function()
        expect_type("function", lurek.timer.getMicroTime)
    end)

    -- @description Calls getMicroTime and checks that the returned microsecond timer value has Lua type number.
    it("getMicroTime returns a number", function()
        local t = lurek.timer.getMicroTime()
        expect_type("number", t)
    end)

    -- @description Calls getMicroTime and asserts the reported microsecond timer value is non-negative.
    it("getMicroTime returns non-negative", function()
        local t = lurek.timer.getMicroTime()
        expect_true(t >= 0, "getMicroTime >= 0")
    end)

    -- @description Samples getMicroTime twice and asserts the second reading never goes backward.
    it("getMicroTime is monotonically increasing", function()
        local t1 = lurek.timer.getMicroTime()
        local t2 = lurek.timer.getMicroTime()
        expect_true(t2 >= t1, "getMicroTime must not go backward")
    end)

    -- @description Asserts that sleep is present and callable as a function.
    it("sleep is a function", function()
        expect_type("function", lurek.timer.sleep)
    end)

    -- @description Calls sleep with zero and a negative duration and asserts both calls complete without error.
    it("sleep with zero or negative does not error", function()
        lurek.timer.sleep(0)
        lurek.timer.sleep(-1)
        expect_true(true, "sleep with zero/negative is safe")
    end)

    -- @description Asserts that step is present and callable as a function.
    it("step is a function", function()
        expect_type("function", lurek.timer.step)
    end)

    -- @description Calls step and checks that the returned frame delta has Lua type number.
    it("step returns a number", function()
        local dt = lurek.timer.step()
        expect_type("number", dt)
    end)

    -- @description Calls step and asserts the returned frame delta is greater than or equal to zero.
    it("step returns non-negative delta", function()
        local dt = lurek.timer.step()
        expect_true(dt >= 0, "step() delta >= 0")
    end)

    -- @description Calls step, then verifies getDelta returns the same value within a tiny absolute tolerance.
    it("step updates getDelta", function()
        local dt = lurek.timer.step()
        local after = lurek.timer.getDelta()
        -- After step(), getDelta() should return the same value step() returned
        expect_true(math.abs(after - dt) < 1e-9, "getDelta matches step() result")
    end)
end)

-- @description Validates the physics timestep API, including its default value, mutation, and min/max clamping.
describe("lurek.timer physics delta", function()
    -- @description Asserts that getPhysicsDelta is present and callable as a function.
    it("getPhysicsDelta is a function", function()
        expect_type("function", lurek.timer.getPhysicsDelta)
    end)

    -- @description Asserts that setPhysicsDelta is present and callable as a function.
    it("setPhysicsDelta is a function", function()
        expect_type("function", lurek.timer.setPhysicsDelta)
    end)

    -- @description Reads the physics delta and checks that the default value matches 1/60 within a tight tolerance.
    it("getPhysicsDelta returns default 1/60", function()
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-9)
    end)

    -- @description Sets the physics delta to 1/30, asserts the new value is reported back, then restores the original delta.
    it("setPhysicsDelta changes the value", function()
        local original = lurek.timer.getPhysicsDelta()
        lurek.timer.setPhysicsDelta(1.0 / 30.0)
        local after = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 30.0, after, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(original)
    end)

    -- @description Sets an excessively small physics delta and asserts it is clamped up to the 1/240 minimum before restoring 1/60.
    it("setPhysicsDelta clamps to minimum 1/240", function()
        lurek.timer.setPhysicsDelta(0.001) -- ~1000 Hz, too fast
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 240.0, dt, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
    end)

    -- @description Sets an excessively large physics delta and asserts it is clamped down to the 1/10 maximum before restoring 1/60.
    it("setPhysicsDelta clamps to maximum 1/10", function()
        lurek.timer.setPhysicsDelta(1.0) -- 1 Hz, too slow
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 10.0, dt, 1e-9)
        -- restore
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
    end)

    -- @description Restores the default physics delta and verifies it still reports a value near 1/60.
    it("default physics tick rate is consistent with 60 Hz", function()
        -- Restore to default first, then verify it is near 1/60.
        lurek.timer.setPhysicsDelta(1.0 / 60.0)
        local dt = lurek.timer.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-6)
    end)
end)

-- â”€â”€ Scheduler â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises scheduler creation, timer lifecycle operations, repeated callbacks, pause state, intervals, scaling, and named timers.
describe("lurek.timer.newScheduler", function()
    -- @description Creates a scheduler and asserts the constructor returns a non-nil userdata value.
    it("creates a scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_not_nil(sched)
    end)

    -- @description Creates a fresh scheduler and asserts getCount reports zero timers.
    it("getCount returns 0 for empty scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_equal(sched:getCount(), 0)
    end)

    -- @description Creates a fresh scheduler and asserts isEmpty returns true before any timers are added.
    it("isEmpty returns true for empty scheduler", function()
        local sched = lurek.timer.newScheduler()
        expect_true(sched:isEmpty())
    end)

    -- @description Schedules a one-shot callback, verifies it does not fire early after 0.3 seconds, then fires after the total elapsed time exceeds 0.5 seconds and removes itself.
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

    -- @description Schedules a repeating callback with a max count of three and asserts the callback count increments once per 0.5 second update.
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

    -- @description Adds a one-shot timer, cancels it by id, and asserts cancel succeeds and the scheduler count returns to zero.
    it("cancel removes a timer", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:after(1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancel(id)
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)

    -- @description Attempts to cancel a nonexistent timer id and asserts the call returns false.
    it("cancel returns false for unknown id", function()
        local sched = lurek.timer.newScheduler()
        local ok = sched:cancel(9999)
        expect_equal(ok, false)
    end)

    -- @description Adds three timers of mixed kinds, asserts the count is three, then cancels all timers and asserts the count is zero.
    it("cancelAll removes all timers", function()
        local sched = lurek.timer.newScheduler()
        sched:after(1.0, function() end)
        sched:after(2.0, function() end)
        sched:every(0.5, function() end)
        expect_equal(sched:getCount(), 3)
        sched:cancelAll()
        expect_equal(sched:getCount(), 0)
    end)

    -- @description Pauses a one-shot timer mid-countdown, verifies it does not fire during a long paused update, then resumes it and confirms it fires once the remaining time elapses.
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

    -- @description Creates a five-second timer and asserts getRemaining decreases from 5.0 to 4.0 after one second of scheduler update time.
    it("getRemaining tracks countdown", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:after(5.0, function() end)
        expect_near(sched:getRemaining(id), 5.0, 0.0001)
        sched:update(1.0)
        expect_near(sched:getRemaining(id), 4.0, 0.0001)
    end)

    -- @description Creates a repeating timer and asserts getInterval reports the configured 0.25 second interval.
    it("getInterval returns timer interval", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:every(0.25, function() end)
        expect_near(sched:getInterval(id), 0.25, 0.0001)
    end)

    -- @description Changes a repeating timer interval from 0.5 to 1.0 seconds and asserts getInterval reports the updated value.
    it("setInterval changes timer interval", function()
        local sched = lurek.timer.newScheduler()
        local id = sched:every(0.5, function() end)
        sched:setInterval(id, 1.0)
        expect_near(sched:getInterval(id), 1.0, 0.0001)
    end)

    -- @description Sets scheduler time scale to 2.0, verifies the reported scale, and asserts a 1.0 second timer fires after a 0.5 second update because scaled time reaches 1.0.
    it("setTimeScale affects update speed", function()
        local sched = lurek.timer.newScheduler()
        local fired = false
        sched:after(1.0, function() fired = true end)
        sched:setTimeScale(2.0)
        expect_near(sched:getTimeScale(), 2.0, 0.0001)
        sched:update(0.5) -- 0.5 * 2.0 = 1.0 elapsed
        expect_equal(fired, true)
    end)

    -- @description Creates a named one-shot timer, then asserts cancelNamed succeeds and removes the only scheduled timer.
    it("afterNamed creates named timer that cancelNamed can remove", function()
        local sched = lurek.timer.newScheduler()
        sched:afterNamed("mytimer", 1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancelNamed("mytimer")
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)
end)

-- @description Validates the frame counter accessor exists, returns a number, and reports a non-negative integer value.
describe("lurek.timer.getFrameCount", function()
    -- @description Asserts that getFrameCount is present and callable as a function.
    it("getFrameCount is a function", function()
        expect_type("function", lurek.timer.getFrameCount)
    end)

    -- @description Calls getFrameCount and checks that the returned frame count has Lua type number.
    it("getFrameCount returns a number", function()
        local count = lurek.timer.getFrameCount()
        expect_type("number", count)
    end)

    -- @description Calls getFrameCount and asserts the value is at least zero and exactly equal to its floored integer form.
    it("getFrameCount returns a non-negative integer", function()
        local count = lurek.timer.getFrameCount()
        expect_true(count >= 0, "frame count must be non-negative")
        expect_true(count == math.floor(count), "frame count must be an integer")
    end)
end)

-- @description Tests for new timer features: scheduler.pauseNamed/resumeNamed, chain(), tickRealTimers(), getSmoothedDelta.
describe("lurek.timer new scheduler features", function()
  -- @covers lurek.timer.newScheduler
  -- @description Creates a scheduler, schedules a named event, pauses it, advances time, confirms it did not fire, then resumes and confirms it fires.
  it("pauseNamed and resumeNamed block and allow events", function()
    local s = lurek.timer.newScheduler()
    local fired = false
    s:everyNamed(0.1, "mytimer", function() fired = true end)
    s:pauseNamed("mytimer")
    s:update(0.2)
    expect_equal(fired, false)
    s:resumeNamed("mytimer")
    s:update(0.1)
    expect_equal(fired, true)
  end)

  -- @covers lurek.timer.chain
  -- @description Creates a two-step chain; confirms second step fires after both delays have elapsed.
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
  -- @description Schedules a near-zero real-clock timer; confirms it fires after tickRealTimers() is called with sufficient elapsed time.
  it("afterReal fires via tickRealTimers", function()
    local fired = false
    lurek.timer.afterReal(0.0, function() fired = true end)
    lurek.timer.tickRealTimers()
    expect_equal(fired, true)
  end)

  -- @covers lurek.timer.setSmoothingFactor
  -- @covers lurek.timer.getSmoothedDelta
  -- @description Confirms getSmoothedDelta returns a positive number after calling it once.
  it("getSmoothedDelta returns a positive number", function()
    lurek.timer.setSmoothingFactor(0.5)
    local dt = lurek.timer.getSmoothedDelta()
    expect_true(type(dt) == "number" and dt >= 0, "smoothed delta must be non-negative")
  end)

  -- @covers lurek.timer.newScheduler
  -- @description Verifies isPausedNamed returns correct booleans.
  it("isPausedNamed reflects pause state", function()
    local s = lurek.timer.newScheduler()
    s:everyNamed(1.0, "ticker", function() end)
    expect_equal(s:isPausedNamed("ticker"), false)
    s:pauseNamed("ticker")
    expect_equal(s:isPausedNamed("ticker"), true)
    s:resumeNamed("ticker")
    expect_equal(s:isPausedNamed("ticker"), false)
  end)
end)

-- ── Coroutine wait support ───────────────────────────────────────────────────

-- @description Verifies coroutine wait/tick APIs: tickWaits is callable, waitFrames yields and resumes, waitSeconds completes after tick.
describe("lurek.timer coroutine wait support", function()
    -- @covers lurek.timer.tickWaits
    -- @description Calls tickWaits with no pending waits; expects no error.
    it("timer_tickWaits_is_callable", function()
        lurek.timer.tickWaits()
        expect_true(true, "tickWaits should not error when there are no pending waits")
    end)

    -- @covers lurek.timer.waitFrames
    -- @description Creates a coroutine that calls waitFrames(1); confirms it yields (status remains "suspended") after the first resume.
    it("timer_waitFrames_inside_coroutine_yields", function()
        local co = coroutine.create(function()
            lurek.timer.waitFrames(1)
        end)
        coroutine.resume(co)
        expect_equal(coroutine.status(co), "suspended",
            "coroutine should still be suspended after waitFrames(1)")
    end)

    -- @covers lurek.timer.waitFrames
    -- @covers lurek.timer.tickWaits
    -- @description Same setup as above; after one tickWaits() call the frame count reaches 1 so the coroutine is resumed to completion.
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

    -- @covers lurek.timer.waitSeconds
    -- @covers lurek.timer.tickWaits
    -- @description Creates a coroutine calling waitSeconds(0); after resume + tick it should reach completion because 0-second deadline is already expired.
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

-- @description Covers suite: lurek.timer physics max steps configurability.
describe("lurek.timer physicsMaxSteps configurability", function()
    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @description Verifies getPhysicsMaxSteps is exported as a callable function.
    it("getPhysicsMaxSteps is a function", function()
        expect_type("function", lurek.timer.getPhysicsMaxSteps)
    end)

    -- @covers lurek.timer.setPhysicsMaxSteps
    -- @description Verifies setPhysicsMaxSteps is exported as a callable function.
    it("setPhysicsMaxSteps is a function", function()
        expect_type("function", lurek.timer.setPhysicsMaxSteps)
    end)

    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @description Confirms the default physics max steps value is 8 on a fresh VM.
    it("getPhysicsMaxSteps_default_is_8", function()
        local steps = lurek.timer.getPhysicsMaxSteps()
        expect_equal(8, steps)
    end)

    -- @covers lurek.timer.setPhysicsMaxSteps
    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @description Sets a new physics max steps value and reads it back to verify round-trip fidelity.
    it("setPhysicsMaxSteps_roundtrips_value", function()
        lurek.timer.setPhysicsMaxSteps(16)
        expect_equal(16, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)

    -- @covers lurek.timer.setPhysicsMaxSteps
    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @description Passes 0 (below minimum); the engine must clamp the stored value to 1.
    it("setPhysicsMaxSteps_clamps_below_minimum_to_1", function()
        lurek.timer.setPhysicsMaxSteps(0)
        expect_equal(1, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)

    -- @covers lurek.timer.setPhysicsMaxSteps
    -- @covers lurek.timer.getPhysicsMaxSteps
    -- @description Passes 999 (above maximum); the engine must clamp the stored value to 64.
    it("setPhysicsMaxSteps_clamps_above_maximum_to_64", function()
        lurek.timer.setPhysicsMaxSteps(999)
        expect_equal(64, lurek.timer.getPhysicsMaxSteps())
        lurek.timer.setPhysicsMaxSteps(8) -- restore default
    end)
end)

-- ── afterFrames / everyFrames / updateFrames ──────────────────────────────────
-- @description Tests for frame-count based scheduler events: afterFrames, everyFrames, updateFrames.
describe("lurek.timer scheduler frame events", function()
  -- @covers lurek.timer.newScheduler
  -- @covers lurek.timer.Scheduler.afterFrames
  -- @covers lurek.timer.Scheduler.updateFrames
  -- @description afterFrames fires callback exactly after the given number of updateFrames calls.
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

  -- @covers lurek.timer.Scheduler.afterFrames
  -- @description afterFrames fires exactly once even after many more frames.
  it("afterFrames fires exactly once", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(1, function() fired = fired + 1 end)
    for _ = 1, 5 do s:updateFrames() end
    expect_equal(1, fired)
  end)

  -- @covers lurek.timer.Scheduler.everyFrames
  -- @covers lurek.timer.Scheduler.updateFrames
  -- @description everyFrames fires once every n frames over 6 frames.
  it("everyFrames fires every n frames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:everyFrames(2, function() fired = fired + 1 end)
    for _ = 1, 6 do s:updateFrames() end
    expect_equal(3, fired)
  end)

  -- @covers lurek.timer.Scheduler.everyFrames
  -- @description everyFrames with a count limit stops after that many firings.
  it("everyFrames respects count limit", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:everyFrames(1, function() fired = fired + 1 end, 3)
    for _ = 1, 10 do s:updateFrames() end
    expect_equal(3, fired)
  end)

  -- @covers lurek.timer.Scheduler.updateFrames
  -- @description updateFrames returns the number of callbacks that fired this call.
  it("updateFrames returns fired count", function()
    local s = lurek.timer.newScheduler()
    s:afterFrames(1, function() end)
    s:afterFrames(1, function() end)
    local count = s:updateFrames()
    expect_equal(2, count)
  end)

  -- @covers lurek.timer.Scheduler.afterFrames
  -- @description afterFrames with n=0 fires immediately on the first updateFrames.
  it("afterFrames(0) fires on first updateFrames", function()
    local s = lurek.timer.newScheduler()
    local fired = 0
    s:afterFrames(0, function() fired = fired + 1 end)
    s:updateFrames()
    expect_equal(1, fired)
  end)
end)

-- ── afterNamed replacement semantics ────────────────────────────────────────

-- @description Verifies that calling afterNamed twice with the same name replaces the first timer, leaving only one scheduled event.
describe("lurek.timer scheduler afterNamed replacement", function()
  -- @covers lurek.timer.Scheduler.afterNamed
  -- @description Schedules two afterNamed events with the same name; count must remain 1 (second replaces first).
  it("afterNamed with same name replaces the previous timer", function()
    local s = lurek.timer.newScheduler()
    s:afterNamed("step", 5.0, function() end)
    expect_equal(1, s:getCount())
    s:afterNamed("step", 5.0, function() end)
    expect_equal(1, s:getCount())
  end)

  -- @covers lurek.timer.Scheduler.afterNamed
  -- @description Only the replacement callback fires; the original must not execute.
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

  -- @covers lurek.timer.Scheduler.afterNamed
  -- @description Different names do NOT replace each other; count must equal the number of distinct names.
  it("afterNamed with different names does not replace", function()
    local s = lurek.timer.newScheduler()
    s:afterNamed("a", 1.0, function() end)
    s:afterNamed("b", 1.0, function() end)
    expect_equal(2, s:getCount())
  end)
end)

-- ── lurek.timer.delay ─────────────────────────────────────────────────────────

-- @description Verifies lurek.timer.delay is a coroutine-based wait alias backed by waitSeconds.
describe("lurek.timer.delay", function()
  -- @covers lurek.timer.delay
  -- @description delay is exported as a callable function.
  it("delay is a function", function()
    expect_type("function", lurek.timer.delay)
  end)

  -- @covers lurek.timer.delay
  -- @covers lurek.timer.tickWaits
  -- @description delay(0) inside a coroutine yields and resumes after one tickWaits.
  it("delay(0) yields and resumes after tickWaits", function()
    local co = coroutine.create(function()
      lurek.timer.delay(0)
    end)
    coroutine.resume(co)
    lurek.timer.tickWaits()
    expect_equal("dead", coroutine.status(co))
  end)
end)

test_summary()
