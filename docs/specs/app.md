# app

## General Info

- Module group: `Edge/Integration`
- Source path: `src/app/`
- Lua API path(s): None direct
- Primary Lua namespace: None direct
- Rust test path(s): tests/rust/unit/engine_tests.rs; tests/rust/ext/graphics_runtime_smoke_tests.rs
- Lua test path(s): None dedicated

## Summary

The `app` module is Lurek2D's application entry-point and engine lifecycle orchestrator. It sits at the Edge/Integration tier — the topmost layer of the engine dependency graph — and owns the winit 0.30 event loop, the wgpu surface and device, the Lua VM instance, and the main frame pacing loop.

`App::run()` is where everything starts: it creates the OS window via winit, initialises the wgpu renderer, constructs `SharedState`, creates the Lua VM via `lua_api::create_lua_vm()`, and then enters the winit event loop. Each frame the loop dispatches OS events into `SharedState::event_queue`, calls the Lua `lurek.process(dt)` / `lurek.render()` / `lurek.render_ui()` callbacks, then calls `GpuRenderer::render_frame()` to process the accumulated `RenderCommand` queue.

Special startup modes are handled here: if no valid `conf.toml` is found, the engine enters a splash/error mode rendered by `error_screen.rs`; `debug_overlay.rs` provides the lightweight in-engine FPS and draw-call counter overlay that is independent of the full `devtools` system. Gamepad discovery and hot-plug events are routed through the gilrs library and injected into `SharedState::gamepad_states`. File drag-and-drop events and screenshot requests are also handled at this layer.

Because `App` imports from virtually every other module (render, audio, input, lua_api, filesystem, etc.) it is deliberately kept thin — orchestration only, no domain logic. All subsystem behaviour lives in their own modules; `App` just wires them up and drives the frame cycle.

**Scope boundary**: Edge/Integration tier. Imports from all other module groups. Nothing in the engine imports from `app`.

## Files

- `app.rs`: Defines the public App entry point and the internal runtime implementation that owns the window, event loop integration, renderer, Lua VM, and frame lifecycle. This is the main file for startup flow, event handling, splash mode, and run-state transitions.
- `app_winit.rs`: Contains alternate or parked winit-specific app code that is not part of the active module export surface. Treat it as implementation context, not the first place to extend live behavior unless it is reconnected deliberately.
- `debug_overlay.rs`: Defines DebugOverlay, the lightweight in-engine overlay for frame and draw statistics. It exists so app-level runtime state can expose quick visual diagnostics without dragging in the full devtools stack.
- `error_screen.rs`: Defines ErrorScreen, the structured presentation for runtime and Lua failures. This file owns how fatal problems become user-visible render commands instead of raw crashes or console output.
- `mod.rs`: Module root that exposes the public app-facing types. It keeps the external surface small while hiding most of the runtime wiring details.

## Types

- `App` (`struct`, `app.rs`): Public entry point used to launch the engine with loaded configuration and optional startup error context. It is the outward-facing runtime shell around the real application lifecycle.
- `App` (`struct`, `app_winit.rs`): Public entry point used to launch the engine with loaded configuration and optional startup error context. It is the outward-facing runtime shell around the real application lifecycle.
- `DebugOverlay` (`struct`, `debug_overlay.rs`): Small runtime overlay for FPS and draw-call visibility. It is useful when changes affect per-frame diagnostics rather than the full devtools subsystem.
- `ErrorScreen` (`struct`, `error_screen.rs`): Structured error presentation model that converts failures into readable render commands. It is the module's user-facing failure surface.

## Functions

- `App::new` (`app.rs`): Creates a new `App` with the given `Config` and an optional conf.lua error.
- `App::run` (`app.rs`): Initialises the GPU, window, Lua VM, and runs the event loop until the game exits.
- `App::new` (`app_winit.rs`): Creates a new `App` with the given `Config`.
- `App::run` (`app_winit.rs`): Initialises the GPU, window, Lua VM, and runs the event loop until the game exits.
- `DebugOverlay::new` (`debug_overlay.rs`): Creates a new disabled debug overlay.
- `DebugOverlay::build_render_commands` (`debug_overlay.rs`): Generates draw commands for the overlay.
- `ErrorScreen::from_error` (`error_screen.rs`): Creates an `ErrorScreen` from a plain error message string.
- `ErrorScreen::from_lua_error` (`error_screen.rs`): Creates an `ErrorScreen` from an `mlua::Error`.
- `ErrorScreen::from_engine_error` (`error_screen.rs`): Creates an `ErrorScreen` from an `EngineError`.
- `ErrorScreen::build_render_commands` (`error_screen.rs`): Generates a sequence of `RenderCommand` values that render the error screen.
- `ErrorScreen::as_text` (`error_screen.rs`): Returns the full error text as a plain string suitable for clipboard copy.
- `wrap_text` (`error_screen.rs`): Wraps a text string at word boundaries to fit within `max_chars` columns.
- `format_traceback` (`error_screen.rs`): Cleans up a Lua traceback string for display.

## Lua API Reference

- No dedicated direct `lurek.*` namespace is exposed by this module.

## References

- `event`: Imports or references `event` from `src/event/`.
- `image`: Imports or references `image` from `src/image/`.
- `input`: Imports or references `input` from `src/input/`.
- `light`: Imports or references `light` from `src/light/`.
- `lua_api`: Imports or references `lua_api` from `src/lua_api/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `sprite`: Imports or references `sprite` from `src/sprite/`.
- `timer`: Imports or references `timer` from `src/timer/`.

## Notes

- Keep this module reference synchronized with `src/app/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
