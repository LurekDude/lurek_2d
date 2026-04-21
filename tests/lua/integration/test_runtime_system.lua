-- Lurek2D Integration Test: System API.
-- Exercises platform-facing system helpers from Lua, including namespace availability, clipboard stubs, and quit-signal surface wiring.

-- @description Covers suite: lurek.runtime module exists.
describe("lurek.runtime module exists", function()
    -- @covers lurek.runtime
    -- @covers lurek.runtime.getOS
    -- @covers lurek.runtime.clipboard
    -- @covers lurek.runtime.getClipboardText
    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime.getVersion
    -- @covers lurek.runtime.setClipboardText
    -- @covers lurek.event.quit
    -- @description Verifies the platform namespace exists; this file is stored under integration but this test is effectively single-module platform coverage.
    it("lurek.runtime is a table", function()
        expect_type("table", lurek.runtime)
    end)
end)

-- @description Covers suite: lurek.runtime.getOS.
describe("lurek.runtime.getOS", function()
    -- @covers lurek.runtime.getOS
    -- @covers lurek.runtime
    -- @description Verifies the platform OS getter is exposed as a function; this is single-module platform coverage.
    it("is a function", function()
        expect_type("function", lurek.runtime.getOS)
    end)

    -- @covers lurek.runtime.getOS
    -- @covers lurek.runtime
    -- @description Verifies the platform OS getter returns a string value.
    it("returns a string", function()
        local os = lurek.runtime.getOS()
        expect_type("string", os)
    end)

    -- @covers lurek.runtime.getOS
    -- @covers lurek.runtime
    -- @description Verifies the platform OS getter returns one of the expected engine OS labels.
    it("returns a known OS name", function()
        local os = lurek.runtime.getOS()
        local valid = (os == "Windows" or os == "Linux" or os == "macOS"
                      or os == "Android" or os == "iOS" or os == "Unknown")
        expect_true(valid, "OS should be a known name, got: " .. os)
    end)
end)

-- @description Covers suite: lurek.runtime.getVersion.
describe("lurek.runtime.getVersion", function()
    -- @covers lurek.runtime.getVersion
    -- @covers lurek.runtime
    -- @description Verifies the platform version getter is exposed as a function.
    it("is a function", function()
        expect_type("function", lurek.runtime.getVersion)
    end)

    -- @covers lurek.runtime.getVersion
    -- @covers lurek.runtime
    -- @description Verifies the platform version getter returns a string.
    it("returns a string", function()
        local ver = lurek.runtime.getVersion()
        expect_type("string", ver)
    end)

    -- @covers lurek.runtime.getVersion
    -- @covers lurek.runtime
    -- @description Verifies the reported platform version string is not empty.
    it("returns non-empty version", function()
        local ver = lurek.runtime.getVersion()
        expect_true(#ver > 0, "version should not be empty")
    end)
end)

-- @description Covers suite: lurek.runtime.getInfo.
describe("lurek.runtime.getInfo", function()
    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime
    -- @description Verifies the platform info getter is exposed as a function.
    it("is a function", function()
        expect_type("function", lurek.runtime.getInfo)
    end)

    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime
    -- @description Verifies platform info returns a structured table.
    it("returns a table", function()
        local info = lurek.runtime.getInfo()
        expect_type("table", info)
    end)

    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime
    -- @description Verifies platform info reports the expected engine name.
    it("has engine name", function()
        local info = lurek.runtime.getInfo()
        expect_equal("Lurek2D", info.engine)
    end)

    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime.getVersion
    -- @description Verifies platform info includes a version string field.
    it("has version", function()
        local info = lurek.runtime.getInfo()
        expect_type("string", info.version)
    end)

    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime
    -- @description Verifies platform info includes a Lua runtime version string.
    it("has lua_version", function()
        local info = lurek.runtime.getInfo()
        expect_contains(info.lua_version, "Lua")
    end)

    -- @covers lurek.runtime.getInfo
    -- @covers lurek.runtime
    -- @description Verifies platform info identifies wgpu as the renderer backend.
    it("reports the wgpu renderer", function()
        local info = lurek.runtime.getInfo()
        expect_equal("wgpu", info.renderer)
    end)
end)

-- @description Covers suite: lurek.event module exists.
describe("lurek.event module exists", function()
    -- @covers lurek.event
    -- @covers lurek.event.quit
    -- @description Verifies the signal namespace exists; this is a single-module signal smoke test kept in the integration folder.
    it("lurek.event is a table", function()
        expect_type("table", lurek.event)
    end)
end)

-- @description Covers suite: lurek.event.quit.
describe("lurek.event.quit", function()
    -- @covers lurek.event.quit
    -- @covers lurek.event
    -- @description Verifies the quit signal hook is exposed as a function.
    it("is a function", function()
        expect_type("function", lurek.event.quit)
    end)
end)

-- @description Covers suite: lurek.runtime.clipboard stubs.
describe("lurek.runtime.clipboard stubs", function()
    -- @covers lurek.runtime.setClipboardText
    -- @covers lurek.runtime
    -- @description Verifies the platform clipboard setter is exposed as a function.
    it("setClipboardText is a function", function()
        expect_type("function", lurek.runtime.setClipboardText)
    end)

    -- @covers lurek.runtime.getClipboardText
    -- @covers lurek.runtime
    -- @description Verifies the platform clipboard getter is exposed as a function.
    it("getClipboardText is a function", function()
        expect_type("function", lurek.runtime.getClipboardText)
    end)

    -- @covers lurek.runtime.getClipboardText
    -- @covers lurek.runtime
    -- @description Verifies the clipboard getter returns a string even in stubbed or headless environments.
    it("getClipboardText returns a string", function()
        local text = lurek.runtime.getClipboardText()
        expect_type("string", text)
    end)
end)
test_summary()
