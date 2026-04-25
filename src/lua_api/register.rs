//! Lua VM factory: `create_lua_vm` and `create_test_vm`.
//!
//! Moved from `src/lua_api/mod.rs` to satisfy TST-04 (thin `mod.rs`).

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::runtime::config::ModulesConfig;
use crate::runtime::SharedState;

use super::{
    ai_api, animation_api, audio_api, automation_api, camera_api, compute_api, data_api,
    dataframe_api, debugbridge_api, devtools_api, docs_api, ecs_api, effect_api, engine_api,
    event_api, filesystem_api, globe_api, graph_api, html_api, i18n_api, image_api, input_api, light_api,
    log_api, math_api, minimap_api, mods_api, network_api, parallax_api, particle_api,
    pathfind_api, patterns_api, physics_api, pipeline_api, procgen_api, raycaster_api, render_api,
    save_api, scene_api, serial_api, spine_api, sprite_api, system_api, terminal_api, thread_api,
    tilemap_api, timer_api, tween_api, ui_api, window_api,
};

/// Creates and configures the Lua VM, registers `lurek.*` sub-APIs according to the
/// provided module flags, and returns the ready `Lua` instance.
///
/// - `state` â€” Shared engine state passed (via `Rc<RefCell>` clone) to every Lua closure.
/// - `modules` â€” Module enable/disable flags read from `conf.toml`. Mandatory APIs
///   (`math`, `log`, `event`) are always registered regardless of flags.
///
/// `LuaResult<Lua>` â€” A configured Lua VM with `lurek.*` as a global, or a Lua error if
/// any sub-API fails to register
pub fn create_lua_vm(state: Rc<RefCell<SharedState>>, modules: &ModulesConfig) -> LuaResult<Lua> {
    let lua = Lua::new();

    // Disable dangerous functions in the sandbox
    {
        let globals = lua.globals();
        globals.set("load", mlua::Value::Nil)?;
        globals.set("loadfile", mlua::Value::Nil)?;
        globals.set("dofile", mlua::Value::Nil)?;
        globals.set("debug", mlua::Value::Nil)?;
        if let Ok(os) = globals.get::<_, mlua::Table>("os") {
            os.set("execute", mlua::Value::Nil)?;
            os.set("getenv", mlua::Value::Nil)?;
        }
        if let Ok(io) = globals.get::<_, mlua::Table>("io") {
            io.set("open", mlua::Value::Nil)?;
            io.set("popen", mlua::Value::Nil)?;
        }
    }

    // Create the lurek namespace table and expose it as the `lurek` global immediately.
    // This must happen before any register() call so that inline Lua snippets (e.g.
    // scene_api.rs) can reference `lurek.*` during module registration.
    let lurek = lua.create_table()?;
    lua.globals().set("lurek", lurek.clone())?;

    // event: lurek.event (always registered â€” mandatory API)
    event_api::register(&lua, &lurek, state.clone())?;

    // timer: lurek.timer
    if modules.timer {
        timer_api::register(&lua, &lurek, state.clone())?;
    }

    // image: lurek.image
    if modules.image {
        image_api::register(&lua, &lurek, state.clone())?;
    }

    // camera: lurek.camera
    if modules.camera {
        camera_api::register(&lua, &lurek, state.clone())?;
    }

    // animation: lurek.animation
    if modules.animation {
        animation_api::register(&lua, &lurek, state.clone())?;
    }

    // sprite: lurek.sprite (pure math/UV â€” always registered, no config flag)
    sprite_api::register(&lua, &lurek, state.clone())?;

    // tween: lurek.tween
    if modules.tween {
        tween_api::register(&lua, &lurek, state.clone())?;
    }

    // thread: lurek.thread
    if modules.thread {
        thread_api::register(&lua, &lurek, state.clone())?;
    }

    // automation: lurek.automation
    if modules.debug {
        automation_api::register(&lua, &lurek, state.clone())?;
    }

    // devtools: lurek.devtools
    if modules.debug {
        devtools_api::register(&lua, &lurek, state.clone())?;
    }

    // debugbridge: lurek.debugbridge
    if modules.debug {
        debugbridge_api::register(&lua, &lurek)?;
    }

    // i18n: lurek.i18n
    if modules.i18n {
        i18n_api::register(&lua, &lurek, state.clone())?;
    }

    // input: lurek.input.keyboard / lurek.input.mouse / lurek.input.gamepad / lurek.input.touch
    if modules.input {
        input_api::register(&lua, &lurek, state.clone())?;
    }

    // save: lurek.save (always registered â€” no config flag)
    save_api::register(&lua, &lurek, state.clone())?;

    // docs: lurek.docs (always registered â€” no config flag)
    docs_api::register(&lua, &lurek)?;

    // log: lurek.log (always registered â€” no config flag)
    log_api::register(&lua, &lurek)?;
    engine_api::register(&lua, &lurek, state.clone())?;

    // data: lurek.data (always registered â€” no config flag)
    data_api::register(&lua, &lurek, state.clone())?;

    // mods: lurek.mods (always registered â€” no config flag)
    mods_api::register(&lua, &lurek, state.clone())?;

    // serial: lurek.serial (always registered â€” no config flag)
    serial_api::register(&lua, &lurek, state.clone())?;

    // dataframe: lurek.dataframe (always registered â€” no config flag)
    dataframe_api::register(&lua, &lurek, state.clone())?;

    // light: lurek.light (always registered â€” no config flag)
    light_api::register(&lua, &lurek, state.clone())?;

    // filesystem: lurek.filesystem
    if modules.filesystem {
        filesystem_api::register(&lua, &lurek, state.clone())?;
    }

    // ecs: lurek.ecs
    if modules.ecs {
        ecs_api::register(&lua, &lurek, state.clone())?;
    }

    // window: lurek.window
    if modules.window {
        window_api::register(&lua, &lurek, state.clone())?;
    }

    // scene: lurek.scene
    if modules.scene {
        scene_api::register(&lua, &lurek, state.clone())?;
    }

    // compute: lurek.compute
    if modules.compute {
        compute_api::register(&lua, &lurek, state.clone())?;
    }

    // raycaster: lurek.raycaster
    if modules.raycaster {
        raycaster_api::register(&lua, &lurek, state.clone())?;
    }

    // spine: lurek.spine
    if modules.spine {
        spine_api::register(&lua, &lurek, state.clone())?;
    }

    // procgen: lurek.procgen
    if modules.procgen {
        procgen_api::register(&lua, &lurek, state.clone())?;
    }

    // network: lurek.network
    if modules.network {
        network_api::register(&lua, &lurek, state.clone())?;
    }

    // minimap: lurek.minimap
    if modules.minimap {
        minimap_api::register(&lua, &lurek, state.clone())?;
    }

    // pathfind: lurek.pathfind
    if modules.pathfind {
        pathfind_api::register(&lua, &lurek, state.clone())?;
    }

    // terminal: lurek.terminal
    if modules.terminal {
        terminal_api::register(&lua, &lurek, state.clone())?;
    }

    // pipeline: lurek.pipeline
    if modules.pipeline {
        pipeline_api::register(&lua, &lurek, state.clone())?;
    }

    // patterns: lurek.patterns
    if modules.pipeline {
        patterns_api::register(&lua, &lurek, state.clone())?;
    }

    // graph: lurek.graph
    if modules.graph {
        graph_api::register(&lua, &lurek, state.clone())?;
    }

    // globe: lurek.globe
    if modules.globe {
        globe_api::register(&lua, &lurek, state.clone())?;
    }

    // ai: lurek.ai
    if modules.ai {
        ai_api::register(&lua, &lurek, state.clone())?;
    }

    // audio: lurek.audio
    if modules.audio {
        audio_api::register(&lua, &lurek, state.clone())?;
    }

    // effect: lurek.effect
    if modules.effect {
        effect_api::register(&lua, &lurek, state.clone())?;
    }

    // particle: lurek.particle
    if modules.particle {
        particle_api::register(&lua, &lurek, state.clone())?;
    }

    // parallax: lurek.parallax
    if modules.parallax {
        parallax_api::register(&lua, &lurek, state.clone())?;
    }

    // ui: lurek.ui
    if modules.ui {
        ui_api::register(&lua, &lurek, state.clone())?;
    }

    // html: lurek.html (always registered — lightweight, no GPU)
    html_api::register(&lua, &lurek)?;

    // tilemap: lurek.tilemap
    if modules.tilemap {
        tilemap_api::register(&lua, &lurek, state.clone())?;
    }

    // math: lurek.math (always registered â€” mandatory)
    math_api::register(&lua, &lurek, state.clone())?;

    // system: lurek.runtime (always registered â€” OS info, openURL, locales)
    system_api::register(&lua, &lurek, state.clone())?;

    // physics: lurek.physics
    if modules.physics {
        physics_api::register(&lua, &lurek, state.clone())?;
    }

    // graphics: lurek.render
    if modules.render {
        render_api::register(&lua, &lurek, state.clone())?;
    }

    lua.globals().set("lurek", lurek)?;

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

/// Creates a test Lua VM with the BDD test framework loaded and all available API modules registered
/// @return LuaResult<Lua>
pub fn create_test_vm() -> LuaResult<Lua> {
    use crate::runtime::config::Config;
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
