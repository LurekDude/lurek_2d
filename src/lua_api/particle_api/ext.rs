//! Extended particle API registrations (second half of `register`).

#[allow(unused_imports)]
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::resource_keys::TextureKey;
use crate::lua_api::SharedState;
use crate::particle::{
    InsertMode, RelativeMode,
};
use slotmap::Key;

use super::helpers::*;

pub(super) fn register_ext(
    lua: &Lua,
    particle: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    // ÔöÇÔöÇ setSpread / getSpread ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpread",
            lua.create_function(move |_, (id_val, spread): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSpread")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSpread")?;
                sys.config.spread = spread;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpread",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSpread")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSpread")?;
                Ok(sys.config.spread)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setLinearAcceleration / getLinearAcceleration ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setLinearAcceleration",
            lua.create_function(
                move |_, (id_val, xmin, ymin, xmax, ymax): (LuaValue, f32, f32, f32, f32)| {
                    let mut st = s.borrow_mut();
                    let key = require_particle_key(
                        &st.particle_systems,
                        &id_val,
                        "luna.particle.setLinearAcceleration",
                    )?;
                    let sys = particle_system_mut(
                        &mut st.particle_systems,
                        key,
                        "luna.particle.setLinearAcceleration",
                    )?;
                    sys.config.linear_accel_x_min = xmin;
                    sys.config.linear_accel_y_min = ymin;
                    sys.config.linear_accel_x_max = xmax;
                    sys.config.linear_accel_y_max = ymax;
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getLinearAcceleration",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getLinearAcceleration",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getLinearAcceleration",
                )?;
                Ok((
                    sys.config.linear_accel_x_min,
                    sys.config.linear_accel_y_min,
                    sys.config.linear_accel_x_max,
                    sys.config.linear_accel_y_max,
                ))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRadialAcceleration / getRadialAcceleration ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRadialAcceleration",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRadialAcceleration",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRadialAcceleration",
                )?;
                sys.config.radial_accel_min = min;
                sys.config.radial_accel_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getRadialAcceleration",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getRadialAcceleration",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getRadialAcceleration",
                )?;
                Ok((sys.config.radial_accel_min, sys.config.radial_accel_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setTangentialAcceleration / getTangentialAcceleration ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setTangentialAcceleration",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setTangentialAcceleration",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setTangentialAcceleration",
                )?;
                sys.config.tangential_accel_min = min;
                sys.config.tangential_accel_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getTangentialAcceleration",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getTangentialAcceleration",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getTangentialAcceleration",
                )?;
                Ok((
                    sys.config.tangential_accel_min,
                    sys.config.tangential_accel_max,
                ))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setLinearDamping / getLinearDamping ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setLinearDamping",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setLinearDamping",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setLinearDamping",
                )?;
                sys.config.linear_damping_min = min;
                sys.config.linear_damping_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getLinearDamping",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getLinearDamping",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getLinearDamping")?;
                Ok((sys.config.linear_damping_min, sys.config.linear_damping_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSizes / getSizes ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSizes",
            lua.create_function(move |_, args: LuaMultiValue| {
                let mut iter = args.into_iter();
                let id_val = iter.next().ok_or_else(|| {
                    mlua::Error::RuntimeError(
                        "luna.particle.setSizes: expected particle system id".into(),
                    )
                })?;
                let mut sizes = Vec::new();
                for v in iter {
                    if let Some(f) = lua_value_to_f64(&v) {
                        sizes.push(f as f32);
                    }
                }
                if sizes.is_empty() {
                    return Err(mlua::Error::RuntimeError(
                        "luna.particle.setSizes: expected at least one size value".into(),
                    ));
                }
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSizes")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSizes")?;
                sys.config.sizes = sizes;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSizes",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSizes")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSizes")?;
                let tbl = lua.create_table()?;
                for (i, &sz) in sys.config.sizes.iter().enumerate() {
                    tbl.set(i as i32 + 1, sz)?;
                }
                Ok(LuaValue::Table(tbl))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSizeVariation / getSizeVariation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSizeVariation",
            lua.create_function(move |_, (id_val, v): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setSizeVariation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setSizeVariation",
                )?;
                sys.config.size_variation = v.clamp(0.0, 1.0);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSizeVariation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getSizeVariation",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getSizeVariation")?;
                Ok(sys.config.size_variation)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRotation / getRotation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRotation",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRotation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRotation",
                )?;
                sys.config.rotation_min = min;
                sys.config.rotation_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getRotation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getRotation",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getRotation")?;
                Ok((sys.config.rotation_min, sys.config.rotation_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSpin / getSpin ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpin",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSpin")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSpin")?;
                sys.config.spin_min = min;
                sys.config.spin_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpin",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSpin")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSpin")?;
                Ok((sys.config.spin_min, sys.config.spin_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSpinVariation / getSpinVariation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpinVariation",
            lua.create_function(move |_, (id_val, v): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setSpinVariation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setSpinVariation",
                )?;
                sys.config.spin_variation = v.clamp(0.0, 1.0);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpinVariation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getSpinVariation",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getSpinVariation")?;
                Ok(sys.config.spin_variation)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRelativeRotation / hasRelativeRotation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRelativeRotation",
            lua.create_function(move |_, (id_val, enable): (LuaValue, bool)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRelativeRotation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRelativeRotation",
                )?;
                sys.config.relative_rotation = enable;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "hasRelativeRotation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.hasRelativeRotation",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.hasRelativeRotation",
                )?;
                Ok(sys.config.relative_rotation)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setColors / getColors ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setColors",
            lua.create_function(move |_, args: LuaMultiValue| {
                let mut iter = args.into_iter();
                let id_val = iter.next().ok_or_else(|| {
                    mlua::Error::RuntimeError(
                        "luna.particle.setColors: expected particle system id".into(),
                    )
                })?;
                let mut colors = Vec::new();
                for v in iter {
                    if let LuaValue::Table(t) = v {
                        if let Ok(c) = parse_color(&t, 1.0) {
                            colors.push(c);
                        }
                    }
                }
                if colors.is_empty() {
                    return Err(mlua::Error::RuntimeError(
                        "luna.particle.setColors: expected at least one color table".into(),
                    ));
                }
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setColors")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setColors")?;
                sys.config.colors = colors;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getColors",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getColors")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getColors")?;
                let tbl = lua.create_table()?;
                for (i, c) in sys.config.colors.iter().enumerate() {
                    let ct = lua.create_table()?;
                    ct.set(1i32, c[0])?;
                    ct.set(2i32, c[1])?;
                    ct.set(3i32, c[2])?;
                    ct.set(4i32, c[3])?;
                    tbl.set(i as i32 + 1, ct)?;
                }
                Ok(LuaValue::Table(tbl))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setTexture / getTexture ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setTexture",
            lua.create_function(move |_, (id_val, tex_id): (LuaValue, u64)| {
                let tex_key = TextureKey::from(slotmap::KeyData::from_ffi(tex_id));
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setTexture",
                )?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setTexture")?;
                sys.config.texture_id = Some(tex_key);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getTexture",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getTexture",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getTexture")?;
                if let Some(tex) = sys.config.texture_id {
                    Ok(LuaValue::Number(tex.data().as_ffi() as f64))
                } else {
                    Ok(LuaValue::Nil)
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ setOffset / getOffset ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setOffset",
            lua.create_function(move |_, (id_val, ox, oy): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setOffset")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setOffset")?;
                sys.config.offset_x = ox;
                sys.config.offset_y = oy;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getOffset",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getOffset")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getOffset")?;
                Ok((sys.config.offset_x, sys.config.offset_y))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setInsertMode / getInsertMode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setInsertMode",
            lua.create_function(move |_, (id_val, mode): (LuaValue, String)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setInsertMode",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setInsertMode",
                )?;
                sys.config.insert_mode = match mode.as_str() {
                    "top" => InsertMode::Top,
                    "bottom" => InsertMode::Bottom,
                    "random" => InsertMode::Random,
                    _ => {
                        return Err(mlua::Error::RuntimeError(format!(
                            "luna.particle.setInsertMode: unknown mode '{}'",
                            mode
                        )));
                    }
                };
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getInsertMode",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getInsertMode",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getInsertMode")?;
                let mode_str = match sys.config.insert_mode {
                    InsertMode::Top => "top",
                    InsertMode::Bottom => "bottom",
                    InsertMode::Random => "random",
                };
                Ok(mode_str.to_string())
            })?,
        )?;
    }

    // ÔöÇÔöÇ setBufferSize / getBufferSize ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setBufferSize",
            lua.create_function(move |_, (id_val, size): (LuaValue, u32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setBufferSize",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setBufferSize",
                )?;
                sys.config.max_particles = size;
                sys.particles.truncate(size as usize);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getBufferSize",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getBufferSize",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getBufferSize")?;
                Ok(sys.config.max_particles)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setQuads ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setQuads",
            lua.create_function(move |_, (id_val, quads_table): (LuaValue, LuaTable)| {
                let mut quads = Vec::new();
                for i in 1..=256 {
                    match quads_table.get::<_, LuaTable>(i) {
                        Ok(q) => {
                            let x: f32 = q.get(1i32).unwrap_or(0.0);
                            let y: f32 = q.get(2i32).unwrap_or(0.0);
                            let w: f32 = q.get(3i32).unwrap_or(0.0);
                            let h: f32 = q.get(4i32).unwrap_or(0.0);
                            quads.push([x, y, w, h]);
                        }
                        Err(_) => break,
                    }
                }
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setQuads")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setQuads")?;
                sys.config.quads = quads;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ setGravity ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setGravity",
            lua.create_function(move |_, (id_val, gx, gy): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setGravity",
                )?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setGravity")?;
                sys.config.gravity_x = gx;
                sys.config.gravity_y = gy;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getGravity ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getGravity",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getGravity",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getGravity")?;
                Ok((sys.config.gravity_x, sys.config.gravity_y))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setAlphas ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setAlphas",
            lua.create_function(move |_, args: LuaMultiValue| {
                if args.is_empty() {
                    return Err(LuaError::RuntimeError(
                        "luna.particle.setAlphas: expected at least a particle system handle"
                            .into(),
                    ));
                }
                let id_val = &args[0];
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, id_val, "luna.particle.setAlphas")?;
                let mut alphas = Vec::new();
                for v in args.iter().skip(1) {
                    if let Some(n) = lua_value_to_f64(v) {
                        alphas.push(n as f32);
                    }
                }
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setAlphas")?;
                sys.config.alpha_keyframes = alphas;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getAlphas ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getAlphas",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getAlphas")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getAlphas")?;
                let t = lua.create_table()?;
                for (i, a) in sys.config.alpha_keyframes.iter().enumerate() {
                    t.set(i as i32 + 1, *a)?;
                }
                Ok(t)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmissionShape ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmissionShape",
            lua.create_function(
                move |_, (id_val, shape, args): (LuaValue, String, Option<LuaTable>)| {
                    let mut st = s.borrow_mut();
                    let key = require_particle_key(
                        &st.particle_systems,
                        &id_val,
                        "luna.particle.setEmissionShape",
                    )?;
                    let es = parse_emission_shape(&shape, args.as_ref());
                    let sys = particle_system_mut(
                        &mut st.particle_systems,
                        key,
                        "luna.particle.setEmissionShape",
                    )?;
                    sys.config.emission_shape = es;
                    Ok(())
                },
            )?,
        )?;
    }

    // ÔöÇÔöÇ getEmissionShape ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmissionShape",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getEmissionShape",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getEmissionShape")?;
                emission_shape_to_lua(lua, &sys.config.emission_shape)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRelativeMode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRelativeMode",
            lua.create_function(move |_, (id_val, mode): (LuaValue, String)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRelativeMode",
                )?;
                let rm = match mode.to_lowercase().as_str() {
                    "attached" => RelativeMode::Attached,
                    _ => RelativeMode::Detached,
                };
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRelativeMode",
                )?;
                sys.config.relative_mode = rm;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getRelativeMode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getRelativeMode",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getRelativeMode",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getRelativeMode")?;
                Ok(match sys.config.relative_mode {
                    RelativeMode::Attached => "attached".to_string(),
                    RelativeMode::Detached => "detached".to_string(),
                })
            })?,
        )?;
    }

    /// Particle on this ParticleSystem.
    ///
    /// # Returns
    /// The result.
    Ok(())
}
