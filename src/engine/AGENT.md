# `engine` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Baseline |
| **Lua API** | `None` |
| **Source** | `src/engine/` |
| **Tests** | `tests/engine_tests.rs` |

## Summary

The engine module is the nervous system of Luna2D — it owns everything that
must happen in the right order at the right time.  Window creation, GPU
surface initialisation, Lua VM construction, `SharedState` assembly, the main
game loop, fixed-timestep physics ticking, input event routing, error handling
with a full-screen error display, debug overlay, structured log messages, and
the typed resource keys that identify GPU objects all live here.

The winit `ApplicationHandler` pattern structures the loop around OS events
rather than a manual spin: `resumed()` initialises GPU and Lua, `window_event()`
routes input events to the input-state structs, and `about_to_wait()` fires
`tick_frame()` which runs the full update/draw cycle and presents the frame.
This event-driven architecture is required for correct behaviour on macOS and
ensures tight integration with the operating system's event queue on all
desktop platforms.

`SharedState` is the hub that connects every subsystem to every API call.  It
is deliberately `Rc<RefCell<>>` rather than `Arc<Mutex<>>` because all Lua
callbacks are strictly single-threaded; removing the need for cross-thread
safety eliminates an entire class of potential data-race bugs and avoids the
overhead of lock acquisition on every API call.  Config is loaded from
`luna.toml` in the game directory before the window is created, so window
dimensions, title, VSYNC mode, target FPS, and which optional modules
(physics, audio, gamepad) are enabled are all known at surface initialisation
time.

## Architecture

```
App (entry point)
  │
  ├── RunState ── Running | Error | Restarting
  │
  ├── LunaApp (private winit ApplicationHandler)
  │     ├── init_gpu() ── wgpu adapter/device/surface
  │     ├── init_lua() ── Lua VM + register all luna.* APIs
  │     ├── tick_frame() ── input poll → lua update(dt) → lua draw() → present
  │     └── game_update() ── fixed timestep logic
  │
  ├── Config ── loaded from conf.lua
  │     ├── WindowConfig { title, width, height, vsync, resizable, fullscreen }
  │     ├── GraphicsConfig { backend, power_preference }
  │     ├── ModulesConfig { physics, audio, joystick }
  │     ├── PerformanceConfig { target_fps, fixed_timestep }
  │     └── load_from_conf_lua(path) → Config
  │
  ├── EngineError ── 13 variants (E1001–E1012)
  │     ├── ErrorCategory (5 enum variants)
  │     └── error_code() → "E10XX" string
  │
  ├── ErrorScreen ── blue background, word wrap, Escape/R controls
  │
  ├── DebugOverlay ── FPS + draw calls (F12 toggle)
  │
  ├── LogMessages ── L001–L032 constants + log_msg! macro
  │
  └── ResourceKeys ── 10 SlotMap key types
        TextureKey, FontKey, CanvasKey, SoundKey, ParticleKey,
        SpriteBatchKey, ShaderKey, MeshKey, BusKey, MidiPlayerKey
```

## Source Files

| File | Purpose |
|------|---------|
| `app.rs` | Luna2D application lifecycle using winit 0.30 + wgpu GPU rendering |
| `config.rs` | Engine and window configuration loaded from `conf.lua` |
| `debug_overlay.rs` | Debug overlay for displaying FPS and draw call statistics |
| `error.rs` | Structured error types and result alias for the Luna2D engine |
| `error_screen.rs` | Visual error screen for displaying Lua and engine errors to the user |
| `log_messages.rs` | Structured logging with stable message IDs for the Luna2D engine |
| `resource_keys.rs` | Typed resource keys for generational ID-based resource pools |
| `shared_state.rs` | Shared engine state hub: SharedState, WindowState, FullscreenType, and ErrorInfo |

## Submodules

### `engine::app`

Luna2D application lifecycle using winit 0.

- **`App`** (struct): Entry point for the Luna2D engine. Owns the game loop, GPU renderer, and Lua VM lifecycle.

### `engine::config`

Engine and window configuration loaded from `conf.

- **`Config`** (struct): Top-level engine configuration. Consult the module-level documentation for the broader usage context and preconditions....
- **`WindowConfig`** (struct): Window dimensions, title, vsync, fullscreen, and resize settings.
- **`ModulesConfig`** (struct): Flags to enable or disable optional engine subsystems.
- **`PerformanceConfig`** (struct): Frame rate cap and other performance tuning options.

### `engine::debug_overlay`

Debug overlay for displaying FPS and draw call statistics.

- **`DebugOverlay`** (struct): Debug overlay showing FPS and render statistics.

### `engine::error`

Structured error types and result alias for the Luna2D engine.

- **`ErrorCategory`** (enum): Error category for grouping related engine errors.
- **`EngineError`** (enum): All possible error conditions that can occur in the Luna2D engine.  Each variant carries a stable error code...
- **`EngineResult`** (type): Convenience alias for `Result<T, EngineError>` used throughout the engine.

### `engine::error_screen`

Visual error screen for displaying Lua and engine errors to the user.

- **`ErrorScreen`** (struct): Visual error screen that generates `DrawCommand` sequences for the GPU renderer.  Stores a pre-processed error title,...
- **`wrap_text`** (fn): Wraps a text string at word boundaries to fit within `max_chars` columns.
- **`format_traceback`** (fn): Cleans up a Lua traceback string for display.

### `engine::log_messages`

Structured logging with stable message IDs for the Luna2D engine.

- **`set_log_level`** (fn): Sets the global log level at runtime (called from `luna.system.setLogLevel`).
- **`get_log_level`** (fn): Returns the current log level name. This accessor incurs no allocation; call it freely in hot paths.
- **`L001_ENGINE_START`** (const): Log message: engine starting. Consult the module-level documentation for the broader usage context and preconditions.
- **`L002_ENGINE_STOP`** (const): Log message: engine shut down. Consult the module-level documentation for the broader usage context and preconditions.
- **`L003_GAME_LOADED`** (const): Log message: game loaded from path. Consult the module-level documentation for the broader usage context and...
- **`L004_GAME_RESTART`** (const): Log message: game restarted. Consult the module-level documentation for the broader usage context and preconditions.
- **`L005_CONF_LOADED`** (const): Log message: conf.lua loaded. Consult the module-level documentation for the broader usage context and preconditions.
- **`L010_RENDER_ERROR`** (const): Log message: render error occurred. Consult the module-level documentation for the broader usage context and...
- **`L011_LUA_ERROR`** (const): Log message: Lua error caught. Consult the module-level documentation for the broader usage context and preconditions.
- **`L012_AUDIO_ERROR`** (const): Log message: audio error. Consult the module-level documentation for the broader usage context and preconditions.
- **`L013_FS_ERROR`** (const): Log message: filesystem error. Consult the module-level documentation for the broader usage context and preconditions.
- **`L014_PHYSICS_ERROR`** (const): Log message: physics error. Consult the module-level documentation for the broader usage context and preconditions.
- **`L015_RESOURCE_NOT_FOUND`** (const): Log message: resource not found. Consult the module-level documentation for the broader usage context and preconditions.
- **`L020_NO_AUDIO_DEVICE`** (const): Log message: no audio device available. Consult the module-level documentation for the broader usage context and...
- **`L021_CLIPBOARD_FAIL`** (const): Log message: clipboard access failed. Consult the module-level documentation for the broader usage context and...
- **`L022_UNKNOWN_LOG_LEVEL`** (const): Log message: unknown log level requested.
- **`L030_ASYNC_LOAD_REQUEST`** (const): Log message: async asset load requested.
- **`L031_ASYNC_LOAD_COMPLETE`** (const): Log message: async asset load completed.
- **`L032_BATCH_STATS`** (const): Log message: draw batch statistics. Consult the module-level documentation for the broader usage context and...

### `engine::resource_keys`

Typed resource keys for generational ID-based resource pools.

### `engine::shared_state`

Shared engine state hub passed to every Lua API closure via `Rc<RefCell<>>`.

- **`FullscreenType`** (enum): Fullscreen mode — `Desktop` (borderless) or `Exclusive` (true fullscreen).
- **`WindowState`** (struct): Current window dimensions, DPI scale factor, and fullscreen mode.
- **`ErrorInfo`** (struct): Captured Lua or engine error and traceback for the error screen display.
- **`SharedState`** (struct): Central shared state passed as `Rc<RefCell<SharedState>>` to every Lua API closure. Owns all subsystem state: GPU renderer, audio buses, physics worlds, textures, fonts, canvases, input, camera, particle systems, and draw command queue.

## Key Types

### Structs

#### `engine::app::App`

Entry point for the Luna2D engine. Owns the game loop, GPU renderer, and Lua VM lifecycle.

#### `engine::config::Config`

Top-level engine configuration. Consult the module-level documentation for the broader usage context and preconditions....

#### `engine::debug_overlay::DebugOverlay`

Debug overlay showing FPS and render statistics.

#### `engine::error_screen::ErrorScreen`

Visual error screen that generates `DrawCommand` sequences for the GPU renderer.  Stores a pre-processed error title,...

#### `engine::config::ModulesConfig`

Flags to enable or disable optional engine subsystems.

#### `engine::config::PerformanceConfig`

Frame rate cap and other performance tuning options.

#### `engine::config::WindowConfig`

Window dimensions, title, vsync, fullscreen, and resize settings.

#### `engine::shared_state::ErrorInfo`

Captured Lua or engine error and traceback for the error screen display.

#### `engine::shared_state::SharedState`

Central shared state passed as `Rc<RefCell<SharedState>>` to every Lua API closure.

#### `engine::shared_state::WindowState`

Current window dimensions, DPI scale factor, and fullscreen mode.

### Enums

#### `engine::shared_state::FullscreenType`

Fullscreen mode — `Desktop` (borderless) or `Exclusive` (true fullscreen).

#### `engine::error::EngineError`

All possible error conditions that can occur in the Luna2D engine.  Each variant carries a stable error code...

#### `engine::error::ErrorCategory`

Error category for grouping related engine errors.

### Type Aliases

#### `engine::error::EngineResult`

Convenience alias for `Result<T, EngineError>` used throughout the engine.

## Public Functions

- **`format_traceback()`** `error_screen::` — Cleans up a Lua traceback string for display.
- **`get_log_level()`** `log_messages::` — Returns the current log level name. This accessor incurs no allocation; call it freely in hot paths.
- **`set_log_level()`** `log_messages::` — Sets the global log level at runtime (called from `luna.system.setLogLevel`).
- **`wrap_text()`** `error_screen::` — Wraps a text string at word boundaries to fit within `max_chars` columns.

## Constants

- **`L001_ENGINE_START`** — Log message: engine starting. Consult the module-level documentation for the broader usage context and preconditions.
- **`L002_ENGINE_STOP`** — Log message: engine shut down. Consult the module-level documentation for the broader usage context and preconditions.
- **`L003_GAME_LOADED`** — Log message: game loaded from path. Consult the module-level documentation for the broader usage context and...
- **`L004_GAME_RESTART`** — Log message: game restarted. Consult the module-level documentation for the broader usage context and preconditions.
- **`L005_CONF_LOADED`** — Log message: conf.lua loaded. Consult the module-level documentation for the broader usage context and preconditions.
- **`L010_RENDER_ERROR`** — Log message: render error occurred. Consult the module-level documentation for the broader usage context and...
- **`L011_LUA_ERROR`** — Log message: Lua error caught. Consult the module-level documentation for the broader usage context and preconditions.
- **`L012_AUDIO_ERROR`** — Log message: audio error. Consult the module-level documentation for the broader usage context and preconditions.
- **`L013_FS_ERROR`** — Log message: filesystem error. Consult the module-level documentation for the broader usage context and preconditions.
- **`L014_PHYSICS_ERROR`** — Log message: physics error. Consult the module-level documentation for the broader usage context and preconditions.
- **`L015_RESOURCE_NOT_FOUND`** — Log message: resource not found. Consult the module-level documentation for the broader usage context and preconditions.
- **`L020_NO_AUDIO_DEVICE`** — Log message: no audio device available. Consult the module-level documentation for the broader usage context and...
- **`L021_CLIPBOARD_FAIL`** — Log message: clipboard access failed. Consult the module-level documentation for the broader usage context and...
- **`L022_UNKNOWN_LOG_LEVEL`** — Log message: unknown log level requested.
- **`L030_ASYNC_LOAD_REQUEST`** — Log message: async asset load requested.
- **`L031_ASYNC_LOAD_COMPLETE`** — Log message: async asset load completed.
- **`L032_BATCH_STATS`** — Log message: draw batch statistics. Consult the module-level documentation for the broader usage context and...

## Item Summary

| Kind | Count |
|------|-------|
| `const` | 17 |
| `enum` | 2 |
| `fn` | 4 |
| `mod` | 7 |
| `struct` | 7 |
| `type` | 1 |
| **Total** | **38** |

