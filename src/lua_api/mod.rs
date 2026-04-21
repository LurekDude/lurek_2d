//! Lua API binding bridge for the Lurek2D engine.
//!
//! This is the integration layer that registers all `lurek.*` API sub-modules
//! on top of the types defined in `engine`. `SharedState`, `WindowState`,
//! `FullscreenType`, and `ErrorInfo` are defined in `engine::shared_state`
//! and re-exported here for sub-module convenience.
//!
//! The primary entry point is [`create_lua_vm`] (see [`register`]) which constructs
//! a configured LuaJIT VM with every `lurek.*` namespace bound.

pub use crate::runtime::{ErrorInfo, FullscreenType, SharedState, WindowState};

/// Registers the `lurek.event.*` event queue and signal API.
pub mod event_api;

/// Registers the `lurek.timer.*` frame-timing API.
pub mod timer_api;

/// Registers the `lurek.image.*` pixel-level image manipulation API.
pub mod image_api;

/// Registers the `lurek.camera.*` Camera2D API.
pub mod camera_api;

/// Registers the `lurek.tween.*` API.
pub mod animation_api;

/// Registers the `lurek.thread.*` background threading API.
pub mod thread_api;
/// Registers the `lurek.tween.*` property animation API.
pub mod tween_api;

/// Registers the `lurek.automation.*` automated input simulation API.
pub mod automation_api;

/// Registers the `lurek.input.keyboard` / `lurek.input.mouse` / `lurek.input.gamepad` / `lurek.input.touch` input API.
pub mod input_api;

/// Registers the `lurek.save.*` slot-based save/load API.
pub mod save_api;

/// Registers the `lurek.data.*` binary data, compression, hashing, and encoding API.
pub mod data_api;

/// Registers the `lurek.ecs.*` lightweight ECS API.
pub mod ecs_api;

/// Registers the `lurek.scene.*` scene stack and depth-sorter API.
pub mod scene_api;

/// Registers the `lurek.compute.*` array computation API.
pub mod compute_api;

/// Registers the `lurek.window.*` window management API.
pub mod window_api;

/// Registers the `lurek.mods.*` mod management API.
pub mod mods_api;

/// Registers the `lurek.filesystem.*` sandboxed file I/O API.
pub mod filesystem_api;

/// Registers the `lurek.serial.*` format serialization API.
pub mod serial_api;

/// Registers the `lurek.raycaster.*` DDA grid raycasting API.
pub mod raycaster_api;

/// Registers the `lurek.spine.*` skeletal animation API.
pub mod spine_api;

/// Registers the `lurek.procgen.*` procedural generation API.
pub mod procgen_api;

/// Registers the `lurek.network.*` UDP networking API.
pub mod network_api;

/// Registers the `lurek.minimap.*` grid-based minimap API.
pub mod minimap_api;

/// Registers the `lurek.pathfind.*` grid-based pathfinding API.
pub mod pathfind_api;

/// Registers the `lurek.dataframe.*` tabular data API.
pub mod dataframe_api;

/// Registers the `lurek.light.*` 2D lighting API.
pub mod light_api;

/// Registers the `lurek.terminal.*` text-mode terminal emulator API.
pub mod terminal_api;

/// Registers the `lurek.pipeline.*` DAG pipeline orchestrator API.
pub mod pipeline_api;

/// Registers the `lurek.graph.*` directed-graph and item-flow simulation API.
pub mod graph_api;

/// Registers the `lurek.globe.*` Geoscape-style province sphere API.
pub mod globe_api;

/// Registers the `lurek.ai.*` game AI toolkit API.
pub mod ai_api;

/// Registers the `lurek.audio.*` audio playback, mixing, and MIDI API.
pub mod audio_api;

/// Registers the `lurek.effect.*` post-processing and screen overlay API.
pub mod effect_api;

/// Registers the `lurek.particle.*` particle system and trail API.
pub mod particle_api;

/// Registers the `lurek.parallax.*` multi-layer parallax background API.
pub mod parallax_api;

/// Registers the `lurek.ui.*` retained-mode widget UI API.
pub mod ui_api;

/// Registers the `lurek.tilemap.*` tile-based map authoring and coordinate helpers API.
pub mod tilemap_api;

/// Registers the `lurek.sprite.*` sprite-sheet UV layout, atlas parsing, and RPGMaker helpers.
pub mod sprite_api;

/// Registers the `lurek.math.*` math utilities API.
pub mod math_api;

/// Registers the `lurek.physics.*` rigid-body physics API.
pub mod physics_api;

/// Registers the `lurek.physics.*` stateless geometric overlap helpers.
pub mod collision_api;

/// Registers the `lurek.render.*` rendering and drawing API.
pub mod render_api;

/// Exposes low-level system queries (processor count, memory size, URL opening, locale, power).
pub mod system_api;

/// Registers the `lurek.devtools.*` developer diagnostics API.
pub mod devtools_api;

/// Registers the `lurek.debugbridge.*` TCP debug server API.
pub mod debugbridge_api;

/// Registers the `lurek.i18n.*` multi-locale string catalog API.
pub mod i18n_api;

/// Registers the `lurek.log.*` structured log level API.
pub mod log_api;

/// Registers the `lurek.runtime.*` runtime engine metadata API.
pub mod engine_api;

/// Registers the `lurek.docs.*` documentation management API.
pub mod docs_api;

/// Registers the `lurek.patterns.*` game programming patterns API.
pub mod patterns_api;

/// Shared `LunaType` trait and `add_type_methods` helper for typed UserData objects.
pub mod lua_types;

/// Lua VM factory: [`create_lua_vm`] and [`create_test_vm`].
pub mod register;
pub use register::{create_lua_vm, create_test_vm};
