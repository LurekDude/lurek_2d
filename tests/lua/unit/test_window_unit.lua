-- Lurek2D Window API Tests

describe("lurek.window module exists", function()
    -- @tests lurek.window
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
    it("lurek.window is a table", function()
        expect_type("table", lurek.window)
    end)
end)

describe("lurek.window basic functions", function()
    -- @covers lurek.window.getTitle
    it("getTitle is a function", function()
        expect_type("function", lurek.window.getTitle)
    end)

    -- @covers lurek.window.getTitle
    it("getTitle returns a string", function()
        local title = lurek.window.getTitle()
        expect_type("string", title)
    end)

    -- @covers lurek.window.getDimensions
    it("getDimensions is a function", function()
        expect_type("function", lurek.window.getDimensions)
    end)

    -- @covers lurek.window.getDimensions
    it("getDimensions returns two numbers", function()
        local w, h = lurek.window.getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers lurek.window.getDimensions
    it("getDimensions returns positive values", function()
        local w, h = lurek.window.getDimensions()
        expect_true(w > 0, "width > 0")
        expect_true(h > 0, "height > 0")
    end)

    -- @covers lurek.window.getWidth
    it("getWidth is a function", function()
        expect_type("function", lurek.window.getWidth)
    end)

    -- @covers lurek.window.getWidth
    it("getWidth returns a number", function()
        expect_type("number", lurek.window.getWidth())
    end)

    -- @covers lurek.window.getHeight
    it("getHeight is a function", function()
        expect_type("function", lurek.window.getHeight)
    end)

    -- @covers lurek.window.getHeight
    it("getHeight returns a number", function()
        expect_type("number", lurek.window.getHeight())
    end)
end)

describe("lurek.window fullscreen", function()
    -- @covers lurek.window.setFullscreen
    it("setFullscreen is a function", function()
        expect_type("function", lurek.window.setFullscreen)
    end)

    -- @covers lurek.window.getFullscreen
    it("getFullscreen is a function", function()
        expect_type("function", lurek.window.getFullscreen)
    end)

    -- @covers lurek.window.getFullscreen
    it("getFullscreen returns bool and string", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_type("boolean", fs)
        expect_type("string", ft)
    end)

    -- @covers lurek.window.getFullscreen
    it("getFullscreen default is false/desktop", function()
        local fs, ft = lurek.window.getFullscreen()
        expect_equal(false, fs)
        expect_equal("desktop", ft)
    end)

    -- @covers lurek.window.isOpen
    it("isOpen always returns true", function()
        expect_equal(true, lurek.window.isOpen())
    end)
end)

describe("lurek.window vsync", function()
    -- @covers lurek.window.setVSync
    it("setVSync is a function", function()
        expect_type("function", lurek.window.setVSync)
    end)

    -- @covers lurek.window.getVSync
    it("getVSync is a function", function()
        expect_type("function", lurek.window.getVSync)
    end)

    -- @covers lurek.window.getVSync
    it("getVSync returns default 1", function()
        expect_equal(1, lurek.window.getVSync())
    end)
end)

describe("lurek.window state queries", function()
    -- @covers lurek.window.hasFocus
    it("hasFocus is a function", function()
        expect_type("function", lurek.window.hasFocus)
    end)

    -- @covers lurek.window.hasFocus
    it("hasFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasFocus())
    end)

    -- @covers lurek.window.hasFocus
    it("hasFocus default is true", function()
        expect_equal(true, lurek.window.hasFocus())
    end)

    -- @covers lurek.window.hasMouseFocus
    it("hasMouseFocus is a function", function()
        expect_type("function", lurek.window.hasMouseFocus)
    end)

    -- @covers lurek.window.hasMouseFocus
    it("hasMouseFocus returns boolean", function()
        expect_type("boolean", lurek.window.hasMouseFocus())
    end)

    -- @covers lurek.window.isMinimized
    it("isMinimized is a function", function()
        expect_type("function", lurek.window.isMinimized)
    end)

    -- @covers lurek.window.isMinimized
    it("isMinimized default is false", function()
        expect_equal(false, lurek.window.isMinimized())
    end)

    -- @covers lurek.window.isMaximized
    it("isMaximized is a function", function()
        expect_type("function", lurek.window.isMaximized)
    end)

    -- @covers lurek.window.isMaximized
    it("isMaximized default is false", function()
        expect_equal(false, lurek.window.isMaximized())
    end)

    -- @covers lurek.window.isVisible
    it("isVisible is a function", function()
        expect_type("function", lurek.window.isVisible)
    end)

    -- @covers lurek.window.isVisible
    it("isVisible default is true", function()
        expect_equal(true, lurek.window.isVisible())
    end)
end)

describe("lurek.window minimize/maximize/restore", function()
    -- @covers lurek.window.minimize
    it("minimize is a function", function()
        expect_type("function", lurek.window.minimize)
    end)

    -- @covers lurek.window.maximize
    it("maximize is a function", function()
        expect_type("function", lurek.window.maximize)
    end)

    -- @covers lurek.window.restore
    it("restore is a function", function()
        expect_type("function", lurek.window.restore)
    end)
end)

describe("lurek.window position", function()
    -- @covers lurek.window.getPosition
    it("getPosition is a function", function()
        expect_type("function", lurek.window.getPosition)
    end)

    -- @covers lurek.window.getPosition
    it("getPosition returns two numbers", function()
        local x, y = lurek.window.getPosition()
        expect_type("number", x)
        expect_type("number", y)
    end)

    -- @covers lurek.window.setPosition
    it("setPosition is a function", function()
        expect_type("function", lurek.window.setPosition)
    end)

    -- @covers lurek.window.getDisplayCount
    it("getDisplayCount returns a number", function()
        local n = lurek.window.getDisplayCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least 1 display")
    end)

    -- @covers lurek.window.getDesktopDimensions
    it("getDesktopDimensions returns two numbers", function()
        local w, h = lurek.window.getDesktopDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)
end)

describe("lurek.window DPI", function()
    -- @covers lurek.window.getDPIScale
    it("getDPIScale returns a number", function()
        local s = lurek.window.getDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale > 0")
    end)

    -- @covers lurek.window.getDPIScale
    it("getDPIScale default is 1.0", function()
        local s = lurek.window.getDPIScale()
        expect_equal(1, s)
    end)

    -- @covers lurek.window.toPixels
    it("toPixels converts correctly", function()
        local px = lurek.window.toPixels(100)
        expect_type("number", px)
        -- With default DPI scale of 1.0, should be 100
        expect_equal(100, px)
    end)

    -- @covers lurek.window.fromPixels
    it("fromPixels converts correctly", function()
        local val = lurek.window.fromPixels(100)
        expect_type("number", val)
        expect_equal(100, val)
    end)
end)

describe("lurek.window icon", function()
    -- @covers lurek.window.setIcon
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

describe("lurek.window mode", function()
    -- @covers lurek.window.setMode
    it("setMode is a function", function()
        expect_type("function", lurek.window.setMode)
    end)

    -- @covers lurek.window.getMode
    it("getMode is a function", function()
        expect_type("function", lurek.window.getMode)
    end)

    -- @covers lurek.window.getMode
    it("getMode returns width, height, flags", function()
        local w, h, flags = lurek.window.getMode()
        expect_type("number", w)
        expect_type("number", h)
        expect_type("table", flags)
    end)

    -- @covers lurek.window.getMode
    it("getMode flags contain fullscreen", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("boolean", flags.fullscreen)
    end)

    -- @covers lurek.window.getMode
    it("getMode flags contain fullscreentype", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("string", flags.fullscreentype)
    end)

    -- @covers lurek.window.getMode
    it("getMode flags contain vsync", function()
        local _, _, flags = lurek.window.getMode()
        expect_type("number", flags.vsync)
    end)
end)

describe("lurek.window close and attention", function()
    -- @covers lurek.window.close
    it("close is a function", function()
        expect_type("function", lurek.window.close)
    end)

    -- @covers lurek.window.requestAttention
    it("requestAttention is a function", function()
        expect_type("function", lurek.window.requestAttention)
    end)
end)

-- Phase 17: Missing Window Surface
describe("lurek.window missing surface (Phase 17)", function()
    -- @covers lurek.window.focus
    it("focus is a function", function()
        expect_type("function", lurek.window.focus)
    end)

    -- @covers lurek.window.focus
    it("focus can be called without error", function()
        lurek.window.focus()
    end)

    -- @covers lurek.window.getNativeDPIScale
    it("getNativeDPIScale is a function", function()
        expect_type("function", lurek.window.getNativeDPIScale)
    end)

    -- @covers lurek.window.getNativeDPIScale
    it("getNativeDPIScale returns a positive number", function()
        local s = lurek.window.getNativeDPIScale()
        expect_type("number", s)
        expect_true(s > 0, "DPI scale must be positive")
    end)

    -- @covers lurek.window.getDisplayOrientation
    it("getDisplayOrientation is a function", function()
        expect_type("function", lurek.window.getDisplayOrientation)
    end)

    -- @covers lurek.window.getDisplayOrientation
    it("getDisplayOrientation returns a string", function()
        local o = lurek.window.getDisplayOrientation()
        expect_type("string", o)
    end)

    -- @covers lurek.window.getDisplayOrientation
    it("getDisplayOrientation value is landscape or portrait variant", function()
        local o = lurek.window.getDisplayOrientation()
        local valid = (o == "landscape" or o == "portrait" or
                       o == "landscapeflipped" or o == "portraitflipped")
        expect_true(valid, "orientation must be landscape/portrait/landscapeflipped/portraitflipped")
    end)

    -- @covers lurek.window.getSafeArea
    it("getSafeArea is a function", function()
        expect_type("function", lurek.window.getSafeArea)
    end)

    -- @covers lurek.window.getSafeArea
    it("getSafeArea returns four numbers", function()
        local x, y, w, h = lurek.window.getSafeArea()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers lurek.window.getSafeArea
    it("getSafeArea w and h are positive on desktop", function()
        local _, _, w, h = lurek.window.getSafeArea()
        expect_true(w > 0, "safe area width > 0")
        expect_true(h > 0, "safe area height > 0")
    end)

    -- @covers lurek.window.getSystemTheme
    it("getSystemTheme is a function", function()
        expect_type("function", lurek.window.getSystemTheme)
    end)

    -- @covers lurek.window.getSystemTheme
    it("getSystemTheme returns a string", function()
        local t = lurek.window.getSystemTheme()
        expect_type("string", t)
    end)

    -- @covers lurek.window.isHighDPIAllowed
    it("isHighDPIAllowed is a function", function()
        expect_type("function", lurek.window.isHighDPIAllowed)
    end)

    -- @covers lurek.window.isHighDPIAllowed
    it("isHighDPIAllowed returns a boolean", function()
        expect_type("boolean", lurek.window.isHighDPIAllowed())
    end)
end)

describe("lurek.window DPI and dialog", function()
  -- @covers lurek.window.onDpiChange
  it("onDpiChange registers a callback without error", function()
    expect_no_error(function()
      lurek.window.onDpiChange(function(scale) end)
    end)
  end)

  -- @covers lurek.window.pollDpiChange
  it("pollDpiChange returns a positive number", function()
    local scale = lurek.window.pollDpiChange()
    expect_equal(type(scale), "number")
    expect_true(scale > 0, "DPI scale must be positive")
  end)

  -- @covers lurek.window.openFileDialog
    it("openFileDialog is callable and returns a table in headless mode", function()
    local result = lurek.window.openFileDialog({ title = "Test", multiple = false })
        expect_equal(type(result), "table")
  end)
end)

-- ============================================================
-- Merged from test_window_icon.lua
-- ============================================================

describe("lurek.window.setIcon  exposure", function()
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

describe("lurek.window.setIcon  validation", function()
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

-- ============================================================
-- Merged from test_window_scaling.lua
-- ============================================================

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

describe("Lua API coverage", function()
    -- @covers lurek.window.getFullscreenModes
    it("covers lurek.window.getFullscreenModes", function()
        expect_type("function", lurek.window.getFullscreenModes)
    end)

    -- @covers lurek.window.getDisplayName
    it("covers lurek.window.getDisplayName", function()
        local name = lurek.window.getDisplayName()
        expect_type("string", name)
        expect_true(#name > 0, "display name should not be empty")
    end)

    -- @covers lurek.window.getPixelDimensions
    it("covers lurek.window.getPixelDimensions", function()
        local pixel_w, pixel_h = lurek.window.getPixelDimensions()
        local logical_w, logical_h = lurek.window.getDimensions()
        local scale = lurek.window.getDPIScale()

        expect_type("number", pixel_w)
        expect_type("number", pixel_h)
        expect_equal(math.floor(logical_w * scale + 0.5), pixel_w)
        expect_equal(math.floor(logical_h * scale + 0.5), pixel_h)
    end)

    -- @covers lurek.window.showMessageBox
    it("covers lurek.window.showMessageBox", function()
        expect_type("function", lurek.window.showMessageBox)
    end)

end)

describe("lurek.window.setTitle", function()
    it("updates title without error", function()
        -- @covers lurek.window.setTitle
        local title = lurek.window.getTitle()
        expect_no_error(function()
            lurek.window.setTitle(title)
        end)
        expect_type("string", lurek.window.getTitle())
    end)
end)
describe("lurek.window.isFullscreen", function()
    it("matches the fullscreen flag from getFullscreen", function()
        -- @covers lurek.window.isFullscreen
        local fullscreen_flag = lurek.window.isFullscreen()
        local expected_flag = select(1, lurek.window.getFullscreen())
        expect_type("boolean", fullscreen_flag)
        expect_equal(expected_flag, fullscreen_flag)
    end)
end)

describe("lurek.window.isResizable", function()
    it("returns a boolean", function()
        -- @covers lurek.window.isResizable
        expect_type("boolean", lurek.window.isResizable())
    end)
end)

test_summary()
