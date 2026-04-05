//! Lua API bindings for the `luna.overlay.*` screen-effect overlay module.
//!
//! Registers the `luna.overlay` table and exposes a single factory:
//!
//! - `luna.overlay.newOverlay(width?, height?)` â€” creates a `LuaOverlay`
//!   UserData object.
//!
//! All overlay state lives entirely inside an `Rc<RefCell<Overlay>>`; the
//! `LuaOverlay` wrapper holds a clone of that smart pointer. Calling any
//! method borrows the `RefCell` for the duration of the call, then
//! releases it â€” the engine never holds a long-lived `borrow_mut` across
//! Lua callbacks.
//!
//! The `register` function is called once during engine startup by the
//! `lua_api` module registration chain; it adds the `luna.overlay` table
//! to the root `luna` global.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::fx::screen::{Overlay, WeatherType};

// ---------------------------------------------------------------------------
// LuaOverlay
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for the composable screen-effect overlay.
///
/// This is a thin `mlua` UserData shim around `Rc<RefCell<Overlay>>`. All
/// Lua method calls borrow the inner `Overlay` for the duration of the
/// call and release it immediately, making it safe to pass the same
/// `LuaOverlay` to multiple closures. Cloning the userdata shares the
/// same underlying `Overlay` â€” there is no deep copy.
///
/// # Fields
/// - `inner` â€” `Rc<RefCell<Overlay>>` â€” Shared reference to the overlay state.
#[derive(Clone)]
pub(crate) struct LuaOverlay {
    inner: Rc<RefCell<Overlay>>,
}

impl LunaType for LuaOverlay {
    const TYPE_NAME: &'static str = "Overlay";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaOverlay {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // ===================================================================
        // Core Lifecycle
        // ===================================================================

        /// Advances all active overlay subsystems by `dt` seconds.
        ///
        /// Drives weather particle spawning and culling, flash and shake
        /// decay, fade interpolation, cloud scroll accumulation, and
        /// lightning deactivation. Call exactly once per frame in
        /// `luna.update(dt)` before reading any derived state such as
        /// `getShakeOffset` or `isFlashing`.
        /// @param dt : number
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Placeholder for draw â€” actual rendering handled by the game loop.
        methods.add_method("draw", |_, _this, ()| Ok(()));

        /// Updates the internal canvas dimensions on window resize.
        ///
        /// Informs the weather particle spawner of the new screen bounds so
        /// that particles are culled and spawned correctly after a window
        /// resize event. Does not drop existing particles.
        /// @param width : number
        /// @param height : number
        methods.add_method("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.borrow_mut().resize(w, h);
            Ok(())
        });

        /// Returns the overlay canvas width in pixels.
        ///
        /// Reflects the value passed to `newOverlay` or the most recent
        /// `resize` call.
        /// @return number
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        /// Returns the overlay canvas height in pixels.
        ///
        /// Reflects the value passed to `newOverlay` or the most recent
        /// `resize` call.
        /// @return number
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        /// Returns both canvas dimensions as `(width, height)`.
        ///
        /// Convenience function; equivalent to calling `getWidth()` and
        /// `getHeight()` separately but in a single Lua call.
        /// @return number, number
        methods.add_method("getDimensions", |_, this, ()| {
            let o = this.inner.borrow();
            let (w, h) = o.get_dimensions();
            Ok((w, h))
        });

        /// Resets all overlay subsystems to their inactive defaults.
        ///
        /// Equivalent to calling `Overlay::clear()` â€” drops all live weather
        /// particles, deactivates flash/shake/fade/lightning, and disables
        /// ambient, clouds, fog, heat haze, vignette, and film grain.
        /// All parameters (intensity, colour, duration) are reset to
        /// their initial values. Useful when transitioning between scenes.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        /// Returns `true` if any overlay subsystem is currently active.
        ///
        /// Checks weather enabled, ambient enabled, flash/shake/fade/lightning
        /// active, clouds enabled, fog enabled, heat haze enabled, vignette
        /// enabled, and film grain enabled. Returns `false` when the overlay
        /// has been cleared or was never activated.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| {
            Ok(this.inner.borrow().is_active())
        });

        // ===================================================================
        // Ambient Lighting
        // ===================================================================

        /// Sets the ambient screen tint colour.
        ///
        /// When ambient cycling is disabled (`setAmbientEnabled(false)`) this
        /// colour is applied directly as a persistent full-screen tint each
        /// frame. When cycling is enabled, this value is overwritten each
        /// frame by `compute_color_from_time`. Alpha defaults to 1.0.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number (optional)
        methods.add_method(
            "setAmbientColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut o = this.inner.borrow_mut();
                o.ambient.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );

        /// Returns the current ambient tint colour as `(r, g, b, a)`.
        ///
        /// When time-of-day cycling is active the returned value may change
        /// every frame as `compute_color_from_time` advances.
        /// @return number, number, number, number
        methods.add_method("getAmbientColor", |_, this, ()| {
            let o = this.inner.borrow();
            let c = o.ambient.color;
            Ok((c[0], c[1], c[2], c[3]))
        });

        /// Sets the time-of-day value that drives ambient colour cycling.
        ///
        /// The value is in 24-hour floating-point format (0.0 = midnight,
        /// 12.0 = noon, 24.0 wraps to midnight again). Has no visible
        /// effect unless ambient cycling is enabled via `setAmbientEnabled`.
        /// @param hour : number
        methods.add_method("setTimeOfDay", |_, this, hour: f32| {
            this.inner.borrow_mut().ambient.time_of_day = hour;
            Ok(())
        });

        /// Returns the current time-of-day value (0.0â€“24.0).
        /// @return number
        methods.add_method("getTimeOfDay", |_, this, ()| {
            Ok(this.inner.borrow().ambient.time_of_day)
        });

        /// Enables or disables automatic time-of-day ambient colour cycling.
        ///
        /// When `true`, `update()` calls `compute_color_from_time()` each
        /// frame and overwrites `ambient.color`. When `false`, the colour
        /// set via `setAmbientColor` is used as a static tint.
        /// @param enabled : boolean
        methods.add_method("setAmbientEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().ambient.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if automatic ambient colour cycling is enabled.
        /// @return boolean
        methods.add_method("isAmbientEnabled", |_, this, ()| {
            Ok(this.inner.borrow().ambient.enabled)
        });

        // ===================================================================
        // Weather System
        // ===================================================================

        /// Sets the active weather type by name.
        ///
        /// Valid names: `"none"`, `"rain"`, `"snow"`, `"hail"`, `"dust"`,
        /// `"leaves"`, `"ash"`, `"pollen"`. The new type takes effect on the
        /// next `update` call â€” existing particles are not cleared, so there
        /// may be a brief mix of old and new particle behaviors. Returns a
        /// Lua error if `name` is unrecognised.
        /// @param weather_type : string
        methods.add_method("setWeather", |_, this, name: String| {
            let wt = WeatherType::from_name(&name).ok_or_else(|| {
                LuaError::external(format!(
                    "Unknown weather type '{}'. Expected one of: none, rain, snow, hail, dust, leaves, ash, pollen",
                    name
                ))
            })?;
            this.inner.borrow_mut().weather.weather_type = wt;
            Ok(())
        });

        /// Returns the current weather type as a lowercase string name.
        /// @return string
        methods.add_method("getWeather", |_, this, ()| {
            Ok(this.inner.borrow().weather.weather_type.name().to_string())
        });

        /// Sets the weather particle density.
        ///
        /// Controls both the maximum particle count (up to 200) and the
        /// spawn rate. 0.0 stops spawning; 1.0 produces the maximum
        /// particle density for the current weather type.
        /// @param intensity : number
        methods.add_method("setWeatherIntensity", |_, this, intensity: f32| {
            this.inner.borrow_mut().weather.intensity = intensity;
            Ok(())
        });

        /// Returns the weather particle density (0.0â€“1.0).
        /// @return number
        methods.add_method("getWeatherIntensity", |_, this, ()| {
            Ok(this.inner.borrow().weather.intensity)
        });

        /// Sets the wind direction as an angle in radians.
        ///
        /// 0.0 blows particles to the right; `math.pi / 2` blows downward.
        /// Combined with `setWindSpeed`, this drifts all live particles
        /// each frame by the wind velocity vector.
        /// @param angle : number
        methods.add_method("setWindDirection", |_, this, angle: f32| {
            this.inner.borrow_mut().weather.wind_direction = angle;
            Ok(())
        });

        /// Returns the wind direction in radians.
        /// @return number
        methods.add_method("getWindDirection", |_, this, ()| {
            Ok(this.inner.borrow().weather.wind_direction)
        });

        /// Sets the wind speed in pixels per second.
        ///
        /// Adds a global velocity offset to every live weather particle each
        /// frame. 0.0 disables wind drift.
        /// @param speed : number
        methods.add_method("setWindSpeed", |_, this, speed: f32| {
            this.inner.borrow_mut().weather.wind_speed = speed;
            Ok(())
        });

        /// Returns the wind speed in pixels per second.
        /// @return number
        methods.add_method("getWindSpeed", |_, this, ()| {
            Ok(this.inner.borrow().weather.wind_speed)
        });

        /// Enables or disables the weather particle spawner.
        ///
        /// When disabled, no new particles are spawned but existing ones
        /// continue to move and age until they leave the screen. Set the
        /// weather type to `"none"` first if you want an immediate cutoff.
        /// @param enabled : boolean
        methods.add_method("setWeatherEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().weather.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if the weather particle spawner is enabled.
        /// @return boolean
        methods.add_method("isWeatherEnabled", |_, this, ()| {
            Ok(this.inner.borrow().weather.enabled)
        });

        // ===================================================================
        // Screen Effects
        // ===================================================================

        /// Triggers a full-screen colour flash.
        ///
        /// Immediately overlays the screen with the given colour and linearly
        /// fades it out over `duration` seconds. Calling while a flash is
        /// already in progress restarts it from the new colour and alpha.
        /// Alpha defaults to 1.0; duration defaults to 0.2 s.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number (optional)
        /// @param duration : number (optional)
        methods.add_method(
            "flash",
            |_, this, (r, g, b, a, duration): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner.borrow_mut().trigger_flash(
                    r,
                    g,
                    b,
                    a.unwrap_or(1.0),
                    duration.unwrap_or(0.2),
                );
                Ok(())
            },
        );

        /// Triggers a camera-shake effect.
        ///
        /// Generates per-frame pixel offsets using a fast xorshift PRNG.
        /// The peak offset is `intensity` pixels and decays linearly to
        /// zero by the end of `duration` seconds. Calling while a shake is
        /// active restarts it at full `intensity`. Duration defaults to 0.5 s.
        /// @param intensity : number
        /// @param duration : number (optional)
        methods.add_method(
            "shake",
            |_, this, (intensity, duration): (f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .trigger_shake(intensity, duration.unwrap_or(0.5));
                Ok(())
            },
        );

        /// Starts a smooth full-screen colour fade.
        ///
        /// Interpolates `color[3]` from the current alpha to `target_alpha`
        /// over `duration` seconds. The start alpha is captured from the
        /// current fade state, so chained fade-in / fade-out transitions
        /// are seamless. `target_alpha` defaults to 1.0; duration defaults
        /// to 1.0 s.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param target_alpha : number (optional)
        /// @param duration : number (optional)
        methods.add_method(
            "fade",
            |_,
             this,
             (r, g, b, target_alpha, duration): (
                f32,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
            )| {
                this.inner.borrow_mut().trigger_fade(
                    r,
                    g,
                    b,
                    target_alpha.unwrap_or(1.0),
                    duration.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        /// Returns the current camera-shake pixel offset as `(x, y)`.
        ///
        /// Returns `(0, 0)` when no shake is active. The renderer should
        /// offset all draw operations by this pair to apply the shake.
        /// @return number, number
        methods.add_method("getShakeOffset", |_, this, ()| {
            let (x, y) = this.inner.borrow().get_shake_offset();
            Ok((x, y))
        });

        /// Returns `true` while a flash is fading out.
        /// @return boolean
        methods.add_method("isFlashing", |_, this, ()| {
            Ok(this.inner.borrow().flash.active)
        });

        /// Returns `true` while a camera shake is in progress.
        /// @return boolean
        methods.add_method("isShaking", |_, this, ()| {
            Ok(this.inner.borrow().shake.active)
        });

        /// Returns `true` while a fade transition is in progress.
        /// @return boolean
        methods.add_method("isFading", |_, this, ()| {
            Ok(this.inner.borrow().fade.active)
        });

        // ===================================================================
        // Cloud Shadows
        // ===================================================================

        /// Enables or disables the scrolling cloud shadow overlay.
        ///
        /// Cloud shadows are rendered as soft blob-shaped shadow blobs
        /// drifting horizontally across the scene. Configure their
        /// appearance with `setCloudCount`, `setCloudScale`, and
        /// `setCloudOpacity`.
        /// @param enabled : boolean
        methods.add_method("setCloudShadows", |_, this, enabled: bool| {
            this.inner.borrow_mut().clouds.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if the cloud shadow overlay is enabled.
        /// @return boolean
        methods.add_method("isCloudShadowsEnabled", |_, this, ()| {
            Ok(this.inner.borrow().clouds.enabled)
        });

        /// Sets the number of cloud shadow blobs rendered each frame.
        ///
        /// Higher counts produce denser, more uniform coverage. Each blob
        /// is positioned pseudo-randomly based on its index, so the layout
        /// is consistent across frames.
        /// @param count : number
        methods.add_method("setCloudCount", |_, this, count: u32| {
            this.inner.borrow_mut().clouds.count = count;
            Ok(())
        });

        /// Returns the current cloud shadow blob count.
        /// @return number
        methods.add_method("getCloudCount", |_, this, ()| {
            Ok(this.inner.borrow().clouds.count)
        });

        /// Sets the horizontal scroll speed of cloud shadows in pixels per second.
        ///
        /// The internal `offset` accumulator grows without bound; the renderer
        /// wraps it modulo screen width so shadows loop seamlessly.
        /// @param speed : number
        methods.add_method("setCloudSpeed", |_, this, speed: f32| {
            this.inner.borrow_mut().clouds.speed = speed;
            Ok(())
        });

        /// Returns the cloud shadow scroll speed in pixels per second.
        /// @return number
        methods.add_method("getCloudSpeed", |_, this, ()| {
            Ok(this.inner.borrow().clouds.speed)
        });

        /// Sets the relative size scale of each cloud shadow blob.
        ///
        /// 1.0 is the default blob size; smaller values produce compact
        /// dappled shadows; larger values produce wide overcast patches.
        /// @param scale : number
        methods.add_method("setCloudScale", |_, this, scale: f32| {
            this.inner.borrow_mut().clouds.scale = scale;
            Ok(())
        });

        /// Returns the cloud shadow blob size scale.
        /// @return number
        methods.add_method("getCloudScale", |_, this, ()| {
            Ok(this.inner.borrow().clouds.scale)
        });

        /// Sets the cloud shadow overlay opacity (0.0 = invisible, 1.0 = fully dark).
        ///
        /// Controls how darkly the shadow blobs are blended over the scene.
        /// 0.3 gives a subtle day-time look; 0.7â€“0.9 simulates heavy overcast.
        /// @param opacity : number
        methods.add_method("setCloudOpacity", |_, this, opacity: f32| {
            this.inner.borrow_mut().clouds.opacity = opacity;
            Ok(())
        });

        /// Returns the cloud shadow opacity (0.0â€“1.0).
        /// @return number
        methods.add_method("getCloudOpacity", |_, this, ()| {
            Ok(this.inner.borrow().clouds.opacity)
        });

        // ===================================================================
        // Atmospheric Fog
        // ===================================================================

        /// Enables or disables atmospheric fog.
        /// @param enabled : boolean
        /// Enables or disables the atmospheric fog overlay.
        ///
        /// When enabled, a translucent colour rectangle is blended over the
        /// full scene every frame. Configure thickness via `setFogDensity`
        /// and colour via `setFogColor`.
        /// @param enabled : boolean
        methods.add_method("setFogEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().fog.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if the atmospheric fog overlay is enabled.
        /// @return boolean
        methods.add_method("isFogEnabled", |_, this, ()| {
            Ok(this.inner.borrow().fog.enabled)
        });

        /// Sets the fog density (0.0 = invisible, 1.0 = fully opaque).
        ///
        /// Maps directly to the alpha of the fog colour overlay.
        /// @param density : number
        methods.add_method("setFogDensity", |_, this, density: f32| {
            this.inner.borrow_mut().fog.density = density;
            Ok(())
        });

        /// Returns the current fog density (0.0â€“1.0).
        /// @return number
        methods.add_method("getFogDensity", |_, this, ()| {
            Ok(this.inner.borrow().fog.density)
        });

        /// Sets the fog tint colour. Alpha defaults to 1.0.
        ///
        /// The rendered fog blends this colour at the opacity set by
        /// `setFogDensity`. A grey-blue tint simulates cool morning mist;
        /// warm orange-gold simulates dust storm haze.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number (optional)
        methods.add_method(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.borrow_mut().fog.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );

        /// Returns the current fog colour as `(r, g, b, a)`.
        /// @return number, number, number, number
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.borrow().fog.color;
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ===================================================================
        // Heat Haze
        // ===================================================================

        /// Enables or disables UV-distortion heat shimmer.
        ///
        /// When enabled, the renderer applies a time-animated sine wave
        /// displacement to the scene's UV coordinates, simulating the
        /// wavering distortion seen above hot surfaces.
        /// @param enabled : boolean
        methods.add_method("setHeatHazeEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().heat_haze.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if heat haze distortion is enabled.
        /// @return boolean
        methods.add_method("isHeatHazeEnabled", |_, this, ()| {
            Ok(this.inner.borrow().heat_haze.enabled)
        });

        /// Sets the heat haze distortion intensity.
        ///
        /// Controls the peak UV displacement in pixels. 0.2â€“2.0 gives
        /// subtle mirage shimmer; higher values are suitable for extreme
        /// heat or magical warp effects.
        /// @param intensity : number
        methods.add_method("setHeatHazeIntensity", |_, this, intensity: f32| {
            this.inner.borrow_mut().heat_haze.intensity = intensity;
            Ok(())
        });

        /// Returns the heat haze distortion intensity.
        /// @return number
        methods.add_method("getHeatHazeIntensity", |_, this, ()| {
            Ok(this.inner.borrow().heat_haze.intensity)
        });

        // ===================================================================
        // Vignette
        // ===================================================================

        /// Enables or disables screen-edge darkening (vignette).
        ///
        /// The vignette grades from transparent at the screen centre to
        /// near-black at the corners. Useful for suggesting restricted
        /// vision, dramatic tension, or a cinematic look.
        /// @param enabled : boolean
        methods.add_method("setVignetteEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().vignette.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if the vignette overlay is enabled.
        /// @return boolean
        methods.add_method("isVignetteEnabled", |_, this, ()| {
            Ok(this.inner.borrow().vignette.enabled)
        });

        /// Sets the vignette darkening strength (0.0â€“1.0).
        ///
        /// 0.0 is invisible; 0.5 is a gentle filmic border; 1.0 crushes
        /// corners to near-black.
        /// @param strength : number
        methods.add_method("setVignetteStrength", |_, this, strength: f32| {
            this.inner.borrow_mut().vignette.strength = strength;
            Ok(())
        });

        /// Returns the current vignette darkening strength (0.0â€“1.0).
        /// @return number
        methods.add_method("getVignetteStrength", |_, this, ()| {
            Ok(this.inner.borrow().vignette.strength)
        });

        // ===================================================================
        // Film Grain
        // ===================================================================

        /// Enables or disables per-frame random film grain noise.
        ///
        /// The noise pattern is regenerated every frame so it does not
        /// repeat or create a visible flicker texture.
        /// @param enabled : boolean
        methods.add_method("setFilmGrainEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().film_grain.enabled = enabled;
            Ok(())
        });

        /// Returns `true` if film grain noise is enabled.
        /// @return boolean
        methods.add_method("isFilmGrainEnabled", |_, this, ()| {
            Ok(this.inner.borrow().film_grain.enabled)
        });

        /// Sets the film grain noise amplitude (0.0â€“1.0).
        ///
        /// 0.1â€“0.3 gives a subtle cinematic look. Values above 0.5
        /// produce heavy grain that can obscure fine detail.
        /// @param intensity : number
        methods.add_method("setFilmGrainIntensity", |_, this, intensity: f32| {
            this.inner.borrow_mut().film_grain.intensity = intensity;
            Ok(())
        });

        /// Returns the current film grain noise amplitude (0.0â€“1.0).
        /// @return number
        methods.add_method("getFilmGrainIntensity", |_, this, ()| {
            Ok(this.inner.borrow().film_grain.intensity)
        });

        // ===================================================================
        // Lightning
        // ===================================================================

        /// Triggers a one-shot lightning flash.
        ///
        /// Fires a brief hard white flash (default 0.15 s). Calling while
        /// a flash is in progress restarts it from full brightness.
        /// Customise the flash colour first with `setLightningColor`.
        methods.add_method("triggerLightning", |_, this, ()| {
            this.inner.borrow_mut().trigger_lightning();
            Ok(())
        });

        /// Sets the lightning flash colour. Alpha defaults to 0.8.
        ///
        /// For realistic lightning use near-white (0.9, 0.9, 1.0). For
        /// coloured magical effects any hue may be used.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number (optional)
        methods.add_method(
            "setLightningColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.borrow_mut().lightning.color = [r, g, b, a.unwrap_or(0.8)];
                Ok(())
            },
        );

        /// Returns the current lightning flash colour as `(r, g, b, a)`.
        /// @return number, number, number, number
        methods.add_method("getLightningColor", |_, this, ()| {
            let c = this.inner.borrow().lightning.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
    }
}

// ---------------------------------------------------------------------------
// Module registration
// ---------------------------------------------------------------------------

/// Registers the `luna.overlay.*` Lua API.
///
/// Creates the `luna.overlay` sub-table and adds the `newOverlay` factory
/// function, which returns a fully initialised `LuaOverlay` UserData.
/// All subsystem methods (weather, ambient, flash, shake, fade, clouds,
/// fog, heat haze, vignette, film grain, lightning) are registered on
/// the `LuaOverlay` UserData type via its `LuaUserData` impl.
///
/// # Parameters
/// - `lua` â€” `&Lua` â€” The active Lua VM.
/// - `luna` â€” `&LuaTable` â€” The root `luna` global table.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let overlay_table = lua.create_table()?;

    // luna.overlay.newOverlay(width?, height?)
    overlay_table.set(
        "newOverlay",
        lua.create_function(|_, (width, height): (Option<u32>, Option<u32>)| {
            let w = width.unwrap_or(800);
            let h = height.unwrap_or(600);
            Ok(LuaOverlay {
                inner: Rc::new(RefCell::new(Overlay::new(w, h))),
            })
        })?,
    )?;

    luna.set("overlay", overlay_table)?;
    Ok(())
}

