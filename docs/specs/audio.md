# `audio` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.audio` |
| **Source** | `src/audio/` |
| **Rust Tests** | `tests/rust/unit/audio_tests.rs`, `tests/rust/unit/audio_sound_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_audio.lua`, `tests/lua/unit/test_audio_bus.lua`, `tests/lua/unit/test_audio_dsp.lua`, `tests/lua/integration/test_audio_timer.lua`, `tests/lua/integration/test_audio_event.lua`, `tests/lua/evidence/test_evidence_audio.lua`, `tests/lua/evidence/test_evidence_audio_bus.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The audio module is Lurek2D's playback and mixing backend. It owns sound loading and decoding, per-source playback state, bus routing, master volume, spatial audio state, queueable PCM playback, and the DSP chain used to apply filters and other real-time effects to audio sources and buses.

This module exists so gameplay code can treat sound as engine-managed resources instead of juggling raw backend handles. `Mixer` is the operational center, `Bus` provides grouped control over multiple sources, `SoundData` exposes editable PCM data to Lua, and the DSP types make effect updates safe to push from the main thread while playback continues on the audio thread.

It intentionally does not own filesystem sandboxing, frame timing, or scripting registration. Audio files still come through `filesystem`, the app loop decides when scripts call playback functions, and `src/lua_api/audio_api.rs` decides how the audio surface is exposed to Lua. It also does not currently provide a full multi-device backend or a finished MIDI pipeline; MIDI support is partially present in code but currently constrained by missing parsing dependencies.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.audio.* (Lua API — src/lua_api/audio_api.rs)
    |
    v
src/audio/mod.rs
    |- bus.rs - bus
    |- decoder.rs - decoder
    |- dsp.rs - dsp
    |- midi.rs - midi
    |- midi_player.rs - midi_player
    |- mixer.rs - mixer
    |- sound_data.rs - sound_data
    |- source.rs - source
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `bus.rs` | Named audio bus for grouping sources under shared volume, pitch, and pause controls. |
| `decoder.rs` | Streaming audio decoder for chunked PCM reading. |
| `dsp.rs` | Digital signal processing effects for the Lurek2D audio pipeline. |
| `midi.rs` | MIDI SoundFont state management. |
| `midi_player.rs` | Software MIDI synthesizer: parses MIDI with `midly`, renders to PCM via sine-additive synthesis, and plays through a rodio `Sink`. |
| `mixer.rs` | Core audio mixer that owns every loaded sound and drives playback through rodio. |
| `mod.rs` | Audio subsystem for Lurek2D games. |
| `sound_data.rs` | Decoded PCM audio sample buffer with per-sample read/write access. |
| `source.rs` | Audio source type and playback state enums for the audio subsystem. |

---

## Submodules

### `audio::bus`

Named audio bus for grouping sources under shared volume, pitch, and pause controls.

- **`Bus`** (struct): A named audio bus that applies volume, pitch, and pause overrides to all sources assigned to it.

### `audio::decoder`

Streaming audio decoder for chunked PCM reading.

- **`Decoder`** (struct): Streaming audio decoder that reads PCM in fixed-size chunks.

### `audio::dsp`

Digital signal processing effects for the Lurek2D audio pipeline.

- **`AtomicParam`** (struct): Thread-safe atomic `f32` parameter backed by an `AtomicU32` bit-cast.
- **`EffectType`** (enum): Category of DSP audio effect applied to a sound source.
- **`EffectParams`** (struct): Shared configuration for a single DSP effect slot.
- **`ActiveEffect`** (struct): Per-stream instantiation of an `EffectParams` slot, holding the filter state for a single audio stream.
- **`SharedEffectGraph`** (struct): Shared, thread-safe graph of active DSP effects owned by a sound source.
- **`DynamicEffectSource`** (struct): A rodio `Source` wrapper that applies a dynamic chain of DSP effects to an inner audio source.

### `audio::midi`

MIDI SoundFont state management.

- **`MidiState`** (struct): MIDI SoundFont state.

### `audio::midi_player`

Software MIDI synthesizer: parses MIDI with `midly`, renders to PCM via sine-additive synthesis, and plays through a rodio `Sink`.

- **`MidiData`** (struct): Pre-parsed MIDI metadata extracted during `load()`.
- **`MidiPlayer`** (struct): Software MIDI player with sine-additive synthesis.

### `audio::mixer`

Core audio mixer that owns every loaded sound and drives playback through rodio.

- **`SourceType`** (enum): Type of audio source.
- **`PlayState`** (enum): Playback state of an audio source.
- **`QueueableSource`** (struct): A manually-fed streaming audio source that accepts raw f32 PCM data pushed buffer-by-buffer.
- **`Mixer`** (struct): The `Mixer` is the single point of entry for all audio operations in Lurek2D.

### `audio::sound_data`

Decoded PCM audio sample buffer with per-sample read/write access.

- **`SoundData`** (struct): Decoded audio samples in f32 PCM format.

### `audio::source`

Audio source type and playback state enums for the audio subsystem.

- **`SpatialState`** (struct): 3D spatial audio state for an audio source.
- **`AudioSource`** (struct): Handle for a loaded audio asset (legacy compatibility shim).

---

## Key Types

### Public Types

#### `Bus`

A named audio bus that applies volume, pitch, and pause overrides to all sources assigned to it.

#### `Decoder`

Streaming audio decoder that reads PCM in fixed-size chunks.

#### `AtomicParam`

Thread-safe atomic `f32` parameter backed by an `AtomicU32` bit-cast.

#### `EffectType`

Category of DSP audio effect applied to a sound source.

#### `EffectParams`

Shared configuration for a single DSP effect slot.

#### `ActiveEffect`

Per-stream instantiation of an `EffectParams` slot, holding the filter state for a single audio stream.

#### `SharedEffectGraph`

Shared, thread-safe graph of active DSP effects owned by a sound source.

#### `DynamicEffectSource`

A rodio `Source` wrapper that applies a dynamic chain of DSP effects to an inner audio source.

---

## Lua API

Exposed under `lurek.audio.*` by `src/lua_api/audio_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.audio.newSource` | Loads an audio file and returns a Source handle. |
| `lurek.audio.play` | Plays a source, with optional bus routing via options table. |
| `lurek.audio.stop` | Stops playback and resets seek position. |
| `lurek.audio.setVolume` | Sets source playback volume. |
| `lurek.audio.getVolume` | Returns the source volume. |
| `lurek.audio.pause` | Pauses playback at the current position. |
| `lurek.audio.resume` | Resumes playback from pause. |
| `lurek.audio.setPitch` | Sets source pitch multiplier. |
| `lurek.audio.getPitch` | Returns the source pitch multiplier. |
| `lurek.audio.isPlaying` | Returns true if the source is playing. |
| `lurek.audio.isPaused` | Returns true if the source is paused. |
| `lurek.audio.isStopped` | Returns true if the source is stopped. |
| `lurek.audio.setLooping` | Enables or disables looping. |
| `lurek.audio.isLooping` | Returns true if looping is enabled. |
| `lurek.audio.playLooping` | Plays the source in a continuous loop. |
| `lurek.audio.setPan` | Sets stereo panning (-1.0 left to 1.0 right). |
| `lurek.audio.getPan` | Returns the source stereo panning. |
| `lurek.audio.setMasterVolume` | Sets the global master volume. |
| `lurek.audio.getMasterVolume` | Returns the global master volume. |
| `lurek.audio.getActiveSourceCount` | Returns the number of currently playing sources. |
| `lurek.audio.getSourceCount` | Returns the total number of registered sources. |
| `lurek.audio.getSourceType` | Returns the type string ("static" or "stream") of a source. |
| `lurek.audio.clone` | Creates an independent copy of a source. |
| `lurek.audio.pauseAll` | Pauses all currently playing sources. |
| `lurek.audio.stopAll` | Stops all currently playing sources. |
| `lurek.audio.resumeAll` | Resumes all paused sources. |
| `lurek.audio.release` | Releases a source and frees its memory. |
| `lurek.audio.newBus` | Creates a named audio bus for grouping sources. |
| `lurek.audio.setSourceBus` | Assigns a source to a bus. |
| `lurek.audio.getSourceBus` | Returns the bus a source is assigned to, or nil. |
| `lurek.audio.getMaxSources` | Returns the maximum number of simultaneous sources. |
| `lurek.audio.getDuration` | Returns the total duration of a source in seconds. |
| `lurek.audio.tell` | Returns the current playback position in seconds. |
| `lurek.audio.seek` | Seeks to a time position in seconds. |
| `lurek.audio.setLowpass` | Applies a low-pass filter to a source. |
| `lurek.audio.setHighpass` | Applies a high-pass filter to a source. |
| `lurek.audio.getLowpass` | Returns the low-pass filter cutoff of a source. |
| `lurek.audio.getHighpass` | Returns the high-pass filter cutoff of a source. |
| `lurek.audio.clearFilter` | Removes any active filter from a source. |
| `lurek.audio.fadeIn` | Fades a source in from silence over the given duration. |
| `lurek.audio.getFadeIn` | Returns the fade-in duration of a source. |
| `lurek.audio.setListener2D` | Sets the 2D listener position for spatial audio. |
| `lurek.audio.getListener2D` | Returns the 2D listener position (x, y). |
| `lurek.audio.setListener` | Sets the 3D listener position. |
| `lurek.audio.getListener` | Returns the 3D listener position (x, y, z). |
| `lurek.audio.setPosition` | Sets the 3D position of a source. |
| `lurek.audio.getPosition` | Returns the 3D position of a source (x, y, z). |
| `lurek.audio.setVelocity` | Sets the velocity of a source for Doppler. |
| `lurek.audio.getVelocity` | Returns the velocity of a source (x, y, z). |
| `lurek.audio.setOrientation` | Sets the 6-component orientation of a source. |
| `lurek.audio.getOrientation` | Returns the 6-component orientation of a source. |
| `lurek.audio.setDopplerScale` | Sets the global Doppler effect scale. |
| `lurek.audio.getDopplerScale` | Returns the current Doppler scale. |
| `lurek.audio.setDistanceModel` | Sets the distance attenuation model. |
| `lurek.audio.getDistanceModel` | Returns the current distance model name. |
| `lurek.audio.setMeter` | Sets the metering scale (stub). |
| `lurek.audio.getMeter` | Returns the current peak level (stub). |
| `lurek.audio.newMidiPlayer` | Creates a MIDI player, optionally loading a file. |
| `lurek.audio.newSoundData` | Creates a SoundData from a file or as a silent buffer. |
| `lurek.audio.setMidiSoundFont` | Sets the global SoundFont for MIDI synthesis. |
| `lurek.audio.hasMidiSoundFont` | Returns true if a SoundFont is loaded. |
| `lurek.audio.clearMidiSoundFont` | Unloads the active SoundFont. |
| `lurek.audio.newDecoder` | Creates a streaming audio decoder. |
| `lurek.audio.newQueueableSource` | Creates a queueable source for manual PCM buffering. |
| `lurek.audio.queueSource` | Pushes a SoundData buffer into a queueable source. |
| `lurek.audio.getFreeBufferCount` | Returns the free buffer slots in a queueable source. |
| `lurek.audio.playQueueable` | Starts playback of a queueable source. |
| `lurek.audio.stopQueueable` | Stops a queueable source and drains its buffers. |
| `lurek.audio.getPlaybackDevices` | Returns a table of available audio output device names. |
| `lurek.audio.getPlaybackDevice` | Returns the current audio output device name. |
| `lurek.audio.setPlaybackDevice` | Selects an audio output device by name. |
| `lurek.audio.create_bus` | Creates a bus by name (functional style). |
| `lurek.audio.set_bus_volume` | Sets a bus volume by name. |
| `lurek.audio.add_effect` | Adds a DSP effect to a bus. |
| `lurek.audio.remove_effect` | Removes a DSP effect from a bus. |
| `lurek.audio.set_effect_param` | Sets a parameter on a DSP effect. |
| `lurek.audio.saveWAV` | Saves a SoundData as a 16-bit PCM WAV file at the given path. |

### `Bus` Methods

| Method | Description |
|--------|-------------|
| `bus:getName(...)` | Returns the bus name. |
| `bus:setVolume(...)` | Sets the volume for all sources on this bus. |
| `bus:getVolume(...)` | Returns the bus volume. |
| `bus:setPitch(...)` | Sets the pitch multiplier for all sources on this bus. |
| `bus:getPitch(...)` | Returns the bus pitch multiplier. |
| `bus:pause(...)` | Pauses all sources on this bus. |
| `bus:resume(...)` | Resumes all sources on this bus. |
| `bus:isPaused(...)` | Returns true if this bus is paused. |
| `bus:type(...)` | Returns the type name of this object. |
| `bus:typeOf(...)` | Returns true if this object is of the given type. |

### `Decoder` Methods

| Method | Description |
|--------|-------------|
| `decoder:decode(...)` | Decodes the next chunk of samples, or nil at EOF. |
| `decoder:getChannelCount(...)` | Returns the number of audio channels. |
| `decoder:getBitDepth(...)` | Returns the bit depth. |
| `decoder:getSampleRate(...)` | Returns the sample rate in Hz. |
| `decoder:getDuration(...)` | Returns the total duration in seconds. |
| `decoder:seek(...)` | Seeks to a time offset in seconds. |
| `decoder:rewind(...)` | Rewinds to the beginning. |
| `decoder:tell(...)` | Returns the current position in seconds. |
| `decoder:isSeekable(...)` | Returns true if seeking is supported. |
| `decoder:release(...)` | Releases the decoder (no-op). |

### `MidiPlayer` Methods

| Method | Description |
|--------|-------------|
| `midiplayer:load(...)` | Loads a MIDI file from the given path. |
| `midiplayer:loadData(...)` | Loads MIDI data from a Lua string. |
| `midiplayer:isLoaded(...)` | Returns true if a MIDI sequence is loaded. |
| `midiplayer:getFilePath(...)` | Returns the file path of the loaded MIDI, or nil. |
| `midiplayer:setSoundFont(...)` | Loads a SoundFont file into this player (stub). |
| `midiplayer:getSoundFontPath(...)` | Returns the SoundFont file path, or nil (stub). |
| `midiplayer:useDefaultSoundFont(...)` | Reverts to the built-in default SoundFont (stub). |
| `midiplayer:play(...)` | Starts MIDI playback. |
| `midiplayer:pause(...)` | Pauses MIDI playback. |
| `midiplayer:stop(...)` | Stops MIDI playback. |
| `midiplayer:isPlaying(...)` | Returns true if MIDI is currently playing. |
| `midiplayer:isPaused(...)` | Returns true if MIDI playback is paused. |
| `midiplayer:seek(...)` | Seeks to a time position in seconds. |
| `midiplayer:tell(...)` | Returns the current playback position in seconds. |
| `midiplayer:getDuration(...)` | Returns the total MIDI duration in seconds. |
| `midiplayer:setLooping(...)` | Enables or disables looping. |
| `midiplayer:isLooping(...)` | Returns true if looping is enabled. |
| `midiplayer:setVolume(...)` | Sets MIDI playback volume. |
| `midiplayer:getVolume(...)` | Returns the current MIDI volume. |
| `midiplayer:setBus(...)` | Routes MIDI output through a bus (or nil to clear). |
| `midiplayer:getBus(...)` | Returns the assigned bus, or nil. |
| `midiplayer:setTempo(...)` | Sets playback tempo in BPM. |
| `midiplayer:getTempo(...)` | Returns the current tempo in BPM. |
| `midiplayer:getOriginalTempo(...)` | Returns the original MIDI file tempo in BPM. |
| `midiplayer:setTempoScale(...)` | Sets the tempo scale factor (1.0 = original speed). |
| `midiplayer:getTempoScale(...)` | Returns the current tempo scale factor. |
| `midiplayer:getTicksPerBeat(...)` | Returns the PPQ resolution from the MIDI header. |
| `midiplayer:setChannelVolume(...)` | Sets volume for a MIDI channel (1-indexed). |
| `midiplayer:getChannelVolume(...)` | Returns the volume for a MIDI channel (1-indexed). |
| `midiplayer:setChannelMuted(...)` | Mutes or unmutes a MIDI channel (1-indexed). |
| `midiplayer:isChannelMuted(...)` | Returns true if a MIDI channel is muted (1-indexed). |
| `midiplayer:getChannelInstrument(...)` | Returns the GM instrument for a MIDI channel (1-indexed). |
| `midiplayer:getChannelCount(...)` | Returns the number of MIDI channels. |
| `midiplayer:soloChannel(...)` | Solos a MIDI channel (1-indexed). |
| `midiplayer:unsoloAll(...)` | Clears solo on all channels. |
| `midiplayer:getTrackCount(...)` | Returns the number of tracks in the MIDI sequence. |
| `midiplayer:getTrackName(...)` | Returns the name of a MIDI track (1-indexed), or nil. |
| `midiplayer:setTrackMuted(...)` | Mutes or unmutes a track (1-indexed). |
| `midiplayer:isTrackMuted(...)` | Returns true if a track is muted (1-indexed). |
| `midiplayer:getNoteCount(...)` | Returns the total note count in the MIDI sequence. |
| `midiplayer:setOnNoteOn(...)` | Registers a note-on callback (stub). |
| `midiplayer:setOnNoteOff(...)` | Registers a note-off callback (stub). |
| `midiplayer:setOnEnd(...)` | Registers a playback-end callback (stub). |
| `midiplayer:type(...)` | Returns the type name of this object. |
| `midiplayer:typeOf(...)` | Returns true if this object is of the given type. |

### `Source` Methods

| Method | Description |
|--------|-------------|
| `source:play(...)` | Starts or resumes playback. |
| `source:stop(...)` | Stops playback and resets seek position. |
| `source:pause(...)` | Pauses playback at the current position. |
| `source:resume(...)` | Resumes playback from the paused position. |
| `source:setVolume(...)` | Sets playback volume (0.0 = silent, 1.0 = full). |
| `source:getVolume(...)` | Returns the current volume multiplier. |
| `source:setPitch(...)` | Sets the pitch multiplier (1.0 = normal). |
| `source:getPitch(...)` | Returns the current pitch multiplier. |
| `source:setLooping(...)` | Enables or disables looping playback. |
| `source:isLooping(...)` | Returns true if looping is enabled. |
| `source:isPlaying(...)` | Returns true if currently playing. |
| `source:isPaused(...)` | Returns true if playback is paused. |
| `source:isStopped(...)` | Returns true if playback has stopped. |
| `source:setPan(...)` | Sets stereo panning (-1.0 left to 1.0 right). |
| `source:getPan(...)` | Returns the current stereo panning value. |
| `source:clone(...)` | Creates an independent copy of this source. |
| `source:getType(...)` | Returns the source type ("static" or "stream"). |
| `source:getDuration(...)` | Returns the total duration in seconds. |
| `source:tell(...)` | Returns the current playback position in seconds. |
| `source:seek(...)` | Seeks to a time position in seconds. |
| `source:setLowpass(...)` | Applies a low-pass filter at the given cutoff frequency. |
| `source:setHighpass(...)` | Applies a high-pass filter at the given cutoff frequency. |
| `source:getLowpass(...)` | Returns the low-pass filter cutoff frequency. |
| `source:getHighpass(...)` | Returns the high-pass filter cutoff frequency. |
| `source:clearFilter(...)` | Removes any active filter from this source. |
| `source:fadeIn(...)` | Fades in from silence over the given duration in seconds. |
| `source:getFadeIn(...)` | Returns the current fade-in duration in seconds. |

### `mlua` Methods

| Method | Description |
|--------|-------------|
| `mlua:getSampleCount(...)` | Lua-facing function documented in the binding source. |
| `mlua:getSampleRate(...)` | Lua-facing function documented in the binding source. |
| `mlua:getChannelCount(...)` | Lua-facing function documented in the binding source. |
| `mlua:getDuration(...)` | Lua-facing function documented in the binding source. |
| `mlua:getBitDepth(...)` | Lua-facing function documented in the binding source. |
| `mlua:getSample(...)` | Lua-facing function documented in the binding source. |
| `mlua:setSample(...)` | Lua-facing function documented in the binding source. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.audio.
if lurek.audio then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 15 |
| `enum` | 3 |
| `fn` (Lua API) | 176 |
| **Total** | **194** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/audio/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
