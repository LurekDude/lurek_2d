-- content/examples/window.lua
-- Hand-written coverage of the lurek.window API (50 items).
--
-- The lurek.window namespace owns the OS-level window: title, size,
-- fullscreen mode, vsync, position, icon, DPI scaling, and the logical
-- viewport. Most setters take effect on the next frame; getters reflect
-- the latest event-pumped state.
--
-- Run: cargo run -- content/examples/window.lua

-- ── lurek.window.* functions ──

--@api-stub: lurek.window.setTitle
-- Sets the window title bar text.
-- Call from lurek.init for the boot title; re-call when the active scene or save slot changes.
do  -- lurek.window.setTitle
  function lurek.init()
    lurek.window.setTitle("My Game - Forest Level")
  end
end

--@api-stub: lurek.window.getTitle
-- Returns the current window title.
-- Use to suffix transient state (paused, slot name) without losing the original title.
do  -- lurek.window.getTitle
  local base = lurek.window.getTitle()
  local paused = true
  if paused then
    lurek.window.setTitle(base .. " [PAUSED]")
  end
end

--@api-stub: lurek.window.getWidth
-- Returns the window width in pixels.
-- Use for centring HUD or computing aspect ratios; pair with getHeight rather than re-reading config.
do  -- lurek.window.getWidth
  local w = lurek.window.getWidth()
  local centre_x = w * 0.5
  lurek.log.info("hud centre x=" .. centre_x .. " (window width " .. w .. "px)", "ui")
end

--@api-stub: lurek.window.getHeight
-- Returns the window height in pixels.
-- Use to anchor bottom-of-screen UI (life bar, dialog box) so resize keeps it pinned.
do  -- lurek.window.getHeight
  local h = lurek.window.getHeight()
  local hud_y = h - 48
  lurek.log.info("hud anchored at y=" .. hud_y, "ui")
end

--@api-stub: lurek.window.getDimensions
-- Returns the window dimensions as width, height.
-- Prefer over two separate calls when you need both numbers — one borrow, two returns.
do  -- lurek.window.getDimensions
  local w, h = lurek.window.getDimensions()
  local aspect = w / h
  lurek.log.info("window " .. w .. "x" .. h .. " aspect=" .. aspect, "boot")
end

--@api-stub: lurek.window.setFullscreen
-- Enables or disables fullscreen mode.
-- Pass "desktop" (default, borderless) or "exclusive"; bind to a hotkey rather than calling at boot.
do  -- lurek.window.setFullscreen
  function lurek.init()
    lurek.window.setFullscreen(true, "desktop")
  end
end

--@api-stub: lurek.window.getFullscreen
-- Returns the fullscreen state and type string.
-- Use to update an in-game options menu toggle without tracking the state yourself.
do  -- lurek.window.getFullscreen
  local enabled, fstype = lurek.window.getFullscreen()
  if enabled then
    lurek.log.info("fullscreen on (" .. fstype .. ")", "video")
  else
    lurek.log.info("running windowed", "video")
  end
end

--@api-stub: lurek.window.isOpen
-- Returns whether the window is open.
-- Useful for thread-spawned helpers that want to bail out once the user closed the game.
do  -- lurek.window.isOpen
  if lurek.window.isOpen() then
    lurek.log.info("window is live, starting subsystems", "boot")
  end
end

--@api-stub: lurek.window.setVSync
-- Sets the VSync mode (1=on, 0=off, -1=adaptive).
-- Set 0 only for benchmarking; 1 for shipping; -1 only after confirming the driver supports it.
do  -- lurek.window.setVSync
  local benchmark = false
  lurek.window.setVSync(benchmark and 0 or 1)
end

--@api-stub: lurek.window.getVSync
-- Returns the current VSync mode integer.
-- Surface in the diagnostics overlay so testers can confirm the option menu actually applied.
do  -- lurek.window.getVSync
  local mode = lurek.window.getVSync()
  local label = ({ [-1] = "adaptive", [0] = "off", [1] = "on" })[mode] or "unknown"
  lurek.log.info("vsync=" .. label, "video")
end

--@api-stub: lurek.window.hasFocus
-- Returns whether the window has keyboard focus.
-- Pause music or simulation while focus is lost so background play does not drain CPU.
do  -- lurek.window.hasFocus
  function lurek.process(dt)
    if not lurek.window.hasFocus() then
      return
    end
  end
end

--@api-stub: lurek.window.hasMouseFocus
-- Returns whether the mouse cursor is inside the window.
-- Skip cursor-driven UI hover effects when the pointer is outside; avoids stale highlights.
do  -- lurek.window.hasMouseFocus
  function lurek.process(dt)
    if lurek.window.hasMouseFocus() then
      lurek.log.debug("mouse inside window", "input")
    end
  end
end

--@api-stub: lurek.window.isMinimized
-- Returns whether the window is minimized.
-- Skip GPU-heavy work (post-fx, particles) while minimized to avoid wasted frames.
do  -- lurek.window.isMinimized
  function lurek.draw()
    if lurek.window.isMinimized() then
      return
    end
  end
end

--@api-stub: lurek.window.isMaximized
-- Returns whether the window is maximized.
-- Useful when restoring the user's preferred layout on launch from a settings file.
do  -- lurek.window.isMaximized
  if lurek.window.isMaximized() then
    lurek.log.info("window starts maximized", "boot")
  end
end

--@api-stub: lurek.window.isVisible
-- Returns whether the window is visible.
-- Check before issuing any draw call when running on platforms that may hide the surface.
do  -- lurek.window.isVisible
  function lurek.draw()
    if not lurek.window.isVisible() then
      return
    end
  end
end

--@api-stub: lurek.window.minimize
-- Minimizes the window to the taskbar.
-- Bind to a hotkey or in-game "send to tray" menu entry; do not call at startup.
do  -- lurek.window.minimize
  function lurek.process(dt)
    if lurek.input.isKeyPressed("f11") then
      lurek.window.minimize()
    end
  end
end

--@api-stub: lurek.window.maximize
-- Maximizes the window to fill the desktop.
-- Use as a "fit to screen" alternative to fullscreen — keeps the window chrome visible.
do  -- lurek.window.maximize
  function lurek.init()
    lurek.window.maximize()
  end
end

--@api-stub: lurek.window.restore
-- Restores the window from minimized or maximized state.
-- Call before setMode/setPosition to ensure the window is in a normal state first.
do  -- lurek.window.restore
  function lurek.init()
    lurek.window.restore()
    lurek.window.setMode(1280, 720)
  end
end

--@api-stub: lurek.window.getPosition
-- Returns the window position as x, y in screen coordinates.
-- Persist on quit and pass to setPosition on next launch to remember where the player put it.
do  -- lurek.window.getPosition
  function lurek.quit()
    local x, y = lurek.window.getPosition()
    lurek.log.info("saving window position " .. x .. "," .. y, "shutdown")
  end
end

--@api-stub: lurek.window.setPosition
-- Moves the window to the given screen position.
-- Restore from a saved config; clamp to the desktop area first to avoid offscreen windows.
do  -- lurek.window.setPosition
  function lurek.init()
    local saved_x, saved_y = 100, 100
    lurek.window.setPosition(saved_x, saved_y)
  end
end

--@api-stub: lurek.window.getDisplayCount
-- Returns the number of connected displays.
-- Use to populate a "monitor" dropdown in the options menu; fall back to 1 if multi-monitor is unsupported.
do  -- lurek.window.getDisplayCount
  local n = lurek.window.getDisplayCount()
  if n > 1 then
    lurek.log.info("multi-monitor setup detected (" .. n .. " displays)", "video")
  end
end

--@api-stub: lurek.window.getDesktopDimensions
-- Returns the desktop resolution as width, height.
-- Use to clamp setMode requests so a saved config from a larger monitor cannot create an offscreen window.
do  -- lurek.window.getDesktopDimensions
  local dw, dh = lurek.window.getDesktopDimensions()
  local want_w, want_h = math.min(1280, dw), math.min(720, dh)
  lurek.window.setMode(want_w, want_h)
end

--@api-stub: lurek.window.getDPIScale
-- Returns the DPI scaling factor for the window.
-- Multiply UI element pixel sizes by this so HUD does not look tiny on a 4K HiDPI display.
do  -- lurek.window.getDPIScale
  local s = lurek.window.getDPIScale()
  local font_px = math.floor(16 * s + 0.5)
  lurek.log.info("font size scaled to " .. font_px .. "px (dpi=" .. s .. ")", "ui")
end

--@api-stub: lurek.window.toPixels
-- Converts a device-independent coordinate to physical pixels.
-- Use when sizing textures or framebuffers that must match physical pixels on HiDPI screens.
do  -- lurek.window.toPixels
  local logical_size = 64
  local pixel_size = lurek.window.toPixels(logical_size)
  lurek.log.info("64dp icon = " .. pixel_size .. " physical pixels", "ui")
end

--@api-stub: lurek.window.fromPixels
-- Converts physical pixels to device-independent coordinates.
-- Use to translate raw mouse-pixel deltas into logical units for layout maths.
do  -- lurek.window.fromPixels
  local mouse_dx_pixels = 24
  local logical_dx = lurek.window.fromPixels(mouse_dx_pixels)
  lurek.log.info("mouse dx=" .. logical_dx .. " logical units", "input")
end

--@api-stub: lurek.window.setIcon
-- Sets the window icon from a file path.
-- Call once at boot; the path is resolved relative to the game directory and must exist.
do  -- lurek.window.setIcon
  function lurek.init()
    lurek.window.setIcon("assets/icon.png")
  end
end

--@api-stub: lurek.window.setMode
-- Resizes the window and optionally changes fullscreen and vsync.
-- Pass a flags table to atomically apply size + fullscreen + vsync from a single options-menu commit.
do  -- lurek.window.setMode
  function lurek.init()
    lurek.window.setMode(1280, 720, { fullscreen = false, fullscreentype = "desktop", vsync = 1 })
  end
end

--@api-stub: lurek.window.getMode
-- Returns the window dimensions and mode flags as width, height, flags.
-- Read at boot and serialise to disk so the same display state can be restored next launch.
do  -- lurek.window.getMode
  local w, h, flags = lurek.window.getMode()
  lurek.log.info("mode " .. w .. "x" .. h .. " fullscreen=" .. tostring(flags.fullscreen) ..
    " vsync=" .. flags.vsync, "video")
end

--@api-stub: lurek.window.close
-- Requests the window to close.
-- Bind to an in-game "Quit" menu entry; the engine will run lurek.quit before the process exits.
do  -- lurek.window.close
  function lurek.process(dt)
    if lurek.input.isKeyPressed("escape") then
      lurek.window.close()
    end
  end
end

--@api-stub: lurek.window.requestAttention
-- Flashes the window in the taskbar to request user attention.
-- Use when the player Alt-Tabbed away during a long load and you want to ping them when ready.
do  -- lurek.window.requestAttention
  local load_done = true
  if load_done and not lurek.window.hasFocus() then
    lurek.window.requestAttention()
  end
end

--@api-stub: lurek.window.getFullscreenModes
-- Returns all available fullscreen video modes.
-- Use to populate the resolution dropdown in the options menu, deduped by width/height.
do  -- lurek.window.getFullscreenModes
  local modes = lurek.window.getFullscreenModes()
  for i, m in ipairs(modes) do
    lurek.log.info("mode " .. i .. ": " .. m.width .. "x" .. m.height .. " @ " .. m.refreshRate .. "Hz", "video")
    if i >= 3 then break end
  end
end

--@api-stub: lurek.window.getDisplayName
-- Returns the name of the current display.
-- Surface in the options menu so multi-monitor users know which display the game is running on.
do  -- lurek.window.getDisplayName
  local name = lurek.window.getDisplayName()
  lurek.log.info("running on display: " .. name, "video")
end

--@api-stub: lurek.window.getPixelDimensions
-- Returns the window dimensions in physical pixels.
-- Use when allocating render targets that must exactly match the swap chain on HiDPI screens.
do  -- lurek.window.getPixelDimensions
  local pw, ph = lurek.window.getPixelDimensions()
  lurek.log.info("backbuffer " .. pw .. "x" .. ph .. " physical pixels", "video")
end

--@api-stub: lurek.window.showMessageBox
-- Shows a platform-native message box dialog.
-- Blocks the main loop — use only for fatal errors at boot or destructive confirms ("Delete save?").
-- NOTE: wrapped in lurek.init so it does not execute at file-load time (blocks on user input).
do  -- lurek.window.showMessageBox
  function lurek.init()
    local choice = lurek.window.showMessageBox("My Game", "Delete save slot 1?", "warning", "yesno")
    if choice == "yes" then
      lurek.log.info("user confirmed save deletion", "ui")
    end
  end
end

--@api-stub: lurek.window.focus
-- Requests the window manager to bring the window to the foreground.
-- Use after dismissing a native dialog so input refocuses on the game without an Alt-Tab.
do  -- lurek.window.focus
  function lurek.init()
    lurek.window.focus()
  end
end

--@api-stub: lurek.window.getNativeDPIScale
-- Returns the native DPI scale factor.
-- Same as getDPIScale today; use this name when you specifically want the hardware-reported value.
do  -- lurek.window.getNativeDPIScale
  local native = lurek.window.getNativeDPIScale()
  if native > 1.5 then
    lurek.log.info("HiDPI screen detected (scale " .. native .. ")", "video")
  end
end

--@api-stub: lurek.window.getDisplayOrientation
-- Returns the current display orientation.
-- Branch HUD layouts on "portrait" vs "landscape" so a rotated tablet display still looks right.
do  -- lurek.window.getDisplayOrientation
  local orient = lurek.window.getDisplayOrientation()
  lurek.log.info("layout mode: " .. orient, "ui")
end

--@api-stub: lurek.window.getSafeArea
-- Returns the safe display area as x, y, w, h.
-- Inset critical UI by this rect so notches and rounded corners cannot clip the score or health bar.
do  -- lurek.window.getSafeArea
  local x, y, w, h = lurek.window.getSafeArea()
  lurek.log.info("safe area " .. w .. "x" .. h .. " at (" .. x .. "," .. y .. ")", "ui")
end

--@api-stub: lurek.window.getSystemTheme
-- Returns the OS color theme preference.
-- Drive default UI palette ("dark"/"light"/"unknown") so the game matches the user's desktop on first run.
do  -- lurek.window.getSystemTheme
  local theme = lurek.window.getSystemTheme()
  local bg = (theme == "dark") and { 0.1, 0.1, 0.12, 1 } or { 0.95, 0.95, 0.96, 1 }
  lurek.log.info("ui theme=" .. theme .. " bg=" .. bg[1], "ui")
end

--@api-stub: lurek.window.isHighDPIAllowed
-- Returns whether high-DPI rendering is allowed.
-- Gate optional sharper-text code paths; disable HiDPI render targets when this returns false.
do  -- lurek.window.isHighDPIAllowed
  if lurek.window.isHighDPIAllowed() then
    lurek.log.info("HiDPI rendering enabled", "video")
  end
end

--@api-stub: lurek.window.getScaleInfo
-- Returns viewport scale and offset information as a table.
-- Use the offset_x/offset_y fields to draw letterbox bars in the same colour as the game background.
do  -- lurek.window.getScaleInfo
  local info = lurek.window.getScaleInfo()
  lurek.log.info("scale " .. info.scale_x .. "x" .. info.scale_y ..
    " offset (" .. info.offset_x .. "," .. info.offset_y .. ")" ..
    " game " .. info.game_width .. "x" .. info.game_height, "video")
end

--@api-stub: lurek.window.getScaleMode
-- Returns the current viewport scale mode string.
-- Surface in the options UI ("fit", "stretch", "pixel") so the user knows which mode is active.
do  -- lurek.window.getScaleMode
  local mode = lurek.window.getScaleMode()
  lurek.log.info("viewport scale mode: " .. mode, "video")
end

--@api-stub: lurek.window.setScaleMode
-- Sets the viewport scale mode.
-- Pass "fit" to letterbox, "stretch" to fill, "pixel" for crisp integer scaling on retro art.
do  -- lurek.window.setScaleMode
  function lurek.init()
    lurek.window.setScaleMode("pixel")
  end
end

--@api-stub: lurek.window.getGameWidth
-- Returns the logical game width in virtual pixels.
-- Use as the canonical render width — independent of the OS window size, stable across resizes.
do  -- lurek.window.getGameWidth
  local gw = lurek.window.getGameWidth()
  local centre = gw * 0.5
  lurek.log.info("game width " .. gw .. " centre=" .. centre, "ui")
end

--@api-stub: lurek.window.getGameHeight
-- Returns the logical game height in virtual pixels.
-- Pair with getGameWidth when designing HUD layouts that must remain pixel-perfect under any window size.
do  -- lurek.window.getGameHeight
  local gh = lurek.window.getGameHeight()
  local hud_y = gh - 32
  lurek.log.info("hud baseline at game-y=" .. hud_y, "ui")
end

--@api-stub: lurek.window.isFullscreen
-- Returns whether the window is in fullscreen mode.
-- Quick boolean check when you do not need the type string returned by getFullscreen.
do  -- lurek.window.isFullscreen
  if lurek.window.isFullscreen() then
    lurek.log.info("fullscreen mode active", "video")
  end
end

--@api-stub: lurek.window.isResizable
-- Returns whether the window can be resized by the user.
-- Use to disable the in-game "Custom resolution" UI when the platform forbids resizing.
do  -- lurek.window.isResizable
  if not lurek.window.isResizable() then
    lurek.log.info("custom resolution UI disabled (window non-resizable)", "ui")
  end
end

--@api-stub: lurek.window.onDpiChange
-- Registers a callback invoked (with the new scale factor) when the display.
-- Re-rasterise fonts and re-allocate HiDPI render targets here; pollDpiChange must be called per frame.
do  -- lurek.window.onDpiChange
  function lurek.init()
    lurek.window.onDpiChange(function(new_scale)
      lurek.log.info("dpi changed -> " .. new_scale .. ", rebuilding font atlas", "video")
    end)
  end
end

--@api-stub: lurek.window.pollDpiChange
-- Polls for a pending DPI change event and returns the new scale factor if any.
-- Call once per frame in lurek.process so the onDpiChange callback can actually fire.
do  -- lurek.window.pollDpiChange
  function lurek.process(dt)
    local current = lurek.window.pollDpiChange()
    if current and current > 2.0 then
      lurek.log.debug("very high DPI: " .. current, "video")
    end
  end
end

--@api-stub: lurek.window.openFileDialog
-- Opens a blocking native file-open dialog.
-- Use for "Load mod" or "Import save" buttons; pass filters and multiple=true to allow batch selection.
do  -- lurek.window.openFileDialog
  local paths = lurek.window.openFileDialog({
    title = "My Game - Load save",
    defaultPath = "save",
    filters = { { name = "Save files", extensions = { "dat", "sav" } } },
  })
  if #paths > 0 then
    lurek.log.info("user picked save: " .. paths[1], "save")
  end
end
