-- Lurek2D lurek.log API Tests

describe("lurek.log namespace", function()
    it("lurek.log is a table", function()
        expect_equal("table", type(lurek.log))
    end)

    it("lurek.log.info is a function", function()
        expect_equal("function", type(lurek.log.info))
    end)

    it("lurek.log.warn is a function", function()
        expect_equal("function", type(lurek.log.warn))
    end)

    it("lurek.log.error is a function", function()
        expect_equal("function", type(lurek.log.error))
    end)

    it("lurek.log.debug is a function", function()
        expect_equal("function", type(lurek.log.debug))
    end)

    it("lurek.log.print is a function", function()
        expect_equal("function", type(lurek.log.print))
    end)
end)

describe("lurek.log level functions", function()
    it("info does not error", function()
        lurek.log.info("test message")
    end)

    it("warn does not error", function()
        lurek.log.warn("test warning")
    end)

    it("error does not error", function()
        lurek.log.error("test error")
    end)

    it("debug does not error", function()
        lurek.log.debug("test debug")
    end)

    it("print with known level does not error", function()
        lurek.log.print("info", "printed msg")
    end)

    it("print with unknown level does not crash", function()
        lurek.log.print("unknown_level", "msg")
    end)
end)

describe("lurek.log.setLevel / getLevel", function()
    it("setLevel and getLevel round-trip", function()
        lurek.log.setLevel("warn")
        local level = lurek.log.getLevel()
        expect_equal("warn", level)
        lurek.log.setLevel("debug")
    end)

    it("getLevel returns a non-empty string", function()
        local level = lurek.log.getLevel()
        expect_equal("string", type(level))
        expect_true(#level > 0, "getLevel should return a non-empty string")
    end)
end)

test_summary()
