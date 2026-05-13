use super::SharedState;
use crate::effect::{
    presets::build_preset, ImageEffect, Overlay, PostFxEffect, PostFxEffectType, PostFxStack,
    WeatherType,
};
use crate::render::renderer::{PostFxPass, RenderCommand};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::atomic::{AtomicU64, Ordering};
static NEXT_STACK_ID: AtomicU64 = AtomicU64::new(1);
pub struct LuaPostFxEffect {
    inner: Rc<RefCell<PostFxEffect>>,
}
impl LuaPostFxEffect {
    fn from_owned(e: PostFxEffect) -> Self {
        Self {
            inner: Rc::new(RefCell::new(e)),
        }
    }
    fn from_rc(rc: Rc<RefCell<PostFxEffect>>) -> Self {
        Self { inner: rc }
    }
}
impl LuaUserData for LuaPostFxEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTypeName", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name().to_string())
        });
        methods.add_method("isBuiltIn", |_, this, ()| {
            Ok(this.inner.borrow().is_built_in())
        });
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.borrow().enabled));
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().enabled = enabled;
            Ok(())
        });
        methods.add_method_mut("setParameter", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set_parameter(name, value);
            Ok(())
        });
        methods.add_method(
            "getParameter",
            |_, this, (name, default): (String, Option<f32>)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_parameter(&name, default.unwrap_or(0.0)))
            },
        );
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.borrow().has_parameter(&name))
        });
        methods.add_method("getParameterNames", |_, this, ()| {
            Ok(this.inner.borrow().get_parameter_names())
        });
        methods.add_method("getEffectType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name())
        });
        methods.add_method("getType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name())
        });
        methods.add_method("type", |_, _, ()| Ok("LPostFxEffect"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "PostFxEffect" || name == "Object")
        });
        methods.add_method_mut("setThreshold", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("threshold", v);
            Ok(())
        });
        methods.add_method_mut("setIntensity", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("intensity", v);
            Ok(())
        });
        methods.add_method_mut("setRadius", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("radius", v);
            Ok(())
        });
        methods.add_method_mut("setStrength", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("strength", v);
            Ok(())
        });
        methods.add_method_mut("setScanlineStrength", |_, this, v: f32| {
            this.inner
                .borrow_mut()
                .set_parameter("scanline_strength", v);
            Ok(())
        });
        methods.add_method_mut("setOffset", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("offset", v);
            Ok(())
        });
        methods.add_method_mut("setBrightness", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("brightness", v);
            Ok(())
        });
        methods.add_method_mut("setContrast", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("contrast", v);
            Ok(())
        });
        methods.add_method_mut("setSaturation", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("saturation", v);
            Ok(())
        });
        methods.add_method_mut("enableAutoUniforms", |_, this, ()| {
            this.inner.borrow_mut().auto_uniforms = true;
            Ok(())
        });
        methods.add_method_mut("disableAutoUniforms", |_, this, ()| {
            this.inner.borrow_mut().auto_uniforms = false;
            Ok(())
        });
        methods.add_method("isAutoUniforms", |_, this, ()| {
            Ok(this.inner.borrow().auto_uniforms)
        });
    }
}
pub struct LuaPostFxStack {
    inner: PostFxStack,
    effects: Vec<Rc<RefCell<PostFxEffect>>>,
    stack_id: u64,
    state: Rc<RefCell<SharedState>>,
    feedback_factor: f32,
}
impl LuaUserData for LuaPostFxStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("add", |_, this, effect_ud: LuaAnyUserData| {
            let effect = effect_ud.borrow::<LuaPostFxEffect>()?;
            this.effects.push(Rc::clone(&effect.inner));
            let idx = this.effects.len() - 1;
            this.inner.add(idx);
            Ok(())
        });
        methods.add_method_mut("remove", |_, this, effect_ud: LuaAnyUserData| {
            let effect = effect_ud.borrow::<LuaPostFxEffect>()?;
            let ptr = Rc::as_ptr(&effect.inner);
            if let Some(pos) = this.effects.iter().position(|e| Rc::as_ptr(e) == ptr) {
                this.effects.remove(pos);
                if pos < this.inner.effects.len() {
                    this.inner.effects.remove(pos);
                    this.inner.enabled.remove(pos);
                }
                Ok(true)
            } else {
                Ok(false)
            }
        });
        methods.add_method_mut(
            "insert",
            |_, this, (position, effect_ud): (usize, LuaAnyUserData)| {
                let effect = effect_ud.borrow::<LuaPostFxEffect>()?;
                let idx = (position.saturating_sub(1)).min(this.effects.len());
                this.effects.insert(idx, Rc::clone(&effect.inner));
                this.inner.effects.insert(idx, idx);
                this.inner.enabled.insert(idx, true);
                Ok(())
            },
        );
        methods.add_method_mut(
            "setEnabled",
            |_, this, (position, enabled): (usize, bool)| {
                let idx = position.saturating_sub(1);
                if idx < this.inner.enabled.len() {
                    this.inner.enabled[idx] = enabled;
                }
                Ok(())
            },
        );
        methods.add_method("isEnabled", |_, this, position: usize| {
            let idx = position.saturating_sub(1);
            Ok(this.inner.enabled.get(idx).copied().unwrap_or(false))
        });
        methods.add_method("getEffectCount", |_, this, ()| Ok(this.effects.len()));
        methods.add_method("getEffect", |lua, this, index: usize| {
            let idx = index.saturating_sub(1);
            match this.effects.get(idx) {
                Some(rc) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaPostFxEffect::from_rc(Rc::clone(rc)))?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("getEnabledEffects", |lua, this, ()| {
            let t = lua.create_table()?;
            let mut count = 1;
            for (i, rc) in this.effects.iter().enumerate() {
                if this.inner.enabled.get(i).copied().unwrap_or(true) {
                    t.set(
                        count,
                        lua.create_userdata(LuaPostFxEffect::from_rc(Rc::clone(rc)))?,
                    )?;
                    count += 1;
                }
            }
            Ok(t)
        });
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });
        methods.add_method("len", |_, this, ()| Ok(this.effects.len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.effects.is_empty()));
        methods.add_method_mut("clear", |_, this, ()| {
            this.effects.clear();
            this.inner.clear();
            Ok(())
        });
        methods.add_method_mut("dedup", |_, this, ()| {
            let mut seen_ptrs: Vec<*const ()> = Vec::new();
            let mut new_lua = Vec::with_capacity(this.effects.len());
            let mut new_inner_effects = Vec::with_capacity(this.effects.len());
            let mut new_inner_enabled = Vec::with_capacity(this.effects.len());
            for (i, rc) in this.effects.iter().enumerate() {
                let ptr = Rc::as_ptr(rc) as *const ();
                if !seen_ptrs.contains(&ptr) {
                    seen_ptrs.push(ptr);
                    new_lua.push(Rc::clone(rc));
                    new_inner_effects.push(new_lua.len() - 1);
                    new_inner_enabled.push(this.inner.enabled.get(i).copied().unwrap_or(true));
                }
            }
            let removed = this.effects.len() - new_lua.len();
            this.effects = new_lua;
            this.inner.effects = new_inner_effects;
            this.inner.enabled = new_inner_enabled;
            Ok(removed as i64)
        });
        methods.add_method("isCapturing", |_, this, ()| Ok(this.inner.capturing));
        methods.add_method_mut("beginCapture", |_, this, ()| {
            this.inner.capturing = true;
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::BeginPostFx {
                    stack_id: this.stack_id,
                });
            Ok(())
        });
        methods.add_method_mut("endCapture", |_, this, ()| {
            this.inner.capturing = false;
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::EndPostFx {
                    stack_id: this.stack_id,
                });
            Ok(())
        });
        methods.add_method("apply", |_, this, ()| {
            let passes: Vec<PostFxPass> = this
                .effects
                .iter()
                .zip(this.inner.enabled.iter())
                .filter(|(_, &enabled)| enabled)
                .map(|(effect_rc, _)| {
                    let e = effect_rc.borrow();
                    PostFxPass {
                        effect_name: e.get_type_name().to_string(),
                        params: e.params.clone(),
                        shader_id: e.shader_id,
                        auto_uniforms: e.auto_uniforms,
                    }
                })
                .collect();
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::ApplyPostFx {
                    stack_id: this.stack_id,
                    passes,
                    width: this.inner.width,
                    height: this.inner.height,
                });
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LPostFxStack"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "PostFxStack" || name == "Object")
        });
        methods.add_method_mut("setFeedback", |_, this, factor: f32| {
            this.feedback_factor = factor.clamp(0.0, 1.0);
            Ok(())
        });
        methods.add_method("getFeedback", |_, this, ()| Ok(this.feedback_factor));
        methods.add_method_mut("clearFeedback", |_, this, ()| {
            this.feedback_factor = 0.0;
            Ok(())
        });
    }
}
pub struct LuaImageEffect {
    inner: ImageEffect,
}
impl LuaUserData for LuaImageEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addEffect", |lua, this, name: String| {
            let et = PostFxEffectType::from_name(&name)
                .ok_or_else(|| LuaError::RuntimeError(format!("unknown effect type: {name}")))?;
            let rc = Rc::new(RefCell::new(PostFxEffect::new(et)));
            this.inner.add_effect_rc(Rc::clone(&rc));
            lua.create_userdata(LuaPostFxEffect::from_rc(rc))
        });
        methods.add_method("getEffect", |lua, this, key: LuaValue| {
            let rc_opt = match &key {
                LuaValue::Integer(i) => this
                    .inner
                    .get_effect_by_index((*i as usize).saturating_sub(1)),
                LuaValue::Number(n) => this
                    .inner
                    .get_effect_by_index((*n as usize).saturating_sub(1)),
                LuaValue::String(s) => this.inner.get_effect_by_name(s.to_str()?),
                _ => None,
            };
            match rc_opt {
                Some(rc) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaPostFxEffect::from_rc(rc))?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method_mut("removeEffect", |_, this, key: LuaValue| match &key {
            LuaValue::Integer(i) => Ok(this.inner.remove_by_index((*i as usize).saturating_sub(1))),
            LuaValue::Number(n) => Ok(this.inner.remove_by_index((*n as usize).saturating_sub(1))),
            LuaValue::String(s) => Ok(this.inner.remove_by_name(s.to_str()?)),
            _ => Ok(false),
        });
        methods.add_method_mut("clearEffects", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("effectCount", |_, this, ()| Ok(this.inner.effect_count()));
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.effect_count())
        });
        methods.add_method("clone", |lua, this, ()| {
            let mut new_ie = ImageEffect::new("");
            for i in 0..this.inner.effect_count() {
                if let Some(rc) = this.inner.get_effect_by_index(i) {
                    new_ie.add_effect(rc.borrow().clone());
                }
            }
            lua.create_userdata(LuaImageEffect { inner: new_ie })
        });
        methods.add_method("save", |_, _, ()| Ok(true));
        methods.add_method("type", |_, _, ()| Ok("LImageEffect"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ImageEffect" || name == "Object")
        });
        methods.add_method_mut("removeByIndex", |_, this, idx: usize| {
            Ok(this.inner.remove_by_index(idx))
        });
        methods.add_method_mut("removeByName", |_, this, name: String| {
            Ok(this.inner.remove_by_name(&name))
        });
    }
}
pub struct LuaOverlay {
    inner: Overlay,
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaOverlay {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        methods.add_method_mut(
            "triggerFlash",
            |_, this, (r, g, b, a, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_flash(r, g, b, a, duration);
                Ok(())
            },
        );
        methods.add_method_mut(
            "triggerShake",
            |_, this, (intensity, duration): (f32, f32)| {
                this.inner.trigger_shake(intensity, duration);
                Ok(())
            },
        );
        methods.add_method_mut(
            "triggerFade",
            |_, this, (r, g, b, target_alpha, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_fade(r, g, b, target_alpha, duration);
                Ok(())
            },
        );
        methods.add_method_mut("triggerLightning", |_, this, ()| {
            this.inner.trigger_lightning();
            Ok(())
        });
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.get_shake_offset())
        });
        methods.add_method("isActive", |_, this, ()| Ok(this.inner.is_active()));
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });
        methods.add_method("getFlashAlpha", |_, this, ()| {
            Ok(this.inner.get_flash_alpha())
        });
        methods.add_method("getLightningAlpha", |_, this, ()| {
            Ok(this.inner.get_lightning_alpha())
        });
        methods.add_method_mut("setAmbientEnabled", |_, this, v: bool| {
            this.inner.ambient.enabled = v;
            Ok(())
        });
        methods.add_method("isAmbientEnabled", |_, this, ()| {
            Ok(this.inner.ambient.enabled)
        });
        methods.add_method_mut(
            "setAmbientColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.ambient.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );
        methods.add_method("getAmbientColor", |_, this, ()| {
            let c = this.inner.ambient.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut("pullAmbientFromLight", |_, this, ()| {
            let c = this.state.borrow().light_world.ambient;
            this.inner.ambient.color = [c.r, c.g, c.b, c.a];
            Ok(())
        });
        methods.add_method_mut("pushAmbientToLight", |_, this, ()| {
            let c = this.inner.ambient.color;
            this.state.borrow_mut().light_world.ambient =
                crate::math::Color::new(c[0], c[1], c[2], c[3]);
            Ok(())
        });
        methods.add_method_mut("syncAmbientWithLight", |_, this, mode: String| {
            let light_color = {
                let st = this.state.borrow();
                [
                    st.light_world.ambient.r,
                    st.light_world.ambient.g,
                    st.light_world.ambient.b,
                    st.light_world.ambient.a,
                ]
            };
            let overlay_color = this.inner.ambient.color;
            let resolved = match mode.as_str() {
                "light" => light_color,
                "overlay" => overlay_color,
                "avg" => [
                    (light_color[0] + overlay_color[0]) * 0.5,
                    (light_color[1] + overlay_color[1]) * 0.5,
                    (light_color[2] + overlay_color[2]) * 0.5,
                    (light_color[3] + overlay_color[3]) * 0.5,
                ],
                "max" => [
                    light_color[0].max(overlay_color[0]),
                    light_color[1].max(overlay_color[1]),
                    light_color[2].max(overlay_color[2]),
                    light_color[3].max(overlay_color[3]),
                ],
                "min" => [
                    light_color[0].min(overlay_color[0]),
                    light_color[1].min(overlay_color[1]),
                    light_color[2].min(overlay_color[2]),
                    light_color[3].min(overlay_color[3]),
                ],
                _ => {
                    return Err(LuaError::RuntimeError(
                        "Overlay:syncAmbientWithLight invalid mode; expected 'light', 'overlay', 'avg', 'max', or 'min'"
                            .to_string(),
                    ))
                }
            };
            this.inner.ambient.color = resolved;
            this.state.borrow_mut().light_world.ambient =
                crate::math::Color::new(resolved[0], resolved[1], resolved[2], resolved[3]);
            Ok(())
        });
        methods.add_method_mut("setTimeOfDay", |_, this, v: f32| {
            this.inner.ambient.time_of_day = v;
            Ok(())
        });
        methods.add_method("getTimeOfDay", |_, this, ()| {
            Ok(this.inner.ambient.time_of_day)
        });
        methods.add_method_mut("setFogEnabled", |_, this, v: bool| {
            this.inner.fog.enabled = v;
            Ok(())
        });
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog.enabled));
        methods.add_method_mut("setFogDensity", |_, this, v: f32| {
            this.inner.fog.density = v;
            Ok(())
        });
        methods.add_method("getFogDensity", |_, this, ()| Ok(this.inner.fog.density));
        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.fog.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut("setHeatHazeEnabled", |_, this, v: bool| {
            this.inner.heat_haze.enabled = v;
            Ok(())
        });
        methods.add_method("isHeatHazeEnabled", |_, this, ()| {
            Ok(this.inner.heat_haze.enabled)
        });
        methods.add_method_mut("setHeatHazeIntensity", |_, this, v: f32| {
            this.inner.heat_haze.intensity = v;
            Ok(())
        });
        methods.add_method("getHeatHazeIntensity", |_, this, ()| {
            Ok(this.inner.heat_haze.intensity)
        });
        methods.add_method_mut("setVignetteEnabled", |_, this, v: bool| {
            this.inner.vignette.enabled = v;
            Ok(())
        });
        methods.add_method("isVignetteEnabled", |_, this, ()| {
            Ok(this.inner.vignette.enabled)
        });
        methods.add_method_mut("setVignetteStrength", |_, this, v: f32| {
            this.inner.vignette.strength = v;
            Ok(())
        });
        methods.add_method("getVignetteStrength", |_, this, ()| {
            Ok(this.inner.vignette.strength)
        });
        methods.add_method_mut("setFilmGrainEnabled", |_, this, v: bool| {
            this.inner.film_grain.enabled = v;
            Ok(())
        });
        methods.add_method("isFilmGrainEnabled", |_, this, ()| {
            Ok(this.inner.film_grain.enabled)
        });
        methods.add_method_mut("setFilmGrainIntensity", |_, this, v: f32| {
            this.inner.film_grain.intensity = v;
            Ok(())
        });
        methods.add_method("getFilmGrainIntensity", |_, this, ()| {
            Ok(this.inner.film_grain.intensity)
        });
        methods.add_method_mut("setCloudShadows", |_, this, v: bool| {
            this.inner.clouds.enabled = v;
            Ok(())
        });
        methods.add_method("isCloudShadowsEnabled", |_, this, ()| {
            Ok(this.inner.clouds.enabled)
        });
        methods.add_method_mut("setCloudCount", |_, this, v: u32| {
            this.inner.clouds.count = v;
            Ok(())
        });
        methods.add_method("getCloudCount", |_, this, ()| Ok(this.inner.clouds.count));
        methods.add_method_mut("setCloudSpeed", |_, this, v: f32| {
            this.inner.clouds.speed = v;
            Ok(())
        });
        methods.add_method("getCloudSpeed", |_, this, ()| Ok(this.inner.clouds.speed));
        methods.add_method_mut("setCloudScale", |_, this, v: f32| {
            this.inner.clouds.scale = v;
            Ok(())
        });
        methods.add_method("getCloudScale", |_, this, ()| Ok(this.inner.clouds.scale));
        methods.add_method_mut("setCloudOpacity", |_, this, v: f32| {
            this.inner.clouds.opacity = v;
            Ok(())
        });
        methods.add_method("getCloudOpacity", |_, this, ()| {
            Ok(this.inner.clouds.opacity)
        });
        methods.add_method_mut("setWeatherEnabled", |_, this, v: bool| {
            this.inner.weather.enabled = v;
            Ok(())
        });
        methods.add_method("isWeatherEnabled", |_, this, ()| {
            Ok(this.inner.weather.enabled)
        });
        methods.add_method_mut("setWeather", |_, this, name: String| {
            this.inner.weather.weather_type = WeatherType::from_name(&name)
                .ok_or_else(|| LuaError::RuntimeError(format!("unknown weather type: {name}")))?;
            Ok(())
        });
        methods.add_method("getWeather", |_, this, ()| {
            Ok(this.inner.weather.weather_type.name().to_owned())
        });
        methods.add_method_mut("setWeatherIntensity", |_, this, v: f32| {
            this.inner.weather.intensity = v;
            Ok(())
        });
        methods.add_method("getWeatherIntensity", |_, this, ()| {
            Ok(this.inner.weather.intensity)
        });
        methods.add_method_mut("setWindDirection", |_, this, v: f32| {
            this.inner.weather.wind_direction = v;
            Ok(())
        });
        methods.add_method("getWindDirection", |_, this, ()| {
            Ok(this.inner.weather.wind_direction)
        });
        methods.add_method_mut("setWindSpeed", |_, this, v: f32| {
            this.inner.weather.wind_speed = v;
            Ok(())
        });
        methods.add_method("getWindSpeed", |_, this, ()| {
            Ok(this.inner.weather.wind_speed)
        });
        methods.add_method_mut(
            "setLightningColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.lightning.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );
        methods.add_method("getLightningColor", |_, this, ()| {
            let c = this.inner.lightning.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut(
            "flash",
            |_, this, (r, g, b, a, dur): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .trigger_flash(r, g, b, a.unwrap_or(1.0), dur.unwrap_or(0.2));
                Ok(())
            },
        );
        methods.add_method("isFlashing", |_, this, ()| Ok(this.inner.flash.active));
        methods.add_method_mut("shake", |_, this, (intensity, dur): (f32, Option<f32>)| {
            this.inner.trigger_shake(intensity, dur.unwrap_or(0.5));
            Ok(())
        });
        methods.add_method("isShaking", |_, this, ()| Ok(this.inner.shake.active));
        methods.add_method_mut(
            "fade",
            |_, this, (r, g, b, a, dur): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .trigger_fade(r, g, b, a.unwrap_or(1.0), dur.unwrap_or(1.0));
                Ok(())
            },
        );
        methods.add_method("isFading", |_, this, ()| Ok(this.inner.fade.active));
        methods.add_method("render", |_, this, ()| {
            let cmds = this.inner.build_render_commands();
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        methods.add_method("drawToImage", |_, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_state_to_image(w, h);
            Ok(img)
        });
        methods.add_method_mut(
            "setWater",
            |_, this, (amplitude, frequency, speed): (f32, f32, f32)| {
                this.inner.water.amplitude = amplitude;
                this.inner.water.frequency = frequency;
                this.inner.water.speed = speed;
                this.inner.water.enabled = true;
                Ok(())
            },
        );
        methods.add_method_mut(
            "setWaterTint",
            |_, this, (r, g, b, strength): (f32, f32, f32, f32)| {
                this.inner.water.tint_r = r;
                this.inner.water.tint_g = g;
                this.inner.water.tint_b = b;
                this.inner.water.tint_strength = strength;
                Ok(())
            },
        );
        methods.add_method_mut("setCustomShader", |_, this, name: Option<String>| {
            this.inner.custom_shader = name;
            Ok(())
        });
        methods.add_method("getWater", |lua, this, ()| {
            let w = &this.inner.water;
            let t = lua.create_table()?;
            t.set("enabled", w.enabled)?;
            t.set("amplitude", w.amplitude)?;
            t.set("frequency", w.frequency)?;
            t.set("speed", w.speed)?;
            t.set("tint_r", w.tint_r)?;
            t.set("tint_g", w.tint_g)?;
            t.set("tint_b", w.tint_b)?;
            t.set("tint_strength", w.tint_strength)?;
            t.set("depth_r", w.depth_r)?;
            t.set("depth_g", w.depth_g)?;
            t.set("depth_b", w.depth_b)?;
            t.set("depth_strength", w.depth_strength)?;
            t.set("time", w.time)?;
            Ok(t)
        });
        methods.add_method("type", |_, _this, ()| Ok("LOverlay"));
        methods.add_method("typeOf", |_, _this, name: String| {
            Ok(name == "Object" || name == "Overlay")
        });
    }
}
pub struct LuaScreenTransition {
    inner: crate::effect::ScreenTransition,
}
impl mlua::UserData for LuaScreenTransition {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("play", |_, this, ()| {
            this.inner.play();
            Ok(())
        });
        methods.add_method_mut("reverse", |_, this, ()| {
            this.inner.reverse();
            Ok(())
        });
        methods.add_method_mut("update", |_, this, dt: f32| Ok(this.inner.update(dt)));
        methods.add_method("progress", |_, this, ()| Ok(this.inner.progress()));
        methods.add_method("isActive", |_, this, ()| Ok(this.inner.is_active()));
        methods.add_method("isDone", |_, this, ()| Ok(this.inner.is_done()));
        methods.add_method("kind", |_, this, ()| Ok(this.inner.kind.name()));
        methods.add_method("color", |_, this, ()| {
            let c = this.inner.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut("setColor", |_, this, ct: mlua::Table| {
            this.inner.color = [
                ct.get::<_, f32>(1).unwrap_or(0.0),
                ct.get::<_, f32>(2).unwrap_or(0.0),
                ct.get::<_, f32>(3).unwrap_or(0.0),
                ct.get::<_, f32>(4).unwrap_or(1.0),
            ];
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LScreenTransition"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ScreenTransition" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newEffect",
        lua.create_function(|lua, type_name: String| {
            let effect_type = PostFxEffectType::from_name(&type_name).ok_or_else(|| {
                LuaError::RuntimeError(format!("unknown effect type: {type_name}"))
            })?;
            lua.create_userdata(LuaPostFxEffect::from_owned(PostFxEffect::new(effect_type)))
        })?,
    )?;
    tbl.set(
        "newCustomEffect",
        lua.create_function(|lua, shader_id: usize| {
            lua.create_userdata(LuaPostFxEffect::from_owned(PostFxEffect::new_custom(
                shader_id,
            )))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newStack",
        lua.create_function(move |lua, (w, h): (Option<u32>, Option<u32>)| {
            let (default_w, default_h) = {
                let s = s.borrow();
                (s.window_width, s.window_height)
            };
            let w = w.unwrap_or(default_w);
            let h = h.unwrap_or(default_h);
            lua.create_userdata(LuaPostFxStack {
                inner: PostFxStack::new(w, h),
                effects: Vec::new(),
                stack_id: NEXT_STACK_ID.fetch_add(1, Ordering::Relaxed),
                state: Rc::clone(&s),
                feedback_factor: 0.0,
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newPresetStack",
        lua.create_function(
            move |lua, (name, w, h): (String, Option<u32>, Option<u32>)| {
                let (default_w, default_h) = {
                    let borrow = s.borrow();
                    (borrow.window_width, borrow.window_height)
                };
                let w = w.unwrap_or(default_w);
                let h = h.unwrap_or(default_h);
                let preset = build_preset(&name, w, h)
                    .ok_or_else(|| LuaError::RuntimeError(format!("unknown preset '{}'", name)))?;
                let effects: Vec<Rc<RefCell<PostFxEffect>>> = preset
                    .effects
                    .into_iter()
                    .map(|e| Rc::new(RefCell::new(e)))
                    .collect();
                lua.create_userdata(LuaPostFxStack {
                    inner: preset.stack,
                    effects,
                    stack_id: NEXT_STACK_ID.fetch_add(1, Ordering::Relaxed),
                    state: Rc::clone(&s),
                    feedback_factor: 0.0,
                })
            },
        )?,
    )?;
    tbl.set(
        "newPass",
        lua.create_function(|lua, shader_id: usize| {
            lua.create_userdata(LuaPostFxEffect::from_owned(PostFxEffect::new_custom(
                shader_id,
            )))
        })?,
    )?;
    tbl.set(
        "getEffectTypes",
        lua.create_function(|_, ()| Ok(PostFxEffectType::built_in_names()))?,
    )?;
    tbl.set(
        "newImageEffect",
        lua.create_function(|lua, args: LuaMultiValue| {
            let mut ie = ImageEffect::new("");
            match args.iter().next() {
                None => {}
                Some(LuaValue::String(s)) => {
                    let name = s.to_str().map_err(LuaError::external)?.to_string();
                    let et = PostFxEffectType::from_name(&name).ok_or_else(|| {
                        LuaError::RuntimeError(format!("unknown effect type: {name}"))
                    })?;
                    let mut eff = PostFxEffect::new(et);
                    if let Some(LuaValue::Table(params)) = args.iter().nth(1) {
                        for (k, v) in params.clone().pairs::<String, f32>().flatten() {
                            eff.set_parameter(&k, v);
                        }
                    }
                    ie.add_effect(eff);
                }
                Some(LuaValue::Table(chain)) => {
                    for entry in chain.clone().sequence_values::<LuaTable>() {
                        let entry = entry?;
                        let name: String = entry
                            .get("type")
                            .or_else(|_| entry.get(1))
                            .unwrap_or_default();
                        let et = PostFxEffectType::from_name(&name).ok_or_else(|| {
                            LuaError::RuntimeError(format!("unknown effect type: {name}"))
                        })?;
                        let mut eff = PostFxEffect::new(et);
                        for (k, v) in entry.pairs::<String, LuaValue>().flatten() {
                            if k != "type" {
                                if let LuaValue::Number(n) = v {
                                    eff.set_parameter(&k, n as f32);
                                } else if let LuaValue::Integer(i) = v {
                                    eff.set_parameter(&k, i as f32);
                                }
                            }
                        }
                        ie.add_effect(eff);
                    }
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "newImageEffect: invalid arguments".to_string(),
                    ))
                }
            }
            lua.create_userdata(LuaImageEffect { inner: ie })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newOverlay",
        lua.create_function(move |lua, (w, h): (Option<u32>, Option<u32>)| {
            let width = w.unwrap_or(800);
            let height = h.unwrap_or(600);
            lua.create_userdata(LuaOverlay {
                inner: Overlay::new(width, height),
                state: s.clone(),
            })
        })?,
    )?;
    tbl.set("newTransition", lua.create_function(move |lua, (kind, duration, color_tbl): (Option<String>, Option<f32>, Option<LuaTable>)| {
            let k = crate::effect::TransitionKind::from_str(
                kind.as_deref().unwrap_or("fade"),
            );
            let dur = duration.unwrap_or(1.0);
            let color = if let Some(ct) = color_tbl {
                [
                    ct.get::<_, f32>(1).unwrap_or(0.0),
                    ct.get::<_, f32>(2).unwrap_or(0.0),
                    ct.get::<_, f32>(3).unwrap_or(0.0),
                    ct.get::<_, f32>(4).unwrap_or(1.0),
                ]
            } else {
                [0.0, 0.0, 0.0, 1.0]
            };
            lua.create_userdata(LuaScreenTransition {
                inner: crate::effect::ScreenTransition::new(k, dur, color),
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setShaderErrorDisplay",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().shader_error_display_enabled = enabled;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getShaderErrorDisplay",
        lua.create_function(move |_, ()| Ok(s.borrow().shader_error_display_enabled))?,
    )?;
    lurek.set("effect", tbl)?;
    Ok(())
}
