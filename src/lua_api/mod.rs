//! Lua API binding bridge for the Luna2D engine.
//!
//! This is the integration layer that registers all `luna.*` API sub-modules
//! on top of the types defined in `engine`. `SharedState`, `WindowState`,
//! `FullscreenType`, and `ErrorInfo` are defined in `engine::shared_state`
//! and re-exported here for sub-module convenience.
//!
//! The primary entry point is `create_lua_vm()` which constructs a configured
//! LuaJIT VM with every `luna.*` namespace bound.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

pub use crate::engine::{ErrorInfo, FullscreenType, SharedState, WindowState};

/// Registers the `luna.ai.*` game AI toolkit API.
pub mod ai_api;
/// Registers the `luna.audio.*` sound playback API.
pub mod audio_api;
/// Registers the `luna.compute.*` array computation API.
pub mod compute_api;
/// Registers the `luna.data.*` binary data, compression, hashing, and encoding API.
pub mod data_api;
/// Registers the `luna.dataframe.*` tabular data API.
pub mod dataframe_api;
/// Registers the `luna.debug.*` runtime diagnostics and developer tools API.
pub mod debug_api;
/// Registers the `luna.debugbridge.*` TCP debug server API.
pub mod debugbridge_api;
/// Registers the `luna.dialog.*` dialog sequencer API.
pub mod dialog_api;
/// Registers the `luna.docs.*` documentation management API.
pub mod docs_api;
/// Registers the `luna.entity.*` ECS universe API.
pub mod entity_api;
/// Registers the `luna.event.*` engine control API.
pub mod event_api;
/// Registers the `luna.filesystem.*` sandboxed I/O API.
pub mod filesystem_api;
/// Registers the `luna.graph.*` directed-graph and item-flow simulation API.
pub mod graph_api;
/// Registers the `luna.graphics.*` drawing API.
pub mod graphics_api;
/// Registers the `luna.image.*` pixel-level image manipulation API.
pub mod image_api;
/// Registers the `luna.keyboard.*` and `luna.mouse.*` input API.
pub mod input_api;
/// Registers the `luna.localization.*` internationalization API.
pub mod localization_api;
/// Registers the `luna.log.*` structured game-level logging API.
pub mod log_api;
/// Registers the `luna.math.*` vector and math helper API.
pub mod math_api;
/// Registers Phase 25 `luna.math.*` extension types (Vec2, Grid, Noise, etc.).
// math_ext_api removed – merged into math_api
/// Registers the `luna.minimap.*` minimap API.
pub mod minimap_api;
/// Registers the `luna.modding.*` mod management API.
pub mod modding_api;
/// Registers the `luna.particle.*` particle-effects API.
pub mod particle_api;
/// Registers the `luna.pathfinding.*` grid-based pathfinding API.
pub mod pathfinding_api;
/// Registers the `luna.patterns.*` software design patterns API.
pub mod patterns_api;
/// Registers the `luna.physics.*` rigid-body simulation API.
pub mod physics_api;
/// Registers the `luna.postfx.*` post-processing effects API.
pub mod postfx_api;
/// Registers the `luna.savegame.*` save/load system API.
pub mod savegame_api;
/// Registers the `luna.scene.*` scene stack, registry, data store, and depth-sorter API.
pub mod scene_api;
/// Registers Phase 24 `luna.graphics.*` extension types (Light2D, Camera2D, etc.).
pub mod sprite_api;
/// Registers the `luna.steering.*` AI steering behaviours API.
pub mod steering_api;
/// Registers the `luna.sound.*` decoded audio sample manipulation API.
// sound_api removed – functions merged into audio_api
/// Registers the `luna.system.*` platform query API.
pub mod system_api;
/// Registers the `luna.thread.*` multithreading API.
pub mod thread_api;
/// Re-export thread channel from src/thread.
pub use crate::thread::channel as thread_channel;
/// Re-export thread worker from src/thread.
pub use crate::thread::worker as thread_worker;
/// Registers the `luna.battle.*` turn-based battle API.
pub mod battle_api;
/// Registers the `luna.cardgame.*` card game backend API.
pub mod cardgame_api;
/// Registers the `luna.combat.*` combat system API.
pub mod combat_api;
/// Registers the `luna.crafting.*` crafting system API.
pub mod crafting_api;
/// Registers the `luna.economy.*` named resource economy API.
pub mod economy_api;
/// Registers the `luna.inventory.*` inventory system API.
pub mod inventory_api;
/// Item Api sub-module.
// item_api removed – cardgame covers this domain
/// UserData type utilities for Luna2D Lua objects.
pub mod lua_types;
/// Registers the `luna.quest.*` quest log and objective tracking API.
pub mod quest_api;
/// Registers the `luna.stats.*` character stats API.
pub mod stats_api;
/// Registers the `luna.tilemap.*` tile map, tileset, autotile, and procedural generation API.
pub mod tilemap_api;
/// Registers the `luna.timer.*` frame-timing API.
pub mod timer_api;
/// Registers the `luna.window.*` window management API.
pub mod window_api;

/// Creates and configures the Lua VM, registers all `luna.*` sub-APIs, and returns the ready `Lua` instance.
///
/// # Parameters
/// - `state` — Shared engine state passed (via `Rc<RefCell>` clone) to every Lua closure.
///
/// # Returns
/// `LuaResult<Lua>` — A configured Lua VM with `luna.*` as a global, or a Lua error if any sub-API fails to register.
pub fn create_lua_vm(state: Rc<RefCell<SharedState>>) -> LuaResult<Lua> {
    let lua = Lua::new();

    // Create the luna namespace table
    let luna = lua.create_table()?;

    // Register all sub-APIs
    ai_api::register(&lua, &luna)?;
    steering_api::register(&lua, &luna)?;
    graphics_api::register(&lua, &luna, state.clone())?;
    sprite_api::register(&lua, &luna)?;
    input_api::register(&lua, &luna, state.clone())?;
    audio_api::register(&lua, &luna, state.clone())?;
    timer_api::register(&lua, &luna, state.clone())?;
    math_api::register(&lua, &luna)?;
    filesystem_api::register(&lua, &luna, state.clone())?;
    window_api::register(&lua, &luna, state.clone())?;
    physics_api::register(&lua, &luna)?;
    particle_api::register(&lua, &luna, state.clone())?;
    event_api::register(&lua, &luna, state.clone())?;
    system_api::register(&lua, &luna, state.clone())?;
    data_api::register(&lua, &luna)?;
    log_api::register(&lua, &luna)?;
    localization_api::register(&lua, &luna)?;
    image_api::register(&lua, &luna, state.clone())?;
    compute_api::register(&lua, &luna)?;
    dataframe_api::register(&lua, &luna)?;
    debugbridge_api::register(&lua, &luna)?;
    debug_api::register(&lua, &luna)?;
    docs_api::register(&lua, &luna)?;
    graph_api::register(&lua, &luna)?;
    thread_api::register(&lua, &luna)?;
    tilemap_api::register(&lua, &luna)?;
    scene_api::register(&lua, &luna)?;
    pathfinding_api::register(&lua, &luna)?;
    patterns_api::register(&lua, &luna)?;
    minimap_api::register(&lua, &luna)?;
    dialog_api::register(&lua, &luna)?;
    postfx_api::register(&lua, &luna)?;
    entity_api::register(&lua, &luna)?;
    modding_api::register(&lua, &luna, state.clone())?;
    savegame_api::register(&lua, &luna, state.clone())?;
    cardgame_api::register(&lua, &luna)?;
    battle_api::register(&lua, &luna, state.clone())?;
    combat_api::register(&lua, &luna, state.clone())?;
    economy_api::register(&lua, &luna)?;
    stats_api::register(&lua, &luna)?;
    inventory_api::register(&lua, &luna)?;
    quest_api::register(&lua, &luna)?;
    crafting_api::register(&lua, &luna)?;

    /// Luna on this Object.
    /// # Returns
    /// The result.
    lua.globals().set("luna", luna)?;

    Ok(lua)
}
