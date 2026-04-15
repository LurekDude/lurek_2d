-- Lurek2D Window API Tests

-- @description Covers suite: lurek.window module exists.
describe("lurek.window module exists", function()
    -- @covers lurek.window
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
    -- @description Verifies the window namespace is available as a Lua table.
    it("lurek.window is a table", function()
        expect_type("table", lurek.window)
    end)
end)

-- @description Covers suite: lurek.window basic functions.
describe("lurek.window basic functions", function()
    -- @covers lurek.window.getTitle
    -- @description Verifies getTitle is exposed.
    it("getTitle is a function", function()
        expect_type("function", lurek.window.getTitle)
    end)

    -- @covers lurek.window.getTitle
    -- @description Verifies getTitle returns a string title.
    it("getTitle returns a string", function()
        local title = lurek.window.getTitle()
        expect_type("string", title)
    end)

    -- @covers lurek.window.getDimensions
    -- @description Verifies getDimensions is exposed.
    it("getDimensions is a function", function()
        expect_type("function", lurek.window.getDimensions)
    end)

    -- @covers lurek.window.getDimensions
    -- @description Verifies getDimensions returns numeric width and height values.
    it("getDimensions returns two numbers", function()
        local w, h = lurek.window.getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers lurek.window.getDimensions
    -- @description Verifies getDimensions reports positive size values.
    it("getDimensions returns positive values", function()
        local w, h = lurek.window.getDimensions()
        expect_true(w > 0, "width > 0")
        expect_true(h > 0, "height > 0")
    end)

    -- @covers lurek.window.getWidth
    -- @description Verifies getWidth is exposed.
    it("getWidth is a function", function()
        expect_type("function", lurek.window.getWidth)
    end)

    -- @covers lurek.window.getWidth
    -- @description Verifies getWidth returns a number.
    it("getWidth returns a number", function()
        expect_type("number", lurek.window.getWidth())
    end)

    -- @covers lurek.window.getHeight
    -- @description Verifies getHeight is exposed.
    it("getHeight is a function", function()
        expect_type("function", lurek.window.getHeight)
    end)

    -- @covers lurek.window.getHeight
    -- @description Verifies getHeight returns a number.
    it("getHeight returns a number", function()
        expect_type("number", lurek.window.getHeight())
    end)
end)

-- @description Covers suite: lurek.window fullscreen.
describe("lurek.window fullscreen", function()
    -- @covers lurek.window.setFullscreen
    -- @description Verifies setFullscreen is exposed.
    it("setFullscreen is a function", function()
        expect_type("function", lurek.window.setFullscreen)
    end)

    -- @covers lurek.window.getFullscreen
    -- @description Verifies getFullscreen is exposed.
    it("getFullscreen is a function", function()
        expect_type("function", lurek.window.getFullscreen)
    end)

    -- @covers lurek.window.getFullscreen
    -- @description Verifies getFullscreen returns a boolean flag plus a fullscreen type string.
    it("getFullscreen returns bool and string", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_type("boolean", fs)
        expect_type("string", ft)
    end)

    -- @covers lurek.window.getFullscreen
    -- @description Verifies the default fullscreen state is false with desktop mode.
    it("getFullscreen default is false/desktop", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_equal(false, fs)
        expect_equal("desktop", ft)
    end)

    -- @covers lurek.window.isOpen
    -- @description Verifies isOpen reports true in the headless test harness.
    it("isOpen always returns true", function()
        expect_equal(true, lurek.window.isOpen())
    end)
end)

-- @description Covers suite: lurek.window vsync.
describe("lurek.window vsync", function()
    -- @covers lurek.window.setVSync
    -- @description Verifies setVSync is exposed.
    it("setVSync is a function", function()
        expect_type("function", lurek.window.setVSync)
    end)

    -- @covers lurek.window.getVSync
    -- @description Verifies getVSync is exposed.
    it("getVSync is a function", function()
        expect_type("function", lurek.window.getVSync)
    end)

    -- @covers lurek.window.getVSync
    -- @description Verifies getVSync defaults to mode 1.
    it("getVSync returns default 1", function()
        expect_equal(1, lurek.window.getVSync())
    end)
end)

-- @description Covers suite: lurek.window state queries.
describe("lurek.window state queries", function()
    -- @covers lurek.window.hasFocus
    -- @description Verifies hasFocus is exposed.
    it("hasFocus is a function", function()
        expect_type("function", lurek.window.hasFocus)
    end)

    -- @covers lurek.window.hasFocus
    -- @description Verifies hasFocus returns a boolean value.
    it("hasFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasFocus())
    end)

    -- @covers lurek.window.hasFocus
    -- @description Verifies the headless window reports focused by default.
    it("hasFocus default is true", function()
        expect_equal(true, lurek.window.hasFocus())
    end)

    -- @covers lurek.window.hasMouseFocus
    -- @description Verifies hasMouseFocus is exposed.
    it("hasMouseFocus is a function", function()
        expect_type("function", lurek.window.hasMouseFocus)
    end)

    -- @covers lurek.window.hasMouseFocus
    -- @description Verifies hasMouseFocus returns a boolean value.
    it("hasMouseFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasMouseFocus())
    end)

    -- @covers lurek.window.isMinimized
    -- @description Verifies isMinimized is exposed.
    it("isMinimized is a function", function()
        expect_type("function", lurek.window.isMinimized)
    end)

    -- @covers lurek.window.isMinimized
    -- @description Verifies the window is not minimized by default.
    it("isMinimized default is false", function()
        expect_equal(false, lurek.window.isMinimized())
    end)

    -- @covers lurek.window.isMaximized
    -- @description Verifies isMaximized is exposed.
    it("isMaximized is a function", function()
        expect_type("function", lurek.window.isMaximized)
    end)

    -- @covers lurek.window.isMaximized
    -- @description Verifies the window is not maximized by default.
    it("isMaximized default is false", function()
        expect_equal(false, lurek.window.isMaximized())
    end)

    -- @covers lurek.window.isVisible
    -- @description Verifies isVisible is exposed.
    it("isVisible is a function", function()
        expect_type("function", lurek.window.isVisible)
    end)

    -- @covers lurek.window.isVisible
    -- @description Verifies the window is visible by default.
    it("isVisible default is true", function()
        expect_equal(true, lurek.window.isVisible())
    end)
end)

-- @description Covers suite: lurek.window minimize/maximize/restore.
describe("lurek.window minimize/maximize/restore", function()
    -- @covers lurek.window.minimize
    -- @description Verifies minimize is exposed.
    it("minimize is a function", function()
        expect_type("function", lurek.window.minimize)
    end)

    -- @covers lurek.window.maximize
    -- @description Verifies maximize is exposed.
    it("maximize is a function", function()
        expect_type("function", lurek.window.maximize)
    end)

    -- @covers lurek.window.restore
    -- @description Verifies restore is exposed.
    it("restore is a function", function()
        expect_type("function", lurek.window.restore)
    end)
end)

-- @description Covers suite: lurek.window position.
describe("lurek.window position", function()
    -- @covers lurek.window.getPosition
    -- @description Verifies getPosition is exposed.
    it("getPosition is a function", function()
        expect_type("function", lurek.window.getPosition)
    end)

    -- @covers lurek.window.getPosition
    -- @description Verifies getPosition returns numeric coordinates.
    it("getPosition returns two numbers", function()
        local x, y = lurek.window.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @covers lurek.window.setPosition
    -- @description Verifies setPosition is exposed.
    it("setPosition is a function", function()
        expect_type("function", lurek.window.setPosition)
    end)

    -- @covers lurek.window.getDisplayCount
    -- @description Verifies getDisplayCount returns a numeric monitor count of at least one.
    it("getDisplayCount returns a number", function()
        local n = lurek.window.getDisplayCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least 1 display")
    end)

    -- @covers lurek.window.getDesktopDimensions
    -- @description Verifies getDesktopDimensions returns numeric desktop bounds.
    it("getDesktopDimensions returns two numbers", function()
        local w, h = lurek.window.getDesktopDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)
end)

-- @description Covers suite: lurek.window DPI.
describe("lurek.window DPI", function()
    -- @covers lurek.window.getDPIScale
    -- @description Verifies getDPIScale returns a positive numeric scale.
    it("getDPIScale returns a number", function()
        local s = lurek.window.getDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale > 0")
    end)

    -- @covers lurek.window.getDPIScale
    -- @description Verifies the default DPI scale is 1.0 in the headless harness.
    it("getDPIScale default is 1.0", function()
        local s = lurek.window.getDPIScale()
        expect_equal(1, s)
    end)

    -- @covers lurek.window.toPixels
    -- @description Verifies toPixels converts logical units to numeric pixel units.
    it("toPixels converts correctly", function()
        local px = lurek.window.toPixels(100)
        expect_type("number", px)
        -- With default DPI scale of 1.0, should be 100
        expect_equal(100, px)
    end)

    -- @covers lurek.window.fromPixels
    -- @description Verifies fromPixels converts numeric pixel units back to logical units.
    it("fromPixels converts correctly", function()
        local val = lurek.window.fromPixels(100)
        expect_type("number", val)
        expect_equal(100, val)
    end)
end)

-- @description Covers suite: lurek.window icon.
describe("lurek.window icon", function()
    -- @covers lurek.window.setIcon
    -- @description Verifies setIcon is exposed.
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

-- @description Covers suite: lurek.window mode.
describe("lurek.window mode", function()
    -- @covers lurek.window.setMode
    -- @description Verifies setMode is exposed.
    it("setMode is a function", function()
        expect_type("function", lurek.window.setMode)
    end)

    -- @covers lurek.window.getMode
    -- @description Verifies getMode is exposed.
    it("getMode is a function", function()
        expect_type("function", lurek.window.getMode)
    end)

    -- @covers lurek.window.getMode
    -- @description Verifies getMode returns numeric dimensions plus a flags table.
    it("getMode returns width, height, flags", function()
        local w, h, flags = lurek.window.getMode()
        expect_type("number", w)
        expect_type("number", h)
        expect_type("table", flags)
    end)

    -- @covers lurek.window.getMode
    -- @description Verifies getMode exposes a fullscreen boolean flag.
    it("getMode flags contain fullscreen", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("boolean", flags.fullscreen)
    end)

    -- @covers lurek.window.getMode
    -- @description Verifies getMode exposes a fullscreentype string flag.
    it("getMode flags contain fullscreentype", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("string", flags.fullscreentype)
    end)

    -- @covers lurek.window.getMode
    -- @description Verifies getMode exposes a numeric vsync flag.
    it("getMode flags contain vsync", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("number", flags.vsync)
    end)
end)

-- @description Covers suite: lurek.window close and attention.
describe("lurek.window close and attention", function()
    -- @covers lurek.window.close
    -- @description Verifies close is exposed.
    it("close is a function", function()
        expect_type("function", lurek.window.close)
    end)

    -- @covers lurek.window.requestAttention
    -- @description Verifies requestAttention is exposed.
    it("requestAttention is a function", function()
        expect_type("function", lurek.window.requestAttention)
    end)
end)

-- Phase 17: Missing Window Surface
-- @description Covers suite: lurek.window missing surface (Phase 17).
describe("lurek.window missing surface (Phase 17)", function()
    -- @covers lurek.window.focus
    -- @description Verifies focus is exposed.
    it("focus is a function", function()
        expect_type("function", lurek.window.focus)
    end)

    -- @covers lurek.window.focus
    -- @description Verifies focus can be invoked without error.
    it("focus can be called without error", function()
        lurek.window.focus()
    end)

    -- @covers lurek.window.getNativeDPIScale
    -- @description Verifies getNativeDPIScale is exposed.
    it("getNativeDPIScale is a function", function()
        expect_type("function", lurek.window.getNativeDPIScale)
    end)

    -- @covers lurek.window.getNativeDPIScale
    -- @description Verifies getNativeDPIScale returns a positive number.
    it("getNativeDPIScale returns a positive number", function()
        local s = lurek.window.getNativeDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale must be positive")
    end)

    -- @covers lurek.window.getDisplayOrientation
    -- @description Verifies getDisplayOrientation is exposed.
    it("getDisplayOrientation is a function", function()
        expect_type("function", lurek.window.getDisplayOrientation)
    end)

    -- @covers lurek.window.getDisplayOrientation
    -- @description Verifies getDisplayOrientation returns a string enum value.
    it("getDisplayOrientation returns a string", function()
        local o = lurek.window.getDisplayOrientation()
        expect_type("string", o)
    end)

    -- @covers lurek.window.getDisplayOrientation
    -- @description Verifies display orientation is one of the expected desktop/mobile variants.
    it("getDisplayOrientation value is landscape or portrait variant", function()
        local o = lurek.window.getDisplayOrientation()
        local valid = (o == "landscape" or o == "portrait" or
                       o == "landscapeflipped" or o == "portraitflipped")
        expect_true(valid, "orientation must be landscape/portrait/landscapeflipped/portraitflipped")
    end)

    -- @covers lurek.window.getSafeArea
    -- @description Verifies getSafeArea is exposed.
    it("getSafeArea is a function", function()
        expect_type("function", lurek.window.getSafeArea)
    end)

    -- @covers lurek.window.getSafeArea
    -- @description Verifies getSafeArea returns numeric x, y, width, and height values.
    it("getSafeArea returns four numbers", function()
        local x, y, w, h = lurek.window.getSafeArea()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers lurek.window.getSafeArea
    -- @description Verifies the reported safe-area width and height are positive.
    it("getSafeArea w and h are positive on desktop", function()
        local _, _, w, h = lurek.window.getSafeArea()
        expect_true(w > 0, "safe area width > 0")
        expect_true(h > 0, "safe area height > 0")
    end)

    -- @covers lurek.window.getSystemTheme
    -- @description Verifies getSystemTheme is exposed.
    it("getSystemTheme is a function", function()
        expect_type("function", lurek.window.getSystemTheme)
    end)

    -- @covers lurek.window.getSystemTheme
    -- @description Verifies getSystemTheme returns a string.
    it("getSystemTheme returns a string", function()
        local t = lurek.window.getSystemTheme()
        expect_type("string", t)
    end)

    -- @covers lurek.window.isHighDPIAllowed
    -- @description Verifies isHighDPIAllowed is exposed.
    it("isHighDPIAllowed is a function", function()
        expect_type("function", lurek.window.isHighDPIAllowed)
    end)

    -- @covers lurek.window.isHighDPIAllowed
    -- @description Verifies isHighDPIAllowed returns a boolean capability flag.
    it("isHighDPIAllowed returns a boolean", function()
        expect_type("boolean", lurek.window.isHighDPIAllowed())
    end)
end)

-- @description Tests for new window features: onDpiChange, pollDpiChange, openFileDialog.
describe("lurek.window DPI and dialog", function()
  -- @covers lurek.window.onDpiChange
  -- @description Registers an onDpiChange callback without error.
  it("onDpiChange registers a callback without error", function()
    expect_no_error(function()
      lurek.window.onDpiChange(function(scale) end)
    end)
  end)

  -- @covers lurek.window.pollDpiChange
  -- @description pollDpiChange returns the current DPI scale without error.
  it("pollDpiChange returns a positive number", function()
    local scale = lurek.window.pollDpiChange()
    expect_equal(type(scale), "number")
    expect_true(scale > 0, "DPI scale must be positive")
  end)

  -- @covers lurek.window.openFileDialog
  -- @description openFileDialog function exists and is callable; in test mode the dialog is expected to return nil (no UI).
  it("openFileDialog is callable and returns nil or string in headless mode", function()
    local result = lurek.window.openFileDialog({ title = "Test", multiple = false })
    expect_true(result == nil or type(result) == "string", "result must be nil or string")
  end)
end)

test_summary()
