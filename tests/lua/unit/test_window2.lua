-- Luna2D Window API Tests

describe("luna.window module exists", function()
    it("luna.window is a table", function()
        expect_type("table", luna.window)
    end)
end)

describe("luna.window basic functions", function()
    it("getTitle is a function", function()
        expect_type("function", luna.window.getTitle)
    end)

    it("getTitle returns a string", function()
        local title = luna.window.getTitle()
        expect_type("string", title)
    end)

    it("getDimensions is a function", function()
        expect_type("function", luna.window.getDimensions)
    end)

    it("getDimensions returns two numbers", function()
        local w, h = luna.window.getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    it("getDimensions returns positive values", function()
        local w, h = luna.window.getDimensions()
        expect_true(w > 0, "width > 0")
        expect_true(h > 0, "height > 0")
    end)

    it("getWidth is a function", function()
        expect_type("function", luna.window.getWidth)
    end)

    it("getWidth returns a number", function()
        expect_type("number", luna.window.getWidth())
    end)

    it("getHeight is a function", function()
        expect_type("function", luna.window.getHeight)
    end)

    it("getHeight returns a number", function()
        expect_type("number", luna.window.getHeight())
    end)
end)

describe("luna.window fullscreen", function()
    it("setFullscreen is a function", function()
        expect_type("function", luna.window.setFullscreen)
    end)

    it("getFullscreen is a function", function()
        expect_type("function", luna.window.getFullscreen)
    end)

    it("getFullscreen returns bool and string", function()
        local fs, ft = luna.window.getFullscreen()
        expect_type("boolean", fs)
        expect_type("string", ft)
    end)

    it("getFullscreen default is false/desktop", function()
        local fs, ft = luna.window.getFullscreen()
        expect_equal(false, fs)
        expect_equal("desktop", ft)
    end)

    it("isOpen always returns true", function()
        expect_equal(true, luna.window.isOpen())
    end)
end)

describe("luna.window vsync", function()
    it("setVSync is a function", function()
        expect_type("function", luna.window.setVSync)
    end)

    it("getVSync is a function", function()
        expect_type("function", luna.window.getVSync)
    end)

    it("getVSync returns default 1", function()
        expect_equal(1, luna.window.getVSync())
    end)
end)

describe("luna.window state queries", function()
    it("hasFocus is a function", function()
        expect_type("function", luna.window.hasFocus)
    end)

    it("hasFocus returns boolean", function()
        expect_type("boolean", luna.window.hasFocus())
    end)

    it("hasFocus default is true", function()
        expect_equal(true, luna.window.hasFocus())
    end)

    it("hasMouseFocus is a function", function()
        expect_type("function", luna.window.hasMouseFocus)
    end)

    it("hasMouseFocus returns boolean", function()
        expect_type("boolean", luna.window.hasMouseFocus())
    end)

    it("isMinimized is a function", function()
        expect_type("function", luna.window.isMinimized)
    end)

    it("isMinimized default is false", function()
        expect_equal(false, luna.window.isMinimized())
    end)

    it("isMaximized is a function", function()
        expect_type("function", luna.window.isMaximized)
    end)

    it("isMaximized default is false", function()
        expect_equal(false, luna.window.isMaximized())
    end)

    it("isVisible is a function", function()
        expect_type("function", luna.window.isVisible)
    end)

    it("isVisible default is true", function()
        expect_equal(true, luna.window.isVisible())
    end)
end)

describe("luna.window minimize/maximize/restore", function()
    it("minimize is a function", function()
        expect_type("function", luna.window.minimize)
    end)

    it("maximize is a function", function()
        expect_type("function", luna.window.maximize)
    end)

    it("restore is a function", function()
        expect_type("function", luna.window.restore)
    end)
end)

describe("luna.window position", function()
    it("getPosition is a function", function()
        expect_type("function", luna.window.getPosition)
    end)

    it("getPosition returns two numbers", function()
        local x, y = luna.window.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    it("setPosition is a function", function()
        expect_type("function", luna.window.setPosition)
    end)

    it("getDisplayCount returns a number", function()
        local n = luna.window.getDisplayCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least 1 display")
    end)

    it("getDesktopDimensions returns two numbers", function()
        local w, h = luna.window.getDesktopDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)
end)

describe("luna.window DPI", function()
    it("getDPIScale returns a number", function()
        local s = luna.window.getDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale > 0")
    end)

    it("getDPIScale default is 1.0", function()
        local s = luna.window.getDPIScale()
        expect_equal(1, s)
    end)

    it("toPixels converts correctly", function()
        local px = luna.window.toPixels(100)
        expect_type("number", px)
        -- With default DPI scale of 1.0, should be 100
        expect_equal(100, px)
    end)

    it("fromPixels converts correctly", function()
        local val = luna.window.fromPixels(100)
        expect_type("number", val)
        expect_equal(100, val)
    end)
end)

describe("luna.window icon", function()
    it("setIcon is a function", function()
        expect_type("function", luna.window.setIcon)
    end)
end)

describe("luna.window mode", function()
    it("setMode is a function", function()
        expect_type("function", luna.window.setMode)
    end)

    it("getMode is a function", function()
        expect_type("function", luna.window.getMode)
    end)

    it("getMode returns width, height, flags", function()
        local w, h, flags = luna.window.getMode()
        expect_type("number", w)
        expect_type("number", h)
        expect_type("table", flags)
    end)

    it("getMode flags contain fullscreen", function()
        local _, _, flags = luna.window.getMode()
        expect_type("boolean", flags.fullscreen)
    end)

    it("getMode flags contain fullscreentype", function()
        local _, _, flags = luna.window.getMode()
        expect_type("string", flags.fullscreentype)
    end)

    it("getMode flags contain vsync", function()
        local _, _, flags = luna.window.getMode()
        expect_type("number", flags.vsync)
    end)
end)

describe("luna.window close and attention", function()
    it("close is a function", function()
        expect_type("function", luna.window.close)
    end)

    it("requestAttention is a function", function()
        expect_type("function", luna.window.requestAttention)
    end)
end)

-- Phase 17: Missing Window Surface
describe("luna.window missing surface (Phase 17)", function()
    it("focus is a function", function()
        expect_type("function", luna.window.focus)
    end)

    it("focus can be called without error", function()
        luna.window.focus()
    end)

    it("getNativeDPIScale is a function", function()
        expect_type("function", luna.window.getNativeDPIScale)
    end)

    it("getNativeDPIScale returns a positive number", function()
        local s = luna.window.getNativeDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale must be positive")
    end)

    it("getDisplayOrientation is a function", function()
        expect_type("function", luna.window.getDisplayOrientation)
    end)

    it("getDisplayOrientation returns a string", function()
        local o = luna.window.getDisplayOrientation()
        expect_type("string", o)
    end)

    it("getDisplayOrientation value is landscape or portrait variant", function()
        local o = luna.window.getDisplayOrientation()
        local valid = (o == "landscape" or o == "portrait" or
                       o == "landscapeflipped" or o == "portraitflipped")
        expect_true(valid, "orientation must be landscape/portrait/landscapeflipped/portraitflipped")
    end)

    it("getSafeArea is a function", function()
        expect_type("function", luna.window.getSafeArea)
    end)

    it("getSafeArea returns four numbers", function()
        local x, y, w, h = luna.window.getSafeArea()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    it("getSafeArea w and h are positive on desktop", function()
        local _, _, w, h = luna.window.getSafeArea()
        expect_true(w > 0, "safe area width > 0")
        expect_true(h > 0, "safe area height > 0")
    end)

    it("getSystemTheme is a function", function()
        expect_type("function", luna.window.getSystemTheme)
    end)

    it("getSystemTheme returns a string", function()
        local t = luna.window.getSystemTheme()
        expect_type("string", t)
    end)

    it("isHighDPIAllowed is a function", function()
        expect_type("function", luna.window.isHighDPIAllowed)
    end)

    it("isHighDPIAllowed returns a boolean", function()
        expect_type("boolean", luna.window.isHighDPIAllowed())
    end)
end)

test_summary()
