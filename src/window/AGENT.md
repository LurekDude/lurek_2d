# `window` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.window` |
| **Source** | `src/window/` |
| **Tests** | `tests/window_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_window.lua` |

## Summary

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

## Source Files

| File | Purpose |
|------|---------|
| `event_loop.rs` | Event Loop implementation for the `window` subsystem |

## Submodules

### `window::event_loop`

Event Loop implementation for the `window` subsystem.

## Lua API

Exposed under `luna.window.*` by `src/lua_api/window_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `mod` | 1 |
| **Total** | **1** |

