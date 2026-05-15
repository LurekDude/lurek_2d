//! `lurek.audio` - Audio playback, mixing, spatial sound, MIDI, and DSP processing for 2D games.
use super::SharedState;
use crate::audio::sound_data::SoundData;
use crate::audio::{Decoder, MidiPlayer, SourceType};
use crate::log_msg;
use crate::runtime::log_messages::LA01_API_STUB;
use crate::runtime::resource_keys::{BusKey, QueueableKey, SoundKey};
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::rc::Rc;
fn sound_key_from_value(val: &LuaValue) -> LuaResult<SoundKey> {
    match val {
        LuaValue::UserData(ud) => {
            let src = ud.borrow::<LuaSource>()?;
            Ok(src.key)
        }
        LuaValue::Integer(id) => Ok(SoundKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(SoundKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError(
            "Expected Source or source id".into(),
        )),
    }
}
fn invalid_source_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released audio source handle",
        function_name
    ))
}
fn ensure_source_exists(
    mixer: &crate::audio::Mixer,
    key: SoundKey,
    function_name: &str,
) -> LuaResult<SoundKey> {
    if mixer.contains_source(key) {
        Ok(key)
    } else {
        Err(invalid_source_handle(function_name))
    }
}
fn require_sound_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<SoundKey> {
    let key = sound_key_from_value(val)?;
    ensure_source_exists(&state.mixer, key, function_name)
}
fn queueable_key_from_u64(raw: u64) -> QueueableKey {
    QueueableKey::from(slotmap::KeyData::from_ffi(raw))
}
fn extract_sound_data_args(args: LuaMultiValue) -> LuaResult<(Option<String>, usize, u32, u16)> {
    let mut it = args.into_iter();
    let first = it
        .next()
        .ok_or_else(|| LuaError::RuntimeError("newSoundData: expected argument".into()))?;
    let (path, count) = match first {
        LuaValue::String(s) => (
            Some(
                s.to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
            ),
            0usize,
        ),
        LuaValue::Integer(n) => (None, n as usize),
        LuaValue::Number(n) => (None, n as usize),
        _ => {
            return Err(LuaError::RuntimeError(
                "newSoundData expects a filename or sample count".into(),
            ))
        }
    };

        /// Registers the `lurek.audio` module, Lua-visible audio constructors, controls, and userdata wrappers.
    let rate = match it.next() {
        Some(LuaValue::Integer(n)) => n as u32,
        Some(LuaValue::Number(n)) => n as u32,
        _ => {
            return Err(LuaError::RuntimeError(
                "newSoundData: sample rate must be a number (e.g. 44100, 48000)".into(),
            ))
        }
    };
    let channels = match it.next() {
        Some(LuaValue::Integer(n)) => n as u16,
        Some(LuaValue::Number(n)) => n as u16,
        _ => 1,
    };
    Ok((path, count, rate, channels))
}
/// Lua-side wrapper around a loaded audio source (sound effect or music stream).
#[derive(Clone)]
pub struct LuaSource {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SoundKey,
}
impl LuaUserData for LuaSource {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- play --
        /// Starts playback of this audio source from the current position.
        /// @return | nil | No return value.
        methods.add_method("play", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:play")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play(key, &game_dir);
            Ok(())
        });
        // -- stop --
        /// Stops playback and resets the source position to the beginning.
        /// @return | nil | No return value.
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:stop")?;
            st.mixer.stop(key);
            Ok(())
        });
        // -- pause --
        /// Pauses playback at the current position, allowing later resumption.
        /// @return | nil | No return value.
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:pause")?;
            st.mixer.pause(key);
            Ok(())
        });
        // -- resume --
        /// Resumes playback from the position where the source was paused.
        /// @return | nil | No return value.
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:resume")?;
            st.mixer.resume(key);
            Ok(())
        });
        // -- setVolume --
        /// Sets the volume level of this source where 0.0 is silent and 1.0 is full volume.
        /// @param | vol | number | Volume multiplier (0.0 = silent, 1.0 = normal, >1.0 = amplified).
        /// @return | nil | No return value.
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        });
        // -- getVolume --
        /// Returns the current volume level of this audio source.
        /// @return | number | Current volume multiplier.
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getVolume")?;
            Ok(st.mixer.get_volume(key))
        });
        // -- setPitch --
        /// Sets the playback speed multiplier, affecting both pitch and duration.
        /// @param | pitch | number | Pitch multiplier (1.0 = normal, 2.0 = double speed/octave up).
        /// @return | nil | No return value.
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        });
        // -- getPitch --
        /// Returns the current pitch multiplier of this audio source.
        /// @return | number | Current pitch multiplier.
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPitch")?;
            Ok(st.mixer.get_pitch(key))
        });
        // -- setLooping --
        /// Enables or disables looping so the source restarts automatically after finishing.
        /// @param | looping | boolean | True to loop continuously, false to play once.
        /// @return | nil | No return value.
        methods.add_method("setLooping", |_, this, looping: bool| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        });
        // -- isLooping --
        /// Returns whether this source is set to loop continuously.
        /// @return | boolean | True if looping is enabled.
        methods.add_method("isLooping", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isLooping")?;
            Ok(st.mixer.is_looping(key))
        });
        // -- isPlaying --
        /// Returns whether this source is currently playing audio.
        /// @return | boolean | True if the source is actively playing.
        methods.add_method("isPlaying", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPlaying")?;
            Ok(st.mixer.is_playing(key))
        });
        // -- isPaused --
        /// Returns whether this source is currently paused.
        /// @return | boolean | True if the source is paused.
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPaused")?;
            Ok(st.mixer.is_paused(key))
        });
        // -- isStopped --
        /// Returns whether this source is currently stopped (not playing or paused).
        /// @return | boolean | True if the source is stopped.
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isStopped")?;
            Ok(st.mixer.is_stopped(key))
        });
        // -- setPan --
        /// Sets the stereo panning position of this source.
        /// @param | pan | number | Pan value from -1.0 (full left) to 1.0 (full right), 0.0 is center.
        /// @return | nil | No return value.
        methods.add_method("setPan", |_, this, pan: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        });
        // -- getPan --
        /// Returns the current stereo panning position of this source.
        /// @return | number | Pan value from -1.0 (left) to 1.0 (right).
        methods.add_method("getPan", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPan")?;
            Ok(st.mixer.get_pan(key))
        });
        // -- clone --
        /// Creates an independent copy of this source sharing the same audio data.
        /// @return | LSource | A new source instance with identical settings.
        methods.add_method("clone", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            match st.mixer.clone_source(this.key) {
                Some(new_key) => Ok(LuaSource {
                    state: this.state.clone(),
                    key: new_key,
                }),
                None => Err(invalid_source_handle("Source:clone")),
            }
        });
        // -- getType --
        /// Returns whether this source was loaded as static (fully in memory) or streaming.
        /// @return | string | Either "static" or "stream".
        methods.add_method("getType", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_source_type(this.key) {
                Some(SourceType::Static) => Ok("static"),
                Some(SourceType::Stream) => Ok("stream"),
                None => Err(invalid_source_handle("Source:getType")),
            }
        });
        // -- getDuration --
        /// Returns the total duration of this audio source in seconds.
        /// @return | number | Duration in seconds.
        methods.add_method("getDuration", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getDuration")?;
            Ok(st.mixer.get_duration(key))
        });
        // -- tell --
        /// Returns the current playback position of this source in seconds.
        /// @return | number | Current position in seconds from the start.
        methods.add_method("tell", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:tell")?;
            Ok(st.mixer.get_tell(key))
        });
        // -- seek --
        /// Seeks to a specific position in seconds within this audio source.
        /// @param | pos | number | Target position in seconds.
        /// @return | nil | No return value.
        methods.add_method("seek", |_, this, pos: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        });
        // -- setLowpass --
        /// Applies a lowpass filter that attenuates frequencies above the cutoff.
        /// @param | cutoff_hz | integer | Cutoff frequency in Hertz.
        /// @return | nil | No return value.
        methods.add_method("setLowpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        });
        // -- setHighpass --
        /// Applies a highpass filter that attenuates frequencies below the cutoff.
        /// @param | cutoff_hz | integer | Cutoff frequency in Hertz.
        /// @return | nil | No return value.
        methods.add_method("setHighpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        });
        // -- getLowpass --
        /// Returns the current lowpass filter cutoff frequency in Hertz.
        /// @return | integer | Cutoff frequency in Hz, or 0 if no lowpass is set.
        methods.add_method("getLowpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        });
        // -- getHighpass --
        /// Returns the current highpass filter cutoff frequency in Hertz.
        /// @return | integer | Cutoff frequency in Hz, or 0 if no highpass is set.
        methods.add_method("getHighpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        });
        // -- clearFilter --
        /// Removes all frequency filters (lowpass and highpass) from this source.
        /// @return | nil | No return value.
        methods.add_method("clearFilter", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        });
        // -- fadeIn --
        /// Sets the fade-in duration so the source ramps from silence to full volume on play.
        /// @param | dur | number | Fade-in duration in seconds.
        /// @return | nil | No return value.
        methods.add_method("fadeIn", |_, this, dur: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:fadeIn")?;
            st.mixer.set_fade_in(key, dur);
            Ok(())
        });
        // -- getFadeIn --
        /// Returns the configured fade-in duration for this source.
        /// @return | number | Fade-in duration in seconds.
        methods.add_method("getFadeIn", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        });
        // -- type --
        /// Returns the type name of this object for runtime type-checking.
        /// @return | string | Always returns "LSource".
        methods.add_method("type", |_, _, ()| Ok("LSource"));
        // -- typeOf --
        /// Checks whether this object is of the given type name or a parent type.
        /// @param | name | string | Type name to check (e.g. "LSource" or "Object").
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSource" || name == "Object")
        });
    }
}
/// Lua-side wrapper around an audio mixing bus for grouped volume and effect control.
#[derive(Clone)]
pub struct LuaBus {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: BusKey,
}
impl LuaUserData for LuaBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the name of this audio bus. This method is available to Lua scripts.
        /// @return | string | Bus name as registered during creation.
        methods.add_method("getName", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_bus(this.key) {
                Some(bus) => Ok(bus.name().to_string()),
                None => Err(LuaError::RuntimeError(
                    "Bus:getName(): invalid bus handle".into(),
                )),
            }
        });
        // -- setVolume --
        /// Sets the volume multiplier for all sources routed through this bus.
        /// @param | vol | number | Volume multiplier (0.0 = silent, 1.0 = normal).
        /// @return | nil | No return value.
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_volume(vol);
            }
            Ok(())
        });
        // -- getVolume --
        /// Returns the current volume multiplier of this bus.
        /// @return | number | Volume multiplier (defaults to 1.0).
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.volume()))
        });
        // -- setPitch --
        /// Sets the pitch multiplier applied to all sources routed through this bus.
        /// @param | pitch | number | Pitch multiplier (1.0 = normal speed).
        /// @return | nil | No return value.
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_pitch(pitch);
            }
            Ok(())
        });
        // -- getPitch --
        /// Returns the current pitch multiplier of this bus.
        /// @return | number | Current pitch multiplier (defaults to 1.0).
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.pitch()))
        });
        // -- pause --
        /// Pauses all sources routed through this bus.
        /// @return | nil | No return value.
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.pause();
            }
            Ok(())
        });
        // -- resume --
        /// Resumes all sources routed through this bus that were paused.
        /// @return | nil | No return value.
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.resume();
            }
            Ok(())
        });
        // -- isPaused --
        /// Returns whether this bus is currently paused.
        /// @return | boolean | True if the bus is paused.
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).is_some_and(|b| b.is_paused()))
        });
        // -- type --
        /// Returns the type name of this object for runtime type-checking.
        /// @return | string | Always returns "LBus".
        methods.add_method("type", |_, _, ()| Ok("LBus"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check (e.g. "LBus", "Bus", or "Object").
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBus" || name == "Bus" || name == "Object")
        });
        // -- setDuckTarget --
        /// Configures ducking so this bus lowers the volume of a target bus when active.
        /// @param | target_name | string | Name of the bus to duck.
        /// @param | duck_vol | number | Volume multiplier applied to the target when ducking (0.0-1.0).
        /// @return | nil | No return value.
        methods.add_method(
            "setDuckTarget",
            |_, this, (target_name, duck_vol): (String, f32)| {
                let mut st = this.state.borrow_mut();
                if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                    bus.set_duck_target(&target_name, duck_vol);
                }
                Ok(())
            },
        );
        // -- clearDuck --
        /// Removes the ducking configuration from this bus.
        /// @return | nil | No return value.
        methods.add_method("clearDuck", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.clear_duck_target();
            }
            Ok(())
        });
        // -- getPeak --
        /// Returns the current peak amplitude level of this bus for VU-meter displays.
        /// @return | number | Peak level from 0.0 to 1.0.
        methods.add_method("getPeak", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.bus_peak(this.key))
        });
    }
}
/// Lua-side wrapper around a MIDI file player with per-channel control and tempo scaling.
#[derive(Clone)]
pub struct LuaMidiPlayer {
    pub(crate) inner: Rc<RefCell<MidiPlayer>>,
    pub(crate) state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaMidiPlayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- load --
        /// Loads a MIDI file from the given path relative to the game directory.
        /// @param | path | string | Relative path to the .mid file.
        /// @return | boolean | True if the file was loaded successfully.
        methods.add_method("load", |_, this, path: String| {
            let st = this.state.borrow();
            let full_path = st.game_dir.join(&path);
            Ok(this.inner.borrow_mut().load(&full_path))
        });
        // -- loadData --
        /// Loads MIDI data from a raw byte string in memory.
        /// @param | data | string | Raw MIDI binary data.
        /// @return | boolean | True if the data was parsed successfully.
        methods.add_method("loadData", |_, this, data: mlua::String| {
            let bytes = data.as_bytes().to_vec();
            Ok(this.inner.borrow_mut().load_data(bytes))
        });
        // -- isLoaded --
        /// Returns whether a MIDI file is currently loaded and ready to play.
        /// @return | boolean | True if a MIDI file is loaded.
        methods.add_method("isLoaded", |_, this, ()| {
            Ok(this.inner.borrow().is_loaded())
        });
        // -- getFilePath --
        /// Returns the file path of the currently loaded MIDI file.
        /// @return | string | File path string or nil if no file is loaded.
        methods.add_method("getFilePath", |_, this, ()| {
            Ok(this.inner.borrow().file_path().map(|s| s.to_string()))
        });
        // -- setSoundFont --
        /// Sets a custom SoundFont file for MIDI synthesis (stub, not yet implemented).
        /// @param | path | string | Relative path to the .sf2 file.
        /// @return | nil | No return value.
        methods.add_method("setSoundFont", |_, _this, _path: String| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setSoundFont");
            Ok(())
        });
        // -- getSoundFontPath --
        /// Returns the path of the currently set SoundFont (stub, not yet implemented).
        /// @return | string | SoundFont path or nil.
        methods.add_method("getSoundFontPath", |_, _this, ()| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:getSoundFontPath");
            Ok(Option::<String>::None)
        });
        // -- useDefaultSoundFont --
        /// Reverts to the built-in default SoundFont (stub, not yet implemented).
        /// @return | nil | No return value.
        methods.add_method("useDefaultSoundFont", |_, _this, ()| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:useDefaultSoundFont");
            Ok(())
        });
        // -- play --
        /// Starts MIDI playback from the current position using the audio output stream.
        /// @return | nil | No return value.
        methods.add_method("play", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(handle) = st.mixer.stream_handle() {
                this.inner.borrow_mut().play(handle);
            }
            Ok(())
        });
        // -- pause --
        /// Pauses MIDI playback at the current position.
        /// @return | nil | No return value.
        methods.add_method("pause", |_, this, ()| {
            this.inner.borrow_mut().pause();
            Ok(())
        });
        // -- stop --
        /// Stops MIDI playback and resets position to the beginning.
        /// @return | nil | No return value.
        methods.add_method("stop", |_, this, ()| {
            this.inner.borrow_mut().stop();
            Ok(())
        });
        // -- isPlaying --
        /// Returns whether the MIDI player is currently playing.
        /// @return | boolean | True if playing.
        methods.add_method("isPlaying", |_, this, ()| {
            Ok(this.inner.borrow().is_playing())
        });
        // -- isPaused --
        /// Returns whether the MIDI player is currently paused.
        /// @return | boolean | True if paused.
        methods.add_method("isPaused", |_, this, ()| {
            Ok(this.inner.borrow().is_paused())
        });
        // -- seek --
        /// Seeks to a specific position in the MIDI file.
        /// @param | secs | number | Target position in seconds.
        /// @return | nil | No return value.
        methods.add_method("seek", |_, this, secs: f64| {
            this.inner.borrow_mut().seek(secs);
            Ok(())
        });
        // -- tell --
        /// Returns the current playback position of the MIDI player in seconds.
        /// @return | number | Current position in seconds.
        methods.add_method("tell", |_, this, ()| Ok(this.inner.borrow().tell()));
        // -- getDuration --
        /// Returns the total duration of the loaded MIDI file in seconds.
        /// @return | number | Duration in seconds.
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration())
        });
        // -- setLooping --
        /// Enables or disables looping for MIDI playback.
        /// @param | looping | boolean | True to loop, false to play once.
        /// @return | nil | No return value.
        methods.add_method("setLooping", |_, this, looping: bool| {
            this.inner.borrow_mut().set_looping(looping);
            Ok(())
        });
        // -- isLooping --
        /// Returns whether MIDI looping is enabled.
        /// @return | boolean | True if looping.
        methods.add_method("isLooping", |_, this, ()| {
            Ok(this.inner.borrow().is_looping())
        });
        // -- setVolume --
        /// Sets the master volume for MIDI playback.
        /// @param | vol | number | Volume multiplier (0.0 = silent, 1.0 = normal).
        /// @return | nil | No return value.
        methods.add_method("setVolume", |_, this, vol: f32| {
            this.inner.borrow_mut().set_volume(vol);
            Ok(())
        });
        // -- getVolume --
        /// Returns the current master volume of the MIDI player.
        /// @return | number | Volume multiplier.
        methods.add_method("getVolume", |_, this, ()| Ok(this.inner.borrow().volume()));
        // -- setBus --
        /// Routes this MIDI player's output through the specified audio bus.
        /// @param | bus | LBus? | Bus to route through, or nil for direct output.
        /// @return | nil | No return value.
        methods.add_method("setBus", |_, this, bus_val: LuaValue| match &bus_val {
            LuaValue::UserData(ud) => {
                let bus = ud.borrow::<LuaBus>()?;
                this.inner.borrow_mut().set_bus_key(Some(bus.key));
                Ok(())
            }
            LuaValue::Nil => {
                this.inner.borrow_mut().set_bus_key(None);
                Ok(())
            }
            _ => Err(LuaError::RuntimeError(
                "MidiPlayer:setBus(): expected Bus or nil".into(),
            )),
        });
        // -- getBus --
        /// Returns the audio bus this MIDI player is routed through.
        /// @return | LBus | The assigned bus, or nil if using direct output.
        methods.add_method("getBus", |_, this, ()| {
            match this.inner.borrow().bus_key() {
                Some(key) => Ok(Some(LuaBus {
                    state: this.state.clone(),
                    key,
                })),
                None => Ok(None),
            }
        });
        // -- setTempo --
        /// Sets the playback tempo in beats per minute.
        /// @param | bpm | number | Desired tempo in BPM.
        /// @return | nil | No return value.
        methods.add_method("setTempo", |_, this, bpm: f64| {
            let original = this.inner.borrow().original_tempo();
            if original > 0.0 {
                this.inner
                    .borrow_mut()
                    .set_tempo_scale((bpm / original) as f32);
            }
            Ok(())
        });
        // -- getTempo --
        /// Returns the current effective tempo in beats per minute.
        /// @return | number | Current tempo in BPM.
        methods.add_method("getTempo", |_, this, ()| {
            let mp = this.inner.borrow();
            Ok(mp.original_tempo() * mp.tempo_scale() as f64)
        });
        // -- getOriginalTempo --
        /// Returns the original tempo of the MIDI file as authored.
        /// @return | number | Original tempo in BPM.
        methods.add_method("getOriginalTempo", |_, this, ()| {
            Ok(this.inner.borrow().original_tempo())
        });
        // -- setTempoScale --
        /// Sets a tempo multiplier relative to the original speed.
        /// @param | scale | number | Tempo scale (1.0 = original, 2.0 = double speed).
        /// @return | nil | No return value.
        methods.add_method("setTempoScale", |_, this, scale: f32| {
            this.inner.borrow_mut().set_tempo_scale(scale);
            Ok(())
        });
        // -- getTempoScale --
        /// Returns the current tempo scale multiplier.
        /// @return | number | Tempo scale factor.
        methods.add_method("getTempoScale", |_, this, ()| {
            Ok(this.inner.borrow().tempo_scale())
        });
        // -- getTicksPerBeat --
        /// Returns the MIDI file's resolution in ticks per beat (PPQN).
        /// @return | integer | Ticks per quarter note.
        methods.add_method("getTicksPerBeat", |_, this, ()| {
            Ok(this.inner.borrow().ticks_per_beat())
        });
        // -- setChannelVolume --
        /// Sets the volume for a specific MIDI channel (1-16).
        /// @param | ch | integer | Channel number (1-16).
        /// @param | vol | number | Volume multiplier (0.0-1.0).
        /// @return | nil | No return value.
        methods.add_method("setChannelVolume", |_, this, (ch, vol): (usize, f32)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_volume(ch - 1, vol);
            }
            Ok(())
        });
        // -- getChannelVolume --
        /// Returns the volume of a specific MIDI channel.
        /// @param | ch | integer | Channel number (1-16).
        /// @return | number | Channel volume (0.0-1.0).
        methods.add_method("getChannelVolume", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_volume(ch - 1))
            } else {
                Ok(0.0)
            }
        });
        // -- setChannelMuted --
        /// Mutes or unmutes a specific MIDI channel.
        /// @param | ch | integer | Channel number (1-16).
        /// @param | muted | boolean | True to mute, false to unmute.
        /// @return | nil | No return value.
        methods.add_method("setChannelMuted", |_, this, (ch, muted): (usize, bool)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_muted(ch - 1, muted);
            }
            Ok(())
        });
        // -- isChannelMuted --
        /// Returns whether a specific MIDI channel is muted.
        /// @param | ch | integer | Channel number (1-16).
        /// @return | boolean | True if the channel is muted.
        methods.add_method("isChannelMuted", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().is_channel_muted(ch - 1))
            } else {
                Ok(false)
            }
        });
        // -- setChannelInstrument --
        /// Sets the General MIDI instrument program for a channel.
        /// @param | ch | integer | Channel number (1-16).
        /// @param | inst | integer | GM instrument program number (0-127).
        /// @return | nil | No return value.
        methods.add_method(
            "setChannelInstrument",
            |_, this, (ch, inst): (usize, u8)| {
                if (1..=16).contains(&ch) {
                    this.inner.borrow_mut().set_channel_instrument(ch - 1, inst);
                }
                Ok(())
            },
        );
        // -- getChannelInstrument --
        /// Returns the current GM instrument program for a channel.
        /// @param | ch | integer | Channel number (1-16).
        /// @return | integer | GM instrument program number (0-127).
        methods.add_method("getChannelInstrument", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_instrument(ch - 1))
            } else {
                Ok(0u8)
            }
        });
        // -- getChannelCount --
        /// Returns the number of active MIDI channels in the loaded file.
        /// @return | integer | Number of active channels.
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.borrow().channel_count())
        });
        // -- soloChannel --
        /// Solos a specific MIDI channel, muting all others.
        /// @param | ch | integer | Channel number (1-16) to solo.
        /// @return | nil | No return value.
        methods.add_method("soloChannel", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().solo_channel(ch - 1);
            }
            Ok(())
        });
        // -- unsoloAll --
        /// Removes solo from all channels, restoring normal playback.
        /// @return | nil | No return value.
        methods.add_method("unsoloAll", |_, this, ()| {
            this.inner.borrow_mut().unsolo_all();
            Ok(())
        });
        // -- getTrackCount --
        /// Returns the number of tracks in the loaded MIDI file.
        /// @return | integer | Number of MIDI tracks.
        methods.add_method("getTrackCount", |_, this, ()| {
            Ok(this.inner.borrow().track_count())
        });
        // -- getTrackName --
        /// Returns the name of a MIDI track by 1-based index.
        /// @param | idx | integer | Track index (1-based).
        /// @return | string | Track name or nil if not available.
        methods.add_method("getTrackName", |_, this, idx: usize| {
            if idx >= 1 {
                Ok(this
                    .inner
                    .borrow()
                    .track_name(idx - 1)
                    .map(|s| s.to_string()))
            } else {
                Ok(None)
            }
        });
        // -- setTrackMuted --
        /// Mutes or unmutes a specific MIDI track.
        /// @param | idx | integer | Track index (1-based).
        /// @param | muted | boolean | True to mute, false to unmute.
        /// @return | nil | No return value.
        methods.add_method("setTrackMuted", |_, this, (idx, muted): (usize, bool)| {
            if idx >= 1 {
                this.inner.borrow_mut().set_track_muted(idx - 1, muted);
            }
            Ok(())
        });
        // -- isTrackMuted --
        /// Returns whether a specific MIDI track is muted.
        /// @param | idx | integer | Track index (1-based).
        /// @return | boolean | True if the track is muted.
        methods.add_method("isTrackMuted", |_, this, idx: usize| {
            if idx >= 1 {
                Ok(this.inner.borrow().is_track_muted(idx - 1))
            } else {
                Ok(false)
            }
        });
        // -- getNoteCount --
        /// Returns the total number of note events in the loaded MIDI file.
        /// @return | integer | Total note count.
        methods.add_method("getNoteCount", |_, this, ()| {
            Ok(this.inner.borrow().note_count())
        });
        // -- setOnNoteOn --
        /// Registers a callback for MIDI note-on events (stub, not yet implemented).
        /// @param | cb | function? | Callback function or nil to clear.
        /// @return | nil | No return value.
        methods.add_method("setOnNoteOn", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnNoteOn");
            Ok(())
        });
        // -- setOnNoteOff --
        /// Registers a callback for MIDI note-off events (stub, not yet implemented).
        /// @param | cb | function? | Callback function or nil to clear.
        /// @return | nil | No return value.
        methods.add_method("setOnNoteOff", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnNoteOff");
            Ok(())
        });
        // -- setOnEnd --
        /// Registers a callback invoked when MIDI playback finishes (stub, not yet implemented).
        /// @param | cb | function? | Callback function or nil to clear.
        /// @return | nil | No return value.
        methods.add_method("setOnEnd", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnEnd");
            Ok(())
        });
        // -- getSampleRate --
        /// Returns the output sample rate used for MIDI synthesis.
        /// @return | integer | Sample rate in Hz (e.g. 44100).
        methods.add_method("getSampleRate", |_, this, ()| {
            Ok(this.inner.borrow().get_output_sample_rate())
        });
        // -- setSampleRate --
        /// Sets the output sample rate for MIDI synthesis.
        /// @param | rate | integer | Sample rate in Hz (e.g. 44100, 48000).
        /// @return | nil | No return value.
        methods.add_method_mut("setSampleRate", |_, this, rate: u32| {
            this.inner.borrow_mut().set_output_sample_rate(rate);
            Ok(())
        });
        // -- getChannels --
        /// Returns the number of output audio channels for MIDI synthesis.
        /// @return | integer | Channel count (1 = mono, 2 = stereo).
        methods.add_method("getChannels", |_, this, ()| {
            Ok(this.inner.borrow().get_output_channels() as u32)
        });
        // -- setChannels --
        /// Sets the number of output audio channels for MIDI synthesis.
        /// @param | channels | integer | Channel count (1 = mono, 2 = stereo).
        /// @return | nil | No return value.
        methods.add_method_mut("setChannels", |_, this, channels: u32| {
            this.inner.borrow_mut().set_output_channels(channels as u16);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object for runtime type-checking.
        /// @return | string | Always returns "LMidiPlayer".
        methods.add_method("type", |_, _, ()| Ok("LMidiPlayer"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check (e.g. "LMidiPlayer", "MidiPlayer", or "Object").
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMidiPlayer" || name == "MidiPlayer" || name == "Object")
        });
    }
}
/// Lua-side wrapper around a pre-allocated pool of identical sound voices for rapid fire effects.
pub(crate) struct LuaSoundPool {
    pub(crate) pool: crate::audio::pool::SoundPool,
    pub(crate) state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaSoundPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- play --
        /// Plays the next available voice from the pool in round-robin order.
        /// @return | integer | Numeric source ID of the voice that started playing.
        methods.add_method_mut("play", |_, this, ()| {
            let key = this.pool.next_voice();
            let game_dir = this.state.borrow().game_dir.clone();
            this.state.borrow_mut().mixer.play(key, &game_dir);
            Ok(slotmap::Key::data(&key).as_ffi() as i64)
        });
        // -- stopAll --
        /// Stops all voices in this sound pool immediately.
        /// @return | nil | No return value.
        methods.add_method_mut("stopAll", |_, this, ()| {
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.stop(key);
            }
            Ok(())
        });
        // -- setVolume --
        /// Sets the volume for all voices in this pool.
        /// @param | vol | number | Volume multiplier (0.0 = silent, 1.0 = normal).
        /// @return | nil | No return value.
        methods.add_method_mut("setVolume", |_, this, vol: f32| {
            this.pool.set_volume(vol);
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.set_volume(key, vol);
            }
            Ok(())
        });
        // -- setBus --
        /// Routes all voices in this pool through the named audio bus.
        /// @param | name | string | Name of the target bus.
        /// @return | nil | No return value.
        methods.add_method_mut("setBus", |_, this, name: String| {
            this.pool.set_bus(&name);
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let bus_key = this.state.borrow().mixer.get_bus_by_name(&name);
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.set_source_bus(key, bus_key);
            }
            Ok(())
        });
        // -- release --
        /// Releases all voices and frees audio resources held by this pool.
        /// @return | nil | No return value.
        methods.add_method_mut("release", |_, this, ()| {
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.release(key);
            }
            Ok(())
        });
        // -- getVoiceCount --
        /// Returns the number of pre-allocated voices in this pool.
        /// @return | integer | Voice count.
        methods.add_method("getVoiceCount", |_, this, ()| Ok(this.pool.voice_count()));
        // -- type --
        /// Returns the type name of this object for runtime type-checking.
        /// @return | string | Always returns "LSoundPool".
        methods.add_method("type", |_, _this, ()| Ok("LSoundPool"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check (e.g. "SoundPool" or "Object").
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SoundPool" || name == "Object")
        });
    }
}
/// Lua-side wrapper around a streaming audio decoder for incremental PCM extraction.
pub struct LuaDecoder {
    inner: Decoder,
}
impl LuaUserData for LuaDecoder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- decode --
        /// Decodes the next chunk of audio data and returns it as a SoundData object.
        /// @return | SoundData | Decoded PCM data, or nil if end of stream reached.
        methods.add_method_mut("decode", |lua, this, ()| match this.inner.decode() {
            Some(pcm_i16) => {
                let samples: Vec<f32> = pcm_i16.iter().map(|&s| s as f32 / 32768.0).collect();
                let sd =
                    SoundData::from_samples(samples, this.inner.sample_rate, this.inner.channels);
                Ok(LuaValue::UserData(lua.create_userdata(sd)?))
            }
            None => Ok(LuaValue::Nil),
        });
        // -- getChannelCount --
        /// Returns the number of audio channels in the source file.
        /// @return | integer | Channel count (1 = mono, 2 = stereo).
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.channels as u32)
        });
        // -- getBitDepth --
        /// Returns the bit depth of the source audio file.
        /// @return | integer | Bits per sample (e.g. 16, 24).
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.inner.bit_depth as u32));
        // -- getSampleRate --
        /// Returns the sample rate of the source audio file.
        /// @return | integer | Sample rate in Hz.
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.inner.sample_rate));
        // -- getDuration --
        /// Returns the total duration of the source audio file in seconds.
        /// @return | number | Duration in seconds.
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.get_duration()));
        // -- seek --
        /// Seeks to a specific position in the audio stream.
        /// @param | offset | number | Target position in seconds.
        /// @return | nil | No return value.
        methods.add_method_mut("seek", |_, this, offset: f64| {
            this.inner.seek(offset);
            Ok(())
        });
        // -- rewind --
        /// Rewinds the decoder back to the beginning of the audio stream.
        /// @return | nil | No return value.
        methods.add_method_mut("rewind", |_, this, ()| {
            this.inner.rewind();
            Ok(())
        });
        // -- tell --
        /// Returns the current read position in the audio stream in seconds.
        /// @return | number | Current position in seconds.
        methods.add_method("tell", |_, this, ()| Ok(this.inner.tell()));
        // -- isSeekable --
        /// Returns whether this decoder supports seeking.
        /// @return | boolean | True if seek operations are supported.
        methods.add_method("isSeekable", |_, this, ()| Ok(this.inner.is_seekable()));
        // -- release --
        /// Releases decoder resources (no-op, kept for API symmetry).
        /// @return | nil | No return value.
        methods.add_method("release", |_, _, ()| Ok(()));
        // -- type --
        /// Returns the type name of this object for runtime type-checking.
        /// @return | string | Always returns "LDecoder".
        methods.add_method("type", |_, _, ()| Ok("LDecoder"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check (e.g. "LDecoder" or "Object").
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDecoder" || name == "Object")
        });
    }
}
/// Registers the `lurek.audio` Lua API table and userdata bindings.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newSource --
    /// Creates a new audio source from a file path, either fully loaded or streaming.
    /// @param | path | string | Relative path to the audio file (WAV, OGG, MP3, FLAC).
    /// @param | sourceType | string? | "static" to load fully into memory, or "stream" (default) for streaming.
    /// @return | LSource | A new audio source ready for playback.
    let s = state.clone();
    tbl.set(
        "newSource",
        lua.create_function(move |_, args: LuaMultiValue| {
            let path: String = args
                .get(0)
                .and_then(|v| match v {
                    LuaValue::String(ls) => Some(ls.to_str().ok()?.to_string()),
                    _ => None,
                })
                .ok_or_else(|| {
                    LuaError::RuntimeError("lurek.audio.newSource: path required".into())
                })?;
            let source_type = args
                .get(1)
                .and_then(|v| match v {
                    LuaValue::String(ls) => Some(ls.to_str().ok()?.to_string()),
                    _ => None,
                })
                .map(|t| match t.as_str() {
                    "static" => SourceType::Static,
                    _ => SourceType::Stream,
                })
                .unwrap_or(SourceType::Stream);
            let mut st = s.borrow_mut();
            let key = st.mixer.load_source(&path, source_type);
            Ok(LuaSource {
                state: s.clone(),
                key,
            })
        })?,
    )?;
    // -- play --
    /// Starts playback of a source by handle, optionally routing through a named bus.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | options | table? | Optional table with "bus" field for bus routing.
    /// @return | integer | Numeric source ID of the playing source.
    let s = state.clone();
    tbl.set(
        "play",
        lua.create_function(
            move |_, (id_val, options): (LuaValue, Option<mlua::Table>)| {
                let mut st = s.borrow_mut();
                let key = require_sound_key(&st, &id_val, "lurek.audio.play")?;
                if let Some(opts) = options {
                    if let Ok(bus_name) = opts.get::<_, String>("bus") {
                        if let Some(bus) = st.mixer.get_bus_by_name(&bus_name) {
                            st.mixer.set_source_bus(key, Some(bus));
                        } else {
                            return Err(LuaError::external("bus not found"));
                        }
                    }
                }
                let game_dir = st.game_dir.clone();
                st.mixer.play(key, &game_dir);
                Ok(key.data().as_ffi())
            },
        )?,
    )?;
    // -- stop --
    /// Stops playback of a source and resets its position to the beginning.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "stop",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.stop")?;
            st.mixer.stop(key);
            Ok(())
        })?,
    )?;
    // -- setVolume --
    /// Sets the volume of a source by handle.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | vol | number | Volume multiplier (0.0 = silent, 1.0 = normal).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setVolume",
        lua.create_function(move |_, (id_val, vol): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        })?,
    )?;
    // -- getVolume --
    /// Returns the current volume of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number | Current volume multiplier.
    let s = state.clone();
    tbl.set(
        "getVolume",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getVolume")?;
            Ok(st.mixer.get_volume(key))
        })?,
    )?;
    // -- pause --
    /// Pauses playback of a source at its current position.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "pause",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.pause")?;
            st.mixer.pause(key);
            Ok(())
        })?,
    )?;
    // -- resume --
    /// Resumes playback of a paused source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "resume",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.resume")?;
            st.mixer.resume(key);
            Ok(())
        })?,
    )?;
    // -- setPitch --
    /// Sets the pitch multiplier of a source, affecting playback speed and tone.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | pitch | number | Pitch multiplier (1.0 = normal, 2.0 = octave up).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setPitch",
        lua.create_function(move |_, (id_val, pitch): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        })?,
    )?;
    // -- getPitch --
    /// Returns the current pitch multiplier of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number | Current pitch multiplier.
    let s = state.clone();
    tbl.set(
        "getPitch",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getPitch")?;
            Ok(st.mixer.get_pitch(key))
        })?,
    )?;
    // -- isPlaying --
    /// Returns whether a source is currently playing.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | boolean | True if the source is playing.
    let s = state.clone();
    tbl.set(
        "isPlaying",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isPlaying")?;
            Ok(st.mixer.is_playing(key))
        })?,
    )?;
    // -- isPaused --
    /// Returns whether a source is currently paused.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | boolean | True if the source is paused.
    let s = state.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isPaused")?;
            Ok(st.mixer.is_paused(key))
        })?,
    )?;
    // -- isStopped --
    /// Returns whether a source is currently stopped.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | boolean | True if the source is stopped.
    let s = state.clone();
    tbl.set(
        "isStopped",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isStopped")?;
            Ok(st.mixer.is_stopped(key))
        })?,
    )?;
    // -- setLooping --
    /// Enables or disables looping for a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | looping | boolean | True to loop, false to play once.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setLooping",
        lua.create_function(move |_, (id_val, looping): (LuaValue, bool)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        })?,
    )?;
    // -- isLooping --
    /// Returns whether a source has looping enabled.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | boolean | True if looping is enabled.
    let s = state.clone();
    tbl.set(
        "isLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isLooping")?;
            Ok(st.mixer.is_looping(key))
        })?,
    )?;
    // -- playLooping --
    /// Starts playback of a source with looping enabled in one call.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "playLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.playLooping")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play_looping(key, &game_dir);
            Ok(())
        })?,
    )?;
    // -- setPan --
    /// Sets the stereo panning of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | pan | number | Pan from -1.0 (left) to 1.0 (right), 0.0 is center.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setPan",
        lua.create_function(move |_, (id_val, pan): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        })?,
    )?;
    // -- getPan --
    /// Returns the current stereo pan position of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number | Pan value from -1.0 (left) to 1.0 (right).
    let s = state.clone();
    tbl.set(
        "getPan",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getPan")?;
            Ok(st.mixer.get_pan(key))
        })?,
    )?;
    // -- setMasterVolume --
    /// Sets the global master volume affecting all audio output.
    /// @param | vol | number | Master volume multiplier (0.0 = silent, 1.0 = normal).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setMasterVolume",
        lua.create_function(move |_, vol: f32| {
            s.borrow_mut().mixer.set_master_volume(vol);
            Ok(())
        })?,
    )?;
    // -- getMasterVolume --
    /// Returns the current global master volume level.
    /// @return | number | Master volume multiplier.
    let s = state.clone();
    tbl.set(
        "getMasterVolume",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_master_volume()))?,
    )?;
    // -- getActiveSourceCount --
    /// Returns the number of sources currently playing audio.
    /// @return | integer | Count of active (playing) sources.
    let s = state.clone();
    tbl.set(
        "getActiveSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_active_source_count()))?,
    )?;
    // -- getSourceCount --
    /// Returns the total number of loaded audio sources (playing or idle).
    /// @return | integer | Total source count.
    let s = state.clone();
    tbl.set(
        "getSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_source_count()))?,
    )?;
    // -- getSourceType --
    /// Returns whether a source is static or streaming.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | string | Either "static" or "stream".
    let s = state.clone();
    tbl.set(
        "getSourceType",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let st = s.borrow();
            match st.mixer.get_source_type(key) {
                Some(SourceType::Static) => Ok("static".to_string()),
                Some(SourceType::Stream) => Ok("stream".to_string()),
                None => Err(LuaError::RuntimeError(
                    "lurek.audio.getSourceType: invalid source handle".into(),
                )),
            }
        })?,
    )?;
    // -- clone --
    /// Creates an independent copy of a source sharing the same audio data.
    /// @param | source | LSource|integer | Audio source or numeric source ID to clone.
    /// @return | LSource | A new source instance with identical settings.
    let s = state.clone();
    tbl.set(
        "clone",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            match st.mixer.clone_source(key) {
                Some(new_key) => Ok(LuaSource {
                    state: s.clone(),
                    key: new_key,
                }),
                None => Err(LuaError::RuntimeError(
                    "lurek.audio.clone: invalid source handle".into(),
                )),
            }
        })?,
    )?;
    // -- pauseAll --
    /// Pauses all currently playing audio sources.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "pauseAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.pause_all();
            Ok(())
        })?,
    )?;
    // -- stopAll --
    /// Stops all audio sources and resets their positions.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "stopAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.stop_all();
            Ok(())
        })?,
    )?;
    // -- resumeAll --
    /// Resumes all paused audio sources. This function is exposed to Lua scripts.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "resumeAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.resume_all();
            Ok(())
        })?,
    )?;
    // -- release --
    /// Releases an audio source, freeing its memory and stopping playback.
    /// @param | source | LSource|integer | Audio source or numeric source ID to release.
    /// @return | boolean | True if the source was successfully released.
    let s = state.clone();
    tbl.set(
        "release",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            if st.mixer.release(key) {
                Ok(true)
            } else {
                Err(LuaError::RuntimeError(
                    "lurek.audio.release: invalid or already-released audio source handle".into(),
                ))
            }
        })?,
    )?;
    // -- newBus --
    /// Creates a new audio mixing bus for grouping and controlling sources.
    /// @param | name | string | Unique name for the bus (e.g. "music", "sfx").
    /// @return | LBus | The new audio bus handle.
    let s = state.clone();
    tbl.set(
        "newBus",
        lua.create_function(move |_, name: String| {
            let mut st = s.borrow_mut();
            let key = st.mixer.new_bus(&name);
            Ok(LuaBus {
                state: s.clone(),
                key,
            })
        })?,
    )?;
    // -- setSourceBus --
    /// Routes a source through a specific audio bus for grouped mixing.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | bus | LBus | The bus to route through.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setSourceBus",
        lua.create_function(move |_, (id_val, bus_val): (LuaValue, LuaValue)| {
            let key = sound_key_from_value(&id_val)?;
            let bus_key = match &bus_val {
                LuaValue::UserData(ud) => {
                    let bus = ud.borrow::<LuaBus>()?;
                    Some(bus.key)
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "lurek.audio.setSourceBus: expected Bus userdata".into(),
                    ));
                }
            };
            s.borrow_mut().mixer.set_source_bus(key, bus_key);
            Ok(())
        })?,
    )?;
    // -- getSourceBus --
    /// Returns the bus a source is routed through.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | LBus | The assigned bus, or nil if using direct output.
    let s = state.clone();
    tbl.set(
        "getSourceBus",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let st = s.borrow();
            match st.mixer.get_source_bus(key) {
                Some(bus_key) => Ok(Some(LuaBus {
                    state: s.clone(),
                    key: bus_key,
                })),
                None => Ok(None),
            }
        })?,
    )?;
    // -- getMaxSources --
    /// Returns the maximum number of simultaneous audio sources supported.
    /// @return | integer | Maximum source count (64).
    tbl.set("getMaxSources", lua.create_function(|_, ()| Ok(64))?)?;
    // -- getDuration --
    /// Returns the total duration of a source in seconds.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number | Duration in seconds.
    let s = state.clone();
    tbl.set(
        "getDuration",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getDuration")?;
            Ok(st.mixer.get_duration(key))
        })?,
    )?;
    // -- tell --
    /// Returns the current playback position of a source in seconds.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number | Current position in seconds.
    let s = state.clone();
    tbl.set(
        "tell",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.tell")?;
            Ok(st.mixer.get_tell(key))
        })?,
    )?;
    // -- seek --
    /// Seeks a source to a specific position in seconds.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | pos | number | Target position in seconds.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "seek",
        lua.create_function(move |_, (id_val, pos): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        })?,
    )?;
    // -- setLowpass --
    /// Applies a lowpass filter to a source, attenuating high frequencies.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | cutoff_hz | integer | Cutoff frequency in Hertz.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setLowpass",
        lua.create_function(move |_, (id_val, cutoff_hz): (LuaValue, u32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        })?,
    )?;
    // -- setHighpass --
    /// Applies a highpass filter to a source, attenuating low frequencies.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | cutoff_hz | integer | Cutoff frequency in Hertz.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setHighpass",
        lua.create_function(move |_, (id_val, cutoff_hz): (LuaValue, u32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        })?,
    )?;
    // -- getLowpass --
    /// Returns the current lowpass filter cutoff of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | integer | Cutoff frequency in Hz, or 0 if not set.
    let s = state.clone();
    tbl.set(
        "getLowpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        })?,
    )?;
    // -- getHighpass --
    /// Returns the current highpass filter cutoff of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | integer | Cutoff frequency in Hz, or 0 if not set.
    let s = state.clone();
    tbl.set(
        "getHighpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        })?,
    )?;
    // -- clearFilter --
    /// Removes all frequency filters from a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "clearFilter",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        })?,
    )?;
    // -- fadeIn --
    /// Sets the fade-in duration for a source so it ramps from silence on play.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | dur | number | Fade-in duration in seconds.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "fadeIn",
        lua.create_function(move |_, (id_val, dur): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.fadeIn")?;
            st.mixer.set_fade_in(key, dur);
            Ok(())
        })?,
    )?;
    // -- getFadeIn --
    /// Returns the configured fade-in duration of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number | Fade-in duration in seconds.
    let s = state.clone();
    tbl.set(
        "getFadeIn",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        })?,
    )?;
    // -- setListener2D --
    /// Sets the 2D listener position for spatial audio calculations.
    /// @param | x | number | Listener X position in world units.
    /// @param | y | number | Listener Y position in world units.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setListener2D",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mixer.set_listener_position(x, y, 0.0);
            Ok(())
        })?,
    )?;
    // -- getListener2D --
    /// Returns the current 2D listener position.
    /// @return | number, number | X and Y position of the listener.
    let s = state.clone();
    tbl.set(
        "getListener2D",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1]))
        })?,
    )?;
    // -- setListener --
    /// Sets the 3D listener position for spatial audio (Z defaults to 0 for 2D games).
    /// @param | x | number | Listener X position.
    /// @param | y | number | Listener Y position.
    /// @param | z | number? | Listener Z position (defaults to 0).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setListener",
        lua.create_function(move |_, (x, y, z): (f32, f32, Option<f32>)| {
            s.borrow_mut()
                .mixer
                .set_listener_position(x, y, z.unwrap_or(0.0));
            Ok(())
        })?,
    )?;
    // -- getListener --
    /// Returns the current 3D listener position.
    /// @return | number, number, number | X, Y, and Z position of the listener.
    let s = state.clone();
    tbl.set(
        "getListener",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;
    // -- setPosition --
    /// Sets the 3D position of a source for spatial audio panning and attenuation.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | x | number | X position in world units.
    /// @param | y | number | Y position in world units.
    /// @param | z | number? | Z position (defaults to 0).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setPosition",
        lua.create_function(
            move |_, (id_val, x, y, z): (LuaValue, f32, f32, Option<f32>)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut()
                    .mixer
                    .set_source_position(key, x, y, z.unwrap_or(0.0));
                Ok(())
            },
        )?,
    )?;
    // -- getPosition --
    /// Returns the 3D position of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number, number, number | X, Y, and Z position.
    let s = state.clone();
    tbl.set(
        "getPosition",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let pos = s.borrow().mixer.get_source_position(key);
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;
    // -- setVelocity --
    /// Sets the velocity of a source for Doppler effect calculations.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | x | number | X velocity component.
    /// @param | y | number | Y velocity component.
    /// @param | z | number? | Z velocity component (defaults to 0).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setVelocity",
        lua.create_function(
            move |_, (id_val, x, y, z): (LuaValue, f32, f32, Option<f32>)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut()
                    .mixer
                    .set_source_velocity(key, x, y, z.unwrap_or(0.0));
                Ok(())
            },
        )?,
    )?;
    // -- getVelocity --
    /// Returns the velocity vector of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number, number, number | X, Y, and Z velocity components.
    let s = state.clone();
    tbl.set(
        "getVelocity",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let vel = s.borrow().mixer.get_source_velocity(key);
            Ok((vel[0], vel[1], vel[2]))
        })?,
    )?;
    // -- setOrientation --
    /// Sets the orientation of a source using forward and up vectors.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @param | fx | number | Forward vector X.
    /// @param | fy | number | Forward vector Y.
    /// @param | fz | number | Forward vector Z.
    /// @param | ux | number | Up vector X.
    /// @param | uy | number | Up vector Y.
    /// @param | uz | number | Up vector Z.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setOrientation",
        lua.create_function(
            move |_, (id_val, fx, fy, fz, ux, uy, uz): (LuaValue, f32, f32, f32, f32, f32, f32)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut()
                    .mixer
                    .set_source_orientation(key, fx, fy, fz, ux, uy, uz);
                Ok(())
            },
        )?,
    )?;
    // -- getOrientation --
    /// Returns the orientation vectors of a source.
    /// @param | source | LSource|integer | Audio source or numeric source ID.
    /// @return | number, number, number, number, number, number | Forward (fx,fy,fz) and up (ux,uy,uz) vectors.
    let s = state.clone();
    tbl.set(
        "getOrientation",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let o = s.borrow().mixer.get_source_orientation(key);
            Ok((o[0], o[1], o[2], o[3], o[4], o[5]))
        })?,
    )?;
    // -- setDopplerScale --
    /// Sets the global Doppler effect intensity multiplier.
    /// @param | scale | number | Doppler scale (0 = disabled, 1.0 = realistic).
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setDopplerScale",
        lua.create_function(move |_, scale: f32| {
            s.borrow_mut().mixer.set_doppler_scale(scale);
            Ok(())
        })?,
    )?;
    // -- getDopplerScale --
    /// Returns the current global Doppler effect scale.
    /// @return | number | Doppler scale factor.
    let s = state.clone();
    tbl.set(
        "getDopplerScale",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_doppler_scale()))?,
    )?;
    // -- setDistanceModel --
    /// Sets the distance attenuation model for spatial audio.
    /// @param | model | string | Model name (e.g. "inverse", "linear", "exponent", "none").
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setDistanceModel",
        lua.create_function(move |_, model: String| {
            s.borrow_mut().mixer.set_distance_model(&model);
            Ok(())
        })?,
    )?;
    // -- getDistanceModel --
    /// Returns the current distance attenuation model name.
    /// @return | string | Distance model name.
    let s = state.clone();
    tbl.set(
        "getDistanceModel",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_distance_model().to_string()))?,
    )?;
    // -- setMeter --
    /// Sets the master peak level for metering purposes.
    /// @param | level | number | Peak level clamped to 0.0-1.0.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "setMeter",
        lua.create_function(move |_, level: f32| {
            s.borrow_mut().mixer.master_peak = level.clamp(0.0, 1.0);
            Ok(())
        })?,
    )?;
    // -- getMeter --
    /// Returns the current master peak level for VU-meter displays.
    /// @return | number | Peak level from 0.0 to 1.0.
    let s = state.clone();
    tbl.set(
        "getMeter",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.master_peak))?,
    )?;
    // -- newMidiPlayer --
    /// Creates a new MIDI player instance, optionally loading a file immediately.
    /// @param | path | string? | Optional relative path to a .mid file to load.
    /// @return | LMidiPlayer | A new MIDI player ready for playback.
    let s = state.clone();
    tbl.set(
        "newMidiPlayer",
        lua.create_function(move |_, path: Option<String>| {
            let mp = MidiPlayer::new();
            let inner = Rc::new(RefCell::new(mp));
            let result = LuaMidiPlayer {
                inner: inner.clone(),
                state: s.clone(),
            };
            if let Some(p) = path {
                let st = s.borrow();
                let full_path = st.game_dir.join(&p);
                drop(st);
                inner.borrow_mut().load(&full_path);
            }
            Ok(result)
        })?,
    )?;
    // -- newSoundData --
    /// Creates a new SoundData object from a file path or blank buffer for procedural audio.
    /// @param | pathOrCount | string|integer | File path to decode, or sample count for blank buffer.
    /// @param | sampleRate | integer | Sample rate in Hz (e.g. 44100, 48000).
    /// @param | channels | integer? | Channel count (1 = mono, 2 = stereo), defaults to 1.
    /// @return | SoundData | Raw PCM sample data for manipulation or playback.
    let s = state.clone();
    tbl.set(
        "newSoundData",
        lua.create_function(move |lua, args: LuaMultiValue| {
            let (path_opt, count, rate, channels) = extract_sound_data_args(args)?;
            let full_path_buf = path_opt.as_ref().map(|p| s.borrow().game_dir.join(p));
            let full_path = full_path_buf.as_ref().and_then(|p| p.to_str());
            let sd = SoundData::from_lua_args(full_path, count, rate, channels)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(sd)
        })?,
    )?;
    let s = state.clone();
    /// Sets the midi sound font for Lua scripts in this module.
    /// @param | path | string | Path-like input used by this call.
    /// @return | nil | No return value.
    tbl.set(
        "setMidiSoundFont",
        lua.create_function(move |_, path: String| {
            let mut st = s.borrow_mut();
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
    let s = state.clone();
    /// Returns true if midi sound font for Lua scripts in this module.
    /// @return | nil | No return value.
    tbl.set(
        "hasMidiSoundFont",
        lua.create_function(move |_, ()| Ok(s.borrow().midi_state.has_soundfont()))?,
    )?;
    let s = state.clone();
    /// Clears midi sound font for Lua scripts in this module.
    /// @return | nil | No return value.
    tbl.set(
        "clearMidiSoundFont",
        lua.create_function(move |_, ()| {
            s.borrow_mut().midi_state.clear_soundfont();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    /// New decoder for Lua scripts in this module.
    /// @param | source | string | Path-like input used by this call.
    /// @param | buffersize | integer? | Lua argument for `buffersize`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newDecoder",
        lua.create_function(move |_, (source, buffersize): (String, Option<usize>)| {
            let st = s.borrow();
            let path = st.game_dir.join(&source);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".to_string()))?;
            let buf = buffersize.unwrap_or(2048);
            let decoder = Decoder::from_file(path_str, buf)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            Ok(LuaDecoder { inner: decoder })
        })?,
    )?;
    let s = state.clone();
    /// New queueable source for Lua scripts in this module.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newQueueableSource",
        lua.create_function(
            move |_,
                  (sample_rate, bit_depth, channels, buffer_count): (
                u32,
                u8,
                u8,
                Option<usize>,
            )| {
                let buf = buffer_count.unwrap_or(4);
                let key = s
                    .borrow_mut()
                    .mixer
                    .new_queueable(sample_rate, bit_depth, channels, buf);
                Ok(slotmap::Key::data(&key).as_ffi())
            },
        )?,
    )?;
    let s = state.clone();
    /// Queue source for Lua scripts in this module.
    /// @param | qsource_id | integer | Lua argument for `qsource_id`.
    /// @param | sd | mlua::AnyUserData | Lua argument for `sd`.
    /// @return | nil | No return value.
    tbl.set(
        "queueSource",
        lua.create_function(move |_, (qsource_id, sd): (u64, mlua::AnyUserData)| {
            let key = queueable_key_from_u64(qsource_id);
            let sd_ref = sd.borrow::<SoundData>()?;
            s.borrow_mut()
                .mixer
                .queue_buffer(key, sd_ref.samples())
                .map_err(|e| LuaError::RuntimeError(e.to_string()))
        })?,
    )?;
    let s = state.clone();
    /// Returns the free buffer count for Lua scripts in this module.
    /// @param | qsource_id | integer | Lua argument for `qsource_id`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "getFreeBufferCount",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            Ok(s.borrow().mixer.queueable_free_buffer_count(key) as u32)
        })?,
    )?;
    let s = state.clone();
    /// Play queueable for Lua scripts in this module.
    /// @param | qsource_id | integer | Lua argument for `qsource_id`.
    /// @return | nil | No return value.
    tbl.set(
        "playQueueable",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            s.borrow_mut().mixer.play_queueable(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    /// Stop queueable for Lua scripts in this module.
    /// @param | qsource_id | integer | Lua argument for `qsource_id`.
    /// @return | nil | No return value.
    tbl.set(
        "stopQueueable",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            s.borrow_mut().mixer.stop_queueable(key);
            Ok(())
        })?,
    )?;
    /// Returns the playback devices for Lua scripts in this module.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "getPlaybackDevices",
        lua.create_function(|lua, ()| {
            let devices = crate::audio::get_playback_devices();
            let t = lua.create_table()?;
            for (i, name) in devices.into_iter().enumerate() {
                t.set(i + 1, name)?;
            }
            Ok(t)
        })?,
    )?;
    /// Returns the playback device for Lua scripts in this module.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "getPlaybackDevice",
        lua.create_function(|_, ()| Ok(crate::audio::get_playback_device()))?,
    )?;
    /// Sets the playback device for Lua scripts in this module.
    /// @param | name | string | String value for `name`.
    /// @return | nil | No return value.
    tbl.set(
        "setPlaybackDevice",
        lua.create_function(|_, name: String| {
            crate::audio::set_playback_device(&name)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))
        })?,
    )?;
    let s = state.clone();
    /// Create_bus for Lua scripts in this module.
    /// @param | name | string | String value for `name`.
    /// @param | parent_name | string? | Lua argument for `parent_name`.
    /// @return | nil | No return value.
    tbl.set(
        "create_bus",
        lua.create_function(move |_, (name, parent_name): (String, Option<String>)| {
            if name.is_empty() {
                return Err(LuaError::external("invalid bus name"));
            }
            let mut st = s.borrow_mut();
            let _parent_key = parent_name.and_then(|n| st.mixer.get_bus_by_name(&n));
            let _bus_key = st.mixer.new_bus(&name);
            Ok(())
        })?,
    )?;

        // -- setSample --
        /// Overwrites one normalized PCM sample value in this sound buffer.
        /// @param | index | integer | Zero-based sample index.
        /// @param | value | number | New sample value.
        /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set(
        "set_bus_volume",
        lua.create_function(move |_, (name, volume): (String, f32)| {
            let mut st = s.borrow_mut();
            if let Some(bus_key) = st.mixer.get_bus_by_name(&name) {
                if let Some(bus) = st.mixer.get_bus_mut(bus_key) {
                    bus.set_volume(volume);
                    return Ok(());
                }
            }
            Err(LuaError::external("bus not found"))
        })?,
    )?;
    let s = state.clone();
    /// Add_effect for Lua scripts in this module.
    /// @param | bus_name | string | Lua argument for `bus_name`.
    /// @param | effect_type_str | string | Lua argument for `effect_type_str`.
    /// @param | params | mlua::Table? | Lua argument for `params`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "add_effect",
        lua.create_function(
            move |_, (bus_name, effect_type_str, params): (String, String, Option<mlua::Table>)| {
                let st = s.borrow();
                let bus_key = st
                    .mixer
                    .get_bus_by_name(&bus_name)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let bus = st
                    .mixer
                    .get_bus(bus_key)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let p1_val = params
                    .as_ref()
                    .and_then(|t| t.get::<_, f32>("value").ok())
                    .unwrap_or(1000.0);
                let eid = bus
                    .add_effect(&effect_type_str, p1_val)
                    .map_err(LuaError::RuntimeError)?;
                Ok(Some(eid))
            },
        )?,
    )?;
    let s = state.clone();
    /// Remove_effect for Lua scripts in this module.
    /// @param | bus_name | string | Lua argument for `bus_name`.
    /// @param | effect_id | integer | Lua argument for `effect_id`.
    /// @return | nil | No return value.
    tbl.set(
        "remove_effect",
        lua.create_function(move |_, (bus_name, effect_id): (String, u32)| {
            let st = s.borrow();
            let bus_key = st
                .mixer
                .get_bus_by_name(&bus_name)
                .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
            let bus = st
                .mixer
                .get_bus(bus_key)
                .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
            bus.remove_effect(effect_id)
                .map_err(LuaError::RuntimeError)
                .map(|_| true)
        })?,
    )?;
    let s = state.clone();
    /// Set_effect_param for Lua scripts in this module.
    /// @param | bus_name | string | Lua argument for `bus_name`.
    /// @param | effect_id | integer | Lua argument for `effect_id`.
    /// @param | param_name | string | Lua argument for `param_name`.
    /// @param | value | number | Lua argument for `value`.
    /// @return | nil | No return value.
    tbl.set(
        "set_effect_param",
        lua.create_function(
            move |_, (bus_name, effect_id, param_name, value): (String, u32, String, f32)| {
                let st = s.borrow();
                let bus_key = st
                    .mixer
                    .get_bus_by_name(&bus_name)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let bus = st
                    .mixer
                    .get_bus(bus_key)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let fx_list = bus.effects.read().unwrap();
                let fx = fx_list
                    .iter()
                    .find(|fx| fx.id == effect_id)
                    .ok_or_else(|| {
                        LuaError::external(format!("Effect not found: {}", effect_id))
                    })?;
                fx.set_param(&param_name, value)
                    .map_err(LuaError::RuntimeError)
                    .map(|_| true)
            },
        )?,
    )?;
    /// New sine wave for Lua scripts in this module.
    /// @param | freq | number | Lua argument for `freq`.
    /// @param | duration | number | Lua argument for `duration`.
    /// @param | sample_rate | integer | Lua argument for `sample_rate`.
    /// @param | amplitude | number | Lua argument for `amplitude`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newSineWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::sine_wave(freq, duration, sample_rate, amplitude))
            },
        )?,
    )?;
    /// New square wave for Lua scripts in this module.
    /// @param | freq | number | Lua argument for `freq`.
    /// @param | duration | number | Lua argument for `duration`.
    /// @param | sample_rate | integer | Lua argument for `sample_rate`.
    /// @param | amplitude | number | Lua argument for `amplitude`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newSquareWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::square_wave(
                    freq,
                    duration,
                    sample_rate,
                    amplitude,
                ))
            },
        )?,
    )?;
    /// New sawtooth wave for Lua scripts in this module.
    /// @param | freq | number | Lua argument for `freq`.
    /// @param | duration | number | Lua argument for `duration`.
    /// @param | sample_rate | integer | Lua argument for `sample_rate`.
    /// @param | amplitude | number | Lua argument for `amplitude`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newSawtoothWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::sawtooth_wave(
                    freq,
                    duration,
                    sample_rate,
                    amplitude,
                ))
            },
        )?,
    )?;
    /// New triangle wave for Lua scripts in this module.
    /// @param | freq | number | Lua argument for `freq`.
    /// @param | duration | number | Lua argument for `duration`.
    /// @param | sample_rate | integer | Lua argument for `sample_rate`.
    /// @param | amplitude | number | Lua argument for `amplitude`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newTriangleWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::triangle_wave(
                    freq,
                    duration,
                    sample_rate,
                    amplitude,
                ))
            },
        )?,
    )?;
    /// New white noise for Lua scripts in this module.
    /// @param | duration | number | Lua argument for `duration`.
    /// @param | sample_rate | integer | Lua argument for `sample_rate`.
    /// @param | amplitude | number | Lua argument for `amplitude`.
    /// @param | seed | integer | Lua argument for `seed`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newWhiteNoise",
        lua.create_function(
            |_, (duration, sample_rate, amplitude, seed): (f32, u32, f32, u32)| {
                Ok(SoundData::white_noise(
                    duration,
                    sample_rate,
                    amplitude,
                    seed,
                ))
            },
        )?,
    )?;
    /// Apply lowpass for Lua scripts in this module.
    /// @param | sd_ud | userdata | Lua argument for `sd_ud`.
    /// @param | cutoff_hz | number | Lua argument for `cutoff_hz`.
    /// @return | nil | No return value.
    tbl.set(
        "applyLowpass",
        lua.create_function(|_, (sd_ud, cutoff_hz): (LuaAnyUserData, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_lowpass(cutoff_hz);
            Ok(())
        })?,
    )?;
    /// Apply highpass for Lua scripts in this module.
    /// @param | sd_ud | userdata | Lua argument for `sd_ud`.
    /// @param | cutoff_hz | number | Lua argument for `cutoff_hz`.
    /// @return | nil | No return value.
    tbl.set(
        "applyHighpass",
        lua.create_function(|_, (sd_ud, cutoff_hz): (LuaAnyUserData, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_highpass(cutoff_hz);
            Ok(())
        })?,
    )?;
    /// Apply bandpass for Lua scripts in this module.
    /// @param | sd_ud | userdata | Lua argument for `sd_ud`.
    /// @param | low_hz | number | Lua argument for `low_hz`.
    /// @param | high_hz | number | Lua argument for `high_hz`.
    /// @return | nil | No return value.
    tbl.set(
        "applyBandpass",
        lua.create_function(|_, (sd_ud, low_hz, high_hz): (LuaAnyUserData, f32, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_bandpass(low_hz, high_hz);
            Ok(())
        })?,
    )?;
    /// Apply gain for Lua scripts in this module.
    /// @param | sd_ud | userdata | Lua argument for `sd_ud`.
    /// @param | gain | number | Lua argument for `gain`.
    /// @return | nil | No return value.
    tbl.set(
        "applyGain",
        lua.create_function(|_, (sd_ud, gain): (LuaAnyUserData, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_gain(gain);
            Ok(())
        })?,
    )?;
    /// Mix into for Lua scripts in this module.
    /// @param | dest_ud | userdata | Lua argument for `dest_ud`.
    /// @param | src_ud | userdata | Lua argument for `src_ud`.
    /// @return | nil | No return value.
    tbl.set(
        "mixInto",
        lua.create_function(|_, (dest_ud, src_ud): (LuaAnyUserData, LuaAnyUserData)| {
            let src_samples: Vec<f32> = {
                let src = src_ud
                    .borrow::<SoundData>()
                    .map_err(|_| LuaError::RuntimeError("src must be a SoundData".into()))?;
                src.samples().to_vec()
            };
            let src_data = {
                let src = src_ud
                    .borrow::<SoundData>()
                    .map_err(|_| LuaError::RuntimeError("src must be a SoundData".into()))?;
                SoundData::from_samples(src_samples, src.sample_rate(), src.channel_count())
            };
            let mut dest = dest_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("dest must be a SoundData".into()))?;
            dest.mix_into(&src_data);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    /// Save wav for Lua scripts in this module.
    /// @param | sd_ud | userdata | Lua argument for `sd_ud`.
    /// @param | filename | string | Path-like input used by this call.
    /// @return | nil | No return value.
    tbl.set(
        "saveWAV",
        lua.create_function(move |_, (sd_ud, filename): (LuaAnyUserData, String)| {
            let path = s.borrow().game_dir.join(&filename);
            let sd = sd_ud
                .borrow::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            let bytes = sd.encode_wav();
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent).map_err(LuaError::external)?;
            }
            std::fs::write(&path, &bytes).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// Sets the stereo width for Lua scripts in this module.
    /// @param | src_ud | userdata | Lua argument for `src_ud`.
    /// @param | width | number | Numeric `width` argument for this call.
    /// @return | nil | No return value.
    tbl.set(
        "setStereoWidth",
        lua.create_function(move |_, (src_ud, width): (LuaAnyUserData, f32)| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow_mut()
                .mixer
                .set_stereo_width(key, width)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// Returns the stereo width for Lua scripts in this module.
    /// @param | src_ud | userdata | Lua argument for `src_ud`.
    /// @return | nil | No return value.
    tbl.set(
        "getStereoWidth",
        lua.create_function(move |_, src_ud: LuaAnyUserData| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow()
                .mixer
                .get_stereo_width(key)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// Sets the random pitch for Lua scripts in this module.
    /// @param | src_ud | userdata | Lua argument for `src_ud`.
    /// @param | min | number | Lua argument for `min`.
    /// @param | max | number | Lua argument for `max`.
    /// @return | nil | No return value.
    tbl.set(
        "setRandomPitch",
        lua.create_function(move |_, (src_ud, min, max): (LuaAnyUserData, f32, f32)| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow_mut()
                .mixer
                .set_random_pitch(key, min, max)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// Clears random pitch for Lua scripts in this module.
    /// @param | src_ud | userdata | Lua argument for `src_ud`.
    /// @return | nil | No return value.
    tbl.set(
        "clearRandomPitch",
        lua.create_function(move |_, src_ud: LuaAnyUserData| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow_mut().mixer.clear_random_pitch(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    /// Crossfade for Lua scripts in this module.
    /// @param | from_ud | userdata | Lua argument for `from_ud`.
    /// @param | to_ud | userdata | Lua argument for `to_ud`.
    /// @param | duration | number | Lua argument for `duration`.
    /// @return | nil | No return value.
    tbl.set(
        "crossfade",
        lua.create_function(
            move |_, (from_ud, to_ud, duration): (LuaAnyUserData, LuaAnyUserData, f32)| {
                let from_key = from_ud
                    .borrow::<LuaSource>()
                    .map_err(|_| LuaError::RuntimeError("from must be an AudioSource".into()))?
                    .key;
                let to_key = to_ud
                    .borrow::<LuaSource>()
                    .map_err(|_| LuaError::RuntimeError("to must be an AudioSource".into()))?
                    .key;
                let game_dir = s.borrow().game_dir.clone();
                s.borrow_mut()
                    .mixer
                    .crossfade(from_key, to_key, duration, &game_dir);
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    /// Returns the bus peak for Lua scripts in this module.
    /// @param | bus_name | string | Lua argument for `bus_name`.
    /// @return | nil | No return value.
    tbl.set(
        "getBusPeak",
        lua.create_function(move |_, bus_name: String| {
            s.borrow()
                .mixer
                .get_bus_peak(&bus_name)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// Returns the bus rms for Lua scripts in this module.
    /// @param | bus_name | string | Lua argument for `bus_name`.
    /// @return | nil | No return value.
    tbl.set(
        "getBusRms",
        lua.create_function(move |_, bus_name: String| {
            s.borrow()
                .mixer
                .get_bus_rms(&bus_name)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// New pool for Lua scripts in this module.
    /// @param | file_path | string | Lua argument for `file_path`.
    /// @param | voice_count | integer | Lua argument for `voice_count`.
    /// @return | table | Table result returned by this call.
    tbl.set(
        "newPool",
        lua.create_function(move |_, (file_path, voice_count): (String, usize)| {
            let pool = s
                .borrow_mut()
                .mixer
                .new_pool(&file_path, voice_count)
                .map_err(LuaError::external)?;
            Ok(LuaSoundPool {
                pool,
                state: s.clone(),
            })
        })?,
    )?;
    let s = state.clone();
    /// Process offline for Lua scripts in this module.
    /// @param | input | string | Lua argument for `input`.
    /// @param | output | string | Lua argument for `output`.
    /// @param | effects_tbl | mlua::Table | Lua argument for `effects_tbl`.
    /// @return | nil | No return value.
    tbl.set(
        "processOffline",
        lua.create_function(
            move |_, (input, output, effects_tbl): (String, String, mlua::Table)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                let mut effects = Vec::new();
                for pair in effects_tbl.sequence_values::<mlua::Table>() {
                    let t = pair.map_err(LuaError::external)?;
                    let typ_str: String = t.get("type").unwrap_or_default();
                    let p1: f32 = t.get("p1").unwrap_or(1000.0);
                    let p2: f32 = t.get("p2").unwrap_or(1.0);
                    let p3: f32 = t.get("p3").unwrap_or(0.5);
                    use crate::audio::EffectType;
                    let typ = match typ_str.as_str() {
                        "lowpass" => EffectType::Lowpass,
                        "highpass" => EffectType::Highpass,
                        "bandpass" => EffectType::Bandpass,
                        "reverb" => EffectType::Reverb,
                        "chorus" => EffectType::Chorus,
                        "notch" => EffectType::Notch,
                        "lowshelf" => EffectType::LowShelf,
                        "highshelf" => EffectType::HighShelf,
                        "bell_eq" => EffectType::BellEq,
                        "reverb2" => EffectType::Reverb2,
                        "flanger" => EffectType::Flanger,
                        "phaser" => EffectType::Phaser,
                        "distortion" => EffectType::Distortion,
                        "limiter" => EffectType::Limiter,
                        "compressor" => EffectType::Compressor,
                        other => {
                            return Err(LuaError::external(format!(
                                "unknown effect type: {}",
                                other
                            )))
                        }
                    };
                    effects.push(crate::audio::OfflineEffect { typ, p1, p2, p3 });
                }
                crate::audio::offline::process_offline(&input_path, &output_path, &effects)
                    .map_err(LuaError::external)
            },
        )?,
    )?;
    let s = state.clone();
    /// Normalize file for Lua scripts in this module.
    /// @param | input | string | Lua argument for `input`.
    /// @param | output | string | Lua argument for `output`.
    /// @param | target | number | Lua argument for `target`.
    /// @return | nil | No return value.
    tbl.set(
        "normalizeFile",
        lua.create_function(move |_, (input, output, target): (String, String, f32)| {
            if input.contains("..") || output.contains("..") {
                return Err(LuaError::external("path traversal not allowed"));
            }
            let game_dir = s.borrow().game_dir.clone();
            let input_path = game_dir.join(&input).to_string_lossy().into_owned();
            let output_path = game_dir.join(&output).to_string_lossy().into_owned();
            crate::audio::offline::normalize_file(&input_path, &output_path, target)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    /// Waveform to png for Lua scripts in this module.
    /// @param | input | string | Lua argument for `input`.
    /// @param | output | string | Lua argument for `output`.
    /// @param | width | integer | Numeric `width` argument for this call.
    /// @param | height | integer | Numeric `height` argument for this call.
    /// @return | nil | No return value.
    tbl.set(
        "waveformToPng",
        lua.create_function(
            move |_, (input, output, width, height): (String, String, u32, u32)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                crate::audio::visualizer::waveform_to_png(&input_path, &output_path, width, height)
                    .map_err(LuaError::external)
            },
        )?,
    )?;
    let s = state.clone();
    /// Spectrogram to png for Lua scripts in this module.
    /// @param | input | string | Lua argument for `input`.
    /// @param | output | string | Lua argument for `output`.
    /// @param | width | integer | Numeric `width` argument for this call.
    /// @param | height | integer | Numeric `height` argument for this call.
    /// @return | nil | No return value.
    tbl.set(
        "spectrogramToPng",
        lua.create_function(
            move |_, (input, output, width, height): (String, String, u32, u32)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                crate::audio::visualizer::spectrogram_to_png(
                    &input_path,
                    &output_path,
                    width,
                    height,
                )
                .map_err(LuaError::external)
            },
        )?,
    )?;
    lurek.set("audio", tbl)?;
    Ok(())
}
/// Represents the Lua-visible LSoundData object exposed by this module.
impl mlua::UserData for SoundData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getSampleCount --
        /// Returns the total number of samples stored in this sound buffer.
        /// @return | integer | Total sample count.
        methods.add_method("getSampleCount", |_, this, ()| Ok(this.sample_count()));
        // -- getSampleRate --
        /// Returns the playback sample rate of this sound buffer.
        /// @return | integer | Sample rate in Hz.
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.sample_rate()));
        // -- getChannelCount --
        /// Returns the number of audio channels stored in this sound buffer.
        /// @return | integer | Channel count.
        methods.add_method("getChannelCount", |_, this, ()| Ok(this.channel_count()));
        // -- getDuration --
        /// Returns the approximate playback duration of this sound buffer.
        /// @return | number | Duration in seconds.
        methods.add_method("getDuration", |_, this, ()| Ok(this.duration()));
        // -- getBitDepth --
        /// Returns the sample bit depth of this sound buffer.
        /// @return | integer | Bit depth per sample.
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.bit_depth()));
        // -- getSample --
        /// Returns the sample value at the given zero-based sample index.
        /// @param | index | integer | Zero-based sample index.
        /// @return | number | Sample value at the requested index.
        methods.add_method("getSample", |_, this, index: usize| {
            this.get_sample(index).ok_or_else(|| {
                LuaError::RuntimeError(format!("Sample index {} out of bounds", index))
            })
        });

        // -- drawWaveform --
        /// Draws this sound buffer as a waveform into an image buffer.
        /// @param | target | LImageData | Target image to draw into.
        /// @param | x | integer | Left pixel coordinate.
        /// @param | y | integer | Top pixel coordinate.
        /// @param | w | integer | Waveform width in pixels.
        /// @param | h | integer | Waveform height in pixels.
        /// @param | r | integer | Red channel from 0 to 255.
        /// @param | g | integer | Green channel from 0 to 255.
        /// @param | b | integer | Blue channel from 0 to 255.
        /// @param | a | integer | Alpha channel from 0 to 255.
        /// @return | nil | No value is returned.
        methods.add_method(
            "drawWaveform",
            |_,
             this,
             (target, x, y, w, h, r, g, b, a): (
                mlua::AnyUserData,
                i32,
                i32,
                u32,
                u32,
                u8,
                u8,
                u8,
                u8,
            )| {
                let mut img = target.borrow_mut::<crate::image::ImageData>()?;
                this.draw_waveform(&mut img, x, y, w, h, r, g, b, a);
                Ok(())
            },
        );
        // -- setSample --
        /// Overwrites the sample value at the given zero-based sample index.
        /// @param | index | integer | Zero-based sample index.
        /// @param | value | number | New sample value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSample", |_, this, (index, value): (usize, f32)| {
            if this.set_sample(index, value) {
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!(
                    "Sample index {} out of bounds",
                    index
                )))
            }
        });
    }
}
