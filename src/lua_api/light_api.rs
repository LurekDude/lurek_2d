//! `luna.light` — 2D lighting, shadow occluders, and ambient control.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::engine::resource_keys::{LightKey, OccluderKey};
use crate::light::{
    Attenuation, FalloffMode, FlickerConfig, Light2D, LightBlendMode, LightType, Occluder,
    ShadowFilter,
};
use crate::math::{Color, Vec2};

// -------------------------------------------------------------------------------
// String ↔ Enum helpers
// -------------------------------------------------------------------------------

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

// -------------------------------------------------------------------------------
// Boundary parsing helpers
// -------------------------------------------------------------------------------

/// Returns a `LuaError` for an invalid or removed light handle.
fn invalid_light(method: &str) -> LuaError {
    LuaError::RuntimeError(format!("{}: invalid or already-removed light handle", method))
}

/// Returns a `LuaError` for an invalid or removed occluder handle.
fn invalid_occluder(method: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed occluder handle",
        method
    ))
}



/// Applies optional settings from a Lua opts table to an `Occluder`.
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
}

impl LuaUserData for LuaLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- setPosition --
        /// Sets the light's world-space position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setPosition"))?;
            light.set_position(x, y);
            Ok(())
        });

        // -- getPosition --
        /// Returns the light's world-space position.
        /// @return number, number
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getPosition"))?;
            Ok(light.get_position())
        });

        // -- setRadius --
        /// Sets the light's influence radius.
        /// @param r : number
        /// @return nil
        methods.add_method("setRadius", |_, this, r: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setRadius"))?;
            light.set_radius(r);
            Ok(())
        });

        // -- getRadius --
        /// Returns the light's influence radius.
        /// @return number
        methods.add_method("getRadius", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getRadius"))?;
            Ok(light.get_radius())
        });

        // -- setColor --
        /// Sets the light's tint color.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method("setColor", |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setColor"))?;
            light.set_color(Color::new(r, g, b, a.unwrap_or(1.0)));
            Ok(())
        });

        // -- getColor --
        /// Returns the light's tint color as (r, g, b, a).
        /// @return number, number, number, number
        methods.add_method("getColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getColor"))?;
            let c = light.get_color();
            Ok((c.r, c.g, c.b, c.a))
        });

        // -- setIntensity --
        /// Sets the brightness multiplier.
        /// @param i : number
        /// @return nil
        methods.add_method("setIntensity", |_, this, i: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setIntensity"))?;
            light.set_intensity(i);
            Ok(())
        });

        // -- getIntensity --
        /// Returns the brightness multiplier.
        /// @return number
        methods.add_method("getIntensity", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getIntensity"))?;
            Ok(light.get_intensity())
        });

        // -- setEnergy --
        /// Sets the energy scaling factor.
        /// @param e : number
        /// @return nil
        methods.add_method("setEnergy", |_, this, e: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setEnergy"))?;
            light.set_energy(e);
            Ok(())
        });

        // -- getEnergy --
        /// Returns the energy scaling factor.
        /// @return number
        methods.add_method("getEnergy", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getEnergy"))?;
            Ok(light.get_energy())
        });

        // -- setBlendMode --
        /// Sets the blend mode ('add', 'sub', or 'mix').
        /// @param mode : string
        /// @return nil
        methods.add_method("setBlendMode", |_, this, mode: String| {
            let bm = parse_blend_mode(&mode)?;
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setBlendMode"))?;
            light.set_blend_mode(bm);
            Ok(())
        });

        // -- getBlendMode --
        /// Returns the blend mode as a string.
        /// @return string
        methods.add_method("getBlendMode", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getBlendMode"))?;
            Ok(blend_mode_to_str(light.get_blend_mode()).to_string())
        });

        // -- setFalloff --
        /// Sets the falloff mode ('linear', 'smooth', or 'constant').
        /// @param mode : string
        /// @return nil
        methods.add_method("setFalloff", |_, this, mode: String| {
            let fm = parse_falloff(&mode)?;
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setFalloff"))?;
            light.set_falloff(fm);
            Ok(())
        });

        // -- getFalloff --
        /// Returns the falloff mode as a string.
        /// @return string
        methods.add_method("getFalloff", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getFalloff"))?;
            Ok(falloff_to_str(light.get_falloff()).to_string())
        });

        // -- setShadowEnabled --
        /// Sets whether this light casts shadows.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method("setShadowEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowEnabled"))?;
            light.set_shadow_enabled(b);
            Ok(())
        });

        // -- isShadowEnabled --
        /// Returns whether this light casts shadows.
        /// @return boolean
        methods.add_method("isShadowEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isShadowEnabled"))?;
            Ok(light.is_shadow_enabled())
        });

        // -- setShadowColor --
        /// Sets the shadow region color.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method(
            "setShadowColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st.light_world.get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setShadowColor"))?;
                light.set_shadow_color(Color::new(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        );

        // -- getShadowColor --
        /// Returns the shadow region color as (r, g, b, a).
        /// @return number, number, number, number
        methods.add_method("getShadowColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowColor"))?;
            let c = light.get_shadow_color();
            Ok((c.r, c.g, c.b, c.a))
        });

        // -- setShadowFilter --
        /// Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
        /// @param filter : string
        /// @return nil
        methods.add_method("setShadowFilter", |_, this, filter: String| {
            let sf = parse_shadow_filter(&filter)?;
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowFilter"))?;
            light.set_shadow_filter(sf);
            Ok(())
        });

        // -- getShadowFilter --
        /// Returns the shadow edge filter as a string.
        /// @return string
        methods.add_method("getShadowFilter", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowFilter"))?;
            Ok(shadow_filter_to_str(light.get_shadow_filter()).to_string())
        });

        // -- setShadowSmooth --
        /// Sets the shadow edge smoothing factor.
        /// @param smooth : number
        /// @return nil
        methods.add_method("setShadowSmooth", |_, this, s: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowSmooth"))?;
            light.set_shadow_smooth(s);
            Ok(())
        });

        // -- getShadowSmooth --
        /// Returns the shadow edge smoothing factor.
        /// @return number
        methods.add_method("getShadowSmooth", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowSmooth"))?;
            Ok(light.get_shadow_smooth())
        });

        // -- setLightMask --
        /// Sets the light interaction bitmask.
        /// @param mask : integer
        /// @return nil
        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setLightMask"))?;
            light.set_light_mask(mask);
            Ok(())
        });

        // -- getLightMask --
        /// Returns the light interaction bitmask.
        /// @return integer
        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getLightMask"))?;
            Ok(light.get_light_mask())
        });

        // -- setShadowMask --
        /// Sets the shadow casting bitmask.
        /// @param mask : integer
        /// @return nil
        methods.add_method("setShadowMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowMask"))?;
            light.set_shadow_mask(mask);
            Ok(())
        });

        // -- getShadowMask --
        /// Returns the shadow casting bitmask.
        /// @return integer
        methods.add_method("getShadowMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowMask"))?;
            Ok(light.get_shadow_mask())
        });

        // -- setEnabled --
        /// Sets whether this light is active.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setEnabled"))?;
            light.set_enabled(b);
            Ok(())
        });

        // -- isEnabled --
        /// Returns whether this light is active.
        /// @return boolean
        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isEnabled"))?;
            Ok(light.is_enabled())
        });

        // -- setLightType --
        /// Sets the geometric light type ('point', 'directional', or 'spot').
        /// @param t : string
        /// @return nil
        methods.add_method("setLightType", |_, this, t: String| {
            let lt = parse_light_type(&t)?;
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setLightType"))?;
            light.set_light_type(lt);
            Ok(())
        });

        // -- getLightType --
        /// Returns the geometric light type as a string.
        /// @return string
        methods.add_method("getLightType", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getLightType"))?;
            Ok(light_type_to_str(light.get_light_type()).to_string())
        });

        // -- setDirection --
        /// Sets the direction angle in radians.
        /// @param dir : number
        /// @return nil
        methods.add_method("setDirection", |_, this, dir: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setDirection"))?;
            light.set_direction(dir);
            Ok(())
        });

        // -- getDirection --
        /// Returns the direction angle in radians.
        /// @return number
        methods.add_method("getDirection", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getDirection"))?;
            Ok(light.get_direction())
        });

        // -- setInnerAngle --
        /// Sets the inner cone angle in radians for spot lights.
        /// @param angle : number
        /// @return nil
        methods.add_method("setInnerAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setInnerAngle"))?;
            light.set_inner_angle(a);
            Ok(())
        });

        // -- getInnerAngle --
        /// Returns the inner cone angle in radians.
        /// @return number
        methods.add_method("getInnerAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getInnerAngle"))?;
            Ok(light.get_inner_angle())
        });

        // -- setOuterAngle --
        /// Sets the outer cone angle in radians for spot lights.
        /// @param angle : number
        /// @return nil
        methods.add_method("setOuterAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setOuterAngle"))?;
            light.set_outer_angle(a);
            Ok(())
        });

        // -- getOuterAngle --
        /// Returns the outer cone angle in radians.
        /// @return number
        methods.add_method("getOuterAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getOuterAngle"))?;
            Ok(light.get_outer_angle())
        });

        // -- setAttenuation --
        /// Sets the custom attenuation coefficients (constant, linear, quadratic).
        /// @param c : number
        /// @param l : number
        /// @param q : number
        /// @return nil
        methods.add_method("setAttenuation", |_, this, (c, l, q): (f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setAttenuation"))?;
            light.set_attenuation(Attenuation::new(c, l, q));
            Ok(())
        });

        // -- getAttenuation --
        /// Returns the custom attenuation coefficients as (constant, linear, quadratic).
        /// @return number, number, number
        methods.add_method("getAttenuation", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getAttenuation"))?;
            let a = light.get_attenuation();
            Ok((a.constant, a.linear, a.quadratic))
        });

        // -- setFlicker --
        /// Sets the flicker effect speed and strength (enables flicker).
        /// @param speed : number
        /// @param strength : number
        /// @return nil
        methods.add_method("setFlicker", |_, this, (speed, strength): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setFlicker"))?;
            *light.flicker_mut() = FlickerConfig::new(speed, strength);
            Ok(())
        });

        // -- getFlicker --
        /// Returns the flicker effect speed and strength.
        /// @return number, number
        methods.add_method("getFlicker", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getFlicker"))?;
            let f = light.flicker();
            Ok((f.speed, f.strength))
        });

        // -- setFlickerEnabled --
        /// Sets whether the flicker effect is active.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method("setFlickerEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setFlickerEnabled"))?;
            light.flicker_mut().enabled = b;
            Ok(())
        });

        // -- isFlickerEnabled --
        /// Returns whether the flicker effect is active.
        /// @return boolean
        methods.add_method("isFlickerEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isFlickerEnabled"))?;
            Ok(light.flicker().enabled)
        });

        // -- setGroupId --
        /// Sets the group identifier for batch operations.
        /// @param id : integer
        /// @return nil
        methods.add_method("setGroupId", |_, this, id: u16| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setGroupId"))?;
            light.set_group_id(id);
            Ok(())
        });

        // -- getGroupId --
        /// Returns the group identifier.
        /// @return integer
        methods.add_method("getGroupId", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getGroupId"))?;
            Ok(light.get_group_id())
        });

        // -- setVolumetric --
        /// Sets whether this light hints at volumetric scattering.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method("setVolumetric", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st.light_world.get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setVolumetric"))?;
            light.set_volumetric(b);
            Ok(())
        });

        // -- isVolumetric --
        /// Returns whether this light hints at volumetric scattering.
        /// @return boolean
        methods.add_method("isVolumetric", |_, this, ()| {
            let st = this.state.borrow();
            let light = st.light_world.get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isVolumetric"))?;
            Ok(light.is_volumetric())
        });

        // -- remove --
        /// Removes this light from the world.
        /// @return nil
        methods.add_method("remove", |_, this, ()| {
            this.state.borrow_mut().light_world.remove_light(this.key);
            Ok(())
        });

        // -- isValid --
        /// Returns whether this light handle is still valid.
        /// @return boolean
        methods.add_method("isValid", |_, this, ()| {
            Ok(this.state.borrow().light_world.lights.contains_key(this.key))
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let st = this.state.borrow();
            match st.light_world.get_light(this.key) {
                Some(l) => Ok(format!("Light({}, {}, r={})", l.x, l.y, l.radius)),
                None => Ok("Light(invalid)".to_string()),
            }
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
        /// @param vertices : table
        /// @return nil
        methods.add_method("setVertices", |_, this, tbl: LuaTable| {
            let flat: Vec<f32> = tbl.sequence_values::<f32>().collect::<LuaResult<_>>()?;
            let tmp = Occluder::from_flat_coords(&flat).map_err(LuaError::RuntimeError)?;
            let mut st = this.state.borrow_mut();
            let occ = st.light_world.get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setVertices"))?;
            occ.set_vertices(tmp.vertices);
            Ok(())
        });

        // -- getVertices --
        /// Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
        /// @return table
        methods.add_method("getVertices", |lua, this, ()| {
            let st = this.state.borrow();
            let occ = st.light_world.get_occluder(this.key)
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
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let occ = st.light_world.get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setPosition"))?;
            occ.set_position(Vec2::new(x, y));
            Ok(())
        });

        // -- getPosition --
        /// Returns the translation offset as (x, y).
        /// @return number, number
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st.light_world.get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getPosition"))?;
            let pos = occ.get_position();
            Ok((pos.x, pos.y))
        });

        // -- setOpacity --
        /// Sets the shadow opacity (0.0–1.0).
        /// @param opacity : number
        /// @return nil
        methods.add_method("setOpacity", |_, this, o: f32| {
            let mut st = this.state.borrow_mut();
            let occ = st.light_world.get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setOpacity"))?;
            occ.set_opacity(o);
            Ok(())
        });

        // -- getOpacity --
        /// Returns the shadow opacity.
        /// @return number
        methods.add_method("getOpacity", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st.light_world.get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getOpacity"))?;
            Ok(occ.get_opacity())
        });

        // -- setLightMask --
        /// Sets the light interaction bitmask.
        /// @param mask : integer
        /// @return nil
        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let occ = st.light_world.get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setLightMask"))?;
            occ.set_light_mask(mask);
            Ok(())
        });

        // -- getLightMask --
        /// Returns the light interaction bitmask.
        /// @return integer
        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st.light_world.get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getLightMask"))?;
            Ok(occ.get_light_mask())
        });

        // -- setEnabled --
        /// Sets whether this occluder is active.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let occ = st.light_world.get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setEnabled"))?;
            occ.set_enabled(b);
            Ok(())
        });

        // -- isEnabled --
        /// Returns whether this occluder is active.
        /// @return boolean
        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st.light_world.get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:isEnabled"))?;
            Ok(occ.is_enabled())
        });

        // -- remove --
        /// Removes this occluder from the world.
        /// @return nil
        methods.add_method("remove", |_, this, ()| {
            this.state.borrow_mut().light_world.remove_occluder(this.key);
            Ok(())
        });

        // -- isValid --
        /// Returns whether this occluder handle is still valid.
        /// @return boolean
        methods.add_method("isValid", |_, this, ()| {
            Ok(this.state.borrow().light_world.occluders.contains_key(this.key))
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let st = this.state.borrow();
            match st.light_world.get_occluder(this.key) {
                Some(o) => Ok(format!("Occluder({} verts)", o.get_vertices().len())),
                None => Ok("Occluder(invalid)".to_string()),
            }
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.light` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newLight --
    /// Creates a new light at (x, y) with the given radius and optional settings.
    /// @param x : number
    /// @param y : number
    /// @param radius : number
    /// @param opts : table?
    /// @return Light
    let s = state.clone();
    tbl.set(
        "newLight",
        lua.create_function(
            move |_, (x, y, radius, opts): (f32, f32, f32, Option<LuaTable>)| {
                let mut light = Light2D::new(x, y, radius);
                if let Some(ref opts) = opts {
                    light.apply_lua_opts(opts)?;
                }
                let key = s.borrow_mut().light_world.add_light(light);
                Ok(LuaLight {
                    state: s.clone(),
                    key,
                })
            },
        )?,
    )?;

    // -- newOccluder --
    /// Creates a new shadow occluder from a vertex table and optional settings.
    /// @param vertices : table
    /// @param opts : table?
    /// @return Occluder
    let s = state.clone();
    tbl.set(
        "newOccluder",
        lua.create_function(move |_, (vtbl, opts): (LuaTable, Option<LuaTable>)| {
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
    /// @param r : number
    /// @param g : number
    /// @param b : number
    /// @param a : number?
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setAmbient",
        lua.create_function(move |_, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
            s.borrow_mut().light_world.ambient = Color::new(r, g, b, a.unwrap_or(1.0));
            Ok(())
        })?,
    )?;

    // -- getAmbient --
    /// Returns the global ambient light color as (r, g, b, a).
    /// @return number, number, number, number
    let s = state.clone();
    tbl.set(
        "getAmbient",
        lua.create_function(move |_, ()| {
            let c = s.borrow().light_world.ambient;
            Ok((c.r, c.g, c.b, c.a))
        })?,
    )?;

    // -- setEnabled --
    /// Sets whether the lighting system is active.
    /// @param enabled : boolean
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setEnabled",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().light_world.enabled = enabled;
            Ok(())
        })?,
    )?;

    // -- isEnabled --
    /// Returns whether the lighting system is active.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isEnabled",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().light_world.enabled)
        })?,
    )?;

    // -- getLightCount --
    /// Returns the number of lights in the world.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getLightCount",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().light_world.light_count())
        })?,
    )?;

    // -- getOccluderCount --
    /// Returns the number of occluders in the world.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getOccluderCount",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().light_world.occluder_count())
        })?,
    )?;

    // -- getMaxLights --
    /// Returns the maximum number of lights processed per frame.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getMaxLights",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().light_world.max_lights)
        })?,
    )?;

    // -- setMaxLights --
    /// Sets the maximum number of lights processed per frame (clamped 1–256).
    /// @param n : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setMaxLights",
        lua.create_function(move |_, n: u16| {
            s.borrow_mut().light_world.max_lights = n.clamp(1, 256);
            Ok(())
        })?,
    )?;

    // -- clear --
    /// Removes all lights and occluders, resets ambient to default.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "clear",
        lua.create_function(move |_, ()| {
            s.borrow_mut().light_world.clear();
            Ok(())
        })?,
    )?;

    // -- setGroupEnabled --
    /// Sets the enabled state for all lights in the given group.
    /// @param groupId : integer
    /// @param enabled : boolean
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setGroupEnabled",
        lua.create_function(move |_, (group_id, enabled): (u16, bool)| {
            s.borrow_mut().light_world.set_group_enabled(group_id, enabled);
            Ok(())
        })?,
    )?;

    // -- setGroupIntensity --
    /// Sets the intensity for all lights in the given group.
    /// @param groupId : integer
    /// @param intensity : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setGroupIntensity",
        lua.create_function(move |_, (group_id, intensity): (u16, f32)| {
            s.borrow_mut().light_world.set_group_intensity(group_id, intensity);
            Ok(())
        })?,
    )?;

    // -- setGroupColor --
    /// Sets the color for all lights in the given group.
    /// @param groupId : integer
    /// @param r : number
    /// @param g : number
    /// @param b : number
    /// @param a : number?
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setGroupColor",
        lua.create_function(
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
    /// @param groupId : integer
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getGroupCount",
        lua.create_function(move |_, group_id: u16| {
            Ok(s.borrow().light_world.group_count(group_id))
        })?,
    )?;

    // -- advanceFlickers --
    /// Advances flicker phase for all lights with flicker enabled.
    /// @param dt : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "advanceFlickers",
        lua.create_function(move |_, dt: f32| {
            s.borrow_mut().light_world.advance_flickers(dt);
            Ok(())
        })?,
    )?;

    luna.set("light", tbl)?;
    Ok(())
}
