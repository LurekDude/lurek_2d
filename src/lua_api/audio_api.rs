//! `lurek.audio` -- Audio playback, mixing, MIDI synthesis, and DSP effects.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::audio::sound_data::SoundData;
use crate::audio::{Decoder, MidiPlayer, SourceType};
use crate::log_msg;
use crate::runtime::log_messages::LA01_API_STUB;
use crate::runtime::resource_keys::{BusKey, QueueableKey, SoundKey};
use slotmap::Key;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Extracts a `SoundKey` from either a `LuaSource` UserData or a numeric ID.
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

/// Builds an error for an invalid or released audio source handle.
fn invalid_source_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released audio source handle",
        function_name
    ))
}

/// Validates that a source key still exists in the mixer.
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

/// Extracts and validates a source key from a Lua value.
fn require_sound_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<SoundKey> {
    let key = sound_key_from_value(val)?;
    ensure_source_exists(&state.mixer, key, function_name)
}

/// Reconstructs a `QueueableKey` from the packed u64 used in Lua.
fn queueable_key_from_u64(raw: u64) -> QueueableKey {
    QueueableKey::from(slotmap::KeyData::from_ffi(raw))
}

/// Parses `newSoundData` arguments from a Lua multi-value into typed components.
///
/// Returns `(path, count, sample_rate, channels)` where `path` is `Some` for
/// file-based construction and `None` for a silent buffer.
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
    let rate = match it.next() {
        Some(LuaValue::Integer(n)) => n as u32,
        Some(LuaValue::Number(n)) => n as u32,
        _ => 44100,
    };
    let channels = match it.next() {
        Some(LuaValue::Integer(n)) => n as u16,
        Some(LuaValue::Number(n)) => n as u16,
        _ => 1,
    };
    Ok((path, count, rate, channels))
}

// -------------------------------------------------------------------------------
// LuaSource UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for an audio source resource.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `SoundKey`.
///
#[derive(Clone)]
pub struct LuaSource {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SoundKey,
}

impl LuaUserData for LuaSource {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- play --
        /// Starts or resumes playback.
        /// @return nil
        methods.add_method("play", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:play")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play(key, &game_dir);
            Ok(())
        });

        // -- stop --
        /// Stops playback and resets seek position.
        /// @return nil
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:stop")?;
            st.mixer.stop(key);
            Ok(())
        });

        // -- pause --
        /// Pauses playback at the current position.
        /// @return nil
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:pause")?;
            st.mixer.pause(key);
            Ok(())
        });

        // -- resume --
        /// Resumes playback from the paused position.
        /// @return nil
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:resume")?;
            st.mixer.resume(key);
            Ok(())
        });

        // -- setVolume --
        /// Sets playback volume (0.0 = silent, 1.0 = full).
        /// @param vol : number
        /// @return nil
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        });

        // -- getVolume --
        /// Returns the current volume multiplier.
        /// @return number
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getVolume")?;
            Ok(st.mixer.get_volume(key))
        });

        // -- setPitch --
        /// Sets the pitch multiplier (1.0 = normal).
        /// @param pitch : number
        /// @return nil
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        });

        // -- getPitch --
        /// Returns the current pitch multiplier.
        /// @return number
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPitch")?;
            Ok(st.mixer.get_pitch(key))
        });

        // -- setLooping --
        /// Enables or disables looping playback.
        /// @param looping : boolean
        /// @return nil
        methods.add_method("setLooping", |_, this, looping: bool| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        });

        // -- isLooping --
        /// Returns true if looping is enabled.
        /// @return boolean
        methods.add_method("isLooping", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isLooping")?;
            Ok(st.mixer.is_looping(key))
        });

        // -- isPlaying --
        /// Returns true if currently playing.
        /// @return boolean
        methods.add_method("isPlaying", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPlaying")?;
            Ok(st.mixer.is_playing(key))
        });

        // -- isPaused --
        /// Returns true if playback is paused.
        /// @return boolean
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPaused")?;
            Ok(st.mixer.is_paused(key))
        });

        // -- isStopped --
        /// Returns true if playback has stopped.
        /// @return boolean
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isStopped")?;
            Ok(st.mixer.is_stopped(key))
        });

        // -- setPan --
        /// Sets stereo panning (-1.0 left to 1.0 right).
        /// @param pan : number
        /// @return nil
        methods.add_method("setPan", |_, this, pan: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        });

        // -- getPan --
        /// Returns the current stereo panning value.
        /// @return number
        methods.add_method("getPan", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPan")?;
            Ok(st.mixer.get_pan(key))
        });

        // -- clone --
        /// Creates an independent copy of this source.
        /// @return Source
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
        /// Returns the source type ("static" or "stream").
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_source_type(this.key) {
                Some(SourceType::Static) => Ok("static"),
                Some(SourceType::Stream) => Ok("stream"),
                None => Err(invalid_source_handle("Source:getType")),
            }
        });

        // -- getDuration --
        /// Returns the total duration in seconds.
        /// @return number
        methods.add_method("getDuration", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getDuration")?;
            Ok(st.mixer.get_duration(key))
        });

        // -- tell --
        /// Returns the current playback position in seconds.
        /// @return number
        methods.add_method("tell", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:tell")?;
            Ok(st.mixer.get_tell(key))
        });

        // -- seek --
        /// Seeks to a time position in seconds.
        /// @param pos : number
        /// @return nil
        methods.add_method("seek", |_, this, pos: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        });

        // -- setLowpass --
        /// Applies a low-pass filter at the given cutoff frequency.
        /// @param cutoff_hz : integer
        /// @return nil
        methods.add_method("setLowpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        });

        // -- setHighpass --
        /// Applies a high-pass filter at the given cutoff frequency.
        /// @param cutoff_hz : integer
        /// @return nil
        methods.add_method("setHighpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        });

        // -- getLowpass --
        /// Returns the low-pass filter cutoff frequency.
        /// @return number
        methods.add_method("getLowpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        });

        // -- getHighpass --
        /// Returns the high-pass filter cutoff frequency.
        /// @return number
        methods.add_method("getHighpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        });

        // -- clearFilter --
        /// Removes any active filter from this source.
        /// @return nil
        methods.add_method("clearFilter", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        });

        // -- fadeIn --
        /// Fades in from silence over the given duration in seconds.
        /// @param dur : number
        /// @return nil
        methods.add_method("fadeIn", |_, this, dur: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:fadeIn")?;
            st.mixer.set_fade_in(key, dur);
            Ok(())
        });

        // -- getFadeIn --
        /// Returns the current fade-in duration in seconds.
        /// @return number
        methods.add_method("getFadeIn", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaBus UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for an audio bus resource.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `BusKey`.
///
#[derive(Clone)]
pub struct LuaBus {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: BusKey,
}

impl LuaUserData for LuaBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the bus name.
        /// @return string
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
        /// Sets the volume for all sources on this bus.
        /// @param vol : number
        /// @return nil
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_volume(vol);
            }
            Ok(())
        });

        // -- getVolume --
        /// Returns the bus volume.
        /// @return number
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.volume()))
        });

        // -- setPitch --
        /// Sets the pitch multiplier for all sources on this bus.
        /// @param pitch : number
        /// @return nil
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_pitch(pitch);
            }
            Ok(())
        });

        // -- getPitch --
        /// Returns the bus pitch multiplier.
        /// @return number
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.pitch()))
        });

        // -- pause --
        /// Pauses all sources on this bus.
        /// @return nil
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.pause();
            }
            Ok(())
        });

        // -- resume --
        /// Resumes all sources on this bus.
        /// @return nil
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.resume();
            }
            Ok(())
        });

        // -- isPaused --
        /// Returns true if this bus is paused.
        /// @return boolean
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).is_some_and(|b| b.is_paused()))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Bus"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Bus" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaMidiPlayer UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for the MIDI player.
///
/// # Fields
/// - `inner` — `Rc<RefCell<MidiPlayer>>`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
#[derive(Clone)]
pub struct LuaMidiPlayer {
    pub(crate) inner: Rc<RefCell<MidiPlayer>>,
    pub(crate) state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaMidiPlayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- load --
        /// Loads a MIDI file from the given path.
        /// @param path : string
        /// @return boolean
        methods.add_method("load", |_, this, path: String| {
            let st = this.state.borrow();
            let full_path = st.game_dir.join(&path);
            Ok(this.inner.borrow_mut().load(&full_path))
        });

        // -- loadData --
        /// Loads MIDI data from a Lua string.
        /// @param data : string
        /// @return boolean
        methods.add_method("loadData", |_, this, data: mlua::String| {
            let bytes = data.as_bytes().to_vec();
            Ok(this.inner.borrow_mut().load_data(bytes))
        });

        // -- isLoaded --
        /// Returns true if a MIDI sequence is loaded.
        /// @return boolean
        methods.add_method("isLoaded", |_, this, ()| {
            Ok(this.inner.borrow().is_loaded())
        });

        // -- getFilePath --
        /// Returns the file path of the loaded MIDI, or nil.
        /// @return string
        methods.add_method("getFilePath", |_, this, ()| {
            Ok(this.inner.borrow().file_path().map(|s| s.to_string()))
        });

        // -- setSoundFont --
        /// Loads a SoundFont file into this player (stub).
        /// @param path : string
        /// @return nil
        methods.add_method("setSoundFont", |_, _this, _path: String| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setSoundFont");
            Ok(())
        });

        // -- getSoundFontPath --
        /// Returns the SoundFont file path, or nil (stub).
        /// @return string
        methods.add_method("getSoundFontPath", |_, _this, ()| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:getSoundFontPath");
            Ok(Option::<String>::None)
        });

        // -- useDefaultSoundFont --
        /// Reverts to the built-in default SoundFont (stub).
        /// @return nil
        methods.add_method("useDefaultSoundFont", |_, _this, ()| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:useDefaultSoundFont");
            Ok(())
        });

        // -- play --
        /// Starts MIDI playback.
        /// @return nil
        methods.add_method("play", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(handle) = st.mixer.stream_handle() {
                this.inner.borrow_mut().play(handle);
            }
            Ok(())
        });

        // -- pause --
        /// Pauses MIDI playback.
        /// @return nil
        methods.add_method("pause", |_, this, ()| {
            this.inner.borrow_mut().pause();
            Ok(())
        });

        // -- stop --
        /// Stops MIDI playback.
        /// @return nil
        methods.add_method("stop", |_, this, ()| {
            this.inner.borrow_mut().stop();
            Ok(())
        });

        // -- isPlaying --
        /// Returns true if MIDI is currently playing.
        /// @return boolean
        methods.add_method("isPlaying", |_, this, ()| {
            Ok(this.inner.borrow().is_playing())
        });

        // -- isPaused --
        /// Returns true if MIDI playback is paused.
        /// @return boolean
        methods.add_method("isPaused", |_, this, ()| {
            Ok(this.inner.borrow().is_paused())
        });

        // -- seek --
        /// Seeks to a time position in seconds.
        /// @param secs : number
        /// @return nil
        methods.add_method("seek", |_, this, secs: f64| {
            this.inner.borrow_mut().seek(secs);
            Ok(())
        });

        // -- tell --
        /// Returns the current playback position in seconds.
        /// @return number
        methods.add_method("tell", |_, this, ()| Ok(this.inner.borrow().tell()));

        // -- getDuration --
        /// Returns the total MIDI duration in seconds.
        /// @return number
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration())
        });

        // -- setLooping --
        /// Enables or disables looping.
        /// @param looping : boolean
        /// @return nil
        methods.add_method("setLooping", |_, this, looping: bool| {
            this.inner.borrow_mut().set_looping(looping);
            Ok(())
        });

        // -- isLooping --
        /// Returns true if looping is enabled.
        /// @return boolean
        methods.add_method("isLooping", |_, this, ()| {
            Ok(this.inner.borrow().is_looping())
        });

        // -- setVolume --
        /// Sets MIDI playback volume.
        /// @param vol : number
        /// @return nil
        methods.add_method("setVolume", |_, this, vol: f32| {
            this.inner.borrow_mut().set_volume(vol);
            Ok(())
        });

        // -- getVolume --
        /// Returns the current MIDI volume.
        /// @return number
        methods.add_method("getVolume", |_, this, ()| Ok(this.inner.borrow().volume()));

        // -- setBus --
        /// Routes MIDI output through a bus (or nil to clear).
        /// @param bus_val : Bus
        /// @return nil
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
        /// Returns the assigned bus, or nil.
        /// @return Bus
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
        /// Sets playback tempo in BPM.
        /// @param bpm : number
        /// @return nil
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
        /// Returns the current tempo in BPM.
        /// @return number
        methods.add_method("getTempo", |_, this, ()| {
            let mp = this.inner.borrow();
            Ok(mp.original_tempo() * mp.tempo_scale() as f64)
        });

        // -- getOriginalTempo --
        /// Returns the original MIDI file tempo in BPM.
        /// @return number
        methods.add_method("getOriginalTempo", |_, this, ()| {
            Ok(this.inner.borrow().original_tempo())
        });

        // -- setTempoScale --
        /// Sets the tempo scale factor (1.0 = original speed).
        /// @param scale : number
        /// @return nil
        methods.add_method("setTempoScale", |_, this, scale: f32| {
            this.inner.borrow_mut().set_tempo_scale(scale);
            Ok(())
        });

        // -- getTempoScale --
        /// Returns the current tempo scale factor.
        /// @return number
        methods.add_method("getTempoScale", |_, this, ()| {
            Ok(this.inner.borrow().tempo_scale())
        });

        // -- getTicksPerBeat --
        /// Returns the PPQ resolution from the MIDI header.
        /// @return integer
        methods.add_method("getTicksPerBeat", |_, this, ()| {
            Ok(this.inner.borrow().ticks_per_beat())
        });

        // -- setChannelVolume --
        /// Sets volume for a MIDI channel (1-indexed).
        /// @param ch : integer
        /// @param vol : number
        /// @return nil
        methods.add_method("setChannelVolume", |_, this, (ch, vol): (usize, f32)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_volume(ch - 1, vol);
            }
            Ok(())
        });

        // -- getChannelVolume --
        /// Returns the volume for a MIDI channel (1-indexed).
        /// @param ch : integer
        /// @return number
        methods.add_method("getChannelVolume", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_volume(ch - 1))
            } else {
                Ok(0.0)
            }
        });

        // -- setChannelMuted --
        /// Mutes or unmutes a MIDI channel (1-indexed).
        /// @param ch : integer
        /// @param muted : boolean
        /// @return nil
        methods.add_method("setChannelMuted", |_, this, (ch, muted): (usize, bool)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_muted(ch - 1, muted);
            }
            Ok(())
        });

        // -- isChannelMuted --
        /// Returns true if a MIDI channel is muted (1-indexed).
        /// @param ch : integer
        /// @return boolean
        methods.add_method("isChannelMuted", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().is_channel_muted(ch - 1))
            } else {
                Ok(false)
            }
        });

        // -- setChannelInstrument --
        /// Sets the GM instrument for a MIDI channel (1-indexed).
        /// @param ch : integer
        /// @param inst : integer
        /// @return nil
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
        /// Returns the GM instrument for a MIDI channel (1-indexed).
        /// @param ch : integer
        /// @return integer
        methods.add_method("getChannelInstrument", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_instrument(ch - 1))
            } else {
                Ok(0u8)
            }
        });

        // -- getChannelCount --
        /// Returns the number of MIDI channels.
        /// @return integer
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.borrow().channel_count())
        });

        // -- soloChannel --
        /// Solos a MIDI channel (1-indexed).
        /// @param ch : integer
        /// @return nil
        methods.add_method("soloChannel", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().solo_channel(ch - 1);
            }
            Ok(())
        });

        // -- unsoloAll --
        /// Clears solo on all channels.
        /// @return nil
        methods.add_method("unsoloAll", |_, this, ()| {
            this.inner.borrow_mut().unsolo_all();
            Ok(())
        });

        // -- getTrackCount --
        /// Returns the number of tracks in the MIDI sequence.
        /// @return integer
        methods.add_method("getTrackCount", |_, this, ()| {
            Ok(this.inner.borrow().track_count())
        });

        // -- getTrackName --
        /// Returns the name of a MIDI track (1-indexed), or nil.
        /// @param idx : integer
        /// @return string
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
        /// Mutes or unmutes a track (1-indexed).
        /// @param idx : integer
        /// @param muted : boolean
        /// @return nil
        methods.add_method("setTrackMuted", |_, this, (idx, muted): (usize, bool)| {
            if idx >= 1 {
                this.inner.borrow_mut().set_track_muted(idx - 1, muted);
            }
            Ok(())
        });

        // -- isTrackMuted --
        /// Returns true if a track is muted (1-indexed).
        /// @param idx : integer
        /// @return boolean
        methods.add_method("isTrackMuted", |_, this, idx: usize| {
            if idx >= 1 {
                Ok(this.inner.borrow().is_track_muted(idx - 1))
            } else {
                Ok(false)
            }
        });

        // -- getNoteCount --
        /// Returns the total note count in the MIDI sequence.
        /// @return integer
        methods.add_method("getNoteCount", |_, this, ()| {
            Ok(this.inner.borrow().note_count())
        });

        // -- setOnNoteOn --
        /// Registers a note-on callback (stub).
        /// @param cb : function
        /// @return nil
        methods.add_method("setOnNoteOn", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnNoteOn");
            Ok(())
        });

        // -- setOnNoteOff --
        /// Registers a note-off callback (stub).
        /// @param cb : function
        /// @return nil
        methods.add_method("setOnNoteOff", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnNoteOff");
            Ok(())
        });

        // -- setOnEnd --
        /// Registers a playback-end callback (stub).
        /// @param cb : function
        /// @return nil
        methods.add_method("setOnEnd", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnEnd");
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("MidiPlayer"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "MidiPlayer" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaSoundPool UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for a polyphonic [`crate::audio::SoundPool`].
///
/// # Fields
/// - `pool` — `crate::audio::pool::SoundPool`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// Methods call through to the shared [`crate::engine::SharedState`] mixer for
/// actual playback operations.
pub(crate) struct LuaSoundPool {
    pub(crate) pool: crate::audio::pool::SoundPool,
    pub(crate) state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaSoundPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- play --
        /// Plays the next available voice and returns its SoundKey as an integer.
        /// @return integer
        methods.add_method_mut("play", |_, this, ()| {
            let key = this.pool.next_voice();
            let game_dir = this.state.borrow().game_dir.clone();
            this.state.borrow_mut().mixer.play(key, &game_dir);
            Ok(slotmap::Key::data(&key).as_ffi() as i64)
        });

        // -- stopAll --
        /// Stops all voices in this pool.
        /// @return nil
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
        /// @param vol : number
        /// @return nil
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
        /// Routes all voices through the named bus.
        /// @param name : string
        /// @return nil
        methods.add_method_mut("setBus", |_, this, name: String| {
            this.pool.set_bus(name.clone());
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let bus_key = this.state.borrow().mixer.get_bus_by_name(&name);
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.set_source_bus(key, bus_key);
            }
            Ok(())
        });

        // -- release --
        /// Releases all voices from the mixer and invalidates this pool.
        /// @return nil
        methods.add_method_mut("release", |_, this, ()| {
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.release(key);
            }
            Ok(())
        });

        // -- getVoiceCount --
        /// Returns the total number of voices in this pool.
        /// @return integer
        methods.add_method("getVoiceCount", |_, this, ()| Ok(this.pool.voice_count()));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _this, ()| Ok("SoundPool"));

        // -- typeOf --
        /// Returns true if the type name matches.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SoundPool" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaDecoder UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for a streaming audio decoder.
pub struct LuaDecoder {
    inner: Decoder,
}

impl LuaUserData for LuaDecoder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- decode --
        /// Decodes the next chunk of samples, or nil at EOF.
        /// @return SoundData
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
        /// Returns the number of audio channels.
        /// @return integer
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.channels as u32)
        });

        // -- getBitDepth --
        /// Returns the bit depth.
        /// @return integer
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.inner.bit_depth as u32));

        // -- getSampleRate --
        /// Returns the sample rate in Hz.
        /// @return integer
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.inner.sample_rate));

        // -- getDuration --
        /// Returns the total duration in seconds.
        /// @return number
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.get_duration()));

        // -- seek --
        /// Seeks to a time offset in seconds.
        /// @param offset : number
        /// @return nil
        methods.add_method_mut("seek", |_, this, offset: f64| {
            this.inner.seek(offset);
            Ok(())
        });

        // -- rewind --
        /// Rewinds to the beginning.
        /// @return nil
        methods.add_method_mut("rewind", |_, this, ()| {
            this.inner.rewind();
            Ok(())
        });

        // -- tell --
        /// Returns the current position in seconds.
        /// @return number
        methods.add_method("tell", |_, this, ()| Ok(this.inner.tell()));

        // -- isSeekable --
        /// Returns true if seeking is supported.
        /// @return boolean
        methods.add_method("isSeekable", |_, this, ()| Ok(this.inner.is_seekable()));

        // -- release --
        /// Releases the decoder (no-op).
        /// @return nil
        methods.add_method("release", |_, _, ()| Ok(()));
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.audio` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── newSource ─────────────────────────────────────────────────────────────
    /// Loads an audio file and returns a Source handle.
    /// @param path : string
    /// @param source_type : string
    /// @return Source
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

    // ── play ──────────────────────────────────────────────────────────────────
    /// Plays a source, with optional bus routing via options table.
    /// @param source : Source
    /// @param options : table
    /// @return integer
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

    // ── stop ──────────────────────────────────────────────────────────────────
    /// Stops playback and resets seek position.
    /// @param source : Source
    /// @return nil
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

    // ── setVolume ─────────────────────────────────────────────────────────────
    /// Sets source playback volume.
    /// @param source : Source
    /// @param vol : number
    /// @return nil
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

    // ── getVolume ─────────────────────────────────────────────────────────────
    /// Returns the source volume.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getVolume",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getVolume")?;
            Ok(st.mixer.get_volume(key))
        })?,
    )?;

    // ── pause ─────────────────────────────────────────────────────────────────
    /// Pauses playback at the current position.
    /// @param source : Source
    /// @return nil
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

    // ── resume ────────────────────────────────────────────────────────────────
    /// Resumes playback from pause.
    /// @param source : Source
    /// @return nil
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

    // ── setPitch ──────────────────────────────────────────────────────────────
    /// Sets source pitch multiplier.
    /// @param source : Source
    /// @param pitch : number
    /// @return nil
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

    // ── getPitch ──────────────────────────────────────────────────────────────
    /// Returns the source pitch multiplier.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getPitch",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getPitch")?;
            Ok(st.mixer.get_pitch(key))
        })?,
    )?;

    // ── isPlaying ─────────────────────────────────────────────────────────────
    /// Returns true if the source is playing.
    /// @param source : Source
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isPlaying",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isPlaying")?;
            Ok(st.mixer.is_playing(key))
        })?,
    )?;

    // ── isPaused ──────────────────────────────────────────────────────────────
    /// Returns true if the source is paused.
    /// @param source : Source
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isPaused")?;
            Ok(st.mixer.is_paused(key))
        })?,
    )?;

    // ── isStopped ─────────────────────────────────────────────────────────────
    /// Returns true if the source is stopped.
    /// @param source : Source
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isStopped",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isStopped")?;
            Ok(st.mixer.is_stopped(key))
        })?,
    )?;

    // ── setLooping ────────────────────────────────────────────────────────────
    /// Enables or disables looping.
    /// @param source : Source
    /// @param looping : boolean
    /// @return nil
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

    // ── isLooping ─────────────────────────────────────────────────────────────
    /// Returns true if looping is enabled.
    /// @param source : Source
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isLooping")?;
            Ok(st.mixer.is_looping(key))
        })?,
    )?;

    // ── playLooping ───────────────────────────────────────────────────────────
    /// Plays the source in a continuous loop.
    /// @param source : Source
    /// @return nil
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

    // ── setPan ────────────────────────────────────────────────────────────────
    /// Sets stereo panning (-1.0 left to 1.0 right).
    /// @param source : Source
    /// @param pan : number
    /// @return nil
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

    // ── getPan ────────────────────────────────────────────────────────────────
    /// Returns the source stereo panning.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getPan",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getPan")?;
            Ok(st.mixer.get_pan(key))
        })?,
    )?;

    // ── setMasterVolume ───────────────────────────────────────────────────────
    /// Sets the global master volume.
    /// @param vol : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setMasterVolume",
        lua.create_function(move |_, vol: f32| {
            s.borrow_mut().mixer.set_master_volume(vol);
            Ok(())
        })?,
    )?;

    // ── getMasterVolume ───────────────────────────────────────────────────────
    /// Returns the global master volume.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getMasterVolume",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_master_volume()))?,
    )?;

    // ── getActiveSourceCount ──────────────────────────────────────────────────
    /// Returns the number of currently playing sources.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getActiveSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_active_source_count()))?,
    )?;

    // ── getSourceCount ────────────────────────────────────────────────────────
    /// Returns the total number of registered sources.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_source_count()))?,
    )?;

    // ── getSourceType ─────────────────────────────────────────────────────────
    /// Returns the type string ("static" or "stream") of a source.
    /// @param source : Source
    /// @return string
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

    // ── clone ─────────────────────────────────────────────────────────────────
    /// Creates an independent copy of a source.
    /// @param source : Source
    /// @return Source
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

    // ── pauseAll ──────────────────────────────────────────────────────────────
    /// Pauses all currently playing sources.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "pauseAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.pause_all();
            Ok(())
        })?,
    )?;

    // ── stopAll ───────────────────────────────────────────────────────────────
    /// Stops all currently playing sources.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "stopAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.stop_all();
            Ok(())
        })?,
    )?;

    // ── resumeAll ─────────────────────────────────────────────────────────────
    /// Resumes all paused sources.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "resumeAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.resume_all();
            Ok(())
        })?,
    )?;

    // ── release ───────────────────────────────────────────────────────────────
    /// Releases a source and frees its memory.
    /// @param source : Source
    /// @return boolean
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

    // ── newBus ────────────────────────────────────────────────────────────────
    /// Creates a named audio bus for grouping sources.
    /// @param name : string
    /// @return Bus
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

    // ── setSourceBus ──────────────────────────────────────────────────────────
    /// Assigns a source to a bus.
    /// @param source : Source
    /// @param bus : Bus
    /// @return nil
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

    // ── getSourceBus ──────────────────────────────────────────────────────────
    /// Returns the bus a source is assigned to, or nil.
    /// @param source : Source
    /// @return Bus
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

    // ── getMaxSources ─────────────────────────────────────────────────────────
    /// Returns the maximum number of simultaneous sources.
    /// @return integer
    tbl.set("getMaxSources", lua.create_function(|_, ()| Ok(64))?)?;

    // ── getDuration ───────────────────────────────────────────────────────────
    /// Returns the total duration of a source in seconds.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getDuration",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getDuration")?;
            Ok(st.mixer.get_duration(key))
        })?,
    )?;

    // ── tell ──────────────────────────────────────────────────────────────────
    /// Returns the current playback position in seconds.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "tell",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.tell")?;
            Ok(st.mixer.get_tell(key))
        })?,
    )?;

    // ── seek ──────────────────────────────────────────────────────────────────
    /// Seeks to a time position in seconds.
    /// @param source : Source
    /// @param pos : number
    /// @return nil
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

    // ── setLowpass ────────────────────────────────────────────────────────────
    /// Applies a low-pass filter to a source.
    /// @param source : Source
    /// @param cutoff_hz : integer
    /// @return nil
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

    // ── setHighpass ───────────────────────────────────────────────────────────
    /// Applies a high-pass filter to a source.
    /// @param source : Source
    /// @param cutoff_hz : integer
    /// @return nil
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

    // ── getLowpass ─────────────────────────────────────────────────────────────
    /// Returns the low-pass filter cutoff of a source.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getLowpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        })?,
    )?;

    // ── getHighpass ───────────────────────────────────────────────────────────
    /// Returns the high-pass filter cutoff of a source.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getHighpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        })?,
    )?;

    // ── clearFilter ───────────────────────────────────────────────────────────
    /// Removes any active filter from a source.
    /// @param source : Source
    /// @return nil
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

    // ── fadeIn ─────────────────────────────────────────────────────────────────
    /// Fades a source in from silence over the given duration.
    /// @param source : Source
    /// @param dur : number
    /// @return nil
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

    // ── getFadeIn ─────────────────────────────────────────────────────────────
    /// Returns the fade-in duration of a source.
    /// @param source : Source
    /// @return number
    let s = state.clone();
    tbl.set(
        "getFadeIn",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        })?,
    )?;

    // ── setListener2D ─────────────────────────────────────────────────────────
    /// Sets the 2D listener position for spatial audio.
    /// @param x : number
    /// @param y : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setListener2D",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mixer.set_listener_position(x, y, 0.0);
            Ok(())
        })?,
    )?;

    // ── getListener2D ─────────────────────────────────────────────────────────
    /// Returns the 2D listener position (x, y).
    /// @return number, number
    let s = state.clone();
    tbl.set(
        "getListener2D",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1]))
        })?,
    )?;

    // ── setListener ───────────────────────────────────────────────────────────
    /// Sets the 3D listener position.
    /// @param x : number
    /// @param y : number
    /// @param z : number
    /// @return nil
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

    // ── getListener ───────────────────────────────────────────────────────────
    /// Returns the 3D listener position (x, y, z).
    /// @return number, number, number
    let s = state.clone();
    tbl.set(
        "getListener",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;

    // ── setPosition ───────────────────────────────────────────────────────────
    /// Sets the 3D position of a source.
    /// @param source : Source
    /// @param x : number
    /// @param y : number
    /// @param z : number
    /// @return nil
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

    // ── getPosition ───────────────────────────────────────────────────────────
    /// Returns the 3D position of a source (x, y, z).
    /// @param source : Source
    /// @return number, number, number
    let s = state.clone();
    tbl.set(
        "getPosition",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let pos = s.borrow().mixer.get_source_position(key);
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;

    // ── setVelocity ───────────────────────────────────────────────────────────
    /// Sets the velocity of a source for Doppler.
    /// @param source : Source
    /// @param x : number
    /// @param y : number
    /// @param z : number
    /// @return nil
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

    // ── getVelocity ───────────────────────────────────────────────────────────
    /// Returns the velocity of a source (x, y, z).
    /// @param source : Source
    /// @return number, number, number
    let s = state.clone();
    tbl.set(
        "getVelocity",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let vel = s.borrow().mixer.get_source_velocity(key);
            Ok((vel[0], vel[1], vel[2]))
        })?,
    )?;

    // ── setOrientation ────────────────────────────────────────────────────────
    /// Sets the 6-component orientation of a source.
    /// @param source : Source
    /// @param fx : number
    /// @param fy : number
    /// @param fz : number
    /// @param ux : number
    /// @param uy : number
    /// @param uz : number
    /// @return nil
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

    // ── getOrientation ────────────────────────────────────────────────────────
    /// Returns the 6-component orientation of a source.
    /// @param source : Source
    /// @return number, number, number, number, number, number
    let s = state.clone();
    tbl.set(
        "getOrientation",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let o = s.borrow().mixer.get_source_orientation(key);
            Ok((o[0], o[1], o[2], o[3], o[4], o[5]))
        })?,
    )?;

    // ── setDopplerScale ───────────────────────────────────────────────────────
    /// Sets the global Doppler effect scale.
    /// @param scale : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setDopplerScale",
        lua.create_function(move |_, scale: f32| {
            s.borrow_mut().mixer.set_doppler_scale(scale);
            Ok(())
        })?,
    )?;

    // ── getDopplerScale ───────────────────────────────────────────────────────
    /// Returns the current Doppler scale.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getDopplerScale",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_doppler_scale()))?,
    )?;

    // ── setDistanceModel ──────────────────────────────────────────────────────
    /// Sets the distance attenuation model.
    /// @param model : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setDistanceModel",
        lua.create_function(move |_, model: String| {
            s.borrow_mut().mixer.set_distance_model(&model);
            Ok(())
        })?,
    )?;

    // ── getDistanceModel ──────────────────────────────────────────────────────
    /// Returns the current distance model name.
    /// @return string
    let s = state.clone();
    tbl.set(
        "getDistanceModel",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_distance_model().to_string()))?,
    )?;

    // ── setMeter ──────────────────────────────────────────────────────────────
    /// Sets the metering scale (stub).
    /// @param scale : number
    /// @return nil
    tbl.set(
        "setMeter",
        lua.create_function(|_, _scale: f32| {
            log_msg!(debug, LA01_API_STUB, "lurek.audio.setMeter");
            Ok(())
        })?,
    )?;

    // ── getMeter ──────────────────────────────────────────────────────────────
    /// Returns the current peak level (stub).
    /// @return number
    tbl.set(
        "getMeter",
        lua.create_function(|_, ()| {
            log_msg!(debug, LA01_API_STUB, "lurek.audio.getMeter");
            Ok(1.0_f32)
        })?,
    )?;

    // ── newMidiPlayer ─────────────────────────────────────────────────────────
    /// Creates a MIDI player, optionally loading a file.
    /// @param path : string
    /// @return MidiPlayer
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

    // ── newSoundData ──────────────────────────────────────────────────────────
    /// Creates a SoundData from a file or as a silent buffer.
    /// @param args : string|integer
    /// @return SoundData
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

    // ── setMidiSoundFont ──────────────────────────────────────────────────────
    /// Sets the global SoundFont for MIDI synthesis.
    /// @param path : string
    /// @return nil
    let s = state.clone();
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

    // ── hasMidiSoundFont ──────────────────────────────────────────────────────
    /// Returns true if a SoundFont is loaded.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "hasMidiSoundFont",
        lua.create_function(move |_, ()| Ok(s.borrow().midi_state.has_soundfont()))?,
    )?;

    // ── clearMidiSoundFont ────────────────────────────────────────────────────
    /// Unloads the active SoundFont.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "clearMidiSoundFont",
        lua.create_function(move |_, ()| {
            s.borrow_mut().midi_state.clear_soundfont();
            Ok(())
        })?,
    )?;

    // ── newDecoder ────────────────────────────────────────────────────────────
    /// Creates a streaming audio decoder.
    /// @param source : string
    /// @param buffersize : integer
    /// @return Decoder
    let s = state.clone();
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

    // ── newQueueableSource ────────────────────────────────────────────────────
    /// Creates a queueable source for manual PCM buffering.
    /// @param sample_rate : integer
    /// @param bit_depth : integer
    /// @param channels : integer
    /// @param buffer_count : integer
    /// @return integer
    let s = state.clone();
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

    // ── queueSource ───────────────────────────────────────────────────────────
    /// Pushes a SoundData buffer into a queueable source.
    /// @param qsource_id : integer
    /// @param sounddata : SoundData
    /// @return nil
    let s = state.clone();
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

    // ── getFreeBufferCount ────────────────────────────────────────────────────
    /// Returns the free buffer slots in a queueable source.
    /// @param qsource_id : integer
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getFreeBufferCount",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            Ok(s.borrow().mixer.queueable_free_buffer_count(key) as u32)
        })?,
    )?;

    // ── playQueueable ─────────────────────────────────────────────────────────
    /// Starts playback of a queueable source.
    /// @param qsource_id : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "playQueueable",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            s.borrow_mut().mixer.play_queueable(key);
            Ok(())
        })?,
    )?;

    // ── stopQueueable ─────────────────────────────────────────────────────────
    /// Stops a queueable source and drains its buffers.
    /// @param qsource_id : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "stopQueueable",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            s.borrow_mut().mixer.stop_queueable(key);
            Ok(())
        })?,
    )?;

    // ── getPlaybackDevices ────────────────────────────────────────────────────
    /// Returns a table of available audio output device names.
    /// @return table
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

    // ── getPlaybackDevice ─────────────────────────────────────────────────────
    /// Returns the current audio output device name.
    /// @return string
    tbl.set(
        "getPlaybackDevice",
        lua.create_function(|_, ()| Ok(crate::audio::get_playback_device()))?,
    )?;

    // ── setPlaybackDevice ─────────────────────────────────────────────────────
    /// Selects an audio output device by name.
    /// @param name : string
    /// @return nil
    tbl.set(
        "setPlaybackDevice",
        lua.create_function(|_, name: String| {
            crate::audio::set_playback_device(&name)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))
        })?,
    )?;

    // ── create_bus ────────────────────────────────────────────────────────────
    /// Creates a bus by name (functional style).
    /// @param name : string
    /// @param parent_name : string
    /// @return nil
    let s = state.clone();
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

    // ── set_bus_volume ────────────────────────────────────────────────────────
    /// Sets a bus volume by name.
    /// @param name : string
    /// @param volume : number
    /// @return nil
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

    // ── add_effect ────────────────────────────────────────────────────────────
    /// Adds a DSP effect to a bus.
    /// @param bus_name : string
    /// @param effect_type : string
    /// @param params : table
    /// @return integer
    let s = state.clone();
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

    // ── remove_effect ─────────────────────────────────────────────────────────
    /// Removes a DSP effect from a bus.
    /// @param bus_name : string
    /// @param effect_id : integer
    /// @return boolean
    let s = state.clone();
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

    // ── set_effect_param ──────────────────────────────────────────────────────
    /// Sets a parameter on a DSP effect.
    /// @param bus_name : string
    /// @param effect_id : integer
    /// @param param_name : string
    /// @param value : number
    /// @return boolean
    let s = state.clone();
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

    // ── newSineWave ───────────────────────────────────────────────────────────
    /// Generate a mono sine-wave SoundData buffer.
    /// @param freq : number
    /// @param duration : number
    /// @param sampleRate : number
    /// @param amplitude : number
    /// @return SoundData
    tbl.set(
        "newSineWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::sine_wave(freq, duration, sample_rate, amplitude))
            },
        )?,
    )?;

    // ── newSquareWave ─────────────────────────────────────────────────────────
    /// Generate a mono square-wave SoundData buffer.
    /// @param freq : number
    /// @param duration : number
    /// @param sampleRate : number
    /// @param amplitude : number
    /// @return SoundData
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

    // ── newSawtoothWave ───────────────────────────────────────────────────────
    /// Generate a mono sawtooth-wave SoundData buffer.
    /// @param freq : number
    /// @param duration : number
    /// @param sampleRate : number
    /// @param amplitude : number
    /// @return SoundData
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

    // ── newTriangleWave ───────────────────────────────────────────────────────
    /// Generate a mono triangle-wave SoundData buffer.
    /// @param freq : number
    /// @param duration : number
    /// @param sampleRate : number
    /// @param amplitude : number
    /// @return SoundData
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

    // ── newWhiteNoise ─────────────────────────────────────────────────────────
    /// Generate a reproducible white-noise SoundData buffer.
    /// @param duration : number
    /// @param sampleRate : number
    /// @param amplitude : number
    /// @param seed : integer
    /// @return SoundData
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

    // ── applyLowpass ──────────────────────────────────────────────────────────
    /// Applies a first-order IIR low-pass filter to a SoundData in-place.
    /// @param sounddata : SoundData
    /// @param cutoff_hz : number
    /// @return nil
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

    // ── applyHighpass ─────────────────────────────────────────────────────────
    /// Applies a first-order IIR high-pass filter to a SoundData in-place.
    /// @param sounddata : SoundData
    /// @param cutoff_hz : number
    /// @return nil
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

    // ── applyBandpass ─────────────────────────────────────────────────────────
    /// Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
    /// @param sounddata : SoundData
    /// @param low_hz : number
    /// @param high_hz : number
    /// @return nil
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

    // ── applyGain ─────────────────────────────────────────────────────────────
    /// Scales every sample by gain (clamped to [-1, 1]).
    /// @param sounddata : SoundData
    /// @param gain : number
    /// @return nil
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

    // ── mixInto ───────────────────────────────────────────────────────────────
    /// Additively mixes another SoundData into the destination in-place.
    /// @param dest : SoundData
    /// @param src : SoundData
    /// @return nil
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

    // ── saveWAV ───────────────────────────────────────────────────────────────
    /// Saves a SoundData as a 16-bit PCM WAV file at the given path.
    /// @param sounddata : SoundData
    /// @param path : string
    /// @return nil
    let s = state.clone();
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

    // ── setStereoWidth ────────────────────────────────────────────────────────
    /// Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
    /// @param src : AudioSource
    /// @param width : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setStereoWidth",
        lua.create_function(move |_, (src_ud, width): (LuaAnyUserData, f32)| {
            let key = src_ud
                .borrow::<LuaAudioSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .0;
            s.borrow_mut()
                .mixer
                .set_stereo_width(key, width)
                .map_err(LuaError::external)
        })?,
    )?;

    // ── getStereoWidth ────────────────────────────────────────────────────────
    /// Returns the current stereo width for a source.
    /// @param src : AudioSource
    /// @return number
    let s = state.clone();
    tbl.set(
        "getStereoWidth",
        lua.create_function(move |_, src_ud: LuaAnyUserData| {
            let key = src_ud
                .borrow::<LuaAudioSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .0;
            s.borrow()
                .mixer
                .get_stereo_width(key)
                .map_err(LuaError::external)
        })?,
    )?;

    // ── setRandomPitch ────────────────────────────────────────────────────────
    /// Sets a random pitch range applied each time the source is played.
    /// @param src : AudioSource
    /// @param min : number
    /// @param max : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setRandomPitch",
        lua.create_function(move |_, (src_ud, min, max): (LuaAnyUserData, f32, f32)| {
            let key = src_ud
                .borrow::<LuaAudioSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .0;
            s.borrow_mut()
                .mixer
                .set_random_pitch(key, min, max)
                .map_err(LuaError::external)
        })?,
    )?;

    // ── clearRandomPitch ──────────────────────────────────────────────────────
    /// Clears any random pitch range on a source, restoring fixed pitch.
    /// @param src : AudioSource
    /// @return nil
    let s = state.clone();
    tbl.set(
        "clearRandomPitch",
        lua.create_function(move |_, src_ud: LuaAnyUserData| {
            let key = src_ud
                .borrow::<LuaAudioSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .0;
            s.borrow_mut().mixer.clear_random_pitch(key);
            Ok(())
        })?,
    )?;

    // ── crossfade ─────────────────────────────────────────────────────────────
    /// Crossfades from one source to another over a duration.
    /// @param from : AudioSource
    /// @param to : AudioSource
    /// @param duration : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "crossfade",
        lua.create_function(
            move |_, (from_ud, to_ud, duration): (LuaAnyUserData, LuaAnyUserData, f32)| {
                let from_key = from_ud
                    .borrow::<LuaAudioSource>()
                    .map_err(|_| LuaError::RuntimeError("from must be an AudioSource".into()))?
                    .0;
                let to_key = to_ud
                    .borrow::<LuaAudioSource>()
                    .map_err(|_| LuaError::RuntimeError("to must be an AudioSource".into()))?
                    .0;
                let game_dir = s.borrow().game_dir.clone();
                s.borrow_mut()
                    .mixer
                    .crossfade(from_key, to_key, duration, &game_dir);
                Ok(())
            },
        )?,
    )?;

    // ── getBusPeak ────────────────────────────────────────────────────────────
    /// Returns the peak signal level of the named bus (stub: always 0.0).
    /// @param bus_name : string
    /// @return number
    let s = state.clone();
    tbl.set(
        "getBusPeak",
        lua.create_function(move |_, bus_name: String| {
            s.borrow()
                .mixer
                .get_bus_peak(&bus_name)
                .map_err(LuaError::external)
        })?,
    )?;

    // ── getBusRms ─────────────────────────────────────────────────────────────
    /// Returns the RMS signal level of the named bus (stub: always 0.0).
    /// @param bus_name : string
    /// @return number
    let s = state.clone();
    tbl.set(
        "getBusRms",
        lua.create_function(move |_, bus_name: String| {
            s.borrow()
                .mixer
                .get_bus_rms(&bus_name)
                .map_err(LuaError::external)
        })?,
    )?;

    // ── newPool ───────────────────────────────────────────────────────────────
    /// Creates a polyphonic sound pool for the given file with N simultaneous voices.
    /// @param file_path : string
    /// @param voice_count : integer
    /// @return SoundPool
    let s = state.clone();
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

    // ── processOffline ────────────────────────────────────────────────────────
    /// Applies a DSP effect chain to a WAV file and writes output.
    /// @param input_path : string
    /// @param output_path : string
    /// @param effects : table  -- list of {type, p1, p2, p3}
    /// @return nil
    let s = state.clone();
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

    // ── normalizeFile ─────────────────────────────────────────────────────────
    /// Normalizes a WAV file peak amplitude to target_level and writes output.
    /// @param input_path : string
    /// @param output_path : string
    /// @param target_level : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "normalizeFile",
        lua.create_function(
            move |_, (input, output, target): (String, String, f32)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                crate::audio::offline::normalize_file(&input_path, &output_path, target)
                    .map_err(LuaError::external)
            },
        )?,
    )?;

    // ── waveformToPng ─────────────────────────────────────────────────────────
    /// Renders the waveform of a WAV file to a PNG image.
    /// @param input_wav : string
    /// @param output_png : string
    /// @param width : integer
    /// @param height : integer
    /// @return nil
    let s = state.clone();
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
                crate::audio::visualizer::waveform_to_png(
                    &input_path,
                    &output_path,
                    width,
                    height,
                )
                .map_err(LuaError::external)
            },
        )?,
    )?;

    // ── spectrogramToPng ──────────────────────────────────────────────────────
    /// Renders a time-frequency spectrogram of a WAV file to a PNG image.
    /// @param input_wav : string
    /// @param output_png : string
    /// @param width : integer
    /// @param height : integer
    /// @return nil
    let s = state.clone();
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

    luna.set("audio", tbl)?;
    Ok(())
}

impl mlua::UserData for SoundData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── getSampleCount ──────────────────────────────────────────
        /// Get the total number of samples.
        /// @return integer
        methods.add_method("getSampleCount", |_, this, ()| Ok(this.sample_count()));
        // ── getSampleRate ──────────────────────────────────────────
        /// Get the sample rate.
        /// @return integer
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.sample_rate()));
        // ── getChannelCount ──────────────────────────────────────────
        /// Get the number of channels.
        /// @return integer
        methods.add_method("getChannelCount", |_, this, ()| Ok(this.channel_count()));
        // ── getDuration ──────────────────────────────────────────
        /// Get the audio duration in seconds.
        /// @return number
        methods.add_method("getDuration", |_, this, ()| Ok(this.duration()));
        // ── getBitDepth ──────────────────────────────────────────
        /// Get the bit depth.
        /// @return integer
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.bit_depth()));
        // ── getSample ──────────────────────────────────────────
        /// Get a specific sample by index.
        /// @param index : integer
        /// @return number
        methods.add_method("getSample", |_, this, index: usize| {
            this.get_sample(index).ok_or_else(|| {
                LuaError::RuntimeError(format!("Sample index {} out of bounds", index))
            })
        });

        // ── drawWaveform ───────────────────────────────────────
        /// Draws the waveform onto an ImageData buffer.
        /// @param target : ImageData
        /// @param x : integer
        /// @param y : integer
        /// @param w : integer
        /// @param h : integer
        /// @param r : integer
        /// @param g : integer
        /// @param b : integer
        /// @param a : integer
        /// @return nil
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

        // ── setSample ──────────────────────────────────────────
        /// Set a specific sample by index.
        /// @param index : integer
        /// @param value : number
        /// @return nil
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
