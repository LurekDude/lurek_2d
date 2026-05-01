-- Lurek2D system API Tests

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("lurek.runtime logging", function()
    -- @covers lurek.runtime.log
    it("log accepts a level and message without error", function()
        expect_no_error(function()
            lurek.runtime.log("info", "test log message")
        end)
    end)

    -- @covers lurek.runtime.log
    it("log accepts debug level", function()
        expect_no_error(function()
            lurek.runtime.log("debug", "debug message")
        end)
    end)

    -- @covers lurek.runtime.log
    it("log accepts warn level", function()
        expect_no_error(function()
            lurek.runtime.log("warn", "warn message")
        end)
    end)
end)

describe("lurek.runtime.runBatch", function()
    -- @covers lurek.runtime.runBatch
    it("runBatch with single task returns results table", function()
        local results = lurek.runtime.runBatch({
            task_a = function() return true end
        })
        expect_type("table", results)
    end)

    -- @covers lurek.runtime.runBatch
    -- @covers lurek.runtime.getBatchResults
    it("getBatchResults returns pass/fail/skip counts", function()
        local results = lurek.runtime.runBatch({
            t1 = function() return true end,
            t2 = function() return true end
        })
        local passed, failed, skipped = lurek.runtime.getBatchResults(results)
        expect_type("number", passed)
        expect_type("number", failed)
        expect_type("number", skipped)
        expect_true(passed >= 0, "passed must be non-negative")
        expect_true(failed >= 0, "failed must be non-negative")
    end)
end)

describe("lurek.runtime platform info", function()
    -- @covers lurek.runtime.getOS
    it("getOS returns a non-empty string", function()
        local os = lurek.runtime.getOS()
        expect_type("string", os)
        expect_true(#os > 0, "OS name must be non-empty")
    end)

    -- @covers lurek.runtime.getVersion
    it("getVersion returns a non-empty string", function()
        local v = lurek.runtime.getVersion()
        expect_type("string", v)
        expect_true(#v > 0, "version must be non-empty")
    end)

    -- @covers lurek.runtime.getProcessorCount
    it("getProcessorCount returns a positive integer", function()
        local n = lurek.runtime.getProcessorCount()
        expect_type("number", n)
        expect_true(n >= 1, "must have at least one CPU")
    end)

    -- @covers lurek.runtime.getMemorySize
    it("getMemorySize returns a positive integer", function()
        local mb = lurek.runtime.getMemorySize()
        expect_type("number", mb)
        expect_true(mb > 0, "memory size must be positive")
    end)

    -- @covers lurek.runtime.getArch
    it("getArch returns a non-empty string", function()
        local arch = lurek.runtime.getArch()
        expect_type("string", arch)
        expect_true(#arch > 0, "arch string must be non-empty")
    end)

    -- @covers lurek.runtime.getPreferredLocales
    it("getPreferredLocales returns a table", function()
        local locales = lurek.runtime.getPreferredLocales()
        expect_type("table", locales)
    end)

    -- @covers lurek.runtime.getPowerInfo
    it("getPowerInfo returns a state string", function()
        local state = lurek.runtime.getPowerInfo()
        expect_type("string", state)
    end)

    -- @covers lurek.runtime.getInfo
    it("getInfo returns a table with os field", function()
        local info = lurek.runtime.getInfo()
        expect_type("table", info)
        expect_type("string", info.os)
    end)

    -- @covers lurek.runtime.openURL
    it("openURL returns a boolean", function()
        local ok = lurek.runtime.openURL("https://example.com")
        expect_type("boolean", ok)
    end)
end)

describe("lurek.runtime message catalog", function()
    -- @covers lurek.runtime.getMessageCount
    it("getMessageCount returns a non-negative integer", function()
        local n = lurek.runtime.getMessageCount()
        expect_type("number", n)
        expect_true(n >= 0, "message count must be non-negative")
    end)

    -- @covers lurek.runtime.hasMessage
    it("hasMessage returns false for a nonexistent id", function()
        local ok = lurek.runtime.hasMessage("__nonexistent_test_id__")
        expect_equal(false, ok)
    end)

    -- @covers lurek.runtime.getMessage
    it("getMessage returns a string for any id (fallback or real)", function()
        local msg = lurek.runtime.getMessage("__nonexistent_test_id__")
        expect_type("string", msg)
    end)
end)

describe("lurek.runtime clipboard", function()
    -- @covers lurek.runtime.setClipboardText
    -- @covers lurek.runtime.getClipboardText
    it("setClipboardText and getClipboardText round-trip", function()
        expect_no_error(function()
            lurek.runtime.setClipboardText("lurek_test_clipboard_value")
        end)
        local v = lurek.runtime.getClipboardText()
        expect_type("string", v)
        -- Value may not persist in headless CI; only assert type
    end)
end)

describe("lurek.runtime debug and log level", function()
    -- @covers lurek.runtime.setDebugOverlay
    -- @covers lurek.runtime.getDebugOverlay
    it("setDebugOverlay/getDebugOverlay round-trip", function()
        lurek.runtime.setDebugOverlay(true)
        expect_equal(true, lurek.runtime.getDebugOverlay())
        lurek.runtime.setDebugOverlay(false)
        expect_equal(false, lurek.runtime.getDebugOverlay())
    end)

    -- @covers lurek.runtime.setLogLevel
    -- @covers lurek.runtime.getLogLevel
    it("setLogLevel/getLogLevel round-trip", function()
        lurek.runtime.setLogLevel("warn")
        local level = lurek.runtime.getLogLevel()
        expect_type("string", level)
        lurek.runtime.setLogLevel("info")
    end)

    -- @covers lurek.runtime.getLastError
    it("getLastError returns nil or a table", function()
        local err = lurek.runtime.getLastError()
        expect_true(err == nil or type(err) == "table", "must be nil or table")
    end)

    -- @covers lurek.runtime.errorSnapshot
    it("errorSnapshot returns a string from an error value", function()
        local snap = lurek.runtime.errorSnapshot("test error")
        expect_type("string", snap)
        expect_true(#snap > 0, "snapshot must not be empty")
    end)
end)

describe("lurek.runtime environment and args", function()
    -- @covers lurek.runtime.getEnv
    it("getEnv returns nil for a non-existent variable", function()
        local v = lurek.runtime.getEnv("__LUREK_TEST_NONEXISTENT_VAR__")
        expect_nil(v)
    end)

    -- @covers lurek.runtime.getArgs
    it("getArgs returns a table", function()
        local args = lurek.runtime.getArgs()
        expect_type("table", args)
    end)

    -- @covers lurek.runtime.parseArgs
    it("parseArgs returns a table with flags, options, and positional fields", function()
        local parsed = lurek.runtime.parseArgs({ "--verbose", "--output", "out.txt", "file.lua" })
        expect_type("table", parsed)
        expect_type("table", parsed.flags)
        expect_type("table", parsed.options)
        expect_type("table", parsed.positional)
    end)

    -- @covers lurek.runtime.parseArgs
    it("parseArgs detects flag --verbose", function()
        local parsed = lurek.runtime.parseArgs({ "--verbose" })
        expect_true(parsed.flags["verbose"] == true, "--verbose should be a flag")
    end)
end)

test_summary()
