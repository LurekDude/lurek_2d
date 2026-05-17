-- content/examples/window.lua
-- lurek.window API examples.
-- Run: cargo run -- content/examples/window.lua

--@api-stub: lurek.window.setTitle
-- Sets the window title bar text
do
  function lurek.init()
    -- setTitle updates the OS window title bar in real-time.
    -- Use it during init to brand your game, or dynamically to show state.
    lurek.window.setTitle("My Game - Forest Level")

    -- Common pattern: append build info for dev builds
    local version = "0.3.1"
    lurek.window.setTitle("My Game v" .. version .. " [DEBUG]")
  end
end

--@api-stub: lurek.window.getTitle
-- Returns the current window title bar text
do
  -- getTitle returns whatever string was last set via setTitle or conf.lua.
  -- Useful for appending status without losing the base title.
  local base = lurek.window.getTitle()
  local paused = true
  if paused then
    -- Append a pause indicator without hardcoding the base title
    lurek.window.setTitle(base .. " [PAUSED]")
  end
end

--@api-stub: lurek.window.getWidth
-- Returns the current window width in logical (DPI-independent) pixels
do
  -- Returns the logical width, NOT physical pixels. On a 2x DPI display
  -- a 1280px logical window would be 2560 physical pixels.
  -- Use this for UI layout and game coordinate calculations.
  local w = lurek.window.getWidth()
  local centre_x = w * 0.5
  lurek.log.info("hud centre x=" .. centre_x .. " (window width " .. w .. "px)", "ui")
end

--@api-stub: lurek.window.getHeight
-- Returns the current window height in logical (DPI-independent) pixels
do
  -- Same as getWidth but vertical. Use for anchoring UI to bottom/top edges.
  local h = lurek.window.getHeight()
  -- Anchor a HUD bar 48px above the bottom edge
  local hud_y = h - 48
  lurek.log.info("hud anchored at y=" .. hud_y, "ui")
end

--@api-stub: lurek.window.getDimensions
-- Returns the current window width and height in logical pixels
do
  -- Returns both dimensions in one call - more efficient than calling
  -- getWidth() and getHeight() separately when you need both.
  local w, h = lurek.window.getDimensions()
  local aspect = w / h
  -- Aspect ratio is useful for deciding UI layout (wide vs narrow)
  lurek.log.info("window " .. w .. "x" .. h .. " aspect=" .. string.format("%.2f", aspect), "boot")
end

--@api-stub: lurek.window.setFullscreen
-- Enables or disables fullscreen mode
do
  function lurek.init()
    -- "desktop" = borderless fullscreen at desktop resolution (fast alt-tab, no mode switch)
    -- "exclusive" = true fullscreen with a mode switch (can change resolution)
    -- Desktop mode is preferred for most games - less disruptive to the user.
    lurek.window.setFullscreen(true, "desktop")
  end

  function lurek.process(dt)
    -- Typical fullscreen toggle with F11
    if lurek.input.keyboard.isDown("f11") then
      local is_fs = lurek.window.isFullscreen()
      lurek.window.setFullscreen(not is_fs, "desktop")
    end
  end
end

--@api-stub: lurek.window.getFullscreen
-- Returns the current fullscreen state and type
do
  -- Returns two values: enabled (boolean) and type (string).
  -- The type is "desktop" or "exclusive" when fullscreen is on.
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
  -- Always returns true while the engine is running.
  -- Useful as a guard in systems that may outlive the window during shutdown.
  if lurek.window.isOpen() then
    lurek.log.info("window is live, starting subsystems", "boot")
  end
end

--@api-stub: lurek.window.setVSync
-- Sets the vertical sync mode
do
  -- VSync modes:
  --   1  = on (cap to monitor refresh, prevents tearing)
  --  -1  = adaptive (sync when fast enough, tear when too slow)
  --   0  = off (unlimited FPS, useful for benchmarking)
  -- For most games, vsync=1 gives the smoothest experience.
  local benchmark = false
  if benchmark then
    lurek.window.setVSync(0)   -- uncapped for profiling
  else
    lurek.window.setVSync(1)   -- standard sync for gameplay
  end
end

--@api-stub: lurek.window.getVSync
-- Returns the current VSync mode
do
  -- Returns an integer: -1, 0, or 1. Map to human-readable labels for UI.
  local mode = lurek.window.getVSync()
  local labels = { [-1] = "Adaptive", [0] = "Off", [1] = "On" }
  local label = labels[mode] or "Unknown"
  lurek.log.info("VSync: " .. label, "video")
end

--@api-stub: lurek.window.hasFocus
-- Returns whether the window currently has keyboard focus
do
  function lurek.process(dt)
    -- Pause game logic when the player alt-tabs away.
    -- This prevents the game from running unattended and wasting resources.
    if not lurek.window.hasFocus() then
      return -- skip game update while unfocused
    end
    -- ... normal game logic here ...
  end
end

--@api-stub: lurek.window.hasMouseFocus
-- Returns whether the mouse cursor is inside the window
do
  function lurek.process(dt)
    -- Only process hover effects when the mouse is actually inside the window.
    -- Prevents edge-of-screen artifacts in windowed mode.
    if lurek.window.hasMouseFocus() then
      -- Update tooltip position, cursor highlight, etc.
      lurek.log.debug("mouse inside window - processing hover", "input")
    end
  end
end

--@api-stub: lurek.window.isMinimized
-- Returns whether the window is currently minimized to the taskbar
do
  function lurek.draw()
    -- Skip all rendering when minimized. The GPU has nothing to present,
    -- so drawing would waste cycles and may cause driver warnings.
    if lurek.window.isMinimized() then
      return
    end
    -- ... render game world ...
  end
end

--@api-stub: lurek.window.isMaximized
-- Returns whether the window is currently maximized
do
  -- Check window state at startup to adapt UI layout.
  -- A maximized window may need different margins than a floating one.
  if lurek.window.isMaximized() then
    lurek.log.info("window starts maximized - using full-width layout", "boot")
  end
end

--@api-stub: lurek.window.isVisible
-- Returns whether the window is currently visible on screen
do
  function lurek.draw()
    -- isVisible is false when the window is fully occluded or on another
    -- virtual desktop. Use it to skip expensive rendering in that case.
    if not lurek.window.isVisible() then
      return
    end
    -- ... render scene ...
  end
end

--@api-stub: lurek.window.minimize
-- Minimizes the window to the taskbar
do
  function lurek.process(dt)
    -- Example: minimize to tray when the player presses a "boss key"
    if lurek.input.keyboard.isDown("pause") then
      lurek.window.minimize()
    end
  end
end

--@api-stub: lurek.window.maximize
-- Maximizes the window to fill the screen
do
  function lurek.init()
    -- Start maximized for games that look best filling the workspace.
    -- Unlike fullscreen, the taskbar and title bar remain visible.
    lurek.window.maximize()
  end
end

--@api-stub: lurek.window.restore
-- Restores the window from minimized or maximized state to its previous size and position
do
  function lurek.init()
    -- Restore ensures the window is in its normal floating state
    -- before applying a specific resolution. Without this, setMode
    -- might fight with the maximized state.
    lurek.window.restore()
    lurek.window.setMode(1280, 720)
  end
end

--@api-stub: lurek.window.getPosition
-- Returns the window position on screen in pixels
do
  function lurek.quit()
    -- Save window position on exit so we can restore it next launch.
    -- Players expect their window placement to persist between sessions.
    local x, y = lurek.window.getPosition()
    lurek.log.info("saving window position " .. x .. "," .. y, "shutdown")
    -- In a real game, write x,y to a config file here
  end
end

--@api-stub: lurek.window.setPosition
-- Moves the window to the specified screen position
do
  function lurek.init()
    -- Restore saved position from previous session.
    -- If the saved position is off-screen (monitor unplugged), the OS
    -- will clamp it, so this is safe to call with stale values.
    local saved_x, saved_y = 100, 100 -- loaded from config
    lurek.window.setPosition(saved_x, saved_y)
  end
end

--@api-stub: lurek.window.getDisplayCount
-- Returns the number of connected displays (monitors)
do
  -- Useful for building a "select monitor" dropdown in video settings.
  local n = lurek.window.getDisplayCount()
  if n > 1 then
    lurek.log.info("multi-monitor setup detected (" .. n .. " displays)", "video")
  end
end

--@api-stub: lurek.window.getDesktopDimensions
-- Returns the desktop resolution of a specific display, or the current display if none is specified
do
  -- Use the desktop resolution to pick a sensible default window size.
  -- The optional display parameter is zero-based (0 = primary monitor).
  local dw, dh = lurek.window.getDesktopDimensions() -- current display
  -- Clamp window to 80% of desktop size for comfortable windowed play
  local want_w = math.min(1280, math.floor(dw * 0.8))
  local want_h = math.min(720, math.floor(dh * 0.8))
  lurek.window.setMode(want_w, want_h)
end

--@api-stub: lurek.window.getDPIScale
-- Returns the current DPI scale factor of the window
do
  -- A scale of 1.0 = standard 96 DPI. 2.0 = Retina / 200% scaling.
  -- Multiply logical sizes by this factor to get crisp rendering on HiDPI.
  local s = lurek.window.getDPIScale()
  local font_px = math.floor(16 * s + 0.5)
  lurek.log.info("font size scaled to " .. font_px .. "px (dpi scale=" .. s .. ")", "ui")
end

--@api-stub: lurek.window.toPixels
-- Converts a value from logical (DPI-independent) units to physical pixel units using the current DPI scale
do
  -- Use toPixels when you need to size GPU resources (textures, render targets)
  -- that must match physical screen pixels for crisp output.
  local logical_size = 64
  local pixel_size = lurek.window.toPixels(logical_size)
  lurek.log.info("64 logical units = " .. pixel_size .. " physical pixels", "ui")
end

--@api-stub: lurek.window.fromPixels
-- Converts a value from physical pixel units to logical (DPI-independent) units using the current DPI scale
do
  -- Use fromPixels when raw pixel input (e.g., mouse delta) needs to be
  -- converted to game-space logical coordinates.
  local mouse_dx_pixels = 24
  local logical_dx = lurek.window.fromPixels(mouse_dx_pixels)
  lurek.log.info("mouse moved " .. logical_dx .. " logical units", "input")
end

--@api-stub: lurek.window.setIcon
-- Sets the window icon from an image file
do
  function lurek.init()
    -- Sets the window icon shown in the title bar and taskbar.
    -- The path is relative to the game's root directory.
    -- Supports PNG, BMP, and other common formats.
    lurek.window.setIcon("assets/icon.png")
  end
end

--@api-stub: lurek.window.setMode
-- Sets the window display mode with a specific resolution and optional flags
do
  function lurek.init()
    -- setMode is the primary way to configure the window at startup.
    -- The flags table is optional; omit fields to keep their current values.
    lurek.window.setMode(1280, 720, {
      fullscreen = false,         -- start windowed
      fullscreentype = "desktop", -- borderless when fullscreen is toggled
      vsync = 1,                  -- sync to monitor refresh
    })
  end
end

--@api-stub: lurek.window.getMode
-- Returns the current window display mode: width, height, and a flags table containing fullscreen state, fullscreen type, and VSync mode
do
  -- getMode gives you the complete window state in one call.
  -- The flags table mirrors what you pass to setMode.
  local w, h, flags = lurek.window.getMode()
  lurek.log.info(
    "mode " .. w .. "x" .. h ..
    " fullscreen=" .. tostring(flags.fullscreen) ..
    " type=" .. flags.fullscreentype ..
    " vsync=" .. flags.vsync,
    "video"
  )
end

--@api-stub: lurek.window.windowConfig
-- Applies multiple window settings at once from a configuration table
do
  -- windowConfig is a batch setter - apply title, size, position, fullscreen,
  -- vsync, scale mode, and display in a single call. Useful for applying
  -- a saved settings profile or implementing a "video settings" menu.
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
    -- close() triggers a graceful shutdown. The lurek.quit callback
    -- will still fire, giving you a chance to save state.
    if lurek.input.keyboard.isDown("escape") then
      lurek.window.close()
    end
  end
end

--@api-stub: lurek.window.requestAttention
-- Requests user attention by flashing the taskbar icon
do
  -- Flash the taskbar to notify the player when something finishes
  -- in the background (e.g., matchmaking found a game).
  local matchmaking_done = true
  if matchmaking_done and not lurek.window.hasFocus() then
    lurek.window.requestAttention()
  end
end

--@api-stub: lurek.window.getFullscreenModes
-- Returns a list of all supported fullscreen video modes across all monitors
do
  -- Each mode has width, height, and refreshRate fields.
  -- Use this to populate a resolution picker in your settings menu.
  local modes = lurek.window.getFullscreenModes()
  for i, m in ipairs(modes) do
    lurek.log.info(
      "mode " .. i .. ": " .. m.width .. "x" .. m.height .. " @ " .. m.refreshRate .. "Hz",
      "video"
    )
    if i >= 5 then break end -- limit output for demo
  end
end

--@api-stub: lurek.window.getDisplayName
-- Returns the human-readable name of a display
do
  -- Returns the OS-reported monitor name (e.g., "DELL U2723QE").
  -- The optional parameter is a zero-based display index.
  local name = lurek.window.getDisplayName()
  lurek.log.info("running on display: " .. name, "video")
end

--@api-stub: lurek.window.getPixelDimensions
-- Returns the window dimensions in actual physical pixels, accounting for DPI scaling
do
  -- Unlike getDimensions (logical), this returns the real framebuffer size.
  -- Use it when allocating render targets or computing pixel-perfect effects.
  local pw, ph = lurek.window.getPixelDimensions()
  lurek.log.info("backbuffer " .. pw .. "x" .. ph .. " physical pixels", "video")
end

--@api-stub: lurek.window.focus
-- Requests keyboard focus for the window
do
  function lurek.init()
    -- Bring the window to front and grab keyboard focus.
    -- Useful after spawning from a launcher or CLI.
    lurek.window.focus()
  end
end

--@api-stub: lurek.window.getNativeDPIScale
-- Returns the native DPI scale factor reported by the operating system
do
  -- getNativeDPIScale returns the OS-level scaling (e.g., Windows 150% = 1.5).
  -- Compare with getDPIScale() which may differ if the engine overrides scaling.
  local native = lurek.window.getNativeDPIScale()
  if native > 1.5 then
    lurek.log.info("HiDPI screen detected (native scale " .. native .. "x)", "video")
  end
end

--@api-stub: lurek.window.getDisplayOrientation
-- Returns the display orientation based on the window's aspect ratio
do
  -- Returns "landscape" (width >= height) or "portrait" (height > width).
  -- Useful for adapting UI layout when the window is resized to a tall shape.
  local orient = lurek.window.getDisplayOrientation()
  lurek.log.info("layout mode: " .. orient, "ui")
end

--@api-stub: lurek.window.getSafeArea
-- Returns the safe drawing area of the window
do
  -- On desktop, safe area equals the full window (x=0, y=0, w=width, h=height).
  -- This API exists for compatibility with mobile-style layout code.
  local x, y, w, h = lurek.window.getSafeArea()
  lurek.log.info("safe area " .. w .. "x" .. h .. " at (" .. x .. "," .. y .. ")", "ui")
end

--@api-stub: lurek.window.getSystemTheme
-- Returns the operating system's current color theme
do
  -- Returns "dark", "light", or "unknown" depending on OS support.
  -- Use it to pick default UI colors that match the player's desktop.
  local theme = lurek.window.getSystemTheme()
  local bg = (theme == "dark")
    and { 0.1, 0.1, 0.12, 1 }
    or { 0.95, 0.95, 0.96, 1 }
  lurek.log.info("system theme=" .. theme, "ui")
end

--@api-stub: lurek.window.isHighDPIAllowed
-- Returns whether high-DPI rendering is allowed
do
  -- Currently always returns false on desktop.
  -- When true, the engine renders at native pixel density (sharper but more GPU work).
  if lurek.window.isHighDPIAllowed() then
    lurek.log.info("HiDPI rendering enabled - expect higher GPU load", "video")
  end
end

--@api-stub: lurek.window.getScaleInfo
-- Returns detailed scaling information including scale factors, offsets, and logical game dimensions
do
  -- getScaleInfo returns a table with:
  --   scale_x, scale_y   - how much the game is stretched to fit the window
  --   offset_x, offset_y - letterbox/pillarbox black bar offsets in pixels
  --   game_width, game_height - the logical resolution the game draws at
  -- Use this for converting screen coordinates to game coordinates.
  local info = lurek.window.getScaleInfo()
  lurek.log.info(
    "scale " .. info.scale_x .. "x" .. info.scale_y ..
    " offset (" .. info.offset_x .. "," .. info.offset_y .. ")" ..
    " game " .. info.game_width .. "x" .. info.game_height,
    "video"
  )
end

--@api-stub: lurek.window.getScaleMode
-- Returns the current content scale mode name
do
  -- Possible values: "stretch", "letterbox", "pixel-perfect", etc.
  -- This reflects what was set in conf.lua or via setScaleMode().
  local mode = lurek.window.getScaleMode()
  lurek.log.info("viewport scale mode: " .. mode, "video")
end

--@api-stub: lurek.window.setScaleMode
-- Sets the content scale mode
do
  function lurek.init()
    -- Scale modes control how the game's logical resolution maps to the window:
    --   "stretch"        - fill window, may distort aspect ratio
    --   "letterbox"      - fit with black bars, preserves aspect ratio
    --   "pixel-perfect"  - integer scaling only, best for pixel art
    lurek.window.setScaleMode("letterbox")
  end
end

--@api-stub: lurek.window.getGameWidth
-- Returns the logical game width as defined by the current scale mode and game configuration
do
  -- getGameWidth returns the width the game "thinks" it has, regardless of
  -- window size. In letterbox mode this stays fixed even when the window resizes.
  local gw = lurek.window.getGameWidth()
  local centre = gw * 0.5
  lurek.log.info("game width " .. gw .. " centre=" .. centre, "ui")
end

--@api-stub: lurek.window.getGameHeight
-- Returns the logical game height as defined by the current scale mode and game configuration
do
  -- Same concept as getGameWidth for the vertical axis.
  -- Use game dimensions (not window dimensions) for placing game objects.
  local gh = lurek.window.getGameHeight()
  local hud_y = gh - 32
  lurek.log.info("hud baseline at game-y=" .. hud_y, "ui")
end

--@api-stub: lurek.window.isFullscreen
-- Returns whether the window is currently in fullscreen mode
do
  -- Simple boolean check, unlike getFullscreen() which also returns the type.
  -- Use when you only need to know if fullscreen is active.
  if lurek.window.isFullscreen() then
    lurek.log.info("fullscreen mode active", "video")
  end
end

--@api-stub: lurek.window.isResizable
-- Returns whether the window can be resized by the user
do
  -- If the window is non-resizable, disable resolution options in the UI
  -- since the user cannot drag-resize and would only be confused.
  if not lurek.window.isResizable() then
    lurek.log.info("resolution picker disabled (window is non-resizable)", "ui")
  end
end

--@api-stub: lurek.window.onDpiChange
-- Registers a callback function that is called whenever the DPI scale factor changes
do
  function lurek.init()
    -- Register a callback to react when the window moves to a different monitor
    -- with a different DPI scale. Rebuild font atlases or resize UI elements here.
    -- Only one callback can be active - setting a new one replaces the old.
    lurek.window.onDpiChange(function(new_scale)
      lurek.log.info("DPI changed to " .. new_scale .. "x, rebuilding font atlas", "video")
      -- Reload scaled assets, rebuild text cache, etc.
    end)
  end
end

--@api-stub: lurek.window.pollDpiChange
-- Checks if the DPI scale has changed since the last poll and fires the onDpiChange callback if so
do
  function lurek.process(dt)
    -- Call once per frame to detect monitor changes.
    -- If the DPI changed since last poll, the onDpiChange callback fires.
    -- Returns the current DPI scale regardless of whether it changed.
    local current = lurek.window.pollDpiChange()
    if current and current > 2.0 then
      lurek.log.debug("very high DPI display: " .. current .. "x", "video")
    end
  end
end

--@api-stub: lurek.window.openFileDialog
-- Opens a native file picker dialog and returns the selected file paths (non-headless)
do
  -- openFileDialog opens a blocking OS file dialog.
  -- The game freezes until the user picks or cancels.
  -- Use for mod loading, save import, or level editor file selection.
  -- Verify existence without calling (non-headless operation)
  assert(type(lurek.window.openFileDialog) == "function", "openFileDialog must be a function")
  lurek.log.info("openFileDialog available (not called in headless mode)", "window")
end

--@api-stub: lurek.window.getDisplays
-- Returns a list of all connected displays with their properties
do
  -- Returns an array of tables, each with: index, name, x, y, width, height,
  -- scale, refreshRate, and primary (boolean).
  -- Use this to build a monitor selection UI with full details.
  local displays = lurek.window.getDisplays()
  for _, d in ipairs(displays) do
    local primary_tag = d.primary and " [PRIMARY]" or ""
    lurek.log.info(
      "display " .. d.index .. ": " .. d.name ..
      " " .. d.width .. "x" .. d.height ..
      " @" .. d.refreshRate .. "Hz" ..
      " scale=" .. d.scale .. primary_tag,
      "video"
    )
  end
end

--@api-stub: lurek.window.getCurrentDisplay
-- Returns the index of the display that currently contains the window
do
  -- Returns the zero-based index of whichever monitor the window center is on.
  -- Use with setDisplay() to remember and restore the player's preferred monitor.
  local idx = lurek.window.getCurrentDisplay()
  lurek.log.info("window is on monitor index: " .. idx, "video")
end

--@api-stub: lurek.window.setDisplay
-- Moves the window to the specified display
do
  function lurek.init()
    -- Move the window to a specific monitor by zero-based index.
    -- Throws an error if the index is negative.
    -- Combine with getDisplayCount() to validate before calling.
    local target = 0 -- primary monitor
    if target < lurek.window.getDisplayCount() then
      lurek.window.setDisplay(target)
    end
  end
end

--@api-stub: lurek.window.flash
-- Flashes the window briefly to attract the user's attention
do
  -- flash() is a quick visual notification. Unlike requestAttention() which
  -- flashes the taskbar, this briefly flashes the window frame itself.
  if not lurek.window.hasFocus() then
    lurek.window.flash()
  end
end

--@api-stub: lurek.window.showMessageBox
-- Displays a native OS message box dialog (non-headless)
do
  -- showMessageBox blocks the game until the user clicks a button.
  -- Use for critical errors, quit confirmation, or important notices.
  -- box_type: "info", "warning", or "error" (changes the icon)
  -- btn_type: "ok", "okcancel", or "yesno" (changes the button layout)
  -- Verify existence without calling (non-headless operation)
  assert(type(lurek.window.showMessageBox) == "function", "showMessageBox must be a function")
  lurek.log.info("showMessageBox available (not called in headless mode)", "window")
end

--@api-stub: lurek.window.display
-- Performs the display operation on this window.
do
  -- The display sub-namespace provides an alternative grouped API for
  -- multi-monitor operations. Same functionality as the top-level display methods.
  local display_ns = lurek.window["display"]
  local displays = display_ns.getDisplays()
  local current = display_ns.getCurrent()
  display_ns.setCurrent(current)
  lurek.log.info("display count=" .. display_ns.getCount(), "video")
end

--@api-stub: lurek.window.mode
-- Performs the mode operation on this window.
do
  -- The mode sub-namespace groups get/set for the window display mode.
  -- Equivalent to getMode()/setMode() but accessed via a sub-table.
  local mode_ns = lurek.window["mode"]
  local w, h, flags = mode_ns.get()
  mode_ns.set(w, h, { fullscreen = flags.fullscreen, vsync = flags.vsync })
end

--@api-stub: lurek.window.cursor
-- Performs the cursor operation on this window.
do
  -- The cursor sub-namespace provides cursor-related queries.
  local inside = lurek.window["cursor"].hasFocus()
  lurek.log.info("cursor in window=" .. tostring(inside), "input")
end

print("content/examples/window.lua")
