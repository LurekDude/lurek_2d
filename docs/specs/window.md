# window

## General Info

- Module group: `Platform Services`
- Source path: `src/window/`
- Lua API path(s): `src/lua_api/window_api.rs`
- Primary Lua namespace: `lurek.window`
- Rust test path(s): tests/rust/unit/window_tests.rs
- Lua test path(s): tests/lua/unit/test_window_core_unit.lua

## Summary

The `window` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Platform Services group rather than absorb behavior owned by those neighbors.

## Files

- `event_loop.rs`: Owns monitor/event-loop helper functions for display enumeration, startup monitor selection, and centering windows on target monitors.
- `management.rs`: Owns window commands and queries such as title, fullscreen, vsync, size, position, minimize, maximize, restore, visibility, DPI scale, and message boxes.
- `mod.rs`: Declares the window submodules and re-exports the public management and viewport helpers as the module's main surface.
- `viewport.rs`: Owns logical game dimensions, scale-mode changes, and coordinate conversion between game space and on-screen pixels.

## Types

- `ModeInfo` (`struct`, `management.rs`): A compact snapshot of fullscreen and vsync state returned by the window mode query helpers.
- `ScaleInfo` (`struct`, `viewport.rs`): A read-only snapshot of current viewport scale, offsets, and logical game dimensions used by coordinate-conversion callers.

## Functions

- `set_title` (`management.rs`): Schedules a window title change for the next frame.
- `set_fullscreen` (`management.rs`): Schedules a fullscreen mode change.
- `is_fullscreen` (`management.rs`): Returns whether the window is currently in fullscreen mode.
- `set_vsync` (`management.rs`): Schedules a VSync mode change.
- `get_vsync` (`management.rs`): Returns the current VSync mode integer.
- `get_dpi_scale` (`management.rs`): Returns the DPI scale factor of the display the window is on.
- `get_position` (`management.rs`): Returns the current window position in screen coordinates as `(x, y)`.
- `set_position` (`management.rs`): Schedules a window position change to `(x, y)` in screen coordinates.
- `set_display` (`management.rs`): Schedules moving the window to a selected monitor index.
- `minimize` (`management.rs`): Schedules a window minimize (iconify) operation.
- `maximize` (`management.rs`): Schedules a window maximize operation.
- `restore` (`management.rs`): Schedules a window restore from minimized or maximized state.
- `is_minimized` (`management.rs`): Returns whether the window is currently minimized.
- `is_maximized` (`management.rs`): Returns whether the window is currently maximized.
- `has_focus` (`management.rs`): Returns whether the window currently has keyboard focus.
- `request_attention` (`management.rs`): Schedules a user-attention request (taskbar flash on Windows / dock bounce on macOS).
- `flash` (`management.rs`): Alias for `request_attention`.
- `close` (`management.rs`): Schedules window closure on the next frame, exiting the game loop.
- `set_icon` (`management.rs`): Schedules a window icon change from the given file path.
- `set_size` (`management.rs`): Schedules a window resize to `(w, h)` logical pixels.
- `get_fullscreen_type_str` (`management.rs`): Returns the fullscreen type as a lowercase string.
- `get_fullscreen` (`management.rs`): Returns the fullscreen state and type as a `(bool, &str)` pair.
- `is_visible` (`management.rs`): Returns whether the window is currently visible.
- `has_mouse_focus` (`management.rs`): Returns whether the mouse cursor is inside the window.
- `to_dpi_pixels` (`management.rs`): Converts a device-independent value to physical pixels using the DPI scale.
- `from_dpi_pixels` (`management.rs`): Converts a physical pixel value to device-independent coordinates.
- `get_pixel_dimensions` (`management.rs`): Returns the window dimensions in physical pixels (logical size × DPI scale).
- `set_mode` (`management.rs`): Schedules a combined window mode change (size + optional fullscreen + optional vsync).
- `get_mode` (`management.rs`): Returns the current window mode settings.
- `show_message_box` (`management.rs`): Shows a platform-native message box dialog.
- `get_width` (`viewport.rs`): Returns the logical game width in virtual pixels.
- `get_height` (`viewport.rs`): Returns the logical game height in virtual pixels.
- `get_scale_mode` (`viewport.rs`): Returns the current viewport scale mode string.
- `set_scale_mode` (`viewport.rs`): Schedules a viewport scale mode change.
- `to_pixels` (`viewport.rs`): Converts game-space coordinates `(x, y)` to window pixel coordinates.
- `from_pixels` (`viewport.rs`): Converts window pixel coordinates `(x, y)` back to game-space coordinates.
- `get_scale_info` (`viewport.rs`): Returns the current viewport scale and offset information.
- `set_scale_mode_validated` (`viewport.rs`): Validates and schedules a viewport scale mode change.
- `get_displays` (`event_loop.rs`): Returns structured metadata for connected displays.
- `current_display_index` (`event_loop.rs`): Resolves which display currently contains the window.
- `desktop_dimensions_for_display` (`event_loop.rs`): Returns desktop size for a selected display.
- `display_name_for_display` (`event_loop.rs`): Returns display name for a selected display.
- `move_window_to_display` (`event_loop.rs`): Centers and moves the window to a selected monitor.
- `select_startup_monitor` (`event_loop.rs`): Chooses startup monitor with primary fallback.
- `center_window_on_monitor` (`event_loop.rs`): Centers the window in monitor bounds.

## Lua API Reference

- Binding path(s): `src/lua_api/window_api.rs`
- Namespace: `lurek.window`

### Module Functions
- `lurek.window.setTitle`: Sets the text displayed in the window's title bar.
- `lurek.window.getTitle`: Returns the current window title bar text as a string.
- `lurek.window.getWidth`: Returns the current window width in logical pixels.
- `lurek.window.getHeight`: Returns the current window height in logical pixels.
- `lurek.window.getDimensions`: Returns the window dimensions as two values (width, height) in logical pixels.
- `lurek.window.setFullscreen`: Enables or disables fullscreen mode.
- `lurek.window.getFullscreen`: Returns the current fullscreen state as two values: a boolean indicating whether fullscreen is active, and a string describing the type ("desktop" or "exclusive").
- `lurek.window.isOpen`: Returns whether the window is currently open and active.
- `lurek.window.setVSync`: Sets the vertical synchronisation mode for the window's swap chain.
- `lurek.window.getVSync`: Returns the current vertical synchronisation mode as an integer: 1 = VSync on, 0 = VSync off, -1 = adaptive VSync.
- `lurek.window.hasFocus`: Returns whether the window currently has keyboard input focus from the operating system.
- `lurek.window.hasMouseFocus`: Returns whether the mouse cursor is currently inside the window's client area.
- `lurek.window.isMinimized`: Returns whether the window is currently minimised to the taskbar.
- `lurek.window.isMaximized`: Returns whether the window is currently maximised to fill the entire desktop work area.
- `lurek.window.isVisible`: Returns whether the window is currently visible on screen.
- `lurek.window.minimize`: Minimises the window to the operating system taskbar or dock.
- `lurek.window.maximize`: Maximises the window so it fills the entire desktop work area, excluding the taskbar.
- `lurek.window.restore`: Restores the window to its previous size and position after a `minimize` or `maximize` call.
- `lurek.window.getPosition`: Returns the top-left corner position of the window in screen coordinates as two values (x, y).
- `lurek.window.setPosition`: Moves the top-left corner of the window to the given screen coordinates.
- `lurek.window.getDisplayCount`: Returns the number of displays (monitors) currently connected to the system.
- `lurek.window.getDisplays`: Returns array metadata for all connected displays.
- `lurek.window.getCurrentDisplay`: Returns the index of the monitor the window is currently on.
- `lurek.window.setDisplay`: Queues moving the window to the selected monitor index.
- `lurek.window.getDesktopDimensions`: Returns desktop resolution for the selected monitor (or current monitor by default).
- `lurek.window.getDPIScale`: Returns the current DPI scaling factor for the window as a number.
- `lurek.window.toPixels`: Converts a device-independent (logical) coordinate value to its equivalent in physical pixels using the current DPI scale factor.
- `lurek.window.fromPixels`: Converts a physical pixel value back to device-independent (logical) coordinates using the current DPI scale factor.
- `lurek.window.setIcon`: Sets the window icon from an image file located in the game directory.
- `lurek.window.setMode`: Resizes the window and optionally changes fullscreen and vsync settings in a single call.
- `lurek.window.getMode`: Returns the current window dimensions and mode flags as three values: width, height, and a flags table.
- `lurek.window.close`: Requests the window to close, which will end the game loop after the current frame finishes.
- `lurek.window.requestAttention`: Flashes the window icon in the operating system taskbar or dock to attract the user's attention.
- `lurek.window.flash`: Alias for `requestAttention`.
- `lurek.window.getFullscreenModes`: Returns an array of all available fullscreen video modes supported by the current monitor.
- `lurek.window.getDisplayName`: Returns the human-readable name of a connected display as reported by the operating system (for example "DELL U2723QE" or "Built-in Retina").
- `lurek.window.getPixelDimensions`: Returns the window dimensions in physical (device) pixels as two values (width, height).
- `lurek.window.showMessageBox`: Shows a platform-native message box dialog.
- `lurek.window.focus`: Requests the window manager to bring the window to the foreground.
- `lurek.window.getNativeDPIScale`: Returns the native DPI scale factor.
- `lurek.window.getDisplayOrientation`: Returns the current display orientation.
- `lurek.window.getSafeArea`: Returns the safe display area as x, y, w, h.
- `lurek.window.getSystemTheme`: Returns the OS color theme preference.
- `lurek.window.isHighDPIAllowed`: Returns whether high-DPI rendering is allowed.
- `lurek.window.getScaleInfo`: Returns viewport scale and offset information as a table.
- `lurek.window.getScaleMode`: Returns the current viewport scale mode string.
- `lurek.window.setScaleMode`: Sets the viewport scale mode.
- `lurek.window.getGameWidth`: Returns the logical game width in virtual pixels.
- `lurek.window.getGameHeight`: Returns the logical game height in virtual pixels.
- `lurek.window.isFullscreen`: Returns whether the window is in fullscreen mode.
- `lurek.window.isResizable`: Returns whether the window can be resized by the user.
- `lurek.window.onDpiChange`: Registers a callback invoked (with the new scale factor) when the display DPI changes.
- `lurek.window.pollDpiChange`: Checks whether the DPI scale has changed since the last call and fires the onDpiChange callback if so.
- `lurek.window.openFileDialog`: Opens a blocking native file-open dialog.

### Grouped API Tables
- `lurek.window.display`: Aliases display operations (`getCount`, `getName`, `getDesktopDimensions`, `getDisplays`, `getCurrent`, `setCurrent`).
- `lurek.window.mode`: Aliases mode operations (`set`, `get`, `setFullscreen`, `getFullscreen`, `isFullscreen`, `setVSync`, `getVSync`, `minimize`, `maximize`, `restore`, `isMinimized`, `isMaximized`, `isVisible`, `requestAttention`, `flash`).
- `lurek.window.cursor`: Cursor-focus grouping (`hasFocus`).

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/window/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### Already in place (0.14.0)

- `lurek.window.setPosition(x, y)` / `getPosition()` — implemented via `WindowState.pending_position` and `src/window/management.rs`. IDEA.md was outdated; implementation predates 0.14.1.

### Recent sync (1.0.9-fix.46)

- Implemented multi-monitor enhancement from IDEA: `getDisplays`, `setDisplay`, `getCurrentDisplay`, optional display-index support in `getDesktopDimensions` and `getDisplayName`.
- Implemented API discoverability enhancement: non-breaking grouped aliases under `lurek.window.display`, `lurek.window.mode`, and `lurek.window.cursor`.
- Implemented event-loop placeholder cleanup: `src/window/event_loop.rs` now owns reusable monitor helpers consumed by `app`.

### Recent sync (1.0.9-fix.73)

- Added helper `lurek.window.windowConfig(opts)` to apply common window boot/config patterns in one call.
- Clarified viewport-transform boundary:
  - `window::viewport` owns conversion helpers and scale-mode request surface.
  - `camera` owns world-camera math and view-space transforms.
