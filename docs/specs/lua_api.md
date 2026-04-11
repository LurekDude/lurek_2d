# `lua_api` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | Indirect / none |
| **Source** | `src/lua_api/` |
| **Rust Tests** | tests/rust/unit/; tests/rust/ext/ |
| **Lua Tests** | tests/lua/harness.rs; tests/lua/unit/; tests/lua/integration/; tests/lua/security/; tests/lua/stress/; tests/lua/golden/ |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The lua_api module is the one-way bridge from Rust engine systems into the public lurek.* scripting surface. It exists so game code can use a stable, sandboxed Lua API while the underlying Rust modules remain free to evolve internally behind thin binding layers and typed resource handles.

The module owns Lua VM creation, standard-library allowlisting, dangerous-global removal, module-by-module registration, LuaUserData wrappers, and the small translation layer that turns Lua values into Rust calls and Rust results back into Lua values. The design rule here is thin wrappers: public binding code lives in lua_api, while domain logic stays in the engine modules below it.

This module does not own renderer logic, physics logic, file-system semantics, AI behavior, or any other domain behavior itself. If a change starts to look like business logic instead of registration, validation, conversion, or wrapper glue, it probably belongs in another module and should only be exposed here.

**Scope boundary**: This module currently depends on `ai`, `animation`, `audio`, `automation`, `camera`, `compute`, `data`, `dataframe`, and other adjacent modules. It stays within the Edge/Integration responsibility boundary defined in the architecture docs.

---

## Architecture

```
No direct Lua namespace — consumed through app/runtime integration or other bindings
    |
    v
src/lua_api/mod.rs
    |- ai_api.rs - ai_api
    |- animation_api.rs - animation_api
    |- audio_api.rs - audio_api
    |- automation_api.rs - automation_api
    |- camera_api.rs - camera_api
    |- compute_api.rs - compute_api
    |- data_api.rs - data_api
    |- dataframe_api.rs - dataframe_api
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `ai_api.rs` | Registers the lurek.ai namespace and translates Lua calls into the AI module's Rust types and operations. |
| `animation_api.rs` | Registers lurek.animation and exposes animation playback and clip-facing wrappers. |
| `audio_api.rs` | Registers lurek.audio and wraps mixer, source, bus, and related audio-facing objects. |
| `automation_api.rs` | Registers lurek.simulator and bridges scripted input playback into the automation module. |
| `camera_api.rs` | Registers lurek.camera and exposes camera creation and manipulation. |
| `compute_api.rs` | Registers lurek.compute and bridges array or compute-oriented operations into Lua. |
| `data_api.rs` | Registers lurek.data and exposes binary, encoding, hashing, and related data utilities. |
| `dataframe_api.rs` | Registers lurek.dataframe and wraps tabular data operations for Lua. |
| `debugbridge_api.rs` | Registers lurek.debugbridge and exposes the runtime debug TCP bridge to Lua code and tooling. |
| `devtools_api.rs` | Registers lurek.devtools and wraps runtime diagnostics helpers such as logging, profiling, frame stats, and watchers. |
| `docs_api.rs` | Registers lurek.docs and exposes runtime documentation catalogs, schema validation, and export helpers. |
| `ecs_api.rs` | Registers lurek.entity and bridges ECS world and entity operations. |
| `effect_api.rs` | Registers effect-related Lua APIs for post-processing and visual effects. |
| `event_api.rs` | Registers lurek.signal and exposes event queue and signal-style communication helpers. |
| `filesystem_api.rs` | Registers lurek.fs and enforces sandboxed file-system operations at the Lua boundary. |
| `graph_api.rs` | Registers lurek.graph and bridges graph construction and traversal features. |
| `i18n_api.rs` | Registers localization APIs for translated string catalogs and language lookup. |
| `image_api.rs` | Registers lurek.img and wraps CPU-side image-data operations. |
| `input_api.rs` | Registers keyboard, mouse, gamepad, and touch input namespaces from the engine input state. |
| `light_api.rs` | Registers lurek.light and exposes the lighting system to Lua. |
| `log_api.rs` | Registers lurek.log and exposes structured logging calls at the scripting layer. |
| `lua_types.rs` | Defines shared Lua typing helpers used across many wrappers. It keeps UserData type metadata and common methods consistent across the bridge. |
| `math_api.rs` | Registers lurek.math and bridges engine math helpers, interpolation, and utility functions. |
| `minimap_api.rs` | Registers lurek.minimap and exposes the minimap feature system. |
| `mod.rs` | Creates and configures the Lua VM, opens the allowed standard libraries, removes unsafe globals, and registers the enabled lurek.* namespaces. This is the composition root for scripting. |
| `mods_api.rs` | Registers lurek.modding and bridges mod discovery and load-order tooling. |
| `network_api.rs` | Registers lurek.network and exposes multiplayer or transport-facing operations. |
| `parallax_api.rs` | Registers lurek.parallax and wraps layered scrolling background support. |
| `particle_api.rs` | Registers lurek.particles and exposes emitters and particle-system behavior. |
| `pathfind_api.rs` | Registers lurek.pathfinding and bridges pathfinding data and queries. |
| `patterns_api.rs` | Registers lurek.patterns and exposes reusable design-pattern helpers. |
| `physics_api.rs` | Registers lurek.physics and wraps physics world, bodies, shapes, joints, and queries. |
| `pipeline_api.rs` | Registers lurek.pipeline and exposes DAG workflow orchestration to Lua. |
| `procgen_api.rs` | Registers lurek.procgen and bridges procedural-generation utilities. |
| `raycaster_api.rs` | Registers lurek.raycaster and exposes retro 2.5D raycasting features. |
| `render_api.rs` | Registers the main 2D drawing APIs and resource wrappers used for graphics, canvases, shaders, meshes, and sprite batches. |
| `save_api.rs` | Registers lurek.savegame and exposes save-slot and persistence helpers. |
| `scene_api.rs` | Registers lurek.scene and bridges scene stack and transition management. |
| `serial_api.rs` | Registers lurek.codec and exposes JSON, TOML, and CSV serialization helpers. |
| `spine_api.rs` | Registers lurek.spine and wraps skeletal animation types and operations. |
| `system_api.rs` | Registers lurek.platform and exposes OS and platform query helpers. |
| `terminal_api.rs` | Registers lurek.terminal and exposes terminal-style UI and grid features. |
| `thread_api.rs` | Registers lurek.thread and bridges background worker threads and channels. |
| `tilemap_api.rs` | Registers lurek.tilemap and exposes map, layer, and coordinate helpers. |
| `timer_api.rs` | Registers lurek.time and is the gold-standard example for Lua API docstring and registration style. |
| `tween_api.rs` | Registers lurek.tween and exposes easing-driven property animation. |
| `ui_api.rs` | Registers lurek.ui and wraps retained-mode widget systems. |
| `window_api.rs` | Registers lurek.window and exposes window-management and display queries. |

---

## Submodules

### `lua_api::ai_api`

Registers the lurek.ai namespace and translates Lua calls into the AI module's Rust types and operations.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::animation_api`

Registers lurek.animation and exposes animation playback and clip-facing wrappers.

- **`LuaAnimation`** (struct): Lua-side wrapper around an [`Animation`] controller.

### `lua_api::audio_api`

Registers lurek.audio and wraps mixer, source, bus, and related audio-facing objects.

- **`LuaSource`** (struct): Lua-side wrapper for an audio source resource.
- **`LuaBus`** (struct): Lua-side wrapper for an audio bus resource.
- **`LuaMidiPlayer`** (struct): Lua-side wrapper for the MIDI player.
- **`LuaDecoder`** (struct): Lua-side wrapper for a streaming audio decoder.

### `lua_api::automation_api`

Registers lurek.simulator and bridges scripted input playback into the automation module.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::camera_api`

Registers lurek.camera and exposes camera creation and manipulation.

- **`LuaCamera2D`** (struct): Lua-side wrapper around a [`Camera2D`] instance.

### `lua_api::compute_api`

Registers lurek.compute and bridges array or compute-oriented operations into Lua.

- **`LuaArray`** (struct): Lua-side wrapper around [`NdArray`].

### `lua_api::data_api`

Registers lurek.data and exposes binary, encoding, hashing, and related data utilities.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::dataframe_api`

Registers lurek.dataframe and wraps tabular data operations for Lua.

- **`LuaDataFrame`** (struct): Lua-side wrapper around a shared [`DataFrame`].
- **`LuaDatabase`** (struct): Lua-side wrapper around a shared [`Database`].

### `lua_api::debugbridge_api`

Registers lurek.debugbridge and exposes the runtime debug TCP bridge to Lua code and tooling.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::devtools_api`

Registers lurek.devtools and wraps runtime diagnostics helpers such as logging, profiling, frame stats, and watchers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::docs_api`

Registers lurek.docs and exposes runtime documentation catalogs, schema validation, and export helpers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::ecs_api`

Registers lurek.entity and bridges ECS world and entity operations.

- **`LuaUniverse`** (struct): Lua-side wrapper around a [`Universe`] ECS world.

### `lua_api::effect_api`

Registers effect-related Lua APIs for post-processing and visual effects.

- **`LuaPostFxEffect`** (struct): Lua-side wrapper around [`PostFxEffect`].
- **`LuaPostFxStack`** (struct): Lua-side wrapper around [`PostFxStack`].
- **`LuaImageEffect`** (struct): Lua-side wrapper around [`ImageEffect`].
- **`LuaOverlay`** (struct): Lua-side wrapper around [`Overlay`].

### `lua_api::event_api`

Registers lurek.signal and exposes event queue and signal-style communication helpers.

- **`LuaSignal`** (struct): Lua-side wrapper around a [`Signal`] with registry-stored callbacks.

### `lua_api::filesystem_api`

Registers lurek.fs and enforces sandboxed file-system operations at the Lua boundary.

- **`LuaFileData`** (struct): Lua-side wrapper around a [`FileData`] buffer.
- **`LuaFileHandle`** (struct): Lua-side wrapper around a [`FileHandle`] with interior mutability.

### `lua_api::graph_api`

Registers lurek.graph and bridges graph construction and traversal features.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::i18n_api`

Registers localization APIs for translated string catalogs and language lookup.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::image_api`

Registers lurek.img and wraps CPU-side image-data operations.

- **`LuaLayeredImage`** (struct): Lua-side wrapper around [`LayeredImage`].
- **`LuaCompressedImageData`** (struct): Lua-side wrapper around [`CompressedImageData`].

### `lua_api::input_api`

Registers keyboard, mouse, gamepad, and touch input namespaces from the engine input state.

- **`LuaCursor`** (struct): Lua-side wrapper around a mouse cursor handle.

### `lua_api::light_api`

Registers lurek.light and exposes the lighting system to Lua.

- **`LuaLight`** (struct): Lua-side handle to a light resource stored in [`LightWorld`].
- **`LuaOccluder`** (struct): Lua-side handle to an occluder resource stored in [`LightWorld`].

### `lua_api::log_api`

Registers lurek.log and exposes structured logging calls at the scripting layer.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::lua_types`

Defines shared Lua typing helpers used across many wrappers. It keeps UserData type metadata and common methods consistent across the bridge.

- **`LunaType`** (trait): Marker trait that every Lua UserData type in Lurek2D must implement.

### `lua_api::math_api`

Registers lurek.math and bridges engine math helpers, interpolation, and utility functions.

- **`LuaRandomGenerator`** (struct): Lua-side wrapper around a [`RandomGenerator`].
- **`LuaTransform`** (struct): Lua-side wrapper around a [`Transform`].
- **`LuaBezierCurve`** (struct): Lua-side wrapper around a [`BezierCurve`].
- **`LuaTween`** (struct): Lua-side wrapper around a [`Tween`].
- **`LuaSpatialHash`** (struct): Lua-side wrapper around a [`SpatialHash`].
- **`LuaNoiseGenerator`** (struct): Lua-side wrapper around a [`NoiseGenerator`].

### `lua_api::minimap_api`

Registers lurek.minimap and exposes the minimap feature system.

- **`LuaMinimap`** (struct): Lua-side wrapper around a [`Minimap`].

### `lua_api::mods_api`

Registers lurek.modding and bridges mod discovery and load-order tooling.

- **`LuaMod`** (struct): Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
- **`LuaModManager`** (struct): Lua-side wrapper around [`ModManager`].

### `lua_api::network_api`

Registers lurek.network and exposes multiplayer or transport-facing operations.

- **`LuaNetworkHost`** (struct): Lua-side wrapper around [`NetworkHost`].

### `lua_api::parallax_api`

Registers lurek.parallax and wraps layered scrolling background support.

- **`LuaParallaxLayer`** (struct): Lua-side handle to a single parallax background layer.
- **`LuaParallaxSet`** (struct): Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.

### `lua_api::particle_api`

Registers lurek.particles and exposes emitters and particle-system behavior.

- **`LuaParticleSystem`** (struct): Lua-side handle to a particle system stored in SharedState.
- **`LuaTrail`** (struct): Lua-side wrapper around a [`Trail`] ribbon effect.

### `lua_api::pathfind_api`

Registers lurek.pathfinding and bridges pathfinding data and queries.

- **`LuaNavGrid`** (struct): Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
- **`LuaUnitPathfinder`** (struct): Lua-side wrapper around a [`UnitPathfinder`].
- **`LuaFlowField`** (struct): Lua-side wrapper around a [`FlowField`].
- **`LuaPathGrid`** (struct): Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
- **`LuaAiFlowField`** (struct): Lua-side wrapper around a PathGrid-based [`AiFlowField`].

### `lua_api::patterns_api`

Registers lurek.patterns and exposes reusable design-pattern helpers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::physics_api`

Registers lurek.physics and wraps physics world, bodies, shapes, joints, and queries.

- **`LuaWorld`** (struct): Lua-side handle wrapping a physics World.
- **`LuaBody`** (struct): Lua-side handle to a physics body accessed through its world.
- **`LuaPhysicsShape`** (struct): Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).

### `lua_api::pipeline_api`

Registers lurek.pipeline and exposes DAG workflow orchestration to Lua.

- **`LuaStep`** (struct): Lua-side wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
- **`LuaPipeline`** (struct): Lua-side wrapper around a [`Pipeline`] DAG with scheduler and Lua callback registry.

### `lua_api::procgen_api`

Registers lurek.procgen and bridges procedural-generation utilities.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::raycaster_api`

Registers lurek.raycaster and exposes retro 2.5D raycasting features.

- **`LuaRaycaster`** (struct): Lua-side wrapper around a [`Raycaster2D`] grid.

### `lua_api::render_api`

Registers the main 2D drawing APIs and resource wrappers used for graphics, canvases, shaders, meshes, and sprite batches.

- **`LuaImageData`** (struct): Lua-side handle to a loaded texture stored in SharedState.
- **`LuaImage`** (struct): Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
- **`LuaNineSlice`** (struct): Lua-side 9-slice descriptor.
- **`LuaFont`** (struct): Lua-side handle to a loaded font stored in SharedState.
- **`LuaCanvas`** (struct): Lua-side handle to an off-screen render target stored in SharedState.
- **`LuaSpriteBatch`** (struct): Lua-side handle to a sprite batch stored in SharedState.
- **`LuaMesh`** (struct): Lua-side handle to a mesh stored in SharedState.
- **`LuaShader`** (struct): Lua-side handle to a compiled shader stored in SharedState.
- **`LuaQuad`** (struct): Lua-side quad viewport into a texture.
- **`LuaShape`** (struct): Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].

### `lua_api::save_api`

Registers lurek.savegame and exposes save-slot and persistence helpers.

- **`LuaSaveManager`** (struct): Lua-side wrapper around [`SaveManager`] with per-module callback storage.

### `lua_api::scene_api`

Registers lurek.scene and bridges scene stack and transition management.

- **`LuaDepthSorter`** (struct): Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.

### `lua_api::serial_api`

Registers lurek.codec and exposes JSON, TOML, and CSV serialization helpers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::spine_api`

Registers lurek.spine and wraps skeletal animation types and operations.

- **`LuaSkeleton`** (struct): Lua-side wrapper around a [`Skeleton`].

### `lua_api::system_api`

Registers lurek.platform and exposes OS and platform query helpers.

- **`PowerState`** (enum): Power state of the device.

### `lua_api::terminal_api`

Registers lurek.terminal and exposes terminal-style UI and grid features.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::thread_api`

Registers lurek.thread and bridges background worker threads and channels.

- **`LuaThreadHandle`** (struct): Lua-side wrapper around a background [`LuaThread`].

### `lua_api::tilemap_api`

Registers lurek.tilemap and exposes map, layer, and coordinate helpers.

- **`LuaTileSet`** (struct): Lua-side wrapper around a [`TileSet`].
- **`LuaTileMap`** (struct): Lua-side wrapper around a [`TileMap`].
- **`LuaAutoTileSheet`** (struct): Lua-side wrapper around an [`AutoTileSheet`].
- **`LuaChunkMap`** (struct): Lua-side wrapper around a [`ChunkMap`].
- **`LuaIsoMap`** (struct): Lua-side wrapper around an [`IsoMap`].
- **`LuaMapBlock`** (struct): Lua-side wrapper around a [`MapBlock`].
- **`LuaMapGroup`** (struct): Lua-side wrapper around a [`MapGroup`].
- **`LuaMapScript`** (struct): Lua-side wrapper around a [`MapScript`] procedural generation script.
- **`LuaMapGen`** (struct): Lua-side wrapper for a map generator (size preset or explicit dimensions).

### `lua_api::timer_api`

Registers lurek.time and is the gold-standard example for Lua API docstring and registration style.

- **`LuaScheduler`** (struct): Lua-side wrapper around a [`Scheduler`] with per-event callback storage.

### `lua_api::tween_api`

Registers lurek.tween and exposes easing-driven property animation.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::ui_api`

Registers lurek.ui and wraps retained-mode widget systems.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `lua_api::window_api`

Registers lurek.window and exposes window-management and display queries.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `LunaType`

Shared trait for LuaUserData wrappers that need consistent runtime type metadata, type hierarchies, and stringification behavior.

#### `create_lua_vm`

The module's main composition function that opens the sandboxed VM and registers enabled namespaces.

#### `add_type_methods`

Shared helper that adds common type(), typeOf(), and tostring-style behavior to UserData.

#### `LuaImage, LuaSource, LuaBus, LuaCamera2D, LuaUniverse, LuaWorld, and similar wrapper objects`

Representative resource-handle wrappers that carry keys and light metadata into Lua while the actual engine-owned resources remain in SharedState.

#### `The register(lua, luna, state) convention used by every *_api.rs file`

This is the stable integration contract for adding or auditing a Lua namespace.

---

## Lua API

This module does not expose a dedicated direct Lua namespace. It is consumed indirectly through higher-level engine callbacks, shared state, or other `lurek.*` surfaces.

---

## Lua Examples

```lua
-- This module has no dedicated direct Lua namespace.
-- It is used indirectly through other engine systems.
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 71 |
| `enum` | 1 |
| `fn` (Lua API) | 0 |
| **Total** | **72** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `ai` | Imports or references `ai` from `src/ai/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `animation` | Imports or references `animation` from `src/animation/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `audio` | Imports or references `audio` from `src/audio/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `automation` | Imports or references `automation` from `src/automation/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `camera` | Imports or references `camera` from `src/camera/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `compute` | Imports or references `compute` from `src/compute/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `data` | Imports or references `data` from `src/data/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `dataframe` | Imports or references `dataframe` from `src/dataframe/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `debugbridge` | Imports or references `debugbridge` from `src/debugbridge/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `devtools` | Imports or references `devtools` from `src/devtools/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `docs` | Imports or references `docs` from `src/docs/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `ecs` | Imports or references `ecs` from `src/ecs/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `effect` | Imports or references `effect` from `src/effect/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `event` | Imports or references `event` from `src/event/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `filesystem` | Imports or references `filesystem` from `src/filesystem/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `graph` | Imports or references `graph` from `src/graph/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `i18n` | Imports or references `i18n` from `src/i18n/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `input` | Imports or references `input` from `src/input/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `light` | Imports or references `light` from `src/light/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `log` | Imports or references `log` from `src/log/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `minimap` | Imports or references `minimap` from `src/minimap/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `mods` | Imports or references `mods` from `src/mods/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `network` | Imports or references `network` from `src/network/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `parallax` | Imports or references `parallax` from `src/parallax/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `particle` | Imports or references `particle` from `src/particle/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `pathfind` | Imports or references `pathfind` from `src/pathfind/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `patterns` | Imports or references `patterns` from `src/patterns/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `physics` | Imports or references `physics` from `src/physics/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `pipeline` | Imports or references `pipeline` from `src/pipeline/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `procgen` | Imports or references `procgen` from `src/procgen/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `raycaster` | Imports or references `raycaster` from `src/raycaster/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `save` | Imports or references `save` from `src/save/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `scene` | Imports or references `scene` from `src/scene/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `serial` | Imports or references `serial` from `src/serial/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `spine` | Imports or references `spine` from `src/spine/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `sprite` | Imports or references `sprite` from `src/sprite/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `terminal` | Imports or references `terminal` from `src/terminal/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `thread` | Imports or references `thread` from `src/thread/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `tilemap` | Imports or references `tilemap` from `src/tilemap/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `timer` | Imports or references `timer` from `src/timer/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `tween` | Imports or references `tween` from `src/tween/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `ui` | Imports or references `ui` from `src/ui/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `window` | Imports or references `window` from `src/window/`. | Cross-group dependency from Edge/Integration to Platform Services. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/lua_api/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
- **Lua surface**: This module has no dedicated direct `lurek.*` namespace and is typically consumed through higher integration layers.
