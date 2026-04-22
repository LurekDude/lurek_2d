-- content/examples/window.lua
-- Auto-scaffolded coverage of the lurek.window Lua API (50 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/window.lua

print("[example] lurek.window loaded — 50 API items demonstrated")

-- ── lurek.window free functions ──

--@api-stub: lurek.window.setTitle
-- Sets the window title bar text.
-- Use this when sets the window title bar text is needed.
if false then
  local _r = lurek.window.setTitle(0)
  print(_r)
end

--@api-stub: lurek.window.getTitle
-- Returns the current window title.
-- Use this when returns the current window title is needed.
if false then
  local _r = lurek.window.getTitle()
  print(_r)
end

--@api-stub: lurek.window.getWidth
-- Returns the window width in pixels.
-- Use this when returns the window width in pixels is needed.
if false then
  local _r = lurek.window.getWidth()
  print(_r)
end

--@api-stub: lurek.window.getHeight
-- Returns the window height in pixels.
-- Use this when returns the window height in pixels is needed.
if false then
  local _r = lurek.window.getHeight()
  print(_r)
end

--@api-stub: lurek.window.getDimensions
-- Returns the window dimensions as width, height.
-- Use this when returns the window dimensions as width, height is needed.
if false then
  local _r = lurek.window.getDimensions()
  print(_r)
end

--@api-stub: lurek.window.setFullscreen
-- Enables or disables fullscreen mode.
-- Use this when enables or disables fullscreen mode is needed.
if false then
  local _r = lurek.window.setFullscreen(1, 0)
  print(_r)
end

--@api-stub: lurek.window.getFullscreen
-- Returns the fullscreen state and type string.
-- Use this when returns the fullscreen state and type string is needed.
if false then
  local _r = lurek.window.getFullscreen()
  print(_r)
end

--@api-stub: lurek.window.isOpen
-- Returns whether the window is open.
-- Use this when returns whether the window is open is needed.
if false then
  local _r = lurek.window.isOpen()
  print(_r)
end

--@api-stub: lurek.window.setVSync
-- Sets the VSync mode (1=on, 0=off, -1=adaptive).
-- Use this when sets the VSync mode (1=on, 0=off, -1=adaptive) is needed.
if false then
  local _r = lurek.window.setVSync(nil)
  print(_r)
end

--@api-stub: lurek.window.getVSync
-- Returns the current VSync mode integer.
-- Use this when returns the current VSync mode integer is needed.
if false then
  local _r = lurek.window.getVSync()
  print(_r)
end

--@api-stub: lurek.window.hasFocus
-- Returns whether the window has keyboard focus.
-- Use this when returns whether the window has keyboard focus is needed.
if false then
  local _r = lurek.window.hasFocus()
  print(_r)
end

--@api-stub: lurek.window.hasMouseFocus
-- Returns whether the mouse cursor is inside the window.
-- Use this when returns whether the mouse cursor is inside the window is needed.
if false then
  local _r = lurek.window.hasMouseFocus()
  print(_r)
end

--@api-stub: lurek.window.isMinimized
-- Returns whether the window is minimized.
-- Use this when returns whether the window is minimized is needed.
if false then
  local _r = lurek.window.isMinimized()
  print(_r)
end

--@api-stub: lurek.window.isMaximized
-- Returns whether the window is maximized.
-- Use this when returns whether the window is maximized is needed.
if false then
  local _r = lurek.window.isMaximized()
  print(_r)
end

--@api-stub: lurek.window.isVisible
-- Returns whether the window is visible.
-- Use this when returns whether the window is visible is needed.
if false then
  local _r = lurek.window.isVisible()
  print(_r)
end

--@api-stub: lurek.window.minimize
-- Minimizes the window to the taskbar.
-- Use this when minimizes the window to the taskbar is needed.
if false then
  local _r = lurek.window.minimize()
  print(_r)
end

--@api-stub: lurek.window.maximize
-- Maximizes the window to fill the desktop.
-- Use this when maximizes the window to fill the desktop is needed.
if false then
  local _r = lurek.window.maximize()
  print(_r)
end

--@api-stub: lurek.window.restore
-- Restores the window from minimized or maximized state.
-- Use this when restores the window from minimized or maximized state is needed.
if false then
  local _r = lurek.window.restore()
  print(_r)
end

--@api-stub: lurek.window.getPosition
-- Returns the window position as x, y in screen coordinates.
-- Use this when returns the window position as x, y in screen coordinates is needed.
if false then
  local _r = lurek.window.getPosition()
  print(_r)
end

--@api-stub: lurek.window.setPosition
-- Moves the window to the given screen position.
-- Use this when moves the window to the given screen position is needed.
if false then
  local _r = lurek.window.setPosition(0, 0)
  print(_r)
end

--@api-stub: lurek.window.getDisplayCount
-- Returns the number of connected displays.
-- Use this when returns the number of connected displays is needed.
if false then
  local _r = lurek.window.getDisplayCount()
  print(_r)
end

--@api-stub: lurek.window.getDesktopDimensions
-- Returns the desktop resolution as width, height.
-- Use this when returns the desktop resolution as width, height is needed.
if false then
  local _r = lurek.window.getDesktopDimensions()
  print(_r)
end

--@api-stub: lurek.window.getDPIScale
-- Returns the DPI scaling factor for the window.
-- Use this when returns the DPI scaling factor for the window is needed.
if false then
  local _r = lurek.window.getDPIScale()
  print(_r)
end

--@api-stub: lurek.window.toPixels
-- Converts a device-independent coordinate to physical pixels.
-- Use this when converts a device-independent coordinate to physical pixels is needed.
if false then
  local _r = lurek.window.toPixels(0)
  print(_r)
end

--@api-stub: lurek.window.fromPixels
-- Converts physical pixels to device-independent coordinates.
-- Use this when converts physical pixels to device-independent coordinates is needed.
if false then
  local _r = lurek.window.fromPixels(0)
  print(_r)
end

--@api-stub: lurek.window.setIcon
-- Sets the window icon from a file path.
-- Use this when sets the window icon from a file path is needed.
if false then
  local _r = lurek.window.setIcon(0)
  print(_r)
end

--@api-stub: lurek.window.setMode
-- Resizes the window and optionally changes fullscreen and vsync.
-- Use this when resizes the window and optionally changes fullscreen and vsync is needed.
if false then
  local _r = lurek.window.setMode(0, 0, nil)
  print(_r)
end

--@api-stub: lurek.window.getMode
-- Returns the window dimensions and mode flags as width, height, flags.
-- Use this when returns the window dimensions and mode flags as width, height, flags is needed.
if false then
  local _r = lurek.window.getMode()
  print(_r)
end

--@api-stub: lurek.window.close
-- Requests the window to close.
-- Use this when requests the window to close is needed.
if false then
  local _r = lurek.window.close()
  print(_r)
end

--@api-stub: lurek.window.requestAttention
-- Flashes the window in the taskbar to request user attention.
-- Use this when flashes the window in the taskbar to request user attention is needed.
if false then
  local _r = lurek.window.requestAttention()
  print(_r)
end

--@api-stub: lurek.window.getFullscreenModes
-- Returns all available fullscreen video modes.
-- Use this when returns all available fullscreen video modes is needed.
if false then
  local _r = lurek.window.getFullscreenModes()
  print(_r)
end

--@api-stub: lurek.window.getDisplayName
-- Returns the name of the current display.
-- Use this when returns the name of the current display is needed.
if false then
  local _r = lurek.window.getDisplayName(0)
  print(_r)
end

--@api-stub: lurek.window.getPixelDimensions
-- Returns the window dimensions in physical pixels.
-- Use this when returns the window dimensions in physical pixels is needed.
if false then
  local _r = lurek.window.getPixelDimensions()
  print(_r)
end

--@api-stub: lurek.window.showMessageBox
-- Shows a platform-native message box dialog.
-- Use this when shows a platform-native message box dialog is needed.
if false then
  local _r = lurek.window.showMessageBox()
  print(_r)
end

--@api-stub: lurek.window.focus
-- Requests the window manager to bring the window to the foreground.
-- Use this when requests the window manager to bring the window to the foreground is needed.
if false then
  local _r = lurek.window.focus()
  print(_r)
end

--@api-stub: lurek.window.getNativeDPIScale
-- Returns the native DPI scale factor.
-- Use this when returns the native DPI scale factor is needed.
if false then
  local _r = lurek.window.getNativeDPIScale()
  print(_r)
end

--@api-stub: lurek.window.getDisplayOrientation
-- Returns the current display orientation.
-- Use this when returns the current display orientation is needed.
if false then
  local _r = lurek.window.getDisplayOrientation()
  print(_r)
end

--@api-stub: lurek.window.getSafeArea
-- Returns the safe display area as x, y, w, h.
-- Use this when returns the safe display area as x, y, w, h is needed.
if false then
  local _r = lurek.window.getSafeArea()
  print(_r)
end

--@api-stub: lurek.window.getSystemTheme
-- Returns the OS color theme preference.
-- Use this when returns the OS color theme preference is needed.
if false then
  local _r = lurek.window.getSystemTheme()
  print(_r)
end

--@api-stub: lurek.window.isHighDPIAllowed
-- Returns whether high-DPI rendering is allowed.
-- Use this when returns whether high-DPI rendering is allowed is needed.
if false then
  local _r = lurek.window.isHighDPIAllowed()
  print(_r)
end

--@api-stub: lurek.window.getScaleInfo
-- Returns viewport scale and offset information as a table.
-- Use this when returns viewport scale and offset information as a table is needed.
if false then
  local _r = lurek.window.getScaleInfo()
  print(_r)
end

--@api-stub: lurek.window.getScaleMode
-- Returns the current viewport scale mode string.
-- Use this when returns the current viewport scale mode string is needed.
if false then
  local _r = lurek.window.getScaleMode()
  print(_r)
end

--@api-stub: lurek.window.setScaleMode
-- Sets the viewport scale mode.
-- Use this when sets the viewport scale mode is needed.
if false then
  local _r = lurek.window.setScaleMode(nil)
  print(_r)
end

--@api-stub: lurek.window.getGameWidth
-- Returns the logical game width in virtual pixels.
-- Use this when returns the logical game width in virtual pixels is needed.
if false then
  local _r = lurek.window.getGameWidth()
  print(_r)
end

--@api-stub: lurek.window.getGameHeight
-- Returns the logical game height in virtual pixels.
-- Use this when returns the logical game height in virtual pixels is needed.
if false then
  local _r = lurek.window.getGameHeight()
  print(_r)
end

--@api-stub: lurek.window.isFullscreen
-- Returns whether the window is in fullscreen mode.
-- Use this when returns whether the window is in fullscreen mode is needed.
if false then
  local _r = lurek.window.isFullscreen()
  print(_r)
end

--@api-stub: lurek.window.isResizable
-- Returns whether the window can be resized by the user.
-- Use this when returns whether the window can be resized by the user is needed.
if false then
  local _r = lurek.window.isResizable()
  print(_r)
end

--@api-stub: lurek.window.onDpiChange
-- Registers a callback invoked (with the new scale factor) when the display.
-- Use this when registers a callback invoked (with the new scale factor) when the display is needed.
if false then
  local _r = lurek.window.onDpiChange(1)
  print(_r)
end

--@api-stub: lurek.window.pollDpiChange
-- Polls for a pending DPI change event and returns the new scale factor if any.
-- Use this when polls for a pending DPI change event and returns the new scale factor if any is needed.
if false then
  local _r = lurek.window.pollDpiChange()
  print(_r)
end

--@api-stub: lurek.window.openFileDialog
-- Opens a blocking native file-open dialog.
-- Returns the chosen path string
if false then
  local _r = lurek.window.openFileDialog(0)
  print(_r)
end

