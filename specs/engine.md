# `engine` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Baseline — always-on runtime substrate               |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | — (foundation module; no dedicated `luna.engine` namespace) |
| **Source**     | `src/engine/`                                        |
| **Rust Tests** | `tests/rust/unit/engine_tests.rs`                    |
| **Lua Tests**  | —                                                    |
| **Architecture** | `docs/architecture/engine-architecture.md`          |

## Summary

The engine module is the foundational layer of Luna2D — it owns the application
lifecycle, the main game loop, configuration loading, shared mutable state, error
handling, structured logging, and the typed resource keys that identify every GPU
object in the engine.  It sits at the Baseline tier alongside `math`, meaning every
other module in the system may import from it.  No domain module imports `lua_api`;
engine is the only upward-facing dependency root.

`App` drives the winit 0.30 `ApplicationHandler` event loop.  Internally a private
`LunaApp` struct owns the wgpu surface, GPU renderer, Lua VM, gamepad polling via
gilrs, and the `RunState` machine (`Running → Error → Restarting`).  `resumed()`
initialises the GPU adapter/device/surface and fires the first redraw;
`window_event()` routes OS input events to `KeyboardState`, `MouseState`,
`GamepadState`, and `TouchState` and fires the corresponding `luna.*` callbacks;
`about_to_wait()` calls `tick_frame()` which runs the full update/draw cycle and
presents the rendered frame.  This event-driven architecture is required for correct
behaviour on macOS and ensures tight integration with the OS event queue on all
desktop targets (Windows, Linux, macOS).

`SharedState` is the central hub connecting every subsystem to every Lua API closure.
It is `Rc<RefCell<SharedState>>` — not `Arc<Mutex<>>` — because all Lua callbacks
execute on a single thread; this eliminates data-race bugs and avoids lock overhead.
`SharedState` holds SlotMap resource pools (textures, fonts, canvases, meshes,
shaders, particle systems, shapes, sprite batches), subsystem instances (Mixer,
Clock, GameFS, Camera, EventQueue, KeyboardState, MouseState, TouchState), draw
state (draw commands, color, blend mode, scissor, stencil, depth mode), and
per-frame statistics.

`Config` is loaded from `conf.lua` in the game directory at startup using a
temporary Lua VM.  It captures `WindowConfig` (title, size, vsync, fullscreen,
scale mode, game resolution), `GraphicsConfig` (backend, power preference),
`ModulesConfig` (30+ boolean flags for optional subsystems), and
`PerformanceConfig` (target FPS).  `ModulesConfig::validate_and_fix()` enforces
dependency constraints (e.g. particle/gui/overlay/terminal require graphics).

Error handling uses `EngineError`, a `thiserror`-derived enum with 12 variants
carrying stable four-digit codes (E1001–E1012) grouped into five `ErrorCategory`
values.  `ErrorScreen` renders a blue full-screen error display with word-wrapped
message, traceback, and recovery instructions (Escape to quit, R to restart,
Ctrl+C to copy).  The engine never crashes on Lua errors; it transitions to
`RunState::Error` and displays the error screen.

Structured logging uses stable message IDs (L001–L082, plus subsystem prefixes
A/G/P/DF/LA) defined as `pub const` values.  The `log_msg!` macro looks up
human-readable text from a TOML-backed `MessageCatalog` embedded at compile time
from `src/engine/cfg/messages.toml`.  Resource keys are 14 typed SlotMap newtypes
providing compile-time safety: a `TextureKey` cannot be passed where a `FontKey` is
expected.

The engine module intentionally does NOT expose a `luna.engine` Lua namespace.  It
is a pure foundation layer consumed by all other modules and by `lua_api` for
lifecycle orchestration.

## Architecture

```
App::run(game_dir)
  │
  ├── EventLoop::run_app(LunaApp)
  │
  └── LunaApp (private winit ApplicationHandler)
        │
        ├── resumed()
        │     ├── create Window (winit) with Config settings
        │     ├── init_gpu() → wgpu Instance → Adapter → Device → Surface
        │     │     └── GpuRenderer::new(device, queue, format, w, h)
        │     └── first RedrawRequested triggers init_lua()
        │           ├── create_lua_vm(SharedState, ModulesConfig)
        │           ├── load and exec main.lua (or show splash)
        │           └── call luna.load()
        │
        ├── window_event()
        │     ├── KeyEvent → KeyboardState → luna.keypressed / keyreleased
        │     ├── Ime(Commit) → luna.textinput
        │     ├── CursorMoved → MouseState → luna.mousemoved
        │     ├── MouseInput → luna.mousepressed / mousereleased
        │     ├── MouseWheel → luna.wheelmoved
        │     ├── Touch → TouchState → luna.touchpressed / moved / released
        │     ├── Focused → luna.focus
        │     ├── Occluded → luna.visible
        │     ├── Resized → reconfigure surface → luna.resize
        │     ├── DroppedFile → load game folder (drag-and-drop)
        │     └── CloseRequested → luna.quit() → RunState
        │
        ├── about_to_wait() → tick_frame()
        │     ├── gilrs gamepad polling → luna.gamepadpressed / axis / etc.
        │     ├── apply pending WindowState operations
        │     ├── Clock::tick() → dt
        │     ├── luna.update(dt)
        │     ├── clear draw_commands
        │     ├── luna.draw() → game pushes DrawCommands
        │     ├── DebugOverlay → append overlay DrawCommands
        │     ├── GpuRenderer::render_frame(commands) → present
        │     └── reset per-frame state
        │
        ├── RunState machine
        │     Running ──error──▶ Error(ErrorScreen)
        │       ▲                    │ [Esc] → Quitting
        │       └── [R] ◀── Restarting ◀─┘
        │
        ├── Config (loaded before window creation)
        │     ├── WindowConfig { title, w, h, vsync, fullscreen, scale_mode, ... }
        │     ├── GraphicsConfig { backend, power_preference }
        │     ├── ModulesConfig { 30+ boolean flags }
        │     └── PerformanceConfig { target_fps }
        │
        ├── SharedState (Rc<RefCell<>>)
        │     ├── SlotMap pools: textures, fonts, canvases, shaders, meshes,
        │     │     sprite_batches, shapes, particle_systems
        │     ├── Subsystems: Mixer, Clock, GameFS, Camera, EventQueue,
        │     │     LightWorld, MidiState
        │     ├── Input: KeyboardState, MouseState, TouchState, gamepads
        │     ├── Draw state: draw_commands, color, blend_mode, scissor,
        │     │     stencil_mode, depth_mode, wireframe, color_mask
        │     └── Window: WindowState (query + pending operations)
        │
        ├── EngineError (12 variants, E1001–E1012)
        │     ├── ErrorCategory: Init | Runtime | Resource | Script | System
        │     └── code(), category(), recovery_hint()
        │
        ├── ErrorScreen (blue error display)
        │     ├── from_error(), from_lua_error(), from_engine_error()
        │     └── draw_commands() → Vec<DrawCommand>
        │
        ├── DebugOverlay (F12 toggle, FPS + draw calls)
        │
        ├── MessageCatalog (TOML-backed, embedded at compile time)
        │     └── log_msg! macro → "[L001] Human-readable text"
        │
        └── ResourceKeys (14 typed SlotMap key newtypes)
              TextureKey, FontKey, CanvasKey, SoundKey, ParticleKey,
              SpriteBatchKey, ShaderKey, MeshKey, ShapeKey, BusKey,
              MidiPlayerKey, QueueableKey, LightKey, OccluderKey
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module declaration, re-exports of `App`, `Config`, `SharedState`, `EngineError`, etc. |
| `app.rs` | Application lifecycle: `App`, private `LunaApp` (winit `ApplicationHandler`), `RunState`, game loop, GPU init, Lua VM init, input routing, splash screen, drag-and-drop |
| `app_winit.rs` | **Dead file** — not declared in `mod.rs`, not compiled. Preserved for historical reference only. |
| `config.rs` | `Config`, `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, `PerformanceConfig`, `conf.lua` loading |
| `debug_overlay.rs` | `DebugOverlay` — FPS and draw-call counter rendered in the top-right corner |
| `error.rs` | `EngineError` (12 variants with stable codes), `ErrorCategory`, `EngineResult<T>` |
| `error_screen.rs` | `ErrorScreen` — blue error display with word-wrap, traceback, TTF/bitmap text rendering |
| `log_messages.rs` | Stable message ID constants (`L001`–`L082`, `A001`–`A004`, `G001`–`G005`, `P001`–`P002`, etc.), `set_log_level`/`get_log_level`, `log_msg!` macro |
| `messages.rs` | `MessageCatalog` — TOML-backed message lookup; `init()`, `get_message()`, `catalog()` functions |
| `resource_keys.rs` | 14 typed SlotMap key newtypes: `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`, `SpriteBatchKey`, `ShaderKey`, `MeshKey`, `ShapeKey`, `BusKey`, `MidiPlayerKey`, `QueueableKey`, `LightKey`, `OccluderKey` |
| `shared_state.rs` | `SharedState`, `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest` |
| `temp_test.rs` | Placeholder file — contains only the text `testing`, not compiled |
| `cfg/messages.toml` | TOML catalog of human-readable log message strings, embedded at compile time |

## Submodules

### `engine::app`

Application lifecycle using winit 0.30 + wgpu GPU rendering.

- **`App`** (struct): Public entry point. Holds `Config` and launches the winit event loop via `App::run()`.
- **`LunaApp`** (struct, private): winit `ApplicationHandler` implementation. Owns the window, wgpu surface, `GpuRenderer`, Lua VM, `SharedState`, gilrs gamepad polling, `RunState`, and `DebugOverlay`.
- **`RunState`** (enum, private): `Running` | `Error(ErrorScreen)` | `Restarting`.
- **`recompute_viewport`** (fn, private): Recalculates viewport scale/offset for letterbox, stretch, and pixel scaling modes.

### `engine::config`

Engine and window configuration loaded from `conf.lua`.

- **`Config`** (struct): Top-level container with `window`, `graphics`, `modules`, `performance`, `identity`, `version`, `log_file`, `log_append`, `log_level` fields. `load_from_conf_lua(game_dir)` creates a temporary Lua VM, executes `conf.lua`, and reads values back.
- **`WindowConfig`** (struct): Window geometry (width, height), title, vsync, fullscreen, resizable, min size, borderless, icon path, display index, scale mode, game resolution, maximized.
- **`GraphicsConfig`** (struct): GPU backend selection (`"auto"`, `"dx12"`, `"vulkan"`, `"metal"`) and power preference (`"high"`, `"low"`, `"none"`).
- **`ModulesConfig`** (struct): 30+ boolean flags toggling optional subsystems (audio, physics, graphics, input, timer, filesystem, window, particle, image, gui, overlay, tilemap, scene, savegame, entity, ai, pathfinding, thread, graph, data, compute, minimap, modding, pipeline, system, localization, debug, animation, camera, network, procgen, raycaster, spine, terminal). `validate_and_fix()` enforces dependency constraints.
- **`PerformanceConfig`** (struct): Frame rate cap via `target_fps` (default 60).

### `engine::debug_overlay`

Debug overlay for displaying FPS and draw call statistics.

- **`DebugOverlay`** (struct): Toggleable overlay (`enabled` field). `draw_commands()` generates `DrawCommand` sequences (green text on semi-transparent background) for the top-right corner.

### `engine::error`

Structured error types and result alias.

- **`ErrorCategory`** (enum): Five variants — `Init`, `Runtime`, `Resource`, `Script`, `System`. `as_str()` returns the lowercase name.
- **`EngineError`** (enum): 12 `thiserror`-derived variants — `InitializationError`, `RenderError`, `InputError`, `AudioError`, `PhysicsError`, `FileSystemError`, `LuaError`, `WindowError`, `ConfigError`, `ResourceNotFound`, `ResourceNotLoaded`, `IoError`. Each carries `code()` (E1001–E1012), `category()`, and `recovery_hint()`.
- **`EngineResult<T>`** (type): Alias for `Result<T, EngineError>`.

### `engine::error_screen`

Visual error screen for Lua and engine errors.

- **`ErrorScreen`** (struct): Stores pre-processed title, message lines, and traceback. Constructors: `from_error(&str)`, `from_lua_error(&mlua::Error)`, `from_engine_error(&EngineError)`. `draw_commands()` generates a full blue-background error display with TTF or bitmap fallback text. `as_text()` returns the error as plain text for clipboard copy.
- **`wrap_text`** (fn): Word-boundary text wrapping to a column width.
- **`format_traceback`** (fn): Cleans and formats Lua traceback strings.

### `engine::log_messages`

Structured logging with stable message IDs.

- **`set_log_level`** (fn): Sets the global log level at runtime via `log::set_max_level`.
- **`get_log_level`** (fn): Returns the current log level name as `&'static str`.
- **`log_msg!`** (macro): Emits structured log messages with stable ID prefix and catalog text lookup. Supports five log levels and optional dynamic arguments.
- **70+ `pub const`** values: Stable message IDs grouped by subsystem — lifecycle (`L001`–`L007`), GPU (`L033`–`L035`), errors (`L010`–`L017`), warnings (`L020`–`L024`, `L050`–`L053`), subsystems (`L036`–`L044`), debug (`L030`–`L032`), app surface/cursor/screenshot (`L070`–`L082`), callbacks (`L060`), audio (`A001`–`A004`), graphics (`G001`–`G005`), physics (`P001`–`P002`), dataframe (`DF01`), Lua API layer (`LA01`–`LA08`).

### `engine::messages`

TOML-backed human-readable message catalog.

- **`MessageCatalog`** (struct): Immutable map from message ID to text, parsed from the embedded `messages.toml`. Methods: `from_toml()`, `get()`, `len()`, `is_empty()`.
- **`init`** (fn): Initialises the global `OnceLock<MessageCatalog>` from the embedded TOML. Safe to call multiple times.
- **`get_message`** (fn): Resolves a stable message ID to its human-readable text; returns the raw ID if the catalog is not initialised.
- **`catalog`** (fn): Returns `Option<&'static MessageCatalog>`.

### `engine::resource_keys`

Typed resource keys for generational ID-based resource pools.

- **`TextureKey`** (struct): Key for texture resources.
- **`FontKey`** (struct): Key for font resources.
- **`CanvasKey`** (struct): Key for canvas off-screen render targets.
- **`SoundKey`** (struct): Key for audio source entries in the Mixer.
- **`ParticleKey`** (struct): Key for particle system instances.
- **`SpriteBatchKey`** (struct): Key for sprite batch instances.
- **`ShaderKey`** (struct): Key for custom shader instances.
- **`MeshKey`** (struct): Key for mesh instances.
- **`ShapeKey`** (struct): Key for compound shape instances.
- **`BusKey`** (struct): Key for audio bus instances.
- **`MidiPlayerKey`** (struct): Key for MIDI player instances.
- **`QueueableKey`** (struct): Key for queueable audio source instances.
- **`LightKey`** (struct): Key for light source instances in LightWorld.
- **`OccluderKey`** (struct): Key for shadow occluder instances in LightWorld.

### `engine::shared_state`

Central shared runtime state.

- **`FullscreenType`** (enum): `Desktop` (borderless) or `Exclusive` (true fullscreen).
- **`WindowState`** (struct): Window query state (focused, minimized, maximized, visible, DPI scale, position) and pending operations (title, fullscreen, position, size, minimize, maximize, restore, close, attention, icon, vsync, scale mode). Also holds viewport scaling values (game_width, game_height, scale factors, offsets).
- **`ErrorInfo`** (struct): Captured error info — message, code, category, optional hint.
- **`ScreenshotRequest`** (struct): Pending PNG save request with destination path.
- **`SharedState`** (struct): The central hub. Holds all SlotMap resource pools, subsystem instances (Mixer, Clock, GameFS, Camera, EventQueue, LightWorld, MidiState), input state, draw command queue, per-frame statistics, and async loader. `new()` initialises all fields to safe defaults. `step_timer()` advances the clock. `request_async_load()` and `poll_async_load()` manage background file reads.

## Key Types

### Structs

#### `engine::app::App`

Public entry point for the Luna2D engine. Accepts a `Config` and an optional conf.lua error message. `App::run(game_dir, explicit_game_dir)` launches the winit event loop and does not return until the window is closed.

#### `engine::config::Config`

Top-level engine configuration container. Loaded from `conf.lua` via `Config::load_from_conf_lua(game_dir)` which returns `(Config, Option<String>)` — the config and an optional warning message. All fields have sensible defaults.

#### `engine::config::WindowConfig`

Window geometry, title, vsync, fullscreen, resizable, min size, borderless, icon path, display index, scale mode (`"none"`, `"letterbox"`, `"stretch"`, `"pixel"`), logical game resolution, and maximized flag.

#### `engine::config::GraphicsConfig`

GPU backend selection (`"auto"`, `"dx12"`, `"vulkan"`, `"metal"`) and power preference (`"high"`, `"low"`, `"none"`). Read once at startup; changing after GPU init has no effect.

#### `engine::config::ModulesConfig`

30+ boolean flags controlling which optional subsystems are enabled. `validate_and_fix()` disables modules that depend on absent prerequisites (e.g. particle requires graphics).

#### `engine::config::PerformanceConfig`

Frame rate cap via `target_fps` (default 60).

#### `engine::debug_overlay::DebugOverlay`

Toggleable FPS and draw-call counter. `draw_commands()` produces a `Vec<DrawCommand>` sequence when `enabled` is true; returns empty when disabled.

#### `engine::error_screen::ErrorScreen`

Blue error display with word-wrapped message, traceback, and help footer. Supports TTF fonts when available or falls back to built-in bitmap text. `as_text()` returns the error as plain text for clipboard copy.

#### `engine::messages::MessageCatalog`

Immutable map from stable message ID strings to human-readable text. Parsed from the compile-time-embedded `messages.toml` TOML catalog.

#### `engine::shared_state::WindowState`

Tracks window query state (focused, minimized, maximized, visible, DPI scale, position) and queues pending window operations set by Lua and consumed by the event loop. Also holds viewport scaling state for letterbox/stretch/pixel modes.

#### `engine::shared_state::ErrorInfo`

Captured structured error info: message, stable code, category, optional recovery hint.

#### `engine::shared_state::ScreenshotRequest`

Pending request to save the next rendered frame as a PNG to the given path.

#### `engine::shared_state::SharedState`

Central shared state passed as `Rc<RefCell<SharedState>>` to every Lua API closure and the engine loop. Owns all resource pools (textures, fonts, canvases, meshes, shaders, shapes, sprite batches, particle systems), subsystem instances (Mixer, Clock, GameFS, Camera, EventQueue, LightWorld, MidiState), input state, draw command queue, per-frame statistics, and async loader.

### Enums

#### `engine::error::ErrorCategory`

Five error categories: `Init`, `Runtime`, `Resource`, `Script`, `System`. Used by `EngineError::category()` for structured grouping.

#### `engine::error::EngineError`

12 `thiserror`-derived variants with stable four-digit codes (E1001–E1012): `InitializationError`, `RenderError`, `InputError`, `AudioError`, `PhysicsError`, `FileSystemError`, `LuaError`, `WindowError`, `ConfigError`, `ResourceNotFound`, `ResourceNotLoaded`, `IoError`. Methods: `code()`, `category()`, `recovery_hint()`.

#### `engine::shared_state::FullscreenType`

`Desktop` (borderless fullscreen at desktop resolution) or `Exclusive` (true fullscreen that takes over the display).

## Lua API

No Lua API — foundation module. The engine module does not expose a `luna.engine`
namespace. It provides the infrastructure consumed by all other modules and by
`src/lua_api/` for lifecycle orchestration. Lua interacts with engine functionality
indirectly through `luna.system` (log level, system info), `luna.window` (window
state), `luna.event` (quit, restart), and `luna.graphics` (draw commands, screenshot).

## Lua Examples

N/A — engine is a foundation module with no dedicated Lua API surface. Game scripts
interact with engine functionality through higher-level namespaces:

```lua
-- conf.lua — engine configuration (read by engine::config)
function luna.conf(t)
    t.window.title  = "My Game"
    t.window.width  = 1280
    t.window.height = 720
    t.window.vsync  = true
    t.modules.physics = true
    t.performance.target_fps = 60
end
```

```lua
-- main.lua — engine callbacks (dispatched by engine::app)
function luna.load()
    -- called once after main.lua executes
end

function luna.update(dt)
    -- called every frame with delta time
end

function luna.draw()
    -- called every frame; push DrawCommands here
end

function luna.errorhandler(msg)
    -- optional: custom error handling before error screen
    return msg
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 27    |
| `enum`     | 3     |
| `type`     | 1     |
| `fn`       | 30    |
| `const`    | 73    |
| `macro`    | 1     |
| **Total**  | **135** |

## References

| Module          | Relationship | Notes |
|-----------------|--------------|-------|
| `math`          | Imports from | `Vec2`, `Color`, `Rect` (Baseline leaf — no deps) |
| `graphics`      | Imports from | `GpuRenderer`, `DrawCommand`, `DrawMode`, `TextureData`, `Canvas`, `Mesh`, `Shader`, `Font`, `SpriteBatch`, `CompoundShape`, `BlendMode`, `StencilMode`, `DepthMode`, `RenderStats` |
| `audio`         | Imports from | `Mixer`, `MidiState` |
| `input`         | Imports from | `KeyboardState`, `MouseState`, `GamepadState`, `TouchState`, `GamepadMappings`, `SystemCursor`, key/button conversion functions |
| `timer`         | Imports from | `Clock` |
| `filesystem`    | Imports from | `GameFS`, `AsyncLoader`, `LoadHandle`, `LoadResult`, `LoadStatus` |
| `camera`        | Imports from | `Camera` |
| `event`         | Imports from | `EventQueue`, `EventArg` |
| `particle`      | Imports from | `ParticleSystem` |
| `light`         | Imports from | `LightWorld` |
| `lua_api`       | Imports from | `create_lua_vm` (for Lua VM initialization) |
| `lua_api`       | Imported by  | All `lua_api/*_api.rs` modules receive `Rc<RefCell<SharedState>>` |
| All Tier 1/2    | Imported by  | Every module uses `EngineError`, `EngineResult`, resource keys |
| `main.rs`       | Imported by  | Constructs `App` and calls `App::run()` |

**Similar modules**: `engine` is unique — no other module serves the same role. The closest relationship is with `lua_api`, which is the bridge layer that registers the `luna.*` namespace using types from `engine`.

## Notes

- **`app_winit.rs` is dead code**: It is not declared in `mod.rs` and is not compiled. Preserved for historical reference only. Do not modify it.
- **`temp_test.rs` is a placeholder**: Contains only the text `testing`. Not compiled or tested.
- **`Rc<RefCell<>>` is intentional**: `SharedState` uses `Rc<RefCell<>>` because all Lua callbacks are single-threaded. Never change this to `Arc<Mutex<>>` — it would add lock overhead with zero benefit since worker threads get separate Lua VMs.
- **`conf.lua` errors are non-fatal**: `Config::load_from_conf_lua()` returns defaults on error. The error message is passed through to the engine for later display, but the window still opens.
- **RunState machine is private**: `RunState` and `LunaApp` are not public. External code only interacts with `App::new()` and `App::run()`.
- **ErrorScreen supports TTF fallback**: When the engine fonts are available, error text renders with `PrintFont` commands. Otherwise, it falls back to the built-in bitmap font at a larger scale.
- **Resource keys are cross-module**: The 14 key types defined in `resource_keys.rs` are used throughout the entire engine (graphics, audio, particle, light, etc.), not just within the engine module.
- **`log_msg!` macro requires `MessageCatalog::init()`**: Called automatically by `App::new()`. If used before init, the macro falls back to printing the raw message ID.
- **Viewport scaling**: `recompute_viewport()` supports four modes (`"none"`, `"letterbox"`, `"stretch"`, `"pixel"`) and is called on every window resize. Coordinates are transformed from game-space to window-space.
- **Drag-and-drop**: The splash screen supports dropping a game folder onto the window to load it immediately, enabling a zero-CLI workflow.
- **No `unsafe` in this module** except one `// SAFETY:` documented cast in `get_message()` to extend the lifetime of `OnceLock`-stored strings to `'static`.
