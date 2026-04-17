-- content/examples/window.lua
-- Lurek2D lurek.window API Reference
-- Run with: cargo run -- content/examples/window
--
-- Scenario: A game launcher that detects display configurations, sets up
-- the window with proper DPI scaling, handles fullscreen toggling,
-- and provides a settings screen for resolution/mode selection.

print("=== lurek.window — Window Management ===\n")

-- =============================================================================
-- Window Properties
-- =============================================================================

--@api-stub: lurek.window.setTitle
lurek.window.setTitle("Dragon's Quest — Main Menu")

--@api-stub: lurek.window.getTitle
print("title: " .. lurek.window.getTitle())

--@api-stub: lurek.window.getWidth
print("width: " .. lurek.window.getWidth())

--@api-stub: lurek.window.getHeight
print("height: " .. lurek.window.getHeight())

--@api-stub: lurek.window.getDimensions
local w, h = lurek.window.getDimensions()
print("window: " .. w .. "x" .. h)

--@api-stub: lurek.window.getGameWidth
print("game width: " .. lurek.window.getGameWidth())

--@api-stub: lurek.window.getGameHeight
print("game height: " .. lurek.window.getGameHeight())

--@api-stub: lurek.window.getPixelDimensions
local pw, ph = lurek.window.getPixelDimensions()
print("pixel dims: " .. pw .. "x" .. ph)

--@api-stub: lurek.window.getPosition
local x, y = lurek.window.getPosition()
print("position: " .. x .. "," .. y)

--@api-stub: lurek.window.setPosition
lurek.window.setPosition(100, 100)

-- =============================================================================
-- Window State
-- =============================================================================

--@api-stub: lurek.window.isOpen
print("open: " .. tostring(lurek.window.isOpen()))

--@api-stub: lurek.window.hasFocus
print("has focus: " .. tostring(lurek.window.hasFocus()))

--@api-stub: lurek.window.hasMouseFocus
print("mouse focus: " .. tostring(lurek.window.hasMouseFocus()))

--@api-stub: lurek.window.isMinimized
print("minimized: " .. tostring(lurek.window.isMinimized()))

--@api-stub: lurek.window.isMaximized
print("maximized: " .. tostring(lurek.window.isMaximized()))

--@api-stub: lurek.window.isVisible
print("visible: " .. tostring(lurek.window.isVisible()))

--@api-stub: lurek.window.isResizable
print("resizable: " .. tostring(lurek.window.isResizable()))

-- =============================================================================
-- Window Actions
-- =============================================================================

--@api-stub: lurek.window.minimize
-- lurek.window.minimize()

--@api-stub: lurek.window.maximize
-- lurek.window.maximize()

--@api-stub: lurek.window.restore
-- lurek.window.restore()

--@api-stub: lurek.window.focus
lurek.window.focus()

--@api-stub: lurek.window.requestAttention
lurek.window.requestAttention()

--@api-stub: lurek.window.close
-- lurek.window.close()  -- don't actually close

--@api-stub: lurek.window.setIcon
lurek.window.setIcon("assets/icons/game_icon.png")

-- =============================================================================
-- Fullscreen
-- =============================================================================

--@api-stub: lurek.window.setFullscreen
lurek.window.setFullscreen(false)

--@api-stub: lurek.window.getFullscreen
print("fullscreen type: " .. tostring(lurek.window.getFullscreen()))

--@api-stub: lurek.window.isFullscreen
print("is fullscreen: " .. tostring(lurek.window.isFullscreen()))

-- =============================================================================
-- VSync
-- =============================================================================

--@api-stub: lurek.window.setVSync
lurek.window.setVSync(true)

--@api-stub: lurek.window.getVSync
print("vsync: " .. tostring(lurek.window.getVSync()))

-- =============================================================================
-- Window Mode
-- =============================================================================

--@api-stub: lurek.window.setMode
lurek.window.setMode(1280, 720, {resizable = true, vsync = true})

--@api-stub: lurek.window.getMode
local mw, mh, flags = lurek.window.getMode()
print("mode: " .. mw .. "x" .. mh)

--@api-stub: lurek.window.getFullscreenModes
local modes = lurek.window.getFullscreenModes()
print("available modes: " .. #modes)

-- =============================================================================
-- Display Info
-- =============================================================================

--@api-stub: lurek.window.getDisplayCount
print("displays: " .. lurek.window.getDisplayCount())

--@api-stub: lurek.window.getDisplayName
print("display 1: " .. lurek.window.getDisplayName(1))

--@api-stub: lurek.window.getDesktopDimensions
local dw, dh = lurek.window.getDesktopDimensions()
print("desktop: " .. dw .. "x" .. dh)

--@api-stub: lurek.window.getDisplayOrientation
print("orientation: " .. lurek.window.getDisplayOrientation())

--@api-stub: lurek.window.getSafeArea
local sx, sy, sw, sh = lurek.window.getSafeArea()
print("safe area: " .. sx .. "," .. sy .. " " .. sw .. "x" .. sh)

-- =============================================================================
-- DPI & Scaling
-- =============================================================================

--@api-stub: lurek.window.getDPIScale
print("DPI scale: " .. lurek.window.getDPIScale())

--@api-stub: lurek.window.getNativeDPIScale
print("native DPI: " .. lurek.window.getNativeDPIScale())

--@api-stub: lurek.window.isHighDPIAllowed
print("high DPI: " .. tostring(lurek.window.isHighDPIAllowed()))

--@api-stub: lurek.window.toPixels
local px = lurek.window.toPixels(100)
print("100 units = " .. px .. " pixels")

--@api-stub: lurek.window.fromPixels
local units = lurek.window.fromPixels(200)
print("200 pixels = " .. units .. " units")

--@api-stub: lurek.window.getScaleInfo
local scale_info = lurek.window.getScaleInfo()
print("scale info: " .. tostring(scale_info))

--@api-stub: lurek.window.getScaleMode
print("scale mode: " .. lurek.window.getScaleMode())

--@api-stub: lurek.window.setScaleMode
lurek.window.setScaleMode("letterbox")

--@api-stub: lurek.window.onDpiChange
lurek.window.onDpiChange(function(new_dpi)
    print("DPI changed: " .. new_dpi)
end)

--@api-stub: lurek.window.pollDpiChange
lurek.window.pollDpiChange()

-- =============================================================================
-- System Integration
-- =============================================================================

--@api-stub: lurek.window.getSystemTheme
print("system theme: " .. lurek.window.getSystemTheme())

--@api-stub: lurek.window.showMessageBox
lurek.window.showMessageBox("Info", "Game saved successfully!", "info")

--@api-stub: lurek.window.openFileDialog
local path = lurek.window.openFileDialog("Open Save File", "*.sav")
print("selected file: " .. tostring(path))

print("\n-- window.lua example complete --")
