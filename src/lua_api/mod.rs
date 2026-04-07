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

/// Registers the `luna.signal.*` event queue and signal API.
pub mod event_api;

/// Registers the `luna.time.*` frame-timing API.
pub mod timer_api;

/// Registers the `luna.img.*` pixel-level image manipulation API.
pub mod image_api;

/// Registers the `luna.camera.*` Camera2D API.
pub mod camera_api;

/// Registers the `luna.tween.*` API.
pub mod animation_api;

/// Registers the `luna.thread.*` background threading API.
pub mod thread_api;

/// Registers the `luna.simulator.*` automated input simulation API.
pub mod automation_api;

/// Registers the `luna.keyboard` / `luna.mouse` / `luna.gamepad` / `luna.touch` input API.
pub mod input_api;

/// Registers the `luna.savegame.*` slot-based save/load API.
pub mod savegame_api;

/// Registers the `luna.data.*` binary data, compression, hashing, and encoding API.
pub mod data_api;

/// Registers the `luna.entity.*` lightweight ECS API.
pub mod entity_api;

/// Registers the `luna.scene.*` scene stack and depth-sorter API.
pub mod scene_api;

/// Registers the `luna.gpu.*` array computation API.
pub mod compute_api;

/// Registers the `luna.window.*` window management API.
pub mod window_api;

/// Registers the `luna.modding.*` mod management API.
pub mod modding_api;

/// Registers the `luna.fs.*` sandboxed file I/O API.
pub mod filesystem_api;

/// Registers the `luna.codec.*` format serialization API.
pub mod serial_api;

/// Registers the `luna.raycaster.*` DDA grid raycasting API.
pub mod raycaster_api;

/// Registers the `luna.spine.*` skeletal animation API.
pub mod spine_api;

/// Registers the `luna.procgen.*` procedural generation API.
pub mod procgen_api;

/// Registers the `luna.network.*` UDP networking API.
pub mod network_api;

/// Registers the `luna.minimap.*` grid-based minimap API.
pub mod minimap_api;

/// Registers the `luna.pathfinding.*` grid-based pathfinding API.
pub mod pathfinding_api;

/// Registers the `luna.dataframe.*` tabular data API.
pub mod dataframe_api;

/// Registers the `luna.light.*` 2D lighting API.
pub mod light_api;

/// Registers the `luna.terminal.*` text-mode terminal emulator API.
pub mod terminal_api;

/// Registers the `luna.pipeline.*` DAG pipeline orchestrator API.
pub mod pipeline_api;

/// Registers the `luna.graph.*` directed-graph and item-flow simulation API.
pub mod graph_api;

/// Registers the `luna.ai.*` game AI toolkit API.
pub mod ai_api;

/// Registers the `luna.audio.*` audio playback, mixing, and MIDI API.
pub mod audio_api;

/// Registers the `luna.postfx.*` post-processing and screen overlay API.
pub mod fx_api;

/// Registers the `luna.particles.*` particle system and trail API.
pub mod particle_api;

/// Registers the `luna.ui.*` retained-mode widget UI API.
pub mod gui_api;

/// Registers the `luna.tilemap.*` tile-based map authoring and coordinate helpers API.
pub mod tilemap_api;

/// Registers the `luna.math.*` math utilities API.
pub mod math_api;

/// Registers the `luna.physics.*` rigid-body physics API.
pub mod physics_api;

/// Registers the `luna.gfx.*` rendering and drawing API.
pub mod graphics_api;

/// Exposes low-level system queries (processor count, memory size, URL opening, locale, power).
pub mod system_api;

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

    // event: luna.signal (always registered — mandatory API)
    event_api::register(&lua, &luna, state.clone())?;

    // timer: luna.time
    if modules.timer {
        timer_api::register(&lua, &luna, state.clone())?;
    }

    // image: luna.img
    if modules.image {
        image_api::register(&lua, &luna, state.clone())?;
    }

    // camera: luna.camera
    if modules.camera {
        camera_api::register(&lua, &luna, state.clone())?;
    }

    // animation: luna.tween
    if modules.animation {
        animation_api::register(&lua, &luna, state.clone())?;
    }

    // thread: luna.thread
    if modules.thread {
        thread_api::register(&lua, &luna, state.clone())?;
    }

    // automation: luna.simulator
    if modules.debug {
        automation_api::register(&lua, &luna, state.clone())?;
    }

    // input: luna.keyboard / luna.mouse / luna.gamepad / luna.touch
    if modules.input {
        input_api::register(&lua, &luna, state.clone())?;
    }

    // savegame: luna.savegame (always registered — no config flag)
    savegame_api::register(&lua, &luna, state.clone())?;

    // data: luna.data (always registered — no config flag)
    data_api::register(&lua, &luna, state.clone())?;

    // modding: luna.modding (always registered — no config flag)
    modding_api::register(&lua, &luna, state.clone())?;

    // serial: luna.codec (always registered — no config flag)
    serial_api::register(&lua, &luna, state.clone())?;

    // dataframe: luna.dataframe (always registered — no config flag)
    dataframe_api::register(&lua, &luna, state.clone())?;

    // light: luna.light (always registered — no config flag)
    light_api::register(&lua, &luna, state.clone())?;

    // filesystem: luna.fs
    if modules.filesystem {
        filesystem_api::register(&lua, &luna, state.clone())?;
    }

    // entity: luna.entity
    if modules.entity {
        entity_api::register(&lua, &luna, state.clone())?;
    }

    // window: luna.window
    if modules.window {
        window_api::register(&lua, &luna, state.clone())?;
    }

    // scene: luna.scene
    if modules.scene {
        scene_api::register(&lua, &luna, state.clone())?;
    }

    // compute: luna.gpu
    if modules.compute {
        compute_api::register(&lua, &luna, state.clone())?;
    }

    // raycaster: luna.raycaster
    if modules.raycaster {
        raycaster_api::register(&lua, &luna, state.clone())?;
    }

    // spine: luna.spine
    if modules.spine {
        spine_api::register(&lua, &luna, state.clone())?;
    }

    // procgen: luna.procgen
    if modules.procgen {
        procgen_api::register(&lua, &luna, state.clone())?;
    }

    // network: luna.network
    if modules.network {
        network_api::register(&lua, &luna, state.clone())?;
    }

    // minimap: luna.minimap
    if modules.minimap {
        minimap_api::register(&lua, &luna, state.clone())?;
    }

    // pathfinding: luna.pathfinding
    if modules.pathfinding {
        pathfinding_api::register(&lua, &luna, state.clone())?;
    }

    // terminal: luna.terminal
    if modules.terminal {
        terminal_api::register(&lua, &luna, state.clone())?;
    }

    // pipeline: luna.pipeline
    if modules.pipeline {
        pipeline_api::register(&lua, &luna, state.clone())?;
    }

    // graph: luna.graph
    if modules.graph {
        graph_api::register(&lua, &luna, state.clone())?;
    }

    // ai: luna.ai
    if modules.ai {
        ai_api::register(&lua, &luna, state.clone())?;
    }

    // audio: luna.audio
    if modules.audio {
        audio_api::register(&lua, &luna, state.clone())?;
    }

    // fx: luna.postfx
    if modules.overlay {
        fx_api::register(&lua, &luna, state.clone())?;
    }

    // particle: luna.particles
    if modules.particle {
        particle_api::register(&lua, &luna, state.clone())?;
    }

    // gui: luna.ui
    if modules.gui {
        gui_api::register(&lua, &luna, state.clone())?;
    }

    // tilemap: luna.tilemap
    if modules.tilemap {
        tilemap_api::register(&lua, &luna, state.clone())?;
    }

    // math: luna.math (always registered — mandatory)
    math_api::register(&lua, &luna, state.clone())?;

    // system: luna.platform (always registered — OS info, openURL, locales)
    system_api::register(&lua, &luna, state.clone())?;

    // physics: luna.physics
    if modules.physics {
        physics_api::register(&lua, &luna, state.clone())?;
    }

    // graphics: luna.gfx
    if modules.graphics {
        graphics_api::register(&lua, &luna, state.clone())?;
    }

    // Register luna.conf as a no-op runtime callback.
    // During engine boot the real conf.lua is executed in a temporary Lua VM
    // before this VM is created. At runtime, luna.conf() is a safe no-op so
    // that test scripts and any post-boot calls don't error.
    luna.set("conf", lua.create_function(|_, _: mlua::Value| Ok(()))?)?;

    lua.globals().set("luna", luna)?;

    // Add `library/` to the Lua package path so games can use
    // `require("library.dialog")`, `require("library.item")`, etc.
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

/// Creates a test Lua VM with the BDD test framework loaded and all available API modules registered.
///
/// # Returns
/// `LuaResult<Lua>`.
pub fn create_test_vm() -> LuaResult<Lua> {
    use crate::engine::config::Config;
    use std::path::PathBuf;
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    let modules = Config::default().modules;
    create_lua_vm(state, &modules)
}
