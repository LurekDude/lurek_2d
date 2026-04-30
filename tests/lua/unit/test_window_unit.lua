-- Lurek2D Window API Tests

-- @description Covers suite: lurek.window module exists.
describe("lurek.window module exists", function()
    -- @tests lurek.window
    -- @tests lurek.window.close
    -- @tests lurek.window.focus
    -- @tests lurek.window.fromPixels
    -- @tests lurek.window.getDPIScale
    -- @tests lurek.window.getDesktopDimensions
    -- @tests lurek.window.getDimensions
    -- @tests lurek.window.getDisplayCount
    -- @tests lurek.window.getDisplayOrientation
    -- @tests lurek.window.getFullscreen
    -- @tests lurek.window.getHeight
    -- @tests lurek.window.getMode
    -- @tests lurek.window.getNativeDPIScale
    -- @tests lurek.window.getPosition
    -- @tests lurek.window.getSafeArea
    -- @tests lurek.window.getSystemTheme
    -- @tests lurek.window.getTitle
    -- @tests lurek.window.getVSync
    -- @tests lurek.window.getWidth
    -- @tests lurek.window.hasFocus
    -- @tests lurek.window.hasMouseFocus
    -- @tests lurek.window.isHighDPIAllowed
    -- @tests lurek.window.isMaximized
    -- @tests lurek.window.isMinimized
    -- @tests lurek.window.isOpen
    -- @tests lurek.window.isVisible
    -- @tests lurek.window.maximize
    -- @tests lurek.window.minimize
    -- @tests lurek.window.requestAttention
    -- @tests lurek.window.restore
    -- @tests lurek.window.setFullscreen
    -- @tests lurek.window.setIcon
    -- @tests lurek.window.setMode
    -- @tests lurek.window.setPosition
    -- @tests lurek.window.setVSync
    -- @tests lurek.window.toPixels
    -- @description Verifies the window namespace is available as a Lua table.
    it("lurek.window is a table", function()
        expect_type("table", lurek.window)
    end)
end)

-- @description Covers suite: lurek.window basic functions.
describe("lurek.window basic functions", function()
    -- @tests lurek.window.getTitle
    -- @description Verifies getTitle is exposed.
    it("getTitle is a function", function()
        expect_type("function", lurek.window.getTitle)
    end)

    -- @tests lurek.window.getTitle
    -- @description Verifies getTitle returns a string title.
    it("getTitle returns a string", function()
        local title = lurek.window.getTitle()
        expect_type("string", title)
    end)

    -- @tests lurek.window.getDimensions
    -- @description Verifies getDimensions is exposed.
    it("getDimensions is a function", function()
        expect_type("function", lurek.window.getDimensions)
    end)

    -- @tests lurek.window.getDimensions
    -- @description Verifies getDimensions returns numeric width and height values.
    it("getDimensions returns two numbers", function()
        local w, h = lurek.window.getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @tests lurek.window.getDimensions
    -- @description Verifies getDimensions reports positive size values.
    it("getDimensions returns positive values", function()
        local w, h = lurek.window.getDimensions()
        expect_true(w > 0, "width > 0")
        expect_true(h > 0, "height > 0")
    end)

    -- @tests lurek.window.getWidth
    -- @description Verifies getWidth is exposed.
    it("getWidth is a function", function()
        expect_type("function", lurek.window.getWidth)
    end)

    -- @tests lurek.window.getWidth
    -- @description Verifies getWidth returns a number.
    it("getWidth returns a number", function()
        expect_type("number", lurek.window.getWidth())
    end)

    -- @tests lurek.window.getHeight
    -- @description Verifies getHeight is exposed.
    it("getHeight is a function", function()
        expect_type("function", lurek.window.getHeight)
    end)

    -- @tests lurek.window.getHeight
    -- @description Verifies getHeight returns a number.
    it("getHeight returns a number", function()
        expect_type("number", lurek.window.getHeight())
    end)
end)

-- @description Covers suite: lurek.window fullscreen.
describe("lurek.window fullscreen", function()
    -- @tests lurek.window.setFullscreen
    -- @description Verifies setFullscreen is exposed.
    it("setFullscreen is a function", function()
        expect_type("function", lurek.window.setFullscreen)
    end)

    -- @tests lurek.window.getFullscreen
    -- @description Verifies getFullscreen is exposed.
    it("getFullscreen is a function", function()
        expect_type("function", lurek.window.getFullscreen)
    end)

    -- @tests lurek.window.getFullscreen
    -- @description Verifies getFullscreen returns a boolean flag plus a fullscreen type string.
    it("getFullscreen returns bool and string", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_type("boolean", fs)
        expect_type("string", ft)
    end)

    -- @tests lurek.window.getFullscreen
    -- @description Verifies the default fullscreen state is false with desktop mode.
    it("getFullscreen default is false/desktop", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_equal(false, fs)
        expect_equal("desktop", ft)
    end)

    -- @tests lurek.window.isOpen
    -- @description Verifies isOpen reports true in the headless test harness.
    it("isOpen always returns true", function()
        expect_equal(true, lurek.window.isOpen())
    end)
end)

-- @description Covers suite: lurek.window vsync.
describe("lurek.window vsync", function()
    -- @tests lurek.window.setVSync
    -- @description Verifies setVSync is exposed.
    it("setVSync is a function", function()
        expect_type("function", lurek.window.setVSync)
    end)

    -- @tests lurek.window.getVSync
    -- @description Verifies getVSync is exposed.
    it("getVSync is a function", function()
        expect_type("function", lurek.window.getVSync)
    end)

    -- @tests lurek.window.getVSync
    -- @description Verifies getVSync defaults to mode 1.
    it("getVSync returns default 1", function()
        expect_equal(1, lurek.window.getVSync())
    end)
end)

-- @description Covers suite: lurek.window state queries.
describe("lurek.window state queries", function()
    -- @tests lurek.window.hasFocus
    -- @description Verifies hasFocus is exposed.
    it("hasFocus is a function", function()
        expect_type("function", lurek.window.hasFocus)
    end)

    -- @tests lurek.window.hasFocus
    -- @description Verifies hasFocus returns a boolean value.
    it("hasFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasFocus())
    end)

    -- @tests lurek.window.hasFocus
    -- @description Verifies the headless window reports focused by default.
    it("hasFocus default is true", function()
        expect_equal(true, lurek.window.hasFocus())
    end)

    -- @tests lurek.window.hasMouseFocus
    -- @description Verifies hasMouseFocus is exposed.
    it("hasMouseFocus is a function", function()
        expect_type("function", lurek.window.hasMouseFocus)
    end)

    -- @tests lurek.window.hasMouseFocus
    -- @description Verifies hasMouseFocus returns a boolean value.
    it("hasMouseFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasMouseFocus())
    end)

    -- @tests lurek.window.isMinimized
    -- @description Verifies isMinimized is exposed.
    it("isMinimized is a function", function()
        expect_type("function", lurek.window.isMinimized)
    end)

    -- @tests lurek.window.isMinimized
    -- @description Verifies the window is not minimized by default.
    it("isMinimized default is false", function()
        expect_equal(false, lurek.window.isMinimized())
    end)

    -- @tests lurek.window.isMaximized
    -- @description Verifies isMaximized is exposed.
    it("isMaximized is a function", function()
        expect_type("function", lurek.window.isMaximized)
    end)

    -- @tests lurek.window.isMaximized
    -- @description Verifies the window is not maximized by default.
    it("isMaximized default is false", function()
        expect_equal(false, lurek.window.isMaximized())
    end)

    -- @tests lurek.window.isVisible
    -- @description Verifies isVisible is exposed.
    it("isVisible is a function", function()
        expect_type("function", lurek.window.isVisible)
    end)

    -- @tests lurek.window.isVisible
    -- @description Verifies the window is visible by default.
    it("isVisible default is true", function()
        expect_equal(true, lurek.window.isVisible())
    end)
end)

-- @description Covers suite: lurek.window minimize/maximize/restore.
describe("lurek.window minimize/maximize/restore", function()
    -- @tests lurek.window.minimize
    -- @description Verifies minimize is exposed.
    it("minimize is a function", function()
        expect_type("function", lurek.window.minimize)
    end)

    -- @tests lurek.window.maximize
    -- @description Verifies maximize is exposed.
    it("maximize is a function", function()
        expect_type("function", lurek.window.maximize)
    end)

    -- @tests lurek.window.restore
    -- @description Verifies restore is exposed.
    it("restore is a function", function()
        expect_type("function", lurek.window.restore)
    end)
end)

-- @description Covers suite: lurek.window position.
describe("lurek.window position", function()
    -- @tests lurek.window.getPosition
    -- @description Verifies getPosition is exposed.
    it("getPosition is a function", function()
        expect_type("function", lurek.window.getPosition)
    end)

    -- @tests lurek.window.getPosition
    -- @description Verifies getPosition returns numeric coordinates.
    it("getPosition returns two numbers", function()
        local x, y = lurek.window.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @tests lurek.window.setPosition
    -- @description Verifies setPosition is exposed.
    it("setPosition is a function", function()
        expect_type("function", lurek.window.setPosition)
    end)

    -- @tests lurek.window.getDisplayCount
    -- @description Verifies getDisplayCount returns a numeric monitor count of at least one.
    it("getDisplayCount returns a number", function()
        local n = lurek.window.getDisplayCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least 1 display")
    end)

    -- @tests lurek.window.getDesktopDimensions
    -- @description Verifies getDesktopDimensions returns numeric desktop bounds.
    it("getDesktopDimensions returns two numbers", function()
        local w, h = lurek.window.getDesktopDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)
end)

-- @description Covers suite: lurek.window DPI.
describe("lurek.window DPI", function()
    -- @tests lurek.window.getDPIScale
    -- @description Verifies getDPIScale returns a positive numeric scale.
    it("getDPIScale returns a number", function()
        local s = lurek.window.getDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale > 0")
    end)

    -- @tests lurek.window.getDPIScale
    -- @description Verifies the default DPI scale is 1.0 in the headless harness.
    it("getDPIScale default is 1.0", function()
        local s = lurek.window.getDPIScale()
        expect_equal(1, s)
    end)

    -- @tests lurek.window.toPixels
    -- @description Verifies toPixels converts logical units to numeric pixel units.
    it("toPixels converts correctly", function()
        local px = lurek.window.toPixels(100)
        expect_type("number", px)
        -- With default DPI scale of 1.0, should be 100
        expect_equal(100, px)
    end)

    -- @tests lurek.window.fromPixels
    -- @description Verifies fromPixels converts numeric pixel units back to logical units.
    it("fromPixels converts correctly", function()
        local val = lurek.window.fromPixels(100)
        expect_type("number", val)
        expect_equal(100, val)
    end)
end)

-- @description Covers suite: lurek.window icon.
describe("lurek.window icon", function()
    -- @tests lurek.window.setIcon
    -- @description Verifies setIcon is exposed.
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

-- @description Covers suite: lurek.window mode.
describe("lurek.window mode", function()
    -- @tests lurek.window.setMode
    -- @description Verifies setMode is exposed.
    it("setMode is a function", function()
        expect_type("function", lurek.window.setMode)
    end)

    -- @tests lurek.window.getMode
    -- @description Verifies getMode is exposed.
    it("getMode is a function", function()
        expect_type("function", lurek.window.getMode)
    end)

    -- @tests lurek.window.getMode
    -- @description Verifies getMode returns numeric dimensions plus a flags table.
    it("getMode returns width, height, flags", function()
        local w, h, flags = lurek.window.getMode()
        expect_type("number", w)
        expect_type("number", h)
        expect_type("table", flags)
    end)

    -- @tests lurek.window.getMode
    -- @description Verifies getMode exposes a fullscreen boolean flag.
    it("getMode flags contain fullscreen", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("boolean", flags.fullscreen)
    end)

    -- @tests lurek.window.getMode
    -- @description Verifies getMode exposes a fullscreentype string flag.
    it("getMode flags contain fullscreentype", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("string", flags.fullscreentype)
    end)

    -- @tests lurek.window.getMode
    -- @description Verifies getMode exposes a numeric vsync flag.
    it("getMode flags contain vsync", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("number", flags.vsync)
    end)
end)

-- @description Covers suite: lurek.window close and attention.
describe("lurek.window close and attention", function()
    -- @tests lurek.window.close
    -- @description Verifies close is exposed.
    it("close is a function", function()
        expect_type("function", lurek.window.close)
    end)

    -- @tests lurek.window.requestAttention
    -- @description Verifies requestAttention is exposed.
    it("requestAttention is a function", function()
        expect_type("function", lurek.window.requestAttention)
    end)
end)

-- Phase 17: Missing Window Surface
-- @description Covers suite: lurek.window missing surface (Phase 17).
describe("lurek.window missing surface (Phase 17)", function()
    -- @tests lurek.window.focus
    -- @description Verifies focus is exposed.
    it("focus is a function", function()
        expect_type("function", lurek.window.focus)
    end)

    -- @tests lurek.window.focus
    -- @description Verifies focus can be invoked without error.
    it("focus can be called without error", function()
        lurek.window.focus()
    end)

    -- @tests lurek.window.getNativeDPIScale
    -- @description Verifies getNativeDPIScale is exposed.
    it("getNativeDPIScale is a function", function()
        expect_type("function", lurek.window.getNativeDPIScale)
    end)

    -- @tests lurek.window.getNativeDPIScale
    -- @description Verifies getNativeDPIScale returns a positive number.
    it("getNativeDPIScale returns a positive number", function()
        local s = lurek.window.getNativeDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale must be positive")
    end)

    -- @tests lurek.window.getDisplayOrientation
    -- @description Verifies getDisplayOrientation is exposed.
    it("getDisplayOrientation is a function", function()
        expect_type("function", lurek.window.getDisplayOrientation)
    end)

    -- @tests lurek.window.getDisplayOrientation
    -- @description Verifies getDisplayOrientation returns a string enum value.
    it("getDisplayOrientation returns a string", function()
        local o = lurek.window.getDisplayOrientation()
        expect_type("string", o)
    end)

    -- @tests lurek.window.getDisplayOrientation
    -- @description Verifies display orientation is one of the expected desktop/mobile variants.
    it("getDisplayOrientation value is landscape or portrait variant", function()
        local o = lurek.window.getDisplayOrientation()
        local valid = (o == "landscape" or o == "portrait" or
                       o == "landscapeflipped" or o == "portraitflipped")
        expect_true(valid, "orientation must be landscape/portrait/landscapeflipped/portraitflipped")
    end)

    -- @tests lurek.window.getSafeArea
    -- @description Verifies getSafeArea is exposed.
    it("getSafeArea is a function", function()
        expect_type("function", lurek.window.getSafeArea)
    end)

    -- @tests lurek.window.getSafeArea
    -- @description Verifies getSafeArea returns numeric x, y, width, and height values.
    it("getSafeArea returns four numbers", function()
        local x, y, w, h = lurek.window.getSafeArea()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @tests lurek.window.getSafeArea
    -- @description Verifies the reported safe-area width and height are positive.
    it("getSafeArea w and h are positive on desktop", function()
        local _, _, w, h = lurek.window.getSafeArea()
        expect_true(w > 0, "safe area width > 0")
        expect_true(h > 0, "safe area height > 0")
    end)

    -- @tests lurek.window.getSystemTheme
    -- @description Verifies getSystemTheme is exposed.
    it("getSystemTheme is a function", function()
        expect_type("function", lurek.window.getSystemTheme)
    end)

    -- @tests lurek.window.getSystemTheme
    -- @description Verifies getSystemTheme returns a string.
    it("getSystemTheme returns a string", function()
        local t = lurek.window.getSystemTheme()
        expect_type("string", t)
    end)

    -- @tests lurek.window.isHighDPIAllowed
    -- @description Verifies isHighDPIAllowed is exposed.
    it("isHighDPIAllowed is a function", function()
        expect_type("function", lurek.window.isHighDPIAllowed)
    end)

    -- @tests lurek.window.isHighDPIAllowed
    -- @description Verifies isHighDPIAllowed returns a boolean capability flag.
    it("isHighDPIAllowed returns a boolean", function()
        expect_type("boolean", lurek.window.isHighDPIAllowed())
    end)
end)

-- @description Tests for new window features: onDpiChange, pollDpiChange, openFileDialog.
describe("lurek.window DPI and dialog", function()
  -- @tests lurek.window.onDpiChange
  -- @description Registers an onDpiChange callback without error.
  it("onDpiChange registers a callback without error", function()
    expect_no_error(function()
      lurek.window.onDpiChange(function(scale) end)
    end)
  end)

  -- @tests lurek.window.pollDpiChange
  -- @description pollDpiChange returns the current DPI scale without error.
  it("pollDpiChange returns a positive number", function()
    local scale = lurek.window.pollDpiChange()
    expect_equal(type(scale), "number")
    expect_true(scale > 0, "DPI scale must be positive")
  end)

  -- @tests lurek.window.openFileDialog
    -- @description openFileDialog function exists and is callable; in test mode the dialog is expected to return an empty table.
    it("openFileDialog is callable and returns a table in headless mode", function()
    local result = lurek.window.openFileDialog({ title = "Test", multiple = false })
        expect_equal(type(result), "table")
  end)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_window_icon.lua
-- ═══════════════════════════════════════════════════════════════════════

describe("lurek.window.setIcon — exposure", function()
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

describe("lurek.window.setIcon — validation", function()
    it("raises error for empty path", function()
        expect_error(function()
            lurek.window.setIcon("")
        end)
    end)

    it("raises error for nonexistent file", function()
        expect_error(function()
            lurek.window.setIcon("nonexistent_icon_file.png")
        end)
    end)

    it("raises error for path that does not exist regardless of extension", function()
        expect_error(function()
            lurek.window.setIcon("missing_icon.bmp")
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_window_scaling.lua
-- ═══════════════════════════════════════════════════════════════════════

describe("lurek.window scaling API exists", function()
    it("setScaleMode is a function", function()
        expect_type("function", lurek.window.setScaleMode)
    end)

    it("getScaleMode is a function", function()
        expect_type("function", lurek.window.getScaleMode)
    end)

    it("getScaleInfo is a function", function()
        expect_type("function", lurek.window.getScaleInfo)
    end)

    it("getGameWidth is a function", function()
        expect_type("function", lurek.window.getGameWidth)
    end)

    it("getGameHeight is a function", function()
        expect_type("function", lurek.window.getGameHeight)
    end)
end)

describe("lurek.window.getScaleMode defaults", function()
    it("returns a string", function()
        local mode = lurek.window.getScaleMode()
        expect_type("string", mode)
    end)

    it("default scale mode is none", function()
        local mode = lurek.window.getScaleMode()
        expect_equal("none", mode)
    end)
end)

describe("lurek.window.setScaleMode", function()
    it("accepts letterbox mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("letterbox")
        end)
    end)

    it("accepts stretch mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("stretch")
        end)
    end)

    it("accepts pixel mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("pixel")
        end)
    end)

    it("accepts none mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("none")
        end)
    end)

    it("silently ignores an invalid mode without error", function()
        local before = lurek.window.getScaleMode()
        expect_no_error(function()
            lurek.window.setScaleMode("invalid_mode")
        end)
        local after = lurek.window.getScaleMode()
        expect_equal(before, after)
    end)

    it("silently ignores an empty string without error", function()
        local before = lurek.window.getScaleMode()
        expect_no_error(function()
            lurek.window.setScaleMode("")
        end)
        local after = lurek.window.getScaleMode()
        expect_equal(before, after)
    end)
end)

describe("lurek.window.getGameWidth", function()
    it("returns a number", function()
        local w = lurek.window.getGameWidth()
        expect_type("number", w)
    end)

    it("returns a positive value", function()
        local w = lurek.window.getGameWidth()
        expect_true(w > 0, "game_width must be positive, got " .. tostring(w))
    end)
end)

describe("lurek.window.getGameHeight", function()
    it("returns a number", function()
        local h = lurek.window.getGameHeight()
        expect_type("number", h)
    end)

    it("returns a positive value", function()
        local h = lurek.window.getGameHeight()
        expect_true(h > 0, "game_height must be positive, got " .. tostring(h))
    end)
end)

describe("lurek.window.getScaleInfo", function()
    it("returns a table", function()
        local info = lurek.window.getScaleInfo()
        expect_type("table", info)
    end)

    it("table contains scale_x field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.scale_x)
    end)

    it("table contains scale_y field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.scale_y)
    end)

    it("table contains offset_x field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.offset_x)
    end)

    it("table contains offset_y field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.offset_y)
    end)

    it("table contains game_width field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.game_width)
    end)

    it("table contains game_height field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.game_height)
    end)

    it("scale_x is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.scale_x)
    end)

    it("scale_y is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.scale_y)
    end)

    it("offset_x is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.offset_x)
    end)

    it("offset_y is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.offset_y)
    end)

    it("game_width matches getGameWidth()", function()
        local info = lurek.window.getScaleInfo()
        local w = lurek.window.getGameWidth()
        expect_near(w, info.game_width, 0.001)
    end)

    it("game_height matches getGameHeight()", function()
        local info = lurek.window.getScaleInfo()
        local h = lurek.window.getGameHeight()
        expect_near(h, info.game_height, 0.001)
    end)

    it("default scale_x is 1.0 with none mode", function()
        local info = lurek.window.getScaleInfo()
        if lurek.window.getScaleMode() == "none" then
            expect_near(1.0, info.scale_x, 0.001)
        end
    end)

    it("default scale_y is 1.0 with none mode", function()
        local info = lurek.window.getScaleInfo()
        if lurek.window.getScaleMode() == "none" then
            expect_near(1.0, info.scale_y, 0.001)
        end
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.window.getFullscreenModes
    it("covers lurek.window.getFullscreenModes", function()
        expect_type("function", lurek.window.getFullscreenModes)
    end)

    -- @tests lurek.window.getDisplayName
    it("covers lurek.window.getDisplayName", function()
        local name = lurek.window.getDisplayName()
        expect_type("string", name)
        expect_true(#name > 0, "display name should not be empty")
    end)

    -- @tests lurek.window.getPixelDimensions
    it("covers lurek.window.getPixelDimensions", function()
        local pixel_w, pixel_h = lurek.window.getPixelDimensions()
        local logical_w, logical_h = lurek.window.getDimensions()
        local scale = lurek.window.getDPIScale()

        expect_type("number", pixel_w)
        expect_type("number", pixel_h)
        expect_equal(math.floor(logical_w * scale + 0.5), pixel_w)
        expect_equal(math.floor(logical_h * scale + 0.5), pixel_h)
    end)

    -- @tests lurek.window.showMessageBox
    it("covers lurek.window.showMessageBox", function()
        expect_type("function", lurek.window.showMessageBox)
    end)

end)

describe("lurek.window.setTitle", function()
    it("updates title without error", function()
        -- @tests lurek.window.setTitle
        local title = lurek.window.getTitle()
        expect_no_error(function()
            lurek.window.setTitle(title)
        end)
        expect_type("string", lurek.window.getTitle())
    end)
end)
describe("lurek.window.isFullscreen", function()
    it("matches the fullscreen flag from getFullscreen", function()
        -- @tests lurek.window.isFullscreen
        local fullscreen_flag = lurek.window.isFullscreen()
        local expected_flag = select(1, lurek.window.getFullscreen())
        expect_type("boolean", fullscreen_flag)
        expect_equal(expected_flag, fullscreen_flag)
    end)
end)

describe("lurek.window.isResizable", function()
    it("returns a boolean", function()
        -- @tests lurek.window.isResizable
        expect_type("boolean", lurek.window.isResizable())
    end)
end)
