-- examples/window.lua
-- Lurek2D lurek.window API Reference
-- Every lurek.window function is demonstrated with inline comments.

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Title
-- ─────────────────────────────────────────────────────────────────────────────

lurek.window.setTitle("My Awesome Game")
local title = lurek.window.getTitle()  -- → "My Awesome Game"

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Dimensions (virtual / logical pixels)
-- ─────────────────────────────────────────────────────────────────────────────

local w = lurek.window.getWidth()      -- logical width
local h = lurek.window.getHeight()     -- logical height
local ww, wh = lurek.window.getDimensions()  -- both at once

-- ─────────────────────────────────────────────────────────────────────────────
-- Fullscreen
-- ─────────────────────────────────────────────────────────────────────────────

-- Enter fullscreen  (type: "desktop" = borderless window | "exclusive" = native)
lurek.window.setFullscreen(true)
lurek.window.setFullscreen(true, "desktop")     -- borderless fullscreen (default)
lurek.window.setFullscreen(true, "exclusive")   -- exclusive fullscreen

-- Leave fullscreen
lurek.window.setFullscreen(false)

-- Query current state; returns (isFullscreen, type)
local is_fs, fs_type = lurek.window.getFullscreen()

-- Toggle convenience pattern:
function lurek.keypressed(key)
    if key == "f11" then
        lurek.window.setFullscreen(not lurek.window.getFullscreen())
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- VSync
-- ─────────────────────────────────────────────────────────────────────────────

-- VSync modes: "on" (fifo), "off" (immediate), "adaptive" (mailbox if available)
lurek.window.setVSync("on")
local vs = lurek.window.getVSync()  -- → "on" | "off" | "adaptive"

-- ─────────────────────────────────────────────────────────────────────────────
-- Window State Queries
-- ─────────────────────────────────────────────────────────────────────────────

local open = lurek.window.isOpen()           -- true while window exists
local focus = lurek.window.hasFocus()        -- keyboard focus
local mouse_focus = lurek.window.hasMouseFocus()  -- mouse is over window
local minimized = lurek.window.isMinimized()
local maximized = lurek.window.isMaximized()
local visible = lurek.window.isVisible()

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Visibility / Placement
-- ─────────────────────────────────────────────────────────────────────────────

lurek.window.minimize()    -- minimize to taskbar
lurek.window.maximize()    -- maximize to fill desktop

-- Move the window to a specific screen position (OS may ignore on some platforms)
lurek.window.setPosition(200, 100)

-- Get current top-left position relative to the primary display
local wx, wy = lurek.window.getPosition()

-- ─────────────────────────────────────────────────────────────────────────────
-- DPI / HiDPI Scaling
-- ─────────────────────────────────────────────────────────────────────────────

-- Convert logical (virtual) pixels → physical pixels
local px, py = lurek.window.toPixels(100, 100)

-- Convert physical pixels → logical (virtual) pixels
local lx, ly = lurek.window.fromPixels(px, py)

-- ─────────────────────────────────────────────────────────────────────────────
-- Display Information
-- ─────────────────────────────────────────────────────────────────────────────

-- Number of connected displays
local display_count = lurek.window.getDisplayCount()

-- Desktop dimensions for a display index (1‑based, default = 1)
local dw, dh = lurek.window.getDesktopDimensions()
local dw2, dh2 = lurek.window.getDesktopDimensions(2)  -- second monitor

-- Prevent the display from sleeping (useful for media or kiosk apps)
lurek.window.setDisplaySleepEnabled(false)  -- keep display on

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Icon
-- ─────────────────────────────────────────────────────────────────────────────

-- Set the window's taskbar / titlebar icon (load with lurek.gfx.newImage)
local icon_img = lurek.gfx.newImage("icon.png")
lurek.window.setIcon(icon_img)

-- ─────────────────────────────────────────────────────────────────────────────
-- Clipboard
-- ─────────────────────────────────────────────────────────────────────────────

-- Write text to the OS clipboard
lurek.window.setClipboard("Hello from Lurek2D!")

-- Read text from the clipboard (returns nil if clipboard is empty or non-text)
local text = lurek.window.getClipboard()
if text then
    print("Clipboard:", text)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Window Callbacks
-- ─────────────────────────────────────────────────────────────────────────────

function lurek.resize(w, h)
    -- Called when the window is resized (e.g., user drags the edge).
    -- Recreate any render targets or layout caches here.
    print("window resized to", w, h)
end

function lurek.focus(hasFocus)
    -- Called when the window gains or loses keyboard focus.
    if not hasFocus then
        -- pause the game, silence audio, etc.
    end
end

function lurek.visible(isVisible)
    -- Called when the window is minimized or restored.
    if not isVisible then
        -- pause heavy background work
    end
end

function lurek.exit()
    -- Called when the OS requests the window to close (Alt+F4, ⌘Q, etc.).
    -- Return true to cancel the close (e.g., show a save dialog first).
    -- Return nil / false to allow the close (default behaviour).
    return false  -- allow quit
end


-- ─── lurek.system ───────────────────────────────────────────────────────────────
lurek.system.getArch()  -- Returns the CPU architecture string for the current machine
local args = lurek.system.getArgs()  -- Returns the command-line arguments as a table
lurek.system.getBatchResults({})  -- Returns the output table from the most recently completed runBatch call
lurek.system.getClipboardText()  -- Returns the current contents of the system clipboard
lurek.system.getDebugOverlay()  -- Returns whether the debug overlay is currently visible
lurek.system.getEnv("name")  -- Returns the value of the named OS environment variable, or nil if not set
lurek.system.getInfo()  -- Returns a table of system information including OS name, CPU model, and installed RAM
lurek.system.getLastError()  -- Returns the last unhandled error message, or nil
lurek.system.getLogLevel()  -- Returns the name of the current minimum log level for runtime messages
lurek.system.getMemorySize()  -- Returns the total amount of installed system RAM in megabytes
lurek.system.getOS()  -- Returns the host operating system name ('Windows', 'Linux', 'macOS')
lurek.system.getPowerInfo()  -- Returns battery state, percentage charged, and estimated time remaining
lurek.system.getPreferredLocales()  -- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US')
lurek.system.getProcessorCount()  -- Returns the number of logical CPU cores available
lurek.system.getVersion()  -- Returns the Lurek2D engine version string
lurek.system.log("info", "Game initialized")  -- Emit a log message at a specified level
lurek.system.openURL("https://lurek2d.io")  -- Opens URL in the system default browser
lurek.system.parseArgs()  -- Parses a command-line argument string and returns a structured key/value table
lurek.system.runBatch({})  -- Runs a list of shell commands in parallel and returns immediately without blocking
lurek.system.setClipboardText("Copied text")  -- Replaces the system clipboard contentsgiven string
lurek.system.setDebugOverlay(false)  -- Shows or hides the FPS/draw-call debug overlay
lurek.system.setLogLevel("warn")  -- Minimum log level: "debug", "info", "warn", "error"ges

-- ─── lurek.window ───────────────────────────────────────────────────────────────
lurek.window.close()  -- Requests the window to close
lurek.window.focus()  -- Requests the window manager to bring the window to the foreground
local d_p_i_scale = lurek.window.getDPIScale()  -- Returns the DPI scaling factor for the window
local display_name = lurek.window.getDisplayName()  -- Returns the name of the current display
local display_orientation = lurek.window.getDisplayOrientation()  -- Returns the current display orientation
local fullscreen_modes = lurek.window.getFullscreenModes()  -- Returns all available fullscreen video modes
local game_height = lurek.window.getGameHeight()  -- Returns the logical game height in virtual pixels
local game_width = lurek.window.getGameWidth()  -- Returns the logical game width in virtual pixels
local mode = lurek.window.getMode()  -- Returns the window dimensions and mode flags as width, height, flags
local native_d_p_i_scale = lurek.window.getNativeDPIScale()  -- Returns the native DPI scale factor
local pixel_dimensions = lurek.window.getPixelDimensions()  -- Returns the window dimensions in physical pixels
local safe_area = lurek.window.getSafeArea()  -- Returns the safe display area as x, y, w, h
local scale_info = lurek.window.getScaleInfo()  -- Returns viewport scale and offset information as a table
local scale_mode = lurek.window.getScaleMode()  -- Returns the current viewport scale mode string
local system_theme = lurek.window.getSystemTheme()  -- Returns the OS color theme preference
local is_fullscreen = lurek.window.isFullscreen()  -- Returns whether the window is in fullscreen mode
local is_high_d_p_i_allowed = lurek.window.isHighDPIAllowed()  -- Returns whether high-DPI rendering is allowed
local is_resizable = lurek.window.isResizable()  -- Returns whether the window can be resized by the user
lurek.window.requestAttention()  -- Flashes the window in the taskbar to request user attention
lurek.window.restore()  -- Restores the window from minimized or maximized state
lurek.window.setMode(1, 1)  -- Resizes the window and optionally changes fullscreen and vsync
lurek.window.setScaleMode("letterbox")  -- "stretch", "letterbox", "integer", "none"
local show_message_box = lurek.window.showMessageBox("Error", "File not found.")  -- Shows a platform-native message box dialog
