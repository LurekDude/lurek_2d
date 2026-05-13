#[cfg(feature = "automation-plugin")]
use super::automation_api;
#[cfg(feature = "devtools-plugin")]
use super::devtools_api;
#[cfg(feature = "graph")]
use super::graph_api;
use super::{
    ai_api, animation_api, audio_api, camera_api, compute_api, data_api, dataframe_api,
    debugbridge_api, docs_api, ecs_api, effect_api, engine_api, event_api, filesystem_api,
    globe_api, html_api, i18n_api, image_api, input_api, light_api, log_api, math_api, minimap_api,
    mods_api, network_api, parallax_api, particle_api, pathfind_api, patterns_api, physics_api,
    pipeline_api, procgen_api, province_api, raycaster_api, render_api, save_api, scene_api,
    serial_api, spine_api, sprite_api, system_api, terminal_api, thread_api, tilemap_api,
    timer_api, tween_api, ui_api, window_api,
};
use crate::runtime::config::ModulesConfig;
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
pub fn create_lua_vm(state: Rc<RefCell<SharedState>>, modules: &ModulesConfig) -> LuaResult<Lua> {
    let lua = Lua::new();
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
    let lurek = lua.create_table()?;
    lua.globals().set("lurek", lurek.clone())?;
    event_api::register(&lua, &lurek, state.clone())?;
    if modules.timer {
        timer_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.image {
        image_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.camera {
        camera_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.animation {
        animation_api::register(&lua, &lurek, state.clone())?;
    }
    sprite_api::register(&lua, &lurek, state.clone())?;
    if modules.tween {
        tween_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.thread {
        thread_api::register(&lua, &lurek, state.clone())?;
    }
    #[cfg(feature = "automation-plugin")]
    if modules.debug {
        automation_api::register(&lua, &lurek, state.clone())?;
    }
    #[cfg(feature = "devtools-plugin")]
    if modules.debug {
        devtools_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.debug {
        debugbridge_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.i18n {
        i18n_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.input {
        input_api::register(&lua, &lurek, state.clone())?;
    }
    save_api::register(&lua, &lurek, state.clone())?;
    docs_api::register(&lua, &lurek, state.clone())?;
    log_api::register(&lua, &lurek, state.clone())?;
    engine_api::register(&lua, &lurek, state.clone())?;
    data_api::register(&lua, &lurek, state.clone())?;
    mods_api::register(&lua, &lurek, state.clone())?;
    serial_api::register(&lua, &lurek, state.clone())?;
    dataframe_api::register(&lua, &lurek, state.clone())?;
    light_api::register(&lua, &lurek, state.clone())?;
    if modules.filesystem {
        filesystem_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.ecs {
        ecs_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.window {
        window_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.scene {
        scene_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.compute {
        compute_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.raycaster {
        raycaster_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.spine {
        spine_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.procgen {
        procgen_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.network {
        network_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.minimap {
        minimap_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.image {
        province_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.pathfind {
        pathfind_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.terminal {
        terminal_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.pipeline {
        pipeline_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.pipeline {
        patterns_api::register(&lua, &lurek, state.clone())?;
    }
    #[cfg(feature = "graph")]
    if modules.graph {
        graph_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.globe {
        globe_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.ai {
        ai_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.audio {
        audio_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.effect {
        effect_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.particle {
        particle_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.parallax {
        parallax_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.ui {
        ui_api::register(&lua, &lurek, state.clone())?;
    }
    html_api::register(&lua, &lurek, state.clone())?;
    if modules.tilemap {
        tilemap_api::register(&lua, &lurek, state.clone())?;
    }
    math_api::register(&lua, &lurek, state.clone())?;
    system_api::register(&lua, &lurek, state.clone())?;
    if modules.physics {
        physics_api::register(&lua, &lurek, state.clone())?;
    }
    if modules.render {
        render_api::register(&lua, &lurek, state.clone())?;
    }
    lua.globals().set("lurek", lurek)?;
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
