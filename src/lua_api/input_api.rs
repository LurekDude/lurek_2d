//! Input Api implementation for the `lua_api` subsystem.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for input api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use super::SharedState;
use crate::input::keyboard::{get_key_from_scancode, get_scancode_from_key};
use crate::input::mouse::SystemCursor;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Registers `luna.keyboard.*` and `luna.mouse.*` query functions into the Lua VM.
///
/// # Parameters
/// - `lua` — The active Lua VM instance.
/// - `luna` — The `luna` global table to attach functions to.
/// - `state` — Shared engine state accessed by the registered closures.
///
/// # Returns
/// `LuaResult<()>` — Ok if all functions were registered successfully; Lua error otherwise.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    // luna.keyboard
    let keyboard = lua.create_table()?;

    /// Returns whether the given key is currently held down.
    let s = state.clone();
    /// @param args : MultiValue
    /// @return boolean
    keyboard.set(
        "isDown",
        lua.create_function(move |_, args: LuaMultiValue| {
            let st = s.borrow();
            for arg in args.iter() {
                if let LuaValue::String(key) = arg {
                    if st.keys_down.contains(key.to_str().unwrap_or("")) {
                        return Ok(true);
                    }
                }
            }
            Ok(false)
        })?,
    )?;

    /// Returns whether the key with the given scancode is held.
    let s = state.clone();
    /// @param scancode : string
    /// @return any
    keyboard.set(
        "isScancodeDown",
        lua.create_function(move |_, scancode: String| {
            Ok(s.borrow().keyboard.is_scancode_down(&scancode))
        })?,
    )?;

    /// Enables or disables key-repeat events.
    let s = state.clone();
    /// @param enabled : boolean
    keyboard.set(
        "setKeyRepeat",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_key_repeat(enabled);
            Ok(())
        })?,
    )?;

    /// Returns whether key-repeat is currently enabled.
    let s = state.clone();
    keyboard.set(
        "hasKeyRepeat",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_key_repeat()))?,
    )?;

    /// Enables or disables Unicode text input mode.
    let s = state.clone();
    /// @param enabled : boolean
    keyboard.set(
        "setTextInput",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_text_input(enabled);
            Ok(())
        })?,
    )?;

    /// Returns whether text input mode is currently active.
    let s = state.clone();
    /// @return any
    keyboard.set(
        "hasTextInput",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_text_input()))?,
    )?;

    /// Returns the hardware scancode for the given key name.
    /// @param key : string
    /// @return any
    keyboard.set(
        "getScancodeFromKey",
        lua.create_function(move |_, key: String| Ok(get_scancode_from_key(&key)))?,
    )?;

    /// Returns the key name for the given hardware scancode.
    /// @param scancode : string
    /// @return any
    keyboard.set(
        "getKeyFromScancode",
        lua.create_function(move |_, scancode: String| Ok(get_key_from_scancode(&scancode)))?,
    )?;

    /// Keyboard.
    luna.set("keyboard", keyboard)?;

    // luna.mouse
    let mouse = lua.create_table()?;
    /// Returns the current position (x, y).
    let s = state.clone();
    /// @return any
    mouse.set(
        "getPosition",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.mouse.x, st.mouse.y))
        })?,
    )?;

    /// Returns the current mouse X position in window coordinates.
    let s = state.clone();
    /// @return any
    mouse.set(
        "getX",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.x))?,
    )?;

    /// Returns the current mouse Y position in window coordinates.
    let s = state.clone();
    /// @return any
    mouse.set(
        "getY",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.y))?,
    )?;

    /// Returns whether the given key is currently held down.
    let s = state.clone();
    /// @param button : integer
    /// @return any
    mouse.set(
        "isDown",
        lua.create_function(move |_, button: usize| {
            let btn = if button > 0 { button - 1 } else { 0 };
            Ok(s.borrow().mouse.is_down(btn))
        })?,
    )?;

    /// Shows or hides the operating-system mouse cursor over the game window.
    ///
    /// # Parameters
    /// - `visible` — true to show the cursor, false to hide it.
    let s = state.clone();
    /// @param visible : boolean
    mouse.set(
        "setVisible",
        lua.create_function(move |_, visible: bool| {
            s.borrow_mut().mouse.set_visible(visible);
            Ok(())
        })?,
    )?;

    /// Returns whether the mouse cursor is currently visible.
    let s = state.clone();
    mouse.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_visible()))?,
    )?;

    /// Locks or unlocks the mouse cursor to the window.
    let s = state.clone();
    /// @param grabbed : boolean
    mouse.set(
        "setGrabbed",
        lua.create_function(move |_, grabbed: bool| {
            s.borrow_mut().mouse.set_grabbed(grabbed);
            Ok(())
        })?,
    )?;

    /// Returns whether the mouse cursor is locked to the window.
    let s = state.clone();
    mouse.set(
        "isGrabbed",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_grabbed()))?,
    )?;

    /// Enables or disables raw relative mouse motion mode.
    let s = state.clone();
    /// @param relative : boolean
    mouse.set(
        "setRelativeMode",
        lua.create_function(move |_, relative: bool| {
            s.borrow_mut().mouse.set_relative_mode(relative);
            Ok(())
        })?,
    )?;

    /// Returns whether relative mouse mode is active.
    let s = state.clone();
    mouse.set(
        "getRelativeMode",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_relative_mode()))?,
    )?;

    /// Moves the mouse cursor to the given window-space position.
    let s = state.clone();
    /// @param x : number
    /// @param y : number
    mouse.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mouse.request_position(x, y);
            Ok(())
        })?,
    )?;

    /// Sets the currently visible mouse cursor to the given hardware cursor handle.
    ///
    /// # Parameters
    /// - `cursor` — Cursor ID returned by newCursor or getSystemCursor, or nil to reset.
    let s = state.clone();
    /// @param name : string
    mouse.set(
        "setCursor",
        lua.create_function(move |_, name: String| {
            s.borrow_mut()
                .mouse
                .set_cursor(SystemCursor::from_name(&name));
            Ok(())
        })?,
    )?;

    /// Returns the currently active cursor ID.
    let s = state.clone();
    /// @return any
    mouse.set(
        "getCursor",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_cursor().as_str().to_string()))?,
    )?;

    /// Returns the mouse scroll wheel delta (dx, dy) since last frame.
    let s = state.clone();
    /// @return any
    mouse.set(
        "getWheelDelta",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let (sx, sy) = st.mouse.get_scroll();
            Ok((sx, sy))
        })?,
    )?;

    /// Mouse.
    luna.set("mouse", mouse)?;

    // luna.gamepad
    let gamepad = lua.create_table()?;

    /// Returns the number of connected gamepads.
    let s = state.clone();
    /// @return table
    gamepad.set(
        "getCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;

    /// Returns the number of tracked gamepad slots.
    let s = state.clone();
    /// @return table
    gamepad.set(
        "getJoystickCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;

    /// Returns a list of connected gamepad IDs.
    let s = state.clone();
    /// @return table
    gamepad.set(
        "getJoysticks",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for gp in &st.gamepads {
                if gp.connected {
                    tbl.push(gp.id as i64)?;
                }
            }
            Ok(tbl)
        })?,
    )?;

    /// Returns whether the gamepad with the given ID is connected.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    gamepad.set(
        "isConnected",
        lua.create_function(move |_, id: usize| {
            let st = s.borrow();
            Ok(st.gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;

    /// Returns the human-readable name of a gamepad.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    gamepad.set(
        "getName",
        lua.create_function(move |_, id: usize| {
            let st = s.borrow();
            Ok(st
                .gamepads
                .get(id)
                .map_or_else(|| "Unknown".to_string(), |gp| gp.name.clone()))
        })?,
    )?;

    /// Returns whether the joystick at the given slot is a recognized gamepad.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    gamepad.set(
        "isGamepad",
        lua.create_function(move |_, id: usize| {
            let st = s.borrow();
            Ok(st.gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;

    /// Returns the total number of buttons on the gamepad.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    gamepad.set(
        "getButtonCount",
        lua.create_function(move |_, id: usize| {
            let st = s.borrow();
            Ok(st.gamepads.get(id).map_or(0, |gp| gp.get_button_count()))
        })?,
    )?;

    /// Returns the total number of analog axes on the gamepad.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    gamepad.set(
        "getAxisCount",
        lua.create_function(move |_, id: usize| {
            let st = s.borrow();
            Ok(st.gamepads.get(id).map_or(0, |gp| gp.get_axis_count()))
        })?,
    )?;

    /// Returns whether the given key is currently held down.
    let s = state.clone();
    /// @param id : integer
    /// @param button : integer
    /// @return any
    gamepad.set(
        "isDown",
        lua.create_function(move |_, (id, button): (usize, u32)| {
            let st = s.borrow();
            Ok(st
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.is_button_pressed(button)))
        })?,
    )?;

    /// Returns the current value (-1 to 1) of a gamepad analog axis.
    let s = state.clone();
    /// @param id : integer
    /// @param axis : integer
    /// @return any
    gamepad.set(
        "getAxis",
        lua.create_function(move |_, (id, axis): (usize, u32)| {
            let st = s.borrow();
            Ok(st
                .gamepads
                .get(id)
                .map_or(0.0, |gp| gp.get_axis_value(axis)))
        })?,
    )?;

    /// Returns whether the gamepad supports haptic vibration.
    /// @param id : integer
    /// @return boolean
    gamepad.set(
        "isVibrationSupported",
        lua.create_function(move |_, _id: usize| Ok(false))?,
    )?;

    /// Returns the hardware GUID string of the gamepad.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    gamepad.set(
        "getGUID",
        lua.create_function(move |_, id: usize| {
            let st = s.borrow();
            Ok(st
                .gamepads
                .get(id)
                .map_or_else(String::new, |gp| gp.get_guid().to_string()))
        })?,
    )?;

    /// Returns the direction (string) of a hat switch on the gamepad.
    let s = state.clone();
    /// @param id : integer
    /// @param hat : integer
    /// @return any
    gamepad.set(
        "getHat",
        lua.create_function(move |_, (id, hat): (usize, u32)| {
            let st = s.borrow();
            Ok(st
                .gamepads
                .get(id)
                .map_or_else(|| "c".to_string(), |gp| gp.get_hat(hat).to_string()))
        })?,
    )?;

    /// Triggers haptic rumble with the given left/right motor strengths.
    /// @param args : MultiValue
    /// @return boolean
    gamepad.set(
        "setVibration",
        lua.create_function(move |_, _args: LuaMultiValue| Ok(false))?,
    )?;

    /// Enable or disable receiving gamepad events when the window is not focused.
    let s = state.clone();
    /// @param enable : boolean
    gamepad.set(
        "setBackgroundEvents",
        lua.create_function(move |_, enable: bool| {
            s.borrow_mut().gamepad_background_events = enable;
            Ok(())
        })?,
    )?;

    /// Returns whether background gamepad events are enabled.
    let s = state.clone();
    /// @return table
    gamepad.set(
        "getBackgroundEvents",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepad_background_events))?,
    )?;

    /// Gamepad.
    luna.set("gamepad", gamepad)?;

    // luna.touch
    let touch = lua.create_table()?;

    /// Returns a table of active touch points (id, x, y, pressure).
    let s = state.clone();
    /// @return table
    touch.set(
        "getTouches",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let touches = st.touch.get_touches();
            let tbl = lua.create_table()?;
            for (i, tp) in touches.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Id.
                entry.set("id", tp.id)?;
                /// X.
                entry.set("x", tp.x)?;
                /// Y.
                entry.set("y", tp.y)?;
                /// Pressure.
                entry.set("pressure", tp.pressure)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Returns the current position (x, y).
    let s = state.clone();
    /// @param id : integer
    /// @return any
    touch.set(
        "getPosition",
        lua.create_function(move |_, id: u64| {
            let st = s.borrow();
            if let Some(tp) = st.touch.get_touch(id) {
                Ok((tp.x, tp.y))
            } else {
                Ok((0.0, 0.0))
            }
        })?,
    )?;

    /// Returns the pressure (0-1) of the touch with the given ID.
    let s = state.clone();
    /// @param id : integer
    /// @return any
    touch.set(
        "getPressure",
        lua.create_function(move |_, id: u64| {
            let st = s.borrow();
            Ok(st.touch.get_touch(id).map_or(0.0, |tp| tp.pressure))
        })?,
    )?;

    /// Returns the number of currently active touch points.
    let s = state.clone();
    touch.set(
        "getTouchCount",
        lua.create_function(move |_, ()| Ok(s.borrow().touch.get_touch_count()))?,
    )?;

    /// Touch.
    luna.set("touch", touch)?;

    Ok(())
}
