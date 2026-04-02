//! Registers the `luna.particle.*` particle-system API.
//!
//! Provides functions for creating, updating, drawing, and controlling
//! emitter-based particle effects from Lua game scripts.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::SharedState;
use crate::particle::{
    AreaDistribution, EmissionShape, ParticleConfig, ParticleSystem, RelativeMode,
};

mod helpers;
pub(super) mod ext;
use helpers::*;

pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let particle = lua.create_table()?;

    // ÔöÇÔöÇ newSystem ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "newSystem",
            lua.create_function(move |_, config: Option<LuaTable>| {
                let mut cfg = ParticleConfig::default();
                if let Some(t) = config {
                    if let Ok(v) = t.get::<_, u32>("maxParticles") {
                        cfg.max_particles = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("emissionRate") {
                        cfg.emission_rate = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("lifetimeMin") {
                        cfg.lifetime_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("lifetimeMax") {
                        cfg.lifetime_max = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedMin") {
                        cfg.speed_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedMax") {
                        cfg.speed_max = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("direction") {
                        cfg.direction = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spread") {
                        cfg.spread = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("gravityX") {
                        cfg.gravity_x = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("gravityY") {
                        cfg.gravity_y = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spinMin") {
                        cfg.spin_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spinMax") {
                        cfg.spin_max = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("emitterLifetime") {
                        cfg.emitter_lifetime = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("sizeVariation") {
                        cfg.size_variation = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spinVariation") {
                        cfg.spin_variation = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("rotationMin") {
                        cfg.rotation_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("rotationMax") {
                        cfg.rotation_max = v;
                    }
                    if let Ok(v) = t.get::<_, bool>("relativeRotation") {
                        cfg.relative_rotation = v;
                    }

                    // Multi-stop sizes ÔÇö prefer `sizes` table, fall back to sizeStart/sizeEnd
                    let has_sizes = if let Ok(st) = t.get::<_, LuaTable>("sizes") {
                        let mut sizes = Vec::new();
                        for i in 1..=32 {
                            match st.get::<_, f32>(i) {
                                Ok(v) => sizes.push(v),
                                Err(_) => break,
                            }
                        }
                        if !sizes.is_empty() {
                            cfg.sizes = sizes;
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };
                    if !has_sizes {
                        // Backward compat: sizeStart/sizeEnd -> sizes vec
                        let s0 = t.get::<_, f32>("sizeStart");
                        let s1 = t.get::<_, f32>("sizeEnd");
                        if let (Ok(start), Ok(end)) = (s0, s1) {
                            cfg.sizes = vec![start, end];
                        } else if let Ok(start) = t.get::<_, f32>("sizeStart") {
                            cfg.sizes = vec![start, cfg.sizes.last().copied().unwrap_or(1.0)];
                        } else if let Ok(end) = t.get::<_, f32>("sizeEnd") {
                            cfg.sizes = vec![cfg.sizes.first().copied().unwrap_or(4.0), end];
                        }
                    }

                    // Multi-stop colors ÔÇö prefer `colors` table, fall back to colorStart/colorEnd
                    let has_colors = if let Ok(ct) = t.get::<_, LuaTable>("colors") {
                        let mut colors = Vec::new();
                        for i in 1..=32 {
                            match ct.get::<_, LuaTable>(i) {
                                Ok(c) => {
                                    if let Ok(col) = parse_color(&c, 1.0) {
                                        colors.push(col);
                                    }
                                }
                                Err(_) => break,
                            }
                        }
                        if !colors.is_empty() {
                            cfg.colors = colors;
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };
                    if !has_colors {
                        // Backward compat: colorStart/colorEnd -> colors vec
                        let cs = t
                            .get::<_, LuaTable>("colorStart")
                            .ok()
                            .and_then(|c| parse_color(&c, 1.0).ok());
                        let ce = t
                            .get::<_, LuaTable>("colorEnd")
                            .ok()
                            .and_then(|c| parse_color(&c, 0.0).ok());
                        match (cs, ce) {
                            (Some(s), Some(e)) => cfg.colors = vec![s, e],
                            (Some(s), None) => {
                                cfg.colors = vec![
                                    s,
                                    cfg.colors.last().copied().unwrap_or([1.0, 1.0, 1.0, 0.0]),
                                ]
                            }
                            (None, Some(e)) => {
                                cfg.colors = vec![
                                    cfg.colors.first().copied().unwrap_or([1.0, 1.0, 1.0, 1.0]),
                                    e,
                                ]
                            }
                            (None, None) => {}
                        }
                    }

                    // --- Alpha keyframes ---
                    if let Ok(at) = t.get::<_, LuaTable>("alphaKeyframes") {
                        let mut alphas = Vec::new();
                        for i in 1..=32 {
                            match at.get::<_, f32>(i) {
                                Ok(v) => alphas.push(v),
                                Err(_) => break,
                            }
                        }
                        if !alphas.is_empty() {
                            cfg.alpha_keyframes = alphas;
                        }
                    }

                    // --- Emission shape ---
                    if let Ok(shape_str) = t.get::<_, String>("emissionShape") {
                        cfg.emission_shape = match shape_str.to_lowercase().as_str() {
                            "point" => EmissionShape::Point,
                            "circle" => {
                                let radius = t.get::<_, f32>("emissionShapeRadius").unwrap_or(10.0);
                                let fill = t.get::<_, bool>("emissionShapeFill").unwrap_or(true);
                                EmissionShape::Circle { radius, fill }
                            }
                            "rectangle" => {
                                let w = t.get::<_, f32>("emissionShapeWidth").unwrap_or(20.0);
                                let h = t.get::<_, f32>("emissionShapeHeight").unwrap_or(20.0);
                                EmissionShape::Rectangle {
                                    width: w,
                                    height: h,
                                }
                            }
                            "ring" => {
                                let inner =
                                    t.get::<_, f32>("emissionShapeInnerRadius").unwrap_or(5.0);
                                let outer =
                                    t.get::<_, f32>("emissionShapeOuterRadius").unwrap_or(10.0);
                                EmissionShape::Ring {
                                    inner_radius: inner,
                                    outer_radius: outer,
                                }
                            }
                            "line" => {
                                let length = t.get::<_, f32>("emissionShapeLength").unwrap_or(20.0);
                                let angle = t.get::<_, f32>("emissionShapeAngle").unwrap_or(0.0);
                                EmissionShape::Line { length, angle }
                            }
                            "cone" => {
                                let radius = t.get::<_, f32>("emissionShapeRadius").unwrap_or(10.0);
                                let angle = t.get::<_, f32>("emissionShapeAngle").unwrap_or(0.0);
                                let spread = t.get::<_, f32>("emissionShapeSpread").unwrap_or(0.5);
                                EmissionShape::Cone {
                                    radius,
                                    angle,
                                    spread,
                                }
                            }
                            "star" => {
                                let points = t.get::<_, u32>("emissionShapePoints").unwrap_or(5);
                                let outer =
                                    t.get::<_, f32>("emissionShapeOuterRadius").unwrap_or(20.0);
                                let inner =
                                    t.get::<_, f32>("emissionShapeInnerRadius").unwrap_or(8.0);
                                EmissionShape::Star {
                                    points,
                                    outer_radius: outer,
                                    inner_radius: inner,
                                }
                            }
                            "spiral" => {
                                let revolutions =
                                    t.get::<_, f32>("emissionShapeRevolutions").unwrap_or(2.0);
                                let radius = t.get::<_, f32>("emissionShapeRadius").unwrap_or(30.0);
                                EmissionShape::Spiral {
                                    revolutions,
                                    radius,
                                }
                            }
                            _ => EmissionShape::Point,
                        };
                    }

                    // --- Relative mode ---
                    if let Ok(mode_str) = t.get::<_, String>("relativeMode") {
                        cfg.relative_mode = match mode_str.to_lowercase().as_str() {
                            "attached" => RelativeMode::Attached,
                            _ => RelativeMode::Detached,
                        };
                    }

                    // --- New physics fields ---
                    if let Ok(v) = t.get::<_, f32>("turbulence") {
                        cfg.turbulence = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("drag") {
                        cfg.drag = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("orbitSpeed") {
                        cfg.orbit_speed = v;
                    }
                    if let Ok(v) = t.get::<_, u32>("animatedFrames") {
                        cfg.animated_frames = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("frameRate") {
                        cfg.frame_rate = v;
                    }
                    if let Ok(v) = t.get::<_, bool>("colorBySpeed") {
                        cfg.color_by_speed = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedColorMin") {
                        cfg.speed_color_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedColorMax") {
                        cfg.speed_color_max = v;
                    }
                }
                let mut st = s.borrow_mut();
                let key = st.particle_systems.insert(ParticleSystem::new(cfg));
                Ok(LuaParticleSystem {
                    state: s.clone(),
                    key,
                })
            })?,
        )?;
    }

    // ÔöÇÔöÇ update ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "update",
            lua.create_function(move |_, (id_val, dt): (LuaValue, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.update")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.update(dt);
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ draw ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "draw",
            lua.create_function(
                move |_, (id_val, x, y): (LuaValue, Option<f32>, Option<f32>)| {
                    let key = particle_key_from_value(&id_val)?;
                    let mut st = s.borrow_mut();
                    ensure_particle_exists(&st.particle_systems, key, "luna.particle.draw")?;
                    let cmds = if let Some(sys) = st.particle_systems.get(key) {
                        sys.draw_commands(x.unwrap_or(0.0), y.unwrap_or(0.0))
                    } else {
                        Vec::new()
                    };
                    st.draw_commands.extend(cmds);
                    Ok(())
                },
            )?,
        )?;
    }

    // ÔöÇÔöÇ start ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "start",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.start")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.start();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ stop ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "stop",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.stop")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.stop();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ pause ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "pause",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.pause")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.pause();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ reset ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "reset",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.reset")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.reset();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ emit ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "emit",
            lua.create_function(move |_, (id_val, count): (LuaValue, u32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.emit")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.emit(count);
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ clone ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "clone",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                let new_sys = st.particle_systems.get(key).map(|sys| sys.clone_config());
                if let Some(sys) = new_sys {
                    let new_key = st.particle_systems.insert(sys);
                    Ok(LuaParticleSystem {
                        state: s.clone(),
                        key: new_key,
                    })
                } else {
                    Err(mlua::Error::RuntimeError(
                        "luna.particle.clone: invalid particle system handle".into(),
                    ))
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ release ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "release",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                if st.particle_systems.remove(key).is_some() {
                    Ok(true)
                } else {
                    Err(mlua::Error::RuntimeError(
                        "luna.particle.release: invalid or already-released particle system handle"
                            .into(),
                    ))
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ getCount ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getCount",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.getCount")?;
                Ok(st.particle_systems.get(key).map(|s| s.count()).unwrap_or(0))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isActive ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isActive",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isActive")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_active())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isPaused ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isPaused",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isPaused")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_paused())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isStopped ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isStopped",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isStopped")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_stopped())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isEmpty ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isEmpty",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isEmpty")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_empty())
                    .unwrap_or(true))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isFull ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isFull",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isFull")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_full())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setPosition ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setPosition",
            lua.create_function(move |_, (id_val, x, y): (LuaValue, f32, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.setPosition")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.emitter_x = x;
                    sys.emitter_y = y;
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getPosition ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getPosition",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.getPosition")?;
                if let Some(sys) = st.particle_systems.get(key) {
                    Ok((sys.emitter_x, sys.emitter_y))
                } else {
                    Ok((0.0, 0.0))
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ moveTo ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "moveTo",
            lua.create_function(move |_, (id_val, x, y): (LuaValue, f32, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.moveTo")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.move_to(x, y);
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmissionRate / getEmissionRate ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmissionRate",
            lua.create_function(move |_, (id_val, rate): (LuaValue, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.setEmissionRate")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.config.emission_rate = rate;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmissionRate",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.getEmissionRate")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.config.emission_rate)
                    .unwrap_or(0.0))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmissionArea / getEmissionArea ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmissionArea",
            lua.create_function(
                move |_,
                      (id_val, dist, w, h, angle, relative): (
                    LuaValue,
                    String,
                    f32,
                    f32,
                    Option<f32>,
                    Option<bool>,
                )| {
                    let mut st = s.borrow_mut();
                    let key = require_particle_key(
                        &st.particle_systems,
                        &id_val,
                        "luna.particle.setEmissionArea",
                    )?;
                    let sys = particle_system_mut(
                        &mut st.particle_systems,
                        key,
                        "luna.particle.setEmissionArea",
                    )?;
                    sys.config.area_distribution = match dist.as_str() {
                        "none" => AreaDistribution::None,
                        "uniform" => AreaDistribution::Uniform,
                        "normal" => AreaDistribution::Normal,
                        "ellipse" => AreaDistribution::Ellipse,
                        "borderellipse" => AreaDistribution::BorderEllipse,
                        "borderrectangle" => AreaDistribution::BorderRectangle,
                        _ => {
                            return Err(mlua::Error::RuntimeError(format!(
                                "luna.particle.setEmissionArea: unknown distribution '{}'",
                                dist
                            )));
                        }
                    };
                    sys.config.area_width = w;
                    sys.config.area_height = h;
                    sys.config.area_angle = angle.unwrap_or(0.0);
                    sys.config.area_direction_relative = relative.unwrap_or(false);
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmissionArea",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getEmissionArea",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getEmissionArea")?;
                let dist_str = match sys.config.area_distribution {
                    AreaDistribution::None => "none",
                    AreaDistribution::Uniform => "uniform",
                    AreaDistribution::Normal => "normal",
                    AreaDistribution::Ellipse => "ellipse",
                    AreaDistribution::BorderEllipse => "borderellipse",
                    AreaDistribution::BorderRectangle => "borderrectangle",
                };
                Ok((
                    dist_str.to_string(),
                    sys.config.area_width,
                    sys.config.area_height,
                    sys.config.area_angle,
                    sys.config.area_direction_relative,
                ))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setParticleLifetime / getParticleLifetime ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setParticleLifetime",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setParticleLifetime",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setParticleLifetime",
                )?;
                sys.config.lifetime_min = min;
                sys.config.lifetime_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getParticleLifetime",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getParticleLifetime",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getParticleLifetime",
                )?;
                Ok((sys.config.lifetime_min, sys.config.lifetime_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmitterLifetime / getEmitterLifetime ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmitterLifetime",
            lua.create_function(move |_, (id_val, lifetime): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setEmitterLifetime",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setEmitterLifetime",
                )?;
                sys.config.emitter_lifetime = lifetime;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmitterLifetime",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getEmitterLifetime",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getEmitterLifetime",
                )?;
                Ok(sys.config.emitter_lifetime)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSpeed / getSpeed ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpeed",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSpeed")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSpeed")?;
                sys.config.speed_min = min;
                sys.config.speed_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpeed",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSpeed")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSpeed")?;
                Ok((sys.config.speed_min, sys.config.speed_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setDirection / getDirection ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setDirection",
            lua.create_function(move |_, (id_val, dir): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setDirection",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setDirection",
                )?;
                sys.config.direction = dir;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getDirection",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getDirection",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getDirection")?;
                Ok(sys.config.direction)
            })?,
        )?;
    }


    ext::register_ext(lua, &particle, state.clone())?;

    luna.set("particle", particle)?;
    Ok(())
}
