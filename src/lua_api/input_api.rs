//! `lurek.input` -- Input bindings for keyboard, mouse, cursor objects, gamepads, touch points, action mappings, combo detection, virtual d-pad conversion, input recording, and playback state exposed through nested Lua tables.

use super::SharedState;
use crate::input::combo::{ComboDetector, ComboStep};
use crate::input::keyboard::{get_key_from_scancode, get_scancode_from_key};
use crate::input::mouse::{is_cursor_supported, CursorKind, SystemCursor};
use crate::input::virtual_dpad;
use mlua::prelude::*;
use mlua::Variadic;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
/// Parses a gamepad binding string in `gamepad:id:button` form.
fn parse_gamepad_binding(binding: &str) -> Option<(usize, u32)> {
    let mut parts = binding.split(':');
    let prefix = parts.next()?;
    if prefix != "gamepad" {
        return None;
    }
    let id = parts.next()?.parse::<usize>().ok()?;
    let button = parts.next()?.parse::<u32>().ok()?;
    Some((id, button))
}
/// Returns whether a keyboard or gamepad binding is currently down.
fn binding_is_down(st: &SharedState, binding: &str) -> bool {
    if let Some((id, button)) = parse_gamepad_binding(binding) {
        return st
            .gamepads
            .get(id)
            .is_some_and(|gp| gp.is_button_pressed(button));
    }
    st.keyboard.is_down(binding)
}
/// Returns whether a keyboard or gamepad binding was pressed this frame.
fn binding_was_pressed(st: &SharedState, binding: &str) -> bool {
    if let Some((id, button)) = parse_gamepad_binding(binding) {
        return st
            .gamepads
            .get(id)
            .is_some_and(|gp| gp.was_button_pressed(button));
    }
    st.keyboard.get_pressed().iter().any(|k| k == binding)
}
/// Returns whether a keyboard or gamepad binding was released this frame.
fn binding_was_released(st: &SharedState, binding: &str) -> bool {
    if let Some((id, button)) = parse_gamepad_binding(binding) {
        return st
            .gamepads
            .get(id)
            .is_some_and(|gp| gp.was_button_released(button));
    }
    st.keyboard.get_released().iter().any(|k| k == binding)
}
/// Lua-side cursor handle for system and custom cursor requests.
pub struct LuaCursor {
    /// Cursor kind and custom image metadata.
    kind: CursorKind,
}
/// Provides Lua methods for cursor handles.
impl LuaUserData for LuaCursor {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- release --
        /// Releases cursor resources; currently a no-op for managed cursor handles.
        methods.add_method("release", |_, _this, ()| Ok(()));
        // -- getType --
        /// Returns whether this cursor is a system cursor or custom cursor.
        /// @return | string | `system` or `custom`.
        methods.add_method("getType", |_, this, ()| {
            Ok(match &this.kind {
                CursorKind::System(_) => "system",
                CursorKind::Custom { .. } => "custom",
            })
        });
        // -- type --
        /// Returns the Lua-visible type name for this cursor handle.
        /// @return | string | The string `LCursor`.
        methods.add_method("type", |_, _, ()| Ok("LCursor"));
        // -- typeOf --
        /// Returns whether this cursor handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LCursor` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCursor" || name == "Object")
        });
    }
}
/// Lua-side combo detector handle tracking ordered key sequences.
struct LuaCombo {
    /// Combo detector with steps and gap timing.
    detector: ComboDetector,
    /// Total elapsed time since the last feed or reset.
    total_elapsed_ms: u64,
}
/// Provides Lua methods for feeding and inspecting combo progress.
impl LuaUserData for LuaCombo {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- feed --
        /// Feeds one key into the combo detector and returns progress status.
        /// @param | key | string | Key name to feed into the combo sequence.
        /// @return | string | `completed`, `advanced`, `broken`, or `idle`.
        methods.add_method_mut("feed", |_, this, key: String| {
            let progress = this.detector.feed(&key, 0);
            this.total_elapsed_ms = 0;
            let result = match progress {
                crate::input::combo::ComboProgress::Completed => "completed",
                crate::input::combo::ComboProgress::Advanced { .. } => "advanced",
                crate::input::combo::ComboProgress::Broken => "broken",
                crate::input::combo::ComboProgress::Idle => "idle",
            };
            Ok(result)
        });
        // -- tick --
        /// Advances combo timeout state and returns progress status.
        /// @param | dt | number | Delta time in seconds.
        /// @return | string | `expired`, `in_progress`, or `idle`.
        methods.add_method_mut("tick", |_, this, dt: f64| {
            let elapsed_ms = (dt * 1000.0).round() as u64;
            this.total_elapsed_ms += elapsed_ms;
            let progress = this.detector.tick(elapsed_ms);
            let result = match progress {
                crate::input::combo::ComboProgress::Broken => "expired",
                crate::input::combo::ComboProgress::Advanced { .. } => "in_progress",
                _ => "idle",
            };
            Ok(result)
        });
        // -- reset --
        /// Resets combo progress and elapsed time.
        methods.add_method_mut("reset", |_, this, ()| {
            this.detector.reset();
            this.total_elapsed_ms = 0;
            Ok(())
        });
        // -- progress --
        /// Returns the current combo step index reached.
        /// @return | integer | Number of completed combo steps.
        methods.add_method(
            "progress",
            |_, this, ()| Ok(this.detector.progress() as i64),
        );
        // -- totalSteps --
        /// Returns the number of steps in this combo sequence.
        /// @return | integer | Total combo step count.
        methods.add_method("totalSteps", |_, this, ()| Ok(this.detector.len() as i64));
        // -- isInProgress --
        /// Returns whether the combo sequence is partially matched.
        /// @return | boolean | True when the combo is in progress.
        methods.add_method("isInProgress", |_, this, ()| {
            Ok(this.detector.is_in_progress())
        });
        // -- getStep --
        /// Returns step data by one-based index.
        /// @param | index | integer | One-based combo step index.
        /// @return | table | Step table with `key` and `gap_ms`, or nil when out of range.
        /// @field | key | string | Key name.
        /// @field | gap_ms | number | Gap in milliseconds.
        methods.add_method("getStep", |lua, this, index: usize| {
            if index == 0 || index > this.detector.steps.len() {
                return Ok(LuaValue::Nil);
            }
            let step = &this.detector.steps[index - 1];
            let tbl = lua.create_table()?;
            /// Performs the 'key' operation.
            tbl.set("key", step.key.clone())?;
            /// Performs the 'gap_ms' operation.
            tbl.set("gap_ms", step.max_gap_ms)?;
            Ok(LuaValue::Table(tbl))
        });
        // -- type --
        /// Returns the Lua-visible type name for this combo handle.
        /// @return | string | The string `LCombo`.
        methods.add_method("type", |_, _, ()| Ok("LCombo"));
        // -- typeOf --
        /// Returns whether this combo handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LCombo` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCombo" || name == "Object")
        });
    }
}
/// Lua-side handle for serialized input recording data.
struct LuaInputRecording {
    /// Recorded input frames and metadata.
    inner: crate::input::recorder::InputRecording,
}
/// Provides Lua methods for recording metadata and JSON export.
impl LuaUserData for LuaInputRecording {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- toJson --
        /// Serializes this input recording to JSON text.
        /// @return | string | Recording JSON.
        methods.add_method("toJson", |_, this, ()| {
            this.inner.to_json().map_err(LuaError::RuntimeError)
        });
        // -- totalFrames --
        /// Returns total frame count stored in this recording.
        /// @return | integer | Total recorded frames.
        methods.add_method("totalFrames", |_, this, ()| {
            Ok(this.inner.total_frames as i64)
        });
        // -- frameCount --
        /// Returns the number of event frames stored in this recording.
        /// @return | integer | Stored event frame count.
        methods.add_method("frameCount", |_, this, ()| {
            Ok(this.inner.frames.len() as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this input recording handle.
        /// @return | string | The string `LInputRecording`.
        methods.add_method("type", |_, _, ()| Ok("LInputRecording"));
        // -- typeOf --
        /// Returns whether this input recording handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LInputRecording` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LInputRecording" || name == "Object")
        });
    }
}
/// Registers `lurek.input` keyboard, mouse, gamepad, touch, action, combo, and recording helpers.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let input_tbl = lua.create_table()?;
    let keyboard = lua.create_table()?;
    let s = state.clone();
    // -- keyboard.isDown --
    /// Returns whether any of the supplied key names are currently held down.
    /// @param | ... | string | One or more key name strings (e.g. `"space"`, `"w"`, `"up"`). At least one required.
    /// @return | boolean | `true` if any of the given keys is currently pressed.
    keyboard.set(
        "isDown",
        lua.create_function(move |_, args: Variadic<String>| {
            Ok(s.borrow().keyboard.is_any_down(&args))
        })?,
    )?;
    let s = state.clone();
    // -- keyboard.isScancodeDown --
    /// Returns whether a scancode is currently down.
    /// @param | scancode | string | Keyboard scancode name.
    /// @return | boolean | True when the scancode is down.
    keyboard.set(
        "isScancodeDown",
        lua.create_function(move |_, scancode: String| {
            Ok(s.borrow().keyboard.is_scancode_down(&scancode))
        })?,
    )?;
    let s = state.clone();
    // -- keyboard.setKeyRepeat --
    /// Enables or disables key repeat tracking.
    /// @param | enabled | boolean | New key repeat flag.
    keyboard.set(
        "setKeyRepeat",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_key_repeat(enabled);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- keyboard.hasKeyRepeat --
    /// Returns whether key repeat tracking is enabled.
    /// @return | boolean | True when key repeat is enabled.
    keyboard.set(
        "hasKeyRepeat",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_key_repeat()))?,
    )?;
    let s = state.clone();
    // -- keyboard.setTextInput --
    /// Enables or disables text input tracking.
    /// @param | enabled | boolean | New text input flag.
    keyboard.set(
        "setTextInput",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_text_input(enabled);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- keyboard.hasTextInput --
    /// Returns whether text input tracking is enabled.
    /// @return | boolean | True when text input is enabled.
    keyboard.set(
        "hasTextInput",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_text_input()))?,
    )?;
    // -- keyboard.getScancodeFromKey --
    /// Converts a key name to its scancode name when known.
    /// @param | key | string | Key name.
    /// @return | string | Scancode string, or nil when unknown.
    keyboard.set(
        "getScancodeFromKey",
        lua.create_function(move |_, key: String| Ok(get_scancode_from_key(&key)))?,
    )?;
    // -- keyboard.getKeyFromScancode --
    /// Converts a scancode name to its key name when known.
    /// @param | scancode | string | Scancode name.
    /// @return | string | Key string, or nil when unknown.
    keyboard.set(
        "getKeyFromScancode",
        lua.create_function(move |_, scancode: String| Ok(get_key_from_scancode(&scancode)))?,
    )?;
    let s = state.clone();
    // -- keyboard.isModifierActive --
    /// Returns whether a named keyboard modifier is active.
    /// @param | modifier | string | Modifier name such as shift, ctrl, alt, or gui.
    /// @return | boolean | True when the modifier is active.
    keyboard.set(
        "isModifierActive",
        lua.create_function(move |_, modifier: String| {
            Ok(s.borrow().keyboard.is_modifier_active(&modifier))
        })?,
    )?;
    /// Performs the 'keyboard' operation.
    input_tbl.set("keyboard", keyboard)?;
    let mouse = lua.create_table()?;
    let s = state.clone();
    // -- mouse.getPosition --
    /// Returns the current mouse position.
    /// @return | number | Mouse x coordinate.
    /// @return | number | Mouse y coordinate.
    mouse.set(
        "getPosition",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.mouse.x, st.mouse.y))
        })?,
    )?;
    let s = state.clone();
    // -- mouse.getX --
    /// Returns the current mouse x coordinate.
    /// @return | number | Mouse x coordinate.
    mouse.set(
        "getX",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.x))?,
    )?;
    let s = state.clone();
    // -- mouse.getY --
    /// Returns the current mouse y coordinate.
    /// @return | number | Mouse y coordinate.
    mouse.set(
        "getY",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.y))?,
    )?;
    let s = state.clone();
    // -- mouse.isDown --
    /// Returns whether a one-based mouse button index is down.
    /// @param | button | integer | One-based mouse button index.
    /// @return | boolean | True when the button is down.
    mouse.set(
        "isDown",
        lua.create_function(move |_, button: usize| {
            Ok(s.borrow().mouse.is_down(button.saturating_sub(1)))
        })?,
    )?;
    let s = state.clone();
    // -- mouse.setVisible --
    /// Sets the mouse cursor visibility state.
    /// @param | visible | boolean | New cursor visibility flag.
    mouse.set(
        "setVisible",
        lua.create_function(move |_, visible: bool| {
            s.borrow_mut().mouse.set_visible(visible);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- mouse.isVisible --
    /// Returns whether the mouse cursor is visible.
    /// @return | boolean | True when the cursor is visible.
    mouse.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_visible()))?,
    )?;
    let s = state.clone();
    // -- mouse.setGrabbed --
    /// Sets whether the mouse is grabbed by the window.
    /// @param | grabbed | boolean | New grabbed flag.
    mouse.set(
        "setGrabbed",
        lua.create_function(move |_, grabbed: bool| {
            s.borrow_mut().mouse.set_grabbed(grabbed);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- mouse.isGrabbed --
    /// Returns whether the mouse is grabbed by the window.
    /// @return | boolean | True when the mouse is grabbed.
    mouse.set(
        "isGrabbed",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_grabbed()))?,
    )?;
    let s = state.clone();
    // -- mouse.setRelativeMode --
    /// Sets the relative mouse input mode state.
    /// @param | relative | boolean | New relative mode flag.
    mouse.set(
        "setRelativeMode",
        lua.create_function(move |_, relative: bool| {
            s.borrow_mut().mouse.set_relative_mode(relative);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- mouse.getRelativeMode --
    /// Returns whether relative mouse mode is enabled.
    /// @return | boolean | True when relative mode is enabled.
    mouse.set(
        "getRelativeMode",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_relative_mode()))?,
    )?;
    let s = state.clone();
    // -- mouse.setPosition --
    /// Requests a mouse cursor position change.
    /// @param | x | number | Target x coordinate.
    /// @param | y | number | Target y coordinate.
    mouse.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mouse.request_position(x, y);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- mouse.setCursor --
    /// Sets the active cursor from a cursor handle, system cursor name, or nil for arrow.
    /// @param | cursor | LCursor | `LCursor`, system cursor string, or nil.
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
    // -- mouse.newCursor --
    /// Creates a custom cursor handle from RGBA pixels and hotspot coordinates.
    /// @param | pixels | table | Cursor pixel bytes.
    /// @param | width | integer | Cursor width in pixels.
    /// @param | height | integer | Cursor height in pixels.
    /// @param | hotx | integer? | Optional hotspot x coordinate.
    /// @param | hoty | integer? | Optional hotspot y coordinate.
    /// @return | LCursor | New custom cursor handle.
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
    // -- mouse.getSystemCursor --
    /// Creates a system cursor handle from a cursor name.
    /// @param | name | string | System cursor name.
    /// @return | LCursor | System cursor handle.
    mouse.set(
        "getSystemCursor",
        lua.create_function(move |_, name: String| {
            Ok(LuaCursor {
                kind: CursorKind::System(SystemCursor::from_name(&name)),
            })
        })?,
    )?;
    // -- mouse.isCursorSupported --
    /// Returns whether the current platform supports cursor changes.
    /// @return | boolean | True when cursor changes are supported.
    mouse.set(
        "isCursorSupported",
        lua.create_function(move |_, ()| Ok(is_cursor_supported()))?,
    )?;
    let s = state.clone();
    // -- mouse.getCursor --
    /// Returns the current system cursor name.
    /// @return | string | Current cursor name.
    mouse.set(
        "getCursor",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_cursor().as_str().to_string()))?,
    )?;
    let s = state.clone();
    // -- mouse.getWheelDelta --
    /// Returns the current mouse wheel delta.
    /// @return | number | Horizontal wheel delta.
    /// @return | number | Vertical wheel delta.
    mouse.set(
        "getWheelDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_scroll()))?,
    )?;
    /// Performs the 'mouse' operation.
    input_tbl.set("mouse", mouse)?;
    let gamepad = lua.create_table()?;
    let s = state.clone();
    // -- gamepad.getCount --
    /// Returns the number of gamepad slots tracked by the runtime.
    /// @return | integer | Gamepad slot count.
    gamepad.set(
        "getCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;
    let s = state.clone();
    // -- gamepad.getJoystickCount --
    /// Returns the number of joystick slots tracked by the runtime.
    /// @return | integer | Joystick slot count.
    gamepad.set(
        "getJoystickCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;
    let s = state.clone();
    // -- gamepad.getJoysticks --
    /// Returns ids for currently connected gamepads.
    /// @return | integer[] | Array table of connected gamepad ids.
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
    let s = state.clone();
    // -- gamepad.isConnected --
    /// Returns whether a gamepad id is currently connected.
    /// @param | id | integer | Gamepad id.
    /// @return | boolean | True when the gamepad is connected.
    gamepad.set(
        "isConnected",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.getName --
    /// Returns a gamepad display name by its id.
    /// @param | id | integer | Gamepad id.
    /// @return | string | Gamepad name, or `Unknown` when missing.
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
    let s = state.clone();
    // -- gamepad.isGamepad --
    /// Returns whether a connected gamepad exists at an id.
    /// @param | id | integer | Gamepad id.
    /// @return | boolean | True when the id is a connected gamepad.
    gamepad.set(
        "isGamepad",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.getButtonCount --
    /// Returns the button count for a gamepad.
    /// @param | id | integer | Gamepad id.
    /// @return | integer | Button count, or zero when missing.
    gamepad.set(
        "getButtonCount",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .map_or(0, |gp| gp.get_button_count()))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.getAxisCount --
    /// Returns the axis count for a gamepad.
    /// @param | id | integer | Gamepad id.
    /// @return | integer | Axis count, or zero when missing.
    gamepad.set(
        "getAxisCount",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .map_or(0, |gp| gp.get_axis_count()))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.isDown --
    /// Returns whether a gamepad button is currently down.
    /// @param | id | integer | Gamepad id.
    /// @param | button | integer | Button index.
    /// @return | boolean | True when the button is down.
    gamepad.set(
        "isDown",
        lua.create_function(move |_, (id, button): (usize, u32)| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.is_button_pressed(button)))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.getAxis --
    /// Returns a gamepad axis value by index.
    /// @param | id | integer | Gamepad id.
    /// @param | axis | integer | Axis index.
    /// @return | number | Axis value, or zero when missing.
    gamepad.set(
        "getAxis",
        lua.create_function(move |_, (id, axis): (usize, u32)| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .map_or(0.0, |gp| gp.get_axis_value(axis)))
        })?,
    )?;
    // -- gamepad.virtualDpad --
    /// Converts analog x and y values into virtual d-pad booleans and direction.
    /// @param | x | number | Horizontal analog value.
    /// @param | y | number | Vertical analog value.
    /// @param | deadzone | number? | Deadzone threshold, defaults to 0.3.
    /// @return | table | Table with `up`, `down`, `left`, `right`, and `direction` fields.
    /// @field | up | boolean | Up pressed.
    /// @field | down | boolean | Down pressed.
    /// @field | left | boolean | Left pressed.
    /// @field | right | boolean | Right pressed.
    /// @field | direction | string | Direction name.
    gamepad.set(
        "virtualDpad",
        lua.create_function(move |lua, (x, y, deadzone): (f32, f32, Option<f32>)| {
            let (up, down, left, right, direction) = virtual_dpad(x, y, deadzone.unwrap_or(0.3));
            let tbl = lua.create_table()?;
            /// Performs the 'up' operation.
            tbl.set("up", up)?;
            /// Performs the 'down' operation.
            tbl.set("down", down)?;
            /// Performs the 'left' operation.
            tbl.set("left", left)?;
            /// Performs the 'right' operation.
            tbl.set("right", right)?;
            /// Performs the 'direction' operation.
            tbl.set("direction", direction)?;
            Ok(tbl)
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.isVibrationSupported --
    /// Returns whether a gamepad supports vibration requests.
    /// @param | id | integer | Gamepad id.
    /// @return | boolean | True when vibration is supported.
    gamepad.set(
        "isVibrationSupported",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.is_vibration_supported()))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.vibrate --
    /// Requests gamepad vibration with low and high frequency motor strengths.
    /// @param | id | integer | Gamepad id.
    /// @param | low_freq | number | Low-frequency motor strength clamped to 0.0 through 1.0.
    /// @param | high_freq | number | High-frequency motor strength clamped to 0.0 through 1.0.
    /// @param | duration_ms | number | Duration in milliseconds.
    /// @return | boolean | True when the gamepad supports vibration and the request was queued.
    gamepad.set(
        "vibrate",
        lua.create_function(
            move |_, (id, low_freq, high_freq, duration_ms): (usize, f32, f32, f32)| {
                let mut st = s.borrow_mut();
                let low_freq = low_freq.clamp(0.0, 1.0);
                let high_freq = high_freq.clamp(0.0, 1.0);
                let duration_ms = duration_ms.max(0.0).round() as u32;
                let supported = st
                    .gamepads
                    .get(id)
                    .is_some_and(|gp| gp.is_vibration_supported());
                if supported {
                    st.gamepad_vibration_requests
                        .push(crate::input::GamepadVibrationRequest {
                            id,
                            low_freq,
                            high_freq,
                            duration_ms,
                        });
                }
                Ok(supported)
            },
        )?,
    )?;
    let s = state.clone();
    // -- gamepad.getGUID --
    /// Returns the GUID string for a gamepad.
    /// @param | id | integer | Gamepad id.
    /// @return | string | GUID string, or an empty string when missing.
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
    let s = state.clone();
    // -- gamepad.getHat --
    /// Returns hat direction for a gamepad hat index.
    /// @param | id | integer | Gamepad id.
    /// @param | hat | integer | Hat index.
    /// @return | string | Hat direction string, or `c` when centered or missing.
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
    let s = state.clone();
    // -- gamepad.setVibration --
    /// Requests gamepad vibration with low and high frequency motor strengths.
    /// @param | id | integer | Gamepad id.
    /// @param | low_freq | number | Low-frequency motor strength clamped to 0.0 through 1.0.
    /// @param | high_freq | number | High-frequency motor strength clamped to 0.0 through 1.0.
    /// @param | duration_ms | number | Duration in milliseconds.
    /// @return | boolean | True when the gamepad supports vibration and the request was queued.
    gamepad.set(
        "setVibration",
        lua.create_function(
            move |_, (id, low_freq, high_freq, duration_ms): (usize, f32, f32, f32)| {
                let mut st = s.borrow_mut();
                let low_freq = low_freq.clamp(0.0, 1.0);
                let high_freq = high_freq.clamp(0.0, 1.0);
                let duration_ms = duration_ms.max(0.0).round() as u32;
                let supported = st
                    .gamepads
                    .get(id)
                    .is_some_and(|gp| gp.is_vibration_supported());
                if supported {
                    st.gamepad_vibration_requests
                        .push(crate::input::GamepadVibrationRequest {
                            id,
                            low_freq,
                            high_freq,
                            duration_ms,
                        });
                }
                Ok(supported)
            },
        )?,
    )?;
    let s = state.clone();
    // -- gamepad.wasPressed --
    /// Returns whether a gamepad button was pressed this frame.
    /// @param | id | integer | Gamepad id.
    /// @param | button | integer | Button index.
    /// @return | boolean | True when the button was pressed.
    gamepad.set(
        "wasPressed",
        lua.create_function(move |_, (id, button): (usize, u32)| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.was_button_pressed(button)))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.wasReleased --
    /// Returns whether a gamepad button was released this frame.
    /// @param | id | integer | Gamepad id.
    /// @param | button | integer | Button index.
    /// @return | boolean | True when the button was released.
    gamepad.set(
        "wasReleased",
        lua.create_function(move |_, (id, button): (usize, u32)| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.was_button_released(button)))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.wasConnected --
    /// Returns whether a gamepad connected this frame.
    /// @param | id | integer | Gamepad id.
    /// @return | boolean | True when the gamepad connected this frame.
    gamepad.set(
        "wasConnected",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.was_connected_this_frame()))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.wasDisconnected --
    /// Returns whether a gamepad disconnected this frame.
    /// @param | id | integer | Gamepad id.
    /// @return | boolean | True when the gamepad disconnected this frame.
    gamepad.set(
        "wasDisconnected",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow()
                .gamepads
                .get(id)
                .is_some_and(|gp| gp.was_disconnected_this_frame()))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.setBackgroundEvents --
    /// Enables or disables background gamepad event processing.
    /// @param | enable | boolean | New background event flag.
    gamepad.set(
        "setBackgroundEvents",
        lua.create_function(move |_, enable: bool| {
            s.borrow_mut().gamepad_background_events = enable;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.getBackgroundEvents --
    /// Returns whether background gamepad event processing is enabled.
    /// @return | boolean | True when background events are enabled.
    gamepad.set(
        "getBackgroundEvents",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepad_background_events))?,
    )?;
    let s = state.clone();
    // -- gamepad.setGamepadMapping --
    /// Stores a controller mapping string for a gamepad GUID.
    /// @param | guid | string | Gamepad GUID.
    /// @param | mapping | string | Mapping string.
    gamepad.set(
        "setGamepadMapping",
        lua.create_function(move |_, (guid, mapping): (String, String)| {
            s.borrow_mut().gamepad_mappings.set_mapping(&guid, &mapping);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.getGamepadMappingString --
    /// Returns a stored mapping string for a gamepad GUID.
    /// @param | guid | string | Gamepad GUID.
    /// @return | string | Mapping string, or nil when no mapping exists.
    gamepad.set(
        "getGamepadMappingString",
        lua.create_function(move |_, guid: String| {
            Ok(s.borrow()
                .gamepad_mappings
                .get_mapping_string(&guid)
                .map(|m| m.to_string()))
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.loadGamepadMappings --
    /// Loads gamepad mapping strings from a file.
    /// @param | path | string | Mapping file path.
    gamepad.set(
        "loadGamepadMappings",
        lua.create_function(move |_, path: String| {
            s.borrow_mut()
                .gamepad_mappings
                .load_from_file(&path)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- gamepad.saveGamepadMappings --
    /// Saves gamepad mapping strings to a file.
    /// @param | path | string | Mapping file path.
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
    /// Performs the 'gamepad' operation.
    input_tbl.set("gamepad", gamepad)?;
    let touch = lua.create_table()?;
    let s = state.clone();
    // -- touch.getTouches --
    /// Returns active touch points with id, position, and pressure.
    /// @return | table | Array table of touch records.
    /// @field | id | integer | Touch point id.
    /// @field | x | number | Touch x position.
    /// @field | y | number | Touch y position.
    /// @field | pressure | number | Touch pressure.
    touch.set(
        "getTouches",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let touches = st.touch.get_touches();
            let tbl = lua.create_table()?;
            for (i, tp) in touches.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'id' operation.
                entry.set("id", tp.id)?;
                /// Performs the 'x' operation.
                entry.set("x", tp.x)?;
                /// Performs the 'y' operation.
                entry.set("y", tp.y)?;
                /// Performs the 'pressure' operation.
                entry.set("pressure", tp.pressure)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = state.clone();
    // -- touch.getPosition --
    /// Returns the position of a touch point by id.
    /// @param | id | integer | Touch id.
    /// @return | number | Touch x coordinate, or 0 when missing.
    /// @return | number | Touch y coordinate, or 0 when missing.
    touch.set(
        "getPosition",
        lua.create_function(move |_, id: u64| {
            let st = s.borrow();
            let (x, y) = st.touch.get_touch(id).map_or((0.0, 0.0), |tp| (tp.x, tp.y));
            Ok((x, y))
        })?,
    )?;
    let s = state.clone();
    // -- touch.getPressure --
    /// Returns pressure for a touch point by its id.
    /// @param | id | integer | Touch id.
    /// @return | number | Touch pressure, or 0 when missing.
    touch.set(
        "getPressure",
        lua.create_function(move |_, id: u64| {
            Ok(s.borrow().touch.get_touch(id).map_or(0.0, |tp| tp.pressure))
        })?,
    )?;
    let s = state.clone();
    // -- touch.getTouchCount --
    /// Returns the current active touch count.
    /// @return | integer | Active touch count.
    touch.set(
        "getTouchCount",
        lua.create_function(move |_, ()| Ok(s.borrow().touch.get_touch_count()))?,
    )?;
    let s = state.clone();
    // -- touch.wasPressed --
    /// Returns whether a touch id began this frame.
    /// @param | id | integer | Touch id.
    /// @return | boolean | True when the touch was pressed.
    touch.set(
        "wasPressed",
        lua.create_function(move |_, id: u64| Ok(s.borrow().touch.was_pressed(id)))?,
    )?;
    let s = state.clone();
    // -- touch.wasReleased --
    /// Returns whether a touch id ended this frame.
    /// @param | id | integer | Touch id.
    /// @return | boolean | True when the touch was released.
    touch.set(
        "wasReleased",
        lua.create_function(move |_, id: u64| Ok(s.borrow().touch.was_released(id)))?,
    )?;
    /// Performs the 'touch' operation.
    input_tbl.set("touch", touch)?;
    let action_map: Rc<RefCell<HashMap<String, Vec<String>>>> =
        Rc::new(RefCell::new(HashMap::new()));
    let last_pressed_frame: Rc<RefCell<HashMap<String, u64>>> =
        Rc::new(RefCell::new(HashMap::new()));
    let am = action_map.clone();
    // -- bind --
    /// Adds one or more keyboard/gamepad bindings to an action.
    /// @param | action | string | Action name.
    /// @param | keys | string | Binding string or array table of binding strings.
    input_tbl.set(
        "bind",
        lua.create_function(move |_, (action, keys): (String, LuaValue)| {
            let mut map = am.borrow_mut();
            let entry = map.entry(action).or_default();
            match keys {
                LuaValue::String(s) => {
                    let k = s
                        .to_str()
                        .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                        .to_string();
                    if !entry.contains(&k) {
                        entry.push(k);
                    }
                }
                LuaValue::Table(t) => {
                    for pair in t.sequence_values::<String>() {
                        let k = pair?;
                        if !entry.contains(&k) {
                            entry.push(k);
                        }
                    }
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "input.bind: keys must be a string or array of strings".into(),
                    ))
                }
            }
            Ok(())
        })?,
    )?;
    let am = action_map.clone();
    let s = state.clone();
    // -- newMapping --
    /// Creates an action mapping table with isDown, wasPressed, and wasReleased helper functions.
    /// @param | name | string | Action name.
    /// @param | keys | string | Binding string or array table of binding strings.
    /// @return | table | Mapping table with action query closures.
    /// @field | isDown | function | Returns true while the action is held.
    /// @field | wasPressed | function | Returns true on the frame the action was pressed.
    /// @field | wasReleased | function | Returns true on the frame the action was released.
    input_tbl.set(
        "newMapping",
        lua.create_function(move |lua, (name, keys): (String, LuaValue)| {
            {
                let mut map = am.borrow_mut();
                let entry = map.entry(name.clone()).or_default();
                match keys {
                    LuaValue::String(s) => {
                        let k = s
                            .to_str()
                            .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                            .to_string();
                        if !entry.contains(&k) {
                            entry.push(k);
                        }
                    }
                    LuaValue::Table(t) => {
                        for pair in t.sequence_values::<String>() {
                            let k = pair?;
                            if !entry.contains(&k) {
                                entry.push(k);
                            }
                        }
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "input.newMapping: keys must be a string or array of strings".into(),
                        ))
                    }
                }
            }
            let mapping = lua.create_table()?;
            /// Performs the 'name' operation.
            mapping.set("name", name.clone())?;
            let action = name.clone();
            /// Returns whether any bound key for this mapping is currently down.
            /// @return | boolean | True when any bound key is down.
            let am_is_down = am.clone();
            let s_is_down = s.clone();
            mapping.set(
                "isDown",
                lua.create_function(move |_, ()| {
                    let map = am_is_down.borrow();
                    if let Some(keys) = map.get(&action) {
                        let st = s_is_down.borrow();
                        return Ok(keys.iter().any(|k| binding_is_down(&st, k)));
                    }
                    Ok(false)
                })?,
            )?;
            let action = name.clone();
            /// Returns whether any bound key for this mapping was pressed this frame.
            /// @return | boolean | True when any bound key was pressed.
            let am_pressed = am.clone();
            let s_pressed = s.clone();
            mapping.set(
                "wasPressed",
                lua.create_function(move |_, ()| {
                    let map = am_pressed.borrow();
                    if let Some(keys) = map.get(&action) {
                        let st = s_pressed.borrow();
                        return Ok(keys.iter().any(|k| binding_was_pressed(&st, k)));
                    }
                    Ok(false)
                })?,
            )?;
            let action = name.clone();
            /// Returns whether any bound key for this mapping was released this frame.
            /// @return | boolean | True when any bound key was released.
            let am_released = am.clone();
            let s_released = s.clone();
            mapping.set(
                "wasReleased",
                lua.create_function(move |_, ()| {
                    let map = am_released.borrow();
                    if let Some(keys) = map.get(&action) {
                        let st = s_released.borrow();
                        return Ok(keys.iter().any(|k| binding_was_released(&st, k)));
                    }
                    Ok(false)
                })?,
            )?;
            Ok(mapping)
        })?,
    )?;
    let am = action_map.clone();
    // -- unbind --
    /// Removes all bindings for an action.
    /// @param | action | string | Action name.
    /// @return | boolean | True when the action had bindings.
    input_tbl.set(
        "unbind",
        lua.create_function(move |_, action: String| {
            Ok(am.borrow_mut().remove(&action).is_some())
        })?,
    )?;
    let am = action_map.clone();
    // -- clearBindings --
    /// Removes all action bindings from the map.
    input_tbl.set(
        "clearBindings",
        lua.create_function(move |_, ()| {
            am.borrow_mut().clear();
            Ok(())
        })?,
    )?;
    let am = action_map.clone();
    // -- getBindings --
    /// Returns all registered action bindings.
    /// @return | string[] | Map table from action names to arrays of binding strings.
    input_tbl.set(
        "getBindings",
        lua.create_function(move |lua, ()| {
            let map = am.borrow();
            let out = lua.create_table()?;
            for (action, keys) in map.iter() {
                let kt = lua.create_table()?;
                for (i, k) in keys.iter().enumerate() {
                    kt.set(i + 1, k.clone())?;
                }
                out.set(action.clone(), kt)?;
            }
            Ok(out)
        })?,
    )?;
    let am = action_map.clone();
    let s = state.clone();
    // -- isActionDown --
    /// Returns whether any binding for an action is currently down.
    /// @param | action | string | Action name.
    /// @return | boolean | True when any binding is down.
    input_tbl.set(
        "isActionDown",
        lua.create_function(move |_, action: String| {
            let map = am.borrow();
            if let Some(keys) = map.get(&action) {
                let st = s.borrow();
                return Ok(keys.iter().any(|k| binding_is_down(&st, k)));
            }
            Ok(false)
        })?,
    )?;
    let am = action_map.clone();
    let lpf = last_pressed_frame.clone();
    let s = state.clone();
    // -- wasActionPressed --
    /// Returns whether any binding for an action was pressed this frame and records the frame.
    /// @param | action | string | Action name.
    /// @return | boolean | True when any binding was pressed this frame.
    input_tbl.set(
        "wasActionPressed",
        lua.create_function(move |_, action: String| {
            let map = am.borrow();
            if let Some(keys) = map.get(&action) {
                let st = s.borrow();
                let was_pressed = keys.iter().any(|k| binding_was_pressed(&st, k));
                if was_pressed {
                    let frame = st.clock.frame_count();
                    lpf.borrow_mut().insert(action, frame);
                    return Ok(true);
                }
            }
            Ok(false)
        })?,
    )?;
    let am = action_map.clone();
    let s = state.clone();
    // -- wasActionReleased --
    /// Returns whether any binding for an action was released this frame.
    /// @param | action | string | Action name.
    /// @return | boolean | True when any binding was released this frame.
    input_tbl.set(
        "wasActionReleased",
        lua.create_function(move |_, action: String| {
            let map = am.borrow();
            if let Some(keys) = map.get(&action) {
                let st = s.borrow();
                return Ok(keys.iter().any(|k| binding_was_released(&st, k)));
            }
            Ok(false)
        })?,
    )?;
    let lpf = last_pressed_frame;
    let s = state.clone();
    // -- wasActionPressedWithin --
    /// Returns whether an action was pressed within a recent frame window.
    /// @param | action | string | Action name.
    /// @param | frames | integer | Number of frames allowed since the last press.
    /// @return | boolean | True when the action was pressed within the window.
    input_tbl.set(
        "wasActionPressedWithin",
        lua.create_function(move |_, (action, frames): (String, u64)| {
            if let Some(&pressed_at) = lpf.borrow().get(&action) {
                let current = s.borrow().clock.frame_count();
                return Ok(current.saturating_sub(pressed_at) <= frames);
            }
            Ok(false)
        })?,
    )?;
    // -- newCombo --
    /// Creates a combo detector from string steps or step tables with optional timing.
    /// @param | steps | table | Array table of key strings or `{key, gap}` step tables.
    /// @param | opts | table? | Options table with `total_gap` in milliseconds.
    /// @return | LCombo | New combo detector handle.
    input_tbl.set(
        "newCombo",
        lua.create_function(|_lua, (steps_val, opts): (LuaTable, Option<LuaTable>)| {
            let total_gap_ms: u64 = opts
                .as_ref()
                .and_then(|t| t.get::<_, Option<u64>>("total_gap").ok().flatten())
                .unwrap_or(2000);
            let mut steps: Vec<ComboStep> = Vec::new();
            for pair in steps_val.sequence_values::<LuaValue>() {
                let val = pair?;
                match val {
                    LuaValue::String(s) => {
                        let key = s
                            .to_str()
                            .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                            .to_string();
                        steps.push(ComboStep {
                            key,
                            max_gap_ms: 500,
                        });
                    }
                    LuaValue::Table(t) => {
                        let key: String = t.get("key").map_err(|_| {
                            LuaError::RuntimeError(
                                "input.newCombo: each step table must have a 'key' field".into(),
                            )
                        })?;
                        let gap: u64 = t.get::<_, Option<u64>>("gap")?.unwrap_or(500);
                        steps.push(ComboStep {
                            key,
                            max_gap_ms: gap,
                        });
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "input.newCombo: steps must be strings or tables".into(),
                        ))
                    }
                }
            }
            if steps.is_empty() {
                return Err(LuaError::RuntimeError(
                    "input.newCombo: steps table must not be empty".into(),
                ));
            }
            Ok(LuaCombo {
                detector: ComboDetector::new(steps, total_gap_ms),
                total_elapsed_ms: 0,
            })
        })?,
    )?;
    let rec_rc = Rc::new(RefCell::new(crate::input::recorder::InputRecorder::new()));
    let rc = rec_rc.clone();
    // -- startRecording --
    /// Starts recording input events into the module recorder.
    input_tbl.set(
        "startRecording",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().start_recording();
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
    // -- stopRecording --
    /// Stops input recording and returns the captured recording when one is active.
    /// @return | LInputRecording | Recording handle, or nil when recording was not active.
    input_tbl.set(
        "stopRecording",
        lua.create_function(move |lua, ()| match rc.borrow_mut().stop_recording() {
            Some(rec) => Ok(LuaValue::UserData(
                lua.create_userdata(LuaInputRecording { inner: rec })?,
            )),
            None => Ok(LuaValue::Nil),
        })?,
    )?;
    let rc = rec_rc.clone();
    // -- loadRecording --
    /// Loads recording JSON into the module recorder.
    /// @param | json | string | Recording JSON.
    input_tbl.set(
        "loadRecording",
        lua.create_function(move |_, json: String| {
            let rec = crate::input::recorder::InputRecording::from_json(&json)
                .map_err(LuaError::RuntimeError)?;
            rc.borrow_mut().load(rec);
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
    // -- startPlayback --
    /// Starts playback of the loaded recording.
    input_tbl.set(
        "startPlayback",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().start_playback();
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
    // -- stopPlayback --
    /// Stops playback of the loaded recording.
    input_tbl.set(
        "stopPlayback",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().stop_playback();
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
    // -- isRecording --
    /// Returns whether the module recorder is currently recording.
    /// @return | boolean | True when recording is active.
    input_tbl.set(
        "isRecording",
        lua.create_function(move |_, ()| Ok(rc.borrow().is_recording()))?,
    )?;
    let rc = rec_rc.clone();
    // -- isPlayingBack --
    /// Returns whether the module recorder is currently playing back.
    /// @return | boolean | True when playback is active.
    input_tbl.set(
        "isPlayingBack",
        lua.create_function(move |_, ()| Ok(rc.borrow().is_playing_back()))?,
    )?;
    let rc = rec_rc.clone();
    // -- getPlaybackFrame --
    /// Returns the current playback frame index.
    /// @return | integer | Playback frame index.
    input_tbl.set(
        "getPlaybackFrame",
        lua.create_function(move |_, ()| Ok(rc.borrow().playback_frame_index() as i64))?,
    )?;
    let rc = rec_rc.clone();
    // -- advancePlayback --
    /// Advances playback by one frame and returns events for that frame.
    /// @return | table | Array of event records with `kind` and `name` fields.
    /// @field | kind | string | Event kind (press, release, hold).
    /// @field | name | string | Event name.
    input_tbl.set(
        "advancePlayback",
        lua.create_function(move |lua, ()| {
            let events = rc.borrow_mut().playback_frame();
            let tbl = lua.create_table()?;
            for (i, ev) in events.iter().enumerate() {
                let etbl = lua.create_table()?;
                /// Performs the 'kind' operation.
                etbl.set("kind", ev.kind.clone())?;
                /// Performs the 'name' operation.
                etbl.set("name", ev.name.clone())?;
                tbl.set(i + 1, etbl)?;
            }
            Ok(tbl)
        })?,
    )?;
    /// Performs the 'input' operation.
    lurek.set("input", input_tbl)?;
    Ok(())
}
