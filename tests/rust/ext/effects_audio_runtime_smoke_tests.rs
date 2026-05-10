//! Headless runtime smoke for light/particle/effect/audio API surfaces.

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::runtime::config::Config;

fn create_smoke_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Smoke",
        PathBuf::from("."),
    )));
    state.borrow_mut().load_default_fonts();
    create_lua_vm(state, &Config::default().modules).expect("Failed to create Lua VM")
}

#[test]
fn runtime_smoke_light_particle_effect_audio() {
    let lua = create_smoke_vm();

    let script = r#"
        assert(type(lurek.light) == "table")
        assert(type(lurek.particle) == "table")
        assert(type(lurek.effect) == "table")
        assert(type(lurek.audio) == "table")

        lurek.light.clear()
        local light = lurek.light.newLight(64, 64, 32)
        assert(light ~= nil)

        local ps = lurek.particle.newSystem({ emissionRate = 10, maxParticles = 32 })
        assert(ps ~= nil)
        assert(type(lurek.particle.isActive(ps)) == "boolean")

        local stack = lurek.effect.newStack(320, 240)
        local fx = lurek.effect.newEffect("bloom")
        stack:add(fx)

        lurek.audio.setMasterVolume(0.25)
        local vol = lurek.audio.getMasterVolume()
        assert(type(vol) == "number")
        assert(vol >= 0.0 and vol <= 1.0)
    "#;

    lua.load(script)
        .set_name("effects_audio_runtime_smoke")
        .exec()
        .expect("runtime smoke script failed");
}
