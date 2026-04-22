-- content/examples/window.lua
-- Practical usage examples for the lurek.window API (50 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.window.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/window.lua

print("[example] lurek.window — 50 API entries")

-- ── lurek.window.* free functions ──

--@api-stub: lurek.window.setTitle
-- Sets the window title bar text.
-- Call when you need to assign title.
local ok, err = pcall(function() lurek.window.setTitle(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.window.setTitle applied=", ok)

--@api-stub: lurek.window.getTitle
-- Returns the current window title.
-- Call when you need to read title.
local ok, value = pcall(function() return lurek.window.getTitle() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getTitle ->", v)

--@api-stub: lurek.window.getWidth
-- Returns the window width in pixels.
-- Call when you need to read width.
local ok, value = pcall(function() return lurek.window.getWidth() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getWidth ->", v)

--@api-stub: lurek.window.getHeight
-- Returns the window height in pixels.
-- Call when you need to read height.
local ok, value = pcall(function() return lurek.window.getHeight() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getHeight ->", v)

--@api-stub: lurek.window.getDimensions
-- Returns the window dimensions as width, height.
-- Call when you need to read dimensions.
local ok, value = pcall(function() return lurek.window.getDimensions() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getDimensions ->", v)

--@api-stub: lurek.window.setFullscreen
-- Enables or disables fullscreen mode.
-- Call when you need to assign fullscreen.
local ok, err = pcall(function() lurek.window.setFullscreen(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.window.setFullscreen applied=", ok)

--@api-stub: lurek.window.getFullscreen
-- Returns the fullscreen state and type string.
-- Call when you need to read fullscreen.
local ok, value = pcall(function() return lurek.window.getFullscreen() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getFullscreen ->", v)

--@api-stub: lurek.window.isOpen
-- Returns whether the window is open.
-- Call when you need to check is open.
local ok, result = pcall(function() return lurek.window.isOpen() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isOpen ok=", ok)

--@api-stub: lurek.window.setVSync
-- Sets the VSync mode (1=on, 0=off, -1=adaptive).
-- Call when you need to assign v sync.
local ok, err = pcall(function() lurek.window.setVSync(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.window.setVSync applied=", ok)

--@api-stub: lurek.window.getVSync
-- Returns the current VSync mode integer.
-- Call when you need to read v sync.
local ok, value = pcall(function() return lurek.window.getVSync() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getVSync ->", v)

--@api-stub: lurek.window.hasFocus
-- Returns whether the window has keyboard focus.
-- Call when you need to check has focus.
local ok, result = pcall(function() return lurek.window.hasFocus() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.hasFocus ok=", ok)

--@api-stub: lurek.window.hasMouseFocus
-- Returns whether the mouse cursor is inside the window.
-- Call when you need to check has mouse focus.
local ok, result = pcall(function() return lurek.window.hasMouseFocus() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.hasMouseFocus ok=", ok)

--@api-stub: lurek.window.isMinimized
-- Returns whether the window is minimized.
-- Call when you need to check is minimized.
local ok, result = pcall(function() return lurek.window.isMinimized() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isMinimized ok=", ok)

--@api-stub: lurek.window.isMaximized
-- Returns whether the window is maximized.
-- Call when you need to check is maximized.
local ok, result = pcall(function() return lurek.window.isMaximized() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isMaximized ok=", ok)

--@api-stub: lurek.window.isVisible
-- Returns whether the window is visible.
-- Call when you need to check is visible.
local ok, result = pcall(function() return lurek.window.isVisible() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isVisible ok=", ok)

--@api-stub: lurek.window.minimize
-- Minimizes the window to the taskbar.
-- Call when you need to invoke minimize.
local ok, result = pcall(function() return lurek.window.minimize() end)
if ok then print("lurek.window.minimize ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.maximize
-- Maximizes the window to fill the desktop.
-- Call when you need to invoke maximize.
local ok, result = pcall(function() return lurek.window.maximize() end)
if ok then print("lurek.window.maximize ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.restore
-- Restores the window from minimized or maximized state.
-- Call when you need to invoke restore.
local ok, result = pcall(function() return lurek.window.restore() end)
if ok then print("lurek.window.restore ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.getPosition
-- Returns the window position as x, y in screen coordinates.
-- Call when you need to read position.
local ok, value = pcall(function() return lurek.window.getPosition() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getPosition ->", v)

--@api-stub: lurek.window.setPosition
-- Moves the window to the given screen position.
-- Call when you need to assign position.
local ok, err = pcall(function() lurek.window.setPosition(0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.window.setPosition applied=", ok)

--@api-stub: lurek.window.getDisplayCount
-- Returns the number of connected displays.
-- Call when you need to read display count.
local ok, value = pcall(function() return lurek.window.getDisplayCount() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getDisplayCount ->", v)

--@api-stub: lurek.window.getDesktopDimensions
-- Returns the desktop resolution as width, height.
-- Call when you need to read desktop dimensions.
local ok, value = pcall(function() return lurek.window.getDesktopDimensions() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getDesktopDimensions ->", v)

--@api-stub: lurek.window.getDPIScale
-- Returns the DPI scaling factor for the window.
-- Call when you need to read d p i scale.
local ok, value = pcall(function() return lurek.window.getDPIScale() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getDPIScale ->", v)

--@api-stub: lurek.window.toPixels
-- Converts a device-independent coordinate to physical pixels.
-- Call when you need to invoke to pixels.
local ok, result = pcall(function() return lurek.window.toPixels(nil) end)
if ok then print("lurek.window.toPixels ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.fromPixels
-- Converts physical pixels to device-independent coordinates.
-- Call when you need to invoke from pixels.
local ok, obj = pcall(function() return lurek.window.fromPixels(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.window.fromPixels ok=", ok)

--@api-stub: lurek.window.setIcon
-- Sets the window icon from a file path.
-- Call when you need to assign icon.
local ok, err = pcall(function() lurek.window.setIcon("path") end)
if not ok then print("set skipped:", err) end
print("lurek.window.setIcon applied=", ok)

--@api-stub: lurek.window.setMode
-- Resizes the window and optionally changes fullscreen and vsync.
-- Call when you need to assign mode.
local ok, err = pcall(function() lurek.window.setMode(100, 100, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.window.setMode applied=", ok)

--@api-stub: lurek.window.getMode
-- Returns the window dimensions and mode flags as width, height, flags.
-- Call when you need to read mode.
local ok, value = pcall(function() return lurek.window.getMode() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getMode ->", v)

--@api-stub: lurek.window.close
-- Requests the window to close.
-- Call when you need to invoke close.
local ok, result = pcall(function() return lurek.window.close() end)
if ok then print("lurek.window.close ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.requestAttention
-- Flashes the window in the taskbar to request user attention.
-- Call when you need to invoke request attention.
local ok, result = pcall(function() return lurek.window.requestAttention() end)
if ok then print("lurek.window.requestAttention ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.getFullscreenModes
-- Returns all available fullscreen video modes.
-- Call when you need to read fullscreen modes.
local ok, value = pcall(function() return lurek.window.getFullscreenModes() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getFullscreenModes ->", v)

--@api-stub: lurek.window.getDisplayName
-- Returns the name of the current display.
-- Call when you need to read display name.
local ok, value = pcall(function() return lurek.window.getDisplayName(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.window.getDisplayName ->", v)

--@api-stub: lurek.window.getPixelDimensions
-- Returns the window dimensions in physical pixels.
-- Call when you need to read pixel dimensions.
local ok, value = pcall(function() return lurek.window.getPixelDimensions() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getPixelDimensions ->", v)

--@api-stub: lurek.window.showMessageBox
-- Shows a platform-native message box dialog.
-- Call when you need to invoke show message box.
local ok, result = pcall(function() return lurek.window.showMessageBox() end)
if ok then print("lurek.window.showMessageBox ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.focus
-- Requests the window manager to bring the window to the foreground.
-- Call when you need to invoke focus.
local ok, result = pcall(function() return lurek.window.focus() end)
if ok then print("lurek.window.focus ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.getNativeDPIScale
-- Returns the native DPI scale factor.
-- Call when you need to read native d p i scale.
local ok, value = pcall(function() return lurek.window.getNativeDPIScale() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getNativeDPIScale ->", v)

--@api-stub: lurek.window.getDisplayOrientation
-- Returns the current display orientation.
-- Call when you need to read display orientation.
local ok, value = pcall(function() return lurek.window.getDisplayOrientation() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getDisplayOrientation ->", v)

--@api-stub: lurek.window.getSafeArea
-- Returns the safe display area as x, y, w, h.
-- Call when you need to read safe area.
local ok, value = pcall(function() return lurek.window.getSafeArea() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getSafeArea ->", v)

--@api-stub: lurek.window.getSystemTheme
-- Returns the OS color theme preference.
-- Call when you need to read system theme.
local ok, value = pcall(function() return lurek.window.getSystemTheme() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getSystemTheme ->", v)

--@api-stub: lurek.window.isHighDPIAllowed
-- Returns whether high-DPI rendering is allowed.
-- Call when you need to check is high d p i allowed.
local ok, result = pcall(function() return lurek.window.isHighDPIAllowed() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isHighDPIAllowed ok=", ok)

--@api-stub: lurek.window.getScaleInfo
-- Returns viewport scale and offset information as a table.
-- Call when you need to read scale info.
local ok, value = pcall(function() return lurek.window.getScaleInfo() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getScaleInfo ->", v)

--@api-stub: lurek.window.getScaleMode
-- Returns the current viewport scale mode string.
-- Call when you need to read scale mode.
local ok, value = pcall(function() return lurek.window.getScaleMode() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getScaleMode ->", v)

--@api-stub: lurek.window.setScaleMode
-- Sets the viewport scale mode.
-- Call when you need to assign scale mode.
local ok, err = pcall(function() lurek.window.setScaleMode(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.window.setScaleMode applied=", ok)

--@api-stub: lurek.window.getGameWidth
-- Returns the logical game width in virtual pixels.
-- Call when you need to read game width.
local ok, value = pcall(function() return lurek.window.getGameWidth() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getGameWidth ->", v)

--@api-stub: lurek.window.getGameHeight
-- Returns the logical game height in virtual pixels.
-- Call when you need to read game height.
local ok, value = pcall(function() return lurek.window.getGameHeight() end)
local v = ok and value or "(unavailable)"
print("lurek.window.getGameHeight ->", v)

--@api-stub: lurek.window.isFullscreen
-- Returns whether the window is in fullscreen mode.
-- Call when you need to check is fullscreen.
local ok, result = pcall(function() return lurek.window.isFullscreen() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isFullscreen ok=", ok)

--@api-stub: lurek.window.isResizable
-- Returns whether the window can be resized by the user.
-- Call when you need to check is resizable.
local ok, result = pcall(function() return lurek.window.isResizable() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.window.isResizable ok=", ok)

--@api-stub: lurek.window.onDpiChange
-- Registers a callback invoked (with the new scale factor) when the display.
-- Call when you need to invoke on dpi change.
local ok, result = pcall(function() return lurek.window.onDpiChange(function() end) end)
if ok then print("lurek.window.onDpiChange ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.pollDpiChange
-- Polls for a pending DPI change event and returns the new scale factor if any.
-- Call when you need to invoke poll dpi change.
local ok, result = pcall(function() return lurek.window.pollDpiChange() end)
if ok then print("lurek.window.pollDpiChange ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.window.openFileDialog
-- Opens a blocking native file-open dialog.
-- Returns the chosen path string.
local ok, obj = pcall(function() return lurek.window.openFileDialog({}) end)
if ok and obj then print("created:", obj) end
print("lurek.window.openFileDialog ok=", ok)

