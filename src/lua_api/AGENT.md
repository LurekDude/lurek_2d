# `lua_api` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Bridge Layer |
| **Lua API** | `N/A — this IS the binding layer` |
| **Source** | `src/lua_api/` |
| **Tests** | `tests/lua/` (Lua BDD harness via `tests/lua/harness.rs`) |

## Summary

The lua_api module is the complete Lua interface layer — it re-exports
`SharedState` (defined in `engine::shared_state`, the single `Rc<RefCell<>>` struct that every API closure
captures), implements the Lua VM factory function `create_lua_vm()`, and
contains 40+ API source files each implementing a family of `luna.*` functions.
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

> **Gameplay libraries** (battle, cardgame, combat, crafting, dialog, economy,
> inventory, quest, stats) are pure-Lua modules in `library/` — they have no
> Rust API files in this folder.

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
        └── Thread ── luna.thread.* (multi-threading)
```

## Source Files

| File | Purpose |
|------|---------|
| `ai_api.rs` | Registers the `luna.ai.*` game AI toolkit API |
| `audio_api.rs` | Registers the `luna.audio.*` sound playback API |
| `automation_api.rs` | Registers the `luna.simulator.*` automated input simulation API |
| `compute_api.rs` | Registers the `luna.compute.*` array computation API |
| `data_api.rs` | Registers the `luna.data.*` binary data, compression, hashing, and encoding API |
| `dataframe_api.rs` | Registers the `luna.dataframe.*` tabular data API |
| `debug_api.rs` | Registers the `luna.devtools.*` runtime diagnostics and developer tools API |
| `debugbridge_api.rs` | Registers the `luna.debugbridge.*` TCP debug server API |
| `docs_api.rs` | Registers the `luna.docs.*` documentation management API |
| `entity_api.rs` | Registers the `luna.entity.*` ECS universe API |
| `event_api.rs` | Registers `luna.event.*` engine lifecycle API |
| `filesystem_api.rs` | Registers the `luna.filesystem.*` sandboxed I/O API |
| `font_api.rs` | Registers the `luna.font.*` font rasterizer and glyph metrics API |
| `graph_api.rs` | Registers the `luna.graph.*` directed-graph and item-flow simulation API |
| `graphics_api.rs` | Registers the `luna.graphics.*` drawing API |
| `gui_api.rs` | Registers the `luna.gui.*` retained-mode widget UI API |
| `image_api.rs` | Registers the `luna.image.*` pixel-level image manipulation API |
| `input_api.rs` | Registers the `luna.keyboard.*` and `luna.mouse.*` input API |
| `localization_api.rs` | Registers the `luna.localization.*` internationalization API |
| `log_api.rs` | Registers the `luna.log.*` structured game-level logging API |
| `lua_types.rs` | UserData type utilities for Luna2D Lua objects |
| `math_api.rs` | Registers the `luna.math.*` vector and math helper API |
| `minimap_api.rs` | Registers the `luna.minimap.*` minimap API |
| `modding_api.rs` | Registers the `luna.modding.*` mod management API |
| `overlay_api.rs` | Registers the `luna.overlay.*` screen-effect overlay API |
| `particle_api.rs` | Registers the `luna.particle.*` particle-effects API |
| `pathfinding_api.rs` | Registers the `luna.pathfinding.*` grid-based pathfinding API |
| `patterns_api.rs` | Registers the `luna.patterns.*` software design patterns API |
| `physics_api.rs` | Registers the `luna.physics.*` rigid-body simulation API |
| `pipeline_api.rs` | Registers the `luna.pipeline.*` DAG pipeline orchestrator API |
| `postfx_api.rs` | Registers the `luna.postfx.*` post-processing effects API |
| `savegame_api.rs` | Registers the `luna.savegame.*` save/load system API |
| `scene_api.rs` | Registers the `luna.scene.*` scene stack, registry, data store, and depth-sorter API |
| `sprite_api.rs` | Registers extended graphics types: sprite system, Camera2D, Animation, Trail, atlas utilities |
| `steering_api.rs` | Registers the `luna.steering.*` AI steering behaviours API |
| `system_api.rs` | Registers the `luna.system.*` platform query API |
| `thread_api.rs` | Registers the `luna.thread.*` multithreading API |
| `tilemap_api.rs` | Registers the `luna.tilemap.*` tile map, tileset, autotile, and procedural generation API |
| `timer_api.rs` | Registers the `luna.timer.*` frame-timing API |
| `window_api.rs` | Registers the `luna.window.*` window management API |

## Submodules

### `lua_api::ai_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.ai.*` game AI toolkit API.

### `lua_api::audio_api`

Audio Api implementation for the `lua_api` subsystem.

- **`LuaSource`** (struct): Lua UserData wrapper for an audio source resource.
- **`LuaBus`** (struct): Lua UserData wrapper for an audio bus. Consult the module-level documentation for the broader usage context and...
- **`LuaMidiPlayer`** (struct): Lua UserData wrapper for the MIDI player.
- **`register`** (fn): Registers all `luna.audio.*` functions into the Lua VM.

### `lua_api::compute_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.compute` table with array factory functions.

### `lua_api::data_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.data` table on the provided `luna` namespace.

### `lua_api::dataframe_api`

Registers the `luna.

- **`register`** (fn): Register the `luna.dataframe` namespace.

### `lua_api::debug_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.devtools` namespace.

### `lua_api::debugbridge_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.debugbridge` namespace.

### `lua_api::docs_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.docs` namespace. Panics in debug mode if the same entity is registered twice.

### `lua_api::entity_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.entity` table with the `newUniverse` factory function.

### `lua_api::event_api`

Event Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.event.quit()` and related engine lifecycle functions into the Lua VM.

### `lua_api::filesystem_api`

Filesystem Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.filesystem.*` functions into the Lua VM.

### `lua_api::graph_api`

Registers the `luna.

- **`register`** (fn): Register the `luna.graph` API table. Panics in debug mode if the same entity is registered twice.

### `lua_api::graphics_api`

Registers the `luna.

- **`ext`** (mod): Ext sub-module.
- **`register`** (fn): Register `luna..*` bindings in the Lua state.

### `lua_api::graphics_api::ext`

Extended graphics API registrations (second half of `register`).

- **`register_ext`** (fn): Register extended Lua bindings for this sub-module.

### `lua_api::graphics_api::helpers`

Helper types and utilities for the graphics API.

- **`LuaImage`** (struct): Lua UserData wrapper for a loaded texture/image resource.
- **`LuaNineSlice`** (struct): Lua UserData wrapper for a nine-slice (9-patch) image definition.  Stores the source texture key, border insets, and...
- **`LuaFont`** (struct): Lua UserData wrapper for a loaded font resource.
- **`LuaSpriteBatch`** (struct): Lua UserData wrapper for a sprite batch resource.
- **`LuaCanvas`** (struct): Lua UserData wrapper for an off-screen canvas resource.
- **`texture_key_from_value`** (fn): Extract a `TextureKey` from either a `LuaImage` UserData or a numeric ID.
- **`font_key_from_value`** (fn): Extract a `FontKey` from either a `LuaFont` UserData or a numeric ID.
- **`batch_key_from_value`** (fn): Extract a `SpriteBatchKey` from either a `LuaSpriteBatch` UserData or a numeric ID.
- **`canvas_key_from_value`** (fn): Extract a `CanvasKey` from either a `LuaCanvas` UserData or a numeric ID.
- **`invalid_texture_handle`** (fn): Returns a `LuaError` for an invalid texture handle.
- **`invalid_font_handle`** (fn): Returns a `LuaError` for an invalid font handle.
- **`invalid_batch_handle`** (fn): Returns a `LuaError` for an invalid batch handle.
- **`invalid_canvas_handle`** (fn): Returns a `LuaError` for an invalid canvas handle.
- **`invalid_mesh_handle`** (fn): Returns a `LuaError` for an invalid mesh handle.
- **`require_texture_key`** (fn): Resolve and validate a texture key, returning `LuaError` if missing.
- **`require_font_key`** (fn): Resolve and validate a font key, returning `LuaError` if missing.
- **`require_batch_key`** (fn): Resolve and validate a batch key, returning `LuaError` if missing.
- **`require_canvas_key`** (fn): Resolve and validate a canvas key, returning `LuaError` if missing.
- **`require_mesh_key`** (fn): Resolve and validate a mesh key, returning `LuaError` if missing.

### `lua_api::image_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.image` table on the provided `luna` namespace.

### `lua_api::input_api`

Input Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.keyboard.*` and `luna.mouse.*` query functions into the Lua VM.

### `lua_api::localization_api`

Registers the `luna.

- **`register`** (fn): Registers `luna.localization.*` functions.

### `lua_api::log_api`

Structured game-level logging API (`luna.

- **`register`** (fn): Registers the `luna.log.*` namespace into the shared `luna` table.

### `lua_api::lua_types`

UserData type utilities for Luna2D Lua objects.

- **`LunaType`** (trait): Standard type identification for Luna2D UserData objects.  Every Luna2D Lua object implements this trait to declare its...
- **`add_type_methods`** (fn): Adds standard `type()` and `typeOf()` methods to a UserData definition.

### `lua_api::math_api`

Math Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.math.*` helpers (Vec2, distance, random, noise, transforms, etc.) into the Lua VM.

### `lua_api::minimap_api`

Lua API bindings for the `luna.

- **`LuaMinimap`** (struct): Lua UserData wrapper for a grid-based minimap.
- **`register`** (fn): Register the `luna.minimap` module. Panics in debug mode if the same entity is registered twice.

### `lua_api::modding_api`

Modding Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.modding.*` functions into the Lua VM.

### `lua_api::particle_api`

Registers the `luna.

- **`ext`** (mod): Ext sub-module.
- **`register`** (fn): Register `luna..*` bindings in the Lua state.

### `lua_api::particle_api::ext`

Extended particle API registrations (second half of `register`).

- **`register_ext`** (fn): Register extended Lua bindings for this sub-module.

### `lua_api::particle_api::helpers`

Helper functions for the particle API.

- **`invalid_particle_handle`** (fn): Returns a `LuaError` for an invalid particle handle.
- **`ensure_particle_exists`** (fn): Return `LuaError` if the particle does not exist in the pool.
- **`require_particle_key`** (fn): Resolve and validate a particle key, returning `LuaError` if missing.
- **`particle_system`** (fn): Borrow the particle system from shared state.
- **`particle_system_mut`** (fn): Borrow the particle system (mutable) from shared state.
- **`particle_key_from_value`** (fn): Extract a `ParticleKey` from either a `LuaParticleSystem` UserData or a numeric ID.  Callers validate liveness against...
- **`parse_color`** (fn): Helper: parse a Lua color table `{r, g, b, a}` into `[f32; 4]`.
- **`LuaParticleSystem`** (struct): Lua UserData wrapper for a particle system resource.
- **`parse_emission_shape`** (fn): Parse an emission shape from a Lua string name and optional parameters table.
- **`emission_shape_to_lua`** (fn): Convert an `EmissionShape` to a Lua table with type and parameter fields.
- **`lua_value_to_f64`** (fn): Helper to extract an f64 from a `LuaValue`.

### `lua_api::pathfinding_api`

Registers the `luna.

- **`register`** (fn): Register the `luna.pathfinding` namespace.

### `lua_api::patterns_api`

Registers the `luna.

- **`register`** (fn): Registers `luna.patterns.*` factory functions.

### `lua_api::physics_api`

Registers the `luna.

- **`ext`** (mod): Ext sub-module.
- **`register`** (fn): Register `luna..*` bindings in the Lua state.

### `lua_api::physics_api::ext`

Extended physics API registrations (second half of `register`).

- **`register_ext`** (fn): Register extended Lua bindings for this sub-module.

### `lua_api::physics_api::helpers`

Helper types and utilities for the physics API.

- **`parse_body_type`** (fn): Parses a body type string into a `BodyType` enum value.
- **`LuaWorld`** (struct): Lua UserData wrapper for a physics world.
- **`LuaBody`** (struct): Lua UserData wrapper for a physics body.
- **`world_index_from_value`** (fn): Extract a world index from either a `LuaWorld` UserData or an integer.
- **`body_index_from_value`** (fn): Extract a body index from either a `LuaBody` UserData or an integer.

### `lua_api::postfx_api`

Lua API bindings for the `luna.

- **`LuaPostFxEffect`** (struct): Lua UserData wrapper for a single post-processing effect.
- **`register`** (fn): Registers the `luna.postfx.*` API. Panics in debug mode if the same entity is registered twice.

### `lua_api::savegame_api`

Savegame Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.savegame.*` functions into the Lua VM.

### `lua_api::scene_api`

Registers the `luna.

- **`register`** (fn): Registers the `luna.scene` table with scene stack, registry, data store,

### `lua_api::system_api`

System Api implementation for the `lua_api` subsystem.

- **`get_processor_count`** (fn): Returns the number of logical processors available.
- **`get_memory_size`** (fn): Returns total system RAM in MiB using the `sysinfo` crate.
- **`open_url`** (fn): Opens a URL in the default browser/application.  Only `http://`, `https://`, and `mailto:` schemes are allowed.
- **`get_preferred_locales`** (fn): Returns the user's preferred locale strings.
- **`PowerState`** (enum): Power state of the device. Consult the module-level documentation for the broader usage context and preconditions.
- **`get_power_info`** (fn): Returns power/battery information: (state, percent, seconds).  On desktop platforms this returns `(Unknown, None,...
- **`register`** (fn): Registers `luna.system.*` platform query functions into the Lua VM.

### `lua_api::thread_api`

Registers the `luna.

- **`LuaThreadHandle`** (struct): Lua UserData wrapper for a background thread handle.
- **`register`** (fn): Registers all `luna.thread.*` functions into the Lua VM.

### `lua_api::tilemap_api`

Registers the `luna.

- **`ext`** (mod): Ext sub-module.
- **`register`** (fn): Register `luna..*` bindings in the Lua state.

### `lua_api::tilemap_api::ext`

Extended tilemap API registrations (second half of `register`).

- **`register_ext`** (fn): Register extended Lua bindings for this sub-module.

### `lua_api::tilemap_api::helpers`

Helper types and utilities for the tilemap API.

- **`LuaTileSet`** (struct): Lua wrapper around a [`TileSet`]. Consult the module-level documentation for the broader usage context and...
- **`LuaTileMap`** (struct): Lua wrapper around a [`TileMap`]. Consult the module-level documentation for the broader usage context and...
- **`LuaAutoTileSheet`** (struct): Lua wrapper around an [`AutoTileSheet`].
- **`LuaMapBlock`** (struct): Lua wrapper around a [`MapBlock`]. Consult the module-level documentation for the broader usage context and...
- **`LuaMapGroup`** (struct): Lua wrapper around a [`MapGroup`]. Consult the module-level documentation for the broader usage context and...
- **`LuaMapScript`** (struct): Lua wrapper around a [`MapScript`]. Consult the module-level documentation for the broader usage context and...
- **`LuaMapGen`** (struct): Lua wrapper around a [`MapGen`], storing the associated group for generation.
- **`LuaChunkMap`** (struct): Lua wrapper around a [`ChunkMap`]. Consult the module-level documentation for the broader usage context and...
- **`LuaIsoMap`** (struct): Lua wrapper around an [`IsoMap`]. Consult the module-level documentation for the broader usage context and...
- **`rect_to_table`** (fn): Convert a `Rect` into a Lua table `{x, y, w, h}`.
- **`parse_edge`** (fn): Parse an edge tag string into a `TileEdge` enum variant.
- **`parse_script_step`** (fn): Parses a Lua table into a [`ScriptStep`].
- **`step_to_table`** (fn): Converts a [`ScriptStep`] back to a Lua table.

### `lua_api::timer_api`

Timer Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.timer.*` functions into the Lua VM.  Provides frame-timing utilities: delta time, FPS, total time,...

### `lua_api::window_api`

Window Api implementation for the `lua_api` subsystem.

- **`register`** (fn): Registers `luna.window.*` functions into the Lua VM.

## Key Types

### Structs

#### `lua_api::ErrorInfo`

Structured error information for the last engine error.

#### `lua_api::tilemap_api::helpers::LuaAutoTileSheet`

Lua wrapper around an [`AutoTileSheet`].

#### `lua_api::physics_api::helpers::LuaBody`

Lua UserData wrapper for a physics body.

#### `lua_api::audio_api::LuaBus`

Lua UserData wrapper for an audio bus. Consult the module-level documentation for the broader usage context and...

#### `lua_api::graphics_api::helpers::LuaCanvas`

Lua UserData wrapper for an off-screen canvas resource.

#### `lua_api::tilemap_api::helpers::LuaChunkMap`

Lua wrapper around a [`ChunkMap`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::graphics_api::helpers::LuaFont`

Lua UserData wrapper for a loaded font resource.

#### `lua_api::graphics_api::helpers::LuaImage`

Lua UserData wrapper for a loaded texture/image resource.

#### `lua_api::tilemap_api::helpers::LuaIsoMap`

Lua wrapper around an [`IsoMap`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::tilemap_api::helpers::LuaMapBlock`

Lua wrapper around a [`MapBlock`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::tilemap_api::helpers::LuaMapGen`

Lua wrapper around a [`MapGen`], storing the associated group for generation.

#### `lua_api::tilemap_api::helpers::LuaMapGroup`

Lua wrapper around a [`MapGroup`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::tilemap_api::helpers::LuaMapScript`

Lua wrapper around a [`MapScript`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::audio_api::LuaMidiPlayer`

Lua UserData wrapper for the MIDI player.

#### `lua_api::minimap_api::LuaMinimap`

Lua UserData wrapper for a grid-based minimap.

#### `lua_api::graphics_api::helpers::LuaNineSlice`

Lua UserData wrapper for a nine-slice (9-patch) image definition.  Stores the source texture key, border insets, and...

#### `lua_api::particle_api::helpers::LuaParticleSystem`

Lua UserData wrapper for a particle system resource.

#### `lua_api::postfx_api::LuaPostFxEffect`

Lua UserData wrapper for a single post-processing effect.

#### `lua_api::audio_api::LuaSource`

Lua UserData wrapper for an audio source resource.

#### `lua_api::graphics_api::helpers::LuaSpriteBatch`

Lua UserData wrapper for a sprite batch resource.

#### `lua_api::thread_api::LuaThreadHandle`

Lua UserData wrapper for a background thread handle.

#### `lua_api::tilemap_api::helpers::LuaTileMap`

Lua wrapper around a [`TileMap`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::tilemap_api::helpers::LuaTileSet`

Lua wrapper around a [`TileSet`]. Consult the module-level documentation for the broader usage context and...

#### `lua_api::physics_api::helpers::LuaWorld`

Lua UserData wrapper for a physics world.

#### `lua_api::SharedState`

Shared mutable state passed via `Rc<RefCell<SharedState>>` to all Lua API closures and the engine loop.

#### `lua_api::WindowState`

Tracks window state and queues window operations for the event loop.

### Enums

#### `lua_api::FullscreenType`

Fullscreen mode type for window management.

#### `lua_api::system_api::PowerState`

Power state of the device. Consult the module-level documentation for the broader usage context and preconditions.

### Traits

#### `lua_api::lua_types::LunaType`

Standard type identification for Luna2D UserData objects.  Every Luna2D Lua object implements this trait to declare its...

## Public Functions

- **`add_type_methods()`** `lua_types::` — Adds standard `type()` and `typeOf()` methods to a UserData definition.
- **`batch_key_from_value()`** `graphics_api::helpers::` — Extract a `SpriteBatchKey` from either a `LuaSpriteBatch` UserData or a numeric ID.
- **`body_index_from_value()`** `physics_api::helpers::` — Extract a body index from either a `LuaBody` UserData or an integer.
- **`canvas_key_from_value()`** `graphics_api::helpers::` — Extract a `CanvasKey` from either a `LuaCanvas` UserData or a numeric ID.
- **`create_lua_vm()`** — Creates and configures the Lua VM, registers all `luna.*` sub-APIs, and returns the ready `Lua` instance.
- **`emission_shape_to_lua()`** `particle_api::helpers::` — Convert an `EmissionShape` to a Lua table with type and parameter fields.
- **`ensure_particle_exists()`** `particle_api::helpers::` — Return `LuaError` if the particle does not exist in the pool.
- **`font_key_from_value()`** `graphics_api::helpers::` — Extract a `FontKey` from either a `LuaFont` UserData or a numeric ID.
- **`get_memory_size()`** `system_api::` — Returns total system RAM in MiB using the `sysinfo` crate.
- **`get_power_info()`** `system_api::` — Returns power/battery information: (state, percent, seconds).  On desktop platforms this returns `(Unknown, None,...
- **`get_preferred_locales()`** `system_api::` — Returns the user's preferred locale strings.
- **`get_processor_count()`** `system_api::` — Returns the number of logical processors available.
- **`invalid_batch_handle()`** `graphics_api::helpers::` — Returns a `LuaError` for an invalid batch handle.
- **`invalid_canvas_handle()`** `graphics_api::helpers::` — Returns a `LuaError` for an invalid canvas handle.
- **`invalid_font_handle()`** `graphics_api::helpers::` — Returns a `LuaError` for an invalid font handle.
- **`invalid_mesh_handle()`** `graphics_api::helpers::` — Returns a `LuaError` for an invalid mesh handle.
- **`invalid_particle_handle()`** `particle_api::helpers::` — Returns a `LuaError` for an invalid particle handle.
- **`invalid_texture_handle()`** `graphics_api::helpers::` — Returns a `LuaError` for an invalid texture handle.
- **`lua_value_to_f64()`** `particle_api::helpers::` — Helper to extract an f64 from a `LuaValue`.
- **`open_url()`** `system_api::` — Opens a URL in the default browser/application.  Only `http://`, `https://`, and `mailto:` schemes are allowed.
- **`parse_body_type()`** `physics_api::helpers::` — Parses a body type string into a `BodyType` enum value.
- **`parse_color()`** `particle_api::helpers::` — Helper: parse a Lua color table `{r, g, b, a}` into `[f32; 4]`.
- **`parse_edge()`** `tilemap_api::helpers::` — Parse an edge tag string into a `TileEdge` enum variant.
- **`parse_emission_shape()`** `particle_api::helpers::` — Parse an emission shape from a Lua string name and optional parameters table.
- **`parse_script_step()`** `tilemap_api::helpers::` — Parses a Lua table into a [`ScriptStep`].
- **`particle_key_from_value()`** `particle_api::helpers::` — Extract a `ParticleKey` from either a `LuaParticleSystem` UserData or a numeric ID.  Callers validate liveness against...
- **`particle_system()`** `particle_api::helpers::` — Borrow the particle system from shared state.
- **`particle_system_mut()`** `particle_api::helpers::` — Borrow the particle system (mutable) from shared state.
- **`rect_to_table()`** `tilemap_api::helpers::` — Convert a `Rect` into a Lua table `{x, y, w, h}`.
- **`register()`** `ai_api::` — Registers the `luna.ai.*` game AI toolkit API.
- **`register()`** `audio_api::` — Registers all `luna.audio.*` functions into the Lua VM.
- **`register()`** `compute_api::` — Registers the `luna.compute` table with array factory functions.
- **`register()`** `data_api::` — Registers the `luna.data` table on the provided `luna` namespace.
- **`register()`** `dataframe_api::` — Register the `luna.dataframe` namespace.
- **`register()`** `debug_api::` — Registers the `luna.devtools` namespace.
- **`register()`** `debugbridge_api::` — Registers the `luna.debugbridge` namespace.
- **`register()`** `docs_api::` — Registers the `luna.docs` namespace. Panics in debug mode if the same entity is registered twice.
- **`register()`** `entity_api::` — Registers the `luna.entity` table with the `newUniverse` factory function.
- **`register()`** `event_api::` — Registers `luna.event.quit()` and related engine lifecycle functions into the Lua VM.
- **`register()`** `filesystem_api::` — Registers `luna.filesystem.*` functions into the Lua VM.
- **`register()`** `graph_api::` — Register the `luna.graph` API table. Panics in debug mode if the same entity is registered twice.
- **`register()`** `graphics_api::` — Register `luna..*` bindings in the Lua state.
- **`register()`** `image_api::` — Registers the `luna.image` table on the provided `luna` namespace.
- **`register()`** `input_api::` — Registers `luna.keyboard.*` and `luna.mouse.*` query functions into the Lua VM.
- **`register()`** `localization_api::` — Registers `luna.localization.*` functions.
- **`register()`** `log_api::` — Registers the `luna.log.*` namespace into the shared `luna` table.
- **`register()`** `math_api::` — Registers `luna.math.*` helpers (Vec2, distance, random, noise, transforms, etc.) into the Lua VM.
- **`register()`** `minimap_api::` — Register the `luna.minimap` module. Panics in debug mode if the same entity is registered twice.
- **`register()`** `modding_api::` — Registers `luna.modding.*` functions into the Lua VM.
- **`register()`** `particle_api::` — Register `luna..*` bindings in the Lua state.
- **`register()`** `pathfinding_api::` — Register the `luna.pathfinding` namespace.
- **`register()`** `patterns_api::` — Registers `luna.patterns.*` factory functions.
- **`register()`** `physics_api::` — Register `luna..*` bindings in the Lua state.
- **`register()`** `postfx_api::` — Registers the `luna.postfx.*` API. Panics in debug mode if the same entity is registered twice.
- **`register()`** `savegame_api::` — Registers `luna.savegame.*` functions into the Lua VM.
- **`register()`** `scene_api::` — Registers the `luna.scene` table with scene stack, registry, data store,
- **`register()`** `system_api::` — Registers `luna.system.*` platform query functions into the Lua VM.
- **`register()`** `thread_api::` — Registers all `luna.thread.*` functions into the Lua VM.
- **`register()`** `tilemap_api::` — Register `luna..*` bindings in the Lua state.
- **`register()`** `timer_api::` — Registers `luna.timer.*` functions into the Lua VM.  Provides frame-timing utilities: delta time, FPS, total time,...
- **`register()`** `window_api::` — Registers `luna.window.*` functions into the Lua VM.
- **`register_ext()`** `graphics_api::ext::` — Register extended Lua bindings for this sub-module.
- **`register_ext()`** `particle_api::ext::` — Register extended Lua bindings for this sub-module.
- **`register_ext()`** `physics_api::ext::` — Register extended Lua bindings for this sub-module.
- **`register_ext()`** `tilemap_api::ext::` — Register extended Lua bindings for this sub-module.
- **`require_batch_key()`** `graphics_api::helpers::` — Resolve and validate a batch key, returning `LuaError` if missing.
- **`require_canvas_key()`** `graphics_api::helpers::` — Resolve and validate a canvas key, returning `LuaError` if missing.
- **`require_font_key()`** `graphics_api::helpers::` — Resolve and validate a font key, returning `LuaError` if missing.
- **`require_mesh_key()`** `graphics_api::helpers::` — Resolve and validate a mesh key, returning `LuaError` if missing.
- **`require_particle_key()`** `particle_api::helpers::` — Resolve and validate a particle key, returning `LuaError` if missing.
- **`require_texture_key()`** `graphics_api::helpers::` — Resolve and validate a texture key, returning `LuaError` if missing.
- **`step_to_table()`** `tilemap_api::helpers::` — Converts a [`ScriptStep`] back to a Lua table.
- **`texture_key_from_value()`** `graphics_api::helpers::` — Extract a `TextureKey` from either a `LuaImage` UserData or a numeric ID.
- **`world_index_from_value()`** `physics_api::helpers::` — Extract a world index from either a `LuaWorld` UserData or an integer.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 2 |
| `fn` | 87 |
| `mod` | 50 |
| `struct` | 77 |
| `trait` | 1 |
| **Total** | *(see generated docs)* |

