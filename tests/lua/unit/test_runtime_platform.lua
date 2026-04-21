-- Lurek2D system / platform API tests
-- Tests lurek.runtime.* namespace (registered via system_api.rs)
-- Headless-safe: no GPU, no audio, no window.

-- ============================================================
-- Module surface
-- ============================================================
-- @description Covers suite: lurek.runtime module.
describe("lurek.runtime module", function()
    -- @covers lurek.runtime
    -- @covers lurek.runtime.getOS
    -- @covers lurek.runtime.getVersion
    -- @covers lurek.runtime.getArch
    -- @covers lurek.runtime.getProcessorCount
    -- @covers lurek.runtime.getMemorySize
    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime.getClipboardText
    -- @covers lurek.runtime.setClipboardText
    -- @covers lurek.runtime.setDebugOverlay
    -- @covers lurek.runtime.getDebugOverlay
    -- @covers lurek.runtime.setLogLevel
    -- @covers lurek.runtime.getLogLevel
    -- @covers lurek.runtime.log
    -- @covers lurek.runtime.getLastError
    -- @covers lurek.runtime.getEnv
    -- @covers lurek.runtime.getArgs
    -- @covers lurek.runtime.parseArgs
    -- @covers lurek.runtime.getPowerInfo
    -- @covers lurek.runtime.getPreferredLocales
    -- @covers lurek.runtime.openURL
    -- @covers lurek.runtime.getMessage
    -- @covers lurek.runtime.hasMessage
    -- @covers lurek.runtime.getMessageCount
    -- @covers lurek.event.quit
    -- @description Verifies the platform namespace is available as a Lua table.
    it("is a table", function()
        expect_type("table", lurek.runtime)
    end)
end)

-- ============================================================
-- OS information
-- ============================================================
-- @description Covers suite: lurek.runtime.getOS.
describe("lurek.runtime.getOS", function()
    -- @covers lurek.runtime.getOS
    -- @description Verifies getOS is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getOS)
    end)

    -- @covers lurek.runtime.getOS
    -- @description Verifies getOS returns a string payload.
    it("returns a string", function()
        local os = lurek.runtime.getOS()
        expect_type("string", os)
    end)

    -- @covers lurek.runtime.getOS
    -- @description Verifies getOS maps to one of the known platform labels.
    it("returns a known OS name", function()
        local os = lurek.runtime.getOS()
        local valid = (os == "Windows" or os == "Linux" or os == "macOS"
                      or os == "Android" or os == "iOS" or os == "Unknown")
        expect_true(valid, "OS should be recognised, got: " .. os)
    end)
end)

-- @description Covers suite: lurek.runtime.getVersion.
describe("lurek.runtime.getVersion", function()
    -- @covers lurek.runtime.getVersion
    -- @description Verifies getVersion is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getVersion)
    end)

    -- @covers lurek.runtime.getVersion
    -- @description Verifies getVersion returns non-empty version text.
    it("returns a non-empty string", function()
        local ver = lurek.runtime.getVersion()
        expect_type("string", ver)
        expect_true(#ver > 0, "version should not be empty")
    end)
end)

-- @description Covers suite: lurek.runtime.getArch.
describe("lurek.runtime.getArch", function()
    -- @covers lurek.runtime.getArch
    -- @description Verifies getArch is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getArch)
    end)

    -- @covers lurek.runtime.getArch
    -- @description Verifies getArch returns non-empty architecture text.
    it("returns a string", function()
        local arch = lurek.runtime.getArch()
        expect_type("string", arch)
        expect_true(#arch > 0, "arch should not be empty")
    end)
end)

-- @description Covers suite: lurek.runtime.getProcessorCount.
describe("lurek.runtime.getProcessorCount", function()
    -- @covers lurek.runtime.getProcessorCount
    -- @description Verifies getProcessorCount is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getProcessorCount)
    end)

    -- @covers lurek.runtime.getProcessorCount
    -- @description Verifies getProcessorCount returns a positive integer.
    it("returns a positive integer", function()
        local n = lurek.runtime.getProcessorCount()
        expect_type("number", n)
        expect_true(n >= 1, "processor count should be at least 1")
        expect_true(n == math.floor(n), "should be an integer")
    end)
end)

-- @description Covers suite: lurek.runtime.getMemorySize.
describe("lurek.runtime.getMemorySize", function()
    -- @covers lurek.runtime.getMemorySize
    -- @description Verifies getMemorySize is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getMemorySize)
    end)

    -- @covers lurek.runtime.getMemorySize
    -- @description Verifies getMemorySize reports a positive memory value in MiB.
    it("returns a positive number (MiB)", function()
        local mb = lurek.runtime.getMemorySize()
        expect_type("number", mb)
        expect_true(mb > 0, "memory should be positive")
    end)
end)

-- ============================================================
-- Engine info table
-- ============================================================
-- @description Covers suite: lurek.runtime.getInfo.
describe("lurek.runtime.getInfo", function()
    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getInfo)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo returns a table payload.
    it("returns a table", function()
        local info = lurek.runtime.getInfo()
        expect_type("table", info)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo identifies the engine as Lurek2D.
    it("has engine == 'Lurek2D'", function()
        local info = lurek.runtime.getInfo()
        expect_equal("Lurek2D", info.engine)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo includes a non-empty engine version string.
    it("has a non-empty version string", function()
        local info = lurek.runtime.getInfo()
        expect_type("string", info.version)
        expect_true(#info.version > 0)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo exposes the Lua runtime version string.
    it("has lua_version containing 'Lua'", function()
        local info = lurek.runtime.getInfo()
        expect_contains(info.lua_version, "Lua")
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo reports wgpu as the active renderer backend.
    it("reports the wgpu renderer", function()
        local info = lurek.runtime.getInfo()
        expect_equal("wgpu", info.renderer)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo includes the host OS string.
    it("has os field", function()
        local info = lurek.runtime.getInfo()
        expect_type("string", info.os)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo includes a processor count of at least one.
    it("has processors field >= 1", function()
        local info = lurek.runtime.getInfo()
        expect_type("number", info.processors)
        expect_true(info.processors >= 1)
    end)

    -- @covers lurek.runtime.getInfo
    -- @description Verifies getInfo includes a positive memory value.
    it("has memory field > 0", function()
        local info = lurek.runtime.getInfo()
        expect_type("number", info.memory)
        expect_true(info.memory > 0)
    end)
end)

-- ============================================================
-- Clipboard
-- ============================================================
-- @description Covers suite: lurek.runtime clipboard.
describe("lurek.runtime clipboard", function()
    -- @covers lurek.runtime.setClipboardText
    -- @description Verifies the clipboard setter is exposed.
    it("setClipboardText is a function", function()
        expect_type("function", lurek.runtime.setClipboardText)
    end)

    -- @covers lurek.runtime.getClipboardText
    -- @description Verifies the clipboard getter is exposed.
    it("getClipboardText is a function", function()
        expect_type("function", lurek.runtime.getClipboardText)
    end)

    -- @covers lurek.runtime.setClipboardText
    -- @description Verifies setClipboardText accepts a string without error.
    it("setClipboardText does not error", function()
        lurek.runtime.setClipboardText("lurek2d test")
    end)

    -- @covers lurek.runtime.getClipboardText
    -- @description Verifies getClipboardText returns a string payload.
    it("getClipboardText returns a string", function()
        local text = lurek.runtime.getClipboardText()
        expect_type("string", text)
    end)
end)

-- ============================================================
-- Debug overlay
-- ============================================================
-- @description Covers suite: lurek.runtime debug overlay.
describe("lurek.runtime debug overlay", function()
    -- @covers lurek.runtime.setDebugOverlay
    -- @description Verifies the debug-overlay setter is exposed.
    it("setDebugOverlay is a function", function()
        expect_type("function", lurek.runtime.setDebugOverlay)
    end)

    -- @covers lurek.runtime.getDebugOverlay
    -- @description Verifies the debug-overlay getter is exposed.
    it("getDebugOverlay is a function", function()
        expect_type("function", lurek.runtime.getDebugOverlay)
    end)

    -- @covers lurek.runtime.setDebugOverlay
    -- @covers lurek.runtime.getDebugOverlay
    -- @description Verifies debug-overlay state round-trips through the setter and getter.
    it("setDebugOverlay/getDebugOverlay round-trip", function()
        lurek.runtime.setDebugOverlay(true)
        expect_equal(true, lurek.runtime.getDebugOverlay())
        lurek.runtime.setDebugOverlay(false)
        expect_equal(false, lurek.runtime.getDebugOverlay())
    end)
end)

-- ============================================================
-- Log level
-- ============================================================
-- @description Covers suite: lurek.runtime log level.
describe("lurek.runtime log level", function()
    -- @covers lurek.runtime.setLogLevel
    -- @description Verifies the log-level setter is exposed.
    it("setLogLevel is a function", function()
        expect_type("function", lurek.runtime.setLogLevel)
    end)

    -- @covers lurek.runtime.getLogLevel
    -- @description Verifies the log-level getter is exposed.
    it("getLogLevel is a function", function()
        expect_type("function", lurek.runtime.getLogLevel)
    end)

    -- @covers lurek.runtime.setLogLevel
    -- @covers lurek.runtime.getLogLevel
    -- @description Verifies warn log level round-trips through the API.
    it("setLogLevel/getLogLevel round-trip for 'warn'", function()
        lurek.runtime.setLogLevel("warn")
        local level = lurek.runtime.getLogLevel()
        expect_equal("warn", level)
    end)

    -- @covers lurek.runtime.setLogLevel
    -- @covers lurek.runtime.getLogLevel
    -- @description Verifies debug log level round-trips through the API.
    it("setLogLevel/getLogLevel round-trip for 'debug'", function()
        lurek.runtime.setLogLevel("debug")
        local level = lurek.runtime.getLogLevel()
        expect_equal("debug", level)
    end)
end)

-- ============================================================
-- log()
-- ============================================================
-- @description Covers suite: lurek.runtime.log.
describe("lurek.runtime.log", function()
    -- @covers lurek.runtime.log
    -- @description Verifies the generic log bridge is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.log)
    end)

    -- @covers lurek.runtime.log
    -- @description Verifies log accepts the info level without error.
    it("does not error for info level", function()
        lurek.runtime.log("info", "test log message")
    end)

    -- @covers lurek.runtime.log
    -- @description Verifies log accepts the warn level without error.
    it("does not error for warn level", function()
        lurek.runtime.log("warn", "test warn message")
    end)
end)

-- ============================================================
-- getLastError
-- ============================================================
-- @description Covers suite: lurek.runtime.getLastError.
describe("lurek.runtime.getLastError", function()
    -- @covers lurek.runtime.getLastError
    -- @description Verifies getLastError is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getLastError)
    end)

    -- @covers lurek.runtime.getLastError
    -- @description Verifies getLastError returns either nil or a structured table.
    it("returns nil or a table", function()
        local err = lurek.runtime.getLastError()
        local t = type(err)
        expect_true(t == "nil" or t == "table",
            "getLastError should return nil or table, got " .. t)
    end)
end)

-- ============================================================
-- Environment and args
-- ============================================================
-- @description Covers suite: lurek.runtime.getEnv.
describe("lurek.runtime.getEnv", function()
    -- @covers lurek.runtime.getEnv
    -- @description Verifies getEnv is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getEnv)
    end)

    -- @covers lurek.runtime.getEnv
    -- @description Verifies getEnv returns nil for missing environment variables.
    it("returns nil for an unset variable", function()
        local v = lurek.runtime.getEnv("LUREK2D_NONEXISTENT_VAR_12345")
        expect_equal(nil, v)
    end)

    -- @covers lurek.runtime.getEnv
    -- @description Verifies getEnv returns string data for a present variable when available.
    it("returns a string for a set variable", function()
        local v = lurek.runtime.getEnv("PATH")
        if v ~= nil then
            expect_type("string", v)
        end
    end)
end)

-- @description Covers suite: lurek.runtime.getArgs.
describe("lurek.runtime.getArgs", function()
    -- @covers lurek.runtime.getArgs
    -- @description Verifies getArgs is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getArgs)
    end)

    -- @covers lurek.runtime.getArgs
    -- @description Verifies getArgs returns a table of process arguments.
    it("returns a table", function()
        local args = lurek.runtime.getArgs()
        expect_type("table", args)
    end)
end)

-- @description Covers suite: lurek.runtime.parseArgs.
describe("lurek.runtime.parseArgs", function()
    -- @covers lurek.runtime.parseArgs
    -- @description Verifies parseArgs is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.parseArgs)
    end)

    -- @covers lurek.runtime.parseArgs
    -- @description Verifies parseArgs returns flags, options, and positional arrays.
    it("returns a table with flags, options, positional", function()
        local parsed = lurek.runtime.parseArgs({})
        expect_type("table", parsed)
        expect_type("table", parsed.flags)
        expect_type("table", parsed.options)
        expect_type("table", parsed.positional)
    end)

    -- @covers lurek.runtime.parseArgs
    -- @description Verifies parseArgs treats double-dash flags as boolean entries.
    it("parses flag arguments", function()
        local parsed = lurek.runtime.parseArgs({"--verbose", "--debug"})
        expect_equal(true, parsed.flags.verbose)
        expect_equal(true, parsed.flags.debug)
    end)

    -- @covers lurek.runtime.parseArgs
    -- @description Verifies parseArgs splits key=value options into the options table.
    it("parses key=value options", function()
        local parsed = lurek.runtime.parseArgs({"--output=foo.txt"})
        expect_equal("foo.txt", parsed.options.output)
    end)

    -- @covers lurek.runtime.parseArgs
    -- @description Verifies parseArgs preserves bare arguments in positional order.
    it("parses positional arguments", function()
        local parsed = lurek.runtime.parseArgs({"file1.lua", "file2.lua"})
        expect_equal(2, #parsed.positional)
        expect_equal("file1.lua", parsed.positional[1])
    end)
end)

-- ============================================================
-- Message catalog
-- ============================================================
-- @description Covers suite: lurek.runtime runtime message catalog lookup.
describe("lurek.runtime message catalog", function()
    -- @covers lurek.runtime.getMessage
    -- @description Verifies the stable message lookup helper is exposed.
    it("getMessage is a function", function()
        expect_type("function", lurek.runtime.getMessage)
    end)

    -- @covers lurek.runtime.hasMessage
    -- @description Verifies the catalog membership helper is exposed.
    it("hasMessage is a function", function()
        expect_type("function", lurek.runtime.hasMessage)
    end)

    -- @covers lurek.runtime.getMessageCount
    -- @description Verifies the catalog size helper is exposed.
    it("getMessageCount is a function", function()
        expect_type("function", lurek.runtime.getMessageCount)
    end)

    -- @covers lurek.runtime.getMessageCount
    -- @description Verifies the embedded runtime message catalog loads at least the baseline message set.
    it("getMessageCount returns at least 30 entries", function()
        expect_true(lurek.runtime.getMessageCount() >= 30)
    end)

    -- @covers lurek.runtime.getMessage
    -- @description Verifies L001 resolves to the expected startup text from the embedded message catalog.
    it("L001 resolves to startup text", function()
        expect_equal("Lurek2D Engine starting", lurek.runtime.getMessage("L001"))
    end)

    -- @covers lurek.runtime.getMessage
    -- @description Verifies L003 resolves to the expected game-loaded text from the embedded message catalog.
    it("L003 resolves to game loaded", function()
        expect_equal("Game loaded", lurek.runtime.getMessage("L003"))
    end)

    -- @covers lurek.runtime.getMessage
    -- @description Verifies L010 resolves to the expected render-error text from the embedded message catalog.
    it("L010 resolves to render error", function()
        expect_equal("Render error", lurek.runtime.getMessage("L010"))
    end)

    -- @covers lurek.runtime.getMessage
    -- @description Verifies unknown message IDs fall back to the raw ID string instead of crashing or returning nil.
    it("unknown IDs fall back to the raw id", function()
        expect_equal("ZZUNKNOWN", lurek.runtime.getMessage("ZZUNKNOWN"))
    end)

    -- @covers lurek.runtime.hasMessage
    -- @description Verifies known and unknown message IDs are reported correctly by the catalog membership helper.
    it("hasMessage distinguishes known and unknown ids", function()
        expect_equal(true, lurek.runtime.hasMessage("L001"))
        expect_equal(false, lurek.runtime.hasMessage("ZZUNKNOWN"))
    end)
end)

-- ============================================================
-- Power info
-- ============================================================
-- @description Covers suite: lurek.runtime.getPowerInfo.
describe("lurek.runtime.getPowerInfo", function()
    -- @covers lurek.runtime.getPowerInfo
    -- @description Verifies getPowerInfo is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getPowerInfo)
    end)

    -- @covers lurek.runtime.getPowerInfo
    -- @description Verifies getPowerInfo returns a string state as its first value.
    it("returns state as first value (string)", function()
        local state, pct, secs = lurek.runtime.getPowerInfo()
        expect_type("string", state)
    end)
end)

-- ============================================================
-- Preferred locales
-- ============================================================
-- @description Covers suite: lurek.runtime.getPreferredLocales.
describe("lurek.runtime.getPreferredLocales", function()
    -- @covers lurek.runtime.getPreferredLocales
    -- @description Verifies getPreferredLocales is exposed.
    it("is a function", function()
        expect_type("function", lurek.runtime.getPreferredLocales)
    end)

    -- @covers lurek.runtime.getPreferredLocales
    -- @description Verifies getPreferredLocales returns a table payload.
    it("returns a table", function()
        local locales = lurek.runtime.getPreferredLocales()
        expect_type("table", locales)
    end)
end)

-- ============================================================
-- openURL (function-existence test â€” do NOT call it)
-- ============================================================
-- @description Covers suite: lurek.runtime.openURL.
describe("lurek.runtime.openURL", function()
    -- @covers lurek.runtime.openURL
    -- @description Verifies the openURL hook is exposed without invoking side effects.
    it("is a function", function()
        expect_type("function", lurek.runtime.openURL)
    end)
end)

-- ============================================================
-- lurek.event.quit (cross-module surface check)
-- ============================================================
-- @description Covers suite: lurek.event.quit.
describe("lurek.event.quit", function()
    -- @covers lurek.event.quit
    -- @description Verifies the signal namespace exists for the quit helper.
    it("lurek.event is a table", function()
        expect_type("table", lurek.event)
    end)

    -- @covers lurek.event.quit
    -- @description Verifies the quit signal helper is exposed.
    it("quit is a function", function()
        expect_type("function", lurek.event.quit)
    end)
end)

describe("lurek.runtime.errorSnapshot serialisation", function()
    -- @covers lurek.runtime.errorSnapshot
    it("errorSnapshot is a function", function()
        expect_equal("function", type(lurek.runtime.errorSnapshot))
    end)

    -- @covers lurek.runtime.errorSnapshot
    it("returns a non-empty string", function()
        local json = lurek.runtime.errorSnapshot("test error")
        expect_equal("string", type(json))
        expect_true(#json > 0)
    end)

    -- @covers lurek.runtime.errorSnapshot
    it("output contains message field", function()
        local json = lurek.runtime.errorSnapshot("my error")
        expect_true(json:find('"message"') ~= nil)
    end)

    -- @covers lurek.runtime.errorSnapshot
    it("output contains code field", function()
        local json = lurek.runtime.errorSnapshot("err")
        expect_true(json:find('"code"') ~= nil)
    end)

    -- @covers lurek.runtime.errorSnapshot
    it("output contains category field", function()
        local json = lurek.runtime.errorSnapshot("err")
        expect_true(json:find('"category"') ~= nil)
    end)
end)

test_summary()
