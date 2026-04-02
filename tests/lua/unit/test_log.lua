-- Luna2D luna.log API Tests

describe("luna.log namespace", function()
    it("luna.log is a table", function()
        expect_equal("table", type(luna.log))
    end)

    it("luna.log.info is a function", function()
        expect_equal("function", type(luna.log.info))
    end)

    it("luna.log.warn is a function", function()
        expect_equal("function", type(luna.log.warn))
    end)

    it("luna.log.error is a function", function()
        expect_equal("function", type(luna.log.error))
    end)

    it("luna.log.debug is a function", function()
        expect_equal("function", type(luna.log.debug))
    end)

    it("luna.log.print is a function", function()
        expect_equal("function", type(luna.log.print))
    end)
end)

describe("luna.log level functions", function()
    it("info does not error", function()
        luna.log.info("test message")
    end)

    it("warn does not error", function()
        luna.log.warn("test warning")
    end)

    it("error does not error", function()
        luna.log.error("test error")
    end)

    it("debug does not error", function()
        luna.log.debug("test debug")
    end)

    it("print with known level does not error", function()
        luna.log.print("info", "printed msg")
    end)

    it("print with unknown level does not crash", function()
        luna.log.print("unknown_level", "msg")
    end)
end)

describe("luna.log.setLevel / getLevel", function()
    it("setLevel and getLevel round-trip", function()
        luna.log.setLevel("warn")
        local level = luna.log.getLevel()
        expect_equal("warn", level)
        luna.log.setLevel("debug")
    end)

    it("getLevel returns a non-empty string", function()
        local level = luna.log.getLevel()
        expect_equal("string", type(level))
        expect_true(#level > 0, "getLevel should return a non-empty string")
    end)
end)

test_summary()
