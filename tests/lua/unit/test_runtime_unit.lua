-- Lurek2D Runtime Unit Tests
-- @testCategory unit

describe("lurek.runtime metadata", function()
  -- @covers lurek.runtime.getVersion
  it("getVersion returns a non-empty string", function()
    local v = lurek.runtime.getVersion()
    expect_equal(type(v), "string")
    expect_true(#v > 0, "version must be non-empty")
  end)

  -- @covers lurek.runtime.getFrameBudget
  xit("getFrameBudget returns ~16.67 ms", function()
    local b = lurek.runtime.getFrameBudget()
    expect_equal(type(b), "number")
    expect_true(b > 16.0 and b < 17.0, "frame budget must be near 16.67 ms")
  end)

  -- @covers lurek.runtime.memoryUsage
  xit("memoryUsage returns lua_bytes and lua_kb", function()
    local m = lurek.runtime.memoryUsage()
    expect_equal(type(m), "table")
    expect_true(type(m.lua_bytes) == "number" and m.lua_bytes >= 0, "lua_bytes must be >= 0")
    expect_true(type(m.lua_kb) == "number" and m.lua_kb >= 0, "lua_kb must be >= 0")
  end)

  -- @covers lurek.runtime.platform
  xit("platform returns a known platform string", function()
    local p = lurek.runtime.platform()
    local valid = { windows = true, linux = true, macos = true, unknown = true }
    expect_true(valid[p] == true, "platform must be a known OS")
  end)

  -- @covers lurek.runtime.uptime
  xit("uptime returns a non-negative number", function()
    local u = lurek.runtime.uptime()
    expect_equal(type(u), "number")
    expect_true(u >= 0, "uptime must be non-negative")
  end)

  -- @covers lurek.runtime.fps
  xit("fps returns a non-negative number", function()
    local f = lurek.runtime.fps()
    expect_equal(type(f), "number")
    expect_true(f >= 0, "fps must be non-negative")
  end)

  -- @covers lurek.runtime.frameCount
  xit("frameCount returns a non-negative integer", function()
    local c = lurek.runtime.frameCount()
    expect_equal(type(c), "number")
    expect_true(c >= 0, "frameCount must be non-negative")
    expect_equal(math.floor(c), c)
  end)

  -- @covers lurek.runtime.isDebug
  xit("isDebug returns a boolean", function()
    local d = lurek.runtime.isDebug()
    expect_equal(type(d), "boolean")
  end)
end)



-- [merged from test_runtime_window.lua]
-- Lurek2D system / platform API tests
-- Tests lurek.runtime.* namespace (registered via system_api.rs)
-- Headless-safe: no GPU, no audio, no window.

-- ============================================================
-- Module surface
-- ============================================================
describe("lurek.runtime module", function()
    -- @tests lurek.runtime
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
    it("is a table", function()
        expect_type("table", lurek.runtime)
    end)
end)

-- ============================================================
-- OS information
-- ============================================================
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
describe("lurek.runtime debug overlay", function()
    -- @covers lurek.runtime.setDebugOverlay
    it("setDebugOverlay is a function", function()
        expect_type("function", lurek.runtime.setDebugOverlay)
    end)

    -- @covers lurek.runtime.getDebugOverlay
    it("getDebugOverlay is a function", function()
        expect_type("function", lurek.runtime.getDebugOverlay)
    end)

    -- @covers lurek.runtime.setDebugOverlay
    -- @covers lurek.runtime.getDebugOverlay
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
describe("lurek.runtime log level", function()
    -- @covers lurek.runtime.setLogLevel
    it("setLogLevel is a function", function()
        expect_type("function", lurek.runtime.setLogLevel)
    end)

    -- @covers lurek.runtime.getLogLevel
    it("getLogLevel is a function", function()
        expect_type("function", lurek.runtime.getLogLevel)
    end)

    -- @covers lurek.runtime.setLogLevel
    -- @covers lurek.runtime.getLogLevel
    it("setLogLevel/getLogLevel round-trip for 'warn'", function()
        lurek.runtime.setLogLevel("warn")
        local level = lurek.runtime.getLogLevel()
        expect_equal("warn", level)
    end)

    -- @covers lurek.runtime.setLogLevel
    -- @covers lurek.runtime.getLogLevel
    it("setLogLevel/getLogLevel round-trip for 'debug'", function()
        lurek.runtime.setLogLevel("debug")
        local level = lurek.runtime.getLogLevel()
        expect_equal("debug", level)
    end)
end)

-- ============================================================
-- log()
-- ============================================================
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
describe("lurek.runtime.openURL", function()
    -- @covers lurek.runtime.openURL
    it("is a function", function()
        expect_type("function", lurek.runtime.openURL)
    end)
end)

-- ============================================================
-- lurek.event.quit (cross-module surface check)
-- ============================================================
describe("lurek.event.quit", function()
    -- @covers lurek.event.quit
    it("lurek.event is a table", function()
        expect_type("table", lurek.event)
    end)

    -- @covers lurek.event.quit
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
