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

use crate::engine::config::ModulesConfig;
pub use crate::engine::{ErrorInfo, FullscreenType, SharedState, WindowState};

/// Registers the `luna.ai.*` game AI toolkit API.
pub mod ai_api;
/// Registers the `luna.audio.*` sound playback API.
pub mod audio_api;
/// Registers the `luna.simulator.*` automated input simulation API.
pub mod automation_api;
/// Registers the `luna.compute.*` array computation API.
pub mod compute_api;
/// Registers the `luna.data.*` LÖVE2D-compatible binary data, pack, compress, hash, encode, and TOML API.
pub mod data_api;
/// Registers the `luna.dataframe.*` tabular data API.
pub mod dataframe_api;
/// Registers the `luna.debug.*` runtime diagnostics and developer tools API.
pub mod debug_api;
/// Registers the `luna.debugbridge.*` TCP debug server API.
pub mod debugbridge_api;
/// Registers the `luna.serial.*` JSON, TOML, CSV, and YAML serialization API.
pub mod serial_api;
// dialog_api removed — dialog system is now library/dialog/init.lua
/// Registers the `luna.docs.*` documentation management API.
pub mod docs_api;
/// Registers the `luna.entity.*` ECS universe API.
pub mod entity_api;
/// Registers the `luna.event.*` engine control API.
pub mod event_api;
/// Registers the `luna.filesystem.*` sandboxed I/O API.
pub mod filesystem_api;
/// Registers the `luna.font.*` font rasterizer and glyph metrics API.
pub mod font_api;
/// Registers the `luna.graph.*` directed-graph and item-flow simulation API.
pub mod graph_api;
/// Registers the `luna.graphics.*` drawing API.
pub mod graphics_api;
/// Registers the `luna.gui.*` retained-mode widget UI API.
pub mod gui_api;
/// Registers the `luna.image.*` pixel-level image manipulation API.
pub mod image_api;
/// Registers the `luna.keyboard.*` and `luna.mouse.*` input API.
pub mod input_api;
/// Registers the `luna.light.*` 2D lighting API.
pub mod light_api;
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
/// Registers the `luna.overlay.*` screen-effect overlay API.
pub mod overlay_api;
/// Registers the `luna.particle.*` particle-effects API.
pub mod particle_api;
/// Registers the `luna.pathfinding.*` grid-based pathfinding API.
pub mod pathfinding_api;
/// Registers the `luna.patterns.*` software design patterns API.
pub mod patterns_api;
/// Registers the `luna.physics.*` rigid-body simulation API.
pub mod physics_api;
/// Registers the `luna.pipeline.*` DAG pipeline orchestrator API.
pub mod pipeline_api;
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
/// Registers the `luna.terminal.*` text-mode terminal emulator API.
pub mod terminal_api;
/// Registers the `luna.thread.*` multithreading API.
pub mod thread_api;
/// Re-export thread channel from src/thread.
pub use crate::thread::channel as thread_channel;
/// Re-export thread worker from src/thread.
pub use crate::thread::worker as thread_worker;
// battle_api removed — battle system is now library/battle/init.lua
// cardgame_api removed — cardgame system is now library/cardgame/init.lua
// combat_api removed — combat system is now library/combat/init.lua
// crafting_api removed — crafting system is now library/crafting/init.lua
// economy_api removed — economy system is now library/economy/init.lua
// inventory_api removed — inventory system is now library/inventory/init.lua
// item_api removed – cardgame covers this domain (doc comment removed)
/// UserData type utilities for Luna2D Lua objects.
pub mod lua_types;
// quest_api removed — quest system is now library/quest/init.lua
// stats_api removed — stats system is now library/stats/init.lua
/// Registers the `luna.tilemap.*` tile map, tileset, autotile, and procedural generation API.
pub mod animation_api;
pub mod camera_api;
pub mod network_api;
pub mod procgen_api;
pub mod raycaster_api;
pub mod spine_api;
pub mod tilemap_api;
/// Registers the `luna.timer.*` frame-timing API.
pub mod timer_api;
/// Registers the `luna.window.*` window management API.
pub mod window_api;

/// Creates and configures the Lua VM, registers `luna.*` sub-APIs according to the
/// provided module flags, and returns the ready `Lua` instance.
///
/// # Parameters
/// - `state` — Shared engine state passed (via `Rc<RefCell>` clone) to every Lua closure.
/// - `modules` — Module enable/disable flags read from `conf.lua`. Mandatory APIs
///   (`math`, `log`, `event`) are always registered regardless of flags.
///
/// # Returns
/// `LuaResult<Lua>` — A configured Lua VM with `luna.*` as a global, or a Lua error if
/// any sub-API fails to register.
pub fn create_lua_vm(state: Rc<RefCell<SharedState>>, modules: &ModulesConfig) -> LuaResult<Lua> {
    let lua = Lua::new();

    // Create the luna namespace table
    let luna = lua.create_table()?;

    // Mandatory — always registered
    math_api::register(&lua, &luna)?;
    log_api::register(&lua, &luna)?;
    event_api::register(&lua, &luna, state.clone())?;

    // graphics: luna.graphics, luna.font, luna.sprite
    if modules.graphics {
        graphics_api::register(&lua, &luna, state.clone())?;
        font_api::register(&lua, &luna, state.clone())?;
        sprite_api::register(&lua, &luna)?;
    }

    // light: luna.light (requires graphics for GPU rendering)
    if modules.graphics {
        light_api::register(&lua, &luna, state.clone())?;
    }

    // audio: luna.audio
    if modules.audio {
        audio_api::register(&lua, &luna, state.clone())?;
    }

    // input: luna.input (keyboard/mouse/gamepad)
    if modules.input {
        input_api::register(&lua, &luna, state.clone())?;
    }

    // timer: luna.timer
    if modules.timer {
        timer_api::register(&lua, &luna, state.clone())?;
    }

    // filesystem: luna.filesystem
    if modules.filesystem {
        filesystem_api::register(&lua, &luna, state.clone())?;
    }

    // window: luna.window
    if modules.window {
        window_api::register(&lua, &luna, state.clone())?;
    }

    // physics: luna.physics
    if modules.physics {
        physics_api::register(&lua, &luna)?;
    }

    // particle: luna.particle
    if modules.particle {
        particle_api::register(&lua, &luna, state.clone())?;
    }

    // system: luna.system
    if modules.system {
        system_api::register(&lua, &luna, state.clone())?;
    }

    // data: luna.data, luna.serial
    if modules.data {
        data_api::register(&lua, &luna)?;
        serial_api::register(&lua, &luna)?;
    }

    // localization: luna.localization
    if modules.localization {
        localization_api::register(&lua, &luna)?;
    }

    // image: luna.image
    if modules.image {
        image_api::register(&lua, &luna, state.clone())?;
    }

    // gui: luna.gui
    if modules.gui {
        gui_api::register(&lua, &luna)?;
    }

    // compute: luna.compute, luna.dataframe
    if modules.compute {
        compute_api::register(&lua, &luna)?;
        dataframe_api::register(&lua, &luna)?;
    }

    // ai: luna.ai, luna.steering
    if modules.ai {
        ai_api::register(&lua, &luna)?;
        steering_api::register(&lua, &luna)?;
    }

    // pathfinding: luna.pathfinding
    if modules.pathfinding {
        pathfinding_api::register(&lua, &luna)?;
    }

    // graph: luna.graph
    if modules.graph {
        graph_api::register(&lua, &luna)?;
    }

    // thread: luna.thread
    if modules.thread {
        thread_api::register(&lua, &luna)?;
    }

    // tilemap: luna.tilemap
    if modules.tilemap {
        tilemap_api::register(&lua, &luna)?;
    }

    // scene: luna.scene
    if modules.scene {
        scene_api::register(&lua, &luna)?;
    }

    // overlay: luna.overlay, luna.postfx
    if modules.overlay {
        overlay_api::register(&lua, &luna)?;
        postfx_api::register(&lua, &luna, state.clone())?;
    }

    // entity: luna.entity
    if modules.entity {
        entity_api::register(&lua, &luna)?;
    }

    // minimap: luna.minimap
    if modules.minimap {
        minimap_api::register(&lua, &luna)?;
    }

    // modding: luna.modding
    if modules.modding {
        modding_api::register(&lua, &luna, state.clone())?;
    }

    // savegame: luna.savegame
    if modules.savegame {
        savegame_api::register(&lua, &luna, state.clone())?;
    }

    // pipeline: luna.pipeline, luna.patterns
    if modules.pipeline {
        pipeline_api::register(&lua, &luna)?;
        patterns_api::register(&lua, &luna)?;
    }

    // animation: luna.animation
    if modules.animation {
        animation_api::register(&lua, &luna)?;
    }

    // camera: luna.camera
    if modules.camera {
        camera_api::register(&lua, &luna)?;
    }

    // network: luna.network
    if modules.network {
        network_api::register(&lua, &luna)?;
    }

    // procgen: luna.procgen
    if modules.procgen {
        procgen_api::register(&lua, &luna)?;
    }

    // raycaster: luna.raycaster
    if modules.raycaster {
        raycaster_api::register(&lua, &luna)?;
    }

    // spine: luna.spine
    if modules.spine {
        spine_api::register(&lua, &luna)?;
    }

    // terminal: luna.terminal
    if modules.terminal {
        terminal_api::register(&lua, &luna, state.clone())?;
    }

    // debug: luna.debug, luna.debugbridge, luna.docs, luna.simulator
    if modules.debug {
        debug_api::register(&lua, &luna)?;
        debugbridge_api::register(&lua, &luna)?;
        docs_api::register(&lua, &luna)?;
        automation_api::register(&lua, &luna, state.clone())?;
    }

    // Register luna.conf as a no-op runtime callback.
    // During engine boot the real conf.lua is executed in a temporary Lua VM
    // before this VM is created. At runtime, luna.conf() is a safe no-op so
    // that test scripts and any post-boot calls don't error.
    luna.set("conf", lua.create_function(|_, _: mlua::Value| Ok(()))?)?;

    lua.globals().set("luna", luna)?;

    // Add `library/` to the Lua package path so games can use
    // `require("library.dialog")`, `require("library.item")`, etc.
    // Two search patterns are appended:
    //   1. cwd-relative  — works during development (cargo run -- examples/X)
    //   2. exe-relative  — works in distribution (luna2d.exe next to library/)
    {
        let package: LuaTable = lua.globals().get("package")?;
        let old_path: String = package.get("path")?;
        let mut new_path = old_path;
        new_path.push_str(";./?/init.lua;./?.lua");
        if let Ok(exe) = std::env::current_exe() {
            if let Some(dir) = exe.parent() {
                let d = dir.to_string_lossy().replace('\\', "/");
                new_path.push_str(&format!(";{}/?/init.lua;{}/?.lua", d, d));
            }
        }
        package.set("path", new_path)?;
    }

    Ok(lua)
}
