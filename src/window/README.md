# `src/window/` — Window Management (Placeholder)

## Purpose

The window module is an intentional structural placeholder.  Window creation,
display configuration (title, dimensions, fullscreen, VSYNC mode, window icon,
cursor visibility), and the winit event-loop lifecycle are tightly coupled to
GPU surface initialisation in `engine/app.rs` — the wgpu surface must be
created on the same OS thread as the winit window, within the scope of the
event loop's first `resumed()` callback.  Separating window management into a
standalone module at this stage would introduce threading and lifetime
complexity without delivering architectural benefit.

The placeholder exists for clarity: the `luna.window.*` Lua API is real and
substantial (resize, set title, toggle fullscreen, query display information,
get content scale for HiDPI, set and hide mouse cursor), but its Rust
implementation lives in `engine/app.rs` and `src/lua_api/window_api.rs`, not
in this module.  A future refactoring may extract a `WindowState` struct here
as windowing needs grow and the field count in `SharedState` warrants
separation.

## Architecture

```
window/
  └── event_loop.rs ── placeholder (2 lines)
        └── Logic lives in engine::app (winit ApplicationHandler)
```

### How It Works

Window state is tracked in `SharedState::window_state` — a plain struct holding
the current title, pixel dimensions, fullscreen flag, VSYNC setting, and
cursor-visible flag.  When Lua calls `luna.window.setFullscreen(true)`, the
binding sets a `pending_fullscreen` flag in `SharedState`; on the next engine
tick `app.rs` reads the flag and calls the winit `Window::set_fullscreen()`.
This deferred-command pattern avoids calling winit from inside a Lua callback,
which can cause re-entrant event delivery on some platforms.

HiDPI content scale is exposed via `luna.window.getDPIScale()` and updates
whenever a `WindowEvent::ScaleFactorChanged` event is received.  Fonts and
canvas resolutions should be multiplied by this value to render crisp text on
Retina displays.

### Dependency Direction

```
window/ ──────► (none)
```

**Placeholder module** — no real implementation. Window logic is in `engine/`.

---

## File-by-File Analysis

### `mod.rs` — Module Root

**~1 line** — re-exports `event_loop` submodule.

---

### `event_loop.rs` — Placeholder

**~2 lines** | Contains only a comment explaining that event loop logic
lives in `engine::app`.

**Design**: This module exists as an organizational placeholder. The winit
event loop requires tight integration with GPU initialization and Lua VM
lifecycle, so it lives in `engine::app` where all those pieces converge.
Future refactoring may move windowing abstractions here.

---

## Cross-Cutting Concerns

### Lua Integration

Window operations are exposed through `src/lua_api/window_api.rs` (~250 lines)
under `luna.window.*`. The actual state lives in `SharedState::window_state`.

### Usage from Lua

```lua
-- Get window dimensions
local w, h = luna.window.getDimensions()

-- Set title
luna.window.setTitle("My Game — Score: " .. score)

-- Fullscreen toggle
luna.window.setFullscreen(not luna.window.getFullscreen())

-- Get display info
local dw, dh = luna.window.getDesktopDimensions()
```
