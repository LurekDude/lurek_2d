-- content/examples/window.lua
-- lurek.window API examples.
-- Run: cargo run -- content/examples/window.lua

--@api-stub: lurek.window.setTitle
-- Sets the window title bar text
do
  function lurek.init()
    lurek.window.setTitle("My Game - Forest Level")
  end
end

--@api-stub: lurek.window.getTitle
-- Returns the current window title bar text
do
  local base = lurek.window.getTitle()
  local paused = true
  if paused then
    lurek.window.setTitle(base .. " [PAUSED]")
  end
end

--@api-stub: lurek.window.getWidth
-- Returns the current window width in logical (DPI-independent) pixels
do
  local w = lurek.window.getWidth()
  local centre_x = w * 0.5
  lurek.log.info("hud centre x=" .. centre_x .. " (window width " .. w .. "px)", "ui")
end

--@api-stub: lurek.window.getHeight
-- Returns the current window height in logical (DPI-independent) pixels
do
  local h = lurek.window.getHeight()
  local hud_y = h - 48
  lurek.log.info("hud anchored at y=" .. hud_y, "ui")
end

--@api-stub: lurek.window.getDimensions
-- Returns the current window width and height in logical pixels
do
  local w, h = lurek.window.getDimensions()
  local aspect = w / h
  lurek.log.info("window " .. w .. "x" .. h .. " aspect=" .. aspect, "boot")
end

--@api-stub: lurek.window.setFullscreen
-- Enables or disables fullscreen mode
do
  function lurek.init()
    lurek.window.setFullscreen(true, "desktop")
  end
end

--@api-stub: lurek.window.getFullscreen
-- Returns the current fullscreen state and type
do
  local enabled, fstype = lurek.window.getFullscreen()
  if enabled then
    lurek.log.info("fullscreen on (" .. fstype .. ")", "video")
  else
    lurek.log.info("running windowed", "video")
  end
end

--@api-stub: lurek.window.isOpen
-- Returns whether the window is currently open
do
  if lurek.window.isOpen() then
    lurek.log.info("window is live, starting subsystems", "boot")
  end
end

--@api-stub: lurek.window.setVSync
-- Sets the vertical sync mode
do
  local benchmark = false
  lurek.window.setVSync(benchmark and 0 or 1)
end

--@api-stub: lurek.window.getVSync
-- Returns the current VSync mode
do
  local mode = lurek.window.getVSync()
  local label = ({ [-1] = "adaptive", [0] = "off", [1] = "on" })[mode] or "unknown"
  lurek.log.info("vsync=" .. label, "video")
end

--@api-stub: lurek.window.hasFocus
-- Returns whether the window currently has keyboard focus
do
  function lurek.process(dt)
    if not lurek.window.hasFocus() then
      return
    end
  end
end

--@api-stub: lurek.window.hasMouseFocus
-- Returns whether the mouse cursor is inside the window
do
  function lurek.process(dt)
    if lurek.window.hasMouseFocus() then
      lurek.log.debug("mouse inside window", "input")
    end
  end
end

--@api-stub: lurek.window.isMinimized
-- Returns whether the window is currently minimized to the taskbar
do
  function lurek.draw()
    if lurek.window.isMinimized() then
      return
    end
  end
end

--@api-stub: lurek.window.isMaximized
-- Returns whether the window is currently maximized
do
  if lurek.window.isMaximized() then
    lurek.log.info("window starts maximized", "boot")
  end
end

--@api-stub: lurek.window.isVisible
-- Returns whether the window is currently visible on screen
do
  function lurek.draw()
    if not lurek.window.isVisible() then
      return
    end
  end
end

--@api-stub: lurek.window.minimize
-- Minimizes the window to the taskbar
do
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("f11") then
      lurek.window.minimize()
    end
  end
end

--@api-stub: lurek.window.maximize
-- Maximizes the window to fill the screen
do
  function lurek.init()
    lurek.window.maximize()
  end
end

--@api-stub: lurek.window.restore
-- Restores the window from minimized or maximized state to its previous size and position
do
  function lurek.init()
    lurek.window.restore()
    lurek.window.setMode(1280, 720)
  end
end

--@api-stub: lurek.window.getPosition
-- Returns the window position on screen in pixels
do
  function lurek.quit()
    local x, y = lurek.window.getPosition()
    lurek.log.info("saving window position " .. x .. "," .. y, "shutdown")
  end
end

--@api-stub: lurek.window.setPosition
-- Moves the window to the specified screen position
do
  function lurek.init()
    local saved_x, saved_y = 100, 100
    lurek.window.setPosition(saved_x, saved_y)
  end
end

--@api-stub: lurek.window.getDisplayCount
-- Returns the number of connected displays (monitors)
do
  local n = lurek.window.getDisplayCount()
  if n > 1 then
    lurek.log.info("multi-monitor setup detected (" .. n .. " displays)", "video")
  end
end

--@api-stub: lurek.window.getDesktopDimensions
-- Returns the desktop resolution of a specific display, or the current display if none is specified
do
  local dw, dh = lurek.window.getDesktopDimensions()
  local want_w, want_h = math.min(1280, dw), math.min(720, dh)
  lurek.window.setMode(want_w, want_h)
end

--@api-stub: lurek.window.getDPIScale
-- Returns the current DPI scale factor of the window
do
  local s = lurek.window.getDPIScale()
  local font_px = math.floor(16 * s + 0.5)
  lurek.log.info("font size scaled to " .. font_px .. "px (dpi=" .. s .. ")", "ui")
end

--@api-stub: lurek.window.toPixels
-- Converts a value from logical (DPI-independent) units to physical pixel units using the current DPI scale
do
  local logical_size = 64
  local pixel_size = lurek.window.toPixels(logical_size)
  lurek.log.info("64dp icon = " .. pixel_size .. " physical pixels", "ui")
end

--@api-stub: lurek.window.fromPixels
-- Converts a value from physical pixel units to logical (DPI-independent) units using the current DPI scale
do
  local mouse_dx_pixels = 24
  local logical_dx = lurek.window.fromPixels(mouse_dx_pixels)
  lurek.log.info("mouse dx=" .. logical_dx .. " logical units", "input")
end

--@api-stub: lurek.window.setIcon
-- Sets the window icon from an image file
do
  function lurek.init()
    lurek.window.setIcon("assets/icon.png")
  end
end

--@api-stub: lurek.window.setMode
-- Sets the window display mode with a specific resolution and optional flags
do
  function lurek.init()
    lurek.window.setMode(1280, 720, { fullscreen = false, fullscreentype = "desktop", vsync = 1 })
  end
end

--@api-stub: lurek.window.getMode
-- Returns the current window display mode: width, height, and a flags table containing fullscreen state, fullscreen type, and VSync mode
do
  local w, h, flags = lurek.window.getMode()
  lurek.log.info("mode " .. w .. "x" .. h .. " fullscreen=" .. tostring(flags.fullscreen) ..
    " vsync=" .. flags.vsync, "video")
end

--@api-stub: lurek.window.windowConfig
-- Applies multiple window settings at once from a configuration table
do
  lurek.window["windowConfig"]({
    title = "My Game - Config Applied",
    width = 1280,
    height = 720,
    fullscreen = false,
    fullscreentype = "desktop",
    vsync = 1,
    x = 100,
    y = 100,
    scaleMode = "letterbox",
    display = 0,
  })
end

--@api-stub: lurek.window.close
-- Closes the window and signals the engine to shut down
do
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("escape") then
      lurek.window.close()
    end
  end
end

--@api-stub: lurek.window.requestAttention
-- Requests user attention by flashing the taskbar icon
do
  local load_done = true
  if load_done and not lurek.window.hasFocus() then
    lurek.window.requestAttention()
  end
end

--@api-stub: lurek.window.getFullscreenModes
-- Returns a list of all supported fullscreen video modes across all monitors
do
  local modes = lurek.window.getFullscreenModes()
  for i, m in ipairs(modes) do
    lurek.log.info("mode " .. i .. ": " .. m.width .. "x" .. m.height .. " @ " .. m.refreshRate .. "Hz", "video")
    if i >= 3 then break end
  end
end

--@api-stub: lurek.window.getDisplayName
-- Returns the human-readable name of a display
do
  local name = lurek.window.getDisplayName()
  lurek.log.info("running on display: " .. name, "video")
end

--@api-stub: lurek.window.getPixelDimensions
-- Returns the window dimensions in actual physical pixels, accounting for DPI scaling
do
  local pw, ph = lurek.window.getPixelDimensions()
  lurek.log.info("backbuffer " .. pw .. "x" .. ph .. " physical pixels", "video")
end


--@api-stub: lurek.window.focus
-- Requests keyboard focus for the window
do
  function lurek.init()
    lurek.window.focus()
  end
end

--@api-stub: lurek.window.getNativeDPIScale
-- Returns the native DPI scale factor reported by the operating system
do
  local native = lurek.window.getNativeDPIScale()
  if native > 1.5 then
    lurek.log.info("HiDPI screen detected (scale " .. native .. ")", "video")
  end
end

--@api-stub: lurek.window.getDisplayOrientation
-- Returns the display orientation based on the window's aspect ratio
do
  local orient = lurek.window.getDisplayOrientation()
  lurek.log.info("layout mode: " .. orient, "ui")
end

--@api-stub: lurek.window.getSafeArea
-- Returns the safe drawing area of the window
do
  local x, y, w, h = lurek.window.getSafeArea()
  lurek.log.info("safe area " .. w .. "x" .. h .. " at (" .. x .. "," .. y .. ")", "ui")
end

--@api-stub: lurek.window.getSystemTheme
-- Returns the operating system's current color theme
do
  local theme = lurek.window.getSystemTheme()
  local bg = (theme == "dark") and { 0.1, 0.1, 0.12, 1 } or { 0.95, 0.95, 0.96, 1 }
  lurek.log.info("ui theme=" .. theme .. " bg=" .. bg[1], "ui")
end

--@api-stub: lurek.window.isHighDPIAllowed
-- Returns whether high-DPI rendering is allowed
do
  if lurek.window.isHighDPIAllowed() then
    lurek.log.info("HiDPI rendering enabled", "video")
  end
end

--@api-stub: lurek.window.getScaleInfo
-- Returns detailed scaling information including scale factors, offsets, and logical game dimensions
do
  local info = lurek.window.getScaleInfo()
  lurek.log.info("scale " .. info.scale_x .. "x" .. info.scale_y ..
    " offset (" .. info.offset_x .. "," .. info.offset_y .. ")" ..
    " game " .. info.game_width .. "x" .. info.game_height, "video")
end

--@api-stub: lurek.window.getScaleMode
-- Returns the current content scale mode name (e
do
  local mode = lurek.window.getScaleMode()
  lurek.log.info("viewport scale mode: " .. mode, "video")
end

--@api-stub: lurek.window.setScaleMode
-- Sets the content scale mode
do
  function lurek.init()
    lurek.window.setScaleMode("pixel")
  end
end

--@api-stub: lurek.window.getGameWidth
-- Returns the logical game width as defined by the current scale mode and game configuration
do
  local gw = lurek.window.getGameWidth()
  local centre = gw * 0.5
  lurek.log.info("game width " .. gw .. " centre=" .. centre, "ui")
end

--@api-stub: lurek.window.getGameHeight
-- Returns the logical game height as defined by the current scale mode and game configuration
do
  local gh = lurek.window.getGameHeight()
  local hud_y = gh - 32
  lurek.log.info("hud baseline at game-y=" .. hud_y, "ui")
end

--@api-stub: lurek.window.isFullscreen
-- Returns whether the window is currently in fullscreen mode
do
  if lurek.window.isFullscreen() then
    lurek.log.info("fullscreen mode active", "video")
  end
end

--@api-stub: lurek.window.isResizable
-- Returns whether the window can be resized by the user
do
  if not lurek.window.isResizable() then
    lurek.log.info("custom resolution UI disabled (window non-resizable)", "ui")
  end
end

--@api-stub: lurek.window.onDpiChange
-- Registers a callback function that is called whenever the DPI scale factor changes (e
do
  function lurek.init()
    lurek.window.onDpiChange(function(new_scale)
      lurek.log.info("dpi changed -> " .. new_scale .. ", rebuilding font atlas", "video")
    end)
  end
end

--@api-stub: lurek.window.pollDpiChange
-- Checks if the DPI scale has changed since the last poll and fires the onDpiChange callback if so
do
  function lurek.process(dt)
    local current = lurek.window.pollDpiChange()
    if current and current > 2.0 then
      lurek.log.debug("very high DPI: " .. current, "video")
    end
  end
end

--@api-stub: lurek.window.openFileDialog
-- Opens a native file picker dialog and returns the selected file paths
do
  local paths = lurek.window.openFileDialog({
    title = "My Game - Load save",
    defaultPath = "save",
    filters = { { name = "Save files", extensions = { "dat", "sav" } } },
  })
  if #paths > 0 then
    lurek.log.info("user picked save: " .. paths[1], "save")
  end
end

--@api-stub: lurek.window.getDisplays
-- Returns a list of all connected displays with their properties
do
  local displays = lurek.window.getDisplays()
  for _, d in ipairs(displays) do
    lurek.log.info("display " .. d.index .. ": " .. d.name .. " " .. d.width .. "x" .. d.height, "video")
  end
end

--@api-stub: lurek.window.getCurrentDisplay
-- Returns the index of the display that currently contains the window
do
  local idx = lurek.window.getCurrentDisplay()
  lurek.log.info("current monitor index: " .. idx, "video")
end

--@api-stub: lurek.window.setDisplay
-- Moves the window to the specified display
do
  function lurek.init()
    lurek.window.setDisplay(0)
  end
end

--@api-stub: lurek.window.flash
-- Flashes the window briefly to attract the user's attention
do
  if not lurek.window.hasFocus() then
    lurek.window.flash()
  end
end

--@api-stub: lurek.window.display
-- Performs the display operation on this window.
do
  local display_ns = lurek.window["display"]
  local displays = display_ns.getDisplays()
  local current = display_ns.getCurrent()
  display_ns.setCurrent(current)
  lurek.log.info("display count=" .. display_ns.getCount(), "video")
end

--@api-stub: lurek.window.mode
-- Performs the mode operation on this window.
do
  local mode_ns = lurek.window["mode"]
  local w, h, flags = mode_ns.get()
  mode_ns.set(w, h, { fullscreen = flags.fullscreen, vsync = flags.vsync })
end

--@api-stub: lurek.window.cursor
-- Performs the cursor operation on this window.
do
  local inside = lurek.window["cursor"].hasFocus()
  lurek.log.info("cursor in window=" .. tostring(inside), "input")
end
