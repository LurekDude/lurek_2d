# `audio` — Agent Reference

| Property       | Value                                                                    |
|----------------|--------------------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                                          |
| **Status**     | Implemented — Full                                                       |
| **Lua API**    | `luna.audio`                                                             |
| **Source**     | `src/audio/`                                                             |
| **Rust Tests** | `tests/rust/unit/audio_tests.rs`, `tests/rust/unit/audio_sound_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_audio.lua`, `tests/lua/unit/test_audio_dsp.lua`, `tests/lua/unit/test_audio_bus.lua` |
| **Architecture** | —                                                                      |

## Summary

The audio module wraps the `rodio` cross-platform audio library into a game-oriented mixing layer, handling every stage of game audio from file loading to final output. It decodes sound files (WAV, OGG Vorbis, FLAC, MP3) into static in-memory sources or streaming sources, controls per-source playback state (volume, pitch, looping, fade in/out, seek), routes sources through named audio buses for grouped volume and pitch control, and applies real-time DSP effects (lowpass, highpass, bandpass biquad filters, comb-filter reverb, and chorus) via a lock-free `DynamicEffectSource` wrapper that chains effects on the audio thread without blocking the main engine loop.

Each active sound is stored as an `AudioEntry` in a `SlotMap<SoundKey>`. The `Mixer` owns the underlying `rodio::OutputStream` and manages the lifecycle of all `rodio::Sink` handles. Spatial audio is approximated for 2D games: panning is derived from the horizontal offset between a source's world position and the listener position, mapped to a stereo split via a linear panning law. A full 3D listener model (position, orientation, velocity, Doppler scale, distance attenuation model) is exposed for more advanced spatial setups.

A `MidiPlayer` provides synthesised music playback: MIDI events are parsed with `midly` (currently disabled at the crate level) and rendered to PCM at 44100 Hz using additive sine synthesis, supporting per-channel mute, independent volume on each track and channel, bus routing, and real-time tempo scaling. A `Decoder` provides chunked streaming PCM reading for game code that needs frame-by-frame audio processing. `QueueableSource` enables manually-fed streaming audio where game code pushes PCM buffers directly into a playback queue. `SoundData` stores fully decoded f32 PCM samples with per-sample read/write access, used for procedural audio generation and DSP from Lua.

The module falls back gracefully to headless mode (no audio output) when no audio device is available, enabling CI and test environments without crashes.

## Architecture

```
Mixer (central audio manager)
  │
  ├── Sources ─── SlotMap<SoundKey, AudioEntry>
  │     ├── Static ── entire file decoded into Arc<Vec<u8>> (low-latency SFX)
  │     └── Stream ── opened fresh from disk on each play (low-memory music)
  │
  ├── Playback control (per-source)
  │     ├── play / pause / resume / stop
  │     ├── set_volume / set_pitch / set_pan / set_looping
  │     ├── fade_in (linear ramp over duration)
  │     ├── seek (rebuilds sink with skip_duration)
  │     ├── clone_source (Arc sharing of decoded data)
  │     └── spatial: position / velocity / orientation → auto-pan
  │
  ├── Bus routing ─── SlotMap<BusKey, Bus>
  │     ├── Bus { name, volume, pitch, paused, effects }
  │     └── DSP effect chain via SharedEffectGraph
  │           ├── Lowpass / Highpass / Bandpass (biquad)
  │           ├── Reverb (comb-filter)
  │           └── Chorus (short-delay comb)
  │
  ├── Queueable sources ─── SlotMap<QueueableKey, QueueableSource>
  │     └── Manual PCM buffering for procedural audio
  │
  ├── Spatial audio
  │     ├── Listener position / orientation / velocity
  │     ├── Per-source position / velocity / orientation
  │     ├── Doppler scale
  │     └── Distance attenuation model
  │
  ├── Master volume ── global scalar on all output
  │
  └── MidiPlayer ─── sine-additive PCM synthesis
        ├── Per-track/channel mute, solo, volume, instrument
        ├── Tempo changes (scale + BPM)
        ├── Looping and bus routing
        └── Real-time rendering at 44100 Hz

Decoder ─── chunked streaming PCM reader
  └── from_file → decode() chunks → SoundData

SoundData ─── decoded f32 PCM buffer (UserData)
  └── per-sample get/set, duration, channel info
```

## Source Files

| File             | Purpose                                                                              |
|------------------|--------------------------------------------------------------------------------------|
| `bus.rs`         | Named audio bus with shared volume, pitch, pause, and DSP effect chain               |
| `decoder.rs`     | Streaming audio decoder for chunked PCM reading from disk                            |
| `dsp.rs`         | DSP effect chain: AtomicParam, EffectType, EffectParams, ActiveEffect, DynamicEffectSource |
| `midi.rs`        | MIDI SoundFont state management (SF2 validation and storage)                         |
| `midi_player.rs` | Software MIDI synthesizer with sine-additive PCM rendering via rodio Sink            |
| `mixer.rs`       | Core audio mixer: source loading, playback control, bus routing, spatial audio, queueable sources |
| `sound_data.rs`  | Decoded PCM sample buffer with per-sample read/write access (Lua UserData)           |
| `source.rs`      | AudioSource handle (legacy shim) and SpatialState for 3D positioning                 |

## Submodules

### `audio::bus`

Named audio bus for grouping sources under shared volume, pitch, and pause controls. Buses hold a thread-safe DSP effect chain via `Arc<RwLock<Vec<Arc<EffectParams>>>>`.

- **`Bus`** (struct) — A named audio bus applying volume, pitch, and pause overrides to all assigned sources. Pure data container; the Mixer multiplies source values by bus values.

### `audio::decoder`

Streaming audio decoder that reads PCM in fixed-size chunks. Eagerly reads the full file on construction, then serves chunks of configurable size on each `decode()` call.

- **`Decoder`** (struct) — Chunked PCM decoder with seek, tell, rewind, and duration queries.

### `audio::dsp`

Real-time DSP effect processing for the audio pipeline. Effects are configured on the main thread via lock-free `AtomicParam` values and applied on the audio thread inside `DynamicEffectSource`.

- **`AtomicParam`** (struct) — Thread-safe atomic f32 parameter backed by AtomicU32 bit-cast.
- **`EffectType`** (enum) — DSP effect category: Lowpass, Highpass, Bandpass, Reverb, Chorus.
- **`EffectParams`** (struct) — Shared configuration for a single DSP effect slot with atomic parameters.
- **`ActiveEffect`** (struct) — Per-stream instantiation of an EffectParams slot holding biquad filter history and comb-filter delay buffer.
- **`SharedEffectGraph`** (struct) — Thread-safe graph of active DSP effects shared between main and audio threads.
- **`DynamicEffectSource<I>`** (struct) — A rodio Source wrapper that applies a dynamic chain of DSP effects to an inner audio source.

### `audio::midi`

MIDI SoundFont state management. Tracks whether a SoundFont (SF2) file has been loaded and stores its raw bytes.

- **`MidiState`** (struct) — Stores optional SF2 data with RIFF header validation.

### `audio::midi_player`

Software MIDI synthesizer. Parses MIDI via `midly`, renders all tracks to a PCM buffer, and plays through a rodio Sink. Currently disabled at the crate level (midly removed from Cargo.toml).

- **`MidiData`** (struct) — Pre-parsed MIDI metadata: duration, ticks per beat, tempo, track names, note count, channel count.
- **`MidiPlayer`** (struct) — Full MIDI player with per-channel volume, muting, solo, track muting, tempo scaling, looping, and bus routing.

### `audio::mixer`

Core audio mixer that owns every loaded sound and drives playback through rodio. Single point of entry for all audio operations.

- **`SourceType`** (enum) — Static (decoded to memory) or Stream (decoded on-the-fly from disk).
- **`PlayState`** (enum) — Stopped, Playing, or Paused.
- **`QueueableSource`** (struct) — Manually-fed streaming audio source with a FIFO buffer queue for raw f32 PCM data.
- **`Mixer`** (struct) — Central audio manager: source SlotMap, bus SlotMap, queueable SlotMap, master volume, spatial listener state, rodio output stream.

### `audio::sound_data`

Decoded PCM audio sample buffer with per-sample read/write access. Implements `mlua::UserData` for direct Lua access.

- **`SoundData`** (struct) — Interleaved f32 PCM samples clamped to [-1.0, 1.0], with metadata (sample rate, channels, bit depth).

### `audio::source`

Audio source handle and spatial state types.

- **`SpatialState`** (struct) — 3D position, velocity, and orientation for spatial audio panning.
- **`AudioSource`** (struct) — Legacy handle for a loaded audio asset (superseded by Mixer's SlotMap, kept for API compatibility).

## Key Types

### Structs

#### `audio::bus::Bus`

A named audio bus that applies volume, pitch, and pause overrides to all sources assigned to it. Buses are pure data containers — the Mixer multiplies source volume/pitch by bus values. Holds a thread-safe DSP effect chain via `Arc<RwLock<Vec<Arc<EffectParams>>>>`. Methods: `new()`, `name()`, `volume()`, `set_volume()`, `pitch()`, `set_pitch()`, `pause()`, `resume()`, `is_paused()`.

#### `audio::decoder::Decoder`

Streaming audio decoder that reads PCM in fixed-size buffer chunks. Eagerly decodes the full file on construction via rodio, then serves chunks on each `decode()` call. Fields: `path`, `sample_rate`, `channels`, `bit_depth`, `buffer_size`. Methods: `from_file()`, `decode()`, `get_duration()`, `seek()`, `tell()`, `is_seekable()`, `rewind()`.

#### `audio::dsp::AtomicParam`

Thread-safe atomic f32 parameter backed by an AtomicU32 bit-cast. Enables lock-free reads and writes across the audio thread and the main engine thread. Methods: `new()`, `get()`, `set()`.

#### `audio::dsp::EffectParams`

Shared configuration for a single DSP effect slot. Contains the effect type and three atomic parameters (p1: cutoff/room_size, p2: center/mix, p3: reserved). Shared between threads via `Arc<EffectParams>`.

#### `audio::dsp::ActiveEffect`

Per-stream instantiation of an EffectParams slot. Owns biquad filter history (x1/x2/y1/y2 for two channels) and the comb-filter delay buffer used by reverb and chorus effects. Methods: `new()`, `process()`.

#### `audio::dsp::SharedEffectGraph`

Thread-safe graph of active DSP effects owned by a sound source or bus. The main thread pushes `Arc<EffectParams>` entries; the audio thread reads them via non-blocking `try_read`.

#### `audio::dsp::DynamicEffectSource<I>`

A rodio `Source` wrapper that applies a dynamic chain of DSP effects to an inner audio source. On every audio-thread sample, checks the shared effect list and processes through each ActiveEffect in sequence. Implements `Iterator` and `rodio::Source`.

#### `audio::midi::MidiState`

MIDI SoundFont state management. Tracks whether a SoundFont (SF2) file has been loaded, validates RIFF/sfbk headers, and stores raw bytes. Methods: `new()`, `set_soundfont()`, `has_soundfont()`, `clear_soundfont()`, `soundfont_path()`, `soundfont_data()`.

#### `audio::midi_player::MidiData`

Pre-parsed MIDI metadata extracted during `load()`. Contains duration, ticks per beat, original tempo BPM, track count, track names, note count, and channel count.

#### `audio::midi_player::MidiPlayer`

Software MIDI player with sine-additive synthesis. Renders all tracks to a PCM buffer on `play()` and feeds the result into a rodio Sink. Supports per-channel volume, muting, solo, track muting, tempo scaling, looping, and bus routing. Key methods: `new()`, `load()`, `load_data()`, `is_loaded()`, `play()`, `pause()`, `stop()`, `seek()`, `tell()`, `duration()`.

#### `audio::mixer::QueueableSource`

A manually-fed streaming audio source that accepts raw f32 PCM data pushed buffer-by-buffer. Game code pushes audio data into the queue via `queue_buffer`. Fields: `sample_rate`, `bit_depth`, `channels`, `buffer_count`, `queued_buffers`, `free_buffers`.

#### `audio::mixer::Mixer`

Central audio manager. Owns `SlotMap<SoundKey, AudioEntry>` for loaded sounds, `SlotMap<BusKey, Bus>` for named routing groups, `SlotMap<QueueableKey, QueueableSource>` for manual PCM streaming, master volume, spatial listener state (position, orientation, velocity, Doppler scale, distance model), and the rodio output stream. Falls back to headless mode when no audio device is available.

#### `audio::sound_data::SoundData`

Decoded audio samples in f32 PCM format. Stores interleaved samples (for stereo: L, R, L, R, ...). Samples are clamped to [-1.0, 1.0] on write. Implements `mlua::UserData` with Lua methods: `getSampleCount`, `getSampleRate`, `getChannelCount`, `getDuration`, `getBitDepth`, `getSample`, `setSample`.

#### `audio::source::SpatialState`

3D spatial audio state for a source. Contains position `[x, y, z]`, velocity `[x, y, z]`, and orientation (forward + up, 6 floats). Used to compute panning relative to the listener position.

#### `audio::source::AudioSource`

Legacy handle for a loaded audio asset. Superseded by Mixer's SlotMap-based AudioEntry system but kept for API compatibility. Fields: `id`, `file_path`, `volume`, `looping`.

### Enums

#### `audio::dsp::EffectType`

Category of DSP audio effect. Variants: `Lowpass` (biquad low-pass filter), `Highpass` (biquad high-pass filter), `Bandpass` (biquad band-pass filter), `Reverb` (comb-filter reverb), `Chorus` (short-delay chorus/flanger).

#### `audio::mixer::SourceType`

Type of audio source. Variants: `Static` (decoded fully into memory, low latency, higher RAM), `Stream` (streamed from disk incrementally, lower memory).

#### `audio::mixer::PlayState`

Playback state of an audio source. Variants: `Stopped` (not playing, at beginning), `Playing` (currently playing), `Paused` (playing but paused).

## Lua API

Exposed under `luna.audio.*` by `src/lua_api/audio_api.rs`. The API surface includes source lifecycle, playback control, bus management, spatial audio, DSP effects, MIDI synthesis, streaming decoders, queueable sources, and device enumeration.

### Module Functions

| Function | Description |
|----------|-------------|
| `luna.audio.newSource(path, type)` | Loads an audio file; type is `"static"` or `"stream"` (default) |
| `luna.audio.play(source, options)` | Plays a source; optional `{bus="name"}` table for bus routing |
| `luna.audio.stop(source)` | Stops playback and resets position |
| `luna.audio.pause(source)` | Pauses playback at current position |
| `luna.audio.resume(source)` | Resumes playback from pause |
| `luna.audio.setVolume(source, vol)` | Sets per-source volume |
| `luna.audio.getVolume(source)` | Returns per-source volume |
| `luna.audio.setPitch(source, pitch)` | Sets pitch multiplier |
| `luna.audio.getPitch(source)` | Returns pitch multiplier |
| `luna.audio.isPlaying(source)` | Returns true if playing |
| `luna.audio.isPaused(source)` | Returns true if paused |
| `luna.audio.isStopped(source)` | Returns true if stopped |
| `luna.audio.setLooping(source, bool)` | Enables/disables looping |
| `luna.audio.isLooping(source)` | Returns looping state |
| `luna.audio.playLooping(source)` | Plays in continuous loop |
| `luna.audio.setPan(source, pan)` | Sets stereo panning (-1.0 to 1.0) |
| `luna.audio.getPan(source)` | Returns stereo panning value |
| `luna.audio.setMasterVolume(vol)` | Sets global master volume |
| `luna.audio.getMasterVolume()` | Returns global master volume |
| `luna.audio.getActiveSourceCount()` | Returns number of playing sources |
| `luna.audio.getSourceCount()` | Returns total loaded source count |
| `luna.audio.getSourceType(source)` | Returns `"static"` or `"stream"` |
| `luna.audio.clone(source)` | Creates independent copy of a source |
| `luna.audio.pauseAll()` | Pauses all playing sources |
| `luna.audio.stopAll()` | Stops all sources |
| `luna.audio.resumeAll()` | Resumes all paused sources |
| `luna.audio.release(source)` | Releases source and frees memory |
| `luna.audio.getDuration(source)` | Returns total duration in seconds |
| `luna.audio.tell(source)` | Returns current playback position |
| `luna.audio.seek(source, pos)` | Seeks to time position in seconds |
| `luna.audio.setLowpass(source, hz)` | Applies lowpass filter at cutoff |
| `luna.audio.setHighpass(source, hz)` | Applies highpass filter at cutoff |
| `luna.audio.getLowpass(source)` | Returns lowpass cutoff frequency |
| `luna.audio.getHighpass(source)` | Returns highpass cutoff frequency |
| `luna.audio.clearFilter(source)` | Removes all filters from source |
| `luna.audio.fadeIn(source, dur)` | Fades in from silence over duration |
| `luna.audio.getFadeIn(source)` | Returns fade-in duration |
| `luna.audio.getMaxSources()` | Returns max simultaneous sources (64) |
| `luna.audio.newBus(name)` | Creates a named audio bus |
| `luna.audio.setSourceBus(source, bus)` | Assigns source to a bus |
| `luna.audio.getSourceBus(source)` | Returns assigned bus or nil |
| `luna.audio.create_bus(name, parent)` | Creates bus by name (functional style) |
| `luna.audio.set_bus_volume(name, vol)` | Sets bus volume by name |
| `luna.audio.add_effect(bus, type, params)` | Adds DSP effect to a bus |
| `luna.audio.remove_effect(bus, id)` | Removes DSP effect from a bus |
| `luna.audio.set_effect_param(bus, id, param, val)` | Sets DSP effect parameter |
| `luna.audio.setListener2D(x, y)` | Sets 2D listener position |
| `luna.audio.getListener2D()` | Returns 2D listener position |
| `luna.audio.setListener(x, y, z)` | Sets 3D listener position |
| `luna.audio.getListener()` | Returns 3D listener position |
| `luna.audio.setPosition(source, x, y, z)` | Sets source 3D position |
| `luna.audio.getPosition(source)` | Returns source 3D position |
| `luna.audio.setVelocity(source, x, y, z)` | Sets source velocity (Doppler) |
| `luna.audio.getVelocity(source)` | Returns source velocity |
| `luna.audio.setOrientation(source, fx, fy, fz, ux, uy, uz)` | Sets source orientation |
| `luna.audio.getOrientation(source)` | Returns source orientation |
| `luna.audio.setDopplerScale(scale)` | Sets global Doppler scale factor |
| `luna.audio.getDopplerScale()` | Returns Doppler scale factor |
| `luna.audio.setDistanceModel(model)` | Sets distance attenuation model |
| `luna.audio.getDistanceModel()` | Returns distance model name |
| `luna.audio.setMeter(scale)` | Sets metering scale (stub) |
| `luna.audio.getMeter()` | Returns peak level (stub) |
| `luna.audio.newMidiPlayer(path)` | Creates MIDI player, optionally loading a file |
| `luna.audio.newSoundData(args)` | Creates SoundData from file or silent buffer |
| `luna.audio.setMidiSoundFont(path)` | Sets global SoundFont for MIDI |
| `luna.audio.hasMidiSoundFont()` | Returns true if SoundFont loaded |
| `luna.audio.clearMidiSoundFont()` | Unloads active SoundFont |
| `luna.audio.newDecoder(path, bufsize)` | Creates a streaming decoder |
| `luna.audio.newQueueableSource(rate, bits, ch, bufs)` | Creates queueable PCM source |
| `luna.audio.queueSource(id, sounddata)` | Pushes PCM buffer into queue |
| `luna.audio.getFreeBufferCount(id)` | Returns free queue buffer slots |
| `luna.audio.playQueueable(id)` | Starts queueable source playback |
| `luna.audio.stopQueueable(id)` | Stops queueable source |
| `luna.audio.getPlaybackDevices()` | Returns table of output device names |
| `luna.audio.getPlaybackDevice()` | Returns current output device name |
| `luna.audio.setPlaybackDevice(name)` | Selects output device by name |

### Source Methods

`play()`, `stop()`, `pause()`, `resume()`, `setVolume(vol)`, `getVolume()`, `setPitch(pitch)`, `getPitch()`, `setLooping(bool)`, `isLooping()`, `isPlaying()`, `isPaused()`, `isStopped()`, `setPan(pan)`, `getPan()`, `clone()`, `getType()`, `getDuration()`, `tell()`, `seek(pos)`, `setLowpass(hz)`, `setHighpass(hz)`, `getLowpass()`, `getHighpass()`, `clearFilter()`, `fadeIn(dur)`, `getFadeIn()`

### Bus Methods

`getName()`, `setVolume(vol)`, `getVolume()`, `setPitch(pitch)`, `getPitch()`, `pause()`, `resume()`, `isPaused()`

### MidiPlayer Methods

`load(path)`, `loadData(data)`, `isLoaded()`, `getFilePath()`, `setSoundFont(path)`, `getSoundFontPath()`, `useDefaultSoundFont()`, `play()`, `pause()`, `stop()`, `isPlaying()`, `isPaused()`, `seek(secs)`, `tell()`, `getDuration()`, `setLooping(bool)`, `isLooping()`, `setVolume(vol)`, `getVolume()`, `setBus(bus)`, `getBus()`, `setTempo(bpm)`, `getTempo()`, `getOriginalTempo()`, `setTempoScale(scale)`, `getTempoScale()`, `getTicksPerBeat()`, `setChannelVolume(ch, vol)`, `getChannelVolume(ch)`, `setChannelMuted(ch, muted)`, `isChannelMuted(ch)`, `setChannelInstrument(ch, inst)`, `getChannelInstrument(ch)`, `getChannelCount()`, `soloChannel(ch)`, `unsoloAll()`, `getTrackCount()`, `getTrackName(idx)`, `setTrackMuted(idx, muted)`, `isTrackMuted(idx)`, `getNoteCount()`, `setOnNoteOn(cb)`, `setOnNoteOff(cb)`, `setOnEnd(cb)`

### Decoder Methods

`decode()`, `getChannelCount()`, `getBitDepth()`, `getSampleRate()`, `getDuration()`, `seek(offset)`, `rewind()`, `tell()`, `isSeekable()`, `release()`

### SoundData Methods

`getSampleCount()`, `getSampleRate()`, `getChannelCount()`, `getDuration()`, `getBitDepth()`, `getSample(index)`, `setSample(index, value)`

## Lua Examples

```lua
-- Basic audio playback with bus routing
function luna.init()
    -- Create audio buses
    music_bus = luna.audio.newBus("music")
    sfx_bus = luna.audio.newBus("sfx")
    music_bus:setVolume(0.7)

    -- Load a streaming music source and assign to bus
    music = luna.audio.newSource("music.ogg", "stream")
    music:setLooping(true)
    music:setVolume(0.8)
    luna.audio.setSourceBus(music, music_bus)
    music:play()

    -- Load a static SFX source
    sfx = luna.audio.newSource("jump.wav", "static")
    luna.audio.setSourceBus(sfx, sfx_bus)
end

function luna.keypressed(key)
    if key == "space" then
        -- Clone so multiple overlapping plays work
        local s = sfx:clone()
        s:play()
    elseif key == "m" then
        -- Mute/unmute music bus
        if music_bus:isPaused() then
            music_bus:resume()
        else
            music_bus:pause()
        end
    end
end
```

```lua
-- DSP effects on a bus
function luna.init()
    local bus = luna.audio.newBus("fx")
    local id = luna.audio.add_effect("fx", "lowpass", { value = 2000 })
    luna.audio.set_effect_param("fx", id, "cutoff", 1500)
end
```

```lua
-- Spatial audio with 2D listener
function luna.init()
    luna.audio.setListener2D(400, 300)
    local src = luna.audio.newSource("footsteps.ogg", "static")
    luna.audio.setPosition(src, 200, 300, 0)
    src:play()
end

function luna.process(dt)
    -- Move listener with player position
    local px, py = player.x, player.y
    luna.audio.setListener2D(px, py)
end
```

```lua
-- Procedural audio with SoundData
function luna.init()
    local sd = luna.audio.newSoundData(44100, 44100, 1)  -- 1 second mono
    for i = 0, sd:getSampleCount() - 1 do
        local t = i / sd:getSampleRate()
        sd:setSample(i, math.sin(2 * math.pi * 440 * t) * 0.5)
    end
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 15    |
| `enum`    | 3     |
| `fn`      | 3     |
| **Total** | **21** |

## References

| Module       | Relationship | Notes                                                        |
|--------------|--------------|--------------------------------------------------------------|
| `engine`     | Imports from | Uses `SharedState`, `EngineError`, `SoundKey`, `BusKey`, `QueueableKey` resource keys |
| `math`       | Imports from | No direct import, but spatial audio uses float vectors       |
| `sound`      | Similar to   | `sound` module owns `SoundData` type; `audio` owns playback. `SoundData` is defined in `audio::sound_data` but also re-exported from `sound` |
| `lua_api`    | Imported by  | `audio_api.rs` binds all public types to `luna.audio.*` namespace |

## Notes

- **Headless fallback**: `Mixer::new()` catches `rodio::OutputStream::try_default()` errors and runs with `stream_handle = None`. All playback calls become no-ops. This enables CI and test environments without audio devices.
- **rodio version**: Uses rodio 0.17. `Sink` does not expose playback position, so the mixer tracks play-start instants and accumulated pre-pause seconds manually for `tell()`.
- **MIDI disabled**: The `midly` crate has been removed from `Cargo.toml`. `MidiPlayer::load_data()` always returns `false`. To re-enable, restore `midly = "0.5"` and uncomment the parsing code in `midi_player.rs`.
- **Static source caching**: Static sources decode file bytes into `Arc<Vec<u8>>` on first play. Subsequent `play()` and `clone_source()` calls share the `Arc`, avoiding redundant allocations.
- **Seek implementation**: Seeking rebuilds the entire rodio Sink from scratch using `skip_duration()`. This is necessary because rodio Sinks are not seekable. Cost is proportional to the skip duration for streamed sources.
- **DSP thread safety**: `EffectParams` uses `AtomicParam` (AtomicU32 bit-cast) for lock-free parameter mutation from the main thread while the audio thread reads. The `DynamicEffectSource` syncs its `ActiveEffect` list on each audio frame via `try_read` on an `RwLock`.
- **Bus effect chain**: Bus effects are stored in `Arc<RwLock<Vec<Arc<EffectParams>>>>` on the `Bus` struct. When a source assigned to a bus is played, the mixer wraps the audio stream in a `DynamicEffectSource` that references the bus's effect list.
- **Panning law**: Spatial panning uses a simple linear law: `pan = (source_x - listener_x) / 200.0`, clamped to [-1.0, 1.0]. Applied via `rodio::source::ChannelVolume`.
- **QueueableSource**: Game code pushes raw f32 PCM buffers into a FIFO queue. The `playQueueable` and `stopQueueable` calls manage state bookkeeping only; actual audio flow is driven by the queued buffers.
- **Breaking change surface**: Renaming or removing any `luna.audio.*` function or Source/Bus/MidiPlayer method will break existing game scripts. The Source UserData methods (play, stop, setVolume, etc.) are the most commonly used API surface.
