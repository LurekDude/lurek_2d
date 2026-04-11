# `app` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Baseline — application lifecycle substrate                   |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | — (no dedicated `lurek.*` namespace; lifecycle callbacks are `lurek.init`, `lurek.ready`, `lurek.process`, `lurek.render`, etc.) |
| **Source**     | `src/app/`                                                   |
| **Rust Tests** | `tests/rust/unit/engine_tests.rs`                            |
| **Lua Tests**  | —                                                            |
| **Spec**       | `docs/specs/app.md`                                          |

## Purpose

The `app` module implements the winit 0.30 `ApplicationHandler` event loop that
owns the Lurek2D process lifetime.  `App::new()` constructs a winit `EventLoop`,
creates the platform window according to `Config`, initialises the wgpu GPU device
and swap-chain surface, loads the Lua VM via `create_lua_vm()`, and executes the
game's `main.lua`.  After boot the event loop drives all frame updates: `resumed()`
initialises the GPU adapter on first render creation; `window_event()` routes OS
events to keyboard, mouse, gamepad, and touch state and fires the corresponding
`lurek.*` event callbacks; `about_to_wait()` calls `tick_frame()` which runs the
full update-physics-render cycle and presents the frame.

The `RunState` machine (`Running → Error → Restarting`) handles hot-reload and
error-screen transitions.  When no game folder is provided, the module renders the
branded splash screen using embedded PNG assets cached by `make_splash_commands()`.

## Source Files

| File                 | Purpose                                                                 |
|----------------------|-------------------------------------------------------------------------|
| `mod.rs`             | Re-exports `App`; module declaration.                                   |
| `app.rs`             | `App` (public entry point) and private `LunaApp` (`ApplicationHandler`), `RunState`, game loop, GPU init, Lua VM wiring, input routing, splash screen, drag-and-drop, debug overlay. |
| `app_winit.rs`       | Legacy / dead file — not declared in `mod.rs`; preserved for reference. |
| `debug_overlay.rs`   | `DebugOverlay` — FPS and draw-call counter rendered top-right.          |
| `error_screen.rs`    | `ErrorScreen` — blue error display with word-wrap and traceback text.   |

## Key Types

| Type           | Description                                                             |
|----------------|-------------------------------------------------------------------------|
| `App`          | Public engine entry point; wraps the winit `EventLoop` and `LunaApp`.  |
| `RunState`     | Three-variant FSM (`Running`, `Error`, `Restarting`) controlling frame dispatch. |
| `DebugOverlay` | Lightweight FPS + draw-call HUD, toggled by `lurek.devtools.*`.        |
| `ErrorScreen`  | Full-screen error display with structured traceback and word-wrap.      |

## Lua API Summary

This module has no dedicated `lurek.*` namespace.  All lifecycle integration is
handled via callbacks registered by Lua scripts (`lurek.init`, `lurek.ready`,
`lurek.process`, `lurek.process_physics`, `lurek.process_late`, `lurek.render`,
`lurek.render_ui`) which are invoked at the appropriate points in `tick_frame()`.
