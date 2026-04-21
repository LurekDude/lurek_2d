//! `lurek.input.keyboard` / `lurek.input.mouse` / `lurek.input.gamepad` / `lurek.input.touch` â€” Input state queries and cursor management.

use super::SharedState;
use mlua::prelude::*;
use mlua::Variadic;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::input::combo::{ComboDetector, ComboStep};
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
// LuaCombo UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for a [`ComboDetector`] with an integrated millisecond clock.
struct LuaCombo {
    /// The underlying combo detector instance.
    detector: ComboDetector,
    /// Running millisecond accumulator used to supply `elapsed_ms` to the detector.
    total_elapsed_ms: u64,
}

impl LuaUserData for LuaCombo {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- feed --
        /// Feed a key-press event into the combo detector.
        /// Time elapsed since the last `feed` or `tick` call is taken from the internal clock.
        /// @param key : string
        /// @return nil
        /// string  "idle"|"advanced"|"completed"|"broken"
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
        /// Advance the internal clock by `dt` seconds and check for timeouts.
        /// Call once per frame with the frame delta even when no key is pressed.
        /// @param dt : number   frame delta in seconds
        /// @return nil
        /// string  "expired" if a running combo just timed out; "in_progress" or "idle" otherwise
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
        /// Reset the detector to its initial idle state, cancelling any in-progress sequence.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.detector.reset();
            this.total_elapsed_ms = 0;
            Ok(())
        });

        // -- progress --
        /// Returns the number of steps matched so far (0 when idle).
        /// @return integer
        methods.add_method(
            "progress",
            |_, this, ()| Ok(this.detector.progress() as i64),
        );

        // -- totalSteps --
        /// Returns the total number of steps in the combo sequence.
        /// @return integer
        methods.add_method("totalSteps", |_, this, ()| Ok(this.detector.len() as i64));

        // -- isInProgress --
        /// Returns true if the detector is currently mid-sequence.
        /// @return boolean
        methods.add_method("isInProgress", |_, this, ()| {
            Ok(this.detector.is_in_progress())
        });

        // -- getStep --
        /// Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
        /// @param index : integer   1-based
        /// @return nil
        /// table | nil
        methods.add_method("getStep", |lua, this, index: usize| {
            if index == 0 || index > this.detector.steps.len() {
                return Ok(LuaValue::Nil);
            }
            let step = &this.detector.steps[index - 1];
            let tbl = lua.create_table()?;
            tbl.set("key", step.key.clone())?;
            tbl.set("gap_ms", step.max_gap_ms)?;
            Ok(LuaValue::Table(tbl))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaInputRecording â€” userdata returned by stopRecording()
// -------------------------------------------------------------------------------

/// Lua userdata wrapper for a completed [`crate::input::recorder::InputRecording`].
///
/// Returned by `lurek.input.stopRecording()`.  Use `:toJson()` to persist the
/// recording and `lurek.input.loadRecording(json)` to restore it for playback.
struct LuaInputRecording {
    inner: crate::input::recorder::InputRecording,
}

impl LuaUserData for LuaInputRecording {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- toJson --
        /// Serializes this recording to a JSON string for saving to disk.
        /// @return string
        methods.add_method("toJson", |_, this, ()| {
            this.inner.to_json().map_err(LuaError::RuntimeError)
        });

        // -- totalFrames --
        /// Returns the total frame count when recording was stopped.
        /// @return integer
        methods.add_method("totalFrames", |_, this, ()| {
            Ok(this.inner.total_frames as i64)
        });

        // -- frameCount --
        /// Returns the number of sparse event frames stored in this recording.
        /// @return integer
        methods.add_method("frameCount", |_, this, ()| {
            Ok(this.inner.frames.len() as i64)
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.input.keyboard`, `lurek.input.mouse`, `lurek.input.gamepad`, and `lurek.input.touch` API tables.
///
/// @param lua : &Lua
/// @param lurek : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    // lurek.input â€” parent table that nests keyboard, mouse, gamepad, touch
    // plus action-mapping and recorder APIs.
    let input_tbl = lua.create_table()?;

    // â”€â”€ lurek.input.keyboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

    input_tbl.set("keyboard", keyboard)?;

    // â”€â”€ lurek.input.mouse â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_cursor().as_str().to_string()))?,
    )?;

    // -- getWheelDelta --
    /// Returns the mouse scroll wheel delta (dx, dy) since last frame.
    /// @return number, number
    let s = state.clone();
    mouse.set(
        "getWheelDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_scroll()))?,
    )?;

    input_tbl.set("mouse", mouse)?;

    // â”€â”€ lurek.input.gamepad â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            Ok(s.borrow()
                .gamepads
                .get(id)
                .map_or(0, |gp| gp.get_button_count()))
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
            Ok(s.borrow()
                .gamepads
                .get(id)
                .map_or(0, |gp| gp.get_axis_count()))
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
    ///
    /// winit 0.30 does not expose a haptics API on any desktop platform. This function
    /// always returns `false` in the current release. When platform support is added the
    /// return value will reflect actual capability.
    /// @param id : integer
    /// @return boolean
    gamepad.set(
        "isVibrationSupported",
        lua.create_function(move |_, _id: usize| Ok(false))?,
    )?;

    // -- vibrate --
    /// Requests haptic vibration on a gamepad.
    ///
    /// Parameters map to the standard dual-motor model used by most controllers:
    /// - `low_freq`  â€” intensity of the low-frequency (rumble) motor `[0.0, 1.0]`
    /// - `high_freq` â€” intensity of the high-frequency (buzz) motor `[0.0, 1.0]`
    /// - `duration_ms` â€” how long to vibrate in milliseconds
    ///
    /// Returns `false` because winit 0.30 does not expose a haptics API. The call is
    /// logged at `debug` level so it is visible in test recordings even on unsupported
    /// platforms.  When a winit haptics backend is available this function will return
    /// `true` on success.
    ///
    /// @param id : integer
    /// @param low_freq : number
    /// @param high_freq : number
    /// @param duration_ms : number
    /// @return boolean
    gamepad.set(
        "vibrate",
        lua.create_function(
            move |_, (id, low_freq, high_freq, duration_ms): (usize, f32, f32, f32)| {
                let low_freq = low_freq.clamp(0.0, 1.0);
                let high_freq = high_freq.clamp(0.0, 1.0);
                let duration_ms = duration_ms.max(0.0);
                log::debug!(
                    "gamepad::vibrate id={id} low_freq={low_freq:.3} \
                     high_freq={high_freq:.3} duration_ms={duration_ms:.1} \
                     (platform stub â€” winit 0.30 has no haptics API)"
                );
                Ok(false)
            },
        )?,
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

    input_tbl.set("gamepad", gamepad)?;

    // â”€â”€ lurek.input.touch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            let (x, y) = st.touch.get_touch(id).map_or((0.0, 0.0), |tp| (tp.x, tp.y));
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

    input_tbl.set("touch", touch)?;

    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // lurek.input  â€” Action-mapping layer on top of keyboard/mouse/gamepad state
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // action_map: action_name -> list of key/button names
    let action_map: Rc<RefCell<HashMap<String, Vec<String>>>> =
        Rc::new(RefCell::new(HashMap::new()));
    // Tracks the frame count at which each action was last pressed.
    let last_pressed_frame: Rc<RefCell<HashMap<String, u64>>> =
        Rc::new(RefCell::new(HashMap::new()));

    // -- bind --
    /// Maps an action name to one or more key/button names.
    /// Multiple `bind` calls for the same action append to its key list.
    /// @param action : string
    /// @param keys : string | table   one key name or an array of key names
    /// @return nil
    let am = action_map.clone();
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

    // -- unbind --
    /// Removes all key bindings for the given action name.
    /// @param action : string
    /// boolean  true if the action existed
    let am = action_map.clone();
    /// @return boolean
    input_tbl.set(
        "unbind",
        lua.create_function(move |_, action: String| {
            Ok(am.borrow_mut().remove(&action).is_some())
        })?,
    )?;

    // -- clearBindings --
    /// Removes all action bindings.
    /// @return nil
    let am = action_map.clone();
    input_tbl.set(
        "clearBindings",
        lua.create_function(move |_, ()| {
            am.borrow_mut().clear();
            Ok(())
        })?,
    )?;

    // -- getBindings --
    /// Returns a table mapping each action name to its bound keys.
    /// @return table
    let am = action_map.clone();
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

    // -- isActionDown --
    /// Returns true if any key bound to the action is currently held down.
    /// @param action : string
    /// @return boolean
    let am = action_map.clone();
    let s = state.clone();
    input_tbl.set(
        "isActionDown",
        lua.create_function(move |_, action: String| {
            let map = am.borrow();
            if let Some(keys) = map.get(&action) {
                let st = s.borrow();
                for k in keys {
                    if st.keyboard.is_down(k) {
                        return Ok(true);
                    }
                }
            }
            Ok(false)
        })?,
    )?;

    // -- wasActionPressed --
    /// Returns true if any key bound to the action was pressed this frame.
    /// Also records the frame number for use with `wasActionPressedWithin`.
    /// @param action : string
    /// @return boolean
    let am = action_map.clone();
    let lpf = last_pressed_frame.clone();
    let s = state.clone();
    input_tbl.set(
        "wasActionPressed",
        lua.create_function(move |_, action: String| {
            let map = am.borrow();
            if let Some(keys) = map.get(&action) {
                let st = s.borrow();
                let was_pressed = keys.iter().any(|k| st.keyboard.get_pressed().contains(k));
                if was_pressed {
                    let frame = st.clock.frame_count();
                    lpf.borrow_mut().insert(action, frame);
                    return Ok(true);
                }
            }
            Ok(false)
        })?,
    )?;

    // -- wasActionReleased --
    /// Returns true if any key bound to the action was released this frame.
    /// @param action : string
    /// @return boolean
    let am = action_map.clone();
    let s = state.clone();
    input_tbl.set(
        "wasActionReleased",
        lua.create_function(move |_, action: String| {
            let map = am.borrow();
            if let Some(keys) = map.get(&action) {
                let st = s.borrow();
                return Ok(keys.iter().any(|k| st.keyboard.get_released().contains(k)));
            }
            Ok(false)
        })?,
    )?;

    // -- wasActionPressedWithin --
    /// Returns true if the action was pressed within the last `frames` frames.
    /// Requires `wasActionPressed` to have been called at least once per frame;
    /// it is the mechanism that records the last-press frame number.
    /// @param action : string
    /// @param frames : integer
    /// @return boolean
    let lpf = last_pressed_frame;
    let s = state.clone();
    /// Was action pressed within.
    ///
    /// @param action : string
    /// @param frames : integer
    /// @return boolean
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
    /// Creates a new combo detector from an ordered list of steps.
    ///
    /// Each step can be a plain string (key name) or a table `{key="a", gap=500}`.
    /// When a plain string is given, the per-step gap defaults to 500 ms.
    ///
    /// `opts` is an optional table that may contain:
    ///   `total_gap` (integer, ms) â€” budget for the entire sequence (default 2000 ms).
    ///
    /// @param steps : table   array of strings or `{key,gap}` tables
    /// @param opts  : table?  `{total_gap=integer?}`
    /// @return Combo
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

    // â”€â”€ Recording / Playback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    let rec_rc = Rc::new(RefCell::new(crate::input::recorder::InputRecorder::new()));

    let rc = rec_rc.clone();
    /// Starts capturing input events frame-by-frame.  Clears any previous recording.
    /// @return nil
    input_tbl.set(
        "startRecording",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().start_recording();
            Ok(())
        })?,
    )?;

    let rc = rec_rc.clone();
    /// Stops recording and returns an `InputRecording` userdata, or nil if not recording.
    /// @return table|nil
    /// InputRecording|nil
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
    /// Loads a JSON-encoded recording string for playback.
    /// @param json : string
    /// @return nil
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
    /// Starts playback from the beginning of the loaded recording.
    /// @return nil
    input_tbl.set(
        "startPlayback",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().start_playback();
            Ok(())
        })?,
    )?;

    let rc = rec_rc.clone();
    /// Stops playback immediately.
    /// @return nil
    input_tbl.set(
        "stopPlayback",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().stop_playback();
            Ok(())
        })?,
    )?;

    let rc = rec_rc.clone();
    /// Returns true if input recording is currently active.
    /// @return boolean
    input_tbl.set(
        "isRecording",
        lua.create_function(move |_, ()| Ok(rc.borrow().is_recording()))?,
    )?;

    let rc = rec_rc.clone();
    /// Returns true if input playback is currently active.
    /// @return boolean
    input_tbl.set(
        "isPlayingBack",
        lua.create_function(move |_, ()| Ok(rc.borrow().is_playing_back()))?,
    )?;

    let rc = rec_rc.clone();
    /// Returns the current playback frame index (0-based).  Returns 0 when not playing.
    /// @return integer
    input_tbl.set(
        "getPlaybackFrame",
        lua.create_function(move |_, ()| Ok(rc.borrow().playback_frame_index() as i64))?,
    )?;

    let rc = rec_rc.clone();
    /// Advances playback by one frame and returns an array of key/button events for that
    /// frame.  Each event is a table with `kind` ("down"|"up") and `name` string fields.
    /// @return table
    input_tbl.set(
        "advancePlayback",
        lua.create_function(move |lua, ()| {
            let events = rc.borrow_mut().playback_frame();
            let tbl = lua.create_table()?;
            for (i, ev) in events.iter().enumerate() {
                let etbl = lua.create_table()?;
                etbl.set("kind", ev.kind.clone())?;
                etbl.set("name", ev.name.clone())?;
                tbl.set(i + 1, etbl)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Namespace containing the input API module.
    /// Provides input handling devices and event streams.
    lurek.set("input", input_tbl)?;

    Ok(())
}
