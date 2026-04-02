-- Luna2D System API Tests

describe("luna.system module exists", function()
    it("luna.system is a table", function()
        expect_type("table", luna.system)
    end)
end)

describe("luna.system.getOS", function()
    it("is a function", function()
        expect_type("function", luna.system.getOS)
    end)

    it("returns a string", function()
        local os = luna.system.getOS()
        expect_type("string", os)
    end)

    it("returns a known OS name", function()
        local os = luna.system.getOS()
        local valid = (os == "Windows" or os == "Linux" or os == "macOS"
                      or os == "Android" or os == "iOS" or os == "Unknown")
        expect_true(valid, "OS should be a known name, got: " .. os)
    end)
end)

describe("luna.system.getVersion", function()
    it("is a function", function()
        expect_type("function", luna.system.getVersion)
    end)

    it("returns a string", function()
        local ver = luna.system.getVersion()
        expect_type("string", ver)
    end)

    it("returns non-empty version", function()
        local ver = luna.system.getVersion()
        expect_true(#ver > 0, "version should not be empty")
    end)
end)

describe("luna.system.getInfo", function()
    it("is a function", function()
        expect_type("function", luna.system.getInfo)
    end)

    it("returns a table", function()
        local info = luna.system.getInfo()
        expect_type("table", info)
    end)

    it("has engine name", function()
        local info = luna.system.getInfo()
        expect_equal("Luna2D", info.engine)
    end)

    it("has version", function()
        local info = luna.system.getInfo()
        expect_type("string", info.version)
    end)

    it("has lua_version", function()
        local info = luna.system.getInfo()
        expect_contains(info.lua_version, "Lua")
    end)

    it("reports the wgpu renderer", function()
        local info = luna.system.getInfo()
        expect_equal("wgpu", info.renderer)
    end)
end)

describe("luna.event module exists", function()
    it("luna.event is a table", function()
        expect_type("table", luna.event)
    end)
end)

describe("luna.event.quit", function()
    it("is a function", function()
        expect_type("function", luna.event.quit)
    end)
end)

describe("luna.system.clipboard stubs", function()
    it("setClipboardText is a function", function()
        expect_type("function", luna.system.setClipboardText)
    end)

    it("getClipboardText is a function", function()
        expect_type("function", luna.system.getClipboardText)
    end)

    it("getClipboardText returns a string", function()
        local text = luna.system.getClipboardText()
        expect_type("string", text)
    end)
end)

test_summary()
