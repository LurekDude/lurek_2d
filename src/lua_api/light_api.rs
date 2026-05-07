//! `lurek.light` - 2D lighting, shadow occluders, and ambient control.
//!
//! Manages `Light` handles (point / directional / spot) and `Occluder` handles
//! (line-segment shadow casters) within the engine's `LightWorld`. Supports
//! attenuation, blend modes, falloff curves, shadow filtering, flicker configs,
//! cookie textures, colour transitions, and ambient colour control.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::light::transition::LightTransition;
use crate::light::{
    Attenuation, FalloffMode, FlickerConfig, Light2D, LightBlendMode, LightType, Occluder,
    ShadowFilter,
};
use crate::math::{Color, Vec2};
use crate::runtime::resource_keys::{LightKey, OccluderKey};

// -------------------------------------------------------------------------------
// String Enum helpers
// -------------------------------------------------------------------------------

// Parses a blend mode string into `LightBlendMode`.
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

// Converts a `LightBlendMode` to its string representation.
fn blend_mode_to_str(mode: LightBlendMode) -> &'static str {
    match mode {
        LightBlendMode::Add => "add",
        LightBlendMode::Sub => "sub",
        LightBlendMode::Mix => "mix",
    }
}

// Parses a falloff mode string into `FalloffMode`.
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

// Converts a `FalloffMode` to its string representation.
fn falloff_to_str(mode: FalloffMode) -> &'static str {
    match mode {
        FalloffMode::Linear => "linear",
        FalloffMode::Smooth => "smooth",
        FalloffMode::Constant => "constant",
    }
}

// Parses a shadow filter string into `ShadowFilter`.
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

// Converts a `ShadowFilter` to its string representation.
fn shadow_filter_to_str(filter: ShadowFilter) -> &'static str {
    match filter {
        ShadowFilter::None => "none",
        ShadowFilter::Pcf5 => "pcf5",
        ShadowFilter::Pcf13 => "pcf13",
    }
}

// Parses a light type string into `LightType`.
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

// Converts a `LightType` to its string representation.
fn light_type_to_str(lt: LightType) -> &'static str {
    match lt {
        LightType::Point => "point",
        LightType::Directional => "directional",
        LightType::Spot => "spot",
    }
}

// -------------------------------------------------------------------------------
// Boundary parsing helpers
// -------------------------------------------------------------------------------

// Returns a `LuaError` for an invalid or removed light handle.
fn invalid_light(method: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed light handle",
        method
    ))
}

// Returns a `LuaError` for an invalid or removed occluder handle.
fn invalid_occluder(method: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed occluder handle",
        method
    ))
}

// Parses an optional color table `{r, g, b [, a]}` from an opts table field.
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

// Applies optional settings from a Lua opts table to a `Light2D`.
fn apply_light_opts(light: &mut Light2D, opts: &LuaTable) -> LuaResult<()> {
    if let Ok(Some(c)) = parse_opt_color(opts, "color") {
        light.set_color(c);
    }
    if let Ok(v) = opts.get::<_, f32>("intensity") {
        light.set_intensity(v);
    }
    if let Ok(v) = opts.get::<_, f32>("energy") {
        light.set_energy(v);
    }
    if let Ok(s) = opts.get::<_, String>("blend") {
        light.set_blend_mode(parse_blend_mode(&s)?);
    }
    if let Ok(s) = opts.get::<_, String>("falloff") {
        light.set_falloff(parse_falloff(&s)?);
    }
    if let Ok(v) = opts.get::<_, bool>("shadowEnabled") {
        light.set_shadow_enabled(v);
    }
    if let Ok(Some(c)) = parse_opt_color(opts, "shadowColor") {
        light.set_shadow_color(c);
    }
    if let Ok(s) = opts.get::<_, String>("shadowFilter") {
        light.set_shadow_filter(parse_shadow_filter(&s)?);
    }
    if let Ok(v) = opts.get::<_, f32>("shadowSmooth") {
        light.set_shadow_smooth(v);
    }
    if let Ok(v) = opts.get::<_, f32>("shadowSoftness") {
        light.set_shadow_softness(v);
    }
    if let Ok(v) = opts.get::<_, u16>("lightMask") {
        light.set_light_mask(v);
    }
    if let Ok(v) = opts.get::<_, u16>("shadowMask") {
        light.set_shadow_mask(v);
    }
    if let Ok(v) = opts.get::<_, bool>("enabled") {
        light.set_enabled(v);
    }
    if let Ok(s) = opts.get::<_, String>("type") {
        light.set_light_type(parse_light_type(&s)?);
    }
    if let Ok(v) = opts.get::<_, f32>("direction") {
        light.set_direction(v);
    }
    if let Ok(v) = opts.get::<_, f32>("innerAngle") {
        light.set_inner_angle(v);
    }
    if let Ok(v) = opts.get::<_, f32>("outerAngle") {
        light.set_outer_angle(v);
    }
    if let Ok(v) = opts.get::<_, u16>("groupId") {
        light.set_group_id(v);
    }
    if let Ok(v) = opts.get::<_, bool>("volumetric") {
        light.set_volumetric(v);
    }
    if let Ok(v) = opts.get::<_, f32>("flickerSpeed") {
        light.flicker_mut().speed = v;
        light.flicker_mut().enabled = true;
    }
    if let Ok(v) = opts.get::<_, f32>("flickerStrength") {
        light.flicker_mut().strength = v;
        light.flicker_mut().enabled = true;
    }
    if let Ok(path) = opts.get::<_, String>("normalMap") {
        light.set_normal_map_path(path);
    }
    if let Ok(v) = opts.get::<_, f32>("normalStrength") {
        light.set_normal_strength(v);
    }
    if let Ok(v) = opts.get::<_, f32>("attConstant") {
        light.set_attenuation(Attenuation::new(
            v,
            light.get_attenuation().linear,
            light.get_attenuation().quadratic,
        ));
    }
    if let Ok(v) = opts.get::<_, f32>("attLinear") {
        light.set_attenuation(Attenuation::new(
            light.get_attenuation().constant,
            v,
            light.get_attenuation().quadratic,
        ));
    }
    if let Ok(v) = opts.get::<_, f32>("attQuadratic") {
        light.set_attenuation(Attenuation::new(
            light.get_attenuation().constant,
            light.get_attenuation().linear,
            v,
        ));
    }
    Ok(())
}

// Applies optional settings from a Lua opts table to an `Occluder`.
fn apply_occluder_opts(occ: &mut Occluder, opts: &LuaTable) -> LuaResult<()> {
    if let Ok(v) = opts.get::<_, f32>("opacity") {
        occ.set_opacity(v);
    }
    if let Ok(v) = opts.get::<_, u16>("lightMask") {
        occ.set_light_mask(v);
    }
    if let Ok(v) = opts.get::<_, bool>("enabled") {
        occ.set_enabled(v);
    }
    Ok(())
}

// -------------------------------------------------------------------------------
// LuaLight UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a light resource stored in [`LightWorld`].
#[derive(Clone)]
pub struct LuaLight {
    state: Rc<RefCell<SharedState>>,
    key: LightKey,
    /// Active color/intensity/radius transition, if any.
    transition: RefCell<Option<LightTransition>>,
    /// Texture path for cookie (light mask) projection, if any.
    cookie_path: RefCell<Option<String>>,
}

impl LuaUserData for LuaLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setPosition --
        /// Sets the light's world-space position.
        /// @param | x | number | World-space X position.
        /// @param | y | number | World-space Y position.
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setPosition"))?;
            light.set_position(x, y);
            Ok(())
        });

        // -- getPosition --
        /// Returns the light's world-space position.
        /// @return | number | World-space X position.
        /// @return | number | World-space Y position.
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getPosition"))?;
            Ok(light.get_position())
        });

        // -- setRadius --
        /// Sets the light's influence radius.
        /// @param | r | number | Light radius.
        /// @return | nil | No value is returned.
        methods.add_method("setRadius", |_, this, r: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setRadius"))?;
            light.set_radius(r);
            Ok(())
        });

        // -- getRadius --
        /// Returns the light's influence radius.
        /// @return | number | Light radius.
        methods.add_method("getRadius", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getRadius"))?;
            Ok(light.get_radius())
        });

        // -- setColor --
        /// Sets the light's tint color.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number? | Optional alpha channel.
        /// @return | nil | No value is returned.
        methods.add_method("setColor", |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setColor"))?;
                light.set_color(Color::new(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        );

        // -- getColor --
        /// Returns the light's tint color as (r, g, b, a).
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getColor"))?;
            let c = light.get_color();
            Ok((c.r, c.g, c.b, c.a))
        });

        // -- setIntensity --
        /// Sets the brightness multiplier.
        /// @param | i | number | Intensity multiplier.
        /// @return | nil | No value is returned.
        methods.add_method("setIntensity", |_, this, i: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setIntensity"))?;
            light.set_intensity(i);
            Ok(())
        });

        // -- getIntensity --
        /// Returns the brightness multiplier.
        /// @return | number | Intensity multiplier.
        methods.add_method("getIntensity", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getIntensity"))?;
            Ok(light.get_intensity())
        });

        // -- setEnergy --
        /// Sets the energy scaling factor.
        /// @param | e | number | Energy scaling factor.
        /// @return | nil | No value is returned.
        methods.add_method("setEnergy", |_, this, e: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setEnergy"))?;
            light.set_energy(e);
            Ok(())
        });

        // -- getEnergy --
        /// Returns the energy scaling factor.
        /// @return | number | Energy scaling factor.
        methods.add_method("getEnergy", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getEnergy"))?;
            Ok(light.get_energy())
        });

        // -- setBlendMode --
        /// Sets the blend mode ('add', 'sub', or 'mix').
        /// @param | mode | string | Blend mode name.
        /// @return | nil | No value is returned.
        methods.add_method("setBlendMode", |_, this, mode: String| {
            let bm = parse_blend_mode(&mode)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setBlendMode"))?;
            light.set_blend_mode(bm);
            Ok(())
        });

        // -- getBlendMode --
        /// Returns the blend mode as a string.
        /// @return | string | Blend mode name.
        methods.add_method("getBlendMode", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getBlendMode"))?;
            Ok(blend_mode_to_str(light.get_blend_mode()).to_string())
        });

        // -- setFalloff --
        /// Sets the falloff mode ('linear', 'smooth', or 'constant').
        /// @param | mode | string | Falloff mode name.
        /// @return | nil | No value is returned.
        methods.add_method("setFalloff", |_, this, mode: String| {
            let fm = parse_falloff(&mode)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setFalloff"))?;
            light.set_falloff(fm);
            Ok(())
        });

        // -- getFalloff --
        /// Returns the falloff mode as a string.
        /// @return | string | Falloff mode name.
        methods.add_method("getFalloff", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getFalloff"))?;
            Ok(falloff_to_str(light.get_falloff()).to_string())
        });

        // -- setShadowEnabled --
        /// Sets whether this light casts shadows.
        /// @param | enabled | boolean | Whether shadows should be enabled.
        /// @return | nil | No value is returned.
        methods.add_method("setShadowEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowEnabled"))?;
            light.set_shadow_enabled(b);
            Ok(())
        });

        // -- isShadowEnabled --
        /// Returns whether this light casts shadows.
        /// @return | boolean | True if shadows are enabled.
        methods.add_method("isShadowEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isShadowEnabled"))?;
            Ok(light.is_shadow_enabled())
        });

        // -- setShadowColor --
        /// Sets the shadow region color.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number? | Optional alpha channel.
        /// @return | nil | No value is returned.
        methods.add_method("setShadowColor", |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setShadowColor"))?;
                light.set_shadow_color(Color::new(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        );

        // -- getShadowColor --
        /// Returns the shadow region color as (r, g, b, a).
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getShadowColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowColor"))?;
            let c = light.get_shadow_color();
            Ok((c.r, c.g, c.b, c.a))
        });

        // -- setShadowFilter --
        /// Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
        /// @param | filter | string | Shadow filter name.
        /// @return | nil | No value is returned.
        methods.add_method("setShadowFilter", |_, this, filter: String| {
            let sf = parse_shadow_filter(&filter)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowFilter"))?;
            light.set_shadow_filter(sf);
            Ok(())
        });

        // -- getShadowFilter --
        /// Returns the shadow edge filter as a string.
        /// @return | string | Shadow filter name.
        methods.add_method("getShadowFilter", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowFilter"))?;
            Ok(shadow_filter_to_str(light.get_shadow_filter()).to_string())
        });

        // -- setShadowSmooth --
        /// Sets the shadow edge smoothing factor.
        /// @param | smooth | number | Shadow smoothing factor.
        /// @return | nil | No value is returned.
        methods.add_method("setShadowSmooth", |_, this, s: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowSmooth"))?;
            light.set_shadow_smooth(s);
            Ok(())
        });

        // -- getShadowSmooth --
        /// Returns the shadow edge smoothing factor.
        /// @return | number | Shadow smoothing factor.
        methods.add_method("getShadowSmooth", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowSmooth"))?;
            Ok(light.get_shadow_smooth())
        });

        // -- setShadowSoftness --
        /// Sets the penumbra softness multiplier for shadow edges.
        /// @param | softness | number | Penumbra softness multiplier.
        /// @return | nil | No value is returned.
        methods.add_method("setShadowSoftness", |_, this, softness: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowSoftness"))?;
            light.set_shadow_softness(softness);
            Ok(())
        });

        // -- getShadowSoftness --
        /// Returns the penumbra softness multiplier for shadow edges.
        /// @return | number | Penumbra softness multiplier.
        methods.add_method("getShadowSoftness", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowSoftness"))?;
            Ok(light.get_shadow_softness())
        });

        // -- setLightMask --
        /// Sets the light interaction bitmask.
        /// @param | mask | integer | Light interaction bitmask.
        /// @return | nil | No value is returned.
        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setLightMask"))?;
            light.set_light_mask(mask);
            Ok(())
        });

        // -- getLightMask --
        /// Returns the light interaction bitmask.
        /// @return | integer | Light interaction bitmask.
        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getLightMask"))?;
            Ok(light.get_light_mask())
        });

        // -- setShadowMask --
        /// Sets the shadow casting bitmask.
        /// @param | mask | integer | Shadow casting bitmask.
        /// @return | nil | No value is returned.
        methods.add_method("setShadowMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowMask"))?;
            light.set_shadow_mask(mask);
            Ok(())
        });

        // -- getShadowMask --
        /// Returns the shadow casting bitmask.
        /// @return | integer | Shadow casting bitmask.
        methods.add_method("getShadowMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowMask"))?;
            Ok(light.get_shadow_mask())
        });

        // -- setEnabled --
        /// Sets whether this light is active.
        /// @param | enabled | boolean | Whether the light should be active.
        /// @return | nil | No value is returned.
        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setEnabled"))?;
            light.set_enabled(b);
            Ok(())
        });

        // -- isEnabled --
        /// Returns whether this light is active.
        /// @return | boolean | True if the light is active.
        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isEnabled"))?;
            Ok(light.is_enabled())
        });

        // -- setLightType --
        /// Sets the geometric light type ('point', 'directional', or 'spot').
        /// @param | t | string | Light type name.
        /// @return | nil | No value is returned.
        methods.add_method("setLightType", |_, this, t: String| {
            let lt = parse_light_type(&t)?;
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setLightType"))?;
            light.set_light_type(lt);
            Ok(())
        });

        // -- getLightType --
        /// Returns the geometric light type as a string.
        /// @return | string | Light type name.
        methods.add_method("getLightType", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getLightType"))?;
            Ok(light_type_to_str(light.get_light_type()).to_string())
        });

        // -- setDirection --
        /// Sets the direction angle in radians.
        /// @param | dir | number | Direction angle in radians.
        /// @return | nil | No value is returned.
        methods.add_method("setDirection", |_, this, dir: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setDirection"))?;
            light.set_direction(dir);
            Ok(())
        });

        // -- getDirection --
        /// Returns the direction angle in radians.
        /// @return | number | Direction angle in radians.
        methods.add_method("getDirection", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getDirection"))?;
            Ok(light.get_direction())
        });

        // -- setInnerAngle --
        /// Sets the inner cone angle in radians for spot lights.
        /// @param | angle | number | Inner cone angle in radians.
        /// @return | nil | No value is returned.
        methods.add_method("setInnerAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setInnerAngle"))?;
            light.set_inner_angle(a);
            Ok(())
        });

        // -- getInnerAngle --
        /// Returns the inner cone angle in radians.
        /// @return | number | Inner cone angle in radians.
        methods.add_method("getInnerAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getInnerAngle"))?;
            Ok(light.get_inner_angle())
        });

        // -- setOuterAngle --
        /// Sets the outer cone angle in radians for spot lights.
        /// @param | angle | number | Outer cone angle in radians.
        /// @return | nil | No value is returned.
        methods.add_method("setOuterAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setOuterAngle"))?;
            light.set_outer_angle(a);
            Ok(())
        });

        // -- getOuterAngle --
        /// Returns the outer cone angle in radians.
        /// @return | number | Outer cone angle in radians.
        methods.add_method("getOuterAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getOuterAngle"))?;
            Ok(light.get_outer_angle())
        });

        // -- setAttenuation --
        /// Sets the custom attenuation coefficients (constant, linear, quadratic).
        /// @param | c | number | Constant attenuation factor.
        /// @param | l | number | Linear attenuation factor.
        /// @param | q | number | Quadratic attenuation factor.
        /// @return | nil | No value is returned.
        methods.add_method("setAttenuation", |_, this, (c, l, q): (f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setAttenuation"))?;
            light.set_attenuation(Attenuation::new(c, l, q));
            Ok(())
        });

        // -- getAttenuation --
        /// Returns the custom attenuation coefficients as (constant, linear, quadratic).
        /// @return | number | Constant attenuation factor.
        /// @return | number | Linear attenuation factor.
        /// @return | number | Quadratic attenuation factor.
        methods.add_method("getAttenuation", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getAttenuation"))?;
            let a = light.get_attenuation();
            Ok((a.constant, a.linear, a.quadratic))
        });

        // -- setFlicker --
        /// Sets the flicker effect speed and strength (enables flicker).
        /// @param | speed | number | Flicker speed.
        /// @param | strength | number | Flicker strength.
        /// @return | nil | No value is returned.
        methods.add_method("setFlicker", |_, this, (speed, strength): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            {
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setFlicker"))?;
                *light.flicker_mut() = FlickerConfig::new(speed, strength);
            }
            st.light_world.reindex_flickers();
            Ok(())
        });

        // -- getFlicker --
        /// Returns the flicker effect speed and strength.
        /// @return | number | Flicker speed.
        /// @return | number | Flicker strength.
        methods.add_method("getFlicker", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getFlicker"))?;
            let f = light.flicker();
            Ok((f.speed, f.strength))
        });

        // -- setFlickerEnabled --
        /// Sets whether the flicker effect is active.
        /// @param | enabled | boolean | Whether flicker should be enabled.
        /// @return | nil | No value is returned.
        methods.add_method("setFlickerEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            {
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setFlickerEnabled"))?;
                light.flicker_mut().enabled = b;
            }
            st.light_world.reindex_flickers();
            Ok(())
        });

        // -- isFlickerEnabled --
        /// Returns whether the flicker effect is active.
        /// @return | boolean | True if flicker is enabled.
        methods.add_method("isFlickerEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isFlickerEnabled"))?;
            Ok(light.flicker().enabled)
        });

        // -- setGroupId --
        /// Sets the group identifier for batch operations.
        /// @param | id | integer | Group identifier.
        /// @return | nil | No value is returned.
        methods.add_method("setGroupId", |_, this, id: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setGroupId"))?;
            light.set_group_id(id);
            Ok(())
        });

        // -- getGroupId --
        /// Returns the group identifier.
        /// @return | integer | Group identifier.
        methods.add_method("getGroupId", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getGroupId"))?;
            Ok(light.get_group_id())
        });

        // -- setVolumetric --
        /// Sets whether this light hints at volumetric scattering.
        /// @param | enabled | boolean | Whether volumetric scattering should be enabled.
        /// @return | nil | No value is returned.
        methods.add_method("setVolumetric", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setVolumetric"))?;
            light.set_volumetric(b);
            Ok(())
        });

        // -- isVolumetric --
        /// Returns whether this light hints at volumetric scattering.
        /// @return | boolean | True if volumetric scattering is enabled.
        methods.add_method("isVolumetric", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isVolumetric"))?;
            Ok(light.is_volumetric())
        });

        // -- remove --
        /// Removes this light from the world.
        /// @return | nil | No value is returned.
        methods.add_method("remove", |_, this, ()| {
            this.state.borrow_mut().light_world.remove_light(this.key);
            Ok(())
        });

        // -- isValid --
        /// Returns whether this light handle is still valid.
        /// @return | boolean | True if the handle is still valid.
        methods.add_method("isValid", |_, this, ()| {
            Ok(this
                .state
                .borrow()
                .light_world
                .lights
                .contains_key(this.key))
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return | string | Debug string representation.
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let st = this.state.borrow();
            match st.light_world.get_light(this.key) {
                Some(l) => Ok(format!("Light({}, {}, r={})", l.x, l.y, l.radius)),
                None => Ok("Light(invalid)".to_string()),
            }
        });

        // -- addFlicker --
        /// Sets a flicker effect from an intensity range and frequency.
        /// @param | min | number | Lower intensity multiplier.
        /// @param | max | number | Upper intensity multiplier.
        /// @param | hz | number | Oscillation frequency in cycles per second.
        /// @return | nil | No value is returned.
        methods.add_method("addFlicker", |_, this, (min, max, hz): (f32, f32, f32)| {
            let strength = ((max - min) / 2.0).abs();
            let speed = hz * std::f32::consts::TAU;
            let mut st = this.state.borrow_mut();
            {
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:addFlicker"))?;
                *light.flicker_mut() = FlickerConfig::new(speed, strength);
            }
            st.light_world.reindex_flickers();
            Ok(())
        });

        // -- transitionTo --
        /// Starts a smooth transition toward the target light properties.
        /// @param | target | table | Target fields such as `color`, `intensity`, and `radius`.
        /// @param | duration | number | Transition duration in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("transitionTo", |_, this, (target, duration): (LuaTable, f32)| {
                let st = this.state.borrow();
                let light = st
                    .light_world
                    .get_light(this.key)
                    .ok_or_else(|| invalid_light("Light:transitionTo"))?;
                let from_color = [light.color.r, light.color.g, light.color.b, light.color.a];
                let from_intensity = light.intensity;
                let from_radius = light.radius;
                drop(st);
                let to_color: [f32; 4] = if let Ok(ct) = target.get::<_, LuaTable>("color") {
                    [
                        ct.get::<_, f32>(1).unwrap_or(from_color[0]),
                        ct.get::<_, f32>(2).unwrap_or(from_color[1]),
                        ct.get::<_, f32>(3).unwrap_or(from_color[2]),
                        ct.get::<_, f32>(4).unwrap_or(from_color[3]),
                    ]
                } else {
                    from_color
                };
                let to_intensity = target.get::<_, f32>("intensity").unwrap_or(from_intensity);
                let to_radius = target.get::<_, f32>("radius").unwrap_or(from_radius);
                *this.transition.borrow_mut() = Some(LightTransition::new(
                    from_color,
                    to_color,
                    from_intensity,
                    to_intensity,
                    from_radius,
                    to_radius,
                    duration,
                ));
                Ok(())
            },
        );

        // -- updateTransition --
        /// Advances the active transition and applies interpolated values.
        /// @param | dt | number | Frame delta in seconds.
        /// @return | boolean | True while the transition is still running.
        methods.add_method("updateTransition", |_, this, dt: f32| {
            let result = this
                .transition
                .borrow_mut()
                .as_mut()
                .and_then(|t| t.update(dt));
            if let Some((color, intensity, radius)) = result {
                let mut st = this.state.borrow_mut();
                if let Some(light) = st.light_world.get_light_mut(this.key) {
                    light.color.r = color[0];
                    light.color.g = color[1];
                    light.color.b = color[2];
                    light.color.a = color[3];
                    light.intensity = intensity;
                    light.set_radius(radius);
                }
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- stopTransition --
        /// Cancels the active light transition.
        /// @return | nil | No value is returned.
        methods.add_method("stopTransition", |_, this, ()| {
            this.transition.borrow_mut().take();
            Ok(())
        });

        // -- transitionProgress --
        /// Returns the fractional progress of the active transition.
        /// @return | number | Transition progress from 0 to 1.
        methods.add_method("transitionProgress", |_, this, ()| {
            Ok(this
                .transition
                .borrow()
                .as_ref()
                .map(|t| t.progress())
                .unwrap_or(1.0))
        });

        // -- setCookie --
        /// Sets the texture path used as a light cookie for projection.
        /// @param | path | string | Cookie texture path.
        /// @return | nil | No value is returned.
        methods.add_method("setCookie", |_, this, path: String| {
            *this.cookie_path.borrow_mut() = Some(path);
            Ok(())
        });

        // -- getCookie --
        /// Returns the current cookie texture path, or `nil` if unset.
        /// @return | string | Cookie texture path, or nil if unset.
        methods.add_method("getCookie", |_, this, ()| {
            Ok(this.cookie_path.borrow().clone())
        });

        // -- clearCookie --
        /// Removes the cookie texture assignment.
        /// @return | nil | No value is returned.
        methods.add_method("clearCookie", |_, this, ()| {
            this.cookie_path.borrow_mut().take();
            Ok(())
        });

        // -- setNormalMap --
        /// Sets the normal-map texture path hint used by plugin renderers.
        /// @param | path | string | Normal-map texture path.
        /// @return | nil | No value is returned.
        methods.add_method("setNormalMap", |_, this, path: String| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setNormalMap"))?;
            light.set_normal_map_path(path);
            Ok(())
        });

        // -- getNormalMap --
        /// Returns the normal-map texture path hint, or nil when unset.
        /// @return | string | Normal-map texture path, or nil when unset.
        methods.add_method("getNormalMap", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getNormalMap"))?;
            Ok(light.get_normal_map_path().map(str::to_string))
        });

        // -- clearNormalMap --
        /// Clears the normal-map texture path hint.
        /// @return | nil | No value is returned.
        methods.add_method("clearNormalMap", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:clearNormalMap"))?;
            light.clear_normal_map_path();
            Ok(())
        });

        // -- setNormalStrength --
        /// Sets the normal-map response strength multiplier.
        /// @param | strength | number | Normal-map response strength.
        /// @return | nil | No value is returned.
        methods.add_method("setNormalStrength", |_, this, strength: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setNormalStrength"))?;
            light.set_normal_strength(strength);
            Ok(())
        });

        // -- getNormalStrength --
        /// Returns the normal-map response strength multiplier.
        /// @return | number | Normal-map response strength.
        methods.add_method("getNormalStrength", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getNormalStrength"))?;
            Ok(light.get_normal_strength())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LLight"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to test.
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLight" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaOccluder UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to an occluder resource stored in [`LightWorld`].
#[derive(Clone)]
pub struct LuaOccluder {
    state: Rc<RefCell<SharedState>>,
    key: OccluderKey,
}

impl LuaUserData for LuaOccluder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setVertices --
        /// Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
        /// @param | vertices | table | Flat vertex coordinate table.
        /// @return | nil | No value is returned.
        methods.add_method("setVertices", |_, this, tbl: LuaTable| {
            let flat: Vec<f32> = tbl.sequence_values::<f32>().collect::<LuaResult<_>>()?;
            let tmp = Occluder::from_flat_coords(&flat).map_err(LuaError::RuntimeError)?;
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setVertices"))?;
            occ.set_vertices(tmp.vertices);
            Ok(())
        });

        // -- getVertices --
        /// Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
        /// @return | table | Flat vertex coordinate table.
        methods.add_method("getVertices", |lua, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getVertices"))?;
            let tbl = lua.create_table()?;
            for (i, v) in occ.get_vertices().iter().enumerate() {
                tbl.set(i * 2 + 1, v.x)?;
                tbl.set(i * 2 + 2, v.y)?;
            }
            Ok(tbl)
        });

        // -- setPosition --
        /// Sets the translation offset applied to all vertices.
        /// @param | x | number | World-space X offset.
        /// @param | y | number | World-space Y offset.
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setPosition"))?;
            occ.set_position(Vec2::new(x, y));
            Ok(())
        });

        // -- getPosition --
        /// Returns the translation offset as (x, y).
        /// @return | number | Translation X offset.
        /// @return | number | Translation Y offset.
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getPosition"))?;
            let pos = occ.get_position();
            Ok((pos.x, pos.y))
        });

        // -- setOpacity --
        /// Sets the shadow opacity (0.0-1.0).
        /// @param | opacity | number | Shadow opacity from 0.0 to 1.0.
        /// @return | nil | No value is returned.
        methods.add_method("setOpacity", |_, this, o: f32| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setOpacity"))?;
            occ.set_opacity(o);
            Ok(())
        });

        // -- getOpacity --
        /// Returns the shadow opacity.
        /// @return | number | Shadow opacity.
        methods.add_method("getOpacity", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getOpacity"))?;
            Ok(occ.get_opacity())
        });

        // -- setLightMask --
        /// Sets the light interaction bitmask.
        /// @param | mask | integer | Light interaction bitmask.
        /// @return | nil | No value is returned.
        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setLightMask"))?;
            occ.set_light_mask(mask);
            Ok(())
        });

        // -- getLightMask --
        /// Returns the light interaction bitmask.
        /// @return | integer | Light interaction bitmask.
        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getLightMask"))?;
            Ok(occ.get_light_mask())
        });

        // -- setEnabled --
        /// Sets whether this occluder is active.
        /// @param | enabled | boolean | Whether the occluder should be active.
        /// @return | nil | No value is returned.
        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setEnabled"))?;
            occ.set_enabled(b);
            Ok(())
        });

        // -- isEnabled --
        /// Returns whether this occluder is active.
        /// @return | boolean | True if the occluder is active.
        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:isEnabled"))?;
            Ok(occ.is_enabled())
        });

        // -- remove --
        /// Removes this occluder from the world.
        /// @return | nil | No value is returned.
        methods.add_method("remove", |_, this, ()| {
            this.state
                .borrow_mut()
                .light_world
                .remove_occluder(this.key);
            Ok(())
        });

        // -- isValid --
        /// Returns whether this occluder handle is still valid.
        /// @return | boolean | True if the handle is still valid.
        methods.add_method("isValid", |_, this, ()| {
            Ok(this
                .state
                .borrow()
                .light_world
                .occluders
                .contains_key(this.key))
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return | string | Debug string representation.
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let st = this.state.borrow();
            match st.light_world.get_occluder(this.key) {
                Some(o) => Ok(format!("Occluder({} verts)", o.get_vertices().len())),
                None => Ok("Occluder(invalid)".to_string()),
            }
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LOccluder"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to test.
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LOccluder" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.light` API table with the Lua VM.
/// @param | lua | Lua | Active Lua state.
/// @param | lurek | table | Root `lurek` table.
/// @param | state | Rc<RefCell<SharedState>> | Shared engine state.
/// @return | nil | No value is returned.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newLight --
    /// Creates a new light at (x, y) with the given radius and optional settings.
    /// @param | x | number | World-space X position.
    /// @param | y | number | World-space Y position.
    /// @param | radius | number | Light radius.
    /// @param | opts | table? | Optional light settings table.
    /// @return | LLight | Created light handle.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("newLight", lua.create_function(
            move |_, (x, y, radius, opts): (f32, f32, f32, Option<LuaTable>)| {
                let mut light = Light2D::new(x, y, radius);
                if let Some(ref opts) = opts {
                    apply_light_opts(&mut light, opts)?;
                }
                let mut st = s.borrow_mut();
                let key = st.light_world.add_light(light);
                st.light_world.reindex_flickers();
                Ok(LuaLight {
                    state: s.clone(),
                    key,
                    transition: RefCell::new(None),
                    cookie_path: RefCell::new(None),
                })
            },
        )?,
    )?;

    // -- newOccluder --
    /// Creates a new shadow occluder from a vertex table and optional settings.
    /// @param | vertices | table | Flat vertex coordinate table.
    /// @param | opts | table? | Optional occluder settings table.
    /// @return | LOccluder | Created occluder handle.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("newOccluder", lua.create_function(move |_, (vtbl, opts): (LuaTable, Option<LuaTable>)| {
            let flat: Vec<f32> = vtbl.sequence_values::<f32>().collect::<LuaResult<_>>()?;
            let mut occ = Occluder::from_flat_coords(&flat).map_err(LuaError::RuntimeError)?;
            if let Some(ref opts) = opts {
                apply_occluder_opts(&mut occ, opts)?;
            }
            let key = s.borrow_mut().light_world.add_occluder(occ);
            Ok(LuaOccluder {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // -- setAmbient --
    /// Sets the global ambient light color.
    /// @param | r | number | Red channel.
    /// @param | g | number | Green channel.
    /// @param | b | number | Blue channel.
    /// @param | a | number? | Optional alpha channel.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("setAmbient", lua.create_function(move |_, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
            s.borrow_mut().light_world.ambient = Color::new(r, g, b, a.unwrap_or(1.0));
            Ok(())
        })?,
    )?;

    // -- getAmbient --
    /// Returns the global ambient light color as (r, g, b, a).
    /// @return | number | Ambient red component.
    /// @return | number | Ambient green component.
    /// @return | number | Ambient blue component.
    /// @return | number | Ambient alpha component.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getAmbient", lua.create_function(move |_, ()| {
            let c = s.borrow().light_world.ambient;
            Ok((c.r, c.g, c.b, c.a))
        })?,
    )?;

    // -- setEnabled --
    /// Sets whether the lighting system is active.
    /// @param | enabled | boolean | Whether the lighting system should be active.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("setEnabled", lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().light_world.enabled = enabled;
            Ok(())
        })?,
    )?;

    // -- isEnabled --
    /// Returns whether the lighting system is active.
    /// @return | boolean | True if the lighting system is active.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("isEnabled", lua.create_function(move |_, ()| Ok(s.borrow().light_world.enabled))?,
    )?;

    // -- getLightCount --
    /// Returns the number of lights in the world.
    /// @return | integer | Light count.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getLightCount", lua.create_function(move |_, ()| Ok(s.borrow().light_world.light_count()))?,
    )?;

    // -- getOccluderCount --
    /// Returns the number of occluders in the world.
    /// @return | integer | Occluder count.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getOccluderCount", lua.create_function(move |_, ()| Ok(s.borrow().light_world.occluder_count()))?,
    )?;

    // -- getMaxLights --
    /// Returns the maximum number of lights processed per frame.
    /// @return | integer | Maximum per-frame light count.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getMaxLights", lua.create_function(move |_, ()| Ok(s.borrow().light_world.max_lights))?,
    )?;

    // -- setMaxLights --
    /// Sets the maximum number of lights processed per frame (clamped 1-256).
    /// @param | n | integer | Requested per-frame light limit.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("setMaxLights", lua.create_function(move |_, n: u16| {
            s.borrow_mut().light_world.max_lights = n.clamp(1, 256);
            Ok(())
        })?,
    )?;

    // -- clear --
    /// Removes all lights and occluders, resets ambient to default.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("clear", lua.create_function(move |_, ()| {
            s.borrow_mut().light_world.clear();
            Ok(())
        })?,
    )?;

    // -- setGroupEnabled --
    /// Sets the enabled state for all lights in the given group.
    /// @param | groupId | integer | Group identifier.
    /// @param | enabled | boolean | Whether the group should be enabled.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("setGroupEnabled", lua.create_function(move |_, (group_id, enabled): (u16, bool)| {
            s.borrow_mut()
                .light_world
                .set_group_enabled(group_id, enabled);
            Ok(())
        })?,
    )?;

    // -- setGroupIntensity --
    /// Sets the intensity for all lights in the given group.
    /// @param | groupId | integer | Group identifier.
    /// @param | intensity | number | Group intensity multiplier.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("setGroupIntensity", lua.create_function(move |_, (group_id, intensity): (u16, f32)| {
            s.borrow_mut()
                .light_world
                .set_group_intensity(group_id, intensity);
            Ok(())
        })?,
    )?;

    // -- setGroupColor --
    /// Sets the color for all lights in the given group.
    /// @param | groupId | integer | Group identifier.
    /// @param | r | number | Red channel.
    /// @param | g | number | Green channel.
    /// @param | b | number | Blue channel.
    /// @param | a | number? | Optional alpha channel.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("setGroupColor", lua.create_function(
            move |_, (group_id, r, g, b, a): (u16, f32, f32, f32, Option<f32>)| {
                s.borrow_mut()
                    .light_world
                    .set_group_color(group_id, Color::new(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        )?,
    )?;

    // -- getGroupCount --
    /// Returns the number of lights in the given group.
    /// @param | groupId | integer | Group identifier.
    /// @return | integer | Number of lights in the group.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getGroupCount", lua.create_function(move |_, group_id: u16| {
            Ok(s.borrow().light_world.group_count(group_id))
        })?,
    )?;

    // -- advanceFlickers --
    /// Advances flicker phase for all lights with flicker enabled.
    /// @param | dt | number | Frame delta in seconds.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("advanceFlickers", lua.create_function(move |_, dt: f32| {
            s.borrow_mut().light_world.advance_flickers(dt);
            Ok(())
        })?,
    )?;

    // -- syncAmbient --
    /// Returns the current ambient light color snapshot.
    /// @return | number | Ambient red component snapshot.
    /// @return | number | Ambient green component snapshot.
    /// @return | number | Ambient blue component snapshot.
    /// @return | number | Ambient alpha component snapshot.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("syncAmbient", lua.create_function(move |_, ()| {
            let hint = s.borrow().light_world.ambient_color_hint();
            Ok((hint[0], hint[1], hint[2], hint[3]))
        })?,
    )?;

    // -- getGodRayHints --
    /// Returns directional light hints for god-ray rendering.
    /// @return | table | Array of `{x, y, angle}` hint tables.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getGodRayHints", lua.create_function(move |lua, ()| {
            let hints = s.borrow().light_world.directional_light_hints();
            let tbl = lua.create_table()?;
            for (i, (x, y, angle)) in hints.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("x", *x)?;
                t.set("y", *y)?;
                t.set("angle", *angle)?;
                tbl.set(i + 1, t)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- getNormalMapHints --
    /// Returns normal-map lighting hints for plugin renderers.
    /// @return | table | Array of `{x, y, radius, intensity, direction, normalMap, strength}` tables.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getNormalMapHints", lua.create_function(move |lua, ()| {
            let hints = s.borrow().light_world.normal_map_light_hints();
            let tbl = lua.create_table()?;
            for (i, h) in hints.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("x", h.x)?;
                t.set("y", h.y)?;
                t.set("radius", h.radius)?;
                t.set("intensity", h.intensity)?;
                t.set("direction", h.direction)?;
                t.set("normalMap", h.path.clone())?;
                t.set("strength", h.strength)?;
                tbl.set(i + 1, t)?;
            }
            Ok(tbl)
        })?,
    )?;

    lurek.set("light", tbl)?;
    Ok(())
}
