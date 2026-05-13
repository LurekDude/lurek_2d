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
fn binding_is_down(st: &SharedState, binding: &str) -> bool {
    if let Some((id, button)) = parse_gamepad_binding(binding) {
        return st
            .gamepads
            .get(id)
            .is_some_and(|gp| gp.is_button_pressed(button));
    }
    st.keyboard.is_down(binding)
}
fn binding_was_pressed(st: &SharedState, binding: &str) -> bool {
    if let Some((id, button)) = parse_gamepad_binding(binding) {
        return st
            .gamepads
            .get(id)
            .is_some_and(|gp| gp.was_button_pressed(button));
    }
    st.keyboard.get_pressed().iter().any(|k| k == binding)
}
fn binding_was_released(st: &SharedState, binding: &str) -> bool {
    if let Some((id, button)) = parse_gamepad_binding(binding) {
        return st
            .gamepads
            .get(id)
            .is_some_and(|gp| gp.was_button_released(button));
    }
    st.keyboard.get_released().iter().any(|k| k == binding)
}
pub struct LuaCursor {
    kind: CursorKind,
}
impl LuaUserData for LuaCursor {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("release", |_, _this, ()| Ok(()));
        methods.add_method("getType", |_, this, ()| {
            Ok(match &this.kind {
                CursorKind::System(_) => "system",
                CursorKind::Custom { .. } => "custom",
            })
        });
        methods.add_method("type", |_, _, ()| Ok("LCursor"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCursor" || name == "Object")
        });
    }
}
struct LuaCombo {
    detector: ComboDetector,
    total_elapsed_ms: u64,
}
impl LuaUserData for LuaCombo {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method_mut("reset", |_, this, ()| {
            this.detector.reset();
            this.total_elapsed_ms = 0;
            Ok(())
        });
        methods.add_method(
            "progress",
            |_, this, ()| Ok(this.detector.progress() as i64),
        );
        methods.add_method("totalSteps", |_, this, ()| Ok(this.detector.len() as i64));
        methods.add_method("isInProgress", |_, this, ()| {
            Ok(this.detector.is_in_progress())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LCombo"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCombo" || name == "Object")
        });
    }
}
struct LuaInputRecording {
    inner: crate::input::recorder::InputRecording,
}
impl LuaUserData for LuaInputRecording {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("toJson", |_, this, ()| {
            this.inner.to_json().map_err(LuaError::RuntimeError)
        });
        methods.add_method("totalFrames", |_, this, ()| {
            Ok(this.inner.total_frames as i64)
        });
        methods.add_method("frameCount", |_, this, ()| {
            Ok(this.inner.frames.len() as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LInputRecording"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LInputRecording" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let input_tbl = lua.create_table()?;
    let keyboard = lua.create_table()?;
    let s = state.clone();
    keyboard.set(
        "isDown",
        lua.create_function(move |_, args: Variadic<String>| {
            Ok(s.borrow().keyboard.is_any_down(&args))
        })?,
    )?;
    let s = state.clone();
    keyboard.set(
        "isScancodeDown",
        lua.create_function(move |_, scancode: String| {
            Ok(s.borrow().keyboard.is_scancode_down(&scancode))
        })?,
    )?;
    let s = state.clone();
    keyboard.set(
        "setKeyRepeat",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_key_repeat(enabled);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    keyboard.set(
        "hasKeyRepeat",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_key_repeat()))?,
    )?;
    let s = state.clone();
    keyboard.set(
        "setTextInput",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().keyboard.set_text_input(enabled);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    keyboard.set(
        "hasTextInput",
        lua.create_function(move |_, ()| Ok(s.borrow().keyboard.has_text_input()))?,
    )?;
    keyboard.set(
        "getScancodeFromKey",
        lua.create_function(move |_, key: String| Ok(get_scancode_from_key(&key)))?,
    )?;
    keyboard.set(
        "getKeyFromScancode",
        lua.create_function(move |_, scancode: String| Ok(get_key_from_scancode(&scancode)))?,
    )?;
    let s = state.clone();
    keyboard.set(
        "isModifierActive",
        lua.create_function(move |_, modifier: String| {
            Ok(s.borrow().keyboard.is_modifier_active(&modifier))
        })?,
    )?;
    input_tbl.set("keyboard", keyboard)?;
    let mouse = lua.create_table()?;
    let s = state.clone();
    mouse.set(
        "getPosition",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.mouse.x, st.mouse.y))
        })?,
    )?;
    let s = state.clone();
    mouse.set(
        "getX",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.x))?,
    )?;
    let s = state.clone();
    mouse.set(
        "getY",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.y))?,
    )?;
    let s = state.clone();
    mouse.set(
        "isDown",
        lua.create_function(move |_, button: usize| {
            Ok(s.borrow().mouse.is_down(button.saturating_sub(1)))
        })?,
    )?;
    let s = state.clone();
    mouse.set(
        "setVisible",
        lua.create_function(move |_, visible: bool| {
            s.borrow_mut().mouse.set_visible(visible);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    mouse.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_visible()))?,
    )?;
    let s = state.clone();
    mouse.set(
        "setGrabbed",
        lua.create_function(move |_, grabbed: bool| {
            s.borrow_mut().mouse.set_grabbed(grabbed);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    mouse.set(
        "isGrabbed",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.is_grabbed()))?,
    )?;
    let s = state.clone();
    mouse.set(
        "setRelativeMode",
        lua.create_function(move |_, relative: bool| {
            s.borrow_mut().mouse.set_relative_mode(relative);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    mouse.set(
        "getRelativeMode",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_relative_mode()))?,
    )?;
    let s = state.clone();
    mouse.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mouse.request_position(x, y);
            Ok(())
        })?,
    )?;
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
    mouse.set(
        "getSystemCursor",
        lua.create_function(move |_, name: String| {
            Ok(LuaCursor {
                kind: CursorKind::System(SystemCursor::from_name(&name)),
            })
        })?,
    )?;
    mouse.set(
        "isCursorSupported",
        lua.create_function(move |_, ()| Ok(is_cursor_supported()))?,
    )?;
    let s = state.clone();
    mouse.set(
        "getCursor",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_cursor().as_str().to_string()))?,
    )?;
    let s = state.clone();
    mouse.set(
        "getWheelDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().mouse.get_scroll()))?,
    )?;
    input_tbl.set("mouse", mouse)?;
    let gamepad = lua.create_table()?;
    let s = state.clone();
    gamepad.set(
        "getCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;
    let s = state.clone();
    gamepad.set(
        "getJoystickCount",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepads.len()))?,
    )?;
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
    let s = state.clone();
    gamepad.set(
        "isConnected",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;
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
    let s = state.clone();
    gamepad.set(
        "isGamepad",
        lua.create_function(move |_, id: usize| {
            Ok(s.borrow().gamepads.get(id).is_some_and(|gp| gp.connected))
        })?,
    )?;
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
    gamepad.set(
        "virtualDpad",
        lua.create_function(move |lua, (x, y, deadzone): (f32, f32, Option<f32>)| {
            let (up, down, left, right, direction) = virtual_dpad(x, y, deadzone.unwrap_or(0.3));
            let tbl = lua.create_table()?;
            tbl.set("up", up)?;
            tbl.set("down", down)?;
            tbl.set("left", left)?;
            tbl.set("right", right)?;
            tbl.set("direction", direction)?;
            Ok(tbl)
        })?,
    )?;
    let s = state.clone();
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
    gamepad.set(
        "setBackgroundEvents",
        lua.create_function(move |_, enable: bool| {
            s.borrow_mut().gamepad_background_events = enable;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    gamepad.set(
        "getBackgroundEvents",
        lua.create_function(move |_, ()| Ok(s.borrow().gamepad_background_events))?,
    )?;
    let s = state.clone();
    gamepad.set(
        "setGamepadMapping",
        lua.create_function(move |_, (guid, mapping): (String, String)| {
            s.borrow_mut().gamepad_mappings.set_mapping(&guid, &mapping);
            Ok(())
        })?,
    )?;
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
    let touch = lua.create_table()?;
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
    let s = state.clone();
    touch.set(
        "getPosition",
        lua.create_function(move |_, id: u64| {
            let st = s.borrow();
            let (x, y) = st.touch.get_touch(id).map_or((0.0, 0.0), |tp| (tp.x, tp.y));
            Ok((x, y))
        })?,
    )?;
    let s = state.clone();
    touch.set(
        "getPressure",
        lua.create_function(move |_, id: u64| {
            Ok(s.borrow().touch.get_touch(id).map_or(0.0, |tp| tp.pressure))
        })?,
    )?;
    let s = state.clone();
    touch.set(
        "getTouchCount",
        lua.create_function(move |_, ()| Ok(s.borrow().touch.get_touch_count()))?,
    )?;
    let s = state.clone();
    touch.set(
        "wasPressed",
        lua.create_function(move |_, id: u64| Ok(s.borrow().touch.was_pressed(id)))?,
    )?;
    let s = state.clone();
    touch.set(
        "wasReleased",
        lua.create_function(move |_, id: u64| Ok(s.borrow().touch.was_released(id)))?,
    )?;
    input_tbl.set("touch", touch)?;
    let action_map: Rc<RefCell<HashMap<String, Vec<String>>>> =
        Rc::new(RefCell::new(HashMap::new()));
    let last_pressed_frame: Rc<RefCell<HashMap<String, u64>>> =
        Rc::new(RefCell::new(HashMap::new()));
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
    let am = action_map.clone();
    let s = state.clone();
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
            mapping.set("name", name.clone())?;
            let action = name.clone();
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
    input_tbl.set(
        "unbind",
        lua.create_function(move |_, action: String| {
            Ok(am.borrow_mut().remove(&action).is_some())
        })?,
    )?;
    let am = action_map.clone();
    input_tbl.set(
        "clearBindings",
        lua.create_function(move |_, ()| {
            am.borrow_mut().clear();
            Ok(())
        })?,
    )?;
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
    let am = action_map.clone();
    let s = state.clone();
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
    input_tbl.set(
        "startRecording",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().start_recording();
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
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
    input_tbl.set(
        "startPlayback",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().start_playback();
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
    input_tbl.set(
        "stopPlayback",
        lua.create_function(move |_, ()| {
            rc.borrow_mut().stop_playback();
            Ok(())
        })?,
    )?;
    let rc = rec_rc.clone();
    input_tbl.set(
        "isRecording",
        lua.create_function(move |_, ()| Ok(rc.borrow().is_recording()))?,
    )?;
    let rc = rec_rc.clone();
    input_tbl.set(
        "isPlayingBack",
        lua.create_function(move |_, ()| Ok(rc.borrow().is_playing_back()))?,
    )?;
    let rc = rec_rc.clone();
    input_tbl.set(
        "getPlaybackFrame",
        lua.create_function(move |_, ()| Ok(rc.borrow().playback_frame_index() as i64))?,
    )?;
    let rc = rec_rc.clone();
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
    lurek.set("input", input_tbl)?;
    Ok(())
}
