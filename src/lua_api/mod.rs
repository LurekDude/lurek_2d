//! Lua API binding bridge for the Lurek2D engine.
//!
//! This is the integration layer that registers all `lurek.*` API sub-modules
//! on top of the types defined in `engine`. `SharedState`, `WindowState`,
//! `FullscreenType`, and `ErrorInfo` are defined in `engine::shared_state`
//! and re-exported here for sub-module convenience.
//!
//! The primary entry point is `create_lua_vm()` which constructs a configured
//! LuaJIT VM with every `lurek.*` namespace bound.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::config::ModulesConfig;
pub use crate::engine::{ErrorInfo, FullscreenType, SharedState, WindowState};

/// Registers the `lurek.signal.*` event queue and signal API.
pub mod event_api;

/// Registers the `lurek.time.*` frame-timing API.
pub mod timer_api;

/// Registers the `lurek.img.*` pixel-level image manipulation API.
pub mod image_api;

/// Registers the `lurek.camera.*` Camera2D API.
pub mod camera_api;

/// Registers the `lurek.tween.*` API.
pub mod animation_api;

/// Registers the `lurek.thread.*` background threading API.
pub mod thread_api;
pub mod tween_api;

/// Registers the `lurek.simulator.*` automated input simulation API.
pub mod automation_api;

/// Registers the `lurek.keyboard` / `lurek.mouse` / `lurek.gamepad` / `lurek.touch` input API.
pub mod input_api;

/// Registers the `lurek.savegame.*` slot-based save/load API.
pub mod save_api;

/// Registers the `lurek.data.*` binary data, compression, hashing, and encoding API.
pub mod data_api;

/// Registers the `lurek.entity.*` lightweight ECS API.
pub mod ecs_api;

/// Registers the `lurek.scene.*` scene stack and depth-sorter API.
pub mod scene_api;

/// Registers the `lurek.gpu.*` array computation API.
pub mod compute_api;

/// Registers the `lurek.window.*` window management API.
pub mod window_api;

/// Registers the `lurek.modding.*` mod management API.
pub mod mods_api;

/// Registers the `lurek.fs.*` sandboxed file I/O API.
pub mod filesystem_api;

/// Registers the `lurek.codec.*` format serialization API.
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

/// Registers the `lurek.pathfinding.*` grid-based pathfinding API.
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

/// Registers the `lurek.ai.*` game AI toolkit API.
pub mod ai_api;

/// Registers the `lurek.audio.*` audio playback, mixing, and MIDI API.
pub mod audio_api;

/// Registers the `lurek.postfx.*` post-processing and screen overlay API.
pub mod effect_api;

/// Registers the `lurek.particles.*` particle system and trail API.
pub mod particle_api;

/// Registers the `lurek.parallax.*` multi-layer parallax background API.
pub mod parallax_api;

/// Registers the `lurek.ui.*` retained-mode widget UI API.
pub mod ui_api;

/// Registers the `lurek.tilemap.*` tile-based map authoring and coordinate helpers API.
pub mod tilemap_api;

/// Registers the `lurek.math.*` math utilities API.
pub mod math_api;

/// Registers the `lurek.physics.*` rigid-body physics API.
pub mod physics_api;

/// Registers the `lurek.gfx.*` rendering and drawing API.
pub mod graphic_api;

/// Exposes low-level system queries (processor count, memory size, URL opening, locale, power).
pub mod system_api;

/// Registers the `lurek.devtools.*` developer diagnostics API.
pub mod devtools_api;

/// Registers the `lurek.debugbridge.*` TCP debug server API.
pub mod debugbridge_api;

/// Registers the `lurek.localization.*` multi-locale string catalog API.
pub mod i18n_api;

/// Registers the `lurek.log.*` structured log level API.
pub mod log_api;

/// Registers the `lurek.docs.*` documentation management API.
pub mod docs_api;

/// Registers the `lurek.patterns.*` game programming patterns API.
pub mod patterns_api;

/// Shared `LunaType` trait and `add_type_methods` helper for typed UserData objects.
pub mod lua_types;

/// Creates and configures the Lua VM, registers `lurek.*` sub-APIs according to the
/// provided module flags, and returns the ready `Lua` instance.
///
/// # Parameters
/// - `state` — Shared engine state passed (via `Rc<RefCell>` clone) to every Lua closure.
/// - `modules` — Module enable/disable flags read from `conf.lua`. Mandatory APIs
///   (`math`, `log`, `event`) are always registered regardless of flags.
///
/// # Returns
/// `LuaResult<Lua>` — A configured Lua VM with `lurek.*` as a global, or a Lua error if
/// any sub-API fails to register.
pub fn create_lua_vm(state: Rc<RefCell<SharedState>>, modules: &ModulesConfig) -> LuaResult<Lua> {
    let lua = Lua::new();

    // Create the lurek namespace table and expose it as the `lurek` global immediately.
    // This must happen before any register() call so that inline Lua snippets (e.g.
    // scene_api.rs) can reference `lurek.*` during module registration.
    let luna = lua.create_table()?;
    lua.globals().set("lurek", luna.clone())?;

    // event: lurek.signal (always registered — mandatory API)
    event_api::register(&lua, &luna, state.clone())?;

    // timer: lurek.time
    if modules.timer {
        timer_api::register(&lua, &luna, state.clone())?;
    }

    // image: lurek.img
    if modules.image {
        image_api::register(&lua, &luna, state.clone())?;
    }

    // camera: lurek.camera
    if modules.camera {
        camera_api::register(&lua, &luna, state.clone())?;
    }

    // animation: lurek.animation
    if modules.animation {
        animation_api::register(&lua, &luna, state.clone())?;
    }

    // tween: lurek.tween
    if modules.tween {
        tween_api::register(&lua, &luna, state.clone())?;
    }

    // thread: lurek.thread
    if modules.thread {
        thread_api::register(&lua, &luna, state.clone())?;
    }

    // automation: lurek.simulator
    if modules.debug {
        automation_api::register(&lua, &luna, state.clone())?;
    }

    // devtools: lurek.devtools
    if modules.debug {
        devtools_api::register(&lua, &luna, state.clone())?;
    }

    // debugbridge: lurek.debugbridge
    if modules.debug {
        debugbridge_api::register(&lua, &luna)?;
    }

    // localization: lurek.localization
    if modules.localization {
        i18n_api::register(&lua, &luna, state.clone())?;
    }

    // input: lurek.keyboard / lurek.mouse / lurek.gamepad / lurek.touch
    if modules.input {
        input_api::register(&lua, &luna, state.clone())?;
    }

    // savegame: lurek.savegame (always registered — no config flag)
    save_api::register(&lua, &luna, state.clone())?;

    // docs: lurek.docs (always registered — no config flag)
    docs_api::register(&lua, &luna)?;

    // log: lurek.log (always registered — no config flag)
    log_api::register(&lua, &luna)?;

    // data: lurek.data (always registered — no config flag)
    data_api::register(&lua, &luna, state.clone())?;

    // modding: lurek.modding (always registered — no config flag)
    mods_api::register(&lua, &luna, state.clone())?;

    // serial: lurek.codec (always registered — no config flag)
    serial_api::register(&lua, &luna, state.clone())?;

    // dataframe: lurek.dataframe (always registered — no config flag)
    dataframe_api::register(&lua, &luna, state.clone())?;

    // light: lurek.light (always registered — no config flag)
    light_api::register(&lua, &luna, state.clone())?;

    // filesystem: lurek.fs
    if modules.filesystem {
        filesystem_api::register(&lua, &luna, state.clone())?;
    }

    // entity: lurek.entity
    if modules.entity {
        ecs_api::register(&lua, &luna, state.clone())?;
    }

    // window: lurek.window
    if modules.window {
        window_api::register(&lua, &luna, state.clone())?;
    }

    // scene: lurek.scene
    if modules.scene {
        scene_api::register(&lua, &luna, state.clone())?;
    }

    // compute: lurek.gpu
    if modules.compute {
        compute_api::register(&lua, &luna, state.clone())?;
    }

    // raycaster: lurek.raycaster
    if modules.raycaster {
        raycaster_api::register(&lua, &luna, state.clone())?;
    }

    // spine: lurek.spine
    if modules.spine {
        spine_api::register(&lua, &luna, state.clone())?;
    }

    // procgen: lurek.procgen
    if modules.procgen {
        procgen_api::register(&lua, &luna, state.clone())?;
    }

    // network: lurek.network
    if modules.network {
        network_api::register(&lua, &luna, state.clone())?;
    }

    // minimap: lurek.minimap
    if modules.minimap {
        minimap_api::register(&lua, &luna, state.clone())?;
    }

    // pathfinding: lurek.pathfinding
    if modules.pathfinding {
        pathfind_api::register(&lua, &luna, state.clone())?;
    }

    // terminal: lurek.terminal
    if modules.terminal {
        terminal_api::register(&lua, &luna, state.clone())?;
    }

    // pipeline: lurek.pipeline
    if modules.pipeline {
        pipeline_api::register(&lua, &luna, state.clone())?;
    }

    // patterns: lurek.patterns
    if modules.pipeline {
        patterns_api::register(&lua, &luna, state.clone())?;
    }

    // graph: lurek.graph
    if modules.graph {
        graph_api::register(&lua, &luna, state.clone())?;
    }

    // ai: lurek.ai
    if modules.ai {
        ai_api::register(&lua, &luna, state.clone())?;
    }

    // audio: lurek.audio
    if modules.audio {
        audio_api::register(&lua, &luna, state.clone())?;
    }

    // fx: lurek.postfx
    if modules.overlay {
        effect_api::register(&lua, &luna, state.clone())?;
    }

    // particle: lurek.particles
    if modules.particle {
        particle_api::register(&lua, &luna, state.clone())?;
    }

    // parallax: lurek.parallax
    if modules.parallax {
        parallax_api::register(&lua, &luna, state.clone())?;
    }

    // gui: lurek.ui
    if modules.gui {
        ui_api::register(&lua, &luna, state.clone())?;
    }

    // tilemap: lurek.tilemap
    if modules.tilemap {
        tilemap_api::register(&lua, &luna, state.clone())?;
    }

    // math: lurek.math (always registered — mandatory)
    math_api::register(&lua, &luna, state.clone())?;

    // system: lurek.platform (always registered — OS info, openURL, locales)
    system_api::register(&lua, &luna, state.clone())?;

    // physics: lurek.physics
    if modules.physics {
        physics_api::register(&lua, &luna, state.clone())?;
    }

    // graphics: lurek.gfx
    if modules.graphics {
        graphic_api::register(&lua, &luna, state.clone())?;
    }

    // Register lurek.conf as a no-op runtime callback.
    // During engine boot the real conf.lua is executed in a temporary Lua VM
    // before this VM is created. At runtime, lurek.conf() is a safe no-op so
    // that test scripts and any post-boot calls don't error.
    luna.set("conf", lua.create_function(|_, _: mlua::Value| Ok(()))?)?;

    lua.globals().set("lurek", luna)?;

    // Add content-library paths to the Lua package path so games and tests can use
    // `require("library.dialog")`, `require("library.item")`, etc.
    {
        let package: LuaTable = lua.globals().get("package")?;
        let old_path: String = package.get("path")?;
        let mut new_path = old_path;
        new_path.push_str(";./?/init.lua;./?.lua;./content/?/init.lua;./content/?.lua");
        if let Ok(exe) = std::env::current_exe() {
            if let Some(dir) = exe.parent() {
                let d = dir.to_string_lossy().replace('\\', "/");
                new_path.push_str(&format!(
                    ";{}/?/init.lua;{}/?.lua;{}/content/?/init.lua;{}/content/?.lua",
                    d, d, d, d
                ));
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
