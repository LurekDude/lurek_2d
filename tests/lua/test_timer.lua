-- Luna2D Timer API Tests

describe("luna.timer module exists", function()
    it("luna.timer is a table", function()
        expect_type("table", luna.timer)
    end)
end)

describe("luna.timer functions", function()
    it("getDelta is a function", function()
        expect_type("function", luna.timer.getDelta)
    end)

    it("getDelta returns a number", function()
        local dt = luna.timer.getDelta()
        expect_type("number", dt)
    end)

    it("getDelta returns non-negative", function()
        local dt = luna.timer.getDelta()
        expect_true(dt >= 0, "delta >= 0")
    end)

    it("getFPS is a function", function()
        expect_type("function", luna.timer.getFPS)
    end)

    it("getFPS returns a number", function()
        local fps = luna.timer.getFPS()
        expect_type("number", fps)
    end)

    it("getFPS returns non-negative", function()
        local fps = luna.timer.getFPS()
        expect_true(fps >= 0, "fps >= 0")
    end)

    it("getTime is a function", function()
        expect_type("function", luna.timer.getTime)
    end)

    it("getTime returns a number", function()
        local t = luna.timer.getTime()
        expect_type("number", t)
    end)

    it("getTime returns non-negative", function()
        local t = luna.timer.getTime()
        expect_true(t >= 0, "time >= 0")
    end)

    it("getAverageDelta is a function", function()
        expect_type("function", luna.timer.getAverageDelta)
    end)

    it("getAverageDelta returns a number", function()
        local avg = luna.timer.getAverageDelta()
        expect_type("number", avg)
    end)

    it("getAverageDelta returns non-negative", function()
        local avg = luna.timer.getAverageDelta()
        expect_true(avg >= 0, "average delta >= 0")
    end)

    it("getMicroTime is a function", function()
        expect_type("function", luna.timer.getMicroTime)
    end)

    it("getMicroTime returns a number", function()
        local t = luna.timer.getMicroTime()
        expect_type("number", t)
    end)

    it("getMicroTime returns non-negative", function()
        local t = luna.timer.getMicroTime()
        expect_true(t >= 0, "getMicroTime >= 0")
    end)

    it("getMicroTime is monotonically increasing", function()
        local t1 = luna.timer.getMicroTime()
        local t2 = luna.timer.getMicroTime()
        expect_true(t2 >= t1, "getMicroTime must not go backward")
    end)

    it("sleep is a function", function()
        expect_type("function", luna.timer.sleep)
    end)

    it("sleep with zero or negative does not error", function()
        luna.timer.sleep(0)
        luna.timer.sleep(-1)
        expect_true(true, "sleep with zero/negative is safe")
    end)

    it("step is a function", function()
        expect_type("function", luna.timer.step)
    end)

    it("step returns a number", function()
        local dt = luna.timer.step()
        expect_type("number", dt)
    end)

    it("step returns non-negative delta", function()
        local dt = luna.timer.step()
        expect_true(dt >= 0, "step() delta >= 0")
    end)

    it("step updates getDelta", function()
        local dt = luna.timer.step()
        local after = luna.timer.getDelta()
        -- After step(), getDelta() should return the same value step() returned
        expect_true(math.abs(after - dt) < 1e-9, "getDelta matches step() result")
    end)
end)

test_summary()
