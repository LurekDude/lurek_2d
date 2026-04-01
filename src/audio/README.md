# `src/audio/` — Audio Playback and Mixing

## Purpose

The audio module wraps the `rodio` cross-platform audio library into a
game-oriented mixing layer, handling every stage of game audio from file
loading to final output.  It decodes sound files (WAV, OGG Vorbis, FLAC, MP3)
into static in-memory sources or streaming sources, controls per-source
playback state (volume, pitch, looping, fade in/out), routes sources through
named audio buses for grouped volume control (for example a dedicated "sfx"
bus and a "music" bus), and applies simple DSP effects (low-pass and
high-pass filtering) as rodio source wrappers.

Each active sound is stored as an `AudioEntry` in a `SlotMap<SoundKey>`.  The
`Mixer` owns the underlying `rodio::OutputStream` and manages the lifecycle
of all `rodio::Sink` handles; a poll on every frame reaps finished sinks and
keeps the active-source count bounded.  Spatial audio is approximated for 2D
games: panning is derived from the horizontal offset between a sound's world
position and the listener position, mapped to a stereo split via a linear
panning law.

A `MidiPlayer` provides synthesised music playback: MIDI events are parsed
with `midly` and rendered to PCM at 44 100 Hz using additive sine synthesis,
supporting per-channel mute, independent volume control on each track, and
real-time tempo changes encoded in the MIDI file.

## Architecture

```
Mixer (central audio manager)
  │
  ├── Sources ─── SlotMap<SoundKey, AudioEntry>
  │     ├── Static ── entire file decoded into memory
  │     └── Stream ── streaming from disk
  │
  ├── Playback control (per-source)
  │     ├── play / pause / resume / stop
  │     ├── set_volume / set_pitch / set_looping
  │     ├── fade_in (linear over duration)
  │     ├── seek (rebuilds sink for seek support)
  │     └── clone_source (Arc sharing of decoded data)
  │
  ├── Bus routing ─── named buses with volume/pitch/paused
  │     └── Bus { name, volume, pitch, paused }
  │
  ├── Effects
  │     ├── lowpass(source, cutoff_hz)
  │     └── highpass(source, cutoff_hz)
  │
  └── MidiPlayer ─── midly parsing + sine-additive PCM synthesis
        ├── Per-track/channel mute and volume
        ├── Tempo changes (microseconds per beat)
        └── Real-time rendering at 44100 Hz
```

### How It Works

The `Mixer` is single-threaded — rodio handles audio output on its own
internal threads, so the `Mixer` only manages metadata and sink handles from
the main game thread.  `play()` creates a new rodio `Sink`, pushes the decoded
`AudioSource` into it, and stores the handle.  Each `update()` call iterates
all entries and removes sinks that report `is_empty()`, keeping the active
count bounded even if scripts forget to call `stop()`.

Bus routing keeps it simple: a bus is a `(name, volume, pitch, paused)` tuple.
`set_bus_volume(name, vol)` scales the rodio sink volume for all sources on
that bus at the next `update()` call.  Priority between buses (SFX over music
for example) is enforced at the game level through bus volume rather than an
internal priority queue.

The `MidiPlayer` is a frame-rendering synthesiser rather than a pre-decoded
audio stream.  Each `render_frame(dt)` advances the MIDI event pointer,
executes note-on and note-off events into an active-voices table, and sums the
sine waveforms of all currently active voices into the output buffer at the
requested sample rate.  Memory usage is constant regardless of MIDI file
length because only the event stream and the voice table need to be in memory
at once.

### Dependency Direction

```
audio/ ──────► engine::resource_keys (SoundKey, BusKey, MidiPlayerKey)
```

Depends only on resource key types for SlotMap storage.
**Near-leaf module** — no dependencies on graphics, physics, or input.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `Mixer`, `Bus`, `AudioSource`, `MidiPlayer`. Single import point.

**6 lines** — pure re-exports.

---

### `mixer.rs` — `Mixer` (Central Audio Manager)

**~882 lines** | Core audio engine managing all sound playback, mixing, and effects.

#### Struct: `Mixer`

```rust
pub struct Mixer {
    stream_handle: OutputStreamHandle,
    sources: SlotMap<SoundKey, AudioEntry>,
    buses: SlotMap<BusKey, Bus>,
    master_volume: f32,
    // ... internal rodio state
}
```

#### Source Management

| Method | Purpose |
|--------|---------|
| `load_static(path)` | Decode entire file into memory |
| `load_stream(path)` | Stream from disk (lower memory) |
| `clone_source(key)` | Share decoded data via `Arc` |
| `remove(key)` | Stop and destroy source |

#### Playback Control (per-source)

| Method | Behavior |
|--------|----------|
| `play(key)` | Start/resume playback |
| `pause(key)` | Pause without releasing |
| `stop(key)` | Stop and reset position |
| `set_volume(key, vol)` | 0.0–1.0 volume |
| `set_pitch(key, pitch)` | Playback speed multiplier |
| `set_looping(key, bool)` | Loop toggle |
| `fade_in(key, duration)` | Linear fade from 0 to current volume |
| `seek(key, position)` | Seek to time — **rebuilds the rodio sink** |

**Design note**: `seek()` rebuilds the sink because rodio does not natively support
seeking on all source types. The mixer recreates the sink with the source advanced
to the target position.

#### Bus Routing

| Method | Purpose |
|--------|---------|
| `create_bus(name)` | Create named mix bus |
| `set_bus_volume(key, vol)` | Per-bus volume |
| `set_bus_paused(key, bool)` | Pause all sources on bus |
| `assign_to_bus(source, bus)` | Route source through bus |

#### Effects

| Method | Purpose |
|--------|---------|
| `lowpass(key, cutoff_hz)` | Low-pass filter |
| `highpass(key, cutoff_hz)` | High-pass filter |

---

### `bus.rs` — `Bus` (Mix Bus)

**~53 lines** | Simple mix bus with volume, pitch, and pause state.

#### Struct: `Bus`

```rust
pub struct Bus {
    pub name: String,
    pub volume: f32,
    pub pitch: f32,
    pub paused: bool,
}
```

Methods: `new(name)` — defaults to volume 1.0, pitch 1.0, not paused.

---

### `source.rs` — `AudioSource` (Legacy Shim)

**~30 lines** | Legacy type alias retained for backward compatibility.
New code should use `Mixer` directly.

---

### `midi_player.rs` — `MidiPlayer` (MIDI Synthesis)

**~754 lines** | Parses MIDI files via `midly` and synthesizes PCM audio using
sine-additive synthesis at 44100 Hz sample rate.

#### Key Features

| Feature | Implementation |
|---------|---------------|
| MIDI parsing | `midly` crate for SMF format |
| Synthesis | Sine-wave additive per-note |
| Sample rate | 44100 Hz hardcoded |
| Per-channel control | Mute and volume per MIDI channel |
| Per-track control | Mute and volume per MIDI track |
| Tempo | Microseconds-per-beat from MIDI tempo events |

Methods: `new`, `load(path)`, `play`, `pause`, `stop`, `set_volume`, `set_tempo`,
`mute_channel`, `mute_track`, `set_channel_volume`, `set_track_volume`,
`get_position`, `get_duration`, `is_playing`, `render_samples`.

**Design**: Not a full General MIDI synthesizer — uses simple sine waves for
rapid prototyping. Suitable for chiptune-style games, not orchestral playback.

---

## Cross-Cutting Concerns

### Error Handling

Audio operations generally return `Option` or silently ignore invalid keys rather
than panicking — audio glitches should not crash the game.

### Thread Safety

`rodio` internally manages its own audio thread. `Mixer` is single-threaded from
the Lua side. `MidiPlayer` renders samples synchronously on the calling thread.

### Lua Integration

The Lua bridge lives in `src/lua_api/audio_api.rs` (~910 lines), exposing 25+ functions
under `luna.audio.*` plus bus management and MIDI playback.

### Usage from Lua

```lua
-- Load and play a sound
local sfx = luna.audio.newSource("sounds/explosion.wav", "static")
luna.audio.play(sfx)

-- Background music with volume
local bgm = luna.audio.newSource("music/theme.ogg", "stream")
luna.audio.setVolume(bgm, 0.5)
luna.audio.setLooping(bgm, true)
luna.audio.play(bgm)

-- Bus routing
local music_bus = luna.audio.newBus("music")
luna.audio.setBusVolume(music_bus, 0.7)
```
