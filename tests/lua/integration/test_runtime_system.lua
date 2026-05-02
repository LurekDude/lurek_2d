-- Lurek2D Integration Test: System API.
-- Exercises platform-facing system helpers from Lua, including namespace availability, clipboard behavior, and quit-signal surface wiring.

describe("lurek.runtime module exists", function()
    it("lurek.runtime is a table", function()
        expect_type("table", lurek.runtime)
    end)
end)

describe("lurek.runtime.getOS", function()
    it("is a function", function()
        expect_type("function", lurek.runtime.getOS)
    end)

    it("returns a string", function()
        local os = lurek.runtime.getOS()
        expect_type("string", os)
    end)

    it("returns a known OS name", function()
        local os = lurek.runtime.getOS()
        local valid = (os == "Windows" or os == "Linux" or os == "macOS"
                      or os == "Android" or os == "iOS" or os == "Unknown")
        expect_true(valid, "OS should be a known name, got: " .. os)
    end)
end)

describe("lurek.runtime.getVersion", function()
    it("is a function", function()
        expect_type("function", lurek.runtime.getVersion)
    end)

    it("returns a string", function()
        local ver = lurek.runtime.getVersion()
        expect_type("string", ver)
    end)

    it("returns non-empty version", function()
        local ver = lurek.runtime.getVersion()
        expect_true(#ver > 0, "version should not be empty")
    end)
end)

describe("lurek.runtime.getInfo", function()
    it("is a function", function()
        expect_type("function", lurek.runtime.getInfo)
    end)

    it("returns a table", function()
        local info = lurek.runtime.getInfo()
        expect_type("table", info)
    end)

    it("has engine name", function()
        local info = lurek.runtime.getInfo()
        expect_equal("Lurek2D", info.engine)
    end)

    it("has version", function()
        local info = lurek.runtime.getInfo()
        expect_type("string", info.version)
    end)

    it("has lua_version", function()
        local info = lurek.runtime.getInfo()
        expect_contains(info.lua_version, "Lua")
    end)

    it("reports the wgpu renderer", function()
        local info = lurek.runtime.getInfo()
        expect_equal("wgpu", info.renderer)
    end)
end)

describe("lurek.event module exists", function()
    it("lurek.event is a table", function()
        expect_type("table", lurek.event)
    end)
end)

describe("lurek.event.quit", function()
    it("is a function", function()
        expect_type("function", lurek.event.quit)
    end)
end)

describe("lurek.runtime.clipboard behavior", function()
    it("setClipboardText is a function", function()
        expect_type("function", lurek.runtime.setClipboardText)
    end)

    it("getClipboardText is a function", function()
        expect_type("function", lurek.runtime.getClipboardText)
    end)

    it("getClipboardText returns a string", function()
        local text = lurek.runtime.getClipboardText()
        expect_type("string", text)
    end)
end)
test_summary()
