# app

## General Info

- Module group: `Edge/Integration`
- Source path: `src/app/`
- Lua API path(s): None direct
- Primary Lua namespace: None direct
- Rust test path(s): tests/rust/unit/engine_tests.rs; tests/rust/ext/graphics_runtime_smoke_tests.rs
- Lua test path(s): None dedicated

## Summary

The `app` module is Lurek2D's application entry point and engine lifecycle orchestrator — the Edge/Integration tier topmost layer. It owns the winit 0.30 event loop, the wgpu device and surface, the Lua VM instance, and the main frame pacing loop. Nothing else in the engine imports from `app`; it is the integration layer that wires all subsystems together.

**Startup.** `App::run()` is the single public entry point. It creates the OS window via winit, initialises the wgpu device and swap chain, constructs `SharedState`, creates the Lua VM via `lua_api::create_lua_vm()`, and enters the winit event loop. If no game folder is provided on the command line, it shows the native window immediately after GPU setup so the first redraw can present the branded splash screen before `init_lua()` runs. Drag-and-drop of a folder or `.lurek` archive from the OS file manager also starts a game session mid-run.

**Frame loop.** The internal `LurekApp` struct implements winit's `ApplicationHandler` trait. Each frame the loop:
1. Dispatches OS events (keyboard, mouse, gamepad via gilrs, resize, drag-drop, close).
2. Calls the Lua callback sequence: `ready` (once) → `process_physics` (fixed timestep, if used) → `fixedUpdate` (optional fixed timestep) → `process(dt)` → `process_late(dt)` → `render()`.
3. Auto-collects render commands from parallax, tilemap, raycaster, and UI subsystems.
4. Calls `GpuRenderer::render_frame()` to flush the accumulated `RenderCommand` queue to the GPU.

**Run state machine.** `RunState` has three states: Running, Error, and Restarting. Any Lua or engine error transitions to Error, which displays the `ErrorScreen`. R key restarts the game from scratch; the engine re-initialises the Lua VM and reloads all Lua scripts without restarting the process.

**Error screen.** `ErrorScreen` converts Lua runtime errors (`mlua::Error`) and engine errors (`EngineError`) into a structured blue screen with formatted traceback, recovery hints, Ctrl+C clipboard copy of the error text, and R-to-restart. `wrap_text` handles word-wrapping for the narrow screen layout.

**Debug overlay.** `DebugOverlay` is a lightweight FPS and draw-call counter rendered as overlay text, toggled by F12. It uses only the existing `RenderCommand` text draw path and adds negligible overhead.

**Viewport scaling.** `recompute_viewport()` supports four scaling modes configured via `conf.lua`: `letterbox` (fit with black bars), `stretch` (fill with distortion), `pixel` (integer scale), and `none` (raw pixel passthrough). `fit_contain_size` is the helper that computes the maximum integer-preserving size.

**Gamepad support.** gilrs gamepad discovery and hot-plug events are processed in the winit event handler. Axes and buttons are mapped to `lurek.input` key codes and dispatched to the normal input pipeline — no separate gamepad API is needed.

**CI screenshot.** Auto-screenshot mode (`--screenshot`) renders exactly one frame, saves a PNG to a configured path, and exits. Used by `tests/demo_smoke_tests.rs` `#[ignore]` tests to capture reference screenshots.

**Scope boundary.** Edge/Integration tier. Imports from render, audio, input, lua_api, filesystem, and all other module groups. Nothing in the engine imports from `app`.

## Files

- `app.rs`: Defines the public App entry point and the internal runtime implementation that owns the window, event loop integration, renderer, Lua VM, and frame lifecycle. This is the main file for startup flow, event handling, splash mode, and run-state transitions.
- `app_winit.rs`: Contains alternate or parked winit-specific app code that is not part of the active module export surface. Treat it as implementation context, not the first place to extend live behavior unless it is reconnected deliberately.
- `debug_overlay.rs`: Defines DebugOverlay, the lightweight in-engine overlay for frame and draw statistics. It exists so app-level runtime state can expose quick visual diagnostics without dragging in the full devtools stack.
- `error_screen.rs`: Defines ErrorScreen, the structured presentation for runtime and Lua failures. This file owns how fatal problems become user-visible render commands instead of raw crashes or console output.
- `mod.rs`: Module root that exposes the public app-facing types. It keeps the external surface small while hiding most of the runtime wiring details.

## Types

- `RunState` (`enum`, `app.rs`): Tracks whether the engine is running normally, showing an error, or shutting down.
- `LurekApp` (`struct`, `app.rs`): Lurek2D application state managed by the winit event loop.
- `App` (`struct`, `app.rs`): Public entry point used to launch the engine with loaded configuration and optional startup error context. It is the outward-facing runtime shell around the real application lifecycle.
- `App` (`struct`, `app_winit.rs`): Public entry point used to launch the engine with loaded configuration and optional startup error context. It is the outward-facing runtime shell around the real application lifecycle.
- `DebugOverlay` (`struct`, `debug_overlay.rs`): Small runtime overlay for FPS and draw-call visibility. It is useful when changes affect per-frame diagnostics rather than the full devtools subsystem.
- `ErrorScreen` (`struct`, `error_screen.rs`): Structured error presentation model that converts failures into readable render commands. It is the module's user-facing failure surface.

## Functions

- `recompute_viewport` (`app.rs`): Recomputes viewport scale and offset based on game and window dimensions.
- `splash_window_title` (`app.rs`): Returns the splash-mode window title with the engine version appended.
- `fit_contain_size` (`app.rs`): Computes the largest size that fits `src` inside `max` while preserving aspect ratio.
- `LurekApp::new` (`app.rs`): Creates a new [`LurekApp`] from the given configuration and game-folder path.
- `LurekApp::resolve_present_mode` (`app.rs`): Selects the best available [`wgpu::PresentMode`] for the given `requested_mode` integer.
- `LurekApp::init_lua` (`app.rs`): Re-initialises the Lua VM and per-game pipeline state for a new game session.
- `App::new` (`app.rs`): Creates a new `App` with the given `Config` and an optional conf.toml error.
- `App::run` (`app.rs`): Initialises the GPU, window, Lua VM, and runs the event loop until the game exits.
- `App::new` (`app_winit.rs`): Creates a new `App` with the given `Config`.
- `App::run` (`app_winit.rs`): Initialises the GPU, window, Lua VM, and runs the event loop until the game exits.
- `DebugOverlay::new` (`debug_overlay.rs`): Creates a new disabled debug overlay.
- `DebugOverlay::build_render_commands` (`debug_overlay.rs`): Generates draw commands for the effect.
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
