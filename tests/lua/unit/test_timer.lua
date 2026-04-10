-- @covers lurek.time.getAverageDelta
-- @covers lurek.time.getDelta
-- @covers lurek.time.getFPS
-- @covers lurek.time.getMicroTime
-- @covers lurek.time.getPhysicsDelta
-- @covers lurek.time.getTime
-- @covers lurek.time.setPhysicsDelta
-- @covers lurek.time.sleep
-- @covers lurek.time.step

﻿-- Lurek2D Timer API Tests

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

test_summary()
