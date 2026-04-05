//! `luna.audio` Lua API bindings.
//!
//! Auto-generated skeleton from `src/audio/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaAtomicParam ────────────────────────────────────────────────────────────

pub struct LuaAtomicParam(/* TODO: add key + state fields */);


impl LuaAtomicParam {
    /// Returns the current value, loaded with `Relaxed` ordering.
    ///
    ///
    /// @return number
    pub fn get(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Stores a new value with `Relaxed` ordering.
    ///
    ///
    /// @param val : number
    pub fn set(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaAtomicParam {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("get", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("set", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaBus ────────────────────────────────────────────────────────────

pub struct LuaBus(/* TODO: add key + state fields */);


impl LuaBus {
    /// Returns the bus volume (always `>= 0.0`).
    ///
    ///
    /// @return number
    pub fn volume(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the bus pitch multiplier (always `>= 0.0`).
    ///
    ///
    /// @return number
    pub fn pitch(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the bus is paused. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_paused(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaBus {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("volume", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("pitch", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isPaused", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDecoder ────────────────────────────────────────────────────────────

pub struct LuaDecoder(/* TODO: add key + state fields */);


impl LuaDecoder {
    /// Return the total duration in seconds.
    ///
    ///
    /// @return number
    pub fn get_duration(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return the current playback position in seconds.
    ///
    ///
    /// @return number
    pub fn tell(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether this decoder supports seeking.
    ///
    /// Always `true` because PCM data is fully buffered in memory.
    ///
    ///
    /// @return boolean
    pub fn is_seekable(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDecoder {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getDuration", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tell", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isSeekable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMidiPlayer ────────────────────────────────────────────────────────────

pub struct LuaMidiPlayer(/* TODO: add key + state fields */);


impl LuaMidiPlayer {
    /// Returns whether a MIDI file is currently loaded.
    ///
    ///
    /// @return boolean
    pub fn is_loaded(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the file path of the loaded MIDI, if any.
    ///
    ///
    /// @return Option<
    pub fn file_path(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the player is currently playing.
    ///
    ///
    /// @return boolean
    pub fn is_playing(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the player is paused. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_paused(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current playback position in seconds.
    ///
    ///
    /// @return number
    pub fn tell(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the duration of the loaded MIDI in seconds.
    ///
    ///
    /// @return number
    pub fn duration(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the master volume. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return number
    pub fn volume(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether playback is set to loop.
    ///
    ///
    /// @return boolean
    pub fn is_looping(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current tempo scale factor. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return number
    pub fn tempo_scale(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current effective BPM. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return number
    pub fn current_bpm(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the original tempo in BPM from the MIDI file.
    ///
    ///
    /// @return number
    pub fn original_tempo(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the ticks-per-beat value from the MIDI header.
    ///
    ///
    /// @return u16
    pub fn ticks_per_beat(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the volume for a specific MIDI channel (0-15).
    ///
    /// @param ch : integer
    /// @return number
    pub fn channel_volume(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether a specific MIDI channel (0-15) is muted.
    ///
    /// @param ch : integer
    /// @return boolean
    pub fn is_channel_muted(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the instrument (program number) for a MIDI channel (0-15).
    ///
    /// @param ch : integer
    /// @return u8
    pub fn channel_instrument(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of unique MIDI channels used in the loaded file.
    ///
    ///
    /// @return integer
    pub fn channel_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of tracks in the loaded MIDI file.
    ///
    ///
    /// @return integer
    pub fn track_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the name of a track by index, if it has one.
    ///
    /// @param idx : integer
    /// @return Option<
    pub fn track_name(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether a specific track is muted.
    ///
    /// @param idx : integer
    /// @return boolean
    pub fn is_track_muted(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of NoteOn events in the loaded MIDI.
    ///
    ///
    /// @return integer
    pub fn note_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the audio bus key, if assigned. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return BusKey?
    pub fn bus_key(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current playback state. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return PlayState
    pub fn play_state(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMidiPlayer {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isLoaded", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("filePath", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isPlaying", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isPaused", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tell", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("duration", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("volume", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isLooping", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tempoScale", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("currentBpm", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("originalTempo", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("ticksPerBeat", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("channelVolume", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isChannelMuted", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("channelInstrument", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("channelCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("trackCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("trackName", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isTrackMuted", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("noteCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("busKey", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("playState", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMidiState ────────────────────────────────────────────────────────────

pub struct LuaMidiState(/* TODO: add key + state fields */);


impl LuaMidiState {
    /// Check whether a SoundFont is currently loaded.
    ///
    ///
    /// @return boolean
    pub fn has_soundfont(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the path of the loaded SoundFont, if any.
    ///
    ///
    /// @return Option<
    pub fn soundfont_path(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get a reference to the raw SoundFont data, if loaded.
    ///
    ///
    /// @return Option<
    pub fn soundfont_data(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMidiState {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("hasSoundfont", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("soundfontPath", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("soundfontData", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMixer ────────────────────────────────────────────────────────────

pub struct LuaMixer(/* TODO: add key + state fields */);


impl LuaMixer {
    /// Returns a reference to the output stream handle, if available.
    ///
    ///
    /// @return Option<
    pub fn stream_handle(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the per-source playback volume. Defaults to `1.0`.
    ///
    /// @param key : SoundKey
    /// @return number
    pub fn get_volume(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the pitch (playback speed) for the source. Defaults to `1.0`.
    ///
    /// @param key : SoundKey
    /// @return number
    pub fn get_pitch(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the audio source is currently playing (not paused and not empty).
    ///
    /// @param key : SoundKey
    /// @return boolean
    pub fn is_playing(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the playback state of the source, synced with the underlying sink.
    ///
    /// @param key : SoundKey
    /// @return PlayState
    pub fn get_play_state(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the source is paused. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// @param key : SoundKey
    /// @return boolean
    pub fn is_paused(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the source is stopped. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// @param key : SoundKey
    /// @return boolean
    pub fn is_stopped(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the source is set to loop.
    ///
    /// @param key : SoundKey
    /// @return boolean
    pub fn is_looping(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the stereo pan for the source. Defaults to `0.0` (center).
    ///
    /// @param key : SoundKey
    /// @return number
    pub fn get_pan(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the master volume. Defaults to `1.0`.
    ///
    ///
    /// @return number
    pub fn get_master_volume(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the source type for the given key.
    ///
    /// @param key : SoundKey
    /// @return SourceType?
    pub fn get_source_type(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of actively playing (not paused, not empty) sources.
    ///
    ///
    /// @return integer
    pub fn get_active_source_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of loaded sources.
    ///
    ///
    /// @return integer
    pub fn get_source_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the given source key still refers to a loaded audio source.
    ///
    /// @param key : SoundKey
    /// @return boolean
    pub fn contains_source(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns an immutable reference to the bus, if it exists.
    ///
    /// @param key : BusKey
    /// @return Option<
    pub fn get_bus_by_name(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Gets a bus by key.
    ///
    ///
    /// @return Option<
    pub fn get_bus(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the bus key assigned to a source, if any.
    ///
    /// @param key : SoundKey
    /// @return BusKey?
    pub fn get_source_bus(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the cached duration of the audio source in seconds, if known.
    ///
    /// @param key : SoundKey
    /// @return number?
    pub fn get_duration(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the approximate current playback position in seconds.
    ///
    /// @param key : SoundKey
    /// @return number
    pub fn get_tell(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the lowpass cutoff frequency in Hz, if set.
    ///
    /// @param key : SoundKey
    /// @return integer?
    pub fn get_lowpass(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the highpass cutoff frequency in Hz, if set.
    ///
    /// @param key : SoundKey
    /// @return integer?
    pub fn get_highpass(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the fade-in duration in seconds, if set.
    ///
    /// @param key : SoundKey
    /// @return number?
    pub fn get_fade_in(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the 3D spatial position of an audio source.
    ///
    ///
    /// @param key : SoundKey
    pub fn get_source_position(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the spatial velocity of an audio source.
    ///
    ///
    /// @param key : SoundKey
    pub fn get_source_velocity(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the spatial orientation of an audio source.
    ///
    ///
    /// @param key : SoundKey
    pub fn get_source_orientation(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the global Doppler effect scale.
    ///
    ///
    /// @return number
    pub fn get_doppler_scale(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of free buffer slots for a queueable source.
    ///
    /// @param key : QueueableKey
    /// @return integer
    pub fn queueable_free_buffer_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMixer {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("streamHandle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getVolume", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getPitch", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isPlaying", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getPlayState", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isPaused", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isStopped", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isLooping", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getPan", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getMasterVolume", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSourceType", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getActiveSourceCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSourceCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("containsSource", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBusByName", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBus", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSourceBus", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDuration", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTell", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLowpass", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getHighpass", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFadeIn", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSourcePosition", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSourceVelocity", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSourceOrientation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDopplerScale", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queueableFreeBufferCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaQueueableSource ────────────────────────────────────────────────────────────

pub struct LuaQueueableSource(/* TODO: add key + state fields */);


impl LuaQueueableSource {
    /// Returns the number of buffer slots currently available.
    ///
    ///
    /// @return integer
    pub fn free_buffer_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaQueueableSource {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("freeBufferCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaSoundData ────────────────────────────────────────────────────────────

pub struct LuaSoundData(/* TODO: add key + state fields */);


impl LuaSoundData {
    /// Get a sample at the given index (interleaved).
    ///
    /// @param index : integer
    /// @return number?
    pub fn get_sample(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of samples per channel. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn sample_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the sample rate in Hz. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn sample_rate(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of audio channels. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return u16
    pub fn channel_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the bit depth. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return u16
    pub fn bit_depth(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the duration in seconds. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return number
    pub fn duration(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSoundData {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSample", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("sampleCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("sampleRate", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("channelCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("bitDepth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("duration", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.audio.* functions ──────────────────────────────────────────

/// Sets the bus volume, clamped to `>= 0.0`.
///
///
/// @param volume : number
pub fn set_volume(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the bus pitch multiplier, clamped to `>= 0.0`.
///
///
/// @param pitch : number
pub fn set_pitch(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Load an audio file and prepare it for chunked decoding.
///
/// @param path : str
/// @param buffer_size : integer
/// @return Result<Self
pub fn from_file(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Return the next chunk of samples, or `None` at EOF.
///
///
/// @return table?
pub fn decode(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Seek to a time offset in seconds.
///
///
/// @param offset : number
pub fn seek(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies this effect's DSP algorithm to a single PCM sample.
///
/// @param sample : number
/// @param channel : u16
/// @param sample_rate : integer
/// @return number
pub fn process(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Load a SoundFont from raw SF2 data. Replaces the current soundfont value; callers hold responsibility for maintaining consistency with related fields.
///
/// @param data : table
/// @param path : string?
/// @return Result<()
pub fn set_soundfont(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Loads and parses a MIDI file from the given path.
///
/// @param path : Path
/// @return boolean
pub fn load(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Loads MIDI from raw bytes (e.g., embedded data).
///
/// @param data : table
/// @return boolean
pub fn load_data(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Plays the loaded MIDI through the given output stream handle.
///
///
/// @param stream_handle : rodio::OutputStreamHandle
pub fn play(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Seeks to a position in seconds. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @param secs : number
/// Sets the master volume (0.0 = silent, values above 1.0 amplify).
///
///
/// @param vol : number
/// Sets whether playback should loop. Replaces the current looping value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param looping : boolean
pub fn set_looping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the tempo scale factor (minimum 0.01).
///
///
/// @param scale : number
pub fn set_tempo_scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the volume for a specific MIDI channel (0-15).
///
///
/// @param ch : integer
/// @param vol : number
pub fn set_channel_volume(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the mute state for a specific MIDI channel (0-15).
///
///
/// @param ch : integer
/// @param muted : boolean
pub fn set_channel_muted(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the instrument (program number) for a MIDI channel (0-15).
///
///
/// @param ch : integer
/// @param inst : u8
pub fn set_channel_instrument(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Solos a channel (mutes all others). Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @param ch : integer
pub fn solo_channel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the mute state for a specific track by index.
///
///
/// @param idx : integer
/// @param muted : boolean
pub fn set_track_muted(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the audio bus key for mixer routing.
///
///
/// @param key : BusKey?
pub fn set_bus_key(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Pushes a buffer of f32 PCM samples into the queue.
///
/// Returns `Err` if no free buffer slots remain.
///
/// @param data : [f32]
/// @return Result<()
pub fn queue_buffer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers a new audio file path with the given source type and returns its key.
///
/// @param file_path : str
/// @param source_type : SourceType
/// @return SoundKey
pub fn load_source(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Plays the audio source identified by `key`, loading and decoding the file on demand.
///
///
/// @param key : SoundKey
/// @param game_dir : Path
/// Stops playback of a sound and resets its position to the beginning.
///
///
/// @param key : SoundKey
pub fn stop(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the per-source playback volume, clamped to `[0.0, 2.0]`.
///
///
/// @param key : SoundKey
/// @param volume : number
/// Pauses playback of the audio source identified by \key\.
///
///
/// @param key : SoundKey
pub fn pause(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Resumes playback of a paused audio source identified by \key\.
///
///
/// @param key : SoundKey
pub fn resume(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the playback speed (pitch) for the source, clamped to `[0.1, 4.0]`.
///
///
/// @param key : SoundKey
/// @param pitch : number
/// Sets the playback speed (pitch) for the source, clamped to `[0.1, 4.0]`.
///
///
/// @param key : SoundKey
/// @param speed : number
pub fn set_speed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the looping flag for the source. Takes effect on next `play` call.
///
///
/// @param key : SoundKey
/// @param looping : boolean
/// Plays the audio source in an infinite loop.
///
///
/// @param key : SoundKey
/// @param game_dir : Path
pub fn play_looping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the stereo pan for the source, clamped to `[-1.0, 1.0]`.
///
///
/// @param key : SoundKey
/// @param pan : number
pub fn set_pan(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the master volume applied to all sources, clamped to `[0.0, 1.0]`.
///
///
/// @param volume : number
pub fn set_master_volume(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clones a source, sharing cached decoded data (for static sources).
///
/// @param key : SoundKey
/// @return SoundKey?
pub fn clone_source(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Stops and removes the audio source identified by `key`.
///
/// @param key : SoundKey
/// @return boolean
pub fn release(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a new named bus and returns its key.
///
/// @param name : impl Into<String>
/// @return BusKey
pub fn new_bus(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns a mutable reference to the bus, if it exists.
///
/// @param key : BusKey
/// @return Option<
pub fn get_bus_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Assigns a source to a bus. Pass `None` to remove the bus assignment.
///
///
/// @param key : SoundKey
/// @param bus_key : BusKey?
pub fn set_source_bus(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Seeks the source to `position_secs` by rebuilding the sink from the new offset.
///
///
/// @param key : SoundKey
/// @param position_secs : number
/// @param game_dir : Path
/// Sets a lowpass filter cutoff in Hz. Applied on next `play` or `seek`.
///
///
/// @param key : SoundKey
/// @param cutoff_hz : integer
pub fn set_lowpass(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes the lowpass filter from the source.
///
///
/// @param key : SoundKey
pub fn clear_lowpass(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a highpass filter cutoff in Hz. Applied on next `play` or `seek`.
///
///
/// @param key : SoundKey
/// @param cutoff_hz : integer
pub fn set_highpass(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes the highpass filter from the source.
///
///
/// @param key : SoundKey
pub fn clear_highpass(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes all filters (lowpass and highpass) from the source.
///
///
/// @param key : SoundKey
pub fn clear_filter(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the fade-in duration in seconds. Applied on next `play`.
///
///
/// @param key : SoundKey
/// @param duration_secs : number
pub fn set_fade_in(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes the fade-in setting from the source.
///
///
/// @param key : SoundKey
pub fn clear_fade_in(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the 3D spatial position of an audio source.
///
/// Also recomputes the `pan` value using 2D projection so the change takes
/// effect immediately on the next `play` call.
///
///
/// @param key : SoundKey
/// @param x : number
/// @param y : number
/// @param z : number
pub fn set_source_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the spatial velocity of an audio source (used for Doppler calculation).
///
///
/// @param key : SoundKey
/// @param x : number
/// @param y : number
/// @param z : number
pub fn set_source_velocity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the spatial orientation of an audio source.
///
///
/// @param key : SoundKey
/// @param fx : number
/// @param fy : number
/// @param fz : number
/// @param ux : number
/// @param uy : number
/// @param uz : number
pub fn set_source_orientation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the 3D listener position for spatial audio.
///
///
/// @param x : number
/// @param y : number
/// @param z : number
pub fn set_listener_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the listener orientation (forward + up vectors).
///
///
/// @param fx : number
/// @param fy : number
/// @param fz : number
/// @param ux : number
/// @param uy : number
/// @param uz : number
pub fn set_listener_orientation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the listener velocity for Doppler calculation.
///
///
/// @param x : number
/// @param y : number
/// @param z : number
pub fn set_listener_velocity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the global Doppler effect scale.
///
///
/// @param scale : number
pub fn set_doppler_scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the distance attenuation model.
///
///
/// @param model : str
pub fn set_distance_model(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a new queueable source and returns its key.
///
/// @param sample_rate : integer
/// @param bit_depth : u8
/// @param channels : u8
/// @param buffer_count : integer
/// @return QueueableKey
pub fn new_queueable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Pushes a buffer of f32 PCM samples into a queueable source.
///
/// @param key : QueueableKey
/// @param data : [f32]
/// @return Result<()
/// Marks a queueable source as playing (state bookkeeping only; actual PCM playback
/// is driven by game code dequeuing buffers via `queue_buffer`).
///
///
/// @param key : QueueableKey
pub fn play_queueable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Stops a queueable source, draining all queued buffers.
///
///
/// @param key : QueueableKey
pub fn stop_queueable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Releases a queueable source, removing it from the slot-map.
///
/// @param key : QueueableKey
/// @return boolean
pub fn release_queueable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the names of all available audio output devices.
///
/// On most systems this returns at least `"Default"`. Uses `cpal` enumeration
/// when available; falls back to a single-entry stub list otherwise.
///
///
/// @return table
pub fn get_playback_devices(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns the name of the currently active audio output device.
///
///
/// @return string
pub fn get_playback_device(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Selects the audio output device by name.
///
/// Accepts any name returned by [`get_playback_devices`].  Passing an unknown
/// name returns `Err(EngineError::AudioError)`.
///
/// @param name : str
/// @return Result<()
pub fn set_playback_device(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a `SoundData` from an existing f32 sample buffer.
///
/// @param samples : table
/// @param sample_rate : integer
/// @param channels : u16
/// @return Self
pub fn from_samples(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Decode an audio file to SoundData. Returns a fully initialised instance with all fields set to their initial values.
///
/// @param path : str
/// @return Result<Self
/// Set a sample at the given index (clamped to [-1.0, 1.0]).
///
/// @param index : integer
/// @param value : number
/// @return boolean
pub fn set_sample(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.audio` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("setVolume", lua.create_function(set_volume)?)?;
    tbl.set("setPitch", lua.create_function(set_pitch)?)?;
    tbl.set("fromFile", lua.create_function(from_file)?)?;
    tbl.set("decode", lua.create_function(decode)?)?;
    tbl.set("seek", lua.create_function(seek)?)?;
    tbl.set("process", lua.create_function(process)?)?;
    tbl.set("setSoundfont", lua.create_function(set_soundfont)?)?;
    tbl.set("load", lua.create_function(load)?)?;
    tbl.set("loadData", lua.create_function(load_data)?)?;
    tbl.set("play", lua.create_function(play)?)?;
    tbl.set("seek", lua.create_function(seek)?)?;
    tbl.set("setVolume", lua.create_function(set_volume)?)?;
    tbl.set("setLooping", lua.create_function(set_looping)?)?;
    tbl.set("setTempoScale", lua.create_function(set_tempo_scale)?)?;
    tbl.set("setChannelVolume", lua.create_function(set_channel_volume)?)?;
    tbl.set("setChannelMuted", lua.create_function(set_channel_muted)?)?;
    tbl.set("setChannelInstrument", lua.create_function(set_channel_instrument)?)?;
    tbl.set("soloChannel", lua.create_function(solo_channel)?)?;
    tbl.set("setTrackMuted", lua.create_function(set_track_muted)?)?;
    tbl.set("setBusKey", lua.create_function(set_bus_key)?)?;
    tbl.set("queueBuffer", lua.create_function(queue_buffer)?)?;
    tbl.set("loadSource", lua.create_function(load_source)?)?;
    tbl.set("play", lua.create_function(play)?)?;
    tbl.set("stop", lua.create_function(stop)?)?;
    tbl.set("setVolume", lua.create_function(set_volume)?)?;
    tbl.set("pause", lua.create_function(pause)?)?;
    tbl.set("resume", lua.create_function(resume)?)?;
    tbl.set("setPitch", lua.create_function(set_pitch)?)?;
    tbl.set("setSpeed", lua.create_function(set_speed)?)?;
    tbl.set("setLooping", lua.create_function(set_looping)?)?;
    tbl.set("playLooping", lua.create_function(play_looping)?)?;
    tbl.set("setPan", lua.create_function(set_pan)?)?;
    tbl.set("setMasterVolume", lua.create_function(set_master_volume)?)?;
    tbl.set("cloneSource", lua.create_function(clone_source)?)?;
    tbl.set("release", lua.create_function(release)?)?;
    tbl.set("newBus", lua.create_function(new_bus)?)?;
    tbl.set("getBusMut", lua.create_function(get_bus_mut)?)?;
    tbl.set("setSourceBus", lua.create_function(set_source_bus)?)?;
    tbl.set("seek", lua.create_function(seek)?)?;
    tbl.set("setLowpass", lua.create_function(set_lowpass)?)?;
    tbl.set("clearLowpass", lua.create_function(clear_lowpass)?)?;
    tbl.set("setHighpass", lua.create_function(set_highpass)?)?;
    tbl.set("clearHighpass", lua.create_function(clear_highpass)?)?;
    tbl.set("clearFilter", lua.create_function(clear_filter)?)?;
    tbl.set("setFadeIn", lua.create_function(set_fade_in)?)?;
    tbl.set("clearFadeIn", lua.create_function(clear_fade_in)?)?;
    tbl.set("setSourcePosition", lua.create_function(set_source_position)?)?;
    tbl.set("setSourceVelocity", lua.create_function(set_source_velocity)?)?;
    tbl.set("setSourceOrientation", lua.create_function(set_source_orientation)?)?;
    tbl.set("setListenerPosition", lua.create_function(set_listener_position)?)?;
    tbl.set("setListenerOrientation", lua.create_function(set_listener_orientation)?)?;
    tbl.set("setListenerVelocity", lua.create_function(set_listener_velocity)?)?;
    tbl.set("setDopplerScale", lua.create_function(set_doppler_scale)?)?;
    tbl.set("setDistanceModel", lua.create_function(set_distance_model)?)?;
    tbl.set("newQueueable", lua.create_function(new_queueable)?)?;
    tbl.set("queueBuffer", lua.create_function(queue_buffer)?)?;
    tbl.set("playQueueable", lua.create_function(play_queueable)?)?;
    tbl.set("stopQueueable", lua.create_function(stop_queueable)?)?;
    tbl.set("releaseQueueable", lua.create_function(release_queueable)?)?;
    tbl.set("getPlaybackDevices", lua.create_function(get_playback_devices)?)?;
    tbl.set("getPlaybackDevice", lua.create_function(get_playback_device)?)?;
    tbl.set("setPlaybackDevice", lua.create_function(set_playback_device)?)?;
    tbl.set("fromSamples", lua.create_function(from_samples)?)?;
    tbl.set("fromFile", lua.create_function(from_file)?)?;
    tbl.set("setSample", lua.create_function(set_sample)?)?;
    luna.set("audio", tbl)?;
    Ok(())
}
