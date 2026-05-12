//! `lurek.camera` - Camera2D creation and manipulation for 2D viewport control.
//!
//! Each `Camera2D` has position, zoom, rotation, viewport bounds, optional world-space
//! clamping, waypoint path following, smooth zoom tweening, per-layer parallax factors,
//! and screen-world coordinate transforms.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::camera::{
    Camera2D, CameraFollowEasing, CameraPath, CameraRig2D, CameraTweenEasing, ZoomTween,
};
use crate::render::renderer::RenderCommand;
use std::collections::HashMap;

fn make_lua_camera(inner: Rc<RefCell<Camera2D>>, state: Rc<RefCell<SharedState>>) -> LuaCamera2D {
    LuaCamera2D {
        inner,
        path: RefCell::new(None),
        zoom_tween: RefCell::new(None),
        parallax: RefCell::new(HashMap::new()),
        state,
    }
}

fn parse_follow_easing(name: &str) -> CameraFollowEasing {
    match name.to_ascii_lowercase().as_str() {
        "smoothstep" | "smooth" => CameraFollowEasing::SmoothStep,
        "easeout" | "ease_out" | "ease-out" => CameraFollowEasing::EaseOutCubic,
        _ => CameraFollowEasing::Linear,
    }
}

fn parse_zoom_easing(name: Option<String>) -> CameraTweenEasing {
    match name
        .unwrap_or_else(|| "linear".to_string())
        .to_ascii_lowercase()
        .as_str()
    {
        "smoothstep" | "smooth" => CameraTweenEasing::SmoothStep,
        "easeout" | "ease_out" | "ease-out" => CameraTweenEasing::EaseOutCubic,
        _ => CameraTweenEasing::Linear,
    }
}

// ---------------------------------------------------------------------------
// LuaCamera2D UserData
// ---------------------------------------------------------------------------

/// Lua-side wrapper around a [`Camera2D`] instance.
pub struct LuaCamera2D {
    inner: Rc<RefCell<Camera2D>>,
    /// Active waypoint path follower, if any.
    path: RefCell<Option<CameraPath>>,
    /// Active smooth-zoom tween, if any.
    zoom_tween: RefCell<Option<ZoomTween>>,
    /// Per-layer parallax scale factors (`layer_name ' factor`).
    parallax: RefCell<HashMap<String, f32>>,
    /// Shared engine state for queuing render commands.
    state: Rc<RefCell<SharedState>>,
}

impl LuaCamera2D {
    pub(crate) fn visible_area(&self) -> (f32, f32, f32, f32) {
        self.inner.borrow().get_visible_area()
    }

    pub(crate) fn position(&self) -> (f32, f32) {
        self.inner.borrow().get_position()
    }
}

impl LuaUserData for LuaCamera2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setPosition --
        /// Sets the camera's world-space position to the given coordinates.
        /// @param | x | number | The X coordinate in world space
        /// @param | y | number | The Y coordinate in world space
        /// @return | nil | No return value.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_position(x, y);
            Ok(())
        });

        // -- getPosition --
        /// Returns the camera's current world-space position as two values.
        /// @return | number | Camera X coordinate in world space.
        /// @return | number | Camera Y coordinate in world space.
        methods.add_method("getPosition", |_, this, ()| {
            Ok(this.inner.borrow().get_position())
        });

        // -- setZoom --
        /// Sets the camera's uniform zoom factor.
        /// @param | zoom | number | The zoom multiplier (1.0 = 100%)
        /// @return | nil | No return value.
        methods.add_method("setZoom", |_, this, zoom: f32| {
            this.inner.borrow_mut().set_zoom(zoom);
            Ok(())
        });

        // -- getZoom --
        /// Returns the camera's current base zoom factor (before any pulse or breathing effect is applied).
        /// @return | number | The base zoom multiplier
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.borrow().get_zoom()));

        // -- setRotation --
        /// Sets the camera rotation angle in radians.
        /// @param | r | number | The rotation angle in radians
        /// @return | nil | No return value.
        methods.add_method("setRotation", |_, this, r: f32| {
            this.inner.borrow_mut().set_rotation(r);
            Ok(())
        });

        // -- getRotation --
        /// Returns the camera's current rotation angle in radians.
        /// @return | number | The rotation angle in radians
        methods.add_method("getRotation", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation())
        });

        // -- setViewport --
        /// Sets the screen-space viewport rectangle in pixels.
        /// @param | x | number | Left edge of the viewport in screen pixels
        /// @param | y | number | Top edge of the viewport in screen pixels
        /// @param | w | number | Width of the viewport in screen pixels
        /// @param | h | number | Height of the viewport in screen pixels
        /// @return | nil | No return value.
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );

        // -- getViewport --
        /// Returns the current screen-space viewport rectangle as four values.
        /// @return | number | Viewport X position in screen pixels.
        /// @return | number | Viewport Y position in screen pixels.
        /// @return | number | Viewport width in screen pixels.
        /// @return | number | Viewport height in screen pixels.
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().get_viewport())
        });

        // -- getBounds --
        /// Returns current bounds as `(ok, x, y, w, h)`.
        /// @return | boolean | True if bounds are set.
        /// @return | number | Bounds X (0 when unset).
        /// @return | number | Bounds Y (0 when unset).
        /// @return | number | Bounds width (0 when unset).
        /// @return | number | Bounds height (0 when unset).
        methods.add_method("getBounds", |_, this, ()| {
            let out = if let Some((x, y, w, h)) = this.inner.borrow().get_bounds() {
                (true, x, y, w, h)
            } else {
                (false, 0.0, 0.0, 0.0, 0.0)
            };
            Ok(out)
        });

        // -- hasBounds --
        /// Returns true if world bounds are currently set.
        /// @return | boolean | True when bounds are enabled
        methods.add_method("hasBounds", |_, this, ()| {
            Ok(this.inner.borrow().has_bounds())
        });

        // -- setBounds --
        /// Sets world-space rectangular bounds that clamp the camera position.
        /// @param | x | number | Left edge of the bounding rectangle in world space
        /// @param | y | number | Top edge of the bounding rectangle in world space
        /// @param | w | number | Width of the bounding rectangle in world units
        /// @param | h | number | Height of the bounding rectangle in world units
        /// @return | nil | No return value.
        methods.add_method(
            "setBounds",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_bounds(x, y, w, h);
                Ok(())
            },
        );

        // -- removeBounds --
        /// Removes previously set world-space bounds, allowing the camera to move freely in any direction without clamping.
        /// @return | nil | No return value.
        methods.add_method("removeBounds", |_, this, ()| {
            this.inner.borrow_mut().remove_bounds();
            Ok(())
        });

        // -- setTarget --
        /// Sets the follow target position in world space.
        /// @param | x | number | The target X coordinate in world space
        /// @param | y | number | The target Y coordinate in world space
        /// @return | nil | No return value.
        methods.add_method("setTarget", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_target(x, y);
            Ok(())
        });

        // -- getTarget --
        /// Returns current target as `(ok, x, y)`.
        /// @return | boolean | True if target is set.
        /// @return | number | Target X (0 when unset).
        /// @return | number | Target Y (0 when unset).
        methods.add_method("getTarget", |_, this, ()| {
            let out = if let Some((x, y)) = this.inner.borrow().get_target() {
                (true, x, y)
            } else {
                (false, 0.0, 0.0)
            };
            Ok(out)
        });

        // -- clearTarget --
        /// Clears the follow target so the camera stops tracking any position.
        /// @return | nil | No return value.
        methods.add_method("clearTarget", |_, this, ()| {
            this.inner.borrow_mut().clear_target();
            Ok(())
        });

        // -- setFollowSmooth --
        /// Sets the follow interpolation speed for smooth camera tracking.
        /// @param | speed | number | Interpolation speed (0.0 = instant, higher = faster catch-up)
        /// @return | nil | No return value.
        methods.add_method("setFollowSmooth", |_, this, speed: f32| {
            this.inner.borrow_mut().set_follow_smooth(speed);
            Ok(())
        });

        // -- getFollowSmooth --
        /// Returns current follow smoothing factor.
        /// @return | number | Follow smoothing factor
        methods.add_method("getFollowSmooth", |_, this, ()| {
            Ok(this.inner.borrow().get_follow_smooth())
        });

        // -- setFollowEasing --
        /// Sets the easing mode used by smooth follow interpolation.
        /// @param | easing | string | One of: "linear", "smoothstep", "easeout"
        /// @return | nil | No return value.
        methods.add_method("setFollowEasing", |_, this, easing: String| {
            this.inner
                .borrow_mut()
                .set_follow_easing(parse_follow_easing(&easing));
            Ok(())
        });

        // -- getFollowEasing --
        /// Returns the current follow easing mode.
        /// @return | string | Current follow easing mode name
        methods.add_method("getFollowEasing", |_, this, ()| {
            let mode = match this.inner.borrow().get_follow_easing() {
                CameraFollowEasing::Linear => "linear",
                CameraFollowEasing::SmoothStep => "smoothstep",
                CameraFollowEasing::EaseOutCubic => "easeout",
            };
            Ok(mode)
        });

        // -- setDeadZone --
        /// Sets the dead zone half-extents for camera follow.
        /// @param | w | number | Half-width of the dead zone in world units
        /// @param | h | number | Half-height of the dead zone in world units
        /// @return | nil | No return value.
        methods.add_method("setDeadZone", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_dead_zone(w, h);
            Ok(())
        });

        // -- getDeadZone --
        /// Returns dead-zone size as `(ok, width, height)`.
        /// @return | boolean | True if dead-zone is set.
        /// @return | number | Dead-zone width (0 when unset).
        /// @return | number | Dead-zone height (0 when unset).
        methods.add_method("getDeadZone", |_, this, ()| {
            let out = if let Some((w, h)) = this.inner.borrow().get_dead_zone() {
                (true, w, h)
            } else {
                (false, 0.0, 0.0)
            };
            Ok(out)
        });

        // -- setLookAhead --
        /// Sets the look-ahead multiplier for predictive camera follow.
        /// @param | mul | number | Look-ahead multiplier (0.0 = disabled, 1.0 = full velocity offset)
        /// @return | nil | No return value.
        methods.add_method("setLookAhead", |_, this, mul: f32| {
            this.inner.borrow_mut().set_look_ahead(mul);
            Ok(())
        });

        // -- getLookAhead --
        /// Returns current look-ahead multiplier.
        /// @return | number | Look-ahead multiplier
        methods.add_method("getLookAhead", |_, this, ()| {
            Ok(this.inner.borrow().get_look_ahead())
        });

        // -- onWindowResize --
        /// Auto-wires viewport updates to a raw window resize event.
        /// @param | window_w | number | Window width in pixels
        /// @param | window_h | number | Window height in pixels
        /// @return | nil | No return value.
        methods.add_method(
            "onWindowResize",
            |_, this, (window_w, window_h): (f32, f32)| {
                this.inner.borrow_mut().on_window_resize(window_w, window_h);
                Ok(())
            },
        );

        // -- onWindowResizeScaled --
        /// Auto-wires viewport updates to a window resize using scale-mode mapping.
        /// @param | game_w | number | Logical game width
        /// @param | game_h | number | Logical game height
        /// @param | window_w | number | Window width in pixels
        /// @param | window_h | number | Window height in pixels
        /// @param | mode | string | One of: "letterbox", "stretch", "pixelperfect"
        /// @return | nil | No return value.
        methods.add_method(
            "onWindowResizeScaled",
            |_, this, (game_w, game_h, window_w, window_h, mode): (f32, f32, f32, f32, String)| {
                let scale_mode = match mode.to_ascii_lowercase().as_str() {
                    "stretch" => crate::camera::ScaleMode::Stretch,
                    "pixelperfect" | "pixel_perfect" | "pixel-perfect" => {
                        crate::camera::ScaleMode::PixelPerfect
                    }
                    _ => crate::camera::ScaleMode::Letterbox,
                };
                this.inner
                    .borrow_mut()
                    .on_window_resize_scaled(game_w, game_h, window_w, window_h, scale_mode);
                Ok(())
            },
        );

        // -- shake --
        /// Starts a screen-shake effect with the given intensity and duration.
        /// @param | intensity | number | Maximum random offset in world units
        /// @param | duration | number | Duration of the shake effect in seconds
        /// @return | nil | No return value.
        methods.add_method("shake", |_, this, (intensity, duration): (f32, f32)| {
            this.inner.borrow_mut().shake(intensity, duration);
            Ok(())
        });

        // -- update --
        /// Advances the camera simulation by `dt` seconds.
        /// @param | dt | number | Delta time in seconds since the last frame
        /// @return | nil | No return value.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- toWorld --
        /// Converts screen-space pixel coordinates to world-space coordinates accounting for the camera's position, zoom, rotation, and viewport.
        /// @param | sx | number | Screen X coordinate in pixels
        /// @param | sy | number | Screen Y coordinate in pixels
        /// @return | number | Corresponding world-space X coordinate.
        /// @return | number | Corresponding world-space Y coordinate.
        methods.add_method("toWorld", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_world_coords(sx, sy))
        });

        // -- toScreen --
        /// Converts world-space coordinates to screen-space pixel coordinates accounting for the camera's position, zoom, rotation, and viewport.
        /// @param | wx | number | World X coordinate
        /// @param | wy | number | World Y coordinate
        /// @return | number | Corresponding screen-space X coordinate.
        /// @return | number | Corresponding screen-space Y coordinate.
        methods.add_method("toScreen", |_, this, (wx, wy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen_coords(wx, wy))
        });

        // -- getVisibleArea --
        /// Returns the axis-aligned bounding rectangle of the currently visible world area as four values.
        /// @return | number | Visible area X position in world space.
        /// @return | number | Visible area Y position in world space.
        /// @return | number | Visible area width in world units.
        /// @return | number | Visible area height in world units.
        methods.add_method("getVisibleArea", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_area())
        });

        // -- lookAt --
        /// Instantly snaps the camera to look at the given world-space position.
        /// @param | x | number | The world X coordinate to center on
        /// @param | y | number | The world Y coordinate to center on
        /// @return | nil | No return value.
        methods.add_method("lookAt", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().look_at(x, y);
            Ok(())
        });

        // -- move --
        /// Translates the camera by the given delta in world space.
        /// @param | dx | number | Horizontal offset in world units
        /// @param | dy | number | Vertical offset in world units
        /// @return | nil | No return value.
        methods.add_method("move", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().move_by(dx, dy);
            Ok(())
        });

        // -- followPath --
        /// Animates the camera along a sequence of world-space waypoints over the given duration (seconds).
        /// @param | points | table | Point array.
        /// @param | duration | number | Duration in seconds.
        /// @return | nil | No return value.
        methods.add_method(
            "followPath",
            |_, this, (points, duration): (LuaTable, f32)| {
                let mut waypoints: Vec<[f32; 2]> = Vec::new();
                for pair in points.sequence_values::<LuaTable>() {
                    let pair = pair?;
                    let x: f32 = pair.get(1).unwrap_or(0.0);
                    let y: f32 = pair.get(2).unwrap_or(0.0);
                    waypoints.push([x, y]);
                }
                *this.path.borrow_mut() = Some(CameraPath::new(waypoints, duration));
                Ok(())
            },
        );

        // -- stopPath --
        /// Cancels the active camera path animation immediately, leaving the camera at its current position along the path.
        /// @return | nil | No return value.
        methods.add_method("stopPath", |_, this, ()| {
            this.path.borrow_mut().take();
            Ok(())
        });

        // -- updatePath --
        /// Advances the path animation by `dt` seconds and applies the resulting position to the camera.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True if the path updated and produced a new position.
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
        /// Returns the fractional progress `[0, 1]` of the active path, or `1` if no path is running.
        /// @return | number | Current path progress from 0 to 1.
        methods.add_method("pathProgress", |_, this, ()| {
            Ok(this
                .path
                .borrow()
                .as_ref()
                .map(|p| p.progress())
                .unwrap_or(1.0))
        });

        // -- zoomTo --
        /// Smoothly tweens the camera zoom from its current level to `target_zoom` over `duration` seconds.
        /// @param | target_zoom | number | Target zoom.
        /// @param | duration | number | Duration in seconds.
        /// @param | easing | string? | Optional easing: "linear", "smoothstep", "easeout"
        /// @return | nil | No return value.
        methods.add_method(
            "zoomTo",
            |_, this, (target_zoom, duration, easing): (f32, f32, Option<String>)| {
                let current = this.inner.borrow().get_zoom();
                *this.zoom_tween.borrow_mut() = Some(ZoomTween::new_with_easing(
                    current,
                    target_zoom,
                    duration,
                    parse_zoom_easing(easing),
                ));
                Ok(())
            },
        );

        // -- stopZoom --
        /// Cancels the active smooth zoom tween immediately, leaving the camera at its current zoom level.
        /// @return | nil | No return value.
        methods.add_method("stopZoom", |_, this, ()| {
            this.zoom_tween.borrow_mut().take();
            Ok(())
        });

        // -- updateZoom --
        /// Advances the zoom tween by `dt` seconds and applies the resulting zoom level to the camera.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True if the zoom tween updated and produced a zoom value.
        methods.add_method("updateZoom", |_, this, dt: f32| {
            let zoom = this
                .zoom_tween
                .borrow_mut()
                .as_mut()
                .and_then(|z| z.update(dt));
            if let Some(z) = zoom {
                this.inner.borrow_mut().set_zoom(z);
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- setParallaxFactor --
        /// Sets the parallax scroll factor for the named render layer.
        /// @param | layer | string | Layer index.
        /// @param | factor | number | Factor value.
        /// @return | nil | No return value.
        methods.add_method(
            "setParallaxFactor",
            |_, this, (layer, factor): (String, f32)| {
                this.parallax.borrow_mut().insert(layer, factor);
                Ok(())
            },
        );

        // -- getParallaxFactor --
        /// Returns the parallax scroll factor for the named render layer.
        /// @param | layer | string | The render layer name to query
        /// @return | number | The parallax factor (1.0 = moves with camera)
        methods.add_method("getParallaxFactor", |_, this, layer: String| {
            Ok(*this.parallax.borrow().get(&layer).unwrap_or(&1.0))
        });

        // -- clearParallaxFactors --
        /// Removes all parallax factor overrides, resetting every layer to the default factor of 1.0 (no parallax).
        /// @return | nil | No return value.
        methods.add_method("clearParallaxFactors", |_, this, ()| {
            this.parallax.borrow_mut().clear();
            Ok(())
        });

        // -- apply --
        /// Applies this camera's transform to the render stack.
        /// @return | nil | No return value.
        methods.add_method("apply", |_, this, ()| {
            let mut state = this.state.borrow_mut();
            this.inner
                .borrow()
                .append_begin_render_commands(&mut state.render_commands);
            Ok(())
        });

        // -- reset --
        /// Pops the camera transform from the render stack.
        /// @return | nil | No return value.
        methods.add_method("reset", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });

        // -- attach --
        /// Alias for `apply()` that queues this camera's transform onto the render command stack.
        /// @return | nil | No return value.
        methods.add_method("attach", |_, this, ()| {
            let mut state = this.state.borrow_mut();
            this.inner
                .borrow()
                .append_begin_render_commands(&mut state.render_commands);
            Ok(())
        });

        // -- detach --
        /// Alias for `reset()` that removes this camera's transform from the render command stack.
        /// @return | nil | No return value.
        methods.add_method("detach", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });

        // -- Camera effects -------------------------------------------------

        // -- zoomPulse --
        /// Triggers a momentary zoom-in effect that decays back to the base zoom level via a sine envelope.
        /// @param | amplitude | number | Maximum zoom offset at the pulse peak
        /// @param | duration | number | Total duration of the pulse effect in seconds
        /// @return | nil | No return value.
        methods.add_method("zoomPulse", |_, this, (amplitude, duration): (f32, f32)| {
            this.inner
                .borrow_mut()
                .zoom_pulse
                .trigger(amplitude, duration);
            Ok(())
        });

        // -- startSway --
        /// Starts a sinusoidal x/y offset oscillation for ambient camera motion (e.g.
        /// @param | amplitude_x | number | Maximum horizontal offset in world units
        /// @param | amplitude_y | number | Maximum vertical offset in world units
        /// @param | frequency | number | Oscillation frequency in cycles per second
        /// @param | decay | number? | Decay multiplier applied each second (default 1.0 = no decay)
        /// @return | nil | No return value.
        methods.add_method("startSway", |_, this, (amplitude_x, amplitude_y, frequency, decay): (f32, f32, f32, Option<f32>)| {
                let decay = decay.unwrap_or(1.0);
                this.inner
                    .borrow_mut()
                    .sway
                    .start(amplitude_x, amplitude_y, frequency, decay);
                Ok(())
            },
        );

        // -- stopSway --
        /// Stops the active sway oscillation effect immediately, resetting the camera's offset back to zero.
        /// @return | nil | No return value.
        methods.add_method("stopSway", |_, this, ()| {
            this.inner.borrow_mut().sway.stop();
            Ok(())
        });

        // -- isSway --
        /// Returns true if the sway oscillation effect is currently running.
        /// @return | boolean | True if sway is active
        methods.add_method("isSway", |_, this, ()| {
            Ok(this.inner.borrow().sway.is_active())
        });

        // -- startBreathing --
        /// Starts a subtle periodic zoom oscillation that gives the camera a "living" feel, as if the viewport is gently breathing.
        /// @param | amplitude | number? | Peak zoom offset from base (default 0.005)
        /// @param | rate | number? | Oscillation rate in cycles per second (default 0.2)
        /// @return | nil | No return value.
        methods.add_method(
            "startBreathing",
            |_, this, (amplitude, rate): (Option<f32>, Option<f32>)| {
                let amplitude = amplitude.unwrap_or(0.005);
                let rate = rate.unwrap_or(0.2);
                this.inner.borrow_mut().breathing.start(amplitude, rate);
                Ok(())
            },
        );

        // -- stopBreathing --
        /// Stops the active breathing zoom oscillation effect immediately.
        /// @return | nil | No return value.
        methods.add_method("stopBreathing", |_, this, ()| {
            this.inner.borrow_mut().breathing.stop();
            Ok(())
        });

        // -- isBreathing --
        /// Returns true if the breathing zoom oscillation is currently active.
        /// @return | boolean | True if breathing is active
        methods.add_method("isBreathing", |_, this, ()| {
            Ok(this.inner.borrow().breathing.is_active())
        });

        // -- getEffectiveZoom --
        /// Returns the current zoom level including contributions from zoom pulse and breathing effects on top of the base zoom factor.
        /// @return | number | The total effective zoom level
        methods.add_method("getEffectiveZoom", |_, this, ()| {
            Ok(this.inner.borrow().effective_zoom())
        });

        // -- getEffectOffset --
        /// Returns the current world-space x/y offset contributed by the sway and shake effects.
        /// @return | number | World-space X offset in world units.
        /// @return | number | World-space Y offset in world units.
        methods.add_method("getEffectOffset", |_, this, ()| {
            Ok(this.inner.borrow().effect_offset())
        });

        // -- getShakeOffset --
        /// Returns current shake offset as x,y.
        /// @return | number | Shake X offset
        /// @return | number | Shake Y offset
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.borrow().get_shake_offset())
        });

        // -- getRenderOffset --
        /// Returns canonical render offset (sway + shake) as x,y.
        /// @return | number | Render X offset
        /// @return | number | Render Y offset
        methods.add_method("getRenderOffset", |_, this, ()| {
            Ok(this.inner.borrow().render_offset())
        });

        // -- Zoom constraints ──────────────────────────────────────────

        // -- setZoomConstraints --
        /// Sets minimum and maximum zoom level constraints.
        /// @param | min_zoom | number? | Minimum zoom level (nil = unconstrained)
        /// @param | max_zoom | number? | Maximum zoom level (nil = unconstrained)
        /// @return | nil | No return value.
        methods.add_method(
            "setZoomConstraints",
            |_, this, (min_zoom, max_zoom): (Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_zoom_constraints(min_zoom, max_zoom);
                Ok(())
            },
        );

        // -- getZoomConstraints --
        /// Returns current zoom constraints as `(has_min, min, has_max, max)`.
        /// @return | boolean | True if minimum zoom is constrained.
        /// @return | number | Minimum zoom value (0 when unconstrained).
        /// @return | boolean | True if maximum zoom is constrained.
        /// @return | number | Maximum zoom value (0 when unconstrained).
        methods.add_method("getZoomConstraints", |_, this, ()| {
            let (min_z, max_z) = this.inner.borrow().get_zoom_constraints();
            Ok((
                min_z.is_some(),
                min_z.unwrap_or(0.0),
                max_z.is_some(),
                max_z.unwrap_or(0.0),
            ))
        });

        // -- setZoomDamping --
        /// Sets the zoom damping factor for smooth zoom transitions.
        /// @param | damping | number | Damping factor (0.0 = instant, 1.0 = maximum smoothing)
        /// @return | nil | No return value.
        methods.add_method("setZoomDamping", |_, this, damping: f32| {
            this.inner.borrow_mut().set_zoom_damping(damping);
            Ok(())
        });

        // -- getZoomDamping --
        /// Returns the current zoom damping factor.
        /// @return | number | Zoom damping factor
        methods.add_method("getZoomDamping", |_, this, ()| {
            Ok(this.inner.borrow().get_zoom_damping())
        });

        // -- Rotation constraints ──────────────────────────────────────

        // -- setRotationConstraints --
        /// Sets minimum and maximum rotation constraints in radians.
        /// @param | min_rot | number? | Minimum rotation in radians (nil = unconstrained)
        /// @param | max_rot | number? | Maximum rotation in radians (nil = unconstrained)
        /// @return | nil | No return value.
        methods.add_method(
            "setRotationConstraints",
            |_, this, (min_rot, max_rot): (Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_rotation_constraints(min_rot, max_rot);
                Ok(())
            },
        );

        // -- getRotationConstraints --
        /// Returns current rotation constraints as `(has_min, min, has_max, max)`.
        /// @return | boolean | True if minimum rotation is constrained.
        /// @return | number | Minimum rotation value (0 when unconstrained).
        /// @return | boolean | True if maximum rotation is constrained.
        /// @return | number | Maximum rotation value (0 when unconstrained).
        methods.add_method("getRotationConstraints", |_, this, ()| {
            let (min_r, max_r) = this.inner.borrow().get_rotation_constraints();
            Ok((
                min_r.is_some(),
                min_r.unwrap_or(0.0),
                max_r.is_some(),
                max_r.unwrap_or(0.0),
            ))
        });

        // -- setRotationDamping --
        /// Sets the rotation damping factor for smooth rotation transitions.
        /// @param | damping | number | Damping factor (0.0 = instant, 1.0 = maximum smoothing)
        /// @return | nil | No return value.
        methods.add_method("setRotationDamping", |_, this, damping: f32| {
            this.inner.borrow_mut().set_rotation_damping(damping);
            Ok(())
        });

        // -- getRotationDamping --
        /// Returns the current rotation damping factor.
        /// @return | number | Rotation damping factor
        methods.add_method("getRotationDamping", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation_damping())
        });

        // -- Follow presets ────────────────────────────────────────────

        // -- presetTightFollow --
        /// Configures a tight follow setup: fast response, small dead zone, look-ahead enabled.
        /// @return | nil | No return value.
        methods.add_method("presetTightFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_tight_follow();
            Ok(())
        });

        // -- presetCinematicFollow --
        /// Configures a cinematic follow setup: slow response, large dead zone, no look-ahead.
        /// @return | nil | No return value.
        methods.add_method("presetCinematicFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_cinematic_follow();
            Ok(())
        });

        // -- presetBalancedFollow --
        /// Configures a balanced follow setup: moderate response, medium dead zone.
        /// @return | nil | No return value.
        methods.add_method("presetBalancedFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_balanced_follow();
            Ok(())
        });

        // -- presetAggressiveFollow --
        /// Configures an aggressive follow setup: maximum response, minimal dead zone, strong look-ahead.
        /// @return | nil | No return value.
        methods.add_method("presetAggressiveFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_aggressive_follow();
            Ok(())
        });

        // -- type --
        /// Returns the string type name of this userdata object.
        /// @return | string | The type name (e.g. "LScheduler", "LCamera", "LSignal")
        methods.add_method("type", |_, _, ()| Ok("LCamera"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | The type name to check against (e.g. "LScheduler", "Object")
        /// @return | boolean | True if this object matches the given type name
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCamera" || name == "Object")
        });
    }
}

/// Lua-side wrapper around a named multi-camera rig.
pub struct LuaCameraRig {
    inner: Rc<RefCell<CameraRig2D>>,
    state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaCameraRig {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- splitScreen --
        /// Configures split-screen layout and ensures left/right cameras exist.
        /// @param | window_w | number | Window width in pixels
        /// @param | window_h | number | Window height in pixels
        /// @return | nil | No return value.
        methods.add_method(
            "splitScreen",
            |_, this, (window_w, window_h): (f32, f32)| {
                this.inner
                    .borrow_mut()
                    .apply_split_screen_layout(window_w, window_h);
                Ok(())
            },
        );

        // -- minimap --
        /// Configures main+minimap layout and ensures cameras exist.
        /// @param | window_w | number | Window width in pixels
        /// @param | window_h | number | Window height in pixels
        /// @param | ratio | number? | Minimap size ratio (default 0.25)
        /// @return | nil | No return value.
        methods.add_method(
            "minimap",
            |_, this, (window_w, window_h, ratio): (f32, f32, Option<f32>)| {
                this.inner.borrow_mut().apply_minimap_layout(
                    window_w,
                    window_h,
                    ratio.unwrap_or(0.25),
                );
                Ok(())
            },
        );

        // -- pictureInPicture --
        /// Configures main+picture-in-picture layout and ensures cameras exist.
        /// @param | window_w | number | Window width in pixels
        /// @param | window_h | number | Window height in pixels
        /// @param | pip_w | number? | PiP width (default 320)
        /// @param | pip_h | number? | PiP height (default 180)
        /// @return | nil | No return value.
        methods.add_method(
            "pictureInPicture",
            |_, this, (window_w, window_h, pip_w, pip_h): (f32, f32, Option<f32>, Option<f32>)| {
                this.inner.borrow_mut().apply_picture_in_picture_layout(
                    window_w,
                    window_h,
                    pip_w.unwrap_or(320.0),
                    pip_h.unwrap_or(180.0),
                );
                Ok(())
            },
        );

        // -- setPosition --
        /// Sets a named camera position in the rig.
        /// @param | name | string | Camera name
        /// @param | x | number | World X
        /// @param | y | number | World Y
        /// @return | nil | No return value.
        methods.add_method(
            "setPosition",
            |_, this, (name, x, y): (String, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .ensure_camera(&name, 800.0, 600.0)
                    .set_position(x, y);
                Ok(())
            },
        );

        // -- setZoom --
        /// Sets a named camera zoom in the rig.
        /// @param | name | string | Camera name
        /// @param | zoom | number | Zoom value
        /// @return | nil | No return value.
        methods.add_method("setZoom", |_, this, (name, zoom): (String, f32)| {
            this.inner
                .borrow_mut()
                .ensure_camera(&name, 800.0, 600.0)
                .set_zoom(zoom);
            Ok(())
        });

        // -- setTarget --
        /// Sets a named camera follow target in the rig.
        /// @param | name | string | Camera name
        /// @param | x | number | Target X
        /// @param | y | number | Target Y
        /// @return | nil | No return value.
        methods.add_method("setTarget", |_, this, (name, x, y): (String, f32, f32)| {
            this.inner
                .borrow_mut()
                .ensure_camera(&name, 800.0, 600.0)
                .set_target(x, y);
            Ok(())
        });

        // -- updateAll --
        /// Updates all cameras in the rig.
        /// @param | dt | number | Delta time in seconds
        /// @return | nil | No return value.
        methods.add_method("updateAll", |_, this, dt: f32| {
            this.inner.borrow_mut().update_all(dt);
            Ok(())
        });

        // -- apply --
        /// Appends render commands for a named camera.
        /// @param | name | string | Camera name
        /// @return | boolean | True if camera exists and was applied
        methods.add_method("apply", |_, this, name: String| {
            let rig = this.inner.borrow();
            if let Some(cam) = rig.camera(&name) {
                let mut state = this.state.borrow_mut();
                cam.append_begin_render_commands(&mut state.render_commands);
                return Ok(true);
            }
            Ok(false)
        });

        // -- getViewport --
        /// Returns viewport for a named camera as `(ok, x, y, w, h)`.
        /// @param | name | string | Camera name
        /// @return | boolean | True if camera exists.
        /// @return | number | Viewport X (0 when camera is missing).
        /// @return | number | Viewport Y (0 when camera is missing).
        /// @return | number | Viewport width (0 when camera is missing).
        /// @return | number | Viewport height (0 when camera is missing).
        methods.add_method("getViewport", |_, this, name: String| {
            let out = if let Some((x, y, w, h)) = this.inner.borrow().viewport_of(&name) {
                (true, x, y, w, h)
            } else {
                (false, 0.0, 0.0, 0.0, 0.0)
            };
            Ok(out)
        });

        // -- names --
        /// Returns a table array of rig camera names.
        /// @return | table | Camera names array
        methods.add_method("names", |lua, this, ()| {
            let names = this.inner.borrow().camera_names();
            let table = lua.create_table()?;
            for (idx, name) in names.iter().enumerate() {
                table.set(idx + 1, name.as_str())?;
            }
            Ok(table)
        });

        // -- remove --
        /// Removes a named camera from the rig.
        /// @param | name | string | Camera name
        /// @return | boolean | True if camera existed
        methods.add_method("remove", |_, this, name: String| {
            Ok(this.inner.borrow_mut().remove_camera(&name))
        });

        // -- has --
        /// Returns true when rig contains a camera name.
        /// @param | name | string | Camera name
        /// @return | boolean | True when camera exists
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has_camera(&name))
        });

        // -- type --
        /// Returns the type name of this userdata object.
        /// @return | string | Type name string.
        methods.add_method("type", |_, _, ()| Ok("LCameraRig"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True when object matches `name`.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCameraRig" || name == "Object")
        });
    }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers the `lurek.camera` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- new --
    /// Creates a new Camera2D with the given viewport dimensions.
    /// @param | viewport_w | number? | Viewport width in pixels (default 800)
    /// @param | viewport_h | number? | Viewport height in pixels (default 600)
    /// @return | LCamera | New Camera2D with the given viewport dimensions.
    let s = state.clone();
    tbl.set(
        "new",
        lua.create_function(move |lua, (vw, vh): (Option<f32>, Option<f32>)| {
            let vw = vw.unwrap_or(800.0);
            let vh = vh.unwrap_or(600.0);
            lua.create_userdata(make_lua_camera(
                Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                s.clone(),
            ))
        })?,
    )?;

    // -- newCamera -- (alias for `new`, default 800x600 if called with no args)
    /// Creates a new 2D camera with the given viewport dimensions.
    /// @param | viewport_w | number? | Viewport width in pixels (default 800)
    /// @param | viewport_h | number? | Viewport height in pixels (default 600)
    /// @return | LCamera | New 2D camera with the given viewport dimensions.
    let s = state.clone();
    tbl.set(
        "newCamera",
        lua.create_function(move |lua, (vw, vh): (Option<f32>, Option<f32>)| {
            let vw = vw.unwrap_or(800.0);
            let vh = vh.unwrap_or(600.0);
            lua.create_userdata(make_lua_camera(
                Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                s.clone(),
            ))
        })?,
    )?;

    // -- newRig --
    /// Creates a multi-camera rig for split-screen, minimap, and PiP orchestration.
    /// @return | LCameraRig | New camera rig object.
    let s = state.clone();
    tbl.set(
        "newRig",
        lua.create_function(move |lua, ()| {
            lua.create_userdata(LuaCameraRig {
                inner: Rc::new(RefCell::new(CameraRig2D::new())),
                state: s.clone(),
            })
        })?,
    )?;

    lurek.set("camera", tbl)?;
    Ok(())
}
