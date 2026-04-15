//! `lurek.camera` — Camera2D creation and manipulation for 2D viewport control.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::camera::{Camera2D, CameraPath, ZoomTween};
use std::collections::HashMap;

// -------------------------------------------------------------------------------
// LuaCamera2D UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Camera2D`] instance.
pub struct LuaCamera2D {
    inner: Rc<RefCell<Camera2D>>,
    /// Active waypoint path follower, if any.
    path: RefCell<Option<CameraPath>>,
    /// Active smooth-zoom tween, if any.
    zoom_tween: RefCell<Option<ZoomTween>>,
    /// Per-layer parallax scale factors (`layer_name → factor`).
    parallax: RefCell<HashMap<String, f32>>,
}

impl LuaUserData for LuaCamera2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- setPosition --
        /// Sets the camera's world-space position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_position(x, y);
            Ok(())
        });

        // -- getPosition --
        /// Returns the camera's world-space position as x, y.
        /// @return number, number
        methods.add_method("getPosition", |_, this, ()| {
            Ok(this.inner.borrow().get_position())
        });

        // -- setZoom --
        /// Sets the uniform zoom factor (1.0 = natural size).
        /// @param zoom : number
        /// @return nil
        methods.add_method("setZoom", |_, this, zoom: f32| {
            this.inner.borrow_mut().set_zoom(zoom);
            Ok(())
        });

        // -- getZoom --
        /// Returns the current zoom factor.
        /// @return number
        methods.add_method("getZoom", |_, this, ()| {
            Ok(this.inner.borrow().get_zoom())
        });

        // -- setRotation --
        /// Sets the rotation in radians.
        /// @param r : number
        /// @return nil
        methods.add_method("setRotation", |_, this, r: f32| {
            this.inner.borrow_mut().set_rotation(r);
            Ok(())
        });

        // -- getRotation --
        /// Returns the rotation in radians.
        /// @return number
        methods.add_method("getRotation", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation())
        });

        // -- setViewport --
        /// Sets the viewport rectangle in screen pixels.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return nil
        methods.add_method("setViewport", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            this.inner.borrow_mut().set_viewport(x, y, w, h);
            Ok(())
        });

        // -- getViewport --
        /// Returns the current viewport as x, y, w, h.
        /// @return number, number, number, number
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().get_viewport())
        });

        // -- setBounds --
        /// Sets world-space bounds for camera clamping.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return nil
        methods.add_method("setBounds", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            this.inner.borrow_mut().set_bounds(x, y, w, h);
            Ok(())
        });

        // -- removeBounds --
        /// Removes previously set world-space bounds.
        /// @return nil
        methods.add_method("removeBounds", |_, this, ()| {
            this.inner.borrow_mut().remove_bounds();
            Ok(())
        });

        // -- setTarget --
        /// Sets the follow target position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setTarget", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_target(x, y);
            Ok(())
        });

        // -- clearTarget --
        /// Clears the follow target so the camera stops tracking.
        /// @return nil
        methods.add_method("clearTarget", |_, this, ()| {
            this.inner.borrow_mut().clear_target();
            Ok(())
        });

        // -- setFollowSmooth --
        /// Sets the follow smooth interpolation speed (0.0 = instant snap).
        /// @param speed : number
        /// @return nil
        methods.add_method("setFollowSmooth", |_, this, speed: f32| {
            this.inner.borrow_mut().set_follow_smooth(speed);
            Ok(())
        });

        // -- setDeadZone --
        /// Sets the dead zone half-extents for camera follow.
        /// @param w : number
        /// @param h : number
        /// @return nil
        methods.add_method("setDeadZone", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_dead_zone(w, h);
            Ok(())
        });

        // -- setLookAhead --
        /// Sets the look-ahead multiplier for follow prediction.
        /// @param mul : number
        /// @return nil
        methods.add_method("setLookAhead", |_, this, mul: f32| {
            this.inner.borrow_mut().set_look_ahead(mul);
            Ok(())
        });

        // -- shake --
        /// Starts a screen-shake effect.
        /// @param intensity : number
        /// @param duration : number
        /// @return nil
        methods.add_method("shake", |_, this, (intensity, duration): (f32, f32)| {
            this.inner.borrow_mut().shake(intensity, duration);
            Ok(())
        });

        // -- update --
        /// Advances the camera simulation by dt seconds.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- toWorld --
        /// Converts screen coordinates to world coordinates.
        /// @param sx : number
        /// @param sy : number
        /// @return number, number
        methods.add_method("toWorld", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_world_coords(sx, sy))
        });

        // -- toScreen --
        /// Converts world coordinates to screen coordinates.
        /// @param wx : number
        /// @param wy : number
        /// @return number, number
        methods.add_method("toScreen", |_, this, (wx, wy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen_coords(wx, wy))
        });

        // -- getVisibleArea --
        /// Returns the visible world area as x, y, w, h.
        /// @return number, number, number, number
        methods.add_method("getVisibleArea", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_area())
        });

        // -- lookAt --
        /// Instantly moves the camera to look at the given position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("lookAt", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().look_at(x, y);
            Ok(())
        });

        // -- move --
        /// Translates the camera by dx, dy in world space.
        /// @param dx : number
        /// @param dy : number
        /// @return nil
        methods.add_method("move", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().move_by(dx, dy);
            Ok(())
        });

        // -- followPath --
        /// Animates the camera along a sequence of world-space waypoints over
        /// the given duration (seconds). The table must be a flat array of
        /// {x, y} pairs: `{{10,20},{50,80},{100,30}}`. Call `cam:updatePath(dt)`
        /// every frame to advance the animation.
        /// @param points : table
        /// @param duration : number
        /// @return nil
        methods.add_method("followPath", |_, this, (points, duration): (LuaTable, f32)| {
            let mut waypoints: Vec<[f32; 2]> = Vec::new();
            for pair in points.sequence_values::<LuaTable>() {
                let pair = pair?;
                let x: f32 = pair.get(1).unwrap_or(0.0);
                let y: f32 = pair.get(2).unwrap_or(0.0);
                waypoints.push([x, y]);
            }
            *this.path.borrow_mut() = Some(CameraPath::new(waypoints, duration));
            Ok(())
        });

        // -- stopPath --
        /// Cancels the active camera path animation.
        /// @return nil
        methods.add_method("stopPath", |_, this, ()| {
            this.path.borrow_mut().take();
            Ok(())
        });

        // -- updatePath --
        /// Advances the path animation by `dt` seconds and applies the
        /// resulting position to the camera. Returns `true` while the path is
        /// still active, `false` once it has finished.
        /// @param dt : number
        /// @return boolean
        methods.add_method("updatePath", |_, this, dt: f32| {
            let pos = this.path.borrow_mut().as_mut().and_then(|p| p.update(dt));
            if let Some((x, y)) = pos {
                this.inner.borrow_mut().set_position(x, y);
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- pathProgress --
        /// Returns the fractional progress `[0, 1]` of the active path, or
        /// `1` if no path is running.
        /// @return number
        methods.add_method("pathProgress", |_, this, ()| {
            Ok(this.path.borrow().as_ref().map(|p| p.progress()).unwrap_or(1.0))
        });

        // -- zoomTo --
        /// Smoothly tweens the camera zoom from its current level to
        /// `target_zoom` over `duration` seconds. Call `cam:updateZoom(dt)`
        /// every frame.
        /// @param target_zoom : number
        /// @param duration : number
        /// @return nil
        methods.add_method("zoomTo", |_, this, (target_zoom, duration): (f32, f32)| {
            let current = this.inner.borrow().get_zoom();
            *this.zoom_tween.borrow_mut() = Some(ZoomTween::new(current, target_zoom, duration));
            Ok(())
        });

        // -- stopZoom --
        /// Cancels the active zoom tween.
        /// @return nil
        methods.add_method("stopZoom", |_, this, ()| {
            this.zoom_tween.borrow_mut().take();
            Ok(())
        });

        // -- updateZoom --
        /// Advances the zoom tween by `dt` seconds and applies the resulting
        /// zoom level to the camera. Returns `true` while still tweening.
        /// @param dt : number
        /// @return boolean
        methods.add_method("updateZoom", |_, this, dt: f32| {
            let zoom = this.zoom_tween.borrow_mut().as_mut().and_then(|z| z.update(dt));
            if let Some(z) = zoom {
                this.inner.borrow_mut().set_zoom(z);
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- setParallaxFactor --
        /// Sets the parallax scroll factor for the named render layer.
        /// A factor of `1.0` (default) moves with the camera; lower values
        /// create a depth illusion.
        /// @param layer : string
        /// @param factor : number
        /// @return nil
        methods.add_method("setParallaxFactor", |_, this, (layer, factor): (String, f32)| {
            this.parallax.borrow_mut().insert(layer, factor);
            Ok(())
        });

        // -- getParallaxFactor --
        /// Returns the parallax factor for the named layer, or `1.0` if unset.
        /// @param layer : string
        /// @return number
        methods.add_method("getParallaxFactor", |_, this, layer: String| {
            Ok(*this.parallax.borrow().get(&layer).unwrap_or(&1.0))
        });

        // -- clearParallaxFactors --
        /// Removes all parallax factor overrides.
        /// @return nil
        methods.add_method("clearParallaxFactors", |_, this, ()| {
            this.parallax.borrow_mut().clear();
            Ok(())
        });

        // ── Camera effects ──────────────────────────────────────────────

        // -- zoomPulse --
        /// Triggers a momentary zoom-in that decays back via a sine envelope.
        /// Replaces any currently active pulse.
        /// @param amplitude : number
        /// @param duration : number
        /// @return nil
        methods.add_method("zoomPulse", |_, this, (amplitude, duration): (f32, f32)| {
            this.inner.borrow_mut().zoom_pulse.trigger(amplitude, duration);
            Ok(())
        });

        // -- startSway --
        /// Starts a sinusoidal x/y offset oscillation (e.g., boat rocking).
        /// @param amplitude_x : number
        /// @param amplitude_y : number
        /// @param frequency : number
        /// @param decay : number?
        /// @return nil
        methods.add_method(
            "startSway",
            |_, this, (amplitude_x, amplitude_y, frequency, decay): (f32, f32, f32, Option<f32>)| {
                let decay = decay.unwrap_or(1.0);
                this.inner
                    .borrow_mut()
                    .sway
                    .start(amplitude_x, amplitude_y, frequency, decay);
                Ok(())
            },
        );

        // -- stopSway --
        /// Stops the active sway effect immediately.
        /// @return nil
        methods.add_method("stopSway", |_, this, ()| {
            this.inner.borrow_mut().sway.stop();
            Ok(())
        });

        // -- isSway --
        /// Returns true if the sway effect is currently active.
        /// @return boolean
        methods.add_method("isSway", |_, this, ()| {
            Ok(this.inner.borrow().sway.is_active())
        });

        // -- startBreathing --
        /// Starts a subtle periodic zoom oscillation for a "living camera" feel.
        /// @param amplitude : number?
        /// @param rate : number?
        /// @return nil
        methods.add_method("startBreathing", |_, this, (amplitude, rate): (Option<f32>, Option<f32>)| {
            let amplitude = amplitude.unwrap_or(0.005);
            let rate = rate.unwrap_or(0.2);
            this.inner.borrow_mut().breathing.start(amplitude, rate);
            Ok(())
        });

        // -- stopBreathing --
        /// Stops the active breathing effect.
        /// @return nil
        methods.add_method("stopBreathing", |_, this, ()| {
            this.inner.borrow_mut().breathing.stop();
            Ok(())
        });

        // -- isBreathing --
        /// Returns true if the breathing effect is currently active.
        /// @return boolean
        methods.add_method("isBreathing", |_, this, ()| {
            Ok(this.inner.borrow().breathing.is_active())
        });

        // -- getEffectiveZoom --
        /// Returns the current zoom level including zoom pulse and breathing deltas.
        /// @return number
        methods.add_method("getEffectiveZoom", |_, this, ()| {
            Ok(this.inner.borrow().effective_zoom())
        });

        // -- getEffectOffset --
        /// Returns the current sway x, y world-space offset.
        /// @return number, number
        methods.add_method("getEffectOffset", |_, this, ()| {
            Ok(this.inner.borrow().effect_offset())
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.camera` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- new --
    /// Creates a new Camera2D with the given viewport dimensions.
    /// @param viewport_w : number
    /// @param viewport_h : number
    /// @return Camera2D
    tbl.set(
        "new",
        lua.create_function(|lua, (vw, vh): (f32, f32)| {
            lua.create_userdata(LuaCamera2D {
                inner: Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                path: RefCell::new(None),
                zoom_tween: RefCell::new(None),
                parallax: RefCell::new(HashMap::new()),
            })
        })?,
    )?;

    luna.set("camera", tbl)?;
    Ok(())
}
