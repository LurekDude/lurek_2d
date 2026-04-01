# `src/lua_api/` — Lua Binding Layer

## Purpose

The lua_api module is the complete Lua interface layer — it defines
`SharedState` (the single `Rc<RefCell<>>` struct that every API closure
captures), implements the Lua VM factory function `create_lua_vm()`, and
contains 30+ API source files each implementing a family of `luna.*` functions.
When the engine starts a new game, `create_lua_vm()` builds the mlua VM,
creates the `luna` global table, and calls every module's `register()` function
to populate it — one file per subsystem, each file covering a coherent surface
area.

Every API file follows a single contract:
`pub fn register(lua, luna_table, Rc<RefCell<SharedState>>) -> LuaResult<()>`.
Inside `register`, each closure clones the `Rc` before capturing it by move,
borrows `SharedState` via `borrow()` or `borrow_mut()`, performs the operation,
and returns a `LuaResult`.  No unsafe code is needed; the borrow checker
enforces the single-threaded contract and `RefCell` provides the runtime
borrow check that replaces compile-time lifetimes for the complex
cross-closure sharing pattern.

The Lua sandbox is enforced in `system_api.rs`: dangerous globals (`io`,
`os.execute`, `dofile`, `loadfile`, `require`, `package`, `debug`) are nilled
out after VM construction but before any script code runs.  The safe Lua
standard library (`math`, `table`, `string`, `coroutine`, `utf8`) remains
available.  A safe `require`-equivalent is provided through
`luna.filesystem.loadLua()` so game scripts can load modules from within the
sandboxed game directory.

## Architecture

```
SharedState (Rc<RefCell<SharedState>>)
  │
  ├── 90+ pub fields ── textures, fonts, sounds, physics world,
  │     input states, filesystem, renderer, draw commands, etc.
  │
  ├── create_lua_vm() ── Lua VM factory
  │     ├── Creates mlua::Lua instance (LuaJIT or Lua 5.4)
  │     ├── Creates `luna` global table
  │     └── Calls register() on all API modules
  │
  └── API modules (each has pub fn register())
        │
        ├── Graphics ── luna.graphics.* (120+ functions)
        │     ├── Drawing: rectangle, circle, line, polygon, print, ...
        │     ├── Textures: newImage, draw(image), newCanvas, setCanvas
        │     ├── Fonts: newFont, setFont, printf (aligned text)
        │     ├── Transforms: push, pop, translate, rotate, scale
        │     ├── Stencil: setStencilTest, stencil (masking)
        │     ├── Shaders: newShader, setShader, shader:send
        │     ├── Meshes: newMesh, mesh:setVertex
        │     └── SpriteBatch: newSpriteBatch, batch:add
        │
        ├── Audio ── luna.audio.* (25+ functions)
        │     ├── newSource, play, pause, stop, setVolume
        │     ├── Bus: newBus, setBusVolume
        │     └── MIDI: newMidiPlayer, loadMidi
        │
        ├── Input ── luna.keyboard/mouse/gamepad/touch.*
        │     ├── Keyboard: isDown, getPressed, scancodes
        │     ├── Mouse: getPosition, isDown, setCursor
        │     ├── Gamepad: isDown, getAxis, getName
        │     └── Touch: getTouches, getTouch
        │
        ├── Physics ── luna.physics.* (70+ functions)
        │     ├── World: newWorld, step, setGravity
        │     ├── Bodies: newBody (rect/circle/polygon/edge/chain)
        │     ├── Joints: 10 types (revolute, distance, prismatic, ...)
        │     └── Queries: raycast, queryAABB, getContacts
        │
        ├── Filesystem ── luna.filesystem.* (sandboxed I/O)
        ├── Timer ── luna.timer.* (frame timing, scheduler)
        ├── Window ── luna.window.* (window lifecycle)
        ├── Math ── luna.math.* (vector utilities)
        ├── Data ── luna.data.* (compress, hash, TOML)
        ├── DataFrame ── luna.data.* (tabular, SQL)
        ├── Entity ── luna.entity.* (ECS)
        ├── Scene ── luna.scene.* (scene stack)
        ├── Particle ── luna.particle.* (particle systems)
        ├── Tilemap ── luna.tilemap.* (tilemaps, autotile)
        ├── AI ── luna.ai.* (FSM, BT, steering, pathfinding)
        ├── Compute ── luna.compute.* (NdArray)
        ├── Graph ── luna.graph.* (directed graph)
        ├── Image ── luna.image.* (pixel data)
        ├── Sound ── luna.sound.* (raw samples)
        ├── Modding ── luna.modding.* (mod management)
        ├── Savegame ── luna.savegame.* (save/load)
        ├── Pathfinding ── luna.pathfinding.* (A*, flow fields)
        ├── Event ── luna.event.* (custom events)
        ├── System ── luna.system.* (OS info, clipboard)
        ├── Thread ── luna.thread.* (multi-threading)
        ├── Graphics Ext ── additional graphics functions
        └── Math Ext ── additional math functions
```

### How It Works

`SharedState` is designed for single-threaded access only and is `!Send` by
design — wgpu surface handles, `winit::Window`, and the Lua VM itself all
require main-thread access.  Using `Arc<Mutex<>>` instead of `Rc<RefCell<>>`
would require `Send + Sync` bounds on every resource type including GPU objects,
which wgpu explicitly forbids.  The `!Send` constraint is therefore load-bearing
architecture, not an oversight.

The split between `graphics_api.rs` (~2 150 lines) and `graphics_ext_api.rs`
(~300 lines) reflects the incremental development history of the graphics
surface: core draw calls go in the main file, newer specialised renderers and
extended utilities go in ext.  The same pattern applies to `math_api.rs` and
`math_ext_api.rs`.  All splits are logical, not arbitrary size limits;
the distinction is between the stable core API and evolving extended API.

Error conversion follows a single convention: Rust `Err(String)` becomes
`Err(LuaError::RuntimeError(msg))`, which Lua receives as a pcall error with
the Rust error message preserved.  No opaque numeric error codes are used.
The engine's `catch_lua_error` wrapper around `luna.update()` and `luna.draw()`
converts Lua runtime errors into the `RunState::Error` state for display on
the error screen.

### Dependency Direction

```
lua_api/ ──────► ALL domain modules
             ──► engine/ (SharedState, EngineError, resource keys)
```

**Integration module** — depends on every domain module to bridge them to Lua.
Second only to `engine/` in dependency breadth.

---

## File-by-File Analysis

### `mod.rs` — SharedState and VM Factory

**~500 lines** | The central state object and Lua VM creation.

#### Struct: `SharedState`

```rust
pub struct SharedState {
    // 90+ pub fields including:
    pub draw_commands: Vec<DrawCommand>,
    pub renderer: Option<GpuRenderer>,
    pub keyboard: KeyboardState,
    pub mouse: MouseState,
    pub gamepads: Vec<GamepadState>,
    pub touch: TouchState,
    pub physics_world: Option<World>,
    pub mixer: Option<Mixer>,
    pub filesystem: Option<GameFS>,
    pub clock: Clock,
    pub textures: SlotMap<TextureKey, Texture>,
    pub fonts: SlotMap<FontKey, Font>,
    // ... and many more
}
```

#### Struct: `WindowState`

Window dimensions, title, fullscreen state — read/write from Lua.

#### Function: `create_lua_vm(state: Rc<RefCell<SharedState>>) → Lua`

Creates the Lua VM, creates the `luna` global table, and calls `register()`
on all 30+ API modules.

**Design**: SharedState uses `Rc<RefCell<>>` for interior mutability. Each API
module's `register()` function clones the `Rc` and moves it into closures.

---

### `graphics_api.rs` — `luna.graphics.*`

**~2150 lines** | The largest API file. 120+ drawing and resource functions.

**Key patterns**:
- Drawing functions push `DrawCommand` variants to the queue
- Resource functions create SlotMap entries (textures, fonts, canvases)
- Transform functions manage a matrix stack

---

### `physics_api.rs` — `luna.physics.*`

**~1650 lines** | Physics world, body, joint, and query bindings.

---

### `ai_api.rs` — `luna.ai.*`

**~1160 lines** | 37 factory functions with UserData wrappers for 15 AI types.

---

### `tilemap_api.rs` — `luna.tilemap.*`

**~1900 lines** | Tilemap creation, tile access, autotile, TMX loading.

---

### `audio_api.rs` — `luna.audio.*`

**~910 lines** | Sound loading, playback, bus routing, MIDI.

---

### `dataframe_api.rs` — `luna.data.*` (dataframes)

**~700 lines** | DataFrame operations and SQL queries from Lua.

---

### `particle_api.rs` — `luna.particle.*`

**~700 lines** | Particle system configuration and control.

---

### `pathfinding_api.rs` — `luna.pathfinding.*`

**~500 lines** | Grid pathfinding, flow fields, thread pool.

---

### `entity_api.rs` — `luna.entity.*`

**~420 lines** | ECS universe operations from Lua.

---

### `math_api.rs` — `luna.math.*`

**~400 lines** | Vector math, random, noise exposed to Lua.

---

### `compute_api.rs` — `luna.compute.*`

**~380 lines** | NdArray operations from Lua.

---

### `input_api.rs` — `luna.keyboard/mouse/gamepad/touch.*`

**~370 lines** | Input state queries across four namespaces.

---

### `scene_api.rs` — `luna.scene.*`

**~320 lines** | Scene stack management from Lua.

---

### `filesystem_api.rs` — `luna.filesystem.*`

**~300 lines** | Sandboxed file I/O from Lua.

---

### `timer_api.rs` — `luna.timer.*`

**~280 lines** | Frame timing and scheduler from Lua.

---

### `window_api.rs` — `luna.window.*`

**~250 lines** | Window dimensions, title, fullscreen from Lua.

---

### `data_api.rs` — `luna.data.*` (utilities)

**~180 lines** | Compression, hashing, encoding, TOML.

---

### `thread_api.rs` — `luna.thread.*`

**~150 lines** | Thread creation and channel communication.

---

### Smaller API Files

| File | Namespace | Lines | Purpose |
|------|-----------|-------|---------|
| `graph_api.rs` | `luna.graph.*` | ~200 | Directed graph operations |
| `image_api.rs` | `luna.image.*` | ~150 | Pixel data manipulation |
| `modding_api.rs` | `luna.modding.*` | ~150 | Mod management |
| `savegame_api.rs` | `luna.savegame.*` | ~200 | Save/load operations |
| `system_api.rs` | `luna.system.*` | ~100 | OS info, clipboard |
| `sound_api.rs` | `luna.sound.*` | ~60 | Raw audio samples |
| `event_api.rs` | `luna.event.*` | ~80 | Custom event queue |
| `graphics_ext_api.rs` | `luna.graphics.*` | ~300 | Extended graphics functions |
| `math_ext_api.rs` | `luna.math.*` | ~200 | Extended math functions |
| `userdata.rs` | (internal) | ~50 | `LunaType` trait for UserData |

### Internal Helper Files

| File | Purpose |
|------|---------|
| `thread_channel.rs` | Channel type for inter-thread communication |
| `thread_worker.rs` | Worker thread implementation |

---

## Cross-Cutting Concerns

### Registration Pattern

Every API file follows the same signature:

```rust
pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()>
```

Each function clones `Rc` before moving it into a closure:

```rust
let state_clone = state.clone();
luna.set("functionName", lua.create_function(move |lua, args| {
    let mut state = state_clone.borrow_mut();
    // ... use state ...
})?)?;
```

### Error Handling

All Lua-callable functions return `LuaResult<T>`. Engine errors are converted
to Lua errors via `LuaError::RuntimeError(msg)`.

### Resource Management

Resources (textures, fonts, sounds) are stored in `SlotMap` containers in
SharedState. Lua receives opaque keys; the bridge resolves keys to resources
on every call.
