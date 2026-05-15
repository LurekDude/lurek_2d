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

- `Bus::new` (`bus.rs`): Create a new bus with the given name, volume=1.0, pitch=1.0, unpaused, and no effects.
- `Bus::name` (`bus.rs`): Return the name of this bus.
- `Bus::volume` (`bus.rs`): Return the current volume multiplier for this bus.
- `Bus::set_volume` (`bus.rs`): Set the volume multiplier; values below 0.0 are clamped to 0.0.
- `Bus::pitch` (`bus.rs`): Return the current pitch multiplier for this bus.
- `Bus::set_pitch` (`bus.rs`): Set the pitch multiplier; values below 0.0 are clamped to 0.0.
- `Bus::pause` (`bus.rs`): Pause all sources on this bus; no-op if already paused.
- `Bus::resume` (`bus.rs`): Resume all sources on this bus; no-op if already playing.
- `Bus::is_paused` (`bus.rs`): Return `true` when this bus is paused.
- `Bus::add_effect` (`bus.rs`): Append a DSP effect of `effect_type_str` with initial parameter `p1_val` to the chain; returns the new effect ID.
- `Bus::remove_effect` (`bus.rs`): Remove the DSP effect with `effect_id` from the chain; error if not found.
- `Bus::set_duck_target` (`bus.rs`): Set the duck target bus name and duck volume; volume is clamped to 0.0..=1.0.
- `Bus::clear_duck_target` (`bus.rs`): Remove configured duck target from this bus.
- `Decoder::from_file` (`decoder.rs`): Open and fully decode `path` using rodio; `buffer_size` sets the chunk size for `decode()`.
- `Decoder::decode` (`decoder.rs`): Return the next `buffer_size` samples as a `Vec<i16>`, advancing the cursor; `None` at end.
- `Decoder::get_duration` (`decoder.rs`): Return total audio duration in seconds; 0.0 if sample rate or channel count is zero.
- `Decoder::seek` (`decoder.rs`): Seek to `offset` seconds from the start, clamping to the end of the buffer.
- `Decoder::tell` (`decoder.rs`): Return the current playback position in seconds.
- `Decoder::is_seekable` (`decoder.rs`): Return `true`; the PCM buffer always supports random-access seeking.
- `Decoder::rewind` (`decoder.rs`): Reset the read cursor to the start of the buffer.
- `AtomicParam::new` (`dsp.rs`): Create a new `AtomicParam` initialised to `val`.
- `AtomicParam::get` (`dsp.rs`): Return the current f32 value using `Relaxed` ordering.
- `AtomicParam::set` (`dsp.rs`): Store a new f32 value using `Relaxed` ordering.
- `EffectParams::new` (`dsp.rs`): Create new `EffectParams` with `id`, `typ`, and all parameters initialised to 0.0.
- `EffectParams::set_param` (`dsp.rs`): Set a named parameter on this effect; error if `param` is not valid for `typ`.
- `ActiveEffect::new` (`dsp.rs`): Allocate `ActiveEffect` for `params`, sizing `comb_buf` based on effect type and `sample_rate`.
- `ActiveEffect::process` (`dsp.rs`): Apply the effect to one `sample` on `channel`, returning the processed output sample.
- `SharedEffectGraph::new` (`dsp.rs`): Create an empty `SharedEffectGraph`.
- `new` (`dsp.rs`): Wraps an inner audio source with a dynamic DSP effect chain.
- `get_playback_devices` (`facade.rs`): Returns the names of all available audio output devices.
- `get_playback_device` (`facade.rs`): Returns the name of the currently active audio output device.
- `set_playback_device` (`facade.rs`): Selects the audio output device by name.
- `MidiState::new` (`midi.rs`): Create a new `MidiState` with no SoundFont loaded.
- `MidiState::set_soundfont` (`midi.rs`): Load `data` as an SF2 SoundFont, validating the RIFF+sfbk header; error if invalid.
- `MidiState::has_soundfont` (`midi.rs`): Return `true` when a SoundFont is loaded and ready for synthesis.
- `MidiState::clear_soundfont` (`midi.rs`): Unload the current SoundFont and clear its path.
- `MidiState::soundfont_path` (`midi.rs`): Return the source path of the loaded SoundFont, or `None` if none was loaded or path was not provided.
- `MidiState::soundfont_data` (`midi.rs`): Return a byte slice of the loaded SoundFont binary, or `None` if not loaded.
- `MidiPlayer::new` (`midi_player.rs`): Create a new MIDI player with default transport, channel, and output settings.
- `MidiPlayer::load` (`midi_player.rs`): Load MIDI bytes from `path` and pass them to `load_data`; return `false` on read or parse failure.
- `MidiPlayer::load_data` (`midi_player.rs`): Parse and prepare raw MIDI bytes for playback; currently disabled and always return `false`.
- `MidiPlayer::is_loaded` (`midi_player.rs`): Return `true` when parsed MIDI metadata is present.
- `MidiPlayer::file_path` (`midi_player.rs`): Return the loaded MIDI file path, or `None` when no file is loaded.
- `MidiPlayer::play` (`midi_player.rs`): Render the loaded MIDI to PCM and start playback on `stream_handle`; no-op if data is missing.
- `MidiPlayer::stop` (`midi_player.rs`): Stop playback, drop the sink, reset playhead to 0, and set state to `Stopped`.
- `MidiPlayer::pause` (`midi_player.rs`): Pause the active sink and set state to `Paused`.
- `MidiPlayer::resume` (`midi_player.rs`): Resume the active sink and transition from `Paused` to `Playing`.
- `MidiPlayer::is_playing` (`midi_player.rs`): Return `true` when playback state is `Playing`.
- `MidiPlayer::is_paused` (`midi_player.rs`): Return `true` when playback state is `Paused`.
- `MidiPlayer::seek` (`midi_player.rs`): Move the transport playhead to `secs`, clamped to >= 0.0.
- `MidiPlayer::tell` (`midi_player.rs`): Return the current transport playhead position in seconds.
- `MidiPlayer::duration` (`midi_player.rs`): Return song duration in seconds from metadata, or 0.0 if no MIDI is loaded.
- `MidiPlayer::set_volume` (`midi_player.rs`): Set output gain multiplier; values below 0.0 are clamped to 0.0.
- `MidiPlayer::volume` (`midi_player.rs`): Return the current output gain multiplier.
- `MidiPlayer::set_looping` (`midi_player.rs`): Enable or disable infinite playback looping.
- `MidiPlayer::is_looping` (`midi_player.rs`): Return `true` when looping playback is enabled.
- `MidiPlayer::set_tempo_scale` (`midi_player.rs`): Set tempo multiplier; clamped to at least 0.01.
- `MidiPlayer::tempo_scale` (`midi_player.rs`): Return the current tempo multiplier.
- `MidiPlayer::current_bpm` (`midi_player.rs`): Return the current effective BPM after tempo scaling.
- `MidiPlayer::original_tempo` (`midi_player.rs`): Return original BPM from MIDI metadata, or 120.0 when metadata is unavailable.
- `MidiPlayer::ticks_per_beat` (`midi_player.rs`): Return MIDI ticks-per-beat from metadata, or 0 when unavailable.
- `MidiPlayer::set_channel_volume` (`midi_player.rs`): Set channel volume for channel `ch` in 0..16; ignored for out-of-range channels.
- `MidiPlayer::channel_volume` (`midi_player.rs`): Return channel volume for `ch`, or 0.0 when `ch` is out of range.
- `MidiPlayer::set_channel_muted` (`midi_player.rs`): Set mute state for channel `ch` in 0..16; ignored for out-of-range channels.
- `MidiPlayer::is_channel_muted` (`midi_player.rs`): Return `true` when channel `ch` is muted and in range.
- `MidiPlayer::set_channel_instrument` (`midi_player.rs`): Set program/instrument number for channel `ch` in 0..16; ignored when out of range.
- `MidiPlayer::channel_instrument` (`midi_player.rs`): Return instrument number for channel `ch`, or 0 when out of range.
- `MidiPlayer::channel_count` (`midi_player.rs`): Return number of channels that contain note data in loaded metadata.
- `MidiPlayer::solo_channel` (`midi_player.rs`): Solo channel `ch` by muting all other channels.
- `MidiPlayer::unsolo_all` (`midi_player.rs`): Clear all channel mutes set by `solo_channel`.
- `MidiPlayer::track_count` (`midi_player.rs`): Return number of tracks in loaded metadata.
- `MidiPlayer::track_name` (`midi_player.rs`): Return optional track name for `idx`, or `None` if unavailable.
- `MidiPlayer::set_track_muted` (`midi_player.rs`): Set mute state for track `idx`; ignored if out of range.
- `MidiPlayer::is_track_muted` (`midi_player.rs`): Return `true` when track `idx` exists and is muted.
- `MidiPlayer::note_count` (`midi_player.rs`): Return total note event count in loaded metadata.
- `MidiPlayer::set_bus_key` (`midi_player.rs`): Assign or clear the mixer bus key used for this MIDI source.
- `MidiPlayer::bus_key` (`midi_player.rs`): Return the assigned mixer bus key, if any.
- `MidiPlayer::play_state` (`midi_player.rs`): Return current transport state.
- `MidiPlayer::get_output_sample_rate` (`midi_player.rs`): Return output sample rate used by MIDI PCM rendering.
- `MidiPlayer::set_output_sample_rate` (`midi_player.rs`): Set output sample rate, clamped to 8000..=192000 Hz.
- `MidiPlayer::get_output_channels` (`midi_player.rs`): Return output channel count used by MIDI PCM rendering.
- `MidiPlayer::set_output_channels` (`midi_player.rs`): Set output channel count, clamped to mono or stereo (1..=2).
- `QueueableSource::new` (`mixer.rs`): Create a queueable source with given sample rate, bit depth, channels, and buffer slot count.
- `QueueableSource::queue_buffer` (`mixer.rs`): Push `data` into the next free buffer slot; error if no slots are available.
- `QueueableSource::free_buffer_count` (`mixer.rs`): Return the number of unused buffer slots available for queuing.
- `Mixer::new` (`mixer.rs`): Create a new mixer, attempting to open the default audio output stream.
- `Mixer::stream_handle` (`mixer.rs`): Return a reference to the rodio output stream handle, or `None` if audio is unavailable.
- `Mixer::load_source` (`mixer.rs`): Register a new source entry for `file_path` with given `source_type` and return its key.
- `Mixer::play` (`mixer.rs`): Start or restart playback for the source; applies bus volume/pitch and builds a new sink.
- `Mixer::stop` (`mixer.rs`): Stop playback, drop the sink, and reset accumulated position to zero.
- `Mixer::set_volume` (`mixer.rs`): Set per-source volume multiplier; clamped to [0.0, 2.0] and applied to the active sink.
- `Mixer::get_volume` (`mixer.rs`): Return per-source volume multiplier, or 1.0 if the key is invalid.
- `Mixer::pause` (`mixer.rs`): Pause the source sink and accumulate elapsed play time.
- `Mixer::resume` (`mixer.rs`): Resume the paused source sink and restart the play-time clock.
- `Mixer::set_pitch` (`mixer.rs`): Set per-source pitch/speed multiplier; clamped to [0.1, 4.0] and applied to the active sink.
- `Mixer::get_pitch` (`mixer.rs`): Return per-source pitch multiplier, or 1.0 if the key is invalid.
- `Mixer::set_speed` (`mixer.rs`): Set playback speed (alias for `set_pitch`).
- `Mixer::is_playing` (`mixer.rs`): Return `true` when the source sink is active and not paused.
- `Mixer::get_play_state` (`mixer.rs`): Return the current transport state of the source by inspecting its sink.
- `Mixer::is_paused` (`mixer.rs`): Return `true` when the source is currently paused.
- `Mixer::is_stopped` (`mixer.rs`): Return `true` when the source is stopped or its sink is empty.
- `Mixer::set_looping` (`mixer.rs`): Set whether this source should loop.
- `Mixer::is_looping` (`mixer.rs`): Return `true` when the source is configured to loop.
- `Mixer::play_looping` (`mixer.rs`): Enable looping and start playback in one call.
- `Mixer::set_pan` (`mixer.rs`): Set stereo pan position; clamped to [-1.0, 1.0].
- `Mixer::get_pan` (`mixer.rs`): Return per-source pan position, or 0.0 if the key is invalid.
- `Mixer::set_master_volume` (`mixer.rs`): Set global master volume; clamped to [0.0, 1.0] and propagated to all active sinks.
- `Mixer::get_master_volume` (`mixer.rs`): Return the current master volume multiplier.
- `Mixer::get_source_type` (`mixer.rs`): Return the backing source type for the given key, or `None` if invalid.
- `Mixer::get_active_source_count` (`mixer.rs`): Return the number of sources currently playing (active sink, not paused).
- `Mixer::get_source_count` (`mixer.rs`): Return total number of registered sources (playing, paused, or stopped).
- `Mixer::contains_source` (`mixer.rs`): Return `true` when the source key is registered in the mixer.
- `Mixer::pause_all` (`mixer.rs`): Pause all playing sources and accumulate their elapsed time.
- `Mixer::stop_all` (`mixer.rs`): Stop all sources, drop their sinks, and reset positions to zero.
- `Mixer::resume_all` (`mixer.rs`): Resume all paused sources and restart their play-time clocks.
- `Mixer::clone_source` (`mixer.rs`): Clone a source entry (stopped, no sink) preserving its settings; return the new key.
- `Mixer::release` (`mixer.rs`): Remove and stop the source identified by `key`; return `true` if it existed.
- `Mixer::set_peak` (`mixer.rs`): Set the measured peak amplitude for a source; clamped to [0.0, 1.0].
- `Mixer::get_peak` (`mixer.rs`): Return the last measured peak amplitude for the source, or 0.0 if invalid.
- `Mixer::bus_peak` (`mixer.rs`): Return average peak of all sources assigned to the given bus.
- `Mixer::new_bus` (`mixer.rs`): Create a new named bus and return its key.
- `Mixer::get_bus_by_name` (`mixer.rs`): Find a bus key by its human-readable name.
- `Mixer::get_bus` (`mixer.rs`): Return a shared reference to the bus, or `None` if the key is invalid.
- `Mixer::get_bus_mut` (`mixer.rs`): Return a mutable reference to the bus, or `None` if the key is invalid.
- `Mixer::set_source_bus` (`mixer.rs`): Assign or clear the bus routing for a source.
- `Mixer::get_source_bus` (`mixer.rs`): Return the bus key assigned to this source, or `None` if unassigned.
- `Mixer::get_duration` (`mixer.rs`): Return cached total duration of the source in seconds, or `None` if unknown.
- `Mixer::get_tell` (`mixer.rs`): Return the current playback position in seconds based on accumulated and elapsed time.
- `Mixer::seek` (`mixer.rs`): Seek the source to `position_secs`, rebuilding the sink from that offset.
- `Mixer::set_lowpass` (`mixer.rs`): Set low-pass filter cutoff frequency in Hz for the source.
- `Mixer::clear_lowpass` (`mixer.rs`): Remove the low-pass filter from the source.
- `Mixer::set_highpass` (`mixer.rs`): Set high-pass filter cutoff frequency in Hz for the source.
- `Mixer::clear_highpass` (`mixer.rs`): Remove the high-pass filter from the source.
- `Mixer::clear_filter` (`mixer.rs`): Remove both low-pass and high-pass filters from the source.
- `Mixer::get_lowpass` (`mixer.rs`): Return the low-pass cutoff in Hz, or `None` if no low-pass is set.
- `Mixer::get_highpass` (`mixer.rs`): Return the high-pass cutoff in Hz, or `None` if no high-pass is set.
- `Mixer::set_fade_in` (`mixer.rs`): Set fade-in duration in seconds; clamped to >= 0.0.
- `Mixer::clear_fade_in` (`mixer.rs`): Remove configured fade-in from the source.
- `Mixer::get_fade_in` (`mixer.rs`): Return the configured fade-in duration in seconds, or `None` if unset.
- `Mixer::set_source_position` (`mixer.rs`): Set 3D source position and update pan from horizontal offset to listener.
- `Mixer::get_source_position` (`mixer.rs`): Return the 3D position of the source, or `[0,0,0]` if spatial state is unset.
- `Mixer::set_source_velocity` (`mixer.rs`): Set 3D source velocity for doppler calculations.
- `Mixer::get_source_velocity` (`mixer.rs`): Return the 3D velocity of the source, or `[0,0,0]` if spatial state is unset.
- `Mixer::set_source_orientation` (`mixer.rs`): Set 3D source orientation as forward and up vectors.
- `Mixer::get_source_orientation` (`mixer.rs`): Return the source orientation as `[fx,fy,fz,ux,uy,uz]`, or default forward-Z/up-Y.
- `Mixer::set_listener_position` (`mixer.rs`): Set the 3D listener position for spatial audio.
- `Mixer::get_listener_position` (`mixer.rs`): Return the current listener position.
- `Mixer::set_listener_orientation` (`mixer.rs`): Set the listener orientation as forward and up vectors.
- `Mixer::get_listener_orientation` (`mixer.rs`): Return the current listener orientation as `[fx,fy,fz,ux,uy,uz]`.
- `Mixer::set_listener_velocity` (`mixer.rs`): Set the listener velocity vector for doppler calculations.
- `Mixer::get_listener_velocity` (`mixer.rs`): Return the current listener velocity.
- `Mixer::set_doppler_scale` (`mixer.rs`): Set the doppler effect intensity multiplier; clamped to >= 0.0.
- `Mixer::get_doppler_scale` (`mixer.rs`): Return the current doppler scale.
- `Mixer::set_distance_model` (`mixer.rs`): Set the distance attenuation model name.
- `Mixer::get_distance_model` (`mixer.rs`): Return the name of the active distance model.
- `Mixer::new_queueable` (`mixer.rs`): Create a new queueable push-buffer source and return its key.
- `Mixer::queue_buffer` (`mixer.rs`): Push sample data into the queueable source's next free buffer slot.
- `Mixer::queueable_free_buffer_count` (`mixer.rs`): Return the number of free buffer slots for the given queueable source.
- `Mixer::play_queueable` (`mixer.rs`): Start playback of the queueable source (stub: not yet implemented).
- `Mixer::stop_queueable` (`mixer.rs`): Stop the queueable source and return all buffers to the free pool.
- `Mixer::release_queueable` (`mixer.rs`): Remove the queueable source from the mixer; return `true` if it existed.
- `Mixer::set_stereo_width` (`mixer.rs`): Set stereo width for the source; error if the key is invalid.
- `Mixer::get_stereo_width` (`mixer.rs`): Return the stereo width for the source; error if the key is invalid.
- `Mixer::set_random_pitch` (`mixer.rs`): Set a random pitch range `[min, max]` applied each time the source plays; error if min > max.
- `Mixer::clear_random_pitch` (`mixer.rs`): Remove the random pitch range from the source.
- `Mixer::crossfade` (`mixer.rs`): Crossfade from one source to another over `duration_secs`; stops the outgoing source.
- `Mixer::get_bus_peak` (`mixer.rs`): Return average peak amplitude of all sources on the named bus; error if bus not found.
- `Mixer::get_bus_rms` (`mixer.rs`): Return RMS level of the named bus (stub: always 0.0); error if bus not found.
- `Mixer::new_pool` (`mixer.rs`): Create a new sound pool with `voice_count` preloaded copies of `file_path`.
- `process_offline` (`offline.rs`): Decodes `input_path`, applies `effects` in series, and writes the result to `output_path`.
- `normalize_file` (`offline.rs`): Normalises the peak amplitude of `input_path` to `target_level` and writes to `output_path`.
- `SoundPool::new` (`pool.rs`): Create a pool with `keys` and source `file_path`, defaulting to volume=1.0 and no bus.
- `SoundPool::voice_count` (`pool.rs`): Return number of voices in this pool.
- `SoundPool::file_path` (`pool.rs`): Return source file path associated with this pool.
- `SoundPool::volume` (`pool.rs`): Return current pool gain multiplier.
- `SoundPool::set_volume` (`pool.rs`): Set pool gain multiplier; values below 0.0 are clamped to 0.0.
- `SoundPool::bus_name` (`pool.rs`): Return assigned bus name, or `None` if unassigned.
- `SoundPool::set_bus` (`pool.rs`): Assign this pool to bus `name`.
- `SoundPool::clear_bus` (`pool.rs`): Remove any bus assignment from this pool.
- `SoundPool::next_voice` (`pool.rs`): Return next voice key in round-robin order and advance the cursor.
- `SoundPool::all_keys` (`pool.rs`): Return all voice keys managed by this pool.
- `SoundPool::is_valid` (`pool.rs`): Return `true` when the pool contains at least one voice key.
- `SoundData::new` (`sound_data.rs`): Allocate silent audio buffer with `sample_count` frames and `channels` interleaved channels.
- `SoundData::from_samples` (`sound_data.rs`): Construct from an existing interleaved sample vector.
- `SoundData::from_lua_args` (`sound_data.rs`): Build `SoundData` from Lua arguments: load file when `path` is set, otherwise allocate silent buffer.
- `SoundData::from_file` (`sound_data.rs`): Decode audio file at `path` into f32 interleaved samples.
- `SoundData::get_sample` (`sound_data.rs`): Return sample value at `index`, or `None` when out of bounds.
- `SoundData::samples` (`sound_data.rs`): Return all interleaved samples as a shared slice.
- `SoundData::set_sample` (`sound_data.rs`): Set sample at `index` to `value` (clamped to [-1,1]); return `false` if index is invalid.
- `SoundData::sample_count` (`sound_data.rs`): Return number of frames (samples per channel), not raw interleaved element count.
- `SoundData::sample_rate` (`sound_data.rs`): Return sample rate in Hz.
- `SoundData::channel_count` (`sound_data.rs`): Return channel count.
- `SoundData::bit_depth` (`sound_data.rs`): Return logical bit depth metadata.
- `SoundData::duration` (`sound_data.rs`): Return duration in seconds.
- `SoundData::as_samples` (`sound_data.rs`): Return interleaved sample slice.
- `SoundData::encode_wav` (`sound_data.rs`): Encode current samples as an in-memory 16-bit PCM WAV byte vector.
- `SoundData::sine_wave` (`sound_data.rs`): Generate mono sine-wave `SoundData` at `freq` Hz for `duration` seconds.
- `SoundData::square_wave` (`sound_data.rs`): Generate mono square-wave `SoundData` at `freq` Hz for `duration` seconds.
- `SoundData::sawtooth_wave` (`sound_data.rs`): Generate mono sawtooth-wave `SoundData` at `freq` Hz for `duration` seconds.
- `SoundData::triangle_wave` (`sound_data.rs`): Generate mono triangle-wave `SoundData` at `freq` Hz for `duration` seconds.
- `SoundData::white_noise` (`sound_data.rs`): Generate mono white-noise `SoundData` using deterministic LCG seeded by `seed`.
- `SoundData::draw_waveform` (`sound_data.rs`): Draw waveform envelope into `img` as vertical min/max bars in RGBA colour `(r,g,b,a)`.
- `SoundData::apply_lowpass` (`sound_data.rs`): Apply one-pole low-pass filter in place with cutoff `cutoff_hz`.
- `SoundData::apply_highpass` (`sound_data.rs`): Apply one-pole high-pass filter in place with cutoff `cutoff_hz`.
- `SoundData::apply_bandpass` (`sound_data.rs`): Apply simple band-pass by chaining `apply_highpass(low_hz)` then `apply_lowpass(high_hz)`.
- `SoundData::apply_gain` (`sound_data.rs`): Multiply all samples by `gain` and clamp to [-1.0, 1.0].
- `SoundData::mix_into` (`sound_data.rs`): Mix `other` into `self` sample-by-sample, extending length if needed and clamping output to [-1,1].
- `AudioSource::new` (`source.rs`): Create a new source descriptor with volume=1.0 and looping disabled.
- `waveform_to_png` (`visualizer.rs`): Renders the amplitude waveform of `input_wav` to a PNG file at `output_png`.
- `spectrogram_to_png` (`visualizer.rs`): Renders a time–frequency spectrogram of `input_wav` to a PNG file at `output_png`.

## Lua API Reference

- Binding path(s): `src/lua_api/audio_api.rs`
- Namespace: `lurek.audio`

### Module Functions
- `lurek.audio.newSource`: Creates a new audio source from a file path, either fully loaded or streaming.
- `lurek.audio.play`: Starts playback of a source by handle, optionally routing through a named bus.
- `lurek.audio.stop`: Stops playback of a source and resets its position to the beginning.
- `lurek.audio.setVolume`: Sets the volume of a source by handle.
- `lurek.audio.getVolume`: Returns the current volume of a source.
- `lurek.audio.pause`: Pauses playback of a source at its current position.
- `lurek.audio.resume`: Resumes playback of a paused source.
- `lurek.audio.setPitch`: Sets the pitch multiplier of a source, affecting playback speed and tone.
- `lurek.audio.getPitch`: Returns the current pitch multiplier of a source.
- `lurek.audio.isPlaying`: Returns whether a source is currently playing.
- `lurek.audio.isPaused`: Returns whether a source is currently paused.
- `lurek.audio.isStopped`: Returns whether a source is currently stopped.
- `lurek.audio.setLooping`: Enables or disables looping for a source.
- `lurek.audio.isLooping`: Returns whether a source has looping enabled.
- `lurek.audio.playLooping`: Starts playback of a source with looping enabled in one call.
- `lurek.audio.setPan`: Sets the stereo panning of a source.
- `lurek.audio.getPan`: Returns the current stereo pan position of a source.
- `lurek.audio.setMasterVolume`: Sets the global master volume affecting all audio output.
- `lurek.audio.getMasterVolume`: Returns the current global master volume level.
- `lurek.audio.getActiveSourceCount`: Returns the number of sources currently playing audio.
- `lurek.audio.getSourceCount`: Returns the total number of loaded audio sources (playing or idle).
- `lurek.audio.getSourceType`: Returns whether a source is static or streaming.
- `lurek.audio.clone`: Creates an independent copy of a source sharing the same audio data.
- `lurek.audio.pauseAll`: Pauses all currently playing audio sources.
- `lurek.audio.stopAll`: Stops all audio sources and resets their positions.
- `lurek.audio.resumeAll`: Resumes all paused audio sources.
- `lurek.audio.release`: Releases an audio source, freeing its memory and stopping playback.
- `lurek.audio.newBus`: Creates a new audio mixing bus for grouping and controlling sources.
- `lurek.audio.setSourceBus`: Routes a source through a specific audio bus for grouped mixing.
- `lurek.audio.getSourceBus`: Returns the bus a source is routed through.
- `lurek.audio.getMaxSources`: Returns the maximum number of simultaneous audio sources supported.
- `lurek.audio.getDuration`: Returns the total duration of a source in seconds.
- `lurek.audio.tell`: Returns the current playback position of a source in seconds.
- `lurek.audio.seek`: Seeks a source to a specific position in seconds.
- `lurek.audio.setLowpass`: Applies a lowpass filter to a source, attenuating high frequencies.
- `lurek.audio.setHighpass`: Applies a highpass filter to a source, attenuating low frequencies.
- `lurek.audio.getLowpass`: Returns the current lowpass filter cutoff of a source.
- `lurek.audio.getHighpass`: Returns the current highpass filter cutoff of a source.
- `lurek.audio.clearFilter`: Removes all frequency filters from a source.
- `lurek.audio.fadeIn`: Sets the fade-in duration for a source so it ramps from silence on play.
- `lurek.audio.getFadeIn`: Returns the configured fade-in duration of a source.
- `lurek.audio.setListener2D`: Sets the 2D listener position for spatial audio calculations.
- `lurek.audio.getListener2D`: Returns the current 2D listener position.
- `lurek.audio.setListener`: Sets the 3D listener position for spatial audio (Z defaults to 0 for 2D games).
- `lurek.audio.getListener`: Returns the current 3D listener position.
- `lurek.audio.setPosition`: Sets the 3D position of a source for spatial audio panning and attenuation.
- `lurek.audio.getPosition`: Returns the 3D position of a source.
- `lurek.audio.setVelocity`: Sets the velocity of a source for Doppler effect calculations.
- `lurek.audio.getVelocity`: Returns the velocity vector of a source.
- `lurek.audio.setOrientation`: Sets the orientation of a source using forward and up vectors.
- `lurek.audio.getOrientation`: Returns the orientation vectors of a source.
- `lurek.audio.setDopplerScale`: Sets the global Doppler effect intensity multiplier.
- `lurek.audio.getDopplerScale`: Returns the current global Doppler effect scale.
- `lurek.audio.setDistanceModel`: Sets the distance attenuation model for spatial audio.
- `lurek.audio.getDistanceModel`: Returns the current distance attenuation model name.
- `lurek.audio.setMeter`: Sets the master peak level for metering purposes.
- `lurek.audio.getMeter`: Returns the current master peak level for VU-meter displays.
- `lurek.audio.newMidiPlayer`: Creates a new MIDI player instance, optionally loading a file immediately.
- `lurek.audio.newSoundData`: Creates a new SoundData object from a file path or blank buffer for procedural audio.
- `lurek.audio.setMidiSoundFont`: Lua-facing function documented in the binding source.
- `lurek.audio.hasMidiSoundFont`: Lua-facing function documented in the binding source.
- `lurek.audio.clearMidiSoundFont`: Lua-facing function documented in the binding source.
- `lurek.audio.newDecoder`: Lua-facing function documented in the binding source.
- `lurek.audio.newQueueableSource`: Lua-facing function documented in the binding source.
- `lurek.audio.queueSource`: Lua-facing function documented in the binding source.
- `lurek.audio.getFreeBufferCount`: Lua-facing function documented in the binding source.
- `lurek.audio.playQueueable`: Lua-facing function documented in the binding source.
- `lurek.audio.stopQueueable`: Lua-facing function documented in the binding source.
- `lurek.audio.getPlaybackDevices`: Lua-facing function documented in the binding source.
- `lurek.audio.getPlaybackDevice`: Lua-facing function documented in the binding source.
- `lurek.audio.setPlaybackDevice`: Lua-facing function documented in the binding source.
- `lurek.audio.create_bus`: Lua-facing function documented in the binding source.
- `lurek.audio.set_bus_volume`: Overwrites one normalized PCM sample value in this sound buffer.
- `lurek.audio.add_effect`: Lua-facing function documented in the binding source.
- `lurek.audio.remove_effect`: Lua-facing function documented in the binding source.
- `lurek.audio.set_effect_param`: Lua-facing function documented in the binding source.
- `lurek.audio.newSineWave`: Lua-facing function documented in the binding source.
- `lurek.audio.newSquareWave`: Lua-facing function documented in the binding source.
- `lurek.audio.newSawtoothWave`: Lua-facing function documented in the binding source.
- `lurek.audio.newTriangleWave`: Lua-facing function documented in the binding source.
- `lurek.audio.newWhiteNoise`: Lua-facing function documented in the binding source.
- `lurek.audio.applyLowpass`: Lua-facing function documented in the binding source.
- `lurek.audio.applyHighpass`: Lua-facing function documented in the binding source.
- `lurek.audio.applyBandpass`: Lua-facing function documented in the binding source.
- `lurek.audio.applyGain`: Lua-facing function documented in the binding source.
- `lurek.audio.mixInto`: Lua-facing function documented in the binding source.
- `lurek.audio.saveWAV`: Lua-facing function documented in the binding source.
- `lurek.audio.setStereoWidth`: Lua-facing function documented in the binding source.
- `lurek.audio.getStereoWidth`: Lua-facing function documented in the binding source.
- `lurek.audio.setRandomPitch`: Lua-facing function documented in the binding source.
- `lurek.audio.clearRandomPitch`: Lua-facing function documented in the binding source.
- `lurek.audio.crossfade`: Lua-facing function documented in the binding source.
- `lurek.audio.getBusPeak`: Lua-facing function documented in the binding source.
- `lurek.audio.getBusRms`: Lua-facing function documented in the binding source.
- `lurek.audio.newPool`: Lua-facing function documented in the binding source.
- `lurek.audio.processOffline`: Lua-facing function documented in the binding source.
- `lurek.audio.normalizeFile`: Lua-facing function documented in the binding source.
- `lurek.audio.waveformToPng`: Lua-facing function documented in the binding source.
- `lurek.audio.spectrogramToPng`: Lua-facing function documented in the binding source.

### `LBus` Methods
- `LBus:getName`: Returns the name of this audio bus.
- `LBus:setVolume`: Sets the volume multiplier for all sources routed through this bus.
- `LBus:getVolume`: Returns the current volume multiplier of this bus.
- `LBus:setPitch`: Sets the pitch multiplier applied to all sources routed through this bus.
- `LBus:getPitch`: Returns the current pitch multiplier of this bus.
- `LBus:pause`: Pauses all sources routed through this bus.
- `LBus:resume`: Resumes all sources routed through this bus that were paused.
- `LBus:isPaused`: Returns whether this bus is currently paused.
- `LBus:type`: Returns the type name of this object for runtime type-checking.
- `LBus:typeOf`: Checks whether this object matches the given type name.
- `LBus:setDuckTarget`: Configures ducking so this bus lowers the volume of a target bus when active.
- `LBus:clearDuck`: Removes the ducking configuration from this bus.
- `LBus:getPeak`: Returns the current peak amplitude level of this bus for VU-meter displays.

### `LDecoder` Methods
- `LDecoder:decode`: Decodes the next chunk of audio data and returns it as a SoundData object.
- `LDecoder:getChannelCount`: Returns the number of audio channels in the source file.
- `LDecoder:getBitDepth`: Returns the bit depth of the source audio file.
- `LDecoder:getSampleRate`: Returns the sample rate of the source audio file.
- `LDecoder:getDuration`: Returns the total duration of the source audio file in seconds.
- `LDecoder:seek`: Seeks to a specific position in the audio stream.
- `LDecoder:rewind`: Rewinds the decoder back to the beginning of the audio stream.
- `LDecoder:tell`: Returns the current read position in the audio stream in seconds.
- `LDecoder:isSeekable`: Returns whether this decoder supports seeking.
- `LDecoder:release`: Releases decoder resources (no-op, kept for API symmetry).
- `LDecoder:type`: Returns the type name of this object for runtime type-checking.
- `LDecoder:typeOf`: Checks whether this object matches the given type name.

### `LMidiPlayer` Methods
- `LMidiPlayer:load`: Loads a MIDI file from the given path relative to the game directory.
- `LMidiPlayer:loadData`: Loads MIDI data from a raw byte string in memory.
- `LMidiPlayer:isLoaded`: Returns whether a MIDI file is currently loaded and ready to play.
- `LMidiPlayer:getFilePath`: Returns the file path of the currently loaded MIDI file.
- `LMidiPlayer:setSoundFont`: Sets a custom SoundFont file for MIDI synthesis (stub, not yet implemented).
- `LMidiPlayer:getSoundFontPath`: Returns the path of the currently set SoundFont (stub, not yet implemented).
- `LMidiPlayer:useDefaultSoundFont`: Reverts to the built-in default SoundFont (stub, not yet implemented).
- `LMidiPlayer:play`: Starts MIDI playback from the current position using the audio output stream.
- `LMidiPlayer:pause`: Pauses MIDI playback at the current position.
- `LMidiPlayer:stop`: Stops MIDI playback and resets position to the beginning.
- `LMidiPlayer:isPlaying`: Returns whether the MIDI player is currently playing.
- `LMidiPlayer:isPaused`: Returns whether the MIDI player is currently paused.
- `LMidiPlayer:seek`: Seeks to a specific position in the MIDI file.
- `LMidiPlayer:tell`: Returns the current playback position of the MIDI player in seconds.
- `LMidiPlayer:getDuration`: Returns the total duration of the loaded MIDI file in seconds.
- `LMidiPlayer:setLooping`: Enables or disables looping for MIDI playback.
- `LMidiPlayer:isLooping`: Returns whether MIDI looping is enabled.
- `LMidiPlayer:setVolume`: Sets the master volume for MIDI playback.
- `LMidiPlayer:getVolume`: Returns the current master volume of the MIDI player.
- `LMidiPlayer:setBus`: Routes this MIDI player's output through the specified audio bus.
- `LMidiPlayer:getBus`: Returns the audio bus this MIDI player is routed through.
- `LMidiPlayer:setTempo`: Sets the playback tempo in beats per minute.
- `LMidiPlayer:getTempo`: Returns the current effective tempo in beats per minute.
- `LMidiPlayer:getOriginalTempo`: Returns the original tempo of the MIDI file as authored.
- `LMidiPlayer:setTempoScale`: Sets a tempo multiplier relative to the original speed.
- `LMidiPlayer:getTempoScale`: Returns the current tempo scale multiplier.
- `LMidiPlayer:getTicksPerBeat`: Returns the MIDI file's resolution in ticks per beat (PPQN).
- `LMidiPlayer:setChannelVolume`: Sets the volume for a specific MIDI channel (1-16).
- `LMidiPlayer:getChannelVolume`: Returns the volume of a specific MIDI channel.
- `LMidiPlayer:setChannelMuted`: Mutes or unmutes a specific MIDI channel.
- `LMidiPlayer:isChannelMuted`: Returns whether a specific MIDI channel is muted.
- `LMidiPlayer:setChannelInstrument`: Sets the General MIDI instrument program for a channel.
- `LMidiPlayer:getChannelInstrument`: Returns the current GM instrument program for a channel.
- `LMidiPlayer:getChannelCount`: Returns the number of active MIDI channels in the loaded file.
- `LMidiPlayer:soloChannel`: Solos a specific MIDI channel, muting all others.
- `LMidiPlayer:unsoloAll`: Removes solo from all channels, restoring normal playback.
- `LMidiPlayer:getTrackCount`: Returns the number of tracks in the loaded MIDI file.
- `LMidiPlayer:getTrackName`: Returns the name of a MIDI track by 1-based index.
- `LMidiPlayer:setTrackMuted`: Mutes or unmutes a specific MIDI track.
- `LMidiPlayer:isTrackMuted`: Returns whether a specific MIDI track is muted.
- `LMidiPlayer:getNoteCount`: Returns the total number of note events in the loaded MIDI file.
- `LMidiPlayer:setOnNoteOn`: Registers a callback for MIDI note-on events (stub, not yet implemented).
- `LMidiPlayer:setOnNoteOff`: Registers a callback for MIDI note-off events (stub, not yet implemented).
- `LMidiPlayer:setOnEnd`: Registers a callback invoked when MIDI playback finishes (stub, not yet implemented).
- `LMidiPlayer:getSampleRate`: Returns the output sample rate used for MIDI synthesis.
- `LMidiPlayer:setSampleRate`: Sets the output sample rate for MIDI synthesis.
- `LMidiPlayer:getChannels`: Returns the number of output audio channels for MIDI synthesis.
- `LMidiPlayer:setChannels`: Sets the number of output audio channels for MIDI synthesis.
- `LMidiPlayer:type`: Returns the type name of this object for runtime type-checking.
- `LMidiPlayer:typeOf`: Checks whether this object matches the given type name.

### `LSoundData` Methods
- `LSoundData:getSampleCount`: Returns the total number of samples stored in this sound buffer.
- `LSoundData:getSampleRate`: Returns the playback sample rate of this sound buffer.
- `LSoundData:getChannelCount`: Returns the number of audio channels stored in this sound buffer.
- `LSoundData:getDuration`: Returns the approximate playback duration of this sound buffer.
- `LSoundData:getBitDepth`: Returns the sample bit depth of this sound buffer.
- `LSoundData:getSample`: Returns the sample value at the given zero-based sample index.
- `LSoundData:drawWaveform`: Draws this sound buffer as a waveform into an image buffer.
- `LSoundData:setSample`: Overwrites the sample value at the given zero-based sample index.

### `LSoundPool` Methods
- `LSoundPool:play`: Plays the next available voice from the pool in round-robin order.
- `LSoundPool:stopAll`: Stops all voices in this sound pool immediately.
- `LSoundPool:setVolume`: Sets the volume for all voices in this pool.
- `LSoundPool:setBus`: Routes all voices in this pool through the named audio bus.
- `LSoundPool:release`: Releases all voices and frees audio resources held by this pool.
- `LSoundPool:getVoiceCount`: Returns the number of pre-allocated voices in this pool.
- `LSoundPool:type`: Returns the type name of this object for runtime type-checking.
- `LSoundPool:typeOf`: Checks whether this object matches the given type name.

### `LSource` Methods
- `LSource:play`: Starts playback of this audio source from the current position.
- `LSource:stop`: Stops playback and resets the source position to the beginning.
- `LSource:pause`: Pauses playback at the current position, allowing later resumption.
- `LSource:resume`: Resumes playback from the position where the source was paused.
- `LSource:setVolume`: Sets the volume level of this source where 0.0 is silent and 1.0 is full volume.
- `LSource:getVolume`: Returns the current volume level of this audio source.
- `LSource:setPitch`: Sets the playback speed multiplier, affecting both pitch and duration.
- `LSource:getPitch`: Returns the current pitch multiplier of this audio source.
- `LSource:setLooping`: Enables or disables looping so the source restarts automatically after finishing.
- `LSource:isLooping`: Returns whether this source is set to loop continuously.
- `LSource:isPlaying`: Returns whether this source is currently playing audio.
- `LSource:isPaused`: Returns whether this source is currently paused.
- `LSource:isStopped`: Returns whether this source is currently stopped (not playing or paused).
- `LSource:setPan`: Sets the stereo panning position of this source.
- `LSource:getPan`: Returns the current stereo panning position of this source.
- `LSource:clone`: Creates an independent copy of this source sharing the same audio data.
- `LSource:getType`: Returns whether this source was loaded as static (fully in memory) or streaming.
- `LSource:getDuration`: Returns the total duration of this audio source in seconds.
- `LSource:tell`: Returns the current playback position of this source in seconds.
- `LSource:seek`: Seeks to a specific position in seconds within this audio source.
- `LSource:setLowpass`: Applies a lowpass filter that attenuates frequencies above the cutoff.
- `LSource:setHighpass`: Applies a highpass filter that attenuates frequencies below the cutoff.
- `LSource:getLowpass`: Returns the current lowpass filter cutoff frequency in Hertz.
- `LSource:getHighpass`: Returns the current highpass filter cutoff frequency in Hertz.
- `LSource:clearFilter`: Removes all frequency filters (lowpass and highpass) from this source.
- `LSource:fadeIn`: Sets the fade-in duration so the source ramps from silence to full volume on play.
- `LSource:getFadeIn`: Returns the configured fade-in duration for this source.
- `LSource:type`: Returns the type name of this object for runtime type-checking.
- `LSource:typeOf`: Checks whether this object is of the given type name or a parent type.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Platform Services`` into `Platform Services`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/audio/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- **MIDI status**: The `midly` crate has been removed from `Cargo.toml`. Code stubs in `src/audio/midi/` remain and emit `A002_MIDI_DISABLED` log warnings at startup. To re-enable MIDI: add `midly = "0.5"` back to `Cargo.toml` and implement the disabled code paths in `midi_player.rs`. Alternatively, remove the dead code if MIDI support is not planned.
