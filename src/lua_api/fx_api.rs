//! `luna.fx` — Composable visual effects: post-processing pipeline and screen overlays.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::fx::{ImageEffect, Overlay, PostFxEffect, PostFxEffectType, PostFxStack, WeatherType};

// -------------------------------------------------------------------------------
// LuaPostFxEffect UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`PostFxEffect`].
pub struct LuaPostFxEffect {
    inner: PostFxEffect,
}

impl LuaUserData for LuaPostFxEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getTypeName --
        /// Returns the display name of this effect type.
        /// @return string
        methods.add_method("getTypeName", |_, this, ()| {
            Ok(this.inner.get_type_name().to_string())
        });

        // -- isBuiltIn --
        /// Returns true if this is a built-in effect, false if custom.
        /// @return boolean
        methods.add_method("isBuiltIn", |_, this, ()| Ok(this.inner.is_built_in()));

        // -- isEnabled --
        /// Returns whether this effect is currently active.
        /// @return boolean
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.enabled));

        // -- setEnabled --
        /// Enables or disables this effect.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.inner.enabled = enabled;
            Ok(())
        });

        // -- setParameter --
        /// Sets a named float parameter on this effect.
        /// @param name : string
        /// @param value : number
        /// @return nil
        methods.add_method_mut("setParameter", |_, this, (name, value): (String, f32)| {
            this.inner.set_parameter(name, value);
            Ok(())
        });

        // -- getParameter --
        /// Returns a named parameter value, or the default if not set.
        /// @param name : string
        /// @param default : number
        /// @return number
        methods.add_method("getParameter", |_, this, (name, default): (String, f32)| {
            Ok(this.inner.get_parameter(&name, default))
        });

        // -- hasParameter --
        /// Returns true if the named parameter exists on this effect.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.has_parameter(&name))
        });

        // -- getParameterNames --
        /// Returns a list of all parameter names on this effect.
        /// @return table
        methods.add_method("getParameterNames", |_, this, ()| {
            Ok(this.inner.get_parameter_names())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaPostFxStack UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`PostFxStack`].
pub struct LuaPostFxStack {
    inner: PostFxStack,
}

impl LuaUserData for LuaPostFxStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Appends an effect index to the end of the pipeline.
        /// @param effect_idx : integer
        /// @return nil
        methods.add_method_mut("add", |_, this, effect_idx: usize| {
            this.inner.add(effect_idx);
            Ok(())
        });

        // -- remove --
        /// Removes an effect index from the pipeline.
        /// @param effect_idx : integer
        /// @return boolean
        methods.add_method_mut("remove", |_, this, effect_idx: usize| {
            Ok(this.inner.remove(effect_idx))
        });

        // -- insert --
        /// Inserts an effect index at a specific position in the pipeline.
        /// @param position : integer
        /// @param effect_idx : integer
        /// @return nil
        methods.add_method_mut(
            "insert",
            |_, this, (position, effect_idx): (usize, usize)| {
                this.inner.insert(position, effect_idx);
                Ok(())
            },
        );

        // -- setEnabled --
        /// Enables or disables the effect at the given index.
        /// @param effect_idx : integer
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut(
            "setEnabled",
            |_, this, (effect_idx, enabled): (usize, bool)| {
                this.inner.set_enabled(effect_idx, enabled);
                Ok(())
            },
        );

        // -- isEnabled --
        /// Returns whether the effect at the given index is enabled.
        /// @param effect_idx : integer
        /// @return boolean
        methods.add_method("isEnabled", |_, this, effect_idx: usize| {
            Ok(this.inner.is_enabled(effect_idx))
        });

        // -- getEffectCount --
        /// Returns the number of effects in the pipeline.
        /// @return integer
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.get_effect_count())
        });

        // -- getEffect --
        /// Returns the effect index at the given pipeline position, or nil.
        /// @param index : integer
        /// @return integer?
        methods.add_method("getEffect", |_, this, index: usize| {
            Ok(this.inner.get_effect(index))
        });

        // -- getEnabledEffects --
        /// Returns a list of currently enabled effect indices.
        /// @return table
        methods.add_method("getEnabledEffects", |_, this, ()| {
            Ok(this.inner.enabled_effects())
        });

        // -- getWidth --
        /// Returns the width of the render target.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));

        // -- getHeight --
        /// Returns the height of the render target.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));

        // -- getDimensions --
        /// Returns width and height of the render target.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });

        // -- resize --
        /// Resizes the render target to the given dimensions.
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });

        // -- len --
        /// Returns the total number of effect slots in the pipeline.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));

        // -- isEmpty --
        /// Returns true if the pipeline has no effect slots.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));

        // -- clear --
        /// Removes all effects from the pipeline.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaImageEffect UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`ImageEffect`].
pub struct LuaImageEffect {
    inner: ImageEffect,
}

impl LuaUserData for LuaImageEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addEffect --
        /// Appends a post-processing effect to this image effect chain.
        /// @param effect : PostFxEffect
        /// @return nil
        methods.add_method_mut("addEffect", |_, this, effect: LuaAnyUserData| {
            let borrowed = effect.borrow::<LuaPostFxEffect>()?;
            this.inner.add_effect(borrowed.inner.clone());
            Ok(())
        });

        // -- removeByIndex --
        /// Removes the effect at the given index from the chain.
        /// @param idx : integer
        /// @return boolean
        methods.add_method_mut("removeByIndex", |_, this, idx: usize| {
            Ok(this.inner.remove_by_index(idx))
        });

        // -- removeByName --
        /// Removes the first effect matching the given type name.
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("removeByName", |_, this, name: String| {
            Ok(this.inner.remove_by_name(&name))
        });

        // -- clear --
        /// Removes all effects from the chain.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- getEffectCount --
        /// Returns the number of effects in the chain.
        /// @return integer
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.effect_count())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaOverlay UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`Overlay`].
pub struct LuaOverlay {
    inner: Overlay,
}

impl LuaUserData for LuaOverlay {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances all overlay subsystems by the given delta time.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- triggerFlash --
        /// Triggers a screen-wide colour flash effect.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "triggerFlash",
            |_, this, (r, g, b, a, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_flash(r, g, b, a, duration);
                Ok(())
            },
        );

        // -- triggerShake --
        /// Triggers a screen shake effect with the given intensity and duration.
        /// @param intensity : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "triggerShake",
            |_, this, (intensity, duration): (f32, f32)| {
                this.inner.trigger_shake(intensity, duration);
                Ok(())
            },
        );

        // -- triggerFade --
        /// Triggers a screen fade effect to the given colour and alpha.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param target_alpha : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "triggerFade",
            |_, this, (r, g, b, target_alpha, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_fade(r, g, b, target_alpha, duration);
                Ok(())
            },
        );

        // -- triggerLightning --
        /// Triggers a lightning flash effect.
        /// @return nil
        methods.add_method_mut("triggerLightning", |_, this, ()| {
            this.inner.trigger_lightning();
            Ok(())
        });

        // -- getShakeOffset --
        /// Returns the current shake displacement as x, y.
        /// @return number, number
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.get_shake_offset())
        });

        // -- isActive --
        /// Returns true if any overlay subsystem is currently active.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.inner.is_active()));

        // -- clear --
        /// Resets all overlay subsystems to their default inactive state.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- resize --
        /// Resizes the overlay to match new window dimensions.
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });

        // -- getWidth --
        /// Returns the overlay width.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));

        // -- getHeight --
        /// Returns the overlay height.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));

        // -- getDimensions --
        /// Returns the overlay width and height.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });

        // -- getFlashAlpha --
        /// Returns the current flash overlay alpha value.
        /// @return number
        methods.add_method("getFlashAlpha", |_, this, ()| {
            Ok(this.inner.get_flash_alpha())
        });

        // -- getLightningAlpha --
        /// Returns the current lightning overlay alpha value.
        /// @return number
        methods.add_method("getLightningAlpha", |_, this, ()| {
            Ok(this.inner.get_lightning_alpha())
        });

        // ── Ambient ──────────────────────────────────────────────────────────

        // -- setAmbientEnabled --
        /// Enables or disables the ambient light layer.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setAmbientEnabled", |_, this, v: bool| {
            this.inner.ambient.enabled = v;
            Ok(())
        });

        // -- isAmbientEnabled --
        /// Returns whether the ambient light layer is active.
        /// @return boolean
        methods.add_method("isAmbientEnabled", |_, this, ()| {
            Ok(this.inner.ambient.enabled)
        });

        // -- setAmbientColor --
        /// Sets the ambient light tint colour; alpha defaults to 1.0.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @return nil
        methods.add_method_mut(
            "setAmbientColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.ambient.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );

        // -- getAmbientColor --
        /// Returns the current ambient tint as r, g, b, a components.
        /// @return number, number, number, number
        methods.add_method("getAmbientColor", |_, this, ()| {
            let c = this.inner.ambient.color;
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- setTimeOfDay --
        /// Sets the simulated time-of-day (0–24) which drives ambient colour.
        /// @param hour : number
        /// @return nil
        methods.add_method_mut("setTimeOfDay", |_, this, v: f32| {
            this.inner.ambient.time_of_day = v;
            Ok(())
        });

        // -- getTimeOfDay --
        /// Returns the current simulated time-of-day (0–24).
        /// @return number
        methods.add_method("getTimeOfDay", |_, this, ()| {
            Ok(this.inner.ambient.time_of_day)
        });

        // ── Fog ──────────────────────────────────────────────────────────────

        // -- setFogEnabled --
        /// Enables or disables the fog layer.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setFogEnabled", |_, this, v: bool| {
            this.inner.fog.enabled = v;
            Ok(())
        });

        // -- isFogEnabled --
        /// Returns whether the fog layer is active.
        /// @return boolean
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog.enabled));

        // -- setFogDensity --
        /// Sets the fog density (0.0 = clear, 1.0 = fully opaque).
        /// @param density : number
        /// @return nil
        methods.add_method_mut("setFogDensity", |_, this, v: f32| {
            this.inner.fog.density = v;
            Ok(())
        });

        // -- getFogDensity --
        /// Returns the current fog density.
        /// @return number
        methods.add_method("getFogDensity", |_, this, ()| Ok(this.inner.fog.density));

        // -- setFogColor --
        /// Sets the fog tint colour; alpha defaults to 1.0.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @return nil
        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.fog.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );

        // -- getFogColor --
        /// Returns the current fog tint as r, g, b, a components.
        /// @return number, number, number, number
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog.color;
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Heat haze ────────────────────────────────────────────────────────

        // -- setHeatHazeEnabled --
        /// Enables or disables the heat-haze distortion layer.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setHeatHazeEnabled", |_, this, v: bool| {
            this.inner.heat_haze.enabled = v;
            Ok(())
        });

        // -- isHeatHazeEnabled --
        /// Returns whether the heat-haze layer is active.
        /// @return boolean
        methods.add_method("isHeatHazeEnabled", |_, this, ()| {
            Ok(this.inner.heat_haze.enabled)
        });

        // -- setHeatHazeIntensity --
        /// Sets the heat-haze distortion intensity (0.0–1.0).
        /// @param intensity : number
        /// @return nil
        methods.add_method_mut("setHeatHazeIntensity", |_, this, v: f32| {
            this.inner.heat_haze.intensity = v;
            Ok(())
        });

        // -- getHeatHazeIntensity --
        /// Returns the current heat-haze distortion intensity.
        /// @return number
        methods.add_method("getHeatHazeIntensity", |_, this, ()| {
            Ok(this.inner.heat_haze.intensity)
        });

        // ── Vignette ─────────────────────────────────────────────────────────

        // -- setVignetteEnabled --
        /// Enables or disables the screen-edge vignette layer.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setVignetteEnabled", |_, this, v: bool| {
            this.inner.vignette.enabled = v;
            Ok(())
        });

        // -- isVignetteEnabled --
        /// Returns whether the vignette layer is active.
        /// @return boolean
        methods.add_method("isVignetteEnabled", |_, this, ()| {
            Ok(this.inner.vignette.enabled)
        });

        // -- setVignetteStrength --
        /// Sets the vignette darkening strength (0.0–1.0).
        /// @param strength : number
        /// @return nil
        methods.add_method_mut("setVignetteStrength", |_, this, v: f32| {
            this.inner.vignette.strength = v;
            Ok(())
        });

        // -- getVignetteStrength --
        /// Returns the current vignette strength.
        /// @return number
        methods.add_method("getVignetteStrength", |_, this, ()| {
            Ok(this.inner.vignette.strength)
        });

        // ── Film grain ───────────────────────────────────────────────────────

        // -- setFilmGrainEnabled --
        /// Enables or disables the film-grain noise layer.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setFilmGrainEnabled", |_, this, v: bool| {
            this.inner.film_grain.enabled = v;
            Ok(())
        });

        // -- isFilmGrainEnabled --
        /// Returns whether the film-grain layer is active.
        /// @return boolean
        methods.add_method("isFilmGrainEnabled", |_, this, ()| {
            Ok(this.inner.film_grain.enabled)
        });

        // -- setFilmGrainIntensity --
        /// Sets the film-grain noise intensity (0.0–1.0).
        /// @param intensity : number
        /// @return nil
        methods.add_method_mut("setFilmGrainIntensity", |_, this, v: f32| {
            this.inner.film_grain.intensity = v;
            Ok(())
        });

        // -- getFilmGrainIntensity --
        /// Returns the current film-grain intensity.
        /// @return number
        methods.add_method("getFilmGrainIntensity", |_, this, ()| {
            Ok(this.inner.film_grain.intensity)
        });

        // ── Cloud shadows ────────────────────────────────────────────────────

        // -- setCloudShadows --
        /// Enables or disables scrolling cloud-shadow projection.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setCloudShadows", |_, this, v: bool| {
            this.inner.clouds.enabled = v;
            Ok(())
        });

        // -- isCloudShadowsEnabled --
        /// Returns whether cloud shadows are active.
        /// @return boolean
        methods.add_method("isCloudShadowsEnabled", |_, this, ()| {
            Ok(this.inner.clouds.enabled)
        });

        // -- setCloudCount --
        /// Sets the number of cloud shadow instances to render.
        /// @param count : integer
        /// @return nil
        methods.add_method_mut("setCloudCount", |_, this, v: u32| {
            this.inner.clouds.count = v;
            Ok(())
        });

        // -- getCloudCount --
        /// Returns the current cloud shadow instance count.
        /// @return integer
        methods.add_method("getCloudCount", |_, this, ()| Ok(this.inner.clouds.count));

        // -- setCloudSpeed --
        /// Sets the horizontal scroll speed of cloud shadows in pixels per second.
        /// @param speed : number
        /// @return nil
        methods.add_method_mut("setCloudSpeed", |_, this, v: f32| {
            this.inner.clouds.speed = v;
            Ok(())
        });

        // -- getCloudSpeed --
        /// Returns the current cloud shadow scroll speed.
        /// @return number
        methods.add_method("getCloudSpeed", |_, this, ()| Ok(this.inner.clouds.speed));

        // -- setCloudScale --
        /// Sets the scale multiplier applied to each cloud shadow.
        /// @param scale : number
        /// @return nil
        methods.add_method_mut("setCloudScale", |_, this, v: f32| {
            this.inner.clouds.scale = v;
            Ok(())
        });

        // -- getCloudScale --
        /// Returns the current cloud shadow scale.
        /// @return number
        methods.add_method("getCloudScale", |_, this, ()| Ok(this.inner.clouds.scale));

        // -- setCloudOpacity --
        /// Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
        /// @param opacity : number
        /// @return nil
        methods.add_method_mut("setCloudOpacity", |_, this, v: f32| {
            this.inner.clouds.opacity = v;
            Ok(())
        });

        // -- getCloudOpacity --
        /// Returns the current cloud shadow opacity.
        /// @return number
        methods.add_method("getCloudOpacity", |_, this, ()| {
            Ok(this.inner.clouds.opacity)
        });

        // ── Weather ──────────────────────────────────────────────────────────

        // -- setWeatherEnabled --
        /// Enables or disables the weather particle system.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setWeatherEnabled", |_, this, v: bool| {
            this.inner.weather.enabled = v;
            Ok(())
        });

        // -- isWeatherEnabled --
        /// Returns whether the weather particle system is active.
        /// @return boolean
        methods.add_method("isWeatherEnabled", |_, this, ()| {
            Ok(this.inner.weather.enabled)
        });

        // -- setWeather --
        /// Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
        /// @param name : string
        /// @return nil
        methods.add_method_mut("setWeather", |_, this, name: String| {
            this.inner.weather.weather_type = WeatherType::from_name(&name).ok_or_else(|| {
                LuaError::RuntimeError(format!("unknown weather type: {name}"))
            })?;
            Ok(())
        });

        // -- getWeather --
        /// Returns the name of the current weather type.
        /// @return string
        methods.add_method("getWeather", |_, this, ()| {
            Ok(this.inner.weather.weather_type.name().to_owned())
        });

        // -- setWeatherIntensity --
        /// Sets the particle spawn rate multiplier (0.0–1.0).
        /// @param intensity : number
        /// @return nil
        methods.add_method_mut("setWeatherIntensity", |_, this, v: f32| {
            this.inner.weather.intensity = v;
            Ok(())
        });

        // -- getWeatherIntensity --
        /// Returns the current weather intensity.
        /// @return number
        methods.add_method("getWeatherIntensity", |_, this, ()| {
            Ok(this.inner.weather.intensity)
        });

        // -- setWindDirection --
        /// Sets the wind direction in radians (0 = right, π/2 = down).
        /// @param radians : number
        /// @return nil
        methods.add_method_mut("setWindDirection", |_, this, v: f32| {
            this.inner.weather.wind_direction = v;
            Ok(())
        });

        // -- getWindDirection --
        /// Returns the current wind direction in radians.
        /// @return number
        methods.add_method("getWindDirection", |_, this, ()| {
            Ok(this.inner.weather.wind_direction)
        });

        // -- setWindSpeed --
        /// Sets the wind speed applied to weather particles in units per second.
        /// @param speed : number
        /// @return nil
        methods.add_method_mut("setWindSpeed", |_, this, v: f32| {
            this.inner.weather.wind_speed = v;
            Ok(())
        });

        // -- getWindSpeed --
        /// Returns the current wind speed.
        /// @return number
        methods.add_method("getWindSpeed", |_, this, ()| {
            Ok(this.inner.weather.wind_speed)
        });

        // ── Lightning color ──────────────────────────────────────────────────

        // -- setLightningColor --
        /// Sets the lightning flash tint colour; alpha defaults to 1.0.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @return nil
        methods.add_method_mut(
            "setLightningColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.lightning.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );

        // -- getLightningColor --
        /// Returns the lightning flash tint as r, g, b, a components.
        /// @return number, number, number, number
        methods.add_method("getLightningColor", |_, this, ()| {
            let c = this.inner.lightning.color;
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Shorthand screen-effects ─────────────────────────────────────────

        // -- flash --
        /// Triggers a full-screen colour flash; alpha defaults to 1.0, duration to 0.2 s.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "flash",
            |_, this, (r, g, b, a, dur): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .trigger_flash(r, g, b, a.unwrap_or(1.0), dur.unwrap_or(0.2));
                Ok(())
            },
        );

        // -- isFlashing --
        /// Returns true while a flash effect is in progress.
        /// @return boolean
        methods.add_method("isFlashing", |_, this, ()| Ok(this.inner.flash.active));

        // -- shake --
        /// Triggers a camera shake; duration defaults to 0.5 s.
        /// @param intensity : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "shake",
            |_, this, (intensity, dur): (f32, Option<f32>)| {
                this.inner.trigger_shake(intensity, dur.unwrap_or(0.5));
                Ok(())
            },
        );

        // -- isShaking --
        /// Returns true while a shake effect is in progress.
        /// @return boolean
        methods.add_method("isShaking", |_, this, ()| Ok(this.inner.shake.active));

        // -- fade --
        /// Animates a full-screen colour fade; alpha defaults to 1.0, duration to 1.0 s.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param alpha : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "fade",
            |_, this, (r, g, b, a, dur): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .trigger_fade(r, g, b, a.unwrap_or(1.0), dur.unwrap_or(1.0));
                Ok(())
            },
        );

        // -- isFading --
        /// Returns true while a fade effect is in progress.
        /// @return boolean
        methods.add_method("isFading", |_, this, ()| Ok(this.inner.fade.active));

        // ── Misc ─────────────────────────────────────────────────────────────

        // -- draw --
        /// No-op placeholder; the overlay is rendered by the engine's draw pass.
        /// @return nil
        methods.add_method("draw", |_, _this, ()| Ok(()));

        // -- type --
        /// Returns the type name of this object ("Overlay").
        /// @return string
        methods.add_method("type", |_, _this, ()| Ok("Overlay"));

        // -- typeOf --
        /// Returns true if this object is of the given type ("Object" or "Overlay").
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _this, name: String| {
            Ok(name == "Object" || name == "Overlay")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.fx` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newEffect --
    /// Creates a new built-in post-processing effect by type name.
    /// @param type_name : string
    /// @return PostFxEffect
    tbl.set(
        "newEffect",
        lua.create_function(|lua, type_name: String| {
            let effect_type = PostFxEffectType::from_name(&type_name).ok_or_else(|| {
                LuaError::RuntimeError(format!("unknown effect type: {type_name}"))
            })?;
            lua.create_userdata(LuaPostFxEffect {
                inner: PostFxEffect::new(effect_type),
            })
        })?,
    )?;

    // -- newCustomEffect --
    /// Creates a custom shader post-processing effect.
    /// @param shader_id : integer
    /// @return PostFxEffect
    tbl.set(
        "newCustomEffect",
        lua.create_function(|lua, shader_id: usize| {
            lua.create_userdata(LuaPostFxEffect {
                inner: PostFxEffect::new_custom(shader_id),
            })
        })?,
    )?;

    // -- newStack --
    /// Creates a new post-processing pipeline stack.
    /// @param width : integer
    /// @param height : integer
    /// @return PostFxStack
    tbl.set(
        "newStack",
        lua.create_function(|lua, (w, h): (u32, u32)| {
            lua.create_userdata(LuaPostFxStack {
                inner: PostFxStack::new(w, h),
            })
        })?,
    )?;

    // -- newImageEffect --
    /// Creates a new per-image effect chain.
    /// @param name : string
    /// @return ImageEffect
    tbl.set(
        "newImageEffect",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaImageEffect {
                inner: ImageEffect::new(&name),
            })
        })?,
    )?;

    // -- newOverlay --
    /// Creates a new screen overlay controller for weather, flash, shake, and fade effects.
    /// @param width : integer
    /// @param height : integer
    /// @return Overlay
    tbl.set(
        "newOverlay",
        lua.create_function(|lua, (w, h): (u32, u32)| {
            lua.create_userdata(LuaOverlay {
                inner: Overlay::new(w, h),
            })
        })?,
    )?;

    luna.set("fx", tbl)?;

    // Also expose luna.overlay as a dedicated namespace for the Overlay constructor.
    let overlay_tbl = lua.create_table()?;
    overlay_tbl.set(
        "newOverlay",
        lua.create_function(|lua, (w, h): (Option<u32>, Option<u32>)| {
            lua.create_userdata(LuaOverlay {
                inner: Overlay::new(w.unwrap_or(800), h.unwrap_or(600)),
            })
        })?,
    )?;
    luna.set("overlay", overlay_tbl)?;

    Ok(())
}
