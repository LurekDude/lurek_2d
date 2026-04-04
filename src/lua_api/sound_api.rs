//! Registers the `luna.sound.*` decoded audio sample manipulation API.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::SharedState;
use crate::sound::SoundData;

/// Registers the `luna.sound` table on the provided `luna` namespace.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let sound_table = lua.create_table()?;

    // luna.sound.newSoundData(filename) or luna.sound.newSoundData(sampleCount, sampleRate?, channels?)
    let state_clone = state.clone();
    sound_table.set(
        "newSoundData",
        lua.create_function(move |lua, args: LuaMultiValue| {
            let snd_data =
                if args.len() == 1 {
                    match args.into_iter().next().unwrap() {
                        LuaValue::String(s) => {
                            let filename = s
                                .to_str()
                                .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                                .to_string();
                            let state = state_clone.borrow();
                            let path = state.game_dir.join(&filename);
                            SoundData::from_file(path.to_str().ok_or_else(|| {
                                LuaError::RuntimeError("Invalid path".to_string())
                            })?)
                            .map_err(LuaError::RuntimeError)?
                        }
                        LuaValue::Integer(n) => SoundData::new(n as usize, 44100, 1),
                        LuaValue::Number(n) => SoundData::new(n as usize, 44100, 1),
                        _ => {
                            return Err(LuaError::RuntimeError(
                                "newSoundData expects a filename or sample count".to_string(),
                            ))
                        }
                    }
                } else {
                    let mut iter = args.into_iter();
                    let count = match iter.next().unwrap() {
                        LuaValue::Integer(n) => n as usize,
                        LuaValue::Number(n) => n as usize,
                        _ => {
                            return Err(LuaError::RuntimeError(
                                "sample count must be a number".to_string(),
                            ))
                        }
                    };
                    let rate = iter
                        .next()
                        .and_then(|v| match v {
                            LuaValue::Integer(n) => Some(n as u32),
                            LuaValue::Number(n) => Some(n as u32),
                            _ => None,
                        })
                        .unwrap_or(44100);
                    let channels = iter
                        .next()
                        .and_then(|v| match v {
                            LuaValue::Integer(n) => Some(n as u16),
                            LuaValue::Number(n) => Some(n as u16),
                            _ => None,
                        })
                        .unwrap_or(1);
                    SoundData::new(count, rate, channels)
                };

            lua.create_userdata(snd_data)
        })?,
    )?;

    // luna.sound.setMidiSoundFont(path)
    let state_clone = state.clone();
    sound_table.set(
        "setMidiSoundFont",
        lua.create_function(move |_, path: String| {
            let mut st = state_clone.borrow_mut();
            let full_path = st.game_dir.join(&path);
            let data = std::fs::read(&full_path).map_err(|e| {
                LuaError::RuntimeError(format!(
                    "Failed to read SoundFont '{}': {}",
                    full_path.display(),
                    e
                ))
            })?;
            st.midi_state
                .set_soundfont(data, Some(path))
                .map_err(LuaError::RuntimeError)
        })?,
    )?;

    // luna.sound.hasMidiSoundFont()
    let state_clone = state.clone();
    sound_table.set(
        "hasMidiSoundFont",
        lua.create_function(move |_, ()| {
            let st = state_clone.borrow();
            Ok(st.midi_state.has_soundfont())
        })?,
    )?;

    // luna.sound.clearMidiSoundFont()
    let state_clone = state.clone();
    sound_table.set(
        "clearMidiSoundFont",
        lua.create_function(move |_, ()| {
            let mut st = state_clone.borrow_mut();
            st.midi_state.clear_soundfont();
            Ok(())
        })?,
    )?;

    luna.set("sound", sound_table)?;
    Ok(())
}
