//! Audio Api implementation for the `lua_api` subsystem.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for audio api-related operations and data management.
//! Key types exported from this module: `LuaSource`, `LuaBus`, `LuaMidiPlayer`.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use super::SharedState;
use crate::audio::Decoder;
use crate::audio::MidiPlayer;
use crate::audio::SourceType;
use crate::engine::resource_keys::BusKey;
use crate::engine::resource_keys::SoundKey;
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::audio::sound_data::SoundData;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Lua UserData wrapper for an audio source resource.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `SoundKey`.
///
/// Wraps a `SoundKey` and shared state reference so the Lua side
/// can call methods like `source:play()`, `source:setVolume()` directly.
#[derive(Clone)]
pub struct LuaSource {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SoundKey,
}

impl LunaType for LuaSource {
    const TYPE_NAME: &'static str = "Source";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaSource {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Starts or resumes playback from the current seek position.
        methods.add_method("play", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:play")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play(key, &game_dir);
            Ok(())
        });

        /// Stops playback and resets the seek position to the beginning.
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:stop")?;
            st.mixer.stop(key);
            Ok(())
        });

        /// Pauses playback. Call `play()` to resume.
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:pause")?;
            st.mixer.pause(key);
            Ok(())
        });

        /// Resumes playback of this audio source from its current paused position.
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:resume")?;
            st.mixer.resume(key);
            Ok(())
        });

        /// Sets playback volume. `1.0` is full volume; `0.0` is silent.
        /// @param vol : number
        ///
        /// # Parameters
        /// - `volume` — `number`: Volume multiplier (0–1).
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        });

        /// Returns the current volume multiplier.
        /// @return any
        ///
        /// # Returns
        /// `number` — volume (0–1).
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getVolume")?;
            Ok(st.mixer.get_volume(key))
        });

        /// Sets the playback pitch multiplier. `1.0` is normal pitch; `2.0` doubles frequency.
        /// @param pitch : number
        ///
        /// # Parameters
        /// - `pitch` — `number`: Pitch multiplier.
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        });

        /// Returns the current pitch multiplier.
        /// @return any
        ///
        /// # Returns
        /// `number` — pitch multiplier.
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPitch")?;
            Ok(st.mixer.get_pitch(key))
        });

        /// Enables or disables looping. When enabled, the source restarts automatically when it reaches the end.
        /// @param looping : boolean
        ///
        /// # Parameters
        /// - `loop` — `boolean`: `true` to enable looping.
        methods.add_method("setLooping", |_, this, looping: bool| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        });

        /// Returns `true` if this source is set to loop.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isLooping", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isLooping")?;
            Ok(st.mixer.is_looping(key))
        });

        /// Returns `true` if this source is currently playing.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isPlaying", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPlaying")?;
            Ok(st.mixer.is_playing(key))
        });

        /// Returns `true` if playback is currently paused.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPaused")?;
            Ok(st.mixer.is_paused(key))
        });

        /// Returns `true` if playback has stopped (either manually or after the audio ended).
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isStopped")?;
            Ok(st.mixer.is_stopped(key))
        });

        /// Sets the stereo panning (-1.0 left to 1.0 right) of the source.
        /// @param pan : number
        methods.add_method("setPan", |_, this, pan: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        });

        /// Returns the current stereo panning of the source.
        /// @return any
        methods.add_method("getPan", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPan")?;
            Ok(st.mixer.get_pan(key))
        });

        /// Creates an independent copy of an audio source.
        /// @return any
        methods.add_method("clone", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            match st.mixer.clone_source(this.key) {
                Some(new_key) => Ok(LuaSource {
                    state: this.state.clone(),
                    key: new_key,
                }),
                None => Err(mlua::Error::RuntimeError(
                    "Source:clone(): invalid source handle".into(),
                )),
            }
        });

        /// Returns the type of this audio source: 'static', 'stream', or 'queue'.
        /// @return any
        ///
        /// # Returns
        /// Source type string.
        methods.add_method("getType", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_source_type(this.key) {
                Some(crate::audio::SourceType::Static) => Ok("static".to_string()),
                Some(crate::audio::SourceType::Stream) => Ok("stream".to_string()),
                None => Err(mlua::Error::RuntimeError(
                    "Source:getType(): invalid source handle".into(),
                )),
            }
        });

        /// Returns the total duration of this audio source in seconds.
        /// @return any
        ///
        /// # Returns
        /// `number` — total duration in seconds.
        methods.add_method("getDuration", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getDuration")?;
            Ok(st.mixer.get_duration(key))
        });

        /// Returns the current playback position in seconds.
        /// @return any
        ///
        /// # Returns
        /// `number` — current position in seconds.
        methods.add_method("tell", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:tell")?;
            Ok(st.mixer.get_tell(key))
        });

        /// Seeks playback to `offset` seconds from the start.
        /// @param pos : number
        ///
        /// # Parameters
        /// - `offset` — `number`: Target position in seconds.
        methods.add_method("seek", |_, this, pos: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        });
        /// Applies a low-pass filter to the audio source.
        /// @param cutoff_hz : integer
        methods.add_method("setLowpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        });
        /// Applies a high-pass filter to the audio source.
        /// @param cutoff_hz : integer
        methods.add_method("setHighpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        });
        /// Returns the current low-pass filter cutoff frequency.
        /// @return any
        methods.add_method("getLowpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        });
        /// Returns the current high-pass filter cutoff frequency.
        /// @return any
        methods.add_method("getHighpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        });
        /// Removes any active filter from the audio source.
        methods.add_method("clearFilter", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        });
        /// Fades the audio source in from silence over the given duration.
        /// @param duration_secs : number
        methods.add_method("fadeIn", |_, this, duration_secs: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:fadeIn")?;
            st.mixer.set_fade_in(key, duration_secs);
            Ok(())
        });
        /// Returns the current fade-in duration.
        /// @return any
        methods.add_method("getFadeIn", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        });
    }
}

/// Lua UserData wrapper for an audio bus. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `BusKey`.
///
/// Wraps a `BusKey` and shared state reference so the Lua side
/// can call methods like `bus:setVolume()`, `bus:isPaused()` directly.
#[derive(Clone)]
pub struct LuaBus {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: BusKey,
}

impl LunaType for LuaBus {
    const TYPE_NAME: &'static str = "Bus";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the name of this audio bus.
        /// @return any
        methods.add_method("getName", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_bus(this.key) {
                Some(bus) => Ok(bus.name().to_string()),
                None => Err(mlua::Error::RuntimeError(
                    "Bus:getName(): invalid bus handle".into(),
                )),
            }
        });

        /// Sets the volume for all sources routed to this bus.
        /// @param vol : number
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_volume(vol);
            }
            Ok(())
        });

        /// Returns the current volume scale of this audio mixer bus.
        /// @return any
        ///
        /// # Returns
        /// Volume scale in the range 0.0 (silent) to 1.0 (full volume).
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.volume()))
        });

        /// Sets the pitch multiplier for all sources on this bus.
        /// @param pitch : number
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_pitch(pitch);
            }
            Ok(())
        });

        /// Returns the pitch multiplier of this bus.
        /// @return any
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.pitch()))
        });

        /// Pauses all audio sources that are currently playing through this bus.
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.pause();
            }
            Ok(())
        });

        /// Resumes all paused sources on this bus.
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.resume();
            }
            Ok(())
        });

        /// Returns whether this bus is currently paused.
        /// @return any
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).is_some_and(|b| b.is_paused()))
        });
    }
}

/// Lua UserData wrapper for the MIDI player.
///
/// # Fields
/// - `inner` — `Rc<RefCell<MidiPlayer>>`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// Wraps `MidiPlayer` in `Rc<RefCell<>>` so the Lua GC owns it.
/// All instance state lives directly in `MidiPlayer`.
#[derive(Clone)]
pub struct LuaMidiPlayer {
    pub(crate) inner: Rc<RefCell<MidiPlayer>>,
    pub(crate) state: Rc<RefCell<SharedState>>,
}

impl LunaType for LuaMidiPlayer {
    const TYPE_NAME: &'static str = "MidiPlayer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaMidiPlayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // File loading
        /// Loads a MIDI file from the given path and prepares it for playback.
        /// @param path : string
        /// @return any
        ///
        /// # Parameters
        /// - `path` — File path to the .mid MIDI file.
        methods.add_method("load", |_, this, path: String| {
            let st = this.state.borrow();
            let full_path = st.game_dir.join(&path);
            let result = this.inner.borrow_mut().load(&full_path);
            Ok(result)
        });

        /// Loads MIDI data from a Lua string directly into the player.
        /// @return any
        ///
        /// # Parameters
        /// - `data` — Raw MIDI bytes as a Lua string.
        methods.add_method("loadData", |_, this, data: mlua::String| {
            let bytes = data.as_bytes().to_vec();
            let result = this.inner.borrow_mut().load_data(bytes);
            Ok(result)
        });

        /// Returns whether a MIDI file or data string has been successfully loaded.
        /// @return any
        ///
        /// # Returns
        /// true if a sequence is loaded and ready to play.
        methods.add_method("isLoaded", |_, this, ()| {
            Ok(this.inner.borrow().is_loaded())
        });

        /// Returns the file path of the MIDI file currently loaded into the player.
        /// @return any
        ///
        /// # Returns
        /// Path string, or nil if no file is loaded.
        methods.add_method("getFilePath", |_, this, ()| {
            Ok(this.inner.borrow().file_path().map(|s| s.to_string()))
        });

        // SoundFont stubs
        /// Loads a SoundFont (.sf2) file into this player for instrument rendering.
        /// @param path : string
        ///
        /// # Parameters
        /// - `path` — File path to the .sf2 SoundFont file.
        methods.add_method("setSoundFont", |_, _this, _path: String| {
            log::debug!("stub: MidiPlayer:setSoundFont called");
            Ok(())
        });

        /// Returns the file path of the SoundFont (.sf2) currently loaded into the player.
        /// @return any
        ///
        /// # Returns
        /// Path string, or nil if using built-in defaults.
        methods.add_method("getSoundFontPath", |_, _this, ()| {
            log::debug!("stub: MidiPlayer:getSoundFontPath called");
            Ok(Option::<String>::None)
        });

        /// Reverts the player to using the built-in default SoundFont for rendering.
        methods.add_method("useDefaultSoundFont", |_, _this, ()| {
            log::debug!("stub: MidiPlayer:useDefaultSoundFont called");
            Ok(())
        });

        // Playback
        /// Plays the audio source from the beginning.
        methods.add_method("play", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(handle) = st.mixer.stream_handle() {
                this.inner.borrow_mut().play(handle);
            }
            Ok(())
        });

        /// Pauses the audio source at its current position.
        methods.add_method("pause", |_, this, ()| {
            this.inner.borrow_mut().pause();
            Ok(())
        });

        /// Stops playback of the audio source.
        methods.add_method("stop", |_, this, ()| {
            this.inner.borrow_mut().stop();
            Ok(())
        });

        /// Returns whether the audio source is currently playing.
        /// @return any
        methods.add_method("isPlaying", |_, this, ()| {
            Ok(this.inner.borrow().is_playing())
        });

        /// Returns whether the audio source is currently paused.
        /// @return any
        methods.add_method("isPaused", |_, this, ()| {
            Ok(this.inner.borrow().is_paused())
        });

        /// Seeks to the given time position (in seconds) in the source.
        /// @param secs : number
        methods.add_method("seek", |_, this, secs: f64| {
            this.inner.borrow_mut().seek(secs);
            Ok(())
        });

        /// Returns the current playback position in seconds.
        /// @return any
        methods.add_method("tell", |_, this, ()| Ok(this.inner.borrow().tell()));

        /// Returns the total duration of the audio source in seconds.
        /// @return any
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration())
        });

        /// Enables or disables looping playback for the source.
        /// @param looping : boolean
        methods.add_method("setLooping", |_, this, looping: bool| {
            this.inner.borrow_mut().set_looping(looping);
            Ok(())
        });

        /// Returns whether the audio source is set to loop.
        /// @return any
        methods.add_method("isLooping", |_, this, ()| {
            Ok(this.inner.borrow().is_looping())
        });

        // Volume / Bus
        /// Sets the playback volume (0.0 - 1.0) of the source.
        /// @param vol : number
        methods.add_method("setVolume", |_, this, vol: f32| {
            this.inner.borrow_mut().set_volume(vol);
            Ok(())
        });

        /// Returns the current volume of the audio source.
        /// @return any
        methods.add_method("getVolume", |_, this, ()| Ok(this.inner.borrow().volume()));

        /// Routes the MIDI player's synthesizer output through the given audio bus.
        /// @param bus_val : any
        ///
        /// # Parameters
        /// - `bus` — Bus object or bus name string.
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
            _ => Err(mlua::Error::RuntimeError(
                "MidiPlayer:setBus(): expected Bus or nil".into(),
            )),
        });

        /// Returns the audio bus that this MIDI player's output is routed through.
        /// @return any
        ///
        /// # Returns
        /// Bus object, or nil if no bus is assigned.
        methods.add_method("getBus", |_, this, ()| {
            let bus_key = this.inner.borrow().bus_key();
            match bus_key {
                Some(key) => Ok(Some(LuaBus {
                    state: this.state.clone(),
                    key,
                })),
                None => Ok(None),
            }
        });

        // Tempo
        /// Sets the playback tempo in beats per minute.
        /// @param bpm : number
        ///
        /// # Parameters
        /// - `bpm` — Tempo in beats per minute (e.g. 120).
        methods.add_method("setTempo", |_, this, bpm: f64| {
            let original = this.inner.borrow().original_tempo();
            if original > 0.0 {
                this.inner
                    .borrow_mut()
                    .set_tempo_scale((bpm / original) as f32);
            }
            Ok(())
        });

        /// Returns the current playback tempo in beats per minute.
        /// @return any
        ///
        /// # Returns
        /// Tempo as a number in BPM.
        methods.add_method("getTempo", |_, this, ()| {
            let mp = this.inner.borrow();
            Ok(mp.original_tempo() * mp.tempo_scale() as f64)
        });

        /// Returns the original tempo written in the MIDI file, in beats per minute.
        /// @return any
        ///
        /// # Returns
        /// Tempo in BPM.
        methods.add_method("getOriginalTempo", |_, this, ()| {
            Ok(this.inner.borrow().original_tempo())
        });

        /// Sets a multiplier applied to the original MIDI tempo during playback.
        /// @param scale : number
        ///
        /// # Parameters
        /// - `scale` — Tempo scale factor (1.0 = original speed, 2.0 = double speed).
        methods.add_method("setTempoScale", |_, this, scale: f32| {
            this.inner.borrow_mut().set_tempo_scale(scale);
            Ok(())
        });

        /// Returns the current tempo scale factor applied on top of the original BPM.
        /// @return any
        ///
        /// # Returns
        /// Tempo scale as a number (1.0 = original tempo).
        methods.add_method("getTempoScale", |_, this, ()| {
            Ok(this.inner.borrow().tempo_scale())
        });

        /// Returns the ticks-per-beat (PPQ) resolution defined in the MIDI file header.
        /// @return any
        ///
        /// # Returns
        /// Ticks per beat as an integer.
        methods.add_method("getTicksPerBeat", |_, this, ()| {
            Ok(this.inner.borrow().ticks_per_beat())
        });

        // Channel control (1-indexed in Lua, 0-indexed internally)
        /// Sets the volume scale for the specified MIDI channel.
        /// @param ch : integer
        /// @param vol : number
        ///
        /// # Parameters
        /// - `channel` — 1-based MIDI channel (1-16).
        /// - `volume` — Volume scale in [0.0, 1.0].
        methods.add_method("setChannelVolume", |_, this, (ch, vol): (usize, f32)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_volume(ch - 1, vol);
            }
            Ok(())
        });

        /// Returns the current volume scale applied to the given MIDI channel.
        /// @param ch : integer
        /// @return any
        ///
        /// # Parameters
        /// - `channel` — 1-based MIDI channel number (1-16).
        ///
        /// # Returns
        /// Volume scale in [0.0, 1.0].
        methods.add_method("getChannelVolume", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_volume(ch - 1))
            } else {
                Ok(0.0)
            }
        });

        /// Mutes or unmutes the given MIDI channel for selective playback.
        /// @param ch : integer
        /// @param muted : boolean
        ///
        /// # Parameters
        /// - `channel` — 1-based MIDI channel (1-16).
        /// - `muted` — true to silence the channel, false to unmute.
        methods.add_method("setChannelMuted", |_, this, (ch, muted): (usize, bool)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_muted(ch - 1, muted);
            }
            Ok(())
        });

        /// Returns whether the given MIDI channel is currently muted.
        /// @param ch : integer
        /// @return boolean
        ///
        /// # Parameters
        /// - `channel` — 1-based MIDI channel number (1-16).
        ///
        /// # Returns
        /// true if the channel is muted, false otherwise.
        methods.add_method("isChannelMuted", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().is_channel_muted(ch - 1))
            } else {
                Ok(false)
            }
        });

        methods.add_method(
            "setChannelInstrument",
            |_, this, (ch, inst): (usize, u8)| {
                if (1..=16).contains(&ch) {
                    this.inner.borrow_mut().set_channel_instrument(ch - 1, inst);
                }
                Ok(())
            },
        );

        /// Returns the General MIDI instrument index for the given MIDI channel.
        /// @param ch : integer
        /// @return any
        ///
        /// # Parameters
        /// - `channel` — 1-based MIDI channel number (1-16).
        ///
        /// # Returns
        /// GM instrument index (0-127).
        methods.add_method("getChannelInstrument", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_instrument(ch - 1))
            } else {
                Ok(0u8)
            }
        });

        /// Returns the number of MIDI channels present in the loaded sequence.
        /// @return any
        ///
        /// # Returns
        /// Channel count as an integer.
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.borrow().channel_count())
        });

        /// Solos the given MIDI channel so it is the only one producing sound.
        /// @param ch : integer
        ///
        /// # Parameters
        /// - `channel` — 1-based MIDI channel (1-16).
        /// - `solo` — true to solo, false to clear solo.
        methods.add_method("soloChannel", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().solo_channel(ch - 1);
            }
            Ok(())
        });

        /// Clears the solo flag on every track so all tracks are audible.
        methods.add_method("unsoloAll", |_, this, ()| {
            this.inner.borrow_mut().unsolo_all();
            Ok(())
        });

        // Track control (1-indexed in Lua)
        /// Returns the total number of tracks in the loaded MIDI sequence.
        /// @return any
        ///
        /// # Returns
        /// Track count as an integer.
        methods.add_method("getTrackCount", |_, this, ()| {
            Ok(this.inner.borrow().track_count())
        });

        /// Returns the name string of the given MIDI track from the sequence metadata.
        /// @param idx : integer
        /// @return any
        ///
        /// # Parameters
        /// - `track` — 1-based track index.
        ///
        /// # Returns
        /// Track name string, or nil if no name is set.
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

        /// Mutes or unmutes a specific track by index for selective rendering.
        /// @param idx : integer
        /// @param muted : boolean
        ///
        /// # Parameters
        /// - `track` — 1-based track index.
        /// - `muted` — true to silence the track, false to enable it.
        methods.add_method("setTrackMuted", |_, this, (idx, muted): (usize, bool)| {
            if idx >= 1 {
                this.inner.borrow_mut().set_track_muted(idx - 1, muted);
            }
            Ok(())
        });

        /// Returns whether the given track index is currently muted.
        /// @param idx : integer
        /// @return boolean
        ///
        /// # Parameters
        /// - `track` — 1-based track index.
        ///
        /// # Returns
        /// true if the track is muted, false otherwise.
        methods.add_method("isTrackMuted", |_, this, idx: usize| {
            if idx >= 1 {
                Ok(this.inner.borrow().is_track_muted(idx - 1))
            } else {
                Ok(false)
            }
        });

        /// Returns the total number of note events in the loaded MIDI sequence.
        /// @return any
        ///
        /// # Returns
        /// Note count as an integer.
        methods.add_method("getNoteCount", |_, this, ()| {
            Ok(this.inner.borrow().note_count())
        });

        // Callback stubs
        /// Registers a callback invoked for each MIDI note-on event during playback.
        /// @param cb : any
        ///
        /// # Parameters
        /// - `callback` — Function called as callback(channel, note, velocity).
        methods.add_method("setOnNoteOn", |_, _this, _cb: LuaValue| {
            log::debug!("stub: MidiPlayer:setOnNoteOn called");
            Ok(())
        });

        /// Registers a callback invoked for each MIDI note-off event during playback.
        /// @param cb : any
        ///
        /// # Parameters
        /// - `callback` — Function called as callback(channel, note, velocity).
        methods.add_method("setOnNoteOff", |_, _this, _cb: LuaValue| {
            log::debug!("stub: MidiPlayer:setOnNoteOff called");
            Ok(())
        });

        /// Registers a callback invoked when the MIDI sequence finishes playing.
        /// @param cb : any
        ///
        /// # Parameters
        /// - `callback` — Function called with no arguments when playback ends.
        methods.add_method("setOnEnd", |_, _this, _cb: LuaValue| {
            log::debug!("stub: MidiPlayer:setOnEnd called");
            Ok(())
        });
    }
}

/// Extract a `SoundKey` from either a `LuaSource` UserData or a numeric ID.
fn sound_key_from_value(val: &LuaValue) -> LuaResult<SoundKey> {
    match val {
        LuaValue::UserData(ud) => {
            let src = ud.borrow::<LuaSource>()?;
            Ok(src.key)
        }
        LuaValue::Integer(id) => Ok(SoundKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(SoundKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(mlua::Error::RuntimeError(
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

/// Lua UserData wrapper for a streaming audio `Decoder`.
///
/// # Fields
/// - `inner` — `Decoder`.
pub struct LuaDecoder {
    inner: Decoder,
}

impl LuaUserData for LuaDecoder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Decode the next chunk of audio samples.
        ///
        /// # Returns
        /// SoundData userdata or nil at EOF.
        methods.add_method_mut("decode", |lua, this, ()| {
            match this.inner.decode() {
                Some(pcm_i16) => {
                    let samples: Vec<f32> =
                        pcm_i16.iter().map(|&s| s as f32 / 32768.0).collect();
                    let sd = crate::audio::SoundData::from_samples(
                        samples,
                        this.inner.sample_rate,
                        this.inner.channels,
                    );
                    Ok(LuaValue::UserData(lua.create_userdata(sd)?))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// Return the number of audio channels.
        ///
        /// # Returns
        /// `u32`.
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.channels as u32)
        });

        /// Return the bit depth.
        ///
        /// # Returns
        /// `u32`.
        methods.add_method("getBitDepth", |_, this, ()| {
            Ok(this.inner.bit_depth as u32)
        });

        /// Return the sample rate in Hz.
        ///
        /// # Returns
        /// `u32`.
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.inner.sample_rate));

        /// Return the total duration in seconds.
        ///
        /// # Returns
        /// `f64`.
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.get_duration())
        });

        /// Seek to a time offset in seconds.
        ///
        /// # Parameters
        /// - `offset` — `f64`.
        methods.add_method_mut("seek", |_, this, offset: f64| {
            this.inner.seek(offset);
            Ok(())
        });

        /// Rewind to the beginning.
        methods.add_method_mut("rewind", |_, this, ()| {
            this.inner.rewind();
            Ok(())
        });

        /// Release the decoder (no-op in the current model).
        methods.add_method("release", |_, _, ()| Ok(()));
    }
}

/// Registers all `luna.audio.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let audio = lua.create_table()?;

    // luna.audio.newSource(path, type?) -> source_id
    // type = "static" or "stream" (default)
    /// Loads an audio file and returns a source handle.
    let s = state.clone();
    /// @param args : MultiValue
    /// @return any
    audio.set(
        "newSource",
        lua.create_function(move |_, args: LuaMultiValue| {
            let path: String = args
                .get(0)
                .and_then(|v| match v {
                    LuaValue::String(s) => Some(s.to_str().ok()?.to_string()),
                    _ => None,
                })
                .ok_or_else(|| {
                    mlua::Error::RuntimeError("luna.audio.newSource: path required".into())
                })?;

            let source_type = args
                .get(1)
                .and_then(|v| match v {
                    LuaValue::String(s) => Some(s.to_str().ok()?.to_string()),
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

    // luna.audio.play(source_id)
    /// Plays the audio source from the beginning.
    let s = state.clone();
    /// @param id_val : any
    audio.set(
        "play",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.play")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play(key, &game_dir);
            Ok(())
        })?,
    )?;

    // luna.audio.stop(source_id)
    /// Stops playback of the audio source.
    let s = state.clone();
    /// @param id_val : any
    audio.set(
        "stop",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.stop")?;
            st.mixer.stop(key);
            Ok(())
        })?,
    )?;

    // luna.audio.setVolume(source_id, volume)
    /// Sets the playback volume (0.0 - 1.0) of the source.
    let s = state.clone();
    /// @param id_val : any
    /// @param vol : number
    audio.set(
        "setVolume",
        lua.create_function(move |_, (id_val, vol): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        })?,
    )?;

    // luna.audio.getVolume(source_id) -> volume
    /// Returns the current volume of the audio source.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getVolume",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getVolume")?;
            Ok(st.mixer.get_volume(key))
        })?,
    )?;

    // luna.audio.pause(source_id)
    /// Pauses the audio source at its current position.
    let s = state.clone();
    /// @param id_val : any
    audio.set(
        "pause",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.pause")?;
            st.mixer.pause(key);
            Ok(())
        })?,
    )?;

    // luna.audio.resume(source_id)
    /// Resumes playback of a paused audio source from its current position.
    ///
    /// # Parameters
    /// - `source` — Audio source ID to resume.
    let s = state.clone();
    /// @param id_val : any
    audio.set(
        "resume",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.resume")?;
            st.mixer.resume(key);
            Ok(())
        })?,
    )?;

    // luna.audio.setPitch(source_id, pitch)
    /// Sets the pitch (playback speed) multiplier of the source.
    let s = state.clone();
    /// @param id_val : any
    /// @param pitch : number
    audio.set(
        "setPitch",
        lua.create_function(move |_, (id_val, pitch): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        })?,
    )?;

    // luna.audio.getPitch(source_id) -> pitch
    /// Returns the current pitch multiplier of the source.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getPitch",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getPitch")?;
            Ok(st.mixer.get_pitch(key))
        })?,
    )?;

    // luna.audio.isPlaying(source_id) -> bool
    /// Returns whether the audio source is currently playing.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "isPlaying",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.isPlaying")?;
            Ok(st.mixer.is_playing(key))
        })?,
    )?;

    // luna.audio.isPaused(source_id) -> bool
    /// Returns whether the audio source is currently paused.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "isPaused",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.isPaused")?;
            Ok(st.mixer.is_paused(key))
        })?,
    )?;

    // luna.audio.isStopped(source_id) -> bool
    /// Returns whether the audio source is stopped.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "isStopped",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.isStopped")?;
            Ok(st.mixer.is_stopped(key))
        })?,
    )?;

    // luna.audio.setLooping(source_id, looping)
    /// Enables or disables looping playback for the source.
    let s = state.clone();
    /// @param id_val : any
    /// @param looping : boolean
    audio.set(
        "setLooping",
        lua.create_function(move |_, (id_val, looping): (LuaValue, bool)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        })?,
    )?;

    // luna.audio.isLooping(source_id) -> bool
    /// Returns whether the audio source is set to loop.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "isLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.isLooping")?;
            Ok(st.mixer.is_looping(key))
        })?,
    )?;

    // luna.audio.playLooping(source_id)
    /// Plays the audio source in a continuous loop.
    let s = state.clone();
    /// @param id_val : any
    audio.set(
        "playLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.playLooping")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play_looping(key, &game_dir);
            Ok(())
        })?,
    )?;

    // luna.audio.setPan(source_id, pan)
    /// Sets the stereo panning (-1.0 left to 1.0 right) of the source.
    let s = state.clone();
    /// @param id_val : any
    /// @param pan : number
    audio.set(
        "setPan",
        lua.create_function(move |_, (id_val, pan): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        })?,
    )?;

    // luna.audio.getPan(source_id) -> pan
    /// Returns the current stereo panning of the source.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getPan",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getPan")?;
            Ok(st.mixer.get_pan(key))
        })?,
    )?;

    // luna.audio.setMasterVolume(volume)
    /// Sets the global master volume (0.0 - 1.0).
    let s = state.clone();
    /// @param vol : number
    audio.set(
        "setMasterVolume",
        lua.create_function(move |_, vol: f32| {
            s.borrow_mut().mixer.set_master_volume(vol);
            Ok(())
        })?,
    )?;

    // luna.audio.getMasterVolume() -> volume
    /// Returns the current master volume scale (0.0 - 1.0) applied to all audio output.
    ///
    /// # Returns
    /// Master volume as a float in [0.0, 1.0].
    let s = state.clone();
    /// @return any
    audio.set(
        "getMasterVolume",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_master_volume()))?,
    )?;

    // luna.audio.getActiveSourceCount() -> number
    /// Returns the number of currently playing audio sources.
    let s = state.clone();
    /// @return any
    audio.set(
        "getActiveSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_active_source_count()))?,
    )?;

    // luna.audio.getSourceCount() -> number
    /// Returns the number of currently registered audio sources.
    let s = state.clone();
    /// @return any
    audio.set(
        "getSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_source_count()))?,
    )?;

    // luna.audio.getSourceType(source_id) -> "static" or "stream"
    /// Returns the type string ('static' or 'stream') of the source.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getSourceType",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let st = s.borrow();
            match st.mixer.get_source_type(key) {
                Some(SourceType::Static) => Ok("static".to_string()),
                Some(SourceType::Stream) => Ok("stream".to_string()),
                None => Err(mlua::Error::RuntimeError(
                    "luna.audio.getSourceType: invalid source handle".into(),
                )),
            }
        })?,
    )?;

    // luna.audio.clone(source_id) -> new_source_id
    /// Creates an independent copy of an audio source.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "clone",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            match st.mixer.clone_source(key) {
                Some(new_key) => Ok(LuaSource {
                    state: s.clone(),
                    key: new_key,
                }),
                None => Err(mlua::Error::RuntimeError(
                    "luna.audio.clone: invalid source handle".into(),
                )),
            }
        })?,
    )?;

    // luna.audio.pauseAll()
    /// Pauses all currently playing audio sources.
    let s = state.clone();
    audio.set(
        "pauseAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.pause_all();
            Ok(())
        })?,
    )?;

    // luna.audio.stopAll()
    /// Stops all currently playing audio sources.
    let s = state.clone();
    audio.set(
        "stopAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.stop_all();
            Ok(())
        })?,
    )?;

    // luna.audio.resumeAll()
    /// Resumes playback on every audio source that is currently paused.
    let s = state.clone();
    audio.set(
        "resumeAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.resume_all();
            Ok(())
        })?,
    )?;

    // luna.audio.release(source_id) -> bool
    /// Releases the audio source and frees its memory.
    let s = state.clone();
    /// @param id_val : any
    /// @return boolean
    audio.set(
        "release",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            if st.mixer.release(key) {
                Ok(true)
            } else {
                Err(mlua::Error::RuntimeError(
                    "luna.audio.release: invalid or already-released audio source handle".into(),
                ))
            }
        })?,
    )?;

    // luna.audio.newBus(name) -> LuaBus
    /// Creates a named audio bus for grouping sources.
    let s = state.clone();
    /// @param name : string
    /// @return any
    audio.set(
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

    // luna.audio.setSourceBus(source, bus)
    /// Assigns the source to a named audio bus.
    let s = state.clone();
    /// @param id_val : any
    /// @param bus_val : any
    audio.set(
        "setSourceBus",
        lua.create_function(move |_, (id_val, bus_val): (LuaValue, LuaValue)| {
            let key = sound_key_from_value(&id_val)?;
            let bus_key = match &bus_val {
                LuaValue::UserData(ud) => {
                    let bus = ud.borrow::<LuaBus>()?;
                    Some(bus.key)
                }
                _ => {
                    return Err(mlua::Error::RuntimeError(
                        "luna.audio.setSourceBus: expected Bus userdata".into(),
                    ));
                }
            };
            s.borrow_mut().mixer.set_source_bus(key, bus_key);
            Ok(())
        })?,
    )?;

    // luna.audio.getSourceBus(source) -> LuaBus or nil
    /// Returns the bus name the source is assigned to.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
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

    // luna.audio.getMaxSources() -> 64
    /// Returns the maximum number of simultaneous audio sources.
    audio.set("getMaxSources", lua.create_function(|_, ()| Ok(64))?)?;

    // luna.audio.setListener2D(x, y) — keeps backward compat alias
    /// Sets the 2D listener position for spatial audio.
    /// @param x : number
    /// @param y : number
    let s = state.clone();
    audio.set(
        "setListener2D",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mixer.set_listener_position(x, y, 0.0);
            Ok(())
        })?,
    )?;

    // luna.audio.getListener2D() -> x, y  (backward compat)
    /// Returns the current 2D listener position (x, y).
    /// @return any
    let s = state.clone();
    audio.set(
        "getListener2D",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1]))
        })?,
    )?;

    // luna.audio.setListener(x, y, z?) — 3D listener position
    /// Sets the 3D listener position for spatial audio.
    /// @param x : number
    /// @param y : number
    /// @param z : number?
    let s = state.clone();
    audio.set(
        "setListener",
        lua.create_function(move |_, (x, y, z): (f32, f32, Option<f32>)| {
            s.borrow_mut().mixer.set_listener_position(x, y, z.unwrap_or(0.0));
            Ok(())
        })?,
    )?;

    // luna.audio.getListener() -> x, y, z
    /// Returns the 3D listener position.
    /// @return any
    let s = state.clone();
    audio.set(
        "getListener",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;

    // luna.audio.setPosition(source_id, x, y, z?)
    /// Sets the 3D position of an audio source for spatial panning.
    /// @param id_val : any
    /// @param x : number
    /// @param y : number
    /// @param z : number?
    let s = state.clone();
    audio.set(
        "setPosition",
        lua.create_function(move |_, (id_val, x, y, z): (LuaValue, f32, f32, Option<f32>)| {
            let key = sound_key_from_value(&id_val)?;
            s.borrow_mut().mixer.set_source_position(key, x, y, z.unwrap_or(0.0));
            Ok(())
        })?,
    )?;

    // luna.audio.getPosition(source_id) -> x, y, z
    /// Returns the 3D position of an audio source.
    /// @param id_val : any
    /// @return any
    let s = state.clone();
    audio.set(
        "getPosition",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let pos = s.borrow().mixer.get_source_position(key);
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;

    // luna.audio.setVelocity(source_id, x, y, z?)
    /// Sets the velocity of an audio source for Doppler calculation.
    /// @param id_val : any
    /// @param x : number
    /// @param y : number
    /// @param z : number?
    let s = state.clone();
    audio.set(
        "setVelocity",
        lua.create_function(move |_, (id_val, x, y, z): (LuaValue, f32, f32, Option<f32>)| {
            let key = sound_key_from_value(&id_val)?;
            s.borrow_mut().mixer.set_source_velocity(key, x, y, z.unwrap_or(0.0));
            Ok(())
        })?,
    )?;

    // luna.audio.getVelocity(source_id) -> x, y, z
    /// Returns the velocity of an audio source.
    /// @param id_val : any
    /// @return any
    let s = state.clone();
    audio.set(
        "getVelocity",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let vel = s.borrow().mixer.get_source_velocity(key);
            Ok((vel[0], vel[1], vel[2]))
        })?,
    )?;

    // luna.audio.setOrientation(source_id, fx, fy, fz, ux, uy, uz)
    /// Sets the orientation of an audio source.
    /// @param id_val : any
    /// @param fx : number
    /// @param fy : number
    /// @param fz : number
    /// @param ux : number
    /// @param uy : number
    /// @param uz : number
    let s = state.clone();
    audio.set(
        "setOrientation",
        lua.create_function(
            move |_, (id_val, fx, fy, fz, ux, uy, uz): (LuaValue, f32, f32, f32, f32, f32, f32)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut().mixer.set_source_orientation(key, fx, fy, fz, ux, uy, uz);
                Ok(())
            },
        )?,
    )?;

    // luna.audio.getOrientation(source_id) -> fx, fy, fz, ux, uy, uz
    /// Returns the 6-component orientation of an audio source.
    /// @param id_val : any
    /// @return any
    let s = state.clone();
    audio.set(
        "getOrientation",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let o = s.borrow().mixer.get_source_orientation(key);
            Ok((o[0], o[1], o[2], o[3], o[4], o[5]))
        })?,
    )?;

    // luna.audio.setDopplerScale(scale)
    /// Sets the global Doppler effect scale (1.0 = default).
    /// @param scale : number
    let s = state.clone();
    audio.set(
        "setDopplerScale",
        lua.create_function(move |_, scale: f32| {
            s.borrow_mut().mixer.set_doppler_scale(scale);
            Ok(())
        })?,
    )?;

    // luna.audio.getDopplerScale() -> scale
    /// Returns the current global Doppler scale.
    /// @return any
    let s = state.clone();
    audio.set(
        "getDopplerScale",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_doppler_scale()))?,
    )?;

    // luna.audio.setDistanceModel(model)
    /// Sets the distance attenuation model.
    /// @param model : string
    let s = state.clone();
    audio.set(
        "setDistanceModel",
        lua.create_function(move |_, model: String| {
            s.borrow_mut().mixer.set_distance_model(&model);
            Ok(())
        })?,
    )?;

    // luna.audio.getDistanceModel() -> model
    /// Returns the current distance attenuation model name.
    /// @return any
    let s = state.clone();
    audio.set(
        "getDistanceModel",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_distance_model().to_string()))?,
    )?;

    // luna.audio.setMeter(scale) — stub
    /// Enables or disables peak metering on the audio source.
    /// @param scale : number
    audio.set(
        "setMeter",
        lua.create_function(|_, _scale: f32| {
            log::debug!("stub: luna.audio.setMeter called");
            Ok(())
        })?,
    )?;

    // luna.audio.getMeter() -> 1.0 — stub
    /// Returns the current peak level of the audio source.
    /// @return any
    audio.set(
        "getMeter",
        lua.create_function(|_, ()| {
            log::debug!("stub: luna.audio.getMeter called");
            Ok(1.0_f32)
        })?,
    )?;

    // luna.audio.newMidiPlayer([path?]) -> LuaMidiPlayer
    /// Creates a software MIDI synthesizer player.
    let s = state.clone();
    /// @param path : string?
    /// @return any
    audio.set(
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

    // luna.audio.getDuration(source_id) -> number | nil
    /// Returns the total duration of the audio source in seconds.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getDuration",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getDuration")?;
            Ok(st.mixer.get_duration(key))
        })?,
    )?;

    // luna.audio.tell(source_id) -> number
    /// Returns the current playback position in seconds.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "tell",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.tell")?;
            Ok(st.mixer.get_tell(key))
        })?,
    )?;

    // luna.audio.seek(source_id, position)
    /// Seeks to the given time position (in seconds) in the source.
    let s = state.clone();
    /// @param id_val : any
    /// @param pos : number
    audio.set(
        "seek",
        lua.create_function(move |_, (id_val, pos): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        })?,
    )?;

    // luna.audio.setLowpass(source_id, cutoff_hz)
    /// Applies a low-pass filter to the audio source.
    let s = state.clone();
    /// @param id_val : any
    /// @param cutoff_hz : integer
    audio.set(
        "setLowpass",
        lua.create_function(move |_, (id_val, cutoff_hz): (LuaValue, u32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        })?,
    )?;
    // luna.audio.setHighpass(source_id, cutoff_hz)
    /// Applies a high-pass filter to the audio source.
    let s = state.clone();
    /// @param id_val : any
    /// @param cutoff_hz : integer
    audio.set(
        "setHighpass",
        lua.create_function(move |_, (id_val, cutoff_hz): (LuaValue, u32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        })?,
    )?;
    // luna.audio.getLowpass(source_id) -> number | nil
    /// Returns the current low-pass filter cutoff frequency.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getLowpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        })?,
    )?;
    // luna.audio.getHighpass(source_id) -> number | nil
    /// Returns the current high-pass filter cutoff frequency.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getHighpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        })?,
    )?;
    // luna.audio.clearFilter(source_id)
    /// Removes any active filter from the audio source.
    let s = state.clone();
    /// @param id_val : any
    audio.set(
        "clearFilter",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        })?,
    )?;
    // luna.audio.fadeIn(source_id, duration_secs)
    /// Fades the audio source in from silence over the given duration.
    let s = state.clone();
    /// @param id_val : any
    /// @param dur : number
    audio.set(
        "fadeIn",
        lua.create_function(move |_, (id_val, dur): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "luna.audio.fadeIn")?;
            st.mixer.set_fade_in(key, dur);
            Ok(())
        })?,
    )?;
    // luna.audio.getFadeIn(source_id) -> number | nil
    /// Returns the current fade-in duration.
    let s = state.clone();
    /// @param id_val : any
    /// @return any
    audio.set(
        "getFadeIn",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "luna.audio.getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        })?,
    )?;

    // ── Moved from luna.sound ──────────────────────────────────────────────

    // luna.sound.newSoundData(filename) or luna.sound.newSoundData(sampleCount, sampleRate?, channels?)
    /// Creates a raw PCM audio buffer for building procedurally generated sound.
    ///
    /// # Parameters
    /// - `samples` — Total number of PCM samples to allocate.
    /// - `sampleRate` — Sample rate in Hz (e.g. 44100).
    /// - `bitDepth` — Bit depth per sample (8 or 16).
    /// - `channels` — Number of channels (1 = mono, 2 = stereo).
    ///
    /// # Returns
    /// New SoundData object ID.
    let state_clone = state.clone();
    /// @param args : MultiValue
    audio.set(
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
    /// Sets the SoundFont (.sf2) file that the MIDI synthesizer uses for instrument samples.
    ///
    /// # Parameters
    /// - `path` — File path to the .sf2 SoundFont file.
    let state_clone = state.clone();
    /// @param path : string
    audio.set(
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
    /// Returns whether a SoundFont is currently loaded for the MIDI synthesizer.
    ///
    /// # Returns
    /// true if a SoundFont is loaded, false otherwise.
    let state_clone = state.clone();
    /// @return any
    audio.set(
        "hasMidiSoundFont",
        lua.create_function(move |_, ()| {
            let st = state_clone.borrow();
            Ok(st.midi_state.has_soundfont())
        })?,
    )?;

    // luna.sound.clearMidiSoundFont()
    /// Unloads the active SoundFont so the MIDI player falls back to built-in defaults.
    let state_clone = state.clone();
    audio.set(
        "clearMidiSoundFont",
        lua.create_function(move |_, ()| {
            let mut st = state_clone.borrow_mut();
            st.midi_state.clear_soundfont();
            Ok(())
        })?,
    )?;
    // luna.audio.newDecoder(source, buffersize?) -> Decoder userdata
    /// Creates a streaming audio decoder for chunked PCM reading.
    ///
    /// # Parameters
    /// - `source` — File path to the audio file.
    /// - `buffersize` — Optional number of samples per chunk (default 2048).
    ///
    /// # Returns
    /// Decoder userdata.
    let state_clone = state.clone();
    /// @param source : string
    /// @param buffersize : number?
    /// @return any
    audio.set(
        "newDecoder",
        lua.create_function(move |_, (source, buffersize): (String, Option<usize>)| {
            let st = state_clone.borrow();
            let path = st.game_dir.join(&source);
            let path_str = path.to_str().ok_or_else(|| {
                LuaError::RuntimeError("Invalid path".to_string())
            })?;
            let buf = buffersize.unwrap_or(2048);
            let decoder = Decoder::from_file(path_str, buf)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            Ok(LuaDecoder { inner: decoder })
        })?,
    )?;

    /// Audio.
    luna.set("audio", audio)?;
    Ok(())
}
