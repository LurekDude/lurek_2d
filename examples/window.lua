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
