# `window` — Agent Reference

## Module Info

- Module name: `window`
- Module group: Platform Services
- Spec path: `docs/specs/window.md`
- Lua API path(s): `src/lua_api/window_api.rs`
- Rust test path(s): `tests/rust/unit/window_tests.rs`
- Lua test path(s): `tests/lua/unit/test_window.lua`, `tests/lua/unit/test_window_scaling.lua`

## Module Purpose

The `window` module owns engine-level window state and viewport conversion helpers. Its job is to expose a clean Rust surface for title changes, fullscreen and vsync requests, resizing, position changes, focus queries, DPI conversion, and game-space to pixel-space mapping.

This module exists to keep window policy testable and separate from the live OS window handle. Most write operations update `WindowState` pending fields, and the app layer applies those requests on the next frame through `winit`. That split lets Lua and Rust gameplay code request window behavior without importing platform code into unrelated systems.

The module intentionally does not own the actual event loop, swapchain/surface management, or renderer presentation. `engine::app` and the runtime state own the live window object, and `render` owns drawing. The `event_loop` file is currently just a reserved placeholder rather than an active subsystem.

## Files

- `mod.rs`: Declares the window submodules and re-exports the public management and viewport helpers as the module's main surface.
- `management.rs`: Owns window commands and queries such as title, fullscreen, vsync, size, position, minimize, maximize, restore, visibility, DPI scale, and message boxes.
- `viewport.rs`: Owns logical game dimensions, scale-mode changes, and coordinate conversion between game space and on-screen pixels.
- `event_loop.rs`: Reserved placeholder for future event-loop specific code; current event-loop behavior lives outside this module.

## Key Types

- `ModeInfo`: A compact snapshot of fullscreen and vsync state returned by the window mode query helpers.
- `ScaleInfo`: A read-only snapshot of current viewport scale, offsets, and logical game dimensions used by coordinate-conversion callers.
- `WindowState`: The core state object this module reads and mutates, even though it is defined in the runtime shared-state layer rather than here.
- `FullscreenType`: The runtime enum used to distinguish desktop and exclusive fullscreen requests.