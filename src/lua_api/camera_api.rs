//! `lurek.camera` — Camera2D creation and manipulation for 2D viewport control.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::camera::Camera2D;

// -------------------------------------------------------------------------------
// LuaCamera2D UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Camera2D`] instance.
pub struct LuaCamera2D {
    inner: Rc<RefCell<Camera2D>>,
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
            })
        })?,
    )?;

    luna.set("camera", tbl)?;
    Ok(())
}
