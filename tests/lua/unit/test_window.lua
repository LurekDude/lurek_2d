-- Lurek2D Window API Tests
-- @covers lurek.window.close
-- @covers lurek.window.focus
-- @covers lurek.window.fromPixels
-- @covers lurek.window.getDPIScale
-- @covers lurek.window.getDesktopDimensions
-- @covers lurek.window.getDimensions
-- @covers lurek.window.getDisplayCount
-- @covers lurek.window.getDisplayOrientation
-- @covers lurek.window.getFullscreen
-- @covers lurek.window.getHeight
-- @covers lurek.window.getMode
-- @covers lurek.window.getNativeDPIScale
-- @covers lurek.window.getPosition
-- @covers lurek.window.getSafeArea
-- @covers lurek.window.getSystemTheme
-- @covers lurek.window.getTitle
-- @covers lurek.window.getVSync
-- @covers lurek.window.getWidth
-- @covers lurek.window.hasFocus
-- @covers lurek.window.hasMouseFocus
-- @covers lurek.window.isHighDPIAllowed
-- @covers lurek.window.isMaximized
-- @covers lurek.window.isMinimized
-- @covers lurek.window.isOpen
-- @covers lurek.window.isVisible
-- @covers lurek.window.maximize
-- @covers lurek.window.minimize
-- @covers lurek.window.requestAttention
-- @covers lurek.window.restore
-- @covers lurek.window.setFullscreen
-- @covers lurek.window.setIcon
-- @covers lurek.window.setMode
-- @covers lurek.window.setPosition
-- @covers lurek.window.setVSync
-- @covers lurek.window.toPixels


describe("lurek.window module exists", function()
    it("lurek.window is a table", function()
        expect_type("table", lurek.window)
    end)
end)

describe("lurek.window basic functions", function()
    it("getTitle is a function", function()
        expect_type("function", lurek.window.getTitle)
    end)

    it("getTitle returns a string", function()
        local title = lurek.window.getTitle()
        expect_type("string", title)
    end)

    it("getDimensions is a function", function()
        expect_type("function", lurek.window.getDimensions)
    end)

    it("getDimensions returns two numbers", function()
        local w, h = lurek.window.getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    it("getDimensions returns positive values", function()
        local w, h = lurek.window.getDimensions()
        expect_true(w > 0, "width > 0")
        expect_true(h > 0, "height > 0")
    end)

    it("getWidth is a function", function()
        expect_type("function", lurek.window.getWidth)
    end)

    it("getWidth returns a number", function()
        expect_type("number", lurek.window.getWidth())
    end)

    it("getHeight is a function", function()
        expect_type("function", lurek.window.getHeight)
    end)

    it("getHeight returns a number", function()
        expect_type("number", lurek.window.getHeight())
    end)
end)

describe("lurek.window fullscreen", function()
    it("setFullscreen is a function", function()
        expect_type("function", lurek.window.setFullscreen)
    end)

    it("getFullscreen is a function", function()
        expect_type("function", lurek.window.getFullscreen)
    end)

    it("getFullscreen returns bool and string", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_type("boolean", fs)
        expect_type("string", ft)
    end)

    it("getFullscreen default is false/desktop", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_equal(false, fs)
        expect_equal("desktop", ft)
    end)

    it("isOpen always returns true", function()
        expect_equal(true, lurek.window.isOpen())
    end)
end)

describe("lurek.window vsync", function()
    it("setVSync is a function", function()
        expect_type("function", lurek.window.setVSync)
    end)

    it("getVSync is a function", function()
        expect_type("function", lurek.window.getVSync)
    end)

    it("getVSync returns default 1", function()
        expect_equal(1, lurek.window.getVSync())
    end)
end)

describe("lurek.window state queries", function()
    it("hasFocus is a function", function()
        expect_type("function", lurek.window.hasFocus)
    end)

    it("hasFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasFocus())
    end)

    it("hasFocus default is true", function()
        expect_equal(true, lurek.window.hasFocus())
    end)

    it("hasMouseFocus is a function", function()
        expect_type("function", lurek.window.hasMouseFocus)
    end)

    it("hasMouseFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasMouseFocus())
    end)

    it("isMinimized is a function", function()
        expect_type("function", lurek.window.isMinimized)
    end)

    it("isMinimized default is false", function()
        expect_equal(false, lurek.window.isMinimized())
    end)

    it("isMaximized is a function", function()
        expect_type("function", lurek.window.isMaximized)
    end)

    it("isMaximized default is false", function()
        expect_equal(false, lurek.window.isMaximized())
    end)

    it("isVisible is a function", function()
        expect_type("function", lurek.window.isVisible)
    end)

    it("isVisible default is true", function()
        expect_equal(true, lurek.window.isVisible())
    end)
end)

describe("lurek.window minimize/maximize/restore", function()
    it("minimize is a function", function()
        expect_type("function", lurek.window.minimize)
    end)

    it("maximize is a function", function()
        expect_type("function", lurek.window.maximize)
    end)

    it("restore is a function", function()
        expect_type("function", lurek.window.restore)
    end)
end)

describe("lurek.window position", function()
    it("getPosition is a function", function()
        expect_type("function", lurek.window.getPosition)
    end)

    it("getPosition returns two numbers", function()
        local x, y = lurek.window.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    it("setPosition is a function", function()
        expect_type("function", lurek.window.setPosition)
    end)

    it("getDisplayCount returns a number", function()
        local n = lurek.window.getDisplayCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least 1 display")
    end)

    it("getDesktopDimensions returns two numbers", function()
        local w, h = lurek.window.getDesktopDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)
end)

describe("lurek.window DPI", function()
    it("getDPIScale returns a number", function()
        local s = lurek.window.getDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale > 0")
    end)

    it("getDPIScale default is 1.0", function()
        local s = lurek.window.getDPIScale()
        expect_equal(1, s)
    end)

    it("toPixels converts correctly", function()
        local px = lurek.window.toPixels(100)
        expect_type("number", px)
        -- With default DPI scale of 1.0, should be 100
        expect_equal(100, px)
    end)

    it("fromPixels converts correctly", function()
        local val = lurek.window.fromPixels(100)
        expect_type("number", val)
        expect_equal(100, val)
    end)
end)

describe("lurek.window icon", function()
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

describe("lurek.window mode", function()
    it("setMode is a function", function()
        expect_type("function", lurek.window.setMode)
    end)

    it("getMode is a function", function()
        expect_type("function", lurek.window.getMode)
    end)

    it("getMode returns width, height, flags", function()
        local w, h, flags = lurek.window.getMode()
        expect_type("number", w)
        expect_type("number", h)
        expect_type("table", flags)
    end)

    it("getMode flags contain fullscreen", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("boolean", flags.fullscreen)
    end)

    it("getMode flags contain fullscreentype", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("string", flags.fullscreentype)
    end)

    it("getMode flags contain vsync", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("number", flags.vsync)
    end)
end)

describe("lurek.window close and attention", function()
    it("close is a function", function()
        expect_type("function", lurek.window.close)
    end)

    it("requestAttention is a function", function()
        expect_type("function", lurek.window.requestAttention)
    end)
end)

-- Phase 17: Missing Window Surface
describe("lurek.window missing surface (Phase 17)", function()
    it("focus is a function", function()
        expect_type("function", lurek.window.focus)
    end)

    it("focus can be called without error", function()
        lurek.window.focus()
    end)

    it("getNativeDPIScale is a function", function()
        expect_type("function", lurek.window.getNativeDPIScale)
    end)

    it("getNativeDPIScale returns a positive number", function()
        local s = lurek.window.getNativeDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale must be positive")
    end)

    it("getDisplayOrientation is a function", function()
        expect_type("function", lurek.window.getDisplayOrientation)
    end)

    it("getDisplayOrientation returns a string", function()
        local o = lurek.window.getDisplayOrientation()
        expect_type("string", o)
    end)

    it("getDisplayOrientation value is landscape or portrait variant", function()
        local o = lurek.window.getDisplayOrientation()
        local valid = (o == "landscape" or o == "portrait" or
                       o == "landscapeflipped" or o == "portraitflipped")
        expect_true(valid, "orientation must be landscape/portrait/landscapeflipped/portraitflipped")
    end)

    it("getSafeArea is a function", function()
        expect_type("function", lurek.window.getSafeArea)
    end)

    it("getSafeArea returns four numbers", function()
        local x, y, w, h = lurek.window.getSafeArea()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    it("getSafeArea w and h are positive on desktop", function()
        local _, _, w, h = lurek.window.getSafeArea()
        expect_true(w > 0, "safe area width > 0")
        expect_true(h > 0, "safe area height > 0")
    end)

    it("getSystemTheme is a function", function()
        expect_type("function", lurek.window.getSystemTheme)
    end)

    it("getSystemTheme returns a string", function()
        local t = lurek.window.getSystemTheme()
        expect_type("string", t)
    end)

    it("isHighDPIAllowed is a function", function()
        expect_type("function", lurek.window.isHighDPIAllowed)
    end)

    it("isHighDPIAllowed returns a boolean", function()
        expect_type("boolean", lurek.window.isHighDPIAllowed())
    end)
end)

test_summary()
