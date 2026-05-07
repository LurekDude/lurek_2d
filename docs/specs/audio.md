# audio

## General Info

- Module group: `Platform Services`
- Source path: `src/audio/`
- Lua API path(s): `src/lua_api/audio_api.rs`
- Primary Lua namespace: `lurek.audio`
- Rust test path(s): tests/rust/unit/audio_tests.rs, tests/rust/unit/audio_sound_tests.rs
- Lua test path(s): tests/lua/unit/test_audio.lua, tests/lua/unit/test_audio_bus.lua, tests/lua/unit/test_audio_dsp.lua, tests/lua/integration/test_audio_timer.lua, tests/lua/integration/test_audio_event.lua, tests/lua/evidence/test_evidence_audio.lua, tests/lua/evidence/test_evidence_audio_bus.lua

## Summary

The `audio` module is Lurek2D's full-featured sound engine — a Platform Services tier subsystem built on `rodio` 0.17. It handles everything from sound loading and real-time playback to bus mixing, DSP effects chains, spatial 2D audio, MIDI synthesis, and offline processing. All Lua access goes through `lurek.audio.*` which delegates to `Mixer` and `Bus` instances stored in `SharedState`.

**Mixer.** `Mixer` is the central audio controller. It owns a `SlotMap<SoundKey, AudioEntry>` for O(1) handle lookup and safe invalidation on drop. A `rodio::OutputStream` + `OutputStreamHandle` drives PCM to the default audio device (enumerable and selectable via `facade.rs`). Sounds are loaded as two modes: `Static` (fully decoded into a `SoundData` in-memory buffer — for short SFX) or `Stream` (incrementally decoded from disk — for music). Per-source controls: volume, pitch (speed multiplier), stereo pan, looping flag, and independent play/pause/stop/seek operations. Fade-in and fade-out are built-in via linear interpolation over user-specified durations.

**Bus system.** `Bus` is a named group for shared volume and pause control. Sources are assigned to a bus by name at load or dynamically at runtime; the mixer multiplies each source's effective volume/pitch by its bus multiplier on every update. Typical buses: `"music"`, `"sfx"`, `"voice"`. Buses extend into **duck-target** support: `set_duck_target(priority_bus, factor, attack, release)` causes a bus to automatically lower its volume when a designated priority bus is active — dialogue-over-music ducking with no manual scripting. `Bus:getPeak()` returns a real-time RMS level for UI VU meters.

**DSP effects.** `dsp.rs` provides a dynamic per-source `SharedEffectGraph` that chains `ActiveEffect` slots. `EffectType` variants: LowPass, HighPass, Reverb, Delay, Chorus, Distortion, Compressor, Equalizer, Pitch, Gate, Tremolo, Vibrato. Each effect slot stores `EffectParams` with atomic float parameters (`AtomicParam`) for thread-safe real-time automation. `DynamicEffectSource` wraps a rodio source and applies the chain. Buses also carry their own effect chains via `Bus::add_effect` / `Bus::remove_effect`.

**Spatial audio.** `SpatialState` stores a source's world-space position, velocity, and a max-distance for falloff calculation. The mixer translates spatial positions to stereo pan and volume attenuation on each `update(dt)` call. Listener position and orientation are set via `lurek.audio.setListenerPosition` / `setListenerVelocity`.

**Sound data and decoding.** `SoundData` holds fully decoded f32 PCM with per-sample read/write access (useful for procedural audio). `Decoder` provides chunked streaming reads from audio files (WAV, OGG, MP3, FLAC). `QueueableSource` is a manually-fed streaming sink that accepts raw f32 PCM buffers pushed in real time — used for procedurally generated audio or network audio streams.

**MIDI synthesis.** `MidiPlayer` is a software MIDI synthesizer: `load(path)` parses `.mid` files via `midly`, then `render()` produces f32 PCM via sine-additive per-channel synthesis. `get/set_output_sample_rate` and `get/set_output_channels` control output quality. Exposed to Lua as `lurek.audio.loadMidi(path)` returning a `MidiPlayer` userdata with `play`, `pause`, `stop`.

**Sound pool.** `SoundPool` provides round-robin polyphonic playback of a single audio asset — play calls cycle through a fixed number of voices so rapid fire SFX (gunshots, footsteps) don't cut each other off. Configured by `max_voices` parameter.

**Offline processing.** `offline.rs` applies `OfflineEffect` chains to in-memory `SoundData` buffers outside the real-time mixer, producing processed PCM results for export or analysis.

**Visualisation.** `visualizer.rs` exports waveform and spectrogram PNG images from `SoundData`, useful for development tooling, debug overlays, and audio-reactive UI.

**Lua surface.** `lurek.audio.load(path, options)` loads a sound (returning a `SoundKey`), `play`, `pause`, `stop`, `seek`, `volume`, `pitch`, `pan`, `loop`, `fadeTo`, `getDuration`, `getTime`. Bus management: `lurek.audio.getBus(name)` → `Bus` userdata with `setVolume`, `setPitch`, `pause`, `resume`, `addEffect`, `setDuckTarget`, `getPeak`. Effects: `lurek.audio.addEffect(sound_key, effect_type, params)`. Spatial: `setPosition`, `setListenerPosition`. MIDI: `loadMidi` → `MidiPlayer`. Pool: `newPool(path, voices)` → `SoundPool`.

**Scope boundary.** Platform Services tier. Depends on `runtime` (SoundKey, SharedState). Lua bridge in `src/lua_api/audio_api.rs`.

## Files

- `bus.rs`: Named audio bus for grouping sources under shared volume, pitch, and pause controls.
- `decoder.rs`: Streaming audio decoder for chunked PCM reading.
- `dsp.rs`: Digital signal processing effects for the Lurek2D audio pipeline.
- `facade.rs`: Audio device facade: enumeration and selection of playback devices.
- `midi.rs`: MIDI SoundFont state management.
- `midi_player.rs`: Software MIDI synthesizer: parses MIDI with `midly`, renders to PCM via sine-additive synthesis, and plays through a rodio `Sink`.
- `mixer.rs`: Core audio mixer that owns every loaded sound and drives playback through rodio.
- `mod.rs`: Audio subsystem for Lurek2D games.
- `offline.rs`: Offline audio processing utilities.
- `pool.rs`: Polyphonic sound pool for round-robin voice allocation.
- `sound_data.rs`: Decoded PCM audio sample buffer with per-sample read/write access.
- `source.rs`: Audio source type and playback state enums for the audio subsystem.
- `visualizer.rs`: Audio visualisation utilities — waveform and spectrogram PNG export.

## Types

- `Bus` (`struct`, `bus.rs`): A named audio bus that applies volume, pitch, and pause overrides to all sources assigned to it.
- `Decoder` (`struct`, `decoder.rs`): Streaming audio decoder that reads PCM in fixed-size chunks.
- `AtomicParam` (`struct`, `dsp.rs`): Thread-safe atomic `f32` parameter backed by an `AtomicU32` bit-cast.
- `EffectType` (`enum`, `dsp.rs`): Category of DSP audio effect applied to a sound source.
- `EffectParams` (`struct`, `dsp.rs`): Shared configuration for a single DSP effect slot.
- `ActiveEffect` (`struct`, `dsp.rs`): Per-stream instantiation of an `EffectParams` slot, holding the filter state for a single audio stream.
- `SharedEffectGraph` (`struct`, `dsp.rs`): Shared, thread-safe graph of active DSP effects owned by a sound source.
- `DynamicEffectSource` (`struct`, `dsp.rs`): A rodio `Source` wrapper that applies a dynamic chain of DSP effects to an inner audio source.
- `MidiState` (`struct`, `midi.rs`): MIDI SoundFont state.
- `MidiData` (`struct`, `midi_player.rs`): Pre-parsed MIDI metadata extracted during `load()`.
- `MidiPlayer` (`struct`, `midi_player.rs`): Software MIDI player with sine-additive synthesis.
- `SourceType` (`enum`, `mixer.rs`): Type of audio source.
- `PlayState` (`enum`, `mixer.rs`): Playback state of an audio source.
- `QueueableSource` (`struct`, `mixer.rs`): A manually-fed streaming audio source that accepts raw f32 PCM data pushed buffer-by-buffer.
- `Mixer` (`struct`, `mixer.rs`): The `Mixer` is the single point of entry for all audio operations in Lurek2D.
- `OfflineEffect` (`struct`, `offline.rs`): Descriptor for a single DSP effect used in offline processing.
- `SoundPool` (`struct`, `pool.rs`): A round-robin voice pool for polyphonic playback of a single audio file.
- `SoundData` (`struct`, `sound_data.rs`): Decoded audio samples in f32 PCM format.
- `SpatialState` (`struct`, `source.rs`): 3D spatial audio state for an audio source.
- `AudioSource` (`struct`, `source.rs`): Handle for a loaded audio asset (legacy compatibility shim).

## Functions

- `Bus::new` (`bus.rs`): Creates a new bus with the given name, volume `1.0`, pitch `1.0`, and not paused.
- `Bus::name` (`bus.rs`): Returns the bus name.
- `Bus::volume` (`bus.rs`): Returns the bus volume (always `>= 0.0`).
- `Bus::set_volume` (`bus.rs`): Sets the bus volume, clamped to `>= 0.0`.
- `Bus::pitch` (`bus.rs`): Returns the bus pitch multiplier (always `>= 0.0`).
- `Bus::set_pitch` (`bus.rs`): Sets the bus pitch multiplier, clamped to `>= 0.0`.
- `Bus::pause` (`bus.rs`): Pauses the bus.
- `Bus::resume` (`bus.rs`): Resumes the bus.
- `Bus::is_paused` (`bus.rs`): Returns whether the bus is paused.
- `Bus::add_effect` (`bus.rs`): Adds a DSP effect to this audio bus.
- `Bus::remove_effect` (`bus.rs`): Removes a DSP effect from this audio bus by ID.
- `Bus::set_duck_target` (`bus.rs`): Sets the ducking target for this bus.
- `Bus::clear_duck_target` (`bus.rs`): Clears the ducking target, disabling ducking for this bus.
- `Decoder::from_file` (`decoder.rs`): Load an audio file and prepare it for chunked decoding.
- `Decoder::decode` (`decoder.rs`): Return the next chunk of samples, or `None` at EOF.
- `Decoder::get_duration` (`decoder.rs`): Return the total duration in seconds.
- `Decoder::seek` (`decoder.rs`): Seek to a time offset in seconds.
- `Decoder::tell` (`decoder.rs`): Return the current playback position in seconds.
- `Decoder::is_seekable` (`decoder.rs`): Returns whether this decoder supports seeking.
- `Decoder::rewind` (`decoder.rs`): Reset playback to the beginning.
- `AtomicParam::new` (`dsp.rs`): Creates a new `AtomicParam` initialised to `val`.
- `AtomicParam::get` (`dsp.rs`): Returns the current value, loaded with `Relaxed` ordering.
- `AtomicParam::set` (`dsp.rs`): Stores a new value with `Relaxed` ordering.
- `EffectParams::new` (`dsp.rs`): Creates a new `EffectParams` with the given slot ID and effect type.
- `EffectParams::set_param` (`dsp.rs`): Sets an effect parameter by name using lock-free atomic writes.
- `ActiveEffect::new` (`dsp.rs`): Creates a new `ActiveEffect` for the given effect configuration.
- `ActiveEffect::process` (`dsp.rs`): Applies this effect's DSP algorithm to a single PCM sample.
- `SharedEffectGraph::new` (`dsp.rs`): Creates an empty `SharedEffectGraph` with no effects in the chain.
- `new` (`dsp.rs`): Wraps an inner audio source with a dynamic DSP effect chain.
- `get_playback_devices` (`facade.rs`): Returns the names of all available audio output devices.
- `get_playback_device` (`facade.rs`): Returns the name of the currently active audio output device.
- `set_playback_device` (`facade.rs`): Selects the audio output device by name.
- `MidiState::new` (`midi.rs`): Create a new empty MidiState with no SoundFont loaded.
- `MidiState::set_soundfont` (`midi.rs`): Load a SoundFont from raw SF2 data.
- `MidiState::has_soundfont` (`midi.rs`): Check whether a SoundFont is currently loaded.
- `MidiState::clear_soundfont` (`midi.rs`): Clear the loaded SoundFont, freeing its memory.
- `MidiState::soundfont_path` (`midi.rs`): Get the path of the loaded SoundFont, if any.
- `MidiState::soundfont_data` (`midi.rs`): Get a reference to the raw SoundFont data, if loaded.
- `MidiPlayer::new` (`midi_player.rs`): Creates a new MidiPlayer with default settings.
- `MidiPlayer::load` (`midi_player.rs`): Loads and parses a MIDI file from the given path.
- `MidiPlayer::load_data` (`midi_player.rs`): Loads MIDI from raw bytes (e.g., embedded data).
- `MidiPlayer::is_loaded` (`midi_player.rs`): Returns whether a MIDI file is currently loaded.
- `MidiPlayer::file_path` (`midi_player.rs`): Returns the file path of the loaded MIDI, if any.
- `MidiPlayer::play` (`midi_player.rs`): Plays the loaded MIDI through the given output stream handle.
- `MidiPlayer::stop` (`midi_player.rs`): Stops playback and resets position to 0.
- `MidiPlayer::pause` (`midi_player.rs`): Pauses playback.
- `MidiPlayer::resume` (`midi_player.rs`): Resumes paused playback.
- `MidiPlayer::is_playing` (`midi_player.rs`): Returns whether the player is currently playing.
- `MidiPlayer::is_paused` (`midi_player.rs`): Returns whether the player is paused.
- `MidiPlayer::seek` (`midi_player.rs`): Seeks to a position in seconds.
- `MidiPlayer::tell` (`midi_player.rs`): Returns the current playback position in seconds.
- `MidiPlayer::duration` (`midi_player.rs`): Returns the duration of the loaded MIDI in seconds.
- `MidiPlayer::set_volume` (`midi_player.rs`): Sets the master volume (0.0 = silent, values above 1.0 amplify).
- `MidiPlayer::volume` (`midi_player.rs`): Returns the master volume.
- `MidiPlayer::set_looping` (`midi_player.rs`): Sets whether playback should loop.
- `MidiPlayer::is_looping` (`midi_player.rs`): Returns whether playback is set to loop.
- `MidiPlayer::set_tempo_scale` (`midi_player.rs`): Sets the tempo scale factor (minimum 0.01).
- `MidiPlayer::tempo_scale` (`midi_player.rs`): Returns the current tempo scale factor.
- `MidiPlayer::current_bpm` (`midi_player.rs`): Returns the current effective BPM.
- `MidiPlayer::original_tempo` (`midi_player.rs`): Returns the original tempo in BPM from the MIDI file.
- `MidiPlayer::ticks_per_beat` (`midi_player.rs`): Returns the ticks-per-beat value from the MIDI header.
- `MidiPlayer::set_channel_volume` (`midi_player.rs`): Sets the volume for a specific MIDI channel (0-15).
- `MidiPlayer::channel_volume` (`midi_player.rs`): Returns the volume for a specific MIDI channel (0-15).
- `MidiPlayer::set_channel_muted` (`midi_player.rs`): Sets the mute state for a specific MIDI channel (0-15).
- `MidiPlayer::is_channel_muted` (`midi_player.rs`): Returns whether a specific MIDI channel (0-15) is muted.
- `MidiPlayer::set_channel_instrument` (`midi_player.rs`): Sets the instrument (program number) for a MIDI channel (0-15).
- `MidiPlayer::channel_instrument` (`midi_player.rs`): Returns the instrument (program number) for a MIDI channel (0-15).
- `MidiPlayer::channel_count` (`midi_player.rs`): Returns the number of unique MIDI channels used in the loaded file.
- `MidiPlayer::solo_channel` (`midi_player.rs`): Solos a channel (mutes all others).
- `MidiPlayer::unsolo_all` (`midi_player.rs`): Un-solos all channels (unmutes all).
- `MidiPlayer::track_count` (`midi_player.rs`): Returns the number of tracks in the loaded MIDI file.
- `MidiPlayer::track_name` (`midi_player.rs`): Returns the name of a track by index, if it has one.
- `MidiPlayer::set_track_muted` (`midi_player.rs`): Sets the mute state for a specific track by index.
- `MidiPlayer::is_track_muted` (`midi_player.rs`): Returns whether a specific track is muted.
- `MidiPlayer::note_count` (`midi_player.rs`): Returns the total number of NoteOn events in the loaded MIDI.
- `MidiPlayer::set_bus_key` (`midi_player.rs`): Sets the audio bus key for mixer routing.
- `MidiPlayer::bus_key` (`midi_player.rs`): Returns the audio bus key, if assigned.
- `MidiPlayer::play_state` (`midi_player.rs`): Returns the current playback state.
- `MidiPlayer::get_output_sample_rate` (`midi_player.rs`): Returns the PCM output sample rate in Hz.
- `MidiPlayer::set_output_sample_rate` (`midi_player.rs`): Sets the PCM output sample rate in Hz (clamped to 8000â€“192000).
- `MidiPlayer::get_output_channels` (`midi_player.rs`): Returns the PCM output channel count (1 = mono, 2 = stereo).
- `MidiPlayer::set_output_channels` (`midi_player.rs`): Sets the PCM output channel count (clamped to 1â€“2).
- `QueueableSource::new` (`mixer.rs`): Creates a new `QueueableSource` with all buffer slots free.
- `QueueableSource::queue_buffer` (`mixer.rs`): Pushes a buffer of f32 PCM samples into the queue.
- `QueueableSource::free_buffer_count` (`mixer.rs`): Returns the number of buffer slots currently available.
- `Mixer::new` (`mixer.rs`): Creates a new `Mixer`, attempting to open the default system audio output.
- `Mixer::stream_handle` (`mixer.rs`): Returns a reference to the output stream handle, if available.
- `Mixer::load_source` (`mixer.rs`): Registers a new audio file path with the given source type and returns its key.
- `Mixer::play` (`mixer.rs`): Plays the audio source identified by `key`, loading and decoding the file on demand.
- `Mixer::stop` (`mixer.rs`): Stops playback of a sound and resets its position to the beginning.
- `Mixer::set_volume` (`mixer.rs`): Sets the per-source playback volume, clamped to `[0.0, 2.0]`.
- `Mixer::get_volume` (`mixer.rs`): Returns the per-source playback volume.
- `Mixer::pause` (`mixer.rs`): Pauses playback of the audio source identified by \key\.
- `Mixer::resume` (`mixer.rs`): Resumes playback of a paused audio source identified by \key\.
- `Mixer::set_pitch` (`mixer.rs`): Sets the playback speed (pitch) for the source, clamped to `[0.1, 4.0]`.
- `Mixer::get_pitch` (`mixer.rs`): Returns the pitch (playback speed) for the source.
- `Mixer::set_speed` (`mixer.rs`): Sets the playback speed (pitch) for the source, clamped to `[0.1, 4.0]`.
- `Mixer::is_playing` (`mixer.rs`): Returns whether the audio source is currently playing (not paused and not empty).
- `Mixer::get_play_state` (`mixer.rs`): Returns the playback state of the source, synced with the underlying sink.
- `Mixer::is_paused` (`mixer.rs`): Returns whether the source is paused.
- `Mixer::is_stopped` (`mixer.rs`): Returns whether the source is stopped.
- `Mixer::set_looping` (`mixer.rs`): Sets the looping flag for the source.
- `Mixer::is_looping` (`mixer.rs`): Returns whether the source is set to loop.
- `Mixer::play_looping` (`mixer.rs`): Plays the audio source in an infinite loop.
- `Mixer::set_pan` (`mixer.rs`): Sets the stereo pan for the source, clamped to `[-1.0, 1.0]`.
- `Mixer::get_pan` (`mixer.rs`): Returns the stereo pan for the source.
- `Mixer::set_master_volume` (`mixer.rs`): Sets the master volume applied to all sources, clamped to `[0.0, 1.0]`.
- `Mixer::get_master_volume` (`mixer.rs`): Returns the master volume.
- `Mixer::get_source_type` (`mixer.rs`): Returns the source type for the given key.
- `Mixer::get_active_source_count` (`mixer.rs`): Returns the number of actively playing (not paused, not empty) sources.
- `Mixer::get_source_count` (`mixer.rs`): Returns the total number of loaded sources.
- `Mixer::contains_source` (`mixer.rs`): Returns whether the given source key still refers to a loaded audio source.
- `Mixer::pause_all` (`mixer.rs`): Pauses all currently playing sources.
- `Mixer::stop_all` (`mixer.rs`): Stops all sources and drops their sinks.
- `Mixer::resume_all` (`mixer.rs`): Resumes all paused sources.
- `Mixer::clone_source` (`mixer.rs`): Clones a source, sharing cached decoded data (for static sources).
- `Mixer::release` (`mixer.rs`): Stops and removes the audio source identified by `key`.
- `Mixer::set_peak` (`mixer.rs`): Sets the peak amplitude for a source (0.0–1.0).
- `Mixer::get_peak` (`mixer.rs`): Returns the stored peak amplitude for a source, or `0.0` if the source does not exist.
- `Mixer::bus_peak` (`mixer.rs`): Returns the average peak amplitude of all sources currently assigned to the given bus.
- `Mixer::new_bus` (`mixer.rs`): Creates a new named bus and returns its key.
- `Mixer::get_bus_by_name` (`mixer.rs`): Returns an immutable reference to the bus, if it exists.
- `Mixer::get_bus` (`mixer.rs`): Gets a bus by key.
- `Mixer::get_bus_mut` (`mixer.rs`): Returns a mutable reference to the bus, if it exists.
- `Mixer::set_source_bus` (`mixer.rs`): Assigns a source to a bus.
- `Mixer::get_source_bus` (`mixer.rs`): Returns the bus key assigned to a source, if any.
- `Mixer::get_duration` (`mixer.rs`): Returns the cached duration of the audio source in seconds, if known.
- `Mixer::get_tell` (`mixer.rs`): Returns the approximate current playback position in seconds.
- `Mixer::seek` (`mixer.rs`): Seeks the source to `position_secs` by rebuilding the sink from the new offset.
- `Mixer::set_lowpass` (`mixer.rs`): Sets a lowpass filter cutoff in Hz.
- `Mixer::clear_lowpass` (`mixer.rs`): Removes the lowpass filter from the source.
- `Mixer::set_highpass` (`mixer.rs`): Sets a highpass filter cutoff in Hz.
- `Mixer::clear_highpass` (`mixer.rs`): Removes the highpass filter from the source.
- `Mixer::clear_filter` (`mixer.rs`): Removes all filters (lowpass and highpass) from the source.
- `Mixer::get_lowpass` (`mixer.rs`): Returns the lowpass cutoff frequency in Hz, if set.
- `Mixer::get_highpass` (`mixer.rs`): Returns the highpass cutoff frequency in Hz, if set.
- `Mixer::set_fade_in` (`mixer.rs`): Sets the fade-in duration in seconds.
- `Mixer::clear_fade_in` (`mixer.rs`): Removes the fade-in setting from the source.
- `Mixer::get_fade_in` (`mixer.rs`): Returns the fade-in duration in seconds, if set.
- `Mixer::set_source_position` (`mixer.rs`): Sets the 3D spatial position of an audio source.
- `Mixer::get_source_position` (`mixer.rs`): Returns the 3D spatial position of an audio source.
- `Mixer::set_source_velocity` (`mixer.rs`): Sets the spatial velocity of an audio source (used for Doppler calculation).
- `Mixer::get_source_velocity` (`mixer.rs`): Returns the spatial velocity of an audio source.
- `Mixer::set_source_orientation` (`mixer.rs`): Sets the spatial orientation of an audio source.
- `Mixer::get_source_orientation` (`mixer.rs`): Returns the spatial orientation of an audio source.
- `Mixer::set_listener_position` (`mixer.rs`): Sets the 3D listener position for spatial audio.
- `Mixer::get_listener_position` (`mixer.rs`): Returns the 3D listener position.
- `Mixer::set_listener_orientation` (`mixer.rs`): Sets the listener orientation (forward + up vectors).
- `Mixer::get_listener_orientation` (`mixer.rs`): Returns the listener orientation (forward xyz + up xyz).
- `Mixer::set_listener_velocity` (`mixer.rs`): Sets the listener velocity for Doppler calculation.
- `Mixer::get_listener_velocity` (`mixer.rs`): Returns the listener velocity.
- `Mixer::set_doppler_scale` (`mixer.rs`): Sets the global Doppler effect scale.
- `Mixer::get_doppler_scale` (`mixer.rs`): Returns the global Doppler effect scale.
- `Mixer::set_distance_model` (`mixer.rs`): Sets the distance attenuation model.
- `Mixer::get_distance_model` (`mixer.rs`): Returns the current distance attenuation model name.
- `Mixer::new_queueable` (`mixer.rs`): Creates a new queueable source and returns its key.
- `Mixer::queue_buffer` (`mixer.rs`): Pushes a buffer of f32 PCM samples into a queueable source.
- `Mixer::queueable_free_buffer_count` (`mixer.rs`): Returns the number of free buffer slots for a queueable source.
- `Mixer::play_queueable` (`mixer.rs`): Marks a queueable source as playing (state bookkeeping only; actual PCM playback is driven by game code dequeuing buffers via `queue_buffer`).
- `Mixer::stop_queueable` (`mixer.rs`): Stops a queueable source, draining all queued buffers.
- `Mixer::release_queueable` (`mixer.rs`): Releases a queueable source, removing it from the slot-map.
- `Mixer::set_stereo_width` (`mixer.rs`): Sets the stereo width multiplier for a source.
- `Mixer::get_stereo_width` (`mixer.rs`): Returns the current stereo width for a source.
- `Mixer::set_random_pitch` (`mixer.rs`): Sets a random pitch range applied on each call to `play`.
- `Mixer::clear_random_pitch` (`mixer.rs`): Clears any random pitch range set on a source, restoring fixed pitch.
- `Mixer::crossfade` (`mixer.rs`): Crossfades from `from_key` to `to_key` over `duration_secs`.
- `Mixer::get_bus_peak` (`mixer.rs`): Returns the peak signal level for the named bus.
- `Mixer::get_bus_rms` (`mixer.rs`): Returns the RMS signal level for the named bus.
- `Mixer::new_pool` (`mixer.rs`): Loads `voice_count` copies of the file at `file_path` and returns a [`crate::audio::SoundPool`].
- `process_offline` (`offline.rs`): Decodes `input_path`, applies `effects` in series, and writes the result to `output_path`.
- `normalize_file` (`offline.rs`): Normalises the peak amplitude of `input_path` to `target_level` and writes to `output_path`.
- `SoundPool::new` (`pool.rs`): Creates a new `SoundPool` from a set of pre-loaded voice keys.
- `SoundPool::voice_count` (`pool.rs`): Returns the number of voices in the pool.
- `SoundPool::file_path` (`pool.rs`): Returns the source path originally used to create this pool.
- `SoundPool::volume` (`pool.rs`): Returns the shared volume applied to all voices.
- `SoundPool::set_volume` (`pool.rs`): Sets the shared volume for all future plays.
- `SoundPool::bus_name` (`pool.rs`): Returns the bus assignment for all voices, if any.
- `SoundPool::set_bus` (`pool.rs`): Sets the named audio bus that all voices will be routed to.
- `SoundPool::clear_bus` (`pool.rs`): Clears the bus assignment.
- `SoundPool::next_voice` (`pool.rs`): Advances the cursor and returns the next voice key for playback.
- `SoundPool::all_keys` (`pool.rs`): Returns a slice of all voice keys.
- `SoundPool::is_valid` (`pool.rs`): Returns `true` if the pool was created with at least one voice.
- `SoundData::new` (`sound_data.rs`): Create a silent buffer with the given number of samples.
- `SoundData::from_samples` (`sound_data.rs`): Create a `SoundData` from an existing f32 sample buffer.
- `SoundData::from_lua_args` (`sound_data.rs`): Creates `SoundData` from Lua-originated arguments, supporting both file loading and silent buffer creation.
- `SoundData::from_file` (`sound_data.rs`): Decode an audio file to SoundData.
- `SoundData::get_sample` (`sound_data.rs`): Get a sample at the given index (interleaved).
- `SoundData::samples` (`sound_data.rs`): Returns the full interleaved f32 sample buffer as a slice.
- `SoundData::set_sample` (`sound_data.rs`): Set a sample at the given index (clamped to [-1.0, 1.0]).
- `SoundData::sample_count` (`sound_data.rs`): Get the number of samples per channel.
- `SoundData::sample_rate` (`sound_data.rs`): Get the sample rate in Hz.
- `SoundData::channel_count` (`sound_data.rs`): Get the number of audio channels.
- `SoundData::bit_depth` (`sound_data.rs`): Get the bit depth.
- `SoundData::duration` (`sound_data.rs`): Get the duration in seconds.
- `SoundData::as_samples` (`sound_data.rs`): Get a reference to the raw samples.
- `SoundData::encode_wav` (`sound_data.rs`): Encode the audio data as a WAV byte buffer (16-bit PCM).
- `SoundData::sine_wave` (`sound_data.rs`): Generate a mono sine-wave buffer.
- `SoundData::square_wave` (`sound_data.rs`): Generate a mono square-wave buffer.
- `SoundData::sawtooth_wave` (`sound_data.rs`): Generate a mono sawtooth-wave buffer.
- `SoundData::triangle_wave` (`sound_data.rs`): Generate a mono triangle-wave buffer.
- `SoundData::white_noise` (`sound_data.rs`): Generate a reproducible white-noise buffer using a simple LCG PRNG.
- `SoundData::draw_waveform` (`sound_data.rs`): Draws the waveform of the audio samples onto an `ImageData` object.
- `SoundData::apply_lowpass` (`sound_data.rs`): Apply a first-order IIR low-pass filter in-place to the sample buffer.
- `SoundData::apply_highpass` (`sound_data.rs`): Apply a first-order IIR high-pass filter in-place to the sample buffer.
- `SoundData::apply_bandpass` (`sound_data.rs`): Apply a simple bandpass filter in-place (lowpass cascaded with highpass).
- `SoundData::apply_gain` (`sound_data.rs`): Apply gain (amplitude scaling) in-place.
- `SoundData::mix_into` (`sound_data.rs`): Mix another `SoundData` buffer into this one in-place (additive blend).
- `AudioSource::new` (`source.rs`): Creates a new `AudioSource` with default volume (1.0) and looping disabled.
- `waveform_to_png` (`visualizer.rs`): Renders the amplitude waveform of `input_wav` to a PNG file at `output_png`.
- `spectrogram_to_png` (`visualizer.rs`): Renders a time–frequency spectrogram of `input_wav` to a PNG file at `output_png`.

## Lua API Reference

- Binding path(s): `src/lua_api/audio_api.rs`
- Namespace: `lurek.audio`

### Module Functions
- `lurek.audio.newSource`: Loads an audio file and returns a source handle.
- `lurek.audio.play`: Plays a source with optional bus routing.
- `lurek.audio.stop`: Stops playback and resets seek position.
- `lurek.audio.setVolume`: Sets source playback volume.
- `lurek.audio.getVolume`: Returns the source volume.
- `lurek.audio.pause`: Pauses playback at the current position.
- `lurek.audio.resume`: Resumes playback from pause.
- `lurek.audio.setPitch`: Sets source pitch multiplier.
- `lurek.audio.getPitch`: Returns the source pitch multiplier.
- `lurek.audio.isPlaying`: Returns true if the source is playing.
- `lurek.audio.isPaused`: Returns true if the source is paused.
- `lurek.audio.isStopped`: Returns true if the source is stopped.
- `lurek.audio.setLooping`: Enables or disables looping.
- `lurek.audio.isLooping`: Returns true if looping is enabled.
- `lurek.audio.playLooping`: Plays the source in a continuous loop.
- `lurek.audio.setPan`: Sets stereo panning (-1.0 left to 1.0 right).
- `lurek.audio.getPan`: Returns the source stereo panning.
- `lurek.audio.setMasterVolume`: Sets the global master volume.
- `lurek.audio.getMasterVolume`: Returns the global master volume.
- `lurek.audio.getActiveSourceCount`: Returns the number of currently playing sources.
- `lurek.audio.getSourceCount`: Returns the total number of registered sources.
- `lurek.audio.getSourceType`: Returns the type string ("static" or "stream") of a source.
- `lurek.audio.clone`: Creates an independent copy of a source.
- `lurek.audio.pauseAll`: Pauses all currently playing sources.
- `lurek.audio.stopAll`: Stops all currently playing sources.
- `lurek.audio.resumeAll`: Resumes all paused sources.
- `lurek.audio.release`: Releases a source and frees its memory.
- `lurek.audio.newBus`: Creates a named audio bus for grouping sources.
- `lurek.audio.setSourceBus`: Assigns a source to a bus.
- `lurek.audio.getSourceBus`: Returns the bus a source is assigned to, or nil.
- `lurek.audio.getMaxSources`: Returns the maximum number of simultaneous sources.
- `lurek.audio.getDuration`: Returns the total duration of a source in seconds.
- `lurek.audio.tell`: Returns the current playback position in seconds.
- `lurek.audio.seek`: Seeks to a time position in seconds.
- `lurek.audio.setLowpass`: Applies a low-pass filter to a source.
- `lurek.audio.setHighpass`: Applies a high-pass filter to a source.
- `lurek.audio.getLowpass`: Returns the low-pass filter cutoff of a source.
- `lurek.audio.getHighpass`: Returns the high-pass filter cutoff of a source.
- `lurek.audio.clearFilter`: Removes any active filter from a source.
- `lurek.audio.fadeIn`: Fades a source in from silence over the given duration.
- `lurek.audio.getFadeIn`: Returns the fade-in duration of a source.
- `lurek.audio.setListener2D`: Sets the 2D listener position for spatial audio.
- `lurek.audio.getListener2D`: Returns the 2D listener position (x, y).
- `lurek.audio.setListener`: Sets the 3D listener position.
- `lurek.audio.getListener`: Returns the 3D listener position (x, y, z).
- `lurek.audio.setPosition`: Sets the 3D position of a source.
- `lurek.audio.getPosition`: Returns the 3D position of a source (x, y, z).
- `lurek.audio.setVelocity`: Sets the velocity of a source for Doppler.
- `lurek.audio.getVelocity`: Returns the velocity of a source (x, y, z).
- `lurek.audio.setOrientation`: Sets the 6-component orientation of a source.
- `lurek.audio.getOrientation`: Returns the 6-component orientation of a source.
- `lurek.audio.setDopplerScale`: Sets the global Doppler effect scale.
- `lurek.audio.getDopplerScale`: Returns the current Doppler scale.
- `lurek.audio.setDistanceModel`: Sets the distance attenuation model.
- `lurek.audio.getDistanceModel`: Returns the current distance model name.
- `lurek.audio.setMeter`: Sets the master peak meter level.
- `lurek.audio.getMeter`: Returns the stored master peak meter level.
- `lurek.audio.newMidiPlayer`: Creates a MIDI player, optionally loading a file.
- `lurek.audio.newSoundData`: Creates a SoundData from a file or as a silent buffer.
- `lurek.audio.setMidiSoundFont`: Sets the global SoundFont for MIDI synthesis.
- `lurek.audio.hasMidiSoundFont`: Returns true if a SoundFont is loaded.
- `lurek.audio.clearMidiSoundFont`: Unloads the active SoundFont.
- `lurek.audio.newDecoder`: Creates a streaming audio decoder.
- `lurek.audio.newQueueableSource`: Creates a queueable source for manual PCM buffering.
- `lurek.audio.queueSource`: Pushes a SoundData buffer into a queueable source.
- `lurek.audio.getFreeBufferCount`: Returns the free buffer slots in a queueable source.
- `lurek.audio.playQueueable`: Starts playback of a queueable source.
- `lurek.audio.stopQueueable`: Stops a queueable source and drains its buffers.
- `lurek.audio.getPlaybackDevices`: Returns a table of available audio output device names.
- `lurek.audio.getPlaybackDevice`: Returns the current audio output device name.
- `lurek.audio.setPlaybackDevice`: Selects an audio output device by name.
- `lurek.audio.create_bus`: Creates a bus by name (functional style).
- `lurek.audio.set_bus_volume`: Sets a bus volume by name.
- `lurek.audio.add_effect`: Adds a DSP effect to a bus.
- `lurek.audio.remove_effect`: Removes a DSP effect from a bus.
- `lurek.audio.set_effect_param`: Sets a parameter on a DSP effect.
- `lurek.audio.newSineWave`: Generates a mono sine-wave SoundData buffer.
- `lurek.audio.newSquareWave`: Generates a mono square-wave SoundData buffer.
- `lurek.audio.newSawtoothWave`: Generates a mono sawtooth-wave SoundData buffer.
- `lurek.audio.newTriangleWave`: Generates a mono triangle-wave SoundData buffer.
- `lurek.audio.newWhiteNoise`: Generates a reproducible white-noise SoundData buffer.
- `lurek.audio.applyLowpass`: Applies a first-order IIR low-pass filter to a SoundData in-place.
- `lurek.audio.applyHighpass`: Applies a first-order IIR high-pass filter to a SoundData in-place.
- `lurek.audio.applyBandpass`: Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
- `lurek.audio.applyGain`: Scales every sample by gain (clamped to [-1, 1]).
- `lurek.audio.mixInto`: Additively mixes another SoundData into the destination in-place.
- `lurek.audio.saveWAV`: Saves a SoundData as a 16-bit PCM WAV file at the given path.
- `lurek.audio.setStereoWidth`: Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
- `lurek.audio.getStereoWidth`: Returns the current stereo width for a source.
- `lurek.audio.setRandomPitch`: Sets a random pitch range applied each time the source is played.
- `lurek.audio.clearRandomPitch`: Clears any random pitch range on a source, restoring fixed pitch.
- `lurek.audio.crossfade`: Crossfades from one source to another over a duration.
- `lurek.audio.getBusPeak`: Returns the peak signal level of the named bus (stub: always 0.0).
- `lurek.audio.getBusRms`: Returns the RMS signal level of the named bus (stub: always 0.0).
- `lurek.audio.newPool`: Creates a polyphonic sound pool for the given file with N simultaneous voices.
- `lurek.audio.processOffline`: Applies a DSP effect chain to a WAV file and writes output.
- `lurek.audio.normalizeFile`: Normalizes a WAV file peak amplitude to target_level and writes output.
- `lurek.audio.waveformToPng`: Renders the waveform of a WAV file to a PNG image.
- `lurek.audio.spectrogramToPng`: Renders a time-frequency spectrogram of a WAV file to a PNG image.

### `LBus` Methods
- `LBus:getName`: Returns the unique name string assigned to this audio bus.
- `LBus:setVolume`: Sets the volume for all sources on this bus.
- `LBus:getVolume`: Returns the current volume multiplier applied to all sources on this bus.
- `LBus:setPitch`: Sets the pitch multiplier for all sources on this bus.
- `LBus:getPitch`: Returns the bus pitch multiplier.
- `LBus:pause`: Pauses all sources on this bus.
- `LBus:resume`: Resumes all sources on this bus.
- `LBus:isPaused`: Returns true if this bus is paused.
- `LBus:type`: Returns the type name of this object.
- `LBus:typeOf`: Returns true if this object is of the given type.
- `LBus:setDuckTarget`: Configures this bus to duck another bus while it has active sources.
- `LBus:clearDuck`: Removes the ducking target from this bus.
- `LBus:getPeak`: Returns the average peak amplitude of all sources on this bus.

### `LDecoder` Methods
- `LDecoder:decode`: Decodes the next chunk of samples, or nil at EOF.
- `LDecoder:getChannelCount`: Returns the number of audio channels.
- `LDecoder:getBitDepth`: Returns the per-sample bit depth of this decoded audio stream.
- `LDecoder:getSampleRate`: Returns the sample rate in Hz.
- `LDecoder:getDuration`: Returns the total duration in seconds.
- `LDecoder:seek`: Seeks to a time offset in seconds.
- `LDecoder:rewind`: Rewinds to the beginning.
- `LDecoder:tell`: Returns the current position in seconds.
- `LDecoder:isSeekable`: Returns true if seeking is supported.
- `LDecoder:release`: Releases the decoder (no-op).
- `LDecoder:type`: Returns the type name of this object.
- `LDecoder:typeOf`: Returns true if this object is of the given type.

### `LMidiPlayer` Methods
- `LMidiPlayer:load`: Loads a MIDI file from the given path.
- `LMidiPlayer:loadData`: Loads MIDI data from a Lua string.
- `LMidiPlayer:isLoaded`: Returns true if a MIDI sequence is loaded.
- `LMidiPlayer:getFilePath`: Returns the file path of the loaded MIDI, or nil.
- `LMidiPlayer:setSoundFont`: Loads a SoundFont file into this player (stub).
- `LMidiPlayer:getSoundFontPath`: Returns the SoundFont file path, or nil (stub).
- `LMidiPlayer:useDefaultSoundFont`: Reverts to the built-in default SoundFont (stub).
- `LMidiPlayer:play`: Starts or resumes MIDI sequence playback from the current position.
- `LMidiPlayer:pause`: Pauses the MIDI sequence at the current position; resume with `play()`.
- `LMidiPlayer:stop`: Stops MIDI playback and resets the playhead to the beginning.
- `LMidiPlayer:isPlaying`: Returns true if MIDI is currently playing.
- `LMidiPlayer:isPaused`: Returns true if MIDI playback is paused.
- `LMidiPlayer:seek`: Seeks to a time position in seconds.
- `LMidiPlayer:tell`: Returns the current playback position in seconds.
- `LMidiPlayer:getDuration`: Returns the total MIDI duration in seconds.
- `LMidiPlayer:setLooping`: Enables or disables looping.
- `LMidiPlayer:isLooping`: Returns true if looping is enabled.
- `LMidiPlayer:setVolume`: Sets MIDI playback volume.
- `LMidiPlayer:getVolume`: Returns the current MIDI volume.
- `LMidiPlayer:setBus`: Routes MIDI output through a bus (or nil to clear).
- `LMidiPlayer:getBus`: Returns the assigned bus, or nil.
- `LMidiPlayer:setTempo`: Sets playback tempo in BPM.
- `LMidiPlayer:getTempo`: Returns the current tempo in BPM.
- `LMidiPlayer:getOriginalTempo`: Returns the original MIDI file tempo in BPM.
- `LMidiPlayer:setTempoScale`: Sets the tempo scale factor (1.0 = original speed).
- `LMidiPlayer:getTempoScale`: Returns the current tempo scale factor.
- `LMidiPlayer:getTicksPerBeat`: Returns the PPQ resolution from the MIDI header.
- `LMidiPlayer:setChannelVolume`: Sets volume for a MIDI channel (1-indexed).
- `LMidiPlayer:getChannelVolume`: Returns the volume for a MIDI channel (1-indexed).
- `LMidiPlayer:setChannelMuted`: Mutes or unmutes a MIDI channel (1-indexed).
- `LMidiPlayer:isChannelMuted`: Returns true if a MIDI channel is muted (1-indexed).
- `LMidiPlayer:setChannelInstrument`: Sets the GM instrument for a MIDI channel (1-indexed).
- `LMidiPlayer:getChannelInstrument`: Returns the GM instrument for a MIDI channel (1-indexed).
- `LMidiPlayer:getChannelCount`: Returns the number of MIDI channels.
- `LMidiPlayer:soloChannel`: Solos a MIDI channel (1-indexed).
- `LMidiPlayer:unsoloAll`: Clears solo on all channels.
- `LMidiPlayer:getTrackCount`: Returns the number of tracks in the MIDI sequence.
- `LMidiPlayer:getTrackName`: Returns the name of a MIDI track (1-indexed), or nil.
- `LMidiPlayer:setTrackMuted`: Mutes or unmutes a track (1-indexed).
- `LMidiPlayer:isTrackMuted`: Returns true if a track is muted (1-indexed).
- `LMidiPlayer:getNoteCount`: Returns the total note count in the MIDI sequence.
- `LMidiPlayer:setOnNoteOn`: Registers a note-on callback (stub).
- `LMidiPlayer:setOnNoteOff`: Registers a note-off callback (stub).
- `LMidiPlayer:setOnEnd`: Registers a playback-end callback (stub).
- `LMidiPlayer:getSampleRate`: Returns the PCM output sample rate in Hz.
- `LMidiPlayer:setSampleRate`: Sets the PCM output sample rate in Hz (clamped 8000-192000).
- `LMidiPlayer:getChannels`: Returns the PCM output channel count (1 = mono, 2 = stereo).
- `LMidiPlayer:setChannels`: Sets the PCM output channel count (clamped 1-2).
- `LMidiPlayer:type`: Returns the type name of this object.
- `LMidiPlayer:typeOf`: Returns true if this object is of the given type.

### `LSoundData` Methods
- `LSoundData:getSampleCount`: Get the total number of samples.
- `LSoundData:getSampleRate`: Returns the sample rate of this audio buffer in Hz (e.g. 44100 or 48000).
- `LSoundData:getChannelCount`: Get the number of channels.
- `LSoundData:getDuration`: Get the audio duration in seconds.
- `LSoundData:getBitDepth`: Returns the bit depth of this audio buffer (typically 16 or 32 bits per sample).
- `LSoundData:getSample`: Get a specific sample by index.
- `LSoundData:drawWaveform`: Draws the waveform onto an ImageData buffer.
- `LSoundData:setSample`: Set a specific sample by index.

### `LSoundPool` Methods
- `LSoundPool:play`: Plays the next available voice and returns its SoundKey as an integer.
- `LSoundPool:stopAll`: Stops all voices in this pool.
- `LSoundPool:setVolume`: Sets the volume for all voices in this pool.
- `LSoundPool:setBus`: Routes all voices through the named bus.
- `LSoundPool:release`: Releases all voices from the mixer and invalidates this pool.
- `LSoundPool:getVoiceCount`: Returns the total number of voices in this pool.
- `LSoundPool:type`: Returns the type name of this object.
- `LSoundPool:typeOf`: Returns true if the type name matches.

### `LSource` Methods
- `LSource:play`: Starts or resumes playback.
- `LSource:stop`: Stops playback and resets seek position.
- `LSource:pause`: Pauses playback at the current position.
- `LSource:resume`: Resumes playback from the paused position.
- `LSource:setVolume`: Sets playback volume (0.0 = silent, 1.0 = full).
- `LSource:getVolume`: Returns the current volume multiplier.
- `LSource:setPitch`: Sets the pitch multiplier (1.0 = normal).
- `LSource:getPitch`: Returns the current pitch multiplier.
- `LSource:setLooping`: Enables or disables looping playback.
- `LSource:isLooping`: Returns true if looping is enabled.
- `LSource:isPlaying`: Returns true if currently playing.
- `LSource:isPaused`: Returns true if playback is paused.
- `LSource:isStopped`: Returns true if playback has stopped.
- `LSource:setPan`: Sets stereo panning (-1.0 left to 1.0 right).
- `LSource:getPan`: Returns the current stereo panning value.
- `LSource:clone`: Creates an independent copy of this source.
- `LSource:getType`: Returns the source type ("static" or "stream").
- `LSource:getDuration`: Returns the total duration in seconds.
- `LSource:tell`: Returns the current playback position in seconds.
- `LSource:seek`: Seeks to a time position in seconds.
- `LSource:setLowpass`: Applies a low-pass filter at the given cutoff frequency.
- `LSource:setHighpass`: Applies a high-pass filter at the given cutoff frequency.
- `LSource:getLowpass`: Returns the low-pass filter cutoff frequency.
- `LSource:getHighpass`: Returns the high-pass filter cutoff frequency.
- `LSource:clearFilter`: Removes any active filter from this source.
- `LSource:fadeIn`: Fades in from silence over the given duration in seconds.
- `LSource:getFadeIn`: Returns the current fade-in duration in seconds.
- `LSource:type`: Returns the type name of this object.
- `LSource:typeOf`: Returns true if this object is of the given type.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Platform Services`` into `Platform Services`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/audio/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- **MIDI status**: The `midly` crate has been removed from `Cargo.toml`. Code stubs in `src/audio/midi/` remain and emit `A002_MIDI_DISABLED` log warnings at startup. To re-enable MIDI: add `midly = "0.5"` back to `Cargo.toml` and implement the disabled code paths in `midi_player.rs`. Alternatively, remove the dead code if MIDI support is not planned.
