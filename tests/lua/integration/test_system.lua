-- Lurek2D System API Tests

describe("lurek.platform module exists", function()
    it("lurek.platform is a table", function()
        expect_type("table", lurek.platform)
    end)
end)

describe("lurek.platform.getOS", function()
    it("is a function", function()
        expect_type("function", lurek.platform.getOS)
    end)

    it("returns a string", function()
        local os = lurek.platform.getOS()
        expect_type("string", os)
    end)

    it("returns a known OS name", function()
        local os = lurek.platform.getOS()
        local valid = (os == "Windows" or os == "Linux" or os == "macOS"
                      or os == "Android" or os == "iOS" or os == "Unknown")
        expect_true(valid, "OS should be a known name, got: " .. os)
    end)
end)

describe("lurek.platform.getVersion", function()
    it("is a function", function()
        expect_type("function", lurek.platform.getVersion)
    end)

    it("returns a string", function()
        local ver = lurek.platform.getVersion()
        expect_type("string", ver)
    end)

    it("returns non-empty version", function()
        local ver = lurek.platform.getVersion()
        expect_true(#ver > 0, "version should not be empty")
    end)
end)

describe("lurek.platform.getInfo", function()
    it("is a function", function()
        expect_type("function", lurek.platform.getInfo)
    end)

    it("returns a table", function()
        local info = lurek.platform.getInfo()
        expect_type("table", info)
    end)

    it("has engine name", function()
        local info = lurek.platform.getInfo()
        expect_equal("Lurek2D", info.engine)
    end)

    it("has version", function()
        local info = lurek.platform.getInfo()
        expect_type("string", info.version)
    end)

    it("has lua_version", function()
        local info = lurek.platform.getInfo()
        expect_contains(info.lua_version, "Lua")
    end)

    it("reports the wgpu renderer", function()
        local info = lurek.platform.getInfo()
        expect_equal("wgpu", info.renderer)
    end)
end)

describe("lurek.signal module exists", function()
    it("lurek.signal is a table", function()
        expect_type("table", lurek.signal)
    end)
end)

describe("lurek.signal.quit", function()
    it("is a function", function()
        expect_type("function", lurek.signal.quit)
    end)
end)

describe("lurek.platform.clipboard stubs", function()
    it("setClipboardText is a function", function()
        expect_type("function", lurek.platform.setClipboardText)
    end)

    it("getClipboardText is a function", function()
        expect_type("function", lurek.platform.getClipboardText)
    end)

    it("getClipboardText returns a string", function()
        local text = lurek.platform.getClipboardText()
        expect_type("string", text)
    end)
end)

test_summary()
