# `window` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.window`                                        |
| **Source**     | `src/window/`                                        |
| **Rust Tests** | `tests/rust/unit/window_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_window.lua`                     |
| **Architecture** | —                                                  |

## Summary

The `window` module is a Tier 1 core engine subsystem that manages all window lifecycle properties and viewport coordinate-space transforms. It provides pure Rust helper functions that read and mutate `WindowState` fields stored inside `SharedState`. **No winit or wgpu calls are made anywhere in this module.** Instead, operations that require OS interaction — title changes, fullscreen toggles, resizing, icon updates, minimize/maximize — are written into `pending_*` fields on `WindowState`. The engine's `App` event loop (in `engine::app`) consumes those pending fields at the start of the next frame and applies them to the actual winit `Window` handle. This deferred-write architecture keeps the module fully testable without a display server or GPU context, which is critical for headless CI and the Lua BDD test harness.

The module is split into three submodules. `management` owns all window-chrome operations: title, fullscreen mode (desktop or exclusive), VSync, screen position, size, minimize, maximize, restore, close, icon, focus query, visibility, mouse-focus, DPI scale, and a platform-native message box dialog via the `rfd` crate. `viewport` owns the logical game-space coordinate system: game width/height, four scale modes (`none`, `letterbox`, `stretch`, `pixel`), and bidirectional pixel ↔ game-space conversion using pre-computed scale/offset values that `engine::app` recalculates on every resize. `event_loop` is a reserved placeholder for future platform-specific event-loop integration — it currently contains no code.

The Lua surface (`lurek.window.*`, 39 functions) exposes the full management and viewport API plus several display-query conveniences (`getDesktopDimensions`, `getDisplayCount`, `getDisplayName`, `getFullscreenModes`, `getDisplayOrientation`, `getSafeArea`, `getSystemTheme`, `isHighDPIAllowed`, `isResizable`) that read directly from the winit `Window` handle stored in `SharedState`.

**Scope boundary**: The actual winit `Window` handle, the wgpu `Surface`, and all OS-level window manipulation live in `engine::app`. This module only reads and writes the `WindowState` shadow record and provides coordinate-conversion math.

## Architecture

```
                    ┌──────────────────────────────────┐
                    │          engine::app::App         │
                    │  (winit Window + wgpu Surface)    │
                    │  reads pending_* ──► OS calls     │
                    │  recomputes viewport scale/offset │
                    └──────────┬───────────────────────┘
                               │ &mut WindowState
                    ┌──────────▼───────────────────────┐
                    │         window (mod.rs)           │
                    │  re-exports from management +     │
                    │  viewport submodules              │
                    ├──────────────────────────────────┤
                    │  management.rs                    │
                    │   set_title  set_fullscreen       │
                    │   set_vsync  set_position         │
                    │   set_size   set_mode             │
                    │   minimize   maximize   restore   │
                    │   close      set_icon             │
                    │   request_attention               │
                    │   is_*/has_*/get_* queries         │
                    │   show_message_box (rfd)          │
                    │   to_/from_dpi_pixels             │
                    │   ModeInfo                        │
                    ├──────────────────────────────────┤
                    │  viewport.rs                      │
                    │   get_width  get_height           │
                    │   get_scale_mode  set_scale_mode  │
                    │   to_pixels   from_pixels         │
                    │   get_scale_info                  │
                    │   set_scale_mode_validated        │
                    │   ScaleInfo                       │
                    ├──────────────────────────────────┤
                    │  event_loop.rs                    │
                    │   (reserved — no public items)    │
                    └──────────────────────────────────┘
                               │
                    ┌──────────▼───────────────────────┐
                    │   engine::shared_state            │
                    │   WindowState, FullscreenType     │
                    └──────────────────────────────────┘
```

## Source Files

| File             | Purpose                                                                                              |
|------------------|------------------------------------------------------------------------------------------------------|
| `mod.rs`         | Module root — declares submodules and re-exports all public functions and types from `management` and `viewport`. |
| `event_loop.rs`  | Reserved placeholder for future platform-specific event-loop integration. Currently contains no public items. |
| `management.rs`  | Window chrome operations — title, fullscreen, VSync, position, size, minimize, maximize, restore, close, icon, focus, visibility, DPI scale, native message box. All functions take `&WindowState` or `&mut WindowState`; deferred writes go to `pending_*` fields. |
| `viewport.rs`    | Viewport coordinate-space utilities — logical game dimensions, scale mode (`none`/`letterbox`/`stretch`/`pixel`), and bidirectional pixel ↔ game-space coordinate conversion using pre-computed scale and offset values. |

## Submodules

### `window::event_loop`

Reserved placeholder for platform-specific event-loop integration. Currently empty — all event-loop logic lives in `engine::app::App`. No public structs, enums, or functions.

### `window::management`

Window chrome commands and queries. Every function takes `&WindowState` or `&mut WindowState` directly. Mutating functions write to `pending_*` fields for deferred execution by `engine::app`. The `show_message_box` function is the only one that makes an OS call directly (via the `rfd` crate).

- **`ModeInfo`** (struct): Snapshot of fullscreen state, fullscreen type string, and VSync mode integer. Returned by `get_mode`.

Public functions (26): `set_title`, `set_fullscreen`, `is_fullscreen`, `set_vsync`, `get_vsync`, `get_dpi_scale`, `get_position`, `set_position`, `minimize`, `maximize`, `restore`, `is_minimized`, `is_maximized`, `has_focus`, `request_attention`, `close`, `set_icon`, `set_size`, `get_fullscreen_type_str`, `get_fullscreen`, `is_visible`, `has_mouse_focus`, `to_dpi_pixels`, `from_dpi_pixels`, `get_pixel_dimensions`, `set_mode`, `get_mode`, `show_message_box`.

### `window::viewport`

Viewport and coordinate-space utilities. Scale and offset values (`viewport_scale_x/y`, `viewport_offset_x/y`) are computed externally by `engine::app` whenever the window resizes or the scale mode changes. Functions here treat these values as read-only for conversions and use `pending_scale_mode` for deferred mode changes.

- **`ScaleInfo`** (struct): Snapshot of viewport scale factors, offsets, and logical game dimensions. Returned by `get_scale_info`.

Public functions (7): `get_width`, `get_height`, `get_scale_mode`, `set_scale_mode`, `to_pixels`, `from_pixels`, `get_scale_info`, `set_scale_mode_validated`.

## Key Types

### Structs

#### `window::management::ModeInfo`

Snapshot of the current window mode. Contains three fields: `fullscreen` (`bool`) indicating whether the window is fullscreen, `fullscreen_type` (`&'static str`) set to `"desktop"` or `"exclusive"`, and `vsync` (`i32`) holding the VSync mode integer (`1` = Fifo, `0` = Immediate, `-1` = Mailbox).

#### `window::viewport::ScaleInfo`

Viewport scale and offset information. Contains six `f32` fields: `scale_x` and `scale_y` (scale factors from game space to window pixels), `offset_x` and `offset_y` (pixel offsets for letterboxing), and `game_width` and `game_height` (the logical game dimensions in virtual pixels).

### Enums

No public enums in this module. The `FullscreenType` enum (`Desktop` | `Exclusive`) used by `set_fullscreen` is defined in `engine::shared_state`, not here.

## Lua API

Exposed under `lurek.window.*` by `src/lua_api/window_api.rs`.

### Window dimensions and mode

| Function | Description |
|---|---|
| `lurek.window.getWidth()` | Returns the window width in pixels. |
| `lurek.window.getHeight()` | Returns the window height in pixels. |
| `lurek.window.getDimensions()` | Returns window width and height as two integers. |
| `lurek.window.getGameWidth()` | Returns the logical game width in virtual pixels. |
| `lurek.window.getGameHeight()` | Returns the logical game height in virtual pixels. |
| `lurek.window.getPixelDimensions()` | Returns the window dimensions in physical pixels. |
| `lurek.window.setMode(w, h, flags?)` | Resizes the window; flags table accepts `fullscreen`, `fullscreentype`, `vsync`. |
| `lurek.window.getMode()` | Returns width, height, and a flags table with current mode settings. |

### Fullscreen and display

| Function | Description |
|---|---|
| `lurek.window.setFullscreen(enabled, fstype?)` | Enables or disables fullscreen mode. |
| `lurek.window.getFullscreen()` | Returns the fullscreen state and type string. |
| `lurek.window.isFullscreen()` | Returns whether the window is in fullscreen mode. |
| `lurek.window.isOpen()` | Returns whether the window is open. |
| `lurek.window.setVSync(mode)` | Sets the VSync mode (1=on, 0=off, -1=adaptive). |
| `lurek.window.getVSync()` | Returns the current VSync mode integer. |
| `lurek.window.getFullscreenModes()` | Returns all available fullscreen video modes. |
| `lurek.window.getDisplayCount()` | Returns the number of connected displays. |
| `lurek.window.getDesktopDimensions()` | Returns the desktop resolution as width, height. |
| `lurek.window.getDisplayName(display?)` | Returns the name of the current display. |
| `lurek.window.getDisplayOrientation()` | Returns the current display orientation (`"landscape"` or `"portrait"`). |
| `lurek.window.getSafeArea()` | Returns the safe display area as x, y, w, h. |
| `lurek.window.getSystemTheme()` | Returns the OS color theme preference. |
| `lurek.window.isHighDPIAllowed()` | Returns whether high-DPI rendering is allowed. |
| `lurek.window.isResizable()` | Returns whether the window can be resized by the user. |

### Window state

| Function | Description |
|---|---|
| `lurek.window.setTitle(title)` | Sets the window title bar text. |
| `lurek.window.getTitle()` | Returns the current window title. |
| `lurek.window.hasFocus()` | Returns whether the window has keyboard focus. |
| `lurek.window.hasMouseFocus()` | Returns whether the mouse cursor is inside the window. |
| `lurek.window.isMinimized()` | Returns whether the window is minimized. |
| `lurek.window.isMaximized()` | Returns whether the window is maximized. |
| `lurek.window.isVisible()` | Returns whether the window is visible. |
| `lurek.window.minimize()` | Minimizes the window to the taskbar. |
| `lurek.window.maximize()` | Maximizes the window to fill the desktop. |
| `lurek.window.restore()` | Restores the window from minimized or maximized state. |
| `lurek.window.close()` | Requests the window to close. |
| `lurek.window.requestAttention()` | Flashes the window in the taskbar to request user attention. |
| `lurek.window.focus()` | Requests the window manager to bring the window to the foreground. |
| `lurek.window.setIcon(path)` | Sets the window icon from a file path. |
| `lurek.window.setPosition(x, y)` | Moves the window to the given screen position. |
| `lurek.window.getPosition()` | Returns the window position as x, y in screen coordinates. |
| `lurek.window.showMessageBox(title, msg, boxType?, btnType?)` | Shows a platform-native message box dialog; returns button string. |

### DPI and coordinate conversion

| Function | Description |
|---|---|
| `lurek.window.getDPIScale()` | Returns the DPI scaling factor for the window. |
| `lurek.window.getNativeDPIScale()` | Returns the native DPI scale factor. |
| `lurek.window.toPixels(value)` | Converts a device-independent coordinate to physical pixels. |
| `lurek.window.fromPixels(value)` | Converts physical pixels to device-independent coordinates. |

### Viewport scaling

| Function | Description |
|---|---|
| `lurek.window.getScaleInfo()` | Returns a table with scale\_x, scale\_y, offset\_x, offset\_y, game\_width, game\_height. |
| `lurek.window.getScaleMode()` | Returns the current viewport scale mode string. |
| `lurek.window.setScaleMode(mode)` | Sets the viewport scale mode. |

## Lua Examples

```lua
-- Query window dimensions and set title
function lurek.init()
    local w, h = lurek.window.getDimensions()
    lurek.window.setTitle("My Game — " .. w .. "×" .. h)
end

-- Toggle fullscreen on F11, show VSync mode
function lurek.keypressed(key)
    if key == "f11" then
        local fs = lurek.window.isFullscreen()
        lurek.window.setFullscreen(not fs)
    end
end

-- Set a combined window mode with flags
function lurek.init()
    lurek.window.setMode(1280, 720, {
        fullscreen = false,
        fullscreentype = "desktop",
        vsync = 1,
    })
end

-- Viewport scaling: letterbox with fixed game resolution
function lurek.init()
    lurek.window.setScaleMode("letterbox")
    local gw = lurek.window.getGameWidth()
    local gh = lurek.window.getGameHeight()
    print("Game space: " .. gw .. "×" .. gh)
end

-- DPI-aware coordinate conversion
function lurek.render()
    local px = lurek.window.toPixels(100)
    local dp = lurek.window.fromPixels(px)
    -- px == 200 on a 2× HiDPI display, dp == 100
end

-- Platform-native message box
function lurek.exit()
    local btn = lurek.window.showMessageBox(
        "Quit?", "Save before exiting?", "warning", "yesno"
    )
    if btn == "no" then return false end
    return true
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 2     |
| `enum`     | 0     |
| `fn`       | 35    |
| **Total**  | **37** |

## References

| Module          | Relationship | Notes                                                    |
|-----------------|--------------|----------------------------------------------------------|
| `engine`        | Imports from | Uses `SharedState`, `WindowState`, `FullscreenType`      |
| `lua_api`       | Imported by  | `window_api.rs` binds all public functions to `lurek.window.*` |
| `input`         | Related      | Input module reads `WindowState` for cursor position transforms; both are Tier 1 siblings with no direct imports between them |
| `graphics`      | Related      | Renderer reads `WindowState` for surface size and viewport; no direct import from `window` |
| `camera`        | Related      | Camera uses window dimensions for view transforms; reads `SharedState` independently |

**Similar modules**: `window` vs `graphics` — `window` owns the OS window chrome, dimensions, and viewport coordinate transforms; `graphics` owns the GPU renderer, draw commands, textures, and visual output. They share `WindowState` through `SharedState` but never import each other.

## Notes

- **Desktop-only (A-02)**: Lurek2D targets Windows, Linux, and macOS only. Functions like `getSafeArea` return the full window area and `getDisplayOrientation` returns `"landscape"` or `"portrait"` based on width vs height — no mobile notch/inset handling.
- **Deferred-write pattern**: All mutating functions (`set_title`, `set_fullscreen`, `set_size`, etc.) write to `pending_*` fields and take effect on the **next frame**. Lua scripts must not assume the change is visible immediately after calling the setter.
- **`rfd` crate dependency**: `show_message_box` uses the `rfd` crate for native dialogs. This is the only function in the module that performs a blocking OS call. It should not be called from inside `lurek.update` or `lurek.draw` in performance-sensitive code.
- **Viewport scale/offset are read-only here**: `viewport_scale_x/y` and `viewport_offset_x/y` are computed by `engine::app` during resize events. Functions in `viewport.rs` treat them as read-only. Only `set_scale_mode` / `set_scale_mode_validated` trigger a recalculation (deferred via `pending_scale_mode`).
- **Headless testing**: Because no winit or wgpu calls exist in this module, all Rust and Lua tests run fully headless. The Lua test file has 50+ assertions covering every `lurek.window.*` function. Rust tests verify `WindowState` defaults and config propagation.
- **Scale modes**: Four viewport scale modes are supported — `"none"` (1:1 pixel mapping, default), `"letterbox"` (uniform scale with black bars), `"stretch"` (non-uniform scale, fills window), and `"pixel"` (integer scaling for pixel art). `set_scale_mode_validated` logs a warning and returns `false` for unrecognized modes.
- **winit 0.30**: The `Window` handle stored in `SharedState` is from winit 0.30. Functions in `window_api.rs` that directly query the handle (e.g., `getDisplayCount`, `isResizable`) access `st.window.as_ref()` and fall back gracefully when the handle is `None` (headless mode).
- **Breaking change surface**: Renaming or removing any `lurek.window.*` function will break existing game scripts. The `setMode`/`getMode` flags table keys (`fullscreen`, `fullscreentype`, `vsync`) are part of the public API contract.
