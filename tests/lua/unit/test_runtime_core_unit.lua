-- Lurek2D Runtime Unit Tests



-- [merged from test_runtime_window.lua]
-- Lurek2D system / platform API tests
-- Tests lurek.runtime.* namespace (registered via system_api.rs)
-- Headless-safe: no GPU, no audio, no window.

-- ============================================================
-- Module surface
-- ============================================================
-- @describe lurek.runtime module
describe("lurek.runtime module", function()
    -- @covers lurek.runtime
    it("is a table", function()
        expect_type("table", lurek.runtime)
    end)
end)

-- ============================================================
-- OS information
-- ============================================================
-- @describe lurek.runtime.getOS
describe("lurek.runtime.getOS", function()
    -- @covers lurek.runtime.getOS
    it("is a function", function()
        expect_type("function", lurek.runtime.getOS)
    end)

    -- @covers lurek.runtime.getOS
    it("returns a string", function()
        local os = lurek.runtime.getOS()
        expect_type("string", os)
    end)

    -- @covers lurek.runtime.getOS
    it("returns a known OS name", function()
        local os = lurek.runtime.getOS()
        local valid = (os == "Windows" or os == "Linux" or os == "macOS"
                      or os == "Android" or os == "iOS" or os == "Unknown")
        expect_true(valid, "OS should be recognised, got: " .. os)
    end)
end)

-- @describe lurek.runtime.getVersion
describe("lurek.runtime.getVersion", function()
    -- @covers lurek.runtime.getVersion
    it("is a function", function()
        expect_type("function", lurek.runtime.getVersion)
    end)

    -- @covers lurek.runtime.getVersion
    it("returns a non-empty string", function()
        local ver = lurek.runtime.getVersion()
        expect_type("string", ver)
        expect_true(#ver > 0, "version should not be empty")
    end)
end)

-- @describe lurek.runtime.getArch
describe("lurek.runtime.getArch", function()
    -- @covers lurek.runtime.getArch
    it("is a function", function()
        expect_type("function", lurek.runtime.getArch)
    end)

    -- @covers lurek.runtime.getArch
    it("returns a string", function()
        local arch = lurek.runtime.getArch()
        expect_type("string", arch)
        expect_true(#arch > 0, "arch should not be empty")
    end)
end)

-- @describe lurek.runtime.getProcessorCount
describe("lurek.runtime.getProcessorCount", function()
    -- @covers lurek.runtime.getProcessorCount
    it("is a function", function()
        expect_type("function", lurek.runtime.getProcessorCount)
    end)

    -- @covers lurek.runtime.getProcessorCount
    it("returns a positive integer", function()
        local n = lurek.runtime.getProcessorCount()
        expect_type("number", n)
        expect_true(n >= 1, "processor count should be at least 1")
        expect_true(n == math.floor(n), "should be an integer")
    end)
end)

-- @describe lurek.runtime.getMemorySize
describe("lurek.runtime.getMemorySize", function()
    -- @covers lurek.runtime.getMemorySize
    it("is a function", function()
        expect_type("function", lurek.runtime.getMemorySize)
    end)

    -- @covers lurek.runtime.getMemorySize
    it("returns a positive number (MiB)", function()
        local mb = lurek.runtime.getMemorySize()
        expect_type("number", mb)
        expect_true(mb > 0, "memory should be positive")
    end)
end)

-- ============================================================
-- Engine info table
-- ============================================================
-- @describe lurek.runtime.getInfo
describe("lurek.runtime.getInfo", function()
    -- @covers lurek.runtime.getInfo
    it("is a function", function()
        expect_type("function", lurek.runtime.getInfo)
    end)

    -- @covers lurek.runtime.getInfo
    it("returns a table", function()
        local info = lurek.runtime.getInfo()
        expect_type("table", info)
    end)

    -- @covers lurek.runtime.getInfo
    it("has engine == 'Lurek2D'", function()
        local info = lurek.runtime.getInfo()
        expect_equal("Lurek2D", info.engine)
    end)

    -- @covers lurek.runtime.getInfo
    it("has a non-empty version string", function()
        local info = lurek.runtime.getInfo()
        expect_type("string", info.version)
        expect_true(#info.version > 0)
    end)

    -- @covers lurek.runtime.getInfo
    it("has lua_version containing 'Lua'", function()
        local info = lurek.runtime.getInfo()
        expect_contains(info.lua_version, "Lua")
    end)

    -- @covers lurek.runtime.getInfo
    it("reports the wgpu renderer", function()
        local info = lurek.runtime.getInfo()
        expect_equal("wgpu", info.renderer)
    end)

    -- @covers lurek.runtime.getInfo
    it("has os field", function()
        local info = lurek.runtime.getInfo()
        expect_type("string", info.os)
    end)

    -- @covers lurek.runtime.getInfo
    it("has processors field >= 1", function()
        local info = lurek.runtime.getInfo()
        expect_type("number", info.processors)
        expect_true(info.processors >= 1)
    end)

    -- @covers lurek.runtime.getInfo
    it("has memory field > 0", function()
        local info = lurek.runtime.getInfo()
        expect_type("number", info.memory)
        expect_true(info.memory > 0)
    end)
end)

-- ============================================================
-- Clipboard
-- ============================================================
-- @describe lurek.runtime clipboard
describe("lurek.runtime clipboard", function()
    -- @covers lurek.runtime.setClipboardText
    it("setClipboardText is a function", function()
        expect_type("function", lurek.runtime.setClipboardText)
    end)

    -- @covers lurek.runtime.getClipboardText
    it("getClipboardText is a function", function()
        expect_type("function", lurek.runtime.getClipboardText)
    end)

    -- @covers lurek.runtime.setClipboardText
    it("setClipboardText does not error", function()
        lurek.runtime.setClipboardText("lurek2d test")
    end)

    -- @covers lurek.runtime.getClipboardText
    it("getClipboardText returns a string", function()
        local text = lurek.runtime.getClipboardText()
        expect_type("string", text)
    end)
end)

-- ============================================================
-- Debug overlay
-- ============================================================
-- @describe lurek.runtime debug overlay
describe("lurek.runtime debug overlay", function()
    -- @covers lurek.runtime.setDebugOverlay
    it("setDebugOverlay is a function", function()
        expect_type("function", lurek.runtime.setDebugOverlay)
    end)

    -- @covers lurek.runtime.getDebugOverlay
    it("getDebugOverlay is a function", function()
        expect_type("function", lurek.runtime.getDebugOverlay)
    end)

    -- @covers lurek.runtime.getDebugOverlay
    -- @covers lurek.runtime.setDebugOverlay
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
-- @describe lurek.runtime log level
describe("lurek.runtime log level", function()
    -- @covers lurek.runtime.setLogLevel
    it("setLogLevel is a function", function()
        expect_type("function", lurek.runtime.setLogLevel)
    end)

    -- @covers lurek.runtime.getLogLevel
    it("getLogLevel is a function", function()
        expect_type("function", lurek.runtime.getLogLevel)
    end)

    -- @covers lurek.runtime.getLogLevel
    -- @covers lurek.runtime.setLogLevel
    it("setLogLevel/getLogLevel round-trip for 'warn'", function()
        lurek.runtime.setLogLevel("warn")
        local level = lurek.runtime.getLogLevel()
        expect_equal("warn", level)
    end)

    -- @covers lurek.runtime.getLogLevel
    -- @covers lurek.runtime.setLogLevel
    it("setLogLevel/getLogLevel round-trip for 'debug'", function()
        lurek.runtime.setLogLevel("debug")
        local level = lurek.runtime.getLogLevel()
        expect_equal("debug", level)
    end)
end)

-- ============================================================
-- log()
-- ============================================================
-- @describe lurek.runtime.log
describe("lurek.runtime.log", function()
    -- @covers lurek.runtime.log
    it("is a function", function()
        expect_type("function", lurek.runtime.log)
    end)

    -- @covers lurek.runtime.log
    it("does not error for info level", function()
        lurek.runtime.log("info", "test log message")
    end)

    -- @covers lurek.runtime.log
    it("does not error for warn level", function()
        lurek.runtime.log("warn", "test warn message")
    end)
end)

-- ============================================================
-- getLastError
-- ============================================================
-- @describe lurek.runtime.getLastError
describe("lurek.runtime.getLastError", function()
    -- @covers lurek.runtime.getLastError
    it("is a function", function()
        expect_type("function", lurek.runtime.getLastError)
    end)

    -- @covers lurek.runtime.getLastError
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
-- @describe lurek.runtime.getEnv
describe("lurek.runtime.getEnv", function()
    -- @covers lurek.runtime.getEnv
    it("is a function", function()
        expect_type("function", lurek.runtime.getEnv)
    end)

    -- @covers lurek.runtime.getEnv
    it("returns nil for an unset variable", function()
        local v = lurek.runtime.getEnv("LUREK2D_NONEXISTENT_VAR_12345")
        expect_equal(nil, v)
    end)

    -- @covers lurek.runtime.getEnv
    it("returns a string for a set variable", function()
        local v = lurek.runtime.getEnv("PATH")
        if v ~= nil then
            expect_type("string", v)
        end
    end)
end)

-- @describe lurek.runtime.getArgs
describe("lurek.runtime.getArgs", function()
    -- @covers lurek.runtime.getArgs
    it("is a function", function()
        expect_type("function", lurek.runtime.getArgs)
    end)

    -- @covers lurek.runtime.getArgs
    it("returns a table", function()
        local args = lurek.runtime.getArgs()
        expect_type("table", args)
    end)
end)

-- @describe lurek.runtime.parseArgs
describe("lurek.runtime.parseArgs", function()
    -- @covers lurek.runtime.parseArgs
    it("is a function", function()
        expect_type("function", lurek.runtime.parseArgs)
    end)

    -- @covers lurek.runtime.parseArgs
    it("returns a table with flags, options, positional", function()
        local parsed = lurek.runtime.parseArgs({})
        expect_type("table", parsed)
        expect_type("table", parsed.flags)
        expect_type("table", parsed.options)
        expect_type("table", parsed.positional)
    end)

    -- @covers lurek.runtime.parseArgs
    it("parses flag arguments", function()
        local parsed = lurek.runtime.parseArgs({"--verbose", "--debug"})
        expect_equal(true, parsed.flags.verbose)
        expect_equal(true, parsed.flags.debug)
    end)

    -- @covers lurek.runtime.parseArgs
    it("parses key=value options", function()
        local parsed = lurek.runtime.parseArgs({"--output=foo.txt"})
        expect_equal("foo.txt", parsed.options.output)
    end)

    -- @covers lurek.runtime.parseArgs
    it("parses positional arguments", function()
        local parsed = lurek.runtime.parseArgs({"file1.lua", "file2.lua"})
        expect_equal(2, #parsed.positional)
        expect_equal("file1.lua", parsed.positional[1])
    end)
end)

-- ============================================================
-- Message catalog
-- ============================================================
-- @describe lurek.runtime message catalog
describe("lurek.runtime message catalog", function()
    -- @covers lurek.runtime.getMessage
    it("getMessage is a function", function()
        expect_type("function", lurek.runtime.getMessage)
    end)

    -- @covers lurek.runtime.hasMessage
    it("hasMessage is a function", function()
        expect_type("function", lurek.runtime.hasMessage)
    end)

    -- @covers lurek.runtime.getMessageCount
    it("getMessageCount is a function", function()
        expect_type("function", lurek.runtime.getMessageCount)
    end)

    -- @covers lurek.runtime.getMessageCount
    it("getMessageCount returns at least 30 entries", function()
        expect_true(lurek.runtime.getMessageCount() >= 30)
    end)

    -- @covers lurek.runtime.getMessage
    it("L001 resolves to startup text", function()
        expect_equal("Lurek2D Engine starting", lurek.runtime.getMessage("L001"))
    end)

    -- @covers lurek.runtime.getMessage
    it("L003 resolves to game loaded", function()
        expect_equal("Game loaded", lurek.runtime.getMessage("L003"))
    end)

    -- @covers lurek.runtime.getMessage
    it("L010 resolves to render error", function()
        expect_equal("Render error", lurek.runtime.getMessage("L010"))
    end)

    -- @covers lurek.runtime.getMessage
    it("unknown IDs fall back to the raw id", function()
        expect_equal("ZZUNKNOWN", lurek.runtime.getMessage("ZZUNKNOWN"))
    end)

    -- @covers lurek.runtime.hasMessage
    it("hasMessage distinguishes known and unknown ids", function()
        expect_equal(true, lurek.runtime.hasMessage("L001"))
        expect_equal(false, lurek.runtime.hasMessage("ZZUNKNOWN"))
    end)
end)

-- ============================================================
-- Power info
-- ============================================================
-- @describe lurek.runtime.getPowerInfo
describe("lurek.runtime.getPowerInfo", function()
    -- @covers lurek.runtime.getPowerInfo
    it("is a function", function()
        expect_type("function", lurek.runtime.getPowerInfo)
    end)

    -- @covers lurek.runtime.getPowerInfo
    it("returns state as first value (string)", function()
        local state, pct, secs = lurek.runtime.getPowerInfo()
        expect_type("string", state)
    end)
end)

-- ============================================================
-- Preferred locales
-- ============================================================
-- @describe lurek.runtime.getPreferredLocales
describe("lurek.runtime.getPreferredLocales", function()
    -- @covers lurek.runtime.getPreferredLocales
    it("is a function", function()
        expect_type("function", lurek.runtime.getPreferredLocales)
    end)

    -- @covers lurek.runtime.getPreferredLocales
    it("returns a table", function()
        local locales = lurek.runtime.getPreferredLocales()
        expect_type("table", locales)
    end)
end)

-- ============================================================
-- openURL (function-existence test  - do NOT call it)
-- ============================================================
-- @describe lurek.runtime.openURL
describe("lurek.runtime.openURL", function()
    -- @covers lurek.runtime.openURL
    it("is a function", function()
        expect_type("function", lurek.runtime.openURL)
    end)
end)

-- @describe lurek.runtime.errorSnapshot serialisation
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
-- @describe lurek.runtime.setClipboardText + lurek.runtime.getClipboardText
describe("lurek.runtime.setClipboardText + lurek.runtime.getClipboardText", function()
    -- @covers lurek.runtime.setClipboardText
    -- @covers lurek.runtime.getClipboardText
    it("clipboard round-trip (headless-safe)", function()
        if lurek.runtime and lurek.runtime.setClipboardText then
            lurek.runtime.setClipboardText("Lurek2D test")
            local text = lurek.runtime.getClipboardText()
            -- Clipboard may be unavailable in headless mode; only assert when returned
            if text then
                expect_equal("Lurek2D test", text, "clipboard round-trip")
            end
        end
    end)
end)

-- ============================================================
-- reloadConfig / getConfig
-- ============================================================
-- @describe lurek.runtime.reloadConfig
describe("lurek.runtime.reloadConfig", function()
    -- @covers lurek.runtime.reloadConfig
    it("is a function", function()
        expect_type("function", lurek.runtime.reloadConfig)
    end)

    -- @covers lurek.runtime.reloadConfig
    it("does not error when called", function()
        lurek.runtime.reloadConfig()
    end)
end)

-- @describe lurek.runtime.getConfig
describe("lurek.runtime.getConfig", function()
    -- @covers lurek.runtime.getConfig
    it("is a function", function()
        expect_type("function", lurek.runtime.getConfig)
    end)

    -- @covers lurek.runtime.getConfig
    it("returns a table", function()
        local cfg = lurek.runtime.getConfig()
        expect_type("table", cfg)
    end)

    -- @covers lurek.runtime.getConfig
    it("has physics_tick_rate >= 1", function()
        local cfg = lurek.runtime.getConfig()
        expect_type("number", cfg.physics_tick_rate)
        expect_true(cfg.physics_tick_rate >= 1, "physics_tick_rate should be at least 1 Hz")
    end)

    -- @covers lurek.runtime.getConfig
    it("has vsync as a boolean", function()
        local cfg = lurek.runtime.getConfig()
        expect_true(cfg.vsync == true or cfg.vsync == false, "vsync must be boolean")
    end)

    -- @covers lurek.runtime.getConfig
    it("has log_level as a string", function()
        local cfg = lurek.runtime.getConfig()
        expect_type("string", cfg.log_level)
        expect_true(#cfg.log_level > 0, "log_level must be non-empty")
    end)

    -- @covers lurek.runtime.getConfig
    it("has config_reload_revision as a non-negative integer", function()
        local cfg = lurek.runtime.getConfig()
        expect_type("number", cfg.config_reload_revision)
        expect_true(cfg.config_reload_revision >= 0, "revision must be non-negative")
    end)
end)

test_summary()
