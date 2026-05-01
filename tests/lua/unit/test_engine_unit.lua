-- Lurek2D engine API Tests

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("lurek.engine API surface", function()
    -- @covers lurek.engine.fps
    it("fps returns a non-negative number", function()
        local v = lurek.engine.fps()
        expect_type("number", v)
        expect_true(v >= 0, "fps must be non-negative")
    end)

    -- @covers lurek.engine.setResourceBudget
    it("setResourceBudget accepts a byte limit without error", function()
        expect_no_error(function()
            lurek.engine.setResourceBudget(256 * 1024 * 1024)
        end)
        expect_no_error(function()
            lurek.engine.setResourceBudget(0)
        end)
    end)

    -- @covers lurek.engine.getResourceStats
    it("getResourceStats returns a table with required fields", function()
        local stats = lurek.engine.getResourceStats()
        expect_type("table", stats)
        expect_type("number", stats.texture_bytes)
        expect_type("number", stats.budget_bytes)
        expect_type("number", stats.texture_count)
    end)

end)

describe("lurek.engine.getVersion", function()
    -- @covers lurek.engine.getVersion
    it("getVersion returns a non-empty string", function()
        local v = lurek.engine.getVersion()
        expect_type("string", v)
        expect_true(#v > 0, "version string must be non-empty")
    end)
end)

describe("lurek.engine.getFrameBudget", function()
    -- @covers lurek.engine.getFrameBudget
    it("getFrameBudget returns a positive number", function()
        local v = lurek.engine.getFrameBudget()
        expect_type("number", v)
        expect_true(v > 0, "frame budget must be positive")
    end)
end)

describe("lurek.engine.memoryUsage", function()
    -- @covers lurek.engine.memoryUsage
    it("memoryUsage returns a table with lua_bytes and lua_kb", function()
        local v = lurek.engine.memoryUsage()
        expect_type("table", v)
        expect_type("number", v.lua_bytes)
        expect_type("number", v.lua_kb)
        expect_true(v.lua_bytes >= 0, "lua_bytes must be non-negative")
    end)
end)

describe("lurek.engine.platform", function()
    -- @covers lurek.engine.platform
    it("platform returns a non-empty string", function()
        local v = lurek.engine.platform()
        expect_type("string", v)
        expect_true(#v > 0, "platform string must be non-empty")
    end)
end)

describe("lurek.engine.uptime", function()
    -- @covers lurek.engine.uptime
    it("uptime returns a non-negative number", function()
        local v = lurek.engine.uptime()
        expect_type("number", v)
        expect_true(v >= 0, "uptime must be non-negative")
    end)
end)

describe("lurek.engine.frameCount", function()
    -- @covers lurek.engine.frameCount
    it("frameCount returns a non-negative integer", function()
        local v = lurek.engine.frameCount()
        expect_type("number", v)
        expect_true(v >= 0, "frame count must be non-negative")
        expect_true(v == math.floor(v), "frame count must be an integer")
    end)
end)

describe("lurek.engine.isDebug", function()
    -- @covers lurek.engine.isDebug
    it("isDebug returns a boolean", function()
        local v = lurek.engine.isDebug()
        expect_type("boolean", v)
    end)
end)

test_summary()
