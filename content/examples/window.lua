-- examples/window.lua
-- Luna2D luna.window API Reference
-- This file is documentation code, not a runnable game.
-- Every luna.window function is demonstrated with inline comments.

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Title
-- ─────────────────────────────────────────────────────────────────────────────

luna.window.setTitle("My Awesome Game")
local title = luna.window.getTitle()  -- → "My Awesome Game"

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Dimensions (virtual / logical pixels)
-- ─────────────────────────────────────────────────────────────────────────────

local w = luna.window.getWidth()      -- logical width
local h = luna.window.getHeight()     -- logical height
local ww, wh = luna.window.getDimensions()  -- both at once

-- ─────────────────────────────────────────────────────────────────────────────
-- Fullscreen
-- ─────────────────────────────────────────────────────────────────────────────

-- Enter fullscreen  (type: "desktop" = borderless window | "exclusive" = native)
luna.window.setFullscreen(true)
luna.window.setFullscreen(true, "desktop")     -- borderless fullscreen (default)
luna.window.setFullscreen(true, "exclusive")   -- exclusive fullscreen

-- Leave fullscreen
luna.window.setFullscreen(false)

-- Query current state; returns (isFullscreen, type)
local is_fs, fs_type = luna.window.getFullscreen()

-- Toggle convenience pattern:
function luna.keypressed(key)
    if key == "f11" then
        luna.window.setFullscreen(not luna.window.getFullscreen())
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- VSync
-- ─────────────────────────────────────────────────────────────────────────────

-- VSync modes: "on" (fifo), "off" (immediate), "adaptive" (mailbox if available)
luna.window.setVSync("on")
local vs = luna.window.getVSync()  -- → "on" | "off" | "adaptive"

-- ─────────────────────────────────────────────────────────────────────────────
-- Window State Queries
-- ─────────────────────────────────────────────────────────────────────────────

local open = luna.window.isOpen()           -- true while window exists
local focus = luna.window.hasFocus()        -- keyboard focus
local mouse_focus = luna.window.hasMouseFocus()  -- mouse is over window
local minimized = luna.window.isMinimized()
local maximized = luna.window.isMaximized()
local visible = luna.window.isVisible()

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Visibility / Placement
-- ─────────────────────────────────────────────────────────────────────────────

luna.window.minimize()    -- minimize to taskbar
luna.window.maximize()    -- maximize to fill desktop

-- Move the window to a specific screen position (OS may ignore on some platforms)
luna.window.setPosition(200, 100)

-- Get current top-left position relative to the primary display
local wx, wy = luna.window.getPosition()

-- ─────────────────────────────────────────────────────────────────────────────
-- DPI / HiDPI Scaling
-- ─────────────────────────────────────────────────────────────────────────────

-- Convert logical (virtual) pixels → physical pixels
local px, py = luna.window.toPixels(100, 100)

-- Convert physical pixels → logical (virtual) pixels
local lx, ly = luna.window.fromPixels(px, py)

-- ─────────────────────────────────────────────────────────────────────────────
-- Display Information
-- ─────────────────────────────────────────────────────────────────────────────

-- Number of connected displays
local display_count = luna.window.getDisplayCount()

-- Desktop dimensions for a display index (1‑based, default = 1)
local dw, dh = luna.window.getDesktopDimensions()
local dw2, dh2 = luna.window.getDesktopDimensions(2)  -- second monitor

-- Prevent the display from sleeping (useful for media or kiosk apps)
luna.window.setDisplaySleepEnabled(false)  -- keep display on

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Icon
-- ─────────────────────────────────────────────────────────────────────────────

-- Set the window's taskbar / titlebar icon (load with luna.gfx.newImage)
-- local icon_img = luna.gfx.newImage("icon.png")
-- luna.window.setIcon(icon_img)

-- ─────────────────────────────────────────────────────────────────────────────
-- Clipboard
-- ─────────────────────────────────────────────────────────────────────────────

-- Write text to the OS clipboard
luna.window.setClipboard("Hello from Luna2D!")

-- Read text from the clipboard (returns nil if clipboard is empty or non-text)
local text = luna.window.getClipboard()
if text then
    print("Clipboard:", text)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Callbacks
-- ─────────────────────────────────────────────────────────────────────────────

function luna.resize(w, h)
    -- Called when the window is resized (e.g., user drags the edge).
    -- Recreate any render targets or layout caches here.
    print("window resized to", w, h)
end

function luna.focus(hasFocus)
    -- Called when the window gains or loses keyboard focus.
    if not hasFocus then
        -- pause the game, silence audio, etc.
    end
end

function luna.visible(isVisible)
    -- Called when the window is minimized or restored.
    if not isVisible then
        -- pause heavy background work
    end
end

function luna.exit()
    -- Called when the OS requests the window to close (Alt+F4, ⌘Q, etc.).
    -- Return true to cancel the close (e.g., show a save dialog first).
    -- Return nil / false to allow the close (default behaviour).
    return false  -- allow quit
end


-- ─── luna.system ───────────────────────────────────────────────────────────────
luna.system.getArch()  -- Returns the CPU architecture string for the current machine
local args = luna.system.getArgs()  -- Returns the command-line arguments as a table
luna.system.getBatchResults({})  -- Returns the output table from the most recently completed runBatch call
luna.system.getClipboardText()  -- Returns the current contents of the system clipboard
luna.system.getDebugOverlay()  -- Returns whether the debug overlay is currently visible
luna.system.getEnv("name")  -- Returns the value of the named OS environment variable, or nil if not set
luna.system.getInfo()  -- Returns a table of system information including OS name, CPU model, and installed RAM
luna.system.getLastError()  -- Returns the last unhandled error message, or nil
luna.system.getLogLevel()  -- Returns the name of the current minimum log level for runtime messages
luna.system.getMemorySize()  -- Returns the total amount of installed system RAM in megabytes
luna.system.getOS()  -- Returns the host operating system name ('Windows', 'Linux', 'macOS')
luna.system.getPowerInfo()  -- Returns battery state, percentage charged, and estimated time remaining
luna.system.getPreferredLocales()  -- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US')
luna.system.getProcessorCount()  -- Returns the number of logical CPU cores available
luna.system.getVersion()  -- Returns the Luna2D engine version string
luna.system.log("info", "Game initialized")  -- Emit a log message at a specified level
luna.system.openURL("https://luna2d.io")  -- Opens URL in the system default browser
luna.system.parseArgs()  -- Parses a command-line argument string and returns a structured key/value table
luna.system.runBatch({})  -- Runs a list of shell commands in parallel and returns immediately without blocking
luna.system.setClipboardText("Copied text")  -- Replaces the system clipboard contentsgiven string
luna.system.setDebugOverlay(false)  -- Shows or hides the FPS/draw-call debug overlay
luna.system.setLogLevel("warn")  -- Minimum log level: "debug", "info", "warn", "error"ges

-- ─── luna.window ───────────────────────────────────────────────────────────────
luna.window.close()  -- Requests the window to close
luna.window.focus()  -- Requests the window manager to bring the window to the foreground
local d_p_i_scale = luna.window.getDPIScale()  -- Returns the DPI scaling factor for the window
local display_name = luna.window.getDisplayName()  -- Returns the name of the current display
local display_orientation = luna.window.getDisplayOrientation()  -- Returns the current display orientation
local fullscreen_modes = luna.window.getFullscreenModes()  -- Returns all available fullscreen video modes
local game_height = luna.window.getGameHeight()  -- Returns the logical game height in virtual pixels
local game_width = luna.window.getGameWidth()  -- Returns the logical game width in virtual pixels
local mode = luna.window.getMode()  -- Returns the window dimensions and mode flags as width, height, flags
local native_d_p_i_scale = luna.window.getNativeDPIScale()  -- Returns the native DPI scale factor
local pixel_dimensions = luna.window.getPixelDimensions()  -- Returns the window dimensions in physical pixels
local safe_area = luna.window.getSafeArea()  -- Returns the safe display area as x, y, w, h
local scale_info = luna.window.getScaleInfo()  -- Returns viewport scale and offset information as a table
local scale_mode = luna.window.getScaleMode()  -- Returns the current viewport scale mode string
local system_theme = luna.window.getSystemTheme()  -- Returns the OS color theme preference
local is_fullscreen = luna.window.isFullscreen()  -- Returns whether the window is in fullscreen mode
local is_high_d_p_i_allowed = luna.window.isHighDPIAllowed()  -- Returns whether high-DPI rendering is allowed
local is_resizable = luna.window.isResizable()  -- Returns whether the window can be resized by the user
luna.window.requestAttention()  -- Flashes the window in the taskbar to request user attention
luna.window.restore()  -- Restores the window from minimized or maximized state
luna.window.setMode(1, 1)  -- Resizes the window and optionally changes fullscreen and vsync
luna.window.setScaleMode("letterbox")  -- "stretch", "letterbox", "integer", "none"
local show_message_box = luna.window.showMessageBox("Error", "File not found.")  -- Shows a platform-native message box dialog
