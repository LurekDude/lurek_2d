-- Lurek2D timer API tests.
-- Covers frame-timing accessors, sleep/step helpers, scheduler behavior, and timing-state queries exposed through lurek.time.

-- @description Verifies the timer namespace is exposed on lurek as a Lua table.
describe("lurek.time module exists", function()
    -- @covers lurek.time.getAverageDelta
    -- @covers lurek.time.getDelta
    -- @covers lurek.time.getFrameCount
    -- @covers lurek.time.getFPS
    -- @covers lurek.time.getMicroTime
    -- @covers lurek.time.getPhysicsDelta
    -- @covers lurek.time.getTime
    -- @covers lurek.time.setPhysicsDelta
    -- @covers lurek.time.sleep
    -- @covers lurek.time.step
    -- @covers lurek.time.newScheduler
    -- @description Asserts that lurek.time has Lua type table.
    it("lurek.time is a table", function()
        expect_type("table", lurek.time)
    end)
end)

-- @description Validates the core timer accessors return functions, numeric values, and non-negative timing data.
describe("lurek.time functions", function()
    -- @description Asserts that getDelta is present and callable as a function.
    it("getDelta is a function", function()
        expect_type("function", lurek.time.getDelta)
    end)

    -- @description Calls getDelta and checks that the returned value has Lua type number.
    it("getDelta returns a number", function()
        local dt = lurek.time.getDelta()
        expect_type("number", dt)
    end)

    -- @description Calls getDelta and asserts the reported delta is greater than or equal to zero.
    it("getDelta returns non-negative", function()
        local dt = lurek.time.getDelta()
        expect_true(dt >= 0, "delta >= 0")
    end)

    -- @description Asserts that getFPS is present and callable as a function.
    it("getFPS is a function", function()
        expect_type("function", lurek.time.getFPS)
    end)

    -- @description Calls getFPS and checks that the returned value has Lua type number.
    it("getFPS returns a number", function()
        local fps = lurek.time.getFPS()
        expect_type("number", fps)
    end)

    -- @description Calls getFPS and asserts the reported frames per second value is not negative.
    it("getFPS returns non-negative", function()
        local fps = lurek.time.getFPS()
        expect_true(fps >= 0, "fps >= 0")
    end)

    -- @description Asserts that getTime is present and callable as a function.
    it("getTime is a function", function()
        expect_type("function", lurek.time.getTime)
    end)

    -- @description Calls getTime and checks that the returned time value has Lua type number.
    it("getTime returns a number", function()
        local t = lurek.time.getTime()
        expect_type("number", t)
    end)

    -- @description Calls getTime and asserts the elapsed time value is greater than or equal to zero.
    it("getTime returns non-negative", function()
        local t = lurek.time.getTime()
        expect_true(t >= 0, "time >= 0")
    end)

    -- @description Asserts that getAverageDelta is present and callable as a function.
    it("getAverageDelta is a function", function()
        expect_type("function", lurek.time.getAverageDelta)
    end)

    -- @description Calls getAverageDelta and checks that the averaged delta has Lua type number.
    it("getAverageDelta returns a number", function()
        local avg = lurek.time.getAverageDelta()
        expect_type("number", avg)
    end)

    -- @description Calls getAverageDelta and asserts the averaged delta is not negative.
    it("getAverageDelta returns non-negative", function()
        local avg = lurek.time.getAverageDelta()
        expect_true(avg >= 0, "average delta >= 0")
    end)

    -- @description Asserts that getMicroTime is present and callable as a function.
    it("getMicroTime is a function", function()
        expect_type("function", lurek.time.getMicroTime)
    end)

    -- @description Calls getMicroTime and checks that the returned microsecond timer value has Lua type number.
    it("getMicroTime returns a number", function()
        local t = lurek.time.getMicroTime()
        expect_type("number", t)
    end)

    -- @description Calls getMicroTime and asserts the reported microsecond timer value is non-negative.
    it("getMicroTime returns non-negative", function()
        local t = lurek.time.getMicroTime()
        expect_true(t >= 0, "getMicroTime >= 0")
    end)

    -- @description Samples getMicroTime twice and asserts the second reading never goes backward.
    it("getMicroTime is monotonically increasing", function()
        local t1 = lurek.time.getMicroTime()
        local t2 = lurek.time.getMicroTime()
        expect_true(t2 >= t1, "getMicroTime must not go backward")
    end)

    -- @description Asserts that sleep is present and callable as a function.
    it("sleep is a function", function()
        expect_type("function", lurek.time.sleep)
    end)

    -- @description Calls sleep with zero and a negative duration and asserts both calls complete without error.
    it("sleep with zero or negative does not error", function()
        lurek.time.sleep(0)
        lurek.time.sleep(-1)
        expect_true(true, "sleep with zero/negative is safe")
    end)

    -- @description Asserts that step is present and callable as a function.
    it("step is a function", function()
        expect_type("function", lurek.time.step)
    end)

    -- @description Calls step and checks that the returned frame delta has Lua type number.
    it("step returns a number", function()
        local dt = lurek.time.step()
        expect_type("number", dt)
    end)

    -- @description Calls step and asserts the returned frame delta is greater than or equal to zero.
    it("step returns non-negative delta", function()
        local dt = lurek.time.step()
        expect_true(dt >= 0, "step() delta >= 0")
    end)

    -- @description Calls step, then verifies getDelta returns the same value within a tiny absolute tolerance.
    it("step updates getDelta", function()
        local dt = lurek.time.step()
        local after = lurek.time.getDelta()
        -- After step(), getDelta() should return the same value step() returned
        expect_true(math.abs(after - dt) < 1e-9, "getDelta matches step() result")
    end)
end)

-- @description Validates the physics timestep API, including its default value, mutation, and min/max clamping.
describe("lurek.time physics delta", function()
    -- @description Asserts that getPhysicsDelta is present and callable as a function.
    it("getPhysicsDelta is a function", function()
        expect_type("function", lurek.time.getPhysicsDelta)
    end)

    -- @description Asserts that setPhysicsDelta is present and callable as a function.
    it("setPhysicsDelta is a function", function()
        expect_type("function", lurek.time.setPhysicsDelta)
    end)

    -- @description Reads the physics delta and checks that the default value matches 1/60 within a tight tolerance.
    it("getPhysicsDelta returns default 1/60", function()
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-9)
    end)

    -- @description Sets the physics delta to 1/30, asserts the new value is reported back, then restores the original delta.
    it("setPhysicsDelta changes the value", function()
        local original = lurek.time.getPhysicsDelta()
        lurek.time.setPhysicsDelta(1.0 / 30.0)
        local after = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 30.0, after, 1e-9)
        -- restore
        lurek.time.setPhysicsDelta(original)
    end)

    -- @description Sets an excessively small physics delta and asserts it is clamped up to the 1/240 minimum before restoring 1/60.
    it("setPhysicsDelta clamps to minimum 1/240", function()
        lurek.time.setPhysicsDelta(0.001) -- ~1000 Hz, too fast
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 240.0, dt, 1e-9)
        -- restore
        lurek.time.setPhysicsDelta(1.0 / 60.0)
    end)

    -- @description Sets an excessively large physics delta and asserts it is clamped down to the 1/10 maximum before restoring 1/60.
    it("setPhysicsDelta clamps to maximum 1/10", function()
        lurek.time.setPhysicsDelta(1.0) -- 1 Hz, too slow
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 10.0, dt, 1e-9)
        -- restore
        lurek.time.setPhysicsDelta(1.0 / 60.0)
    end)

    -- @description Restores the default physics delta and verifies it still reports a value near 1/60.
    it("default physics tick rate is consistent with 60 Hz", function()
        -- Restore to default first, then verify it is near 1/60.
        lurek.time.setPhysicsDelta(1.0 / 60.0)
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-6)
    end)
end)

-- â”€â”€ Scheduler â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises scheduler creation, timer lifecycle operations, repeated callbacks, pause state, intervals, scaling, and named timers.
describe("lurek.time.newScheduler", function()
    -- @description Creates a scheduler and asserts the constructor returns a non-nil userdata value.
    it("creates a scheduler", function()
        local sched = lurek.time.newScheduler()
        expect_not_nil(sched)
    end)

    -- @description Creates a fresh scheduler and asserts getCount reports zero timers.
    it("getCount returns 0 for empty scheduler", function()
        local sched = lurek.time.newScheduler()
        expect_equal(sched:getCount(), 0)
    end)

    -- @description Creates a fresh scheduler and asserts isEmpty returns true before any timers are added.
    it("isEmpty returns true for empty scheduler", function()
        local sched = lurek.time.newScheduler()
        expect_true(sched:isEmpty())
    end)

    -- @description Schedules a one-shot callback, verifies it does not fire early after 0.3 seconds, then fires after the total elapsed time exceeds 0.5 seconds and removes itself.
    it("after creates a one-shot timer", function()
        local sched = lurek.time.newScheduler()
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
        local sched = lurek.time.newScheduler()
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
        local sched = lurek.time.newScheduler()
        local id = sched:after(1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancel(id)
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)

    -- @description Attempts to cancel a nonexistent timer id and asserts the call returns false.
    it("cancel returns false for unknown id", function()
        local sched = lurek.time.newScheduler()
        local ok = sched:cancel(9999)
        expect_equal(ok, false)
    end)

    -- @description Adds three timers of mixed kinds, asserts the count is three, then cancels all timers and asserts the count is zero.
    it("cancelAll removes all timers", function()
        local sched = lurek.time.newScheduler()
        sched:after(1.0, function() end)
        sched:after(2.0, function() end)
        sched:every(0.5, function() end)
        expect_equal(sched:getCount(), 3)
        sched:cancelAll()
        expect_equal(sched:getCount(), 0)
    end)

    -- @description Pauses a one-shot timer mid-countdown, verifies it does not fire during a long paused update, then resumes it and confirms it fires once the remaining time elapses.
    it("pause and resume stops and restarts a timer", function()
        local sched = lurek.time.newScheduler()
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
        local sched = lurek.time.newScheduler()
        local id = sched:after(5.0, function() end)
        expect_near(sched:getRemaining(id), 5.0, 0.0001)
        sched:update(1.0)
        expect_near(sched:getRemaining(id), 4.0, 0.0001)
    end)

    -- @description Creates a repeating timer and asserts getInterval reports the configured 0.25 second interval.
    it("getInterval returns timer interval", function()
        local sched = lurek.time.newScheduler()
        local id = sched:every(0.25, function() end)
        expect_near(sched:getInterval(id), 0.25, 0.0001)
    end)

    -- @description Changes a repeating timer interval from 0.5 to 1.0 seconds and asserts getInterval reports the updated value.
    it("setInterval changes timer interval", function()
        local sched = lurek.time.newScheduler()
        local id = sched:every(0.5, function() end)
        sched:setInterval(id, 1.0)
        expect_near(sched:getInterval(id), 1.0, 0.0001)
    end)

    -- @description Sets scheduler time scale to 2.0, verifies the reported scale, and asserts a 1.0 second timer fires after a 0.5 second update because scaled time reaches 1.0.
    it("setTimeScale affects update speed", function()
        local sched = lurek.time.newScheduler()
        local fired = false
        sched:after(1.0, function() fired = true end)
        sched:setTimeScale(2.0)
        expect_near(sched:getTimeScale(), 2.0, 0.0001)
        sched:update(0.5) -- 0.5 * 2.0 = 1.0 elapsed
        expect_equal(fired, true)
    end)

    -- @description Creates a named one-shot timer, then asserts cancelNamed succeeds and removes the only scheduled timer.
    it("afterNamed creates named timer that cancelNamed can remove", function()
        local sched = lurek.time.newScheduler()
        sched:afterNamed("mytimer", 1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancelNamed("mytimer")
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)
end)

-- @description Validates the frame counter accessor exists, returns a number, and reports a non-negative integer value.
describe("lurek.time.getFrameCount", function()
    -- @description Asserts that getFrameCount is present and callable as a function.
    it("getFrameCount is a function", function()
        expect_type("function", lurek.time.getFrameCount)
    end)

    -- @description Calls getFrameCount and checks that the returned frame count has Lua type number.
    it("getFrameCount returns a number", function()
        local count = lurek.time.getFrameCount()
        expect_type("number", count)
    end)

    -- @description Calls getFrameCount and asserts the value is at least zero and exactly equal to its floored integer form.
    it("getFrameCount returns a non-negative integer", function()
        local count = lurek.time.getFrameCount()
        expect_true(count >= 0, "frame count must be non-negative")
        expect_true(count == math.floor(count), "frame count must be an integer")
    end)
end)

-- @description Tests for new timer features: scheduler.pauseNamed/resumeNamed, chain(), tickRealTimers(), getSmoothedDelta.
describe("lurek.time new scheduler features", function()
  -- @covers lurek.time.newScheduler
  -- @description Creates a scheduler, schedules a named event, pauses it, advances time, confirms it did not fire, then resumes and confirms it fires.
  it("pauseNamed and resumeNamed block and allow events", function()
    local s = lurek.time.newScheduler()
    local fired = false
    s:everyNamed(0.1, "mytimer", function() fired = true end)
    s:pauseNamed("mytimer")
    s:update(0.2)
    expect_equal(fired, false)
    s:resumeNamed("mytimer")
    s:update(0.1)
    expect_equal(fired, true)
  end)

  -- @covers lurek.time.chain
  -- @description Creates a two-step chain; confirms second step fires after both delays have elapsed.
  it("chain fires steps in sequence", function()
    local results = {}
    local chain_sched = lurek.time.chain({
      { delay = 0.1, func = function() table.insert(results, 1) end },
      { delay = 0.2, func = function() table.insert(results, 2) end },
    })
    chain_sched:update(0.15)
    expect_equal(#results, 1)
    chain_sched:update(0.2)
    expect_equal(#results, 2)
  end)

  -- @covers lurek.time.afterReal
  -- @covers lurek.time.tickRealTimers
  -- @description Schedules a near-zero real-clock timer; confirms it fires after tickRealTimers() is called with sufficient elapsed time.
  it("afterReal fires via tickRealTimers", function()
    local fired = false
    lurek.time.afterReal(0.0, function() fired = true end)
    lurek.time.tickRealTimers()
    expect_equal(fired, true)
  end)

  -- @covers lurek.time.setSmoothingFactor
  -- @covers lurek.time.getSmoothedDelta
  -- @description Confirms getSmoothedDelta returns a positive number after calling it once.
  it("getSmoothedDelta returns a positive number", function()
    lurek.time.setSmoothingFactor(0.5)
    local dt = lurek.time.getSmoothedDelta()
    expect_true(type(dt) == "number" and dt >= 0, "smoothed delta must be non-negative")
  end)

  -- @covers lurek.time.newScheduler
  -- @description Verifies isPausedNamed returns correct booleans.
  it("isPausedNamed reflects pause state", function()
    local s = lurek.time.newScheduler()
    s:everyNamed(1.0, "ticker", function() end)
    expect_equal(s:isPausedNamed("ticker"), false)
    s:pauseNamed("ticker")
    expect_equal(s:isPausedNamed("ticker"), true)
    s:resumeNamed("ticker")
    expect_equal(s:isPausedNamed("ticker"), false)
  end)
end)

test_summary()
