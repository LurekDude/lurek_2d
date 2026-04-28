//! `lurek.camera` - Camera2D creation and manipulation for 2D viewport control.
//!
//! Each `Camera2D` has position, zoom, rotation, viewport bounds, optional world-space
//! clamping, waypoint path following, smooth zoom tweening, per-layer parallax factors,
//! and screen-world coordinate transforms.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::camera::{Camera2D, CameraPath, ZoomTween};
use crate::render::renderer::RenderCommand;
use std::collections::HashMap;

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
        methods.add_method("setViewport", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
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

        // -- setBounds --
        /// Sets world-space rectangular bounds that clamp the camera position.
        /// @param | x | number | Left edge of the bounding rectangle in world space
        /// @param | y | number | Top edge of the bounding rectangle in world space
        /// @param | w | number | Width of the bounding rectangle in world units
        /// @param | h | number | Height of the bounding rectangle in world units
        /// @return | nil | No return value.
        methods.add_method("setBounds", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
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

        // -- setDeadZone --
        /// Sets the dead zone half-extents for camera follow.
        /// @param | w | number | Half-width of the dead zone in world units
        /// @param | h | number | Half-height of the dead zone in world units
        /// @return | nil | No return value.
        methods.add_method("setDeadZone", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_dead_zone(w, h);
            Ok(())
        });

        // -- setLookAhead --
        /// Sets the look-ahead multiplier for predictive camera follow.
        /// @param | mul | number | Look-ahead multiplier (0.0 = disabled, 1.0 = full velocity offset)
        /// @return | nil | No return value.
        methods.add_method("setLookAhead", |_, this, mul: f32| {
            this.inner.borrow_mut().set_look_ahead(mul);
            Ok(())
        });

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
        /// @return | nil | No return value.
        methods.add_method("zoomTo", |_, this, (target_zoom, duration): (f32, f32)| {
            let current = this.inner.borrow().get_zoom();
            *this.zoom_tween.borrow_mut() = Some(ZoomTween::new(current, target_zoom, duration));
            Ok(())
        });

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
        methods.add_method("setParallaxFactor", |_, this, (layer, factor): (String, f32)| {
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
            let cmds = this.inner.borrow().begin_render_commands();
            this.state.borrow_mut().render_commands.extend(cmds);
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
        /// Alias for `apply()`.
        /// @return | nil | No return value.
        methods.add_method("attach", |_, this, ()| {
            let cmds = this.inner.borrow().begin_render_commands();
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });

        // -- detach --
        /// Alias for `reset()`.
        /// @return | nil | No return value.
        methods.add_method("detach", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });

        // -- Camera effects ?""""""""""""""""""""""""""""""""""""""""""""""?

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
        methods.add_method("startBreathing", |_, this, (amplitude, rate): (Option<f32>, Option<f32>)| {
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
    tbl.set("new", lua.create_function(move |lua, (vw, vh): (Option<f32>, Option<f32>)| {
            let vw = vw.unwrap_or(800.0);
            let vh = vh.unwrap_or(600.0);
            lua.create_userdata(LuaCamera2D {
                inner: Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                path: RefCell::new(None),
                zoom_tween: RefCell::new(None),
                parallax: RefCell::new(HashMap::new()),
                state: s.clone(),
            })
        })?,
    )?;

    // -- newCamera -- (alias for `new`, default 800x600 if called with no args)
    /// Creates a new 2D camera with the given viewport dimensions.
    /// @param | viewport_w | number? | Viewport width in pixels (default 800)
    /// @param | viewport_h | number? | Viewport height in pixels (default 600)
    /// @return | LCamera | New 2D camera with the given viewport dimensions.
    let s = state.clone();
    tbl.set("newCamera", lua.create_function(move |lua, (vw, vh): (Option<f32>, Option<f32>)| {
            let vw = vw.unwrap_or(800.0);
            let vh = vh.unwrap_or(600.0);
            lua.create_userdata(LuaCamera2D {
                inner: Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                path: RefCell::new(None),
                zoom_tween: RefCell::new(None),
                parallax: RefCell::new(HashMap::new()),
                state: s.clone(),
            })
        })?,
    )?;

    lurek.set("camera", tbl)?;
    Ok(())
}
