# lua_api

## General Info

- Module group: `Edge/Integration`
- Source path: `src/lua_api/`
- Lua API path(s): None direct
- Primary Lua namespace: `lurek.*` (registers every sub-namespace)
- Rust test path(s): tests/rust/unit/; tests/rust/ext/
- Lua test path(s): tests/lua/harness.rs; tests/lua/unit/; tests/lua/integration/; tests/lua/security/; tests/lua/stress/; tests/lua/golden/

## Summary

The `lua_api` module is the Lua scripting bridge for Lurek2D. Its only responsibility is binding: collecting all `lurek.*` API sub-modules, creating the `lurek` global table, sandboxing the Lua environment, and registering every sub-API when the VM boots. It sits at the Edge/Integration tier — nothing in the engine may import from `lua_api`.

The primary entry point is `create_lua_vm(state, modules)`, which constructs a fresh LuaJIT VM, creates the `lurek` global table, removes dangerous standard library functions (`load`, `loadfile`, `dofile`, `debug`, `os.execute`, `os.getenv`, `io.open`, `io.popen`) from the sandbox, and then calls each sub-API module's `register(lua, luna, state)` function in sequence. Sub-APIs are gated by `ModulesConfig` flags from `conf.toml`, except for the mandatory group (`event`, `timer`, `math`, `log`) which is always registered.

Every sub-API file under `src/lua_api/` follows the Thin Wrapper Rule: `pub fn register()` + Lua wrapper structs + `impl LuaUserData` with `add_method` / `add_method_mut` calls. Domain modules in `src/<module>/` contain only pure-Rust types. From the engine's perspective, `SharedState` and `WindowState` are re-exported here from `crate::runtime` for sub-module convenience, meaning all binding code imports from `lua_api` rather than from `runtime` directly.

`lua_types.rs` provides the `LunaType` trait and `add_type_methods` helper used by sub-APIs for consistent UserData method registration patterns.

**Scope boundary**: Edge/Integration tier. Imports from all other module groups. Nothing imports from `lua_api`.

## Files

- `ai_api.rs`: Registers the lurek.ai namespace and translates Lua calls into the AI module's Rust types and operations.
- `animation_api.rs`: Registers lurek.animation and exposes animation playback and clip-facing wrappers.
- `audio_api.rs`: Registers lurek.audio and wraps mixer, source, bus, and related audio-facing objects.
- `automation_api.rs`: Registers lurek.automation and bridges scripted input playback into the automation module.
- `camera_api.rs`: Registers lurek.camera and exposes camera creation and manipulation.
- `collision_api.rs`: `lurek.physics` — Lightweight stateless geometric collision helpers.
- `compute_api.rs`: Registers lurek.compute and bridges array or compute-oriented operations into Lua.
- `data_api.rs`: Registers lurek.data and exposes binary, encoding, hashing, and related data utilities.
- `dataframe_api.rs`: Registers lurek.dataframe and wraps tabular data operations for Lua.
- `debugbridge_api.rs`: Registers lurek.debugbridge and exposes the runtime debug TCP bridge to Lua code and tooling.
- `devtools_api.rs`: Registers lurek.devtools and wraps runtime diagnostics helpers such as logging, profiling, frame stats, and watchers.
- `docs_api.rs`: Registers lurek.docs and exposes runtime documentation catalogs, schema validation, and export helpers.
- `ecs_api.rs`: Registers lurek.ecs and bridges ECS world and entity operations.
- `effect_api.rs`: Registers effect-related Lua APIs for post-processing and visual effects.
- `engine_api.rs`: `lurek.runtime` — Runtime engine metadata and introspection.
- `event_api.rs`: Registers lurek.event and exposes event queue and signal-style communication helpers.
- `filesystem_api.rs`: Registers lurek.filesystem and enforces sandboxed file-system operations at the Lua boundary.
- `graph_api.rs`: Registers lurek.graph and bridges graph construction and traversal features.
- `i18n_api.rs`: Registers localization APIs for translated string catalogs and language lookup.
- `image_api.rs`: Registers lurek.image and wraps CPU-side image-data operations.
- `input_api.rs`: Registers keyboard, mouse, gamepad, and touch input namespaces from the engine input state.
- `light_api.rs`: Registers lurek.light and exposes the lighting system to Lua.
- `log_api.rs`: Registers lurek.log and exposes structured logging calls at the scripting layer.
- `lua_types.rs`: Defines shared Lua typing helpers used across many wrappers. It keeps UserData type metadata and common methods consistent across the bridge.
- `math_api.rs`: Registers lurek.math and bridges engine math helpers, interpolation, and utility functions.
- `minimap_api.rs`: Registers lurek.minimap and exposes the minimap feature system.
- `mod.rs`: Creates and configures the Lua VM, opens the allowed standard libraries, removes unsafe globals, and registers the enabled lurek.* namespaces. This is the composition root for scripting.
- `mods_api.rs`: Registers lurek.mods and bridges mod discovery and load-order tooling.
- `network_api.rs`: Registers lurek.network and exposes multiplayer or transport-facing operations.
- `parallax_api.rs`: Registers lurek.parallax and wraps layered scrolling background support.
- `particle_api.rs`: Registers lurek.particle and exposes emitters and particle-system behavior.
- `pathfind_api.rs`: Registers lurek.pathfind and bridges pathfinding data and queries.
- `patterns_api.rs`: Registers lurek.patterns and exposes reusable design-pattern helpers.
- `physics_api.rs`: Registers lurek.physics and wraps physics world, bodies, shapes, joints, and queries.
- `pipeline_api.rs`: Registers lurek.pipeline and exposes DAG workflow orchestration to Lua.
- `procgen_api.rs`: Registers lurek.procgen and bridges procedural-generation utilities.
- `raycaster_api.rs`: Registers lurek.raycaster and exposes retro 2.5D raycasting features.
- `render_api.rs`: Registers the main 2D drawing APIs and resource wrappers used for graphics, canvases, shaders, meshes, and sprite batches.
- `save_api.rs`: Registers lurek.save and exposes save-slot and persistence helpers.
- `scene_api.rs`: Registers lurek.scene and bridges scene stack and transition management.
- `serial_api.rs`: Registers lurek.serial and exposes JSON, TOML, and CSV serialization helpers.
- `spine_api.rs`: Registers lurek.spine and wraps skeletal animation types and operations.
- `sprite_api.rs`: `lurek.sprite` — Sprite-sheet UV layout, named frame groups, atlas parsing, and RPGMaker character-sheet helpers.
- `system_api.rs`: Registers lurek.runtime and exposes OS and platform query helpers.
- `terminal_api.rs`: Registers lurek.terminal and exposes terminal-style UI and grid features.
- `thread_api.rs`: Registers lurek.thread and bridges background worker threads and channels.
- `tilemap_api.rs`: Registers lurek.tilemap and exposes map, layer, and coordinate helpers.
- `timer_api.rs`: Registers lurek.timer and is the gold-standard example for Lua API docstring and registration style.
- `tween_api.rs`: Registers lurek.tween and exposes easing-driven property animation.
- `ui_api.rs`: Registers lurek.ui and wraps retained-mode widget systems.
- `window_api.rs`: Registers lurek.window and exposes window-management and display queries.

## Types

- `LuaAnimation` (`struct`, `animation_api.rs`): Lua-side wrapper around an [`Animation`] controller.
- `LuaAnimStateMachine` (`struct`, `animation_api.rs`): Lua-side wrapper around an [`AnimStateMachine`] FSM controller.
- `LuaBlendLayerSet` (`struct`, `animation_api.rs`): Lua-side wrapper around a [`BlendLayerSet`] blend layer compositor.
- `LuaAnimCurve` (`struct`, `animation_api.rs`): Lua-side wrapper around an [`AnimCurve`].
- `LuaAnimSyncGroup` (`struct`, `animation_api.rs`): Lua-side wrapper around an [`AnimSyncGroup`].
- `LuaSource` (`struct`, `audio_api.rs`): Lua-side wrapper for an audio source resource.
- `LuaBus` (`struct`, `audio_api.rs`): Lua-side wrapper for an audio bus resource.
- `LuaMidiPlayer` (`struct`, `audio_api.rs`): Lua-side wrapper for the MIDI player.
- `LuaSoundPool` (`struct`, `audio_api.rs`): Lua-side wrapper for a polyphonic [`crate::audio::SoundPool`].
- `LuaDecoder` (`struct`, `audio_api.rs`): Lua-side wrapper for a streaming audio decoder.
- `LuaCamera2D` (`struct`, `camera_api.rs`): Lua-side wrapper around a [`Camera2D`] instance.
- `LuaArray` (`struct`, `compute_api.rs`): Lua-side wrapper around [`NdArray`].
- `LuaRingBuffer` (`struct`, `data_api.rs`): Lua-side fixed-capacity ring buffer that holds any Lua value.
- `LuaDataFrame` (`struct`, `dataframe_api.rs`): Lua-side wrapper around a shared [`DataFrame`].
- `LuaDatabase` (`struct`, `dataframe_api.rs`): Lua-side wrapper around a shared [`Database`].
- `LuaReplConsole` (`struct`, `devtools_api.rs`): Lua-side wrapper around a [`ReplConsole`] interactive evaluator.
- `LuaUniverse` (`struct`, `ecs_api.rs`): Lua-side wrapper around a [`Universe`] ECS world.
- `LuaPostFxEffect` (`struct`, `effect_api.rs`): Lua-side wrapper around [`PostFxEffect`].
- `LuaPostFxStack` (`struct`, `effect_api.rs`): Lua-side wrapper around [`PostFxStack`].
- `LuaImageEffect` (`struct`, `effect_api.rs`): Lua-side wrapper around [`ImageEffect`].
- `LuaOverlay` (`struct`, `effect_api.rs`): Lua-side wrapper around [`Overlay`].
- `LuaScreenTransition` (`struct`, `effect_api.rs`): Lua-side wrapper around a [`crate::effect::ScreenTransition`].
- `LuaSignal` (`struct`, `event_api.rs`): Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
- `LuaFileData` (`struct`, `filesystem_api.rs`): Lua-side wrapper around a [`FileData`] buffer.
- `LuaFileHandle` (`struct`, `filesystem_api.rs`): Lua-side wrapper around a [`FileHandle`] with interior mutability.
- `LuaProvinceGrid` (`struct`, `image_api.rs`): Lua-side wrapper around [`ProvinceGrid`].
- `LuaLayeredImage` (`struct`, `image_api.rs`): Lua-side wrapper around [`LayeredImage`].
- `LuaCompressedImageData` (`struct`, `image_api.rs`): Lua-side wrapper around [`CompressedImageData`].
- `LuaPaletteLUT` (`struct`, `image_api.rs`): Lua-side wrapper around [`PaletteLUT`].
- `LuaCursor` (`struct`, `input_api.rs`): Lua-side wrapper around a mouse cursor handle.
- `LuaLight` (`struct`, `light_api.rs`): Lua-side handle to a light resource stored in [`LightWorld`].
- `LuaOccluder` (`struct`, `light_api.rs`): Lua-side handle to an occluder resource stored in [`LightWorld`].
- `LunaType` (`trait`, `lua_types.rs`): Shared trait for LuaUserData wrappers that need consistent runtime type metadata, type hierarchies, and stringification behavior. If wrapper behavior should feel uniform across modules, start here.
- `LuaVec2` (`struct`, `math_api.rs`): Lua-side wrapper around a [`Vec2`] value type.
- `LuaVec3` (`struct`, `math_api.rs`): Lua-side wrapper around a [`Vec3`] value type.
- `LuaCatmullRom` (`struct`, `math_api.rs`): Lua-side wrapper around a [`CatmullRomSpline`].
- `LuaHermite` (`struct`, `math_api.rs`): Lua-side wrapper around a [`HermiteSpline`].
- `LuaRandomGenerator` (`struct`, `math_api.rs`): Lua-side wrapper around a [`RandomGenerator`].
- `LuaTransform` (`struct`, `math_api.rs`): Lua-side wrapper around a [`Transform`].
- `LuaBezierCurve` (`struct`, `math_api.rs`): Lua-side wrapper around a [`BezierCurve`].
- `LuaTween` (`struct`, `math_api.rs`): Lua-side wrapper around a [`Tween`].
- `LuaSpatialHash` (`struct`, `math_api.rs`): Lua-side wrapper around a [`SpatialHash`].
- `LuaNoiseGenerator` (`struct`, `math_api.rs`): Lua-side wrapper around a [`NoiseGenerator`].
- `LuaAabbTree` (`struct`, `math_api.rs`): Lua-side wrapper around an [`AabbTree`].
- `LuaMinimap` (`struct`, `minimap_api.rs`): Lua-side wrapper around a [`Minimap`].
- `LuaMod` (`struct`, `mods_api.rs`): Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
- `LuaModManager` (`struct`, `mods_api.rs`): Lua-side wrapper around [`ModManager`].
- `LuaNetworkHost` (`struct`, `network_api.rs`): Lua-side wrapper around [`NetworkHost`].
- `LuaNetworkRuntime` (`struct`, `network_api.rs`): Lua-side wrapper around [`NetworkRuntime`] for async HTTP/TCP/WebSocket.
- `LuaParallaxLayer` (`struct`, `parallax_api.rs`): Lua-side handle to a single parallax background layer.
- `LuaParallaxSet` (`struct`, `parallax_api.rs`): Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.
- `LuaParticleSystem` (`struct`, `particle_api.rs`): Lua-side handle to a particle system stored in SharedState.
- `LuaTrail` (`struct`, `particle_api.rs`): Lua-side wrapper around a [`Trail`] ribbon effect.
- `LuaNavGrid` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
- `LuaUnitPathfinder` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a [`UnitPathfinder`].
- `LuaFlowField` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a [`FlowField`].
- `LuaPathGrid` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
- `LuaAiFlowField` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a PathGrid-based [`AiFlowField`].
- `LuaHexGrid` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a [`HexGrid`].
- `LuaJpsGrid` (`struct`, `pathfind_api.rs`): Lua-side wrapper around a [`JpsGrid`].
- `LuaWorld` (`struct`, `physics_api.rs`): Lua-side handle wrapping a physics World.
- `LuaZone` (`struct`, `physics_api.rs`): Lua-side handle to a [`PhysicsZone`] living inside a [`World`].
- `LuaTerrain` (`struct`, `physics_api.rs`): Lua-side handle to a destructible [`TerrainMap`].
- `LuaCellular` (`struct`, `physics_api.rs`): Lua-side handle to a falling-sand [`CellularWorld`].
- `LuaBody` (`struct`, `physics_api.rs`): Lua-side handle to a physics body accessed through its world.
- `LuaPhysicsShape` (`struct`, `physics_api.rs`): Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).
- `LuaStep` (`struct`, `pipeline_api.rs`): Lua-side wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
- `LuaPipeline` (`struct`, `pipeline_api.rs`): Lua-side wrapper around a [`Pipeline`] DAG with scheduler and Lua callback registry.
- `LuaDoorManager` (`struct`, `raycaster_api.rs`): Lua-side wrapper around a [`DoorManager`], managing sliding doors in a level.
- `LuaHeightMap` (`struct`, `raycaster_api.rs`): Lua-side wrapper around a [`HeightMap`] for variable floor/ceiling heights.
- `LuaPointLight` (`struct`, `raycaster_api.rs`): Lua-side value wrapper around a raycaster [`PointLight`].
- `LuaRaycaster` (`struct`, `raycaster_api.rs`): Lua-side wrapper around a [`Raycaster2D`] grid.
- `LuaSpriteManager` (`struct`, `raycaster_api.rs`): Lua-side wrapper around a [`SpriteManager`] for batch depth-sorted sprite projection.
- `LuaImageData` (`struct`, `render_api.rs`): Lua-side handle to a loaded texture stored in SharedState.
- `LuaImage` (`struct`, `render_api.rs`): Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
- `LuaNineSlice` (`struct`, `render_api.rs`): Lua-side 9-slice descriptor.
- `LuaFont` (`struct`, `render_api.rs`): Lua-side handle to a loaded font stored in SharedState.
- `LuaCanvas` (`struct`, `render_api.rs`): Lua-side handle to an off-screen render target stored in SharedState.
- `LuaSpriteBatch` (`struct`, `render_api.rs`): Lua-side handle to a sprite batch stored in SharedState.
- `LuaMesh` (`struct`, `render_api.rs`): Lua-side handle to a mesh stored in SharedState.
- `LuaShader` (`struct`, `render_api.rs`): Lua-side handle to a compiled shader stored in SharedState.
- `LuaQuad` (`struct`, `render_api.rs`): Lua-side quad viewport into a texture.
- `LuaShape` (`struct`, `render_api.rs`): Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
- `LuaSaveManager` (`struct`, `save_api.rs`): Lua-side wrapper around [`SaveManager`] with per-module callback storage.
- `LuaDepthSorter` (`struct`, `scene_api.rs`): Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.
- `LuaSkeleton` (`struct`, `spine_api.rs`): Lua-side wrapper around a [`Skeleton`].
- `LuaSkeletonAnimation` (`struct`, `spine_api.rs`): Lua-side wrapper around a [`SkeletonAnimation`] keyframe clip.
- `LuaSpriteSheet` (`struct`, `sprite_api.rs`): Lua-side wrapper around a [`SpriteSheet`] frame-grid calculator.
- `LuaSpriteAtlas` (`struct`, `sprite_api.rs`): Lua-side wrapper around a [`SpriteAtlas`] named-region store.
- `PowerState` (`enum`, `system_api.rs`): Power state of the device.
- `LuaThreadHandle` (`struct`, `thread_api.rs`): Lua-side wrapper around a background [`LuaThread`].
- `LuaThreadPool` (`struct`, `thread_api.rs`): Lua-side wrapper around a [`ThreadPool`].
- `LuaPromise` (`struct`, `thread_api.rs`): Lua-side wrapper around a one-shot [`Promise`].
- `LuaTileSet` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`TileSet`].
- `LuaTileMap` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`TileMap`].
- `LuaAutoTileSheet` (`struct`, `tilemap_api.rs`): Lua-side wrapper around an [`AutoTileSheet`].
- `LuaChunkMap` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`ChunkMap`].
- `LuaLargeMapRenderer` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`LargeMapRenderer`] for chunk-level occlusion culling on large worlds.
- `LuaIsoMap` (`struct`, `tilemap_api.rs`): Lua-side wrapper around an [`IsoMap`].
- `LuaMapBlock` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`MapBlock`].
- `LuaMapGroup` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`MapGroup`].
- `LuaMapScript` (`struct`, `tilemap_api.rs`): Lua-side wrapper around a [`MapScript`] procedural generation script.
- `LuaMapGen` (`struct`, `tilemap_api.rs`): Lua-side wrapper for a map generator (size preset or explicit dimensions).
- `LuaScheduler` (`struct`, `timer_api.rs`): Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
- `LuaTweenState` (`struct`, `tween_api.rs`): Lua-side wrapper around the pure-Rust [`TweenState`] timing core.
- `LuaSpring` (`struct`, `tween_api.rs`): Lua-side spring handle: wraps [`SpringSystem`] and a registry reference to the target table.
- `LuaLineChart` (`struct`, `ui_api.rs`): Lua wrapper for a line chart renderer.
- `LuaBarChart` (`struct`, `ui_api.rs`): Lua wrapper for a grouped bar chart renderer.
- `LuaScatterPlot` (`struct`, `ui_api.rs`): Lua wrapper for a scatter plot renderer.
- `LuaPieChart` (`struct`, `ui_api.rs`): Lua wrapper for a pie chart renderer.
- `LuaAreaChart` (`struct`, `ui_api.rs`): Lua wrapper for a stacked area chart renderer.

## Functions

- `register` (`ai_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`animation_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`audio_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`automation_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `Step::vec_from_lua_table` (`automation_api.rs`): vec_from_lua_table.
- `register` (`camera_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`collision_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`compute_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`data_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`dataframe_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`debugbridge_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`devtools_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`docs_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`ecs_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`effect_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`engine_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`event_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`filesystem_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`graph_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`i18n_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`image_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`input_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`light_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`log_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `add_type_methods` (`lua_types.rs`): Adds the standard `type()`, `typeOf(typeName)`, and `__tostring` methods to any [`LuaUserData`] type that also implements [`LunaType`].
- `register` (`math_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`minimap_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `create_lua_vm` (`mod.rs`): Creates and configures the Lua VM, registers `lurek.*` sub-APIs according to the provided module flags, and returns the ready `Lua` instance.
- `create_test_vm` (`mod.rs`): Creates a test Lua VM with the BDD test framework loaded and all available API modules registered.
- `LuaMod::new` (`mods_api.rs`): Creates a new [`LuaMod`] from a [`ModInfo`].
- `LuaModManager::new` (`mods_api.rs`): Creates a new empty [`LuaModManager`].
- `register` (`mods_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`network_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`parallax_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`particle_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `ParticleConfig::from_lua_opts` (`particle_api.rs`): from_lua_opts.
- `register` (`pathfind_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`patterns_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`physics_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `LuaStep::new` (`pipeline_api.rs`): Creates a new [`LuaStep`] wrapping the given [`PipelineStep`].
- `LuaStep::execute_sync` (`pipeline_api.rs`): Executes this step's callback synchronously, handling retries and status transitions @param crate : parameter @return LuaResult<bool>
- `LuaPipeline::new` (`pipeline_api.rs`): Creates a new [`LuaPipeline`] wrapping the given [`Pipeline`].
- `LuaPipeline::from_parts` (`pipeline_api.rs`): Creates a [`LuaPipeline`] from pre-built pipeline and wrapper maps (used by deserialisers).
- `pipeline_result_to_lua` (`pipeline_api.rs`): Converts a `PipelineResult` to a Lua result table for the `run` return value.
- `cancel_remaining_steps` (`pipeline_api.rs`): Cancels all steps in `order` that are still pending.
- `fire_step_callbacks` (`pipeline_api.rs`): Fires the per-step pipeline callbacks based on the step's terminal status.
- `finalize_pipeline_result` (`pipeline_api.rs`): Finalises a pipeline run: collects the `PipelineResult`, converts it to a Lua table, and fires the `on_complete` callback if registered.
- `register` (`pipeline_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`procgen_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `CellularOpts::from_lua_table` (`procgen_api.rs`): from_lua_table.
- `VoronoiOpts::from_lua_table` (`procgen_api.rs`): from_lua_table @param t : &LuaTable @return LuaResult<Self>
- `register` (`raycaster_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`render_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `LuaSaveManager::new` (`save_api.rs`): Creates a new empty save manager wrapper.
- `register` (`save_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`scene_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`serial_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`spine_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`sprite_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `get_processor_count` (`system_api.rs`): Returns the number of logical processors available.
- `get_memory_size` (`system_api.rs`): Returns total system RAM in MiB using the `sysinfo` crate.
- `open_url` (`system_api.rs`): Opens a URL in the default browser/application.
- `get_preferred_locales` (`system_api.rs`): Returns the user's preferred locale strings.
- `PowerState::as_str` (`system_api.rs`): Returns the string representation used in Lua.
- `get_power_info` (`system_api.rs`): Returns power/battery information: (state, percent, seconds).
- `register` (`system_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`terminal_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`thread_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`tilemap_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`timer_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `LuaSpring::tick_with` (`tween_api.rs`): Advances the spring by `dt` seconds, writes positions to the target table, fires the settle callback if all axes converge, and returns `true` when done.
- `register` (`tween_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`ui_api.rs`): Registers the `lurek.window` API table with the Lua VM.
- `register` (`window_api.rs`): Registers the `lurek.window` API table with the Lua VM.

## Lua API Reference

- Namespace: `lurek.ai`

## References

- `ai`: Imports or references `ai` from `src/ai/`.
- `animation`: Imports or references `animation` from `src/animation/`.
- `audio`: Imports or references `audio` from `src/audio/`.
- `automation`: Imports or references `automation` from `src/automation/`.
- `camera`: Imports or references `camera` from `src/camera/`.
- `compute`: Imports or references `compute` from `src/compute/`.
- `data`: Imports or references `data` from `src/data/`.
- `dataframe`: Imports or references `dataframe` from `src/dataframe/`.
- `debugbridge`: Imports or references `debugbridge` from `src/debugbridge/`.
- `devtools`: Imports or references `devtools` from `src/devtools/`.
- `docs`: Imports or references `docs` from `src/docs/`.
- `ecs`: Imports or references `ecs` from `src/ecs/`.
- `effect`: Imports or references `effect` from `src/effect/`.
- `event`: Imports or references `event` from `src/event/`.
- `filesystem`: Imports or references `filesystem` from `src/filesystem/`.
- `graph`: Imports or references `graph` from `src/graph/`.
- `i18n`: Imports or references `i18n` from `src/i18n/`.
- `image`: Imports or references `image` from `src/image/`.
- `input`: Imports or references `input` from `src/input/`.
- `light`: Imports or references `light` from `src/light/`.
- `log`: Imports or references `log` from `src/log/`.
- `math`: Imports or references `math` from `src/math/`.
- `minimap`: Imports or references `minimap` from `src/minimap/`.
- `mods`: Imports or references `mods` from `src/mods/`.
- `network`: Imports or references `network` from `src/network/`.
- `parallax`: Imports or references `parallax` from `src/parallax/`.
- `particle`: Imports or references `particle` from `src/particle/`.
- `pathfind`: Imports or references `pathfind` from `src/pathfind/`.
- `patterns`: Imports or references `patterns` from `src/patterns/`.
- `physics`: Imports or references `physics` from `src/physics/`.
- `pipeline`: Imports or references `pipeline` from `src/pipeline/`.
- `procgen`: Imports or references `procgen` from `src/procgen/`.
- `raycaster`: Imports or references `raycaster` from `src/raycaster/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `save`: Imports or references `save` from `src/save/`.
- `scene`: Imports or references `scene` from `src/scene/`.
- `serial`: Imports or references `serial` from `src/serial/`.
- `spine`: Imports or references `spine` from `src/spine/`.
- `sprite`: Imports or references `sprite` from `src/sprite/`.
- `terminal`: Imports or references `terminal` from `src/terminal/`.
- `thread`: Imports or references `thread` from `src/thread/`.
- `tilemap`: Imports or references `tilemap` from `src/tilemap/`.
- `timer`: Imports or references `timer` from `src/timer/`.
- `tween`: Imports or references `tween` from `src/tween/`.
- `ui`: Imports or references `ui` from `src/ui/`.
- `window`: Imports or references `window` from `src/window/`.

## Notes

- Keep this module reference synchronized with `src/lua_api/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
