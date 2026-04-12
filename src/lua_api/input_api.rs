//! `lurek.keyboard` / `lurek.mouse` / `lurek.gamepad` / `lurek.touch` — Input state queries and cursor management.

use super::SharedState;
use mlua::prelude::*;
use mlua::Variadic;
use std::cell::RefCell;
use std::rc::Rc;

use crate::input::keyboard::{get_key_from_scancode, get_scancode_from_key};
use crate::input::mouse::{is_cursor_supported, CursorKind, SystemCursor};

// -------------------------------------------------------------------------------
// LuaCursor UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a mouse cursor handle.
pub struct LuaCursor {
    kind: CursorKind,
}

impl LuaUserData for LuaCursor {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- release --
        /// Releases the cursor resource (no-op on desktop).
        /// @return nil
        methods.add_method("release", |_, _this, ()| Ok(()));

        // -- getType --
        /// Returns the cursor type as "system" or "custom".
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            Ok(match &this.kind {
                CursorKind::System(_) => "system",
                CursorKind::Custom { .. } => "custom",
            })
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, and `lurek.touch` API tables.
///
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {

    // ── lurek.keyboard ─────────────────────────────────────────────────────────

    let keyboard = lua.create_table()?;

    // -- isDown --
    /// Returns true if any of the given keys is currently held down.
    /// @param keys : string...
    /// @return boolean
    let s = state.clone();
    keyboard.set(
        "isDown",
        lua.create_function(move |_, args: Variadic<String>| {
            Ok(s.borrow().keyboard.is_any_down(&args))
        })?,
    )?;

    // -- isScancodeDown --
    /// Returns whether the key with the given scancode is held.
    /// @param scancode : string
    /// @return boolean
    let s = state.clone();
    keyboard.set(
        "isScancodeDown",
        lua.create_function(move |_, scancode: String| {
            Ok(s.borrow().keyboard.is_scancode_down(&scancode))
        })?,
    )?;

    // -- setKeyRepeat --
    /// Enables or disables key-repeat events.
    /// @param enabled : boolean
    /// @return nil
    let s = state.clone();
    keyboard.set(
        "setKeyRepeat",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_key_repeat(enabled);
            Ok(())
        })?,
    )?;

    // -- hasKeyRepeat --
    /// Returns whether key-repeat is currently enabled.
    /// @return boolean
    let s = state.clone();
    keyboard.set(
        "hasKeyRepeat",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_key_repeat()))?,
    )?;

    // -- setTextInput --
    /// Enables or disables Unicode text input mode.
    /// @param enabled : boolean
    /// @return nil
    let s = state.clone();
    keyboard.set(
        "setTextInput",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_text_input(enabled);
            Ok(())
        })?,
    )?;

    // -- hasTextInput --
    /// Returns whether text input mode is currently active.
    /// @return boolean
    let s = state.clone();
    keyboard.set(
        "hasTextInput",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_text_input()))?,
    )?;

    // -- getScancodeFromKey --
    /// Returns the hardware scancode for the given key name.
    /// @param key : string
    /// @return string?
    keyboard.set(
        "getScancodeFromKey",
        lua.create_function(move |_, key: String| Ok(get_scancode_from_key(&key)))?,
    )?;

    // -- getKeyFromScancode --
    /// Returns the key name for the given hardware scancode.
    /// @param scancode : string
    /// @return string?
    keyboard.set(
        "getKeyFromScancode",
        lua.create_function(move |_, scancode: String| Ok(get_key_from_scancode(&scancode)))?,
    )?;

    // -- isModifierActive --
    /// Returns whether the named modifier key is currently held.
    /// @param modifier : string
    /// @return boolean
    let s = state.clone();
    keyboard.set(
        "isModifierActive",
        lua.create_function(move |_, modifier: String| {
            Ok(s.borrow().keyboard.is_modifier_active(&modifier))
        })?,
    )?;

    luna.set("keyboard", keyboard)?;

    // ── lurek.mouse ────────────────────────────────────────────────────────────

    let mouse = lua.create_table()?;

    // -- getPosition --
    /// Returns the current cursor position as (x, y).
    /// @return number, number
    let s = state.clone();
    mouse.set(
        "getPosition",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.mouse.x, st.mouse.y))
        })?,
    )?;

    // -- getX --
    /// Returns the current mouse X position in window coordinates.
    /// @return number
    let s = state.clone();
    mouse.set(
        "getX",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.x))?,
    )?;

    // -- getY --
    /// Returns the current mouse Y position in window coordinates.
    /// @return number
    let s = state.clone();
    mouse.set(
        "getY",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.y))?,
    )?;

    // -- isDown --
    /// Returns whether the given mouse button is currently held down.
    /// @param button : integer
    /// @return boolean
    let s = state.clone();
    mouse.set(
        "isDown",
        lua.create_function(move |_, button: usize| {
            Ok(s.borrow().mouse.is_down(button.saturating_sub(1)))
        })?,
    )?;

    // -- setVisible --
    /// Shows or hides the operating-system mouse cursor.
    /// @param visible : boolean
    /// @return nil
    let s = state.clone();
    mouse.set(
        "setVisible",
        lua.create_function(move |_, visible: bool| {
            s.borrow_mut().mouse.set_visible(visible);
            Ok(())
        })?,
    )?;

    // -- isVisible --
    /// Returns whether the mouse cursor is currently visible.
    /// @return boolean
    let s = state.clone();
    mouse.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_visible()))?,
    )?;

    // -- setGrabbed --
    /// Locks or unlocks the mouse cursor to the window.
    /// @param grabbed : boolean
    /// @return nil
    let s = state.clone();
    mouse.set(
        "setGrabbed",
        lua.create_function(move |_, grabbed: bool| {
            s.borrow_mut().mouse.set_grabbed(grabbed);
            Ok(())
        })?,
    )?;

    // -- isGrabbed --
    /// Returns whether the mouse cursor is locked to the window.
    /// @return boolean
    let s = state.clone();
    mouse.set(
        "isGrabbed",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_grabbed()))?,
    )?;

    // -- setRelativeMode --
    /// Enables or disables raw relative mouse motion mode.
    /// @param relative : boolean
    /// @return nil
    let s = state.clone();
    mouse.set(
        "setRelativeMode",
        lua.create_function(move |_, relative: bool| {
            s.borrow_mut().mouse.set_relative_mode(relative);
            Ok(())
        })?,
    )?;

    // -- getRelativeMode --
    /// Returns whether relative mouse mode is active.
    /// @return boolean
    let s = state.clone();
    mouse.set(
        "getRelativeMode",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_relative_mode()))?,
    )?;

    // -- setPosition --
    /// Moves the mouse cursor to the given window-space position.
    /// @param x : number
    /// @param y : number
    /// @return nil
    let s = state.clone();
    mouse.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mouse.request_position(x, y);
            Ok(())
        })?,
    )?;

    // -- setCursor --
    /// Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
    /// @param cursor : Cursor?
    /// @return nil
    let s = state.clone();
    mouse.set(
        "setCursor",
        lua.create_function(move |_, cursor_val: LuaValue| {
            let mut st = s.borrow_mut();
            match cursor_val {
                LuaValue::UserData(ud) => {
                    if let Ok(cursor) = ud.borrow::<LuaCursor>() {
                        match &cursor.kind {
                            CursorKind::System(sc) => st.mouse.set_cursor(*sc),
                            CursorKind::Custom { .. } => {
                                st.mouse.set_cursor(SystemCursor::Arrow);
                            }
                        }
                    }
                }
                LuaValue::String(name_str) => {
                    st.mouse.set_cursor(SystemCursor::from_name(
                        name_str.to_str().unwrap_or("arrow"),
                    ));
                }
                LuaValue::Nil => {
                    st.mouse.set_cursor(SystemCursor::Arrow);
                }
                _ => {}
            }
            Ok(())
        })?,
    )?;

    // -- newCursor --
    /// Creates a custom mouse cursor from RGBA pixel data.
    /// @param pixels : table
    /// @param width : integer
    /// @param height : integer
    /// @param hotx : integer?
    /// @param hoty : integer?
    /// @return Cursor
    mouse.set(
        "newCursor",
        lua.create_function(
            move |_,
                  (pixels, width, height, hotx, hoty): (
                Vec<u8>,
                u32,
                u32,
                Option<u32>,
                Option<u32>,
            )| {
                Ok(LuaCursor {
                    kind: CursorKind::Custom {
                        pixels,
                        width,
                        height,
                        hotx: hotx.unwrap_or(0),
                        hoty: hoty.unwrap_or(0),
                    },
                })
            },
        )?,
    )?;

    // -- getSystemCursor --
    /// Returns a system cursor object for the named cursor shape.
    /// @param name : string
    /// @return Cursor
    mouse.set(
        "getSystemCursor",
        lua.create_function(move |_, name: String| {
            Ok(LuaCursor {
                kind: CursorKind::System(SystemCursor::from_name(&name)),
            })
        })?,
    )?;

    // -- isCursorSupported --
    /// Returns whether cursor customisation is supported on this platform.
    /// @return boolean
    mouse.set(
        "isCursorSupported",
        lua.create_function(move |_, ()| Ok(is_cursor_supported()))?,
    )?;

    // -- getCursor --
    /// Returns the name of the currently active system cursor.
    /// @return string
    let s = state.clone();
    mouse.set(
        "getCursor",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().mouse.get_cursor().as_str().to_string())
        })?,
    )?;

    // -- getWheelDelta --
    /// Returns the mouse scroll wheel delta (dx, dy) since last frame.
    /// @return number, number
    let s = state.clone();
    mouse.set(
        "getWheelDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_scroll()))?,
    )?;

    luna.set("mouse", mouse)?;

    // ── lurek.gamepad ──────────────────────────────────────────────────────────

    let gamepad = lua.create_table()?;

    // -- getCount --
    /// Returns the number of connected gamepads.
    /// @return integer
    let s = state.clone();
    gamepad.set(
        "getCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;

    // -- getJoystickCount --
    /// Returns the number of tracked gamepad slots.
    /// @return integer
    let s = state.clone();
    gamepad.set(
        "getJoystickCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;

    // -- getJoysticks --
    /// Returns a list of connected gamepad IDs.
    /// @return table
    let s = state.clone();
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

    // -- isConnected --
    /// Returns whether the gamepad with the given ID is connected.
    /// @param id : integer
    /// @return boolean
    let s = state.clone();
    gamepad.set(
        "isConnected",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;

    // -- getName --
    /// Returns the human-readable name of a gamepad.
    /// @param id : integer
    /// @return string
    let s = state.clone();
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

    // -- isGamepad --
    /// Returns whether the joystick at the given slot is a recognized gamepad.
    /// @param id : integer
    /// @return boolean
    let s = state.clone();
    gamepad.set(
        "isGamepad",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;

    // -- getButtonCount --
    /// Returns the total number of buttons on the gamepad.
    /// @param id : integer
    /// @return integer
    let s = state.clone();
    gamepad.set(
        "getButtonCount",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).map_or(0, |gp| gp.get_button_count()))
        })?,
    )?;

    // -- getAxisCount --
    /// Returns the total number of analog axes on the gamepad.
    /// @param id : integer
    /// @return integer
    let s = state.clone();
    gamepad.set(
        "getAxisCount",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).map_or(0, |gp| gp.get_axis_count()))
        })?,
    )?;

    // -- isDown --
    /// Returns whether the given button on the gamepad is currently held.
    /// @param id : integer
    /// @param button : integer
    /// @return boolean
    let s = state.clone();
    gamepad.set(
        "isDown",
        lua.create_function(move |_, (id, button): (usize, u32)| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.is_button_pressed(button)))
        })?,
    )?;

    // -- getAxis --
    /// Returns the current value (-1 to 1) of a gamepad analog axis.
    /// @param id : integer
    /// @param axis : integer
    /// @return number
    let s = state.clone();
    gamepad.set(
        "getAxis",
        lua.create_function(move |_, (id, axis): (usize, u32)| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .map_or(0.0, |gp| gp.get_axis_value(axis)))
        })?,
    )?;

    // -- isVibrationSupported --
    /// Returns whether the gamepad supports haptic vibration.
    /// @param id : integer
    /// @return boolean
    gamepad.set(
        "isVibrationSupported",
        lua.create_function(move |_, _id: usize| Ok(false))?,
    )?;

    // -- getGUID --
    /// Returns the hardware GUID string of the gamepad.
    /// @param id : integer
    /// @return string
    let s = state.clone();
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

    // -- getHat --
    /// Returns the direction string of a hat switch on the gamepad.
    /// @param id : integer
    /// @param hat : integer
    /// @return string
    let s = state.clone();
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

    // -- setVibration --
    /// Triggers haptic rumble (currently a no-op stub).
    /// @param args : any...
    /// @return boolean
    gamepad.set(
        "setVibration",
        lua.create_function(move |_, _args: LuaMultiValue| Ok(false))?,
    )?;

    // -- setBackgroundEvents --
    /// Enable or disable receiving gamepad events when the window is not focused.
    /// @param enable : boolean
    /// @return nil
    let s = state.clone();
    gamepad.set(
        "setBackgroundEvents",
        lua.create_function(move |_, enable: bool| {
            s.borrow_mut().gamepad_background_events = enable;
            Ok(())
        })?,
    )?;

    // -- getBackgroundEvents --
    /// Returns whether background gamepad events are enabled.
    /// @return boolean
    let s = state.clone();
    gamepad.set(
        "getBackgroundEvents",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepad_background_events))?,
    )?;

    // -- setGamepadMapping --
    /// Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
    /// @param guid : string
    /// @param mapping : string
    /// @return nil
    let s = state.clone();
    gamepad.set(
        "setGamepadMapping",
        lua.create_function(move |_, (guid, mapping): (String, String)| {
            s.borrow_mut().gamepad_mappings.set_mapping(&guid, &mapping);
            Ok(())
        })?,
    )?;

    // -- getGamepadMappingString --
    /// Returns the stored mapping string for the given GUID, or nil.
    /// @param guid : string
    /// @return string?
    let s = state.clone();
    gamepad.set(
        "getGamepadMappingString",
        lua.create_function(move |_, guid: String| {
            Ok(s.borrow()
                .gamepad_mappings
                .get_mapping_string(&guid)
                .map(|m| m.to_string()))
        })?,
    )?;

    // -- loadGamepadMappings --
    /// Loads SDL2 GameControllerDB-format mappings from a file.
    /// @param path : string
    /// @return integer
    let s = state.clone();
    gamepad.set(
        "loadGamepadMappings",
        lua.create_function(move |_, path: String| {
            s.borrow_mut()
                .gamepad_mappings
                .load_from_file(&path)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- saveGamepadMappings --
    /// Saves all stored gamepad mappings to a plain-text file.
    /// @param path : string
    /// @return nil
    let s = state.clone();
    gamepad.set(
        "saveGamepadMappings",
        lua.create_function(move |_, path: String| {
            s.borrow()
                .gamepad_mappings
                .save_to_file(&path)
                .map_err(LuaError::external)?;
            Ok(())
        })?,
    )?;

    luna.set("gamepad", gamepad)?;

    // ── lurek.touch ────────────────────────────────────────────────────────────

    let touch = lua.create_table()?;

    // -- getTouches --
    /// Returns a table of active touch points with id, x, y, and pressure fields.
    /// @return table
    let s = state.clone();
    touch.set(
        "getTouches",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let touches = st.touch.get_touches();
            let tbl = lua.create_table()?;
            for (i, tp) in touches.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("id", tp.id)?;
                entry.set("x", tp.x)?;
                entry.set("y", tp.y)?;
                entry.set("pressure", tp.pressure)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- getPosition --
    /// Returns the position (x, y) of the touch with the given ID.
    /// @param id : integer
    /// @return number, number
    let s = state.clone();
    touch.set(
        "getPosition",
        lua.create_function(move |_, id: u64| {
            let st = s.borrow();
            let (x, y) = st
                .touch
                .get_touch(id)
                .map_or((0.0, 0.0), |tp| (tp.x, tp.y));
            Ok((x, y))
        })?,
    )?;

    // -- getPressure --
    /// Returns the pressure (0-1) of the touch with the given ID.
    /// @param id : integer
    /// @return number
    let s = state.clone();
    touch.set(
        "getPressure",
        lua.create_function(move |_, id: u64| {
            Ok(s.borrow().touch.get_touch(id).map_or(0.0, |tp| tp.pressure))
        })?,
    )?;

    // -- getTouchCount --
    /// Returns the number of currently active touch points.
    /// @return integer
    let s = state.clone();
    touch.set(
        "getTouchCount",
        lua.create_function(move |_, ()| Ok(s.borrow().touch.get_touch_count()))?,
    )?;

    luna.set("touch", touch)?;

    Ok(())
}
