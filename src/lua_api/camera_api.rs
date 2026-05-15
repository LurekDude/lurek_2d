//! `lurek.camera` -- Camera bindings for 2D transforms, targets, bounds, screen conversion, paths, zoom tweens, parallax factors, effects, constraints, presets, and camera rigs.

use super::SharedState;
use crate::camera::{
    Camera2D, CameraFollowEasing, CameraPath, CameraRig2D, CameraTweenEasing, ZoomTween,
};
use crate::render::renderer::RenderCommand;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
/// Builds a Lua camera handle with fresh path, zoom tween, and parallax state.
fn make_lua_camera(inner: Rc<RefCell<Camera2D>>, state: Rc<RefCell<SharedState>>) -> LuaCamera2D {
    LuaCamera2D {
        inner,
        path: RefCell::new(None),
        zoom_tween: RefCell::new(None),
        parallax: RefCell::new(HashMap::new()),
        state,
    }
}
/// Parses a Lua follow easing name into a camera follow easing mode.
fn parse_follow_easing(name: &str) -> CameraFollowEasing {
    match name.to_ascii_lowercase().as_str() {
        "smoothstep" | "smooth" => CameraFollowEasing::SmoothStep,
        "easeout" | "ease_out" | "ease-out" => CameraFollowEasing::EaseOutCubic,
        _ => CameraFollowEasing::Linear,
    }
}
/// Parses an optional Lua zoom easing name into a zoom tween easing mode.
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
/// Lua-side 2D camera handle with transforms, effects, bounds, and render command access.
pub struct LuaCamera2D {
    /// Shared camera state used by all camera methods.
    inner: Rc<RefCell<Camera2D>>,
    /// Optional active path followed by `updatePath`.
    path: RefCell<Option<CameraPath>>,
    /// Optional active zoom tween followed by `updateZoom`.
    zoom_tween: RefCell<Option<ZoomTween>>,
    /// Per-layer parallax factors keyed by layer name.
    parallax: RefCell<HashMap<String, f32>>,
    /// Shared runtime state receiving camera render transform commands.
    state: Rc<RefCell<SharedState>>,
}
impl LuaCamera2D {
    /// Returns the camera visible area tuple for engine-side helpers.
    pub(crate) fn visible_area(&self) -> (f32, f32, f32, f32) {
        self.inner.borrow().get_visible_area()
    }
    /// Returns the camera position tuple for engine-side helpers.
    pub(crate) fn position(&self) -> (f32, f32) {
        self.inner.borrow().get_position()
    }
}
impl LuaUserData for LuaCamera2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setPosition --
        /// Sets the camera world position.
        /// @param | x | number | Camera X position in world units.
        /// @param | y | number | Camera Y position in world units.
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_position(x, y);
            Ok(())
        });
        // -- getPosition --
        /// Returns the camera world position.
        /// @return | number, number | Camera X and Y position in world units.
        methods.add_method("getPosition", |_, this, ()| {
            Ok(this.inner.borrow().get_position())
        });
        // -- setZoom --
        /// Sets the camera zoom factor.
        /// @param | zoom | number | Zoom factor applied to world rendering.
        /// @return | nil | No value is returned.
        methods.add_method("setZoom", |_, this, zoom: f32| {
            this.inner.borrow_mut().set_zoom(zoom);
            Ok(())
        });
        // -- getZoom --
        /// Returns the camera zoom factor.
        /// @return | number | Current zoom factor.
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.borrow().get_zoom()));
        // -- setRotation --
        /// Sets the camera rotation.
        /// @param | r | number | Rotation in radians.
        /// @return | nil | No value is returned.
        methods.add_method("setRotation", |_, this, r: f32| {
            this.inner.borrow_mut().set_rotation(r);
            Ok(())
        });
        // -- getRotation --
        /// Returns the camera rotation.
        /// @return | number | Current rotation in radians.
        methods.add_method("getRotation", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation())
        });
        // -- setViewport --
        /// Sets the camera viewport rectangle.
        /// @param | x | number | Viewport X coordinate in screen pixels.
        /// @param | y | number | Viewport Y coordinate in screen pixels.
        /// @param | w | number | Viewport width in screen pixels.
        /// @param | h | number | Viewport height in screen pixels.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );
        // -- getViewport --
        /// Returns the camera viewport rectangle.
        /// @return | number, number, number, number | Viewport X, Y, width, and height.
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().get_viewport())
        });
        // -- getBounds --
        /// Returns camera bounds with a leading availability flag.
        /// @return | boolean, number, number, number, number | Has-bounds flag followed by X, Y, width, and height.
        methods.add_method("getBounds", |_, this, ()| {
            let out = if let Some((x, y, w, h)) = this.inner.borrow().get_bounds() {
                (true, x, y, w, h)
            } else {
                (false, 0.0, 0.0, 0.0, 0.0)
            };
            Ok(out)
        });
        // -- hasBounds --
        /// Returns whether camera bounds are active.
        /// @return | boolean | True when bounds are active.
        methods.add_method("hasBounds", |_, this, ()| {
            Ok(this.inner.borrow().has_bounds())
        });
        // -- setBounds --
        /// Sets camera world bounds.
        /// @param | x | number | Bounds X coordinate.
        /// @param | y | number | Bounds Y coordinate.
        /// @param | w | number | Bounds width.
        /// @param | h | number | Bounds height.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setBounds",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_bounds(x, y, w, h);
                Ok(())
            },
        );
        // -- removeBounds --
        /// Removes active camera bounds.
        /// @return | nil | No value is returned.
        methods.add_method("removeBounds", |_, this, ()| {
            this.inner.borrow_mut().remove_bounds();
            Ok(())
        });
        // -- setTarget --
        /// Sets a world-space follow target.
        /// @param | x | number | Target X position.
        /// @param | y | number | Target Y position.
        /// @return | nil | No value is returned.
        methods.add_method("setTarget", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_target(x, y);
            Ok(())
        });
        // -- getTarget --
        /// Returns the follow target with a leading availability flag.
        /// @return | boolean, number, number | Has-target flag followed by target X and Y.
        methods.add_method("getTarget", |_, this, ()| {
            let out = if let Some((x, y)) = this.inner.borrow().get_target() {
                (true, x, y)
            } else {
                (false, 0.0, 0.0)
            };
            Ok(out)
        });
        // -- clearTarget --
        /// Clears the follow target.
        /// @return | nil | No value is returned.
        methods.add_method("clearTarget", |_, this, ()| {
            this.inner.borrow_mut().clear_target();
            Ok(())
        });
        // -- setFollowSmooth --
        /// Sets follow smoothing speed.
        /// @param | speed | number | Follow smoothing speed.
        /// @return | nil | No value is returned.
        methods.add_method("setFollowSmooth", |_, this, speed: f32| {
            this.inner.borrow_mut().set_follow_smooth(speed);
            Ok(())
        });
        // -- getFollowSmooth --
        /// Returns follow smoothing speed.
        /// @return | number | Current follow smoothing speed.
        methods.add_method("getFollowSmooth", |_, this, ()| {
            Ok(this.inner.borrow().get_follow_smooth())
        });
        // -- setFollowEasing --
        /// Sets target follow easing mode.
        /// @param | easing | string | Easing name such as `linear`, `smoothstep`, or `easeout`.
        /// @return | nil | No value is returned.
        methods.add_method("setFollowEasing", |_, this, easing: String| {
            this.inner
                .borrow_mut()
                .set_follow_easing(parse_follow_easing(&easing));
            Ok(())
        });
        // -- getFollowEasing --
        /// Returns target follow easing mode.
        /// @return | string | Easing name `linear`, `smoothstep`, or `easeout`.
        methods.add_method("getFollowEasing", |_, this, ()| {
            let mode = match this.inner.borrow().get_follow_easing() {
                CameraFollowEasing::Linear => "linear",
                CameraFollowEasing::SmoothStep => "smoothstep",
                CameraFollowEasing::EaseOutCubic => "easeout",
            };
            Ok(mode)
        });
        // -- setDeadZone --
        /// Sets follow dead-zone dimensions.
        /// @param | w | number | Dead-zone width in world units.
        /// @param | h | number | Dead-zone height in world units.
        /// @return | nil | No value is returned.
        methods.add_method("setDeadZone", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_dead_zone(w, h);
            Ok(())
        });
        // -- getDeadZone --
        /// Returns follow dead-zone dimensions with a leading availability flag.
        /// @return | boolean, number, number | Has-dead-zone flag followed by width and height.
        methods.add_method("getDeadZone", |_, this, ()| {
            let out = if let Some((w, h)) = this.inner.borrow().get_dead_zone() {
                (true, w, h)
            } else {
                (false, 0.0, 0.0)
            };
            Ok(out)
        });
        // -- setLookAhead --
        /// Sets follow look-ahead multiplier.
        /// @param | mul | number | Look-ahead multiplier applied to target motion.
        /// @return | nil | No value is returned.
        methods.add_method("setLookAhead", |_, this, mul: f32| {
            this.inner.borrow_mut().set_look_ahead(mul);
            Ok(())
        });
        // -- getLookAhead --
        /// Returns follow look-ahead multiplier.
        /// @return | number | Current look-ahead multiplier.
        methods.add_method("getLookAhead", |_, this, ()| {
            Ok(this.inner.borrow().get_look_ahead())
        });
        // -- onWindowResize --
        /// Updates camera viewport state after a window resize.
        /// @param | window_w | number | New window width in pixels.
        /// @param | window_h | number | New window height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method(
            "onWindowResize",
            |_, this, (window_w, window_h): (f32, f32)| {
                this.inner.borrow_mut().on_window_resize(window_w, window_h);
                Ok(())
            },
        );
        // -- onWindowResizeScaled --
        /// Updates camera viewport state using a virtual game size and scale mode.
        /// @param | game_w | number | Virtual game width in pixels.
        /// @param | game_h | number | Virtual game height in pixels.
        /// @param | window_w | number | New window width in pixels.
        /// @param | window_h | number | New window height in pixels.
        /// @param | mode | string | Scale mode `letterbox`, `stretch`, or `pixelperfect`.
        /// @return | nil | No value is returned.
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
        /// Starts a camera shake effect.
        /// @param | intensity | number | Shake intensity in world units.
        /// @param | duration | number | Shake duration in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("shake", |_, this, (intensity, duration): (f32, f32)| {
            this.inner.borrow_mut().shake(intensity, duration);
            Ok(())
        });
        // -- update --
        /// Advances camera follow, shake, and effect state.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- toWorld --
        /// Converts screen coordinates to world coordinates.
        /// @param | sx | number | Screen X coordinate.
        /// @param | sy | number | Screen Y coordinate.
        /// @return | number, number | World X and Y coordinates.
        methods.add_method("toWorld", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_world_coords(sx, sy))
        });
        // -- toScreen --
        /// Converts world coordinates to screen coordinates.
        /// @param | wx | number | World X coordinate.
        /// @param | wy | number | World Y coordinate.
        /// @return | number, number | Screen X and Y coordinates.
        methods.add_method("toScreen", |_, this, (wx, wy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen_coords(wx, wy))
        });
        // -- getVisibleArea --
        /// Returns the world-space area visible through this camera.
        /// @return | number, number, number, number | Visible X, Y, width, and height.
        methods.add_method("getVisibleArea", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_area())
        });
        // -- lookAt --
        /// Centers the camera on a world position.
        /// @param | x | number | World X position.
        /// @param | y | number | World Y position.
        /// @return | nil | No value is returned.
        methods.add_method("lookAt", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().look_at(x, y);
            Ok(())
        });
        // -- move --
        /// Moves the camera by a delta.
        /// @param | dx | number | X delta in world units.
        /// @param | dy | number | Y delta in world units.
        /// @return | nil | No value is returned.
        methods.add_method("move", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().move_by(dx, dy);
            Ok(())
        });
        // -- followPath --
        /// Starts camera movement along an array of waypoint tables.
        /// @param | points | table | Array of point tables using numeric indices `1` and `2` for X and Y.
        /// @param | duration | number | Total path duration in seconds.
        /// @return | nil | No value is returned.
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
        /// Stops the active camera path.
        /// @return | nil | No value is returned.
        methods.add_method("stopPath", |_, this, ()| {
            this.path.borrow_mut().take();
            Ok(())
        });
        // -- updatePath --
        /// Advances the active camera path and applies its position.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | boolean | True when a path position was applied.
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
        /// Returns active path progress.
        /// @return | number | Normalized path progress from 0 to 1, or 1 when no path is active.
        methods.add_method("pathProgress", |_, this, ()| {
            Ok(this
                .path
                .borrow()
                .as_ref()
                .map(|p| p.progress())
                .unwrap_or(1.0))
        });
        // -- zoomTo --
        /// Starts a zoom tween toward a target zoom factor.
        /// @param | target_zoom | number | Destination zoom factor.
        /// @param | duration | number | Tween duration in seconds.
        /// @param | easing | string? | Easing name such as `linear`, `smoothstep`, or `easeout`.
        /// @return | nil | No value is returned.
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
        /// Stops the active zoom tween.
        /// @return | nil | No value is returned.
        methods.add_method("stopZoom", |_, this, ()| {
            this.zoom_tween.borrow_mut().take();
            Ok(())
        });
        // -- updateZoom --
        /// Advances the active zoom tween and applies its zoom value.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | boolean | True when a zoom value was applied.
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
        /// Sets a parallax factor for a named layer.
        /// @param | layer | string | Layer name.
        /// @param | factor | number | Parallax factor, where 1.0 follows the camera fully.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setParallaxFactor",
            |_, this, (layer, factor): (String, f32)| {
                this.parallax.borrow_mut().insert(layer, factor);
                Ok(())
            },
        );
        // -- getParallaxFactor --
        /// Returns a parallax factor for a named layer.
        /// @param | layer | string | Layer name.
        /// @return | number | Stored parallax factor, or 1.0 when the layer has no override.
        methods.add_method("getParallaxFactor", |_, this, layer: String| {
            Ok(*this.parallax.borrow().get(&layer).unwrap_or(&1.0))
        });
        // -- clearParallaxFactors --
        /// Clears all layer parallax factor overrides.
        /// @return | nil | No value is returned.
        methods.add_method("clearParallaxFactors", |_, this, ()| {
            this.parallax.borrow_mut().clear();
            Ok(())
        });
        // -- apply --
        /// Appends render commands that apply this camera transform.
        /// @return | nil | No value is returned.
        methods.add_method("apply", |_, this, ()| {
            let mut state = this.state.borrow_mut();
            this.inner
                .borrow()
                .append_begin_render_commands(&mut state.render_commands);
            Ok(())
        });
        // -- reset --
        /// Appends a render command that removes the active camera transform.
        /// @return | nil | No value is returned.
        methods.add_method("reset", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });
        // -- attach --
        /// Appends render commands that attach this camera transform.
        /// @return | nil | No value is returned.
        methods.add_method("attach", |_, this, ()| {
            let mut state = this.state.borrow_mut();
            this.inner
                .borrow()
                .append_begin_render_commands(&mut state.render_commands);
            Ok(())
        });
        // -- detach --
        /// Appends a render command that detaches the active camera transform.
        /// @return | nil | No value is returned.
        methods.add_method("detach", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });
        // -- zoomPulse --
        /// Triggers a temporary zoom pulse effect.
        /// @param | amplitude | number | Zoom pulse amplitude.
        /// @param | duration | number | Pulse duration in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("zoomPulse", |_, this, (amplitude, duration): (f32, f32)| {
            this.inner
                .borrow_mut()
                .zoom_pulse
                .trigger(amplitude, duration);
            Ok(())
        });
        // -- startSway --
        /// Starts camera sway offset animation.
        /// @param | amplitude_x | number | Horizontal sway amplitude.
        /// @param | amplitude_y | number | Vertical sway amplitude.
        /// @param | frequency | number | Sway frequency.
        /// @param | decay | number? | Sway decay value; defaults to 1.0.
        /// @return | nil | No value is returned.
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
        /// Stops camera sway offset animation.
        /// @return | nil | No value is returned.
        methods.add_method("stopSway", |_, this, ()| {
            this.inner.borrow_mut().sway.stop();
            Ok(())
        });
        // -- isSway --
        /// Returns whether camera sway is active.
        /// @return | boolean | True when sway is active.
        methods.add_method("isSway", |_, this, ()| {
            Ok(this.inner.borrow().sway.is_active())
        });
        // -- startBreathing --
        /// Starts subtle breathing zoom animation.
        /// @param | amplitude | number? | Breathing zoom amplitude; defaults to 0.005.
        /// @param | rate | number? | Breathing rate; defaults to 0.2.
        /// @return | nil | No value is returned.
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
        /// Stops breathing zoom animation.
        /// @return | nil | No value is returned.
        methods.add_method("stopBreathing", |_, this, ()| {
            this.inner.borrow_mut().breathing.stop();
            Ok(())
        });
        // -- isBreathing --
        /// Returns whether breathing zoom animation is active.
        /// @return | boolean | True when breathing is active.
        methods.add_method("isBreathing", |_, this, ()| {
            Ok(this.inner.borrow().breathing.is_active())
        });
        // -- getEffectiveZoom --
        /// Returns zoom after camera effects are applied.
        /// @return | number | Effective zoom factor.
        methods.add_method("getEffectiveZoom", |_, this, ()| {
            Ok(this.inner.borrow().effective_zoom())
        });
        // -- getEffectOffset --
        /// Returns combined camera effect offset.
        /// @return | number, number | Effect X and Y offset.
        methods.add_method("getEffectOffset", |_, this, ()| {
            Ok(this.inner.borrow().effect_offset())
        });
        // -- getShakeOffset --
        /// Returns current camera shake offset.
        /// @return | number, number | Shake X and Y offset.
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.borrow().get_shake_offset())
        });
        // -- getRenderOffset --
        /// Returns current render offset after camera effects.
        /// @return | number, number | Render X and Y offset.
        methods.add_method("getRenderOffset", |_, this, ()| {
            Ok(this.inner.borrow().render_offset())
        });
        // -- setZoomConstraints --
        /// Sets optional minimum and maximum zoom constraints.
        /// @param | min_zoom | number? | Optional minimum zoom.
        /// @param | max_zoom | number? | Optional maximum zoom.
        /// @return | nil | No value is returned.
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
        /// Returns zoom constraints with availability flags.
        /// @return | boolean, number, boolean, number | Has-min flag and value followed by has-max flag and value.
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
        /// Sets zoom damping.
        /// @param | damping | number | Zoom damping value.
        /// @return | nil | No value is returned.
        methods.add_method("setZoomDamping", |_, this, damping: f32| {
            this.inner.borrow_mut().set_zoom_damping(damping);
            Ok(())
        });
        // -- getZoomDamping --
        /// Returns zoom damping.
        /// @return | number | Current zoom damping value.
        methods.add_method("getZoomDamping", |_, this, ()| {
            Ok(this.inner.borrow().get_zoom_damping())
        });
        // -- setRotationConstraints --
        /// Sets optional minimum and maximum rotation constraints.
        /// @param | min_rot | number? | Optional minimum rotation in radians.
        /// @param | max_rot | number? | Optional maximum rotation in radians.
        /// @return | nil | No value is returned.
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
        /// Returns rotation constraints with availability flags.
        /// @return | boolean, number, boolean, number | Has-min flag and value followed by has-max flag and value.
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
        /// Sets rotation damping.
        /// @param | damping | number | Rotation damping value.
        /// @return | nil | No value is returned.
        methods.add_method("setRotationDamping", |_, this, damping: f32| {
            this.inner.borrow_mut().set_rotation_damping(damping);
            Ok(())
        });
        // -- getRotationDamping --
        /// Returns rotation damping.
        /// @return | number | Current rotation damping value.
        methods.add_method("getRotationDamping", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation_damping())
        });
        // -- presetTightFollow --
        /// Applies the tight follow camera preset.
        /// @return | nil | No value is returned.
        methods.add_method("presetTightFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_tight_follow();
            Ok(())
        });
        // -- presetCinematicFollow --
        /// Applies the cinematic follow camera preset.
        /// @return | nil | No value is returned.
        methods.add_method("presetCinematicFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_cinematic_follow();
            Ok(())
        });
        // -- presetBalancedFollow --
        /// Applies the balanced follow camera preset.
        /// @return | nil | No value is returned.
        methods.add_method("presetBalancedFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_balanced_follow();
            Ok(())
        });
        // -- presetAggressiveFollow --
        /// Applies the aggressive follow camera preset.
        /// @return | nil | No value is returned.
        methods.add_method("presetAggressiveFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_aggressive_follow();
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this camera handle.
        /// @return | string | The string `LCamera`.
        methods.add_method("type", |_, _, ()| Ok("LCamera"));
        // -- typeOf --
        /// Returns whether this camera handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LCamera` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCamera" || name == "Object")
        });
    }
}
/// Lua-side camera rig that manages named cameras and viewport layouts.
pub struct LuaCameraRig {
    /// Shared camera rig state exposed through this userdata handle.
    inner: Rc<RefCell<CameraRig2D>>,
    /// Shared runtime state receiving render transform commands.
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaCameraRig {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- splitScreen --
        /// Applies a split-screen layout using the current window size.
        /// @param | window_w | number | Window width in pixels.
        /// @param | window_h | number | Window height in pixels.
        /// @return | nil | No value is returned.
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
        /// Applies a minimap layout using the current window size and optional ratio.
        /// @param | window_w | number | Window width in pixels.
        /// @param | window_h | number | Window height in pixels.
        /// @param | ratio | number? | Minimap size ratio; defaults to 0.25.
        /// @return | nil | No value is returned.
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
        /// Applies a picture-in-picture layout using optional inset size.
        /// @param | window_w | number | Window width in pixels.
        /// @param | window_h | number | Window height in pixels.
        /// @param | pip_w | number? | Picture-in-picture width; defaults to 320.
        /// @param | pip_h | number? | Picture-in-picture height; defaults to 180.
        /// @return | nil | No value is returned.
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
        /// Sets the position of a named rig camera, creating it if needed.
        /// @param | name | string | Camera name.
        /// @param | x | number | Camera X position.
        /// @param | y | number | Camera Y position.
        /// @return | nil | No value is returned.
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
        /// Sets the zoom of a named rig camera, creating it if needed.
        /// @param | name | string | Camera name.
        /// @param | zoom | number | Camera zoom factor.
        /// @return | nil | No value is returned.
        methods.add_method("setZoom", |_, this, (name, zoom): (String, f32)| {
            this.inner
                .borrow_mut()
                .ensure_camera(&name, 800.0, 600.0)
                .set_zoom(zoom);
            Ok(())
        });
        // -- setTarget --
        /// Sets the follow target of a named rig camera, creating it if needed.
        /// @param | name | string | Camera name.
        /// @param | x | number | Target X position.
        /// @param | y | number | Target Y position.
        /// @return | nil | No value is returned.
        methods.add_method("setTarget", |_, this, (name, x, y): (String, f32, f32)| {
            this.inner
                .borrow_mut()
                .ensure_camera(&name, 800.0, 600.0)
                .set_target(x, y);
            Ok(())
        });
        // -- updateAll --
        /// Advances every camera in this rig.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("updateAll", |_, this, dt: f32| {
            this.inner.borrow_mut().update_all(dt);
            Ok(())
        });
        // -- apply --
        /// Appends render commands for a named camera in this rig.
        /// @param | name | string | Camera name to apply.
        /// @return | boolean | True when the named camera exists.
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
        /// Returns a named rig camera viewport with a leading availability flag.
        /// @param | name | string | Camera name to query.
        /// @return | boolean, number, number, number, number | Has-camera flag followed by viewport X, Y, width, and height.
        methods.add_method("getViewport", |_, this, name: String| {
            let out = if let Some((x, y, w, h)) = this.inner.borrow().viewport_of(&name) {
                (true, x, y, w, h)
            } else {
                (false, 0.0, 0.0, 0.0, 0.0)
            };
            Ok(out)
        });
        // -- names --
        /// Returns all camera names in this rig.
        /// @return | table | Array table of camera names.
        methods.add_method("names", |lua, this, ()| {
            let names = this.inner.borrow().camera_names();
            let table = lua.create_table()?;
            for (idx, name) in names.iter().enumerate() {
                table.set(idx + 1, name.as_str())?;
            }
            Ok(table)
        });
        // -- remove --
        /// Removes a named camera from this rig.
        /// @param | name | string | Camera name to remove.
        /// @return | boolean | True when the camera existed and was removed.
        methods.add_method("remove", |_, this, name: String| {
            Ok(this.inner.borrow_mut().remove_camera(&name))
        });
        // -- has --
        /// Returns whether this rig contains a named camera.
        /// @param | name | string | Camera name to check.
        /// @return | boolean | True when the camera exists.
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has_camera(&name))
        });
        // -- type --
        /// Returns the Lua-visible type name for this camera rig handle.
        /// @return | string | The string `LCameraRig`.
        methods.add_method("type", |_, _, ()| Ok("LCameraRig"));
        // -- typeOf --
        /// Returns whether this camera rig handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LCameraRig` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCameraRig" || name == "Object")
        });
    }
}
/// Registers the `lurek.camera` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- new --
    /// Creates a 2D camera with optional virtual viewport size.
    /// @param | vw | number? | Virtual viewport width; defaults to 800.
    /// @param | vh | number? | Virtual viewport height; defaults to 600.
    /// @return | LCamera | New camera handle.
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
    // -- newCamera --
    /// Creates a 2D camera with optional virtual viewport size.
    /// @param | vw | number? | Virtual viewport width; defaults to 800.
    /// @param | vh | number? | Virtual viewport height; defaults to 600.
    /// @return | LCamera | New camera handle.
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
    /// Creates an empty named camera rig.
    /// @return | LCameraRig | New camera rig handle.
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
