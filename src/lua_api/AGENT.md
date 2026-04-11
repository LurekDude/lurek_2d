# lua_api

## Module Info
- Module name: lua_api
- Module group: Edge/Integration
- Spec path: docs/specs/lua_api.md
- Lua API path(s): src/lua_api/mod.rs; src/lua_api/*.rs
- Rust test path(s): tests/rust/unit/; tests/rust/ext/
- Lua test path(s): tests/lua/harness.rs; tests/lua/unit/; tests/lua/integration/; tests/lua/security/; tests/lua/stress/; tests/lua/golden/

## Module Purpose

The lua_api module is the one-way bridge from Rust engine systems into the public lurek.* scripting surface. It exists so game code can use a stable, sandboxed Lua API while the underlying Rust modules remain free to evolve internally behind thin binding layers and typed resource handles.

The module owns Lua VM creation, standard-library allowlisting, dangerous-global removal, module-by-module registration, LuaUserData wrappers, and the small translation layer that turns Lua values into Rust calls and Rust results back into Lua values. The design rule here is thin wrappers: public binding code lives in lua_api, while domain logic stays in the engine modules below it.

This module does not own renderer logic, physics logic, file-system semantics, AI behavior, or any other domain behavior itself. If a change starts to look like business logic instead of registration, validation, conversion, or wrapper glue, it probably belongs in another module and should only be exposed here.

## Files
- mod.rs: Creates and configures the Lua VM, opens the allowed standard libraries, removes unsafe globals, and registers the enabled lurek.* namespaces. This is the composition root for scripting.
- lua_types.rs: Defines shared Lua typing helpers used across many wrappers. It keeps UserData type metadata and common methods consistent across the bridge.
- ai_api.rs: Registers the lurek.ai namespace and translates Lua calls into the AI module's Rust types and operations.
- animation_api.rs: Registers lurek.animation and exposes animation playback and clip-facing wrappers.
- audio_api.rs: Registers lurek.audio and wraps mixer, source, bus, and related audio-facing objects.
- automation_api.rs: Registers lurek.simulator and bridges scripted input playback into the automation module.
- camera_api.rs: Registers lurek.camera and exposes camera creation and manipulation.
- compute_api.rs: Registers lurek.compute and bridges array or compute-oriented operations into Lua.
- data_api.rs: Registers lurek.data and exposes binary, encoding, hashing, and related data utilities.
- dataframe_api.rs: Registers lurek.dataframe and wraps tabular data operations for Lua.
- debugbridge_api.rs: Registers lurek.debugbridge and exposes the runtime debug TCP bridge to Lua code and tooling.
- devtools_api.rs: Registers lurek.devtools and wraps runtime diagnostics helpers such as logging, profiling, frame stats, and watchers.
- docs_api.rs: Registers lurek.docs and exposes runtime documentation catalogs, schema validation, and export helpers.
- ecs_api.rs: Registers lurek.entity and bridges ECS world and entity operations.
- effect_api.rs: Registers effect-related Lua APIs for post-processing and visual effects.
- event_api.rs: Registers lurek.signal and exposes event queue and signal-style communication helpers.
- filesystem_api.rs: Registers lurek.fs and enforces sandboxed file-system operations at the Lua boundary.
- graph_api.rs: Registers lurek.graph and bridges graph construction and traversal features.
- i18n_api.rs: Registers localization APIs for translated string catalogs and language lookup.
- image_api.rs: Registers lurek.img and wraps CPU-side image-data operations.
- input_api.rs: Registers keyboard, mouse, gamepad, and touch input namespaces from the engine input state.
- light_api.rs: Registers lurek.light and exposes the lighting system to Lua.
- log_api.rs: Registers lurek.log and exposes structured logging calls at the scripting layer.
- math_api.rs: Registers lurek.math and bridges engine math helpers, interpolation, and utility functions.
- minimap_api.rs: Registers lurek.minimap and exposes the minimap feature system.
- mods_api.rs: Registers lurek.modding and bridges mod discovery and load-order tooling.
- network_api.rs: Registers lurek.network and exposes multiplayer or transport-facing operations.
- parallax_api.rs: Registers lurek.parallax and wraps layered scrolling background support.
- particle_api.rs: Registers lurek.particles and exposes emitters and particle-system behavior.
- pathfind_api.rs: Registers lurek.pathfinding and bridges pathfinding data and queries.
- patterns_api.rs: Registers lurek.patterns and exposes reusable design-pattern helpers.
- physics_api.rs: Registers lurek.physics and wraps physics world, bodies, shapes, joints, and queries.
- pipeline_api.rs: Registers lurek.pipeline and exposes DAG workflow orchestration to Lua.
- procgen_api.rs: Registers lurek.procgen and bridges procedural-generation utilities.
- raycaster_api.rs: Registers lurek.raycaster and exposes retro 2.5D raycasting features.
- render_api.rs: Registers the main 2D drawing APIs and resource wrappers used for graphics, canvases, shaders, meshes, and sprite batches.
- save_api.rs: Registers lurek.savegame and exposes save-slot and persistence helpers.
- scene_api.rs: Registers lurek.scene and bridges scene stack and transition management.
- serial_api.rs: Registers lurek.codec and exposes JSON, TOML, and CSV serialization helpers.
- spine_api.rs: Registers lurek.spine and wraps skeletal animation types and operations.
- system_api.rs: Registers lurek.platform and exposes OS and platform query helpers.
- terminal_api.rs: Registers lurek.terminal and exposes terminal-style UI and grid features.
- thread_api.rs: Registers lurek.thread and bridges background worker threads and channels.
- tilemap_api.rs: Registers lurek.tilemap and exposes map, layer, and coordinate helpers.
- timer_api.rs: Registers lurek.time and is the gold-standard example for Lua API docstring and registration style.
- tween_api.rs: Registers lurek.tween and exposes easing-driven property animation.
- ui_api.rs: Registers lurek.ui and wraps retained-mode widget systems.
- window_api.rs: Registers lurek.window and exposes window-management and display queries.

## Key Types
- LunaType: Shared trait for LuaUserData wrappers that need consistent runtime type metadata, type hierarchies, and stringification behavior. If wrapper behavior should feel uniform across modules, start here.
- create_lua_vm: The module's main composition function that opens the sandboxed VM and registers enabled namespaces. It is the first stop when a namespace is missing, a global is exposed incorrectly, or the VM setup order matters.
- add_type_methods: Shared helper that adds common type(), typeOf(), and tostring-style behavior to UserData. It keeps wrapper ergonomics consistent across dozens of API files.
- LuaImage, LuaSource, LuaBus, LuaCamera2D, LuaUniverse, LuaWorld, and similar wrapper objects: Representative resource-handle wrappers that carry keys and light metadata into Lua while the actual engine-owned resources remain in SharedState. This pattern is the module's most important architectural rule.
- The register(lua, luna, state) convention used by every *_api.rs file: This is the stable integration contract for adding or auditing a Lua namespace. Changes to registration shape, error conversion, or shared-state borrowing patterns should be evaluated against this contract first.