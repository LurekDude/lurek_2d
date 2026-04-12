-- @covers lurek.time.getAverageDelta
-- @covers lurek.time.getDelta
-- @covers lurek.time.getFPS
-- @covers lurek.time.getMicroTime
-- @covers lurek.time.getPhysicsDelta
-- @covers lurek.time.getTime
-- @covers lurek.time.setPhysicsDelta
-- @covers lurek.time.sleep
-- @covers lurek.time.step
-- @covers lurek.time.newScheduler

-- Lurek2D Timer API Tests

describe("lurek.time module exists", function()
    it("lurek.time is a table", function()
        expect_type("table", lurek.time)
    end)
end)

describe("lurek.time functions", function()
    it("getDelta is a function", function()
        expect_type("function", lurek.time.getDelta)
    end)

    it("getDelta returns a number", function()
        local dt = lurek.time.getDelta()
        expect_type("number", dt)
    end)

    it("getDelta returns non-negative", function()
        local dt = lurek.time.getDelta()
        expect_true(dt >= 0, "delta >= 0")
    end)

    it("getFPS is a function", function()
        expect_type("function", lurek.time.getFPS)
    end)

    it("getFPS returns a number", function()
        local fps = lurek.time.getFPS()
        expect_type("number", fps)
    end)

    it("getFPS returns non-negative", function()
        local fps = lurek.time.getFPS()
        expect_true(fps >= 0, "fps >= 0")
    end)

    it("getTime is a function", function()
        expect_type("function", lurek.time.getTime)
    end)

    it("getTime returns a number", function()
        local t = lurek.time.getTime()
        expect_type("number", t)
    end)

    it("getTime returns non-negative", function()
        local t = lurek.time.getTime()
        expect_true(t >= 0, "time >= 0")
    end)

    it("getAverageDelta is a function", function()
        expect_type("function", lurek.time.getAverageDelta)
    end)

    it("getAverageDelta returns a number", function()
        local avg = lurek.time.getAverageDelta()
        expect_type("number", avg)
    end)

    it("getAverageDelta returns non-negative", function()
        local avg = lurek.time.getAverageDelta()
        expect_true(avg >= 0, "average delta >= 0")
    end)

    it("getMicroTime is a function", function()
        expect_type("function", lurek.time.getMicroTime)
    end)

    it("getMicroTime returns a number", function()
        local t = lurek.time.getMicroTime()
        expect_type("number", t)
    end)

    it("getMicroTime returns non-negative", function()
        local t = lurek.time.getMicroTime()
        expect_true(t >= 0, "getMicroTime >= 0")
    end)

    it("getMicroTime is monotonically increasing", function()
        local t1 = lurek.time.getMicroTime()
        local t2 = lurek.time.getMicroTime()
        expect_true(t2 >= t1, "getMicroTime must not go backward")
    end)

    it("sleep is a function", function()
        expect_type("function", lurek.time.sleep)
    end)

    it("sleep with zero or negative does not error", function()
        lurek.time.sleep(0)
        lurek.time.sleep(-1)
        expect_true(true, "sleep with zero/negative is safe")
    end)

    it("step is a function", function()
        expect_type("function", lurek.time.step)
    end)

    it("step returns a number", function()
        local dt = lurek.time.step()
        expect_type("number", dt)
    end)

    it("step returns non-negative delta", function()
        local dt = lurek.time.step()
        expect_true(dt >= 0, "step() delta >= 0")
    end)

    it("step updates getDelta", function()
        local dt = lurek.time.step()
        local after = lurek.time.getDelta()
        -- After step(), getDelta() should return the same value step() returned
        expect_true(math.abs(after - dt) < 1e-9, "getDelta matches step() result")
    end)
end)

describe("lurek.time physics delta", function()
    it("getPhysicsDelta is a function", function()
        expect_type("function", lurek.time.getPhysicsDelta)
    end)

    it("setPhysicsDelta is a function", function()
        expect_type("function", lurek.time.setPhysicsDelta)
    end)

    it("getPhysicsDelta returns default 1/60", function()
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-9)
    end)

    it("setPhysicsDelta changes the value", function()
        local original = lurek.time.getPhysicsDelta()
        lurek.time.setPhysicsDelta(1.0 / 30.0)
        local after = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 30.0, after, 1e-9)
        -- restore
        lurek.time.setPhysicsDelta(original)
    end)

    it("setPhysicsDelta clamps to minimum 1/240", function()
        lurek.time.setPhysicsDelta(0.001) -- ~1000 Hz, too fast
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 240.0, dt, 1e-9)
        -- restore
        lurek.time.setPhysicsDelta(1.0 / 60.0)
    end)

    it("setPhysicsDelta clamps to maximum 1/10", function()
        lurek.time.setPhysicsDelta(1.0) -- 1 Hz, too slow
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 10.0, dt, 1e-9)
        -- restore
        lurek.time.setPhysicsDelta(1.0 / 60.0)
    end)

    it("default physics tick rate is consistent with 60 Hz", function()
        -- Restore to default first, then verify it is near 1/60.
        lurek.time.setPhysicsDelta(1.0 / 60.0)
        local dt = lurek.time.getPhysicsDelta()
        expect_near(1.0 / 60.0, dt, 1e-6)
    end)
end)

-- ── Scheduler ────────────────────────────────────────────────────────────────

describe("lurek.time.newScheduler", function()
    it("creates a scheduler", function()
        local sched = lurek.time.newScheduler()
        expect_not_nil(sched)
    end)

    it("getCount returns 0 for empty scheduler", function()
        local sched = lurek.time.newScheduler()
        expect_equal(sched:getCount(), 0)
    end)

    it("isEmpty returns true for empty scheduler", function()
        local sched = lurek.time.newScheduler()
        expect_true(sched:isEmpty())
    end)

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

    it("cancel removes a timer", function()
        local sched = lurek.time.newScheduler()
        local id = sched:after(1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancel(id)
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)

    it("cancel returns false for unknown id", function()
        local sched = lurek.time.newScheduler()
        local ok = sched:cancel(9999)
        expect_equal(ok, false)
    end)

    it("cancelAll removes all timers", function()
        local sched = lurek.time.newScheduler()
        sched:after(1.0, function() end)
        sched:after(2.0, function() end)
        sched:every(0.5, function() end)
        expect_equal(sched:getCount(), 3)
        sched:cancelAll()
        expect_equal(sched:getCount(), 0)
    end)

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

    it("getRemaining tracks countdown", function()
        local sched = lurek.time.newScheduler()
        local id = sched:after(5.0, function() end)
        expect_near(sched:getRemaining(id), 5.0, 0.0001)
        sched:update(1.0)
        expect_near(sched:getRemaining(id), 4.0, 0.0001)
    end)

    it("getInterval returns timer interval", function()
        local sched = lurek.time.newScheduler()
        local id = sched:every(0.25, function() end)
        expect_near(sched:getInterval(id), 0.25, 0.0001)
    end)

    it("setInterval changes timer interval", function()
        local sched = lurek.time.newScheduler()
        local id = sched:every(0.5, function() end)
        sched:setInterval(id, 1.0)
        expect_near(sched:getInterval(id), 1.0, 0.0001)
    end)

    it("setTimeScale affects update speed", function()
        local sched = lurek.time.newScheduler()
        local fired = false
        sched:after(1.0, function() fired = true end)
        sched:setTimeScale(2.0)
        expect_near(sched:getTimeScale(), 2.0, 0.0001)
        sched:update(0.5) -- 0.5 * 2.0 = 1.0 elapsed
        expect_equal(fired, true)
    end)

    it("afterNamed creates named timer that cancelNamed can remove", function()
        local sched = lurek.time.newScheduler()
        sched:afterNamed("mytimer", 1.0, function() end)
        expect_equal(sched:getCount(), 1)
        local ok = sched:cancelNamed("mytimer")
        expect_true(ok)
        expect_equal(sched:getCount(), 0)
    end)
end)

test_summary()
