use super::SharedState;
use crate::light::transition::LightTransition;
use crate::light::{
    Attenuation, FalloffMode, FlickerConfig, Light2D, LightBlendMode, LightType, Occluder,
    ShadowFilter,
};
use crate::math::{Color, Vec2};
use crate::runtime::resource_keys::{LightKey, OccluderKey};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
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
fn blend_mode_to_str(mode: LightBlendMode) -> &'static str {
    match mode {
        LightBlendMode::Add => "add",
        LightBlendMode::Sub => "sub",
        LightBlendMode::Mix => "mix",
    }
}
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
fn falloff_to_str(mode: FalloffMode) -> &'static str {
    match mode {
        FalloffMode::Linear => "linear",
        FalloffMode::Smooth => "smooth",
        FalloffMode::Constant => "constant",
    }
}
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
fn shadow_filter_to_str(filter: ShadowFilter) -> &'static str {
    match filter {
        ShadowFilter::None => "none",
        ShadowFilter::Pcf5 => "pcf5",
        ShadowFilter::Pcf13 => "pcf13",
    }
}
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
fn light_type_to_str(lt: LightType) -> &'static str {
    match lt {
        LightType::Point => "point",
        LightType::Directional => "directional",
        LightType::Spot => "spot",
    }
}
fn invalid_light(method: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed light handle",
        method
    ))
}
fn invalid_occluder(method: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-removed occluder handle",
        method
    ))
}
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
#[derive(Clone)]
pub struct LuaLight {
    state: Rc<RefCell<SharedState>>,
    key: LightKey,
    transition: RefCell<Option<LightTransition>>,
    cookie_path: RefCell<Option<String>>,
}
impl LuaUserData for LuaLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setPosition"))?;
            light.set_position(x, y);
            Ok(())
        });
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getPosition"))?;
            Ok(light.get_position())
        });
        methods.add_method("setRadius", |_, this, r: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setRadius"))?;
            light.set_radius(r);
            Ok(())
        });
        methods.add_method("getRadius", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getRadius"))?;
            Ok(light.get_radius())
        });
        methods.add_method(
            "setColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setColor"))?;
                light.set_color(Color::new(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        );
        methods.add_method("getColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getColor"))?;
            let c = light.get_color();
            Ok((c.r, c.g, c.b, c.a))
        });
        methods.add_method("setIntensity", |_, this, i: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setIntensity"))?;
            light.set_intensity(i);
            Ok(())
        });
        methods.add_method("getIntensity", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getIntensity"))?;
            Ok(light.get_intensity())
        });
        methods.add_method("setEnergy", |_, this, e: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setEnergy"))?;
            light.set_energy(e);
            Ok(())
        });
        methods.add_method("getEnergy", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getEnergy"))?;
            Ok(light.get_energy())
        });
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
        methods.add_method("getBlendMode", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getBlendMode"))?;
            Ok(blend_mode_to_str(light.get_blend_mode()).to_string())
        });
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
        methods.add_method("getFalloff", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getFalloff"))?;
            Ok(falloff_to_str(light.get_falloff()).to_string())
        });
        methods.add_method("setShadowEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowEnabled"))?;
            light.set_shadow_enabled(b);
            Ok(())
        });
        methods.add_method("isShadowEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isShadowEnabled"))?;
            Ok(light.is_shadow_enabled())
        });
        methods.add_method(
            "setShadowColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let light = st
                    .light_world
                    .get_light_mut(this.key)
                    .ok_or_else(|| invalid_light("Light:setShadowColor"))?;
                light.set_shadow_color(Color::new(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        );
        methods.add_method("getShadowColor", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowColor"))?;
            let c = light.get_shadow_color();
            Ok((c.r, c.g, c.b, c.a))
        });
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
        methods.add_method("getShadowFilter", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowFilter"))?;
            Ok(shadow_filter_to_str(light.get_shadow_filter()).to_string())
        });
        methods.add_method("setShadowSmooth", |_, this, s: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowSmooth"))?;
            light.set_shadow_smooth(s);
            Ok(())
        });
        methods.add_method("getShadowSmooth", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowSmooth"))?;
            Ok(light.get_shadow_smooth())
        });
        methods.add_method("setShadowSoftness", |_, this, softness: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowSoftness"))?;
            light.set_shadow_softness(softness);
            Ok(())
        });
        methods.add_method("getShadowSoftness", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowSoftness"))?;
            Ok(light.get_shadow_softness())
        });
        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setLightMask"))?;
            light.set_light_mask(mask);
            Ok(())
        });
        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getLightMask"))?;
            Ok(light.get_light_mask())
        });
        methods.add_method("setShadowMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setShadowMask"))?;
            light.set_shadow_mask(mask);
            Ok(())
        });
        methods.add_method("getShadowMask", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getShadowMask"))?;
            Ok(light.get_shadow_mask())
        });
        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setEnabled"))?;
            light.set_enabled(b);
            Ok(())
        });
        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isEnabled"))?;
            Ok(light.is_enabled())
        });
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
        methods.add_method("getLightType", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getLightType"))?;
            Ok(light_type_to_str(light.get_light_type()).to_string())
        });
        methods.add_method("setDirection", |_, this, dir: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setDirection"))?;
            light.set_direction(dir);
            Ok(())
        });
        methods.add_method("getDirection", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getDirection"))?;
            Ok(light.get_direction())
        });
        methods.add_method("setInnerAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setInnerAngle"))?;
            light.set_inner_angle(a);
            Ok(())
        });
        methods.add_method("getInnerAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getInnerAngle"))?;
            Ok(light.get_inner_angle())
        });
        methods.add_method("setOuterAngle", |_, this, a: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setOuterAngle"))?;
            light.set_outer_angle(a);
            Ok(())
        });
        methods.add_method("getOuterAngle", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getOuterAngle"))?;
            Ok(light.get_outer_angle())
        });
        methods.add_method("setAttenuation", |_, this, (c, l, q): (f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setAttenuation"))?;
            light.set_attenuation(Attenuation::new(c, l, q));
            Ok(())
        });
        methods.add_method("getAttenuation", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getAttenuation"))?;
            let a = light.get_attenuation();
            Ok((a.constant, a.linear, a.quadratic))
        });
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
        methods.add_method("getFlicker", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getFlicker"))?;
            let f = light.flicker();
            Ok((f.speed, f.strength))
        });
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
        methods.add_method("isFlickerEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isFlickerEnabled"))?;
            Ok(light.flicker().enabled)
        });
        methods.add_method("setGroupId", |_, this, id: u16| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setGroupId"))?;
            light.set_group_id(id);
            Ok(())
        });
        methods.add_method("getGroupId", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getGroupId"))?;
            Ok(light.get_group_id())
        });
        methods.add_method("setVolumetric", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setVolumetric"))?;
            light.set_volumetric(b);
            Ok(())
        });
        methods.add_method("isVolumetric", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:isVolumetric"))?;
            Ok(light.is_volumetric())
        });
        methods.add_method("remove", |_, this, ()| {
            this.state.borrow_mut().light_world.remove_light(this.key);
            Ok(())
        });
        methods.add_method("isValid", |_, this, ()| {
            Ok(this
                .state
                .borrow()
                .light_world
                .lights
                .contains_key(this.key))
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let st = this.state.borrow();
            match st.light_world.get_light(this.key) {
                Some(l) => Ok(format!("Light({}, {}, r={})", l.x, l.y, l.radius)),
                None => Ok("Light(invalid)".to_string()),
            }
        });
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
        methods.add_method(
            "transitionTo",
            |_, this, (target, duration): (LuaTable, f32)| {
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
        methods.add_method("stopTransition", |_, this, ()| {
            this.transition.borrow_mut().take();
            Ok(())
        });
        methods.add_method("transitionProgress", |_, this, ()| {
            Ok(this
                .transition
                .borrow()
                .as_ref()
                .map(|t| t.progress())
                .unwrap_or(1.0))
        });
        methods.add_method("setCookie", |_, this, path: String| {
            *this.cookie_path.borrow_mut() = Some(path);
            Ok(())
        });
        methods.add_method("getCookie", |_, this, ()| {
            Ok(this.cookie_path.borrow().clone())
        });
        methods.add_method("clearCookie", |_, this, ()| {
            this.cookie_path.borrow_mut().take();
            Ok(())
        });
        methods.add_method("setNormalMap", |_, this, path: String| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setNormalMap"))?;
            light.set_normal_map_path(path);
            Ok(())
        });
        methods.add_method("getNormalMap", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getNormalMap"))?;
            Ok(light.get_normal_map_path().map(str::to_string))
        });
        methods.add_method("clearNormalMap", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:clearNormalMap"))?;
            light.clear_normal_map_path();
            Ok(())
        });
        methods.add_method("setNormalStrength", |_, this, strength: f32| {
            let mut st = this.state.borrow_mut();
            let light = st
                .light_world
                .get_light_mut(this.key)
                .ok_or_else(|| invalid_light("Light:setNormalStrength"))?;
            light.set_normal_strength(strength);
            Ok(())
        });
        methods.add_method("getNormalStrength", |_, this, ()| {
            let st = this.state.borrow();
            let light = st
                .light_world
                .get_light(this.key)
                .ok_or_else(|| invalid_light("Light:getNormalStrength"))?;
            Ok(light.get_normal_strength())
        });
        methods.add_method("type", |_, _, ()| Ok("LLight"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLight" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaOccluder {
    state: Rc<RefCell<SharedState>>,
    key: OccluderKey,
}
impl LuaUserData for LuaOccluder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setPosition"))?;
            occ.set_position(Vec2::new(x, y));
            Ok(())
        });
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getPosition"))?;
            let pos = occ.get_position();
            Ok((pos.x, pos.y))
        });
        methods.add_method("setOpacity", |_, this, o: f32| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setOpacity"))?;
            occ.set_opacity(o);
            Ok(())
        });
        methods.add_method("getOpacity", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getOpacity"))?;
            Ok(occ.get_opacity())
        });
        methods.add_method("setLightMask", |_, this, mask: u16| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setLightMask"))?;
            occ.set_light_mask(mask);
            Ok(())
        });
        methods.add_method("getLightMask", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:getLightMask"))?;
            Ok(occ.get_light_mask())
        });
        methods.add_method("setEnabled", |_, this, b: bool| {
            let mut st = this.state.borrow_mut();
            let occ = st
                .light_world
                .get_occluder_mut(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:setEnabled"))?;
            occ.set_enabled(b);
            Ok(())
        });
        methods.add_method("isEnabled", |_, this, ()| {
            let st = this.state.borrow();
            let occ = st
                .light_world
                .get_occluder(this.key)
                .ok_or_else(|| invalid_occluder("Occluder:isEnabled"))?;
            Ok(occ.is_enabled())
        });
        methods.add_method("remove", |_, this, ()| {
            this.state
                .borrow_mut()
                .light_world
                .remove_occluder(this.key);
            Ok(())
        });
        methods.add_method("isValid", |_, this, ()| {
            Ok(this
                .state
                .borrow()
                .light_world
                .occluders
                .contains_key(this.key))
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let st = this.state.borrow();
            match st.light_world.get_occluder(this.key) {
                Some(o) => Ok(format!("Occluder({} verts)", o.get_vertices().len())),
                None => Ok("Occluder(invalid)".to_string()),
            }
        });
        methods.add_method("type", |_, _, ()| Ok("LOccluder"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LOccluder" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "newLight",
        lua.create_function(
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
    let s = state.clone();
    tbl.set(
        "setAmbient",
        lua.create_function(move |_, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
            s.borrow_mut().light_world.ambient = Color::new(r, g, b, a.unwrap_or(1.0));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getAmbient",
        lua.create_function(move |_, ()| {
            let c = s.borrow().light_world.ambient;
            Ok((c.r, c.g, c.b, c.a))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setEnabled",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().light_world.enabled = enabled;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "isEnabled",
        lua.create_function(move |_, ()| Ok(s.borrow().light_world.enabled))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getLightCount",
        lua.create_function(move |_, ()| Ok(s.borrow().light_world.light_count()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getOccluderCount",
        lua.create_function(move |_, ()| Ok(s.borrow().light_world.occluder_count()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getMaxLights",
        lua.create_function(move |_, ()| Ok(s.borrow().light_world.max_lights))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setMaxLights",
        lua.create_function(move |_, n: u16| {
            s.borrow_mut().light_world.max_lights = n.clamp(1, 256);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "clear",
        lua.create_function(move |_, ()| {
            s.borrow_mut().light_world.clear();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setGroupEnabled",
        lua.create_function(move |_, (group_id, enabled): (u16, bool)| {
            s.borrow_mut()
                .light_world
                .set_group_enabled(group_id, enabled);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setGroupIntensity",
        lua.create_function(move |_, (group_id, intensity): (u16, f32)| {
            s.borrow_mut()
                .light_world
                .set_group_intensity(group_id, intensity);
            Ok(())
        })?,
    )?;
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
    let s = state.clone();
    tbl.set(
        "getGroupCount",
        lua.create_function(move |_, group_id: u16| {
            Ok(s.borrow().light_world.group_count(group_id))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "advanceFlickers",
        lua.create_function(move |_, dt: f32| {
            s.borrow_mut().light_world.advance_flickers(dt);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "syncAmbient",
        lua.create_function(move |_, ()| {
            let hint = s.borrow().light_world.ambient_color_hint();
            Ok((hint[0], hint[1], hint[2], hint[3]))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getGodRayHints",
        lua.create_function(move |lua, ()| {
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
    let s = state.clone();
    tbl.set(
        "getNormalMapHints",
        lua.create_function(move |lua, ()| {
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
