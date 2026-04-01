# `src/engine/` — Application Lifecycle and Core Infrastructure

## Purpose

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

### How It Works

The frame tick follows a strict ordering: (1) poll input events from winit,
(2) advance physics with a fixed-timestep accumulator so physics is independent
of frame rate, (3) call `luna.update(dt)` with the real elapsed delta, (4) call
`luna.draw()`, (5) process the `DrawCommand` queue in
`GpuRenderer::render_frame()`, and (6) present the swapchain frame.  Steps 3
and 4 are guarded by `catch_lua_error`, which converts Lua runtime errors into
`RunState::Error`, triggering the error screen without crashing the process.

Error recovery reconstructs the Lua VM and reinitialises `SharedState` on
receiving the "R" key, without restarting the OS process or reinitialising the
GPU.  This fast-reload loop is the primary developer workflow for fixing script
errors: edit Lua, press R, see the result in under a second.

Resource keys (`TextureKey`, `FontKey`, `CanvasKey`, etc.) are typed
`slotmap::DefaultKey` aliases — opaque handles that identify GPU-side
resources inside `GpuRenderer` without leaking raw pointers to Lua.  Lua
scripts receive lightweight table wrappers around these keys; the actual wgpu
objects are never exposed outside the runtime.

### Dependency Direction

```
engine/ ──────► ALL other modules (graphics, audio, input, physics, lua_api, etc.)
```

**Hub module** — the engine is the top-level orchestrator. It is the only module
permitted to depend on every other module.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `App`, `Config`, `EngineError`, `EngineResult`, `ErrorCategory`,
`DebugOverlay`, `ErrorScreen`, `ResourceKeys`, log message types.

**~20 lines** — re-exports for all engine sub-modules.

---

### `app.rs` — `App` (Application Entry Point)

**~1345 lines** | The main game loop and winit `ApplicationHandler` implementation.

#### Struct: `App`

```rust
pub struct App {
    config: Config,
    game_path: Option<PathBuf>,
}
```

#### Enum: `RunState`

`Running | Error(ErrorInfo) | Restarting`

#### Private: `LunaApp`

The winit `ApplicationHandler` trait implementation — handles window events,
manages GPU state, Lua VM, and the frame loop.

| Method | Purpose |
|--------|---------|
| `init_gpu()` | Create wgpu adapter, device, surface |
| `init_lua()` | Create Lua VM, load game script, register all `luna.*` APIs |
| `tick_frame()` | One engine frame: poll input → `luna.update(dt)` → `luna.draw()` → present |
| `game_update()` | Fixed-timestep game logic |
| `render()` | Execute draw command queue through `GpuRenderer` |

**20+ Lua callbacks** dispatched: `load`, `update`, `draw`, `keypressed`, `keyreleased`,
`mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`, `resize`,
`focus`, `visible`, `textinput`, `touchpressed`, `touchmoved`, `touchreleased`,
`gamepadpressed`, `gamepadreleased`, `gamepadaxis`, `quit`.

---

### `config.rs` — `Config` (Game Configuration)

**~268 lines** | Configuration loaded from `conf.lua` at startup.

#### Struct Hierarchy

```rust
pub struct Config {
    pub window: WindowConfig,
    pub modules: ModulesConfig,
    pub performance: PerformanceConfig,
}

pub struct WindowConfig {
    pub title: String,
    pub width: u32,
    pub height: u32,
    pub vsync: bool,
    pub resizable: bool,
    pub fullscreen: bool,
}

pub struct ModulesConfig {
    pub physics: bool,
    pub audio: bool,
    pub joystick: bool,
}

pub struct PerformanceConfig {
    pub target_fps: u32,
    pub fixed_timestep: f64,
}
```

Methods: `default`, `load_from_conf_lua(path)`.

**Design**: `conf.lua` is a Lua script that sets config values in a table.
Unset values fall back to defaults. This matches standard Lua engine conf.lua pattern.

---

### `error.rs` — `EngineError`

**~115 lines** | Structured error enum with error codes and categories.

#### Enum: `EngineError` (13 variants)

| Code | Variant | Category |
|------|---------|----------|
| E1001 | `LuaError` | Runtime |
| E1002 | `GraphicsError` | Graphics |
| E1003 | `AudioError` | Audio |
| E1004 | `FileSystemError` | IO |
| E1005 | `WindowError` | Window |
| E1006 | `ConfigError` | Config |
| E1007 | `PhysicsError` | Physics |
| E1008 | `InputError` | Input |
| E1009 | `TimerError` | Timer |
| E1010 | `MathError` | Math |
| E1011 | `NetworkError` | Network |
| E1012 | `GenericError` | Generic |

Uses `thiserror` derive macro for `Display` and `Error` implementations.

---

### `error_screen.rs` — `ErrorScreen`

**~367 lines** | Blue-background error display with word wrapping and traceback formatting.

Methods: `new`, `render(draw_commands)`, `handle_key(key)`.

Controls: **Escape** to quit, **R** to restart. Formats Lua tracebacks into
readable multi-line displays with line number highlighting.

---

### `debug_overlay.rs` — `DebugOverlay`

**~96 lines** | In-game debug display toggled with F12.

Shows: current FPS, draw call count, batched draw count.

Methods: `new`, `toggle`, `is_visible`, `update(stats)`, `render(draw_commands)`.

---

### `log_messages.rs` — Structured Logging

**~117 lines** | Message constants L001–L032 and the `log_msg!` macro.

Provides stable log message IDs for consistent logging across the engine.
Functions: `set_log_level`, `get_log_level`.

---

### `resource_keys.rs` — SlotMap Key Types

**~21 lines** | Defines 10 `new_key_type!` declarations for SlotMap-based resource storage.

```rust
new_key_type! { pub struct TextureKey; }
new_key_type! { pub struct FontKey; }
new_key_type! { pub struct CanvasKey; }
new_key_type! { pub struct SoundKey; }
new_key_type! { pub struct ParticleKey; }
new_key_type! { pub struct SpriteBatchKey; }
new_key_type! { pub struct ShaderKey; }
new_key_type! { pub struct MeshKey; }
new_key_type! { pub struct BusKey; }
new_key_type! { pub struct MidiPlayerKey; }
```

---

## Cross-Cutting Concerns

### Error Handling

`EngineError` is the engine-wide error type. All modules return `EngineResult<T>`
(alias for `Result<T, EngineError>`) for cross-module operations. Error codes
(E10XX) enable structured error reporting and log filtering.

### Thread Safety

The engine loop runs single-threaded. `SharedState` is `Rc<RefCell<>>`, not
`Arc<Mutex<>>` — no cross-thread access. `AsyncLoader` internally handles its
own threading.

### Lua Integration

`app.rs` creates the Lua VM and registers all `luna.*` API modules. The engine
dispatches Lua callbacks (`luna.load`, `luna.update`, `luna.draw`, etc.) during
the frame loop.

### Usage from Lua

```lua
-- conf.lua (configuration)
function luna.conf(t)
    t.window.title = "My Game"
    t.window.width = 1280
    t.window.height = 720
    t.modules.physics = true
end

-- main.lua (game loop)
function luna.load()
    -- one-time initialization
end

function luna.update(dt)
    -- game logic
end

function luna.draw()
    -- rendering
end
```
