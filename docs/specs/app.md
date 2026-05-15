# app

## General Info

- Module group: `Edge/Integration`
- Source path: `src/app/`
- Lua API path(s): None direct
- Primary Lua namespace: `lurek.input`
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

**Hot-reload.** During `about_to_wait`, the app polls `conf.toml` and content watchers (`*.lua` scripts plus common asset extensions) via `filesystem::FileWatcher`. Config changes apply in-place; content changes trigger a game-session restart (Lua VM + game state) without restarting the engine process or recreating the window/GPU device.

**Frame profiling.** `game_update()` records per-callback CPU wall-clock timing buckets (`process_physics`, `fixedUpdate`, `process`, `process_late`, `draw`, `draw_ui`) and the app loop records frame-stage buckets (`tick`, `update`, `render`, `frame_total`). The snapshot is exposed via `lurek.engine.getFrameProfile()` and `lurek.engine.getFrameProfileText()`.

**Lua callback timeout.** `[performance].lua_callback_timeout_ms` is an optional hard budget for any Lua callback invocation. When exceeded, the callback is aborted via an instruction hook and the run state transitions to `RunState::Error`.

**Run state machine.** `RunState` has three states: Running, Error, and Restarting. Any Lua or engine error transitions to Error, which displays the `ErrorScreen`. R key restarts the game from scratch; the engine re-initialises the Lua VM and reloads all Lua scripts without restarting the process.

**Error screen.** `ErrorScreen` converts Lua runtime errors (`mlua::Error`) and engine errors (`EngineError`) into a structured blue screen with formatted traceback, recovery hints, Ctrl+C clipboard copy of the error text, and R-to-restart. `wrap_text` handles word-wrapping for the narrow screen layout.

**Debug overlay.** `DebugOverlay` is a lightweight FPS and draw-call counter rendered as overlay text, toggled by F12. It uses only the existing `RenderCommand` text draw path and adds negligible overhead.

**Viewport scaling.** `recompute_viewport()` supports four scaling modes configured via `conf.lua`: `letterbox` (fit with black bars), `stretch` (fill with distortion), `pixel` (integer scale), and `none` (raw pixel passthrough). `fit_contain_size` is the helper that computes the maximum integer-preserving size.

**Gamepad support.** gilrs gamepad discovery and hot-plug events are processed in the winit event handler. Axes and buttons are mapped to `lurek.input` key codes and dispatched to the normal input pipeline — no separate gamepad API is needed.

**CI screenshot.** Auto-screenshot mode (`--screenshot`) waits for a configured capture trigger (`--screenshot-time` or `--screenshot-frames`), saves a PNG to a configured path, and exits. Window placement can be controlled with `--window-x`/`--window-y`, and startup window size can be overridden with `--window-width`/`--window-height` for tiled batch runs. Screenshot safety-exit uses a dynamic timeout derived from the configured capture delay (plus grace), so captures at 3s are not terminated prematurely.

**Scope boundary.** Edge/Integration tier. Imports from render, audio, input, lua_api, filesystem, and all other module groups. Nothing in the engine imports from `app`.

## Files

- `app.rs`: Defines the public App entry point and the internal runtime implementation that owns the window, event loop integration, renderer, Lua VM, and frame lifecycle. This is the main file for startup flow, event handling, splash mode, and run-state transitions.
- `debug_overlay.rs`: Defines DebugOverlay, the lightweight in-engine overlay for frame and draw statistics. It exists so app-level runtime state can expose quick visual diagnostics without dragging in the full devtools stack.
- `error_screen.rs`: Defines ErrorScreen, the structured presentation for runtime and Lua failures. This file owns how fatal problems become user-visible render commands instead of raw crashes or console output.
- `frame_profile.rs`: Contains helper formatting utilities for exposing frame profile data in-engine.
- `lua_callbacks.rs`: Contains timeout-aware callback wrappers used by the app loop to invoke `lurek.*` callbacks safely.
- `mod.rs`: Module root that exposes the public app-facing types. It keeps the external surface small while hiding most of the runtime wiring details.
- `splash_screen.rs`: - Decodes embedded splash icon and banner PNGs into temporary texture storage.

## Types

- `RunState` (`enum`, `app.rs`): Tracks whether the engine is running normally, showing an error, or shutting down.
- `LurekApp` (`struct`, `app.rs`): Lurek2D application state managed by the winit event loop.
- `App` (`struct`, `app.rs`): Public entry point used to launch the engine with loaded configuration and optional startup error context. It is the outward-facing runtime shell around the real application lifecycle.
- `DebugOverlay` (`struct`, `debug_overlay.rs`): Small runtime overlay for FPS and draw-call visibility. It is useful when changes affect per-frame diagnostics rather than the full devtools subsystem.
- `ErrorScreen` (`struct`, `error_screen.rs`): Structured error presentation model that converts failures into readable render commands. It is the module's user-facing failure surface.
- `SplashTexture` (`struct`, `splash_screen.rs`): Handle and dimensions for one splash texture uploaded to render texture storage.
- `SplashBranding` (`struct`, `splash_screen.rs`): Embedded splash-branding assets prepared for splash-screen rendering.

## Functions

- `recompute_viewport` (`app.rs`): Recomputes viewport scale and offset based on game and window dimensions.
- `splash_window_title` (`app.rs`): Returns the splash-mode window title with the engine version appended.
- `fit_contain_size` (`app.rs`): Computes the largest size that fits `src` inside `max` while preserving aspect ratio.
- `LurekApp::new` (`app.rs`): Build app runtime state and initialize filesystem watchers from startup config.
- `LurekApp::resolve_present_mode` (`app.rs`): Select supported present mode and normalized vsync flag from requested mode.
- `LurekApp::init_lua` (`app.rs`): Create the Lua VM, load main.lua, and fire `lurek.init()`.
- `App::new` (`app.rs`): Create bootstrap app wrapper with config and optional pre-start config error.
- `App::run` (`app.rs`): Start the winit event loop and run the runtime for the selected game directory.
- `DebugOverlay::new` (`debug_overlay.rs`): Create disabled debug overlay state.
- `DebugOverlay::build_render_commands` (`debug_overlay.rs`): Build render commands for FPS and draw-call counters in a top-right panel.
- `ErrorScreen::from_error` (`error_screen.rs`): Build error screen model from plain text where first line is title and remainder is body.
- `ErrorScreen::from_lua_error` (`error_screen.rs`): Build error screen model from `mlua::Error`, splitting message and traceback sections.
- `ErrorScreen::from_engine_error` (`error_screen.rs`): Build error screen model from `EngineError` display text.
- `ErrorScreen::build_render_commands` (`error_screen.rs`): Build draw commands that render full-screen error background, text body, traceback, and footer hints.
- `ErrorScreen::as_text` (`error_screen.rs`): Return formatted text representation used for clipboard export and logs.
- `wrap_text` (`error_screen.rs`): Wraps a text string at word boundaries to fit within `max_chars` columns.
- `format_traceback` (`error_screen.rs`): Cleans up a Lua traceback string for display.
- `format_frame_profile_line` (`frame_profile.rs`): Format one `FrameProfile` sample as a compact single-line timing string.
- `call_lua_callback` (`lua_callbacks.rs`): Call `lurek.<name>(...)` and log failures to `error!` without returning them.
- `call_lua_callback_checked` (`lua_callbacks.rs`): Call `lurek.<name>(...)` and return any Lua error to the caller.
- `call_lua_callback_with_timeout` (`lua_callbacks.rs`): Call `lurek.<name>(...)` with optional timeout and log failures.
- `call_lua_callback_checked_with_timeout` (`lua_callbacks.rs`): Call `lurek.<name>(...)` and optionally abort execution when callback exceeds `timeout_ms`.
- `load_splash_branding` (`splash_screen.rs`): Decode embedded icon/banner PNG assets and upload them into splash texture storage.
- `make_splash_commands` (`splash_screen.rs`): Build render commands for splash screen branding and drag-and-drop hint text.

## Lua API Reference

- Namespace: `lurek.input`

## References

- `event`: Imports or references `event` from `src/event/`.
- `filesystem`: Imports or references `src/filesystem/`. Cross-group dependency from `Edge/Integration` into `Core Runtime`.
- `image`: Imports or references `image` from `src/image/`.
- `input`: Imports or references `input` from `src/input/`.
- `light`: Imports or references `light` from `src/light/`.
- `lua_api`: Imports or references `lua_api` from `src/lua_api/`.
- `math`: Imports or references `math` from `src/math/`.
- `parallax`: Imports or references `src/parallax/`. Cross-group dependency from `Edge/Integration` into `Feature Systems`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `sprite`: Imports or references `sprite` from `src/sprite/`.
- `tilemap`: Imports or references `src/tilemap/`. Cross-group dependency from `Edge/Integration` into `Feature Systems`.
- `window`: Imports or references `src/window/`. Cross-group dependency from `Edge/Integration` into `Platform Services`.

## Notes

- Keep this module reference synchronized with `src/app/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
