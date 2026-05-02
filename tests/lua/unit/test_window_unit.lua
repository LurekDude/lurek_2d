-- Lurek2D Window API Tests

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

describe("lurek.window DPI and dialog", function()
  it("onDpiChange registers a callback without error", function()
    expect_no_error(function()
      lurek.window.onDpiChange(function(scale) end)
    end)
  end)

  it("pollDpiChange returns a positive number", function()
    local scale = lurek.window.pollDpiChange()
    expect_equal(type(scale), "number")
    expect_true(scale > 0, "DPI scale must be positive")
  end)

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
    it("covers lurek.window.getFullscreenModes", function()
        expect_type("function", lurek.window.getFullscreenModes)
    end)

    it("covers lurek.window.getDisplayName", function()
        local name = lurek.window.getDisplayName()
        expect_type("string", name)
        expect_true(#name > 0, "display name should not be empty")
    end)

    it("covers lurek.window.getPixelDimensions", function()
        local pixel_w, pixel_h = lurek.window.getPixelDimensions()
        local logical_w, logical_h = lurek.window.getDimensions()
        local scale = lurek.window.getDPIScale()

        expect_type("number", pixel_w)
        expect_type("number", pixel_h)
        expect_equal(math.floor(logical_w * scale + 0.5), pixel_w)
        expect_equal(math.floor(logical_h * scale + 0.5), pixel_h)
    end)

    it("covers lurek.window.showMessageBox", function()
        expect_type("function", lurek.window.showMessageBox)
    end)

end)

describe("lurek.window.setTitle", function()
    it("updates title without error", function()
        local title = lurek.window.getTitle()
        expect_no_error(function()
            lurek.window.setTitle(title)
        end)
        expect_type("string", lurek.window.getTitle())
    end)
end)
describe("lurek.window.isFullscreen", function()
    it("matches the fullscreen flag from getFullscreen", function()
        local fullscreen_flag = lurek.window.isFullscreen()
        local expected_flag = select(1, lurek.window.getFullscreen())
        expect_type("boolean", fullscreen_flag)
        expect_equal(expected_flag, fullscreen_flag)
    end)
end)

describe("lurek.window.isResizable", function()
    it("returns a boolean", function()
        expect_type("boolean", lurek.window.isResizable())
    end)
end)
test_summary()
