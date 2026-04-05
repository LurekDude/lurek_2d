//! Luna2D Lua API registration layer.
//!
//! This module is the bridge between the Rust engine modules and the LuaJIT VM.
//! [`create_lua_vm`] creates a sandboxed VM and registers all enabled `luna.*`
//! API sub-modules based on the active [`ModulesConfig`].
//!
//! # Module layout
//!
//! Each sub-module exposes exactly one function:
//! ```text
//! pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>
//! ```
//! That function populates the `luna.<name>` table in the Lua global namespace.
//!
//! # Conditional registration
//!
//! Modules gated on a [`ModulesConfig`] flag are only registered when the flag is
//! `true`.  Always-on modules (math, event, dataframe, serial, light) are registered
//! unconditionally.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::config::ModulesConfig;

// Re-export SharedState so engine callers (app_winit.rs) can import it from lua_api.
pub use crate::engine::SharedState;

// ── API sub-modules ──────────────────────────────────────────────────────────

/// AI FSM, behaviour tree, and steering API.
pub mod ai_api;
/// Sprite animation and frame-clip API.
pub mod animation_api;
/// Audio playback and mixer API.
pub mod audio_api;
/// Automated input and replay API.
pub mod automation_api;
/// Camera and viewport API.
pub mod camera_api;
/// Numerical array and CPU compute API.
pub mod compute_api;
/// Binary data, compression, hashing, and encoding API.
pub mod data_api;
/// Column-major tabular DataFrame API.
pub mod dataframe_api;
/// Lightweight ECS entity API.
pub mod entity_api;
/// Event queue API.
pub mod event_api;
/// Sandboxed game filesystem API.
pub mod filesystem_api;
/// Directed graph and flow simulation API.
pub mod graph_api;
/// GPU rendering pipeline API.
pub mod graphics_api;
/// Retained-mode GUI widgets API.
pub mod gui_api;
/// CPU-side image pixel manipulation API.
pub mod image_api;
/// Keyboard, mouse, gamepad, and touch input API.
pub mod input_api;
/// Lighting and shadow API.
pub mod light_api;
/// Math utilities, noise, easing, random, and transform API.
pub mod math_api;
/// Minimap extraction and FOV masking API.
pub mod minimap_api;
/// Mod discovery and load-ordering API.
pub mod modding_api;
/// UDP networking API.
pub mod network_api;
/// 2D particle emitter API.
pub mod particle_api;
/// A-star and flow-field navigation API.
pub mod pathfinding_api;
/// Rigid-body physics API.
pub mod physics_api;
/// Data pipeline and pattern helpers API.
pub mod pipeline_api;
/// Procedural generation API.
pub mod procgen_api;
/// DDA raycaster API.
pub mod raycaster_api;
/// Save/load orchestration API.
pub mod savegame_api;
/// Scene stack and transition API.
pub mod scene_api;
/// Binary serialisation API.
pub mod serial_api;
/// Decoded PCM audio sample API.
pub mod sound_api;
/// Skeletal animation (Spine) API.
pub mod spine_api;
/// Text-mode terminal emulator API.
pub mod terminal_api;
/// Background thread and Channel API.
pub mod thread_api;
/// Tilemap and tileset API.
pub mod tilemap_api;
/// Frame timing and FPS API.
pub mod timer_api;

// ── VM factory ───────────────────────────────────────────────────────────────

/// Creates a sandboxed LuaJIT VM and registers all enabled `luna.*` API modules.
///
/// The `luna` global table is populated with every sub-API whose corresponding
/// [`ModulesConfig`] flag is `true`.  A small set of always-on modules (math,
/// event, dataframe, serial, light) are registered unconditionally.
///
/// # Parameters
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `modules` — `&ModulesConfig`.
///
/// # Returns
/// `LuaResult<Lua>`.
pub fn create_lua_vm(
    state: Rc<RefCell<SharedState>>,
    modules: &ModulesConfig,
) -> LuaResult<Lua> {
    let lua = Lua::new();
    let luna = lua.create_table()?;

    // ── Always-on ────────────────────────────────────────────────────────────
    math_api::register(&lua, &luna, state.clone())?;
    event_api::register(&lua, &luna, state.clone())?;

    // ── Graphics ─────────────────────────────────────────────────────────────
    if modules.graphics {
        graphics_api::register(&lua, &luna, state.clone())?;
    }
    if modules.image {
        image_api::register(&lua, &luna, state.clone())?;
    }

    // ── Audio ─────────────────────────────────────────────────────────────────
    if modules.audio {
        audio_api::register(&lua, &luna, state.clone())?;
        sound_api::register(&lua, &luna, state.clone())?;
    }

    // ── Physics ───────────────────────────────────────────────────────────────
    if modules.physics {
        physics_api::register(&lua, &luna, state.clone())?;
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    if modules.input {
        input_api::register(&lua, &luna, state.clone())?;
    }

    // ── Timer ─────────────────────────────────────────────────────────────────
    if modules.timer {
        timer_api::register(&lua, &luna, state.clone())?;
    }

    // ── Filesystem ────────────────────────────────────────────────────────────
    if modules.filesystem {
        filesystem_api::register(&lua, &luna, state.clone())?;
    }

    // ── Particle ─────────────────────────────────────────────────────────────
    if modules.particle {
        particle_api::register(&lua, &luna, state.clone())?;
    }

    // ── GUI ───────────────────────────────────────────────────────────────────
    if modules.gui {
        gui_api::register(&lua, &luna, state.clone())?;
    }

    // ── Overlay / light ───────────────────────────────────────────────────────
    if modules.overlay {
        light_api::register(&lua, &luna, state.clone())?;
        pipeline_api::register(&lua, &luna, state.clone())?;
    }

    // ── Tilemap ───────────────────────────────────────────────────────────────
    if modules.tilemap {
        tilemap_api::register(&lua, &luna, state.clone())?;
    }

    // ── Scene ─────────────────────────────────────────────────────────────────
    if modules.scene {
        scene_api::register(&lua, &luna, state.clone())?;
    }

    // ── Savegame ──────────────────────────────────────────────────────────────
    if modules.savegame {
        savegame_api::register(&lua, &luna, state.clone())?;
    }

    // ── Entity ────────────────────────────────────────────────────────────────
    if modules.entity {
        entity_api::register(&lua, &luna, state.clone())?;
    }

    // ── AI ────────────────────────────────────────────────────────────────────
    if modules.ai {
        ai_api::register(&lua, &luna, state.clone())?;
    }

    // ── Pathfinding ───────────────────────────────────────────────────────────
    if modules.pathfinding {
        pathfinding_api::register(&lua, &luna, state.clone())?;
    }

    // ── Thread ────────────────────────────────────────────────────────────────
    if modules.thread {
        thread_api::register(&lua, &luna, state.clone())?;
    }

    // ── Graph ─────────────────────────────────────────────────────────────────
    if modules.graph {
        graph_api::register(&lua, &luna, state.clone())?;
    }

    // ── Data / serial / compute / dataframe ───────────────────────────────────
    if modules.data {
        data_api::register(&lua, &luna, state.clone())?;
        serial_api::register(&lua, &luna, state.clone())?;
    }
    if modules.compute {
        compute_api::register(&lua, &luna, state.clone())?;
        dataframe_api::register(&lua, &luna, state.clone())?;
    }

    // ── Minimap ───────────────────────────────────────────────────────────────
    if modules.minimap {
        minimap_api::register(&lua, &luna, state.clone())?;
    }

    // ── Modding ───────────────────────────────────────────────────────────────
    if modules.modding {
        modding_api::register(&lua, &luna, state.clone())?;
    }

    // ── Camera ────────────────────────────────────────────────────────────────
    if modules.camera {
        camera_api::register(&lua, &luna, state.clone())?;
    }

    // ── Animation ─────────────────────────────────────────────────────────────
    if modules.animation {
        animation_api::register(&lua, &luna, state.clone())?;
    }

    // ── Network ───────────────────────────────────────────────────────────────
    if modules.network {
        network_api::register(&lua, &luna, state.clone())?;
    }

    // ── Procgen ───────────────────────────────────────────────────────────────
    if modules.procgen {
        procgen_api::register(&lua, &luna, state.clone())?;
    }

    // ── Raycaster ─────────────────────────────────────────────────────────────
    if modules.raycaster {
        raycaster_api::register(&lua, &luna, state.clone())?;
    }

    // ── Spine ─────────────────────────────────────────────────────────────────
    if modules.spine {
        spine_api::register(&lua, &luna, state.clone())?;
    }

    // ── Terminal ──────────────────────────────────────────────────────────────
    if modules.terminal {
        terminal_api::register(&lua, &luna, state.clone())?;
    }

    // ── Debug / automation ────────────────────────────────────────────────────
    if modules.debug {
        automation_api::register(&lua, &luna, state.clone())?;
    }

    luna.set("_ENGINE_VERSION", env!("CARGO_PKG_VERSION"))?;
    lua.globals().set("luna", luna)?;

    Ok(lua)
}
