//! Registers the `luna.light.*` 2D lighting API.
//!
//! Provides Lua bindings for creating and managing 2D point lights
//! and polygon shadow occluders via the `LightWorld` resource pool.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::resource_keys::{LightKey, OccluderKey};
use crate::light::{
    Attenuation, FalloffMode, FlickerConfig, Light2D, LightBlendMode, LightType, Occluder,
    ShadowFilter,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::lua_api::SharedState;
use crate::math::{Color, Vec2};

// ── String ↔ Enum helpers ─────────────────────────────────────────────────

/// Parses a blend mode string into `LightBlendMode`.
fn parse_blend_mode(s: &str) -> LuaResult<LightBlendMode> {
    match s {
        "add" => Ok(LightBlendMode::Add),
        "sub" => Ok(LightBlendMode::Sub),
        "mix" => Ok(LightBlendMode::Mix),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid blend mode '{}', expected 'add', 'sub', or 'mix'",
            s
        ))),
    }
}

/// Converts a `LightBlendMode` to its string representation.
fn blend_mode_to_str(mode: LightBlendMode) -> &'static str {
    match mode {
        LightBlendMode::Add => "add",
        LightBlendMode::Sub => "sub",
        LightBlendMode::Mix => "mix",
    }
}

/// Parses a falloff mode string into `FalloffMode`.
fn parse_falloff(s: &str) -> LuaResult<FalloffMode> {
    match s {
        "linear" => Ok(FalloffMode::Linear),
        "smooth" => Ok(FalloffMode::Smooth),
        "constant" => Ok(FalloffMode::Constant),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid falloff '{}', expected 'linear', 'smooth', or 'constant'",
            s
        ))),
    }
}

/// Converts a `FalloffMode` to its string representation.
fn falloff_to_str(mode: FalloffMode) -> &'static str {
    match mode {
        FalloffMode::Linear => "linear",
        FalloffMode::Smooth => "smooth",
        FalloffMode::Constant => "constant",
    }
}

/// Parses a shadow filter string into `ShadowFilter`.
fn parse_shadow_filter(s: &str) -> LuaResult<ShadowFilter> {
    match s {
        "none" => Ok(ShadowFilter::None),
        "pcf5" => Ok(ShadowFilter::Pcf5),
        "pcf13" => Ok(ShadowFilter::Pcf13),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid shadow filter '{}', expected 'none', 'pcf5', or 'pcf13'",
            s
        ))),
    }
}

/// Converts a `ShadowFilter` to its string representation.
fn shadow_filter_to_str(filter: ShadowFilter) -> &'static str {
    match filter {
        ShadowFilter::None => "none",
        ShadowFilter::Pcf5 => "pcf5",
        ShadowFilter::Pcf13 => "pcf13",
    }
}

/// Parses a light type string into `LightType`.
fn parse_light_type(s: &str) -> LuaResult<LightType> {
    match s {
        "point" => Ok(LightType::Point),
        "directional" => Ok(LightType::Directional),
        "spot" => Ok(LightType::Spot),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid light type '{}', expected 'point', 'directional', or 'spot'",
            s
        ))),
    }
}

/// Converts a `LightType` to its string representation.
fn light_type_to_str(lt: LightType) -> &'static str {
    match lt {
        LightType::Point => "point",
        LightType::Directional => "directional",
        LightType::Spot => "spot",
    }
}

// ── Handle validation ─────────────────────────────────────────────────────

/// Returns a `LuaError` for an invalid or removed light handle.
fn invalid_light_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed light handle",
        function_name
    ))
}

/// Returns a `LuaError` for an invalid or removed occluder handle.
fn invalid_occluder_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed occluder handle",
        function_name
    ))
}

// ── UserData types ────────────────────────────────────────────────────────

/// Lua UserData wrapper for a light resource.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `LightKey`.
#[derive(Clone)]
pub struct LuaLight {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: LightKey,
}

impl LunaType for LuaLight {
    const TYPE_NAME: &'static str = "Light";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setPosition"))?;
            light.x = x;
            light.y = y;
            Ok(())
        });

        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getPosition"))?;
            Ok((light.x, light.y))
        });

        methods.add_method("setRadius", |_, this, r: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setRadius"))?;
            light.radius = r;
            Ok(())
        });

        methods.add_method("getRadius", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getRadius"))?;
            Ok(light.radius)
        });

        methods.add_method(
            "setColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light_handle("Light:setColor"))?;
                light.color = Color::new(r, g, b, a.unwrap_or(1.0));
                Ok(())
            },
        );

        methods.add_method("getColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getColor"))?;
            Ok((light.color.r, light.color.g, light.color.b, light.color.a))
        });

        methods.add_method("setIntensity", |_, this, i: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setIntensity"))?;
            light.intensity = i;
            Ok(())
        });

        methods.add_method("getIntensity", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getIntensity"))?;
            Ok(light.intensity)
        });

        methods.add_method("setEnergy", |_, this, e: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setEnergy"))?;
            light.energy = e;
            Ok(())
        });

        methods.add_method("getEnergy", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getEnergy"))?;
            Ok(light.energy)
        });

        methods.add_method("setBlendMode", |_, this, mode: String| {
            let bm = parse_blend_mode(&mode)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setBlendMode"))?;
            light.blend_mode = bm;
            Ok(())
        });

        methods.add_method("getBlendMode", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getBlendMode"))?;
            Ok(blend_mode_to_str(light.blend_mode).to_string())
        });

        methods.add_method("setFalloff", |_, this, mode: String| {
            let fm = parse_falloff(&mode)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setFalloff"))?;
            light.falloff = fm;
            Ok(())
        });

        methods.add_method("getFalloff", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getFalloff"))?;
            Ok(falloff_to_str(light.falloff).to_string())
        });

        methods.add_method("setShadowEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setShadowEnabled"))?;
            light.shadow_enabled = b;
            Ok(())
        });

        methods.add_method("isShadowEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:isShadowEnabled"))?;
            Ok(light.shadow_enabled)
        });

        methods.add_method(
            "setShadowColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light_handle("Light:setShadowColor"))?;
                light.shadow_color = Color::new(r, g, b, a.unwrap_or(1.0));
                Ok(())
            },
        );

        methods.add_method("getShadowColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getShadowColor"))?;
            Ok((
                light.shadow_color.r,
                light.shadow_color.g,
                light.shadow_color.b,
                light.shadow_color.a,
            ))
        });

        methods.add_method("setShadowFilter", |_, this, filter: String| {
            let sf = parse_shadow_filter(&filter)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setShadowFilter"))?;
            light.shadow_filter = sf;
            Ok(())
        });

        methods.add_method("getShadowFilter", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getShadowFilter"))?;
            Ok(shadow_filter_to_str(light.shadow_filter).to_string())
        });

        methods.add_method("setShadowSmooth", |_, this, s: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setShadowSmooth"))?;
            light.shadow_smooth = s;
            Ok(())
        });

        methods.add_method("getShadowSmooth", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getShadowSmooth"))?;
            Ok(light.shadow_smooth)
        });

        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setLightMask"))?;
            light.light_mask = mask;
            Ok(())
        });

        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getLightMask"))?;
            Ok(light.light_mask)
        });

        methods.add_method("setShadowMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setShadowMask"))?;
            light.shadow_mask = mask;
            Ok(())
        });

        methods.add_method("getShadowMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getShadowMask"))?;
            Ok(light.shadow_mask)
        });

        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setEnabled"))?;
            light.enabled = b;
            Ok(())
        });

        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:isEnabled"))?;
            Ok(light.enabled)
        });

        methods.add_method("remove", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            st.light_world.remove_light(this.key);
            Ok(())
        });

        methods.add_method("isValid", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.light_world.lights.contains_key(this.key))
        });

        // ── New effect methods ────────────────────────────────────────

        methods.add_method("setLightType", |_, this, t: String| {
            let lt = parse_light_type(&t)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setLightType"))?;
            light.light_type = lt;
            Ok(())
        });

        methods.add_method("getLightType", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getLightType"))?;
            Ok(light_type_to_str(light.light_type).to_string())
        });

        methods.add_method("setDirection", |_, this, dir: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setDirection"))?;
            light.direction = dir;
            Ok(())
        });

        methods.add_method("getDirection", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getDirection"))?;
            Ok(light.direction)
        });

        methods.add_method("setInnerAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setInnerAngle"))?;
            light.inner_angle = a;
            Ok(())
        });

        methods.add_method("getInnerAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getInnerAngle"))?;
            Ok(light.inner_angle)
        });

        methods.add_method("setOuterAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setOuterAngle"))?;
            light.outer_angle = a;
            Ok(())
        });

        methods.add_method("getOuterAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getOuterAngle"))?;
            Ok(light.outer_angle)
        });

        methods.add_method("setAttenuation", |_, this, (c, l, q): (f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setAttenuation"))?;
            light.attenuation = Attenuation::new(c, l, q);
            Ok(())
        });

        methods.add_method("getAttenuation", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getAttenuation"))?;
            let a = light.attenuation;
            Ok((a.constant, a.linear, a.quadratic))
        });

        methods.add_method("setFlicker", |_, this, (speed, strength): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setFlicker"))?;
            light.flicker = FlickerConfig::new(speed, strength);
            Ok(())
        });

        methods.add_method("getFlicker", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getFlicker"))?;
            let f = &light.flicker;
            Ok((f.speed, f.strength))
        });

        methods.add_method("setFlickerEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setFlickerEnabled"))?;
            light.flicker.enabled = b;
            Ok(())
        });

        methods.add_method("isFlickerEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:isFlickerEnabled"))?;
            Ok(light.flicker.enabled)
        });

        methods.add_method("setGroupId", |_, this, id: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setGroupId"))?;
            light.group_id = id;
            Ok(())
        });

        methods.add_method("getGroupId", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:getGroupId"))?;
            Ok(light.group_id)
        });

        methods.add_method("setVolumetric", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light_handle("Light:setVolumetric"))?;
            light.volumetric = b;
            Ok(())
        });

        methods.add_method("isVolumetric", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light_handle("Light:isVolumetric"))?;
            Ok(light.volumetric)
        });
    }
}

/// Lua UserData wrapper for an occluder resource.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `OccluderKey`.
#[derive(Clone)]
pub struct LuaOccluder {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: OccluderKey,
}

impl LunaType for LuaOccluder {
    const TYPE_NAME: &'static str = "Occluder";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaOccluder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method("setVertices", |_, this, tbl: LuaTable| {
            let verts = parse_vertex_table(&tbl)?;
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:setVertices"))?;
            occ.set_vertices(verts);
            Ok(())
        });

        methods.add_method("getVertices", |lua, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:getVertices"))?;
            let tbl = lua.create_table()?;
            for (i, v) in occ.get_vertices().iter().enumerate() {
                tbl.set(i * 2 + 1, v.x)?;
                tbl.set(i * 2 + 2, v.y)?;
            }
            Ok(tbl)
        });

        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:setPosition"))?;
            occ.set_position(Vec2::new(x, y));
            Ok(())
        });

        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:getPosition"))?;
            let pos = occ.get_position();
            Ok((pos.x, pos.y))
        });

        methods.add_method("setOpacity", |_, this, o: f32| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:setOpacity"))?;
            occ.opacity = o;
            Ok(())
        });

        methods.add_method("getOpacity", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:getOpacity"))?;
            Ok(occ.opacity)
        });

        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:setLightMask"))?;
            occ.light_mask = mask;
            Ok(())
        });

        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:getLightMask"))?;
            Ok(occ.light_mask)
        });

        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:setEnabled"))?;
            occ.enabled = b;
            Ok(())
        });

        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder_handle("Occluder:isEnabled"))?;
            Ok(occ.enabled)
        });

        methods.add_method("remove", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            st.light_world.remove_occluder(this.key);
            Ok(())
        });

        methods.add_method("isValid", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.light_world.occluders.contains_key(this.key))
        });
    }
}

// ── Vertex parsing ────────────────────────────────────────────────────────

/// Parses a flat Lua table `{x1,y1,x2,y2,...}` into `Vec<Vec2>`.
///
/// # Parameters
/// - `tbl` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<Vec<Vec2>>`.
fn parse_vertex_table(tbl: &LuaTable) -> LuaResult<Vec<Vec2>> {
    let len = tbl.len()? as usize;
    if !(6..=512).contains(&len) || !len.is_multiple_of(2) {
        return Err(LuaError::RuntimeError(format!(
            "vertex table must have an even number of elements (6..=512), got {}",
            len
        )));
    }
    let point_count = len / 2;
    if !(3..=256).contains(&point_count) {
        return Err(LuaError::RuntimeError(format!(
            "vertex count must be 3..=256, got {}",
            point_count
        )));
    }
    let mut verts = Vec::with_capacity(point_count);
    for i in 0..point_count {
        let x: f32 = tbl.get((i * 2 + 1) as i64)?;
        let y: f32 = tbl.get((i * 2 + 2) as i64)?;
        verts.push(Vec2::new(x, y));
    }
    Ok(verts)
}

/// Parses an optional color table `{r, g, b [, a]}` from an opts table field.
fn parse_opt_color(opts: &LuaTable, field: &str) -> LuaResult<Option<Color>> {
    let val: LuaValue = opts.get(field)?;
    match val {
        LuaValue::Table(tbl) => {
            let r: f32 = tbl.get(1i32).unwrap_or(1.0);
            let g: f32 = tbl.get(2i32).unwrap_or(1.0);
            let b: f32 = tbl.get(3i32).unwrap_or(1.0);
            let a: f32 = tbl.get(4i32).unwrap_or(1.0);
            Ok(Some(Color::new(r, g, b, a)))
        }
        LuaValue::Nil => Ok(None),
        _ => Err(LuaError::RuntimeError(format!(
            "expected color table for '{}', got {}",
            field,
            val.type_name()
        ))),
    }
}

// ── Module registration ───────────────────────────────────────────────────

/// Registers the `luna.light.*` 2D lighting API.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let light_table = lua.create_table()?;

    // ── luna.light.newLight(x, y, radius [, opts]) ────────────────────
    {
        let state = state.clone();
        light_table.set(
            "newLight",
            lua.create_function(
                move |_, (x, y, radius, opts): (f32, f32, f32, Option<LuaTable>)| {
                    let mut light = Light2D::new(x, y, radius);

                    if let Some(ref opts) = opts {
                        if let Ok(Some(c)) = parse_opt_color(opts, "color") {
                            light.color = c;
                        }
                        if let Ok(v) = opts.get::<_, f32>("intensity") {
                            light.intensity = v;
                        }
                        if let Ok(v) = opts.get::<_, f32>("energy") {
                            light.energy = v;
                        }
                        if let Ok(s) = opts.get::<_, String>("blend") {
                            light.blend_mode = parse_blend_mode(&s)?;
                        }
                        if let Ok(s) = opts.get::<_, String>("falloff") {
                            light.falloff = parse_falloff(&s)?;
                        }
                        if let Ok(v) = opts.get::<_, bool>("shadowEnabled") {
                            light.shadow_enabled = v;
                        }
                        if let Ok(Some(c)) = parse_opt_color(opts, "shadowColor") {
                            light.shadow_color = c;
                        }
                        if let Ok(s) = opts.get::<_, String>("shadowFilter") {
                            light.shadow_filter = parse_shadow_filter(&s)?;
                        }
                        if let Ok(v) = opts.get::<_, f32>("shadowSmooth") {
                            light.shadow_smooth = v;
                        }
                        if let Ok(v) = opts.get::<_, u16>("lightMask") {
                            light.light_mask = v;
                        }
                        if let Ok(v) = opts.get::<_, u16>("shadowMask") {
                            light.shadow_mask = v;
                        }
                        if let Ok(v) = opts.get::<_, bool>("enabled") {
                            light.enabled = v;
                        }
                        // New effect opts
                        if let Ok(s) = opts.get::<_, String>("type") {
                            light.light_type = parse_light_type(&s)?;
                        }
                        if let Ok(v) = opts.get::<_, f32>("direction") {
                            light.direction = v;
                        }
                        if let Ok(v) = opts.get::<_, f32>("innerAngle") {
                            light.inner_angle = v;
                        }
                        if let Ok(v) = opts.get::<_, f32>("outerAngle") {
                            light.outer_angle = v;
                        }
                        if let Ok(v) = opts.get::<_, u16>("groupId") {
                            light.group_id = v;
                        }
                        if let Ok(v) = opts.get::<_, bool>("volumetric") {
                            light.volumetric = v;
                        }
                        // Flicker opts
                        if let Ok(v) = opts.get::<_, f32>("flickerSpeed") {
                            light.flicker.speed = v;
                            light.flicker.enabled = true;
                        }
                        if let Ok(v) = opts.get::<_, f32>("flickerStrength") {
                            light.flicker.strength = v;
                            light.flicker.enabled = true;
                        }
                        // Attenuation opts
                        if let Ok(v) = opts.get::<_, f32>("attConstant") {
                            light.attenuation.constant = v;
                        }
                        if let Ok(v) = opts.get::<_, f32>("attLinear") {
                            light.attenuation.linear = v;
                        }
                        if let Ok(v) = opts.get::<_, f32>("attQuadratic") {
                            light.attenuation.quadratic = v;
                        }
                    }

                    let mut st = state.borrow_mut();
                    let key = st.light_world.add_light(light);
                    Ok(LuaLight {
                        state: state.clone(),
                        key,
                    })
                },
            )?,
        )?;
    }

    // ── luna.light.newOccluder(vertices [, opts]) ─────────────────────
    {
        let state = state.clone();
        light_table.set(
            "newOccluder",
            lua.create_function(move |_, (tbl, opts): (LuaTable, Option<LuaTable>)| {
                let verts = parse_vertex_table(&tbl)?;
                let mut occ = Occluder::new(verts);

                if let Some(ref opts) = opts {
                    if let Ok(v) = opts.get::<_, f32>("opacity") {
                        occ.opacity = v;
                    }
                    if let Ok(v) = opts.get::<_, u16>("lightMask") {
                        occ.light_mask = v;
                    }
                    if let Ok(v) = opts.get::<_, bool>("enabled") {
                        occ.enabled = v;
                    }
                }

                let mut st = state.borrow_mut();
                let key = st.light_world.add_occluder(occ);
                Ok(LuaOccluder {
                    state: state.clone(),
                    key,
                })
            })?,
        )?;
    }

    // ── luna.light.setAmbient(r, g, b [, a]) ─────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "setAmbient",
            lua.create_function(move |_, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = state.borrow_mut();
                st.light_world.ambient = Color::new(r, g, b, a.unwrap_or(1.0));
                Ok(())
            })?,
        )?;
    }

    // ── luna.light.getAmbient() ──────────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "getAmbient",
            lua.create_function(move |_, ()| {
                let st = state.borrow();
                let c = st.light_world.ambient;
                Ok((c.r, c.g, c.b, c.a))
            })?,
        )?;
    }

    // ── luna.light.setEnabled(enabled) ───────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "setEnabled",
            lua.create_function(move |_, enabled: bool| {
                let mut st = state.borrow_mut();
                st.light_world.enabled = enabled;
                Ok(())
            })?,
        )?;
    }

    // ── luna.light.isEnabled() ───────────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "isEnabled",
            lua.create_function(move |_, ()| {
                let st = state.borrow();
                Ok(st.light_world.enabled)
            })?,
        )?;
    }

    // ── luna.light.getLightCount() ───────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "getLightCount",
            lua.create_function(move |_, ()| {
                let st = state.borrow();
                Ok(st.light_world.light_count())
            })?,
        )?;
    }

    // ── luna.light.getOccluderCount() ────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "getOccluderCount",
            lua.create_function(move |_, ()| {
                let st = state.borrow();
                Ok(st.light_world.occluder_count())
            })?,
        )?;
    }

    // ── luna.light.getMaxLights() ────────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "getMaxLights",
            lua.create_function(move |_, ()| {
                let st = state.borrow();
                Ok(st.light_world.max_lights)
            })?,
        )?;
    }

    // ── luna.light.setMaxLights(n) ───────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "setMaxLights",
            lua.create_function(move |_, n: u16| {
                let mut st = state.borrow_mut();
                st.light_world.max_lights = n.clamp(1, 256);
                Ok(())
            })?,
        )?;
    }

    // ── luna.light.clear() ──────────────────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "clear",
            lua.create_function(move |_, ()| {
                let mut st = state.borrow_mut();
                st.light_world.clear();
                Ok(())
            })?,
        )?;
    }

    // ── luna.light.setGroupEnabled(groupId, enabled) ────────────────
    {
        let state = state.clone();
        light_table.set(
            "setGroupEnabled",
            lua.create_function(move |_, (group_id, enabled): (u16, bool)| {
                let mut st = state.borrow_mut();
                st.light_world.set_group_enabled(group_id, enabled);
                Ok(())
            })?,
        )?;
    }

    // ── luna.light.setGroupIntensity(groupId, intensity) ────────────
    {
        let state = state.clone();
        light_table.set(
            "setGroupIntensity",
            lua.create_function(move |_, (group_id, intensity): (u16, f32)| {
                let mut st = state.borrow_mut();
                st.light_world.set_group_intensity(group_id, intensity);
                Ok(())
            })?,
        )?;
    }

    // ── luna.light.setGroupColor(groupId, r, g, b [, a]) ───────────
    {
        let state = state.clone();
        light_table.set(
            "setGroupColor",
            lua.create_function(
                move |_, (group_id, r, g, b, a): (u16, f32, f32, f32, Option<f32>)| {
                    let mut st = state.borrow_mut();
                    st.light_world
                        .set_group_color(group_id, Color::new(r, g, b, a.unwrap_or(1.0)));
                    Ok(())
                },
            )?,
        )?;
    }

    // ── luna.light.getGroupCount(groupId) ───────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "getGroupCount",
            lua.create_function(move |_, group_id: u16| {
                let st = state.borrow();
                Ok(st.light_world.group_count(group_id))
            })?,
        )?;
    }

    // ── luna.light.advanceFlickers(dt) ──────────────────────────────
    {
        let state = state.clone();
        light_table.set(
            "advanceFlickers",
            lua.create_function(move |_, dt: f32| {
                let mut st = state.borrow_mut();
                st.light_world.advance_flickers(dt);
                Ok(())
            })?,
        )?;
    }

    luna.set("light", light_table)?;
    Ok(())
}
