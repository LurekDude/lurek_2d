# `window` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.window` |
| **Source** | `src/window/` |
| **Rust Tests** | `tests/rust/unit/window_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_window.lua`, `tests/lua/unit/test_window_scaling.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The `window` module owns engine-level window state and viewport conversion helpers. Its job is to expose a clean Rust surface for title changes, fullscreen and vsync requests, resizing, position changes, focus queries, DPI conversion, and game-space to pixel-space mapping.

This module exists to keep window policy testable and separate from the live OS window handle. Most write operations update `WindowState` pending fields, and the app layer applies those requests on the next frame through `winit`. That split lets Lua and Rust gameplay code request window behavior without importing platform code into unrelated systems.

The module intentionally does not own the actual event loop, swapchain/surface management, or renderer presentation. `engine::app` and the runtime state own the live window object, and `render` owns drawing. The `event_loop` file is currently just a reserved placeholder rather than an active subsystem.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.window.* (Lua API — src/lua_api/window_api.rs)
    |
    v
src/window/mod.rs
    |- event_loop.rs - event_loop
    |- management.rs - management
    |- viewport.rs - viewport
```

---

## Source Files

| File | Purpose |
|------|---------|
| `event_loop.rs` | Reserved placeholder for future event-loop specific code; current event-loop behavior lives outside this module. |
| `management.rs` | Owns window commands and queries such as title, fullscreen, vsync, size, position, minimize, maximize, restore, visibility, DPI scale, and message boxes. |
| `mod.rs` | Declares the window submodules and re-exports the public management and viewport helpers as the module's main surface. |
| `viewport.rs` | Owns logical game dimensions, scale-mode changes, and coordinate conversion between game space and on-screen pixels. |

---

## Submodules

### `window::event_loop`

Reserved placeholder for future event-loop specific code; current event-loop behavior lives outside this module.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `window::management`

Owns window commands and queries such as title, fullscreen, vsync, size, position, minimize, maximize, restore, visibility, DPI scale, and message boxes.

- **`ModeInfo`** (struct): Information about the current window mode.

### `window::viewport`

Owns logical game dimensions, scale-mode changes, and coordinate conversion between game space and on-screen pixels.

- **`ScaleInfo`** (struct): Viewport scale and offset information.

---

## Key Types

### Public Types

#### `ModeInfo`

A compact snapshot of fullscreen and vsync state returned by the window mode query helpers.

#### `ScaleInfo`

A read-only snapshot of current viewport scale, offsets, and logical game dimensions used by coordinate-conversion callers.

#### `WindowState`

The core state object this module reads and mutates, even though it is defined in the runtime shared-state layer rather than here.

#### `FullscreenType`

The runtime enum used to distinguish desktop and exclusive fullscreen requests.

---

## Lua API

Exposed under `lurek.window.*` by `src/lua_api/window_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.window.setTitle` | Sets the window title bar text. |
| `lurek.window.getTitle` | Returns the current window title. |
| `lurek.window.getWidth` | Returns the window width in pixels. |
| `lurek.window.getHeight` | Returns the window height in pixels. |
| `lurek.window.getDimensions` | Returns the window dimensions as width, height. |
| `lurek.window.setFullscreen` | Enables or disables fullscreen mode. |
| `lurek.window.getFullscreen` | Returns the fullscreen state and type string. |
| `lurek.window.isOpen` | Returns whether the window is open. |
| `lurek.window.setVSync` | Sets the VSync mode (1=on, 0=off, -1=adaptive). |
| `lurek.window.getVSync` | Returns the current VSync mode integer. |
| `lurek.window.hasFocus` | Returns whether the window has keyboard focus. |
| `lurek.window.hasMouseFocus` | Returns whether the mouse cursor is inside the window. |
| `lurek.window.isMinimized` | Returns whether the window is minimized. |
| `lurek.window.isMaximized` | Returns whether the window is maximized. |
| `lurek.window.isVisible` | Returns whether the window is visible. |
| `lurek.window.minimize` | Minimizes the window to the taskbar. |
| `lurek.window.maximize` | Maximizes the window to fill the desktop. |
| `lurek.window.restore` | Restores the window from minimized or maximized state. |
| `lurek.window.getPosition` | Returns the window position as x, y in screen coordinates. |
| `lurek.window.setPosition` | Moves the window to the given screen position. |
| `lurek.window.getDisplayCount` | Returns the number of connected displays. |
| `lurek.window.getDesktopDimensions` | Returns the desktop resolution as width, height. |
| `lurek.window.getDPIScale` | Returns the DPI scaling factor for the window. |
| `lurek.window.toPixels` | Converts a device-independent coordinate to physical pixels. |
| `lurek.window.fromPixels` | Converts physical pixels to device-independent coordinates. |
| `lurek.window.setIcon` | Sets the window icon from a file path. |
| `lurek.window.setMode` | Resizes the window and optionally changes fullscreen and vsync. |
| `lurek.window.getMode` | Returns the window dimensions and mode flags as width, height, flags. |
| `lurek.window.close` | Requests the window to close. |
| `lurek.window.requestAttention` | Flashes the window in the taskbar to request user attention. |
| `lurek.window.getFullscreenModes` | Returns all available fullscreen video modes. |
| `lurek.window.getDisplayName` | Returns the name of the current display. |
| `lurek.window.getPixelDimensions` | Returns the window dimensions in physical pixels. |
| `lurek.window.showMessageBox` | Shows a platform-native message box dialog. |
| `lurek.window.focus` | Requests the window manager to bring the window to the foreground. |
| `lurek.window.getNativeDPIScale` | Returns the native DPI scale factor. |
| `lurek.window.getDisplayOrientation` | Returns the current display orientation. |
| `lurek.window.getSafeArea` | Returns the safe display area as x, y, w, h. |
| `lurek.window.getSystemTheme` | Returns the OS color theme preference. |
| `lurek.window.isHighDPIAllowed` | Returns whether high-DPI rendering is allowed. |
| `lurek.window.getScaleInfo` | Returns viewport scale and offset information as a table. |
| `lurek.window.getScaleMode` | Returns the current viewport scale mode string. |
| `lurek.window.setScaleMode` | Sets the viewport scale mode. |
| `lurek.window.getGameWidth` | Returns the logical game width in virtual pixels. |
| `lurek.window.getGameHeight` | Returns the logical game height in virtual pixels. |
| `lurek.window.isFullscreen` | Returns whether the window is in fullscreen mode. |
| `lurek.window.isResizable` | Returns whether the window can be resized by the user. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.window.
if lurek.window then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 2 |
| `enum` | 0 |
| `fn` (Lua API) | 47 |
| **Total** | **49** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/window/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
