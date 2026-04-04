# `sound` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.sound` |
| **Source** | `src/sound/` |
| **Tests** | `tests/sound_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_sound.lua` |

## Summary

The sound module provides the raw audio data layer that sits beneath the
higher-level `audio/` playback module.  `SoundData` is an in-memory PCM
buffer — a `Vec<f32>` of normalised samples in [−1.0, 1.0] at a declared
sample rate and channel count — that Lua scripts can read and write one sample
at a time.  This enables procedural audio synthesis entirely from Lua (generate
a sine wave, apply an ADSR envelope, create a chord), waveform inspection,
and custom audio effect pipelines without requiring external audio tools.

`MidiState` handles SoundFont (SF2) file loading for the MIDI synthesis path
in `audio/mixer.rs`: it reads the raw bytes of an SF2 file, validates the
RIFF/sfbk header magic to detect malformed files before they reach the
synthesiser, and holds the validated byte slice for the `MidiPlayer` to
reference.  The module is intentionally thin — it does not synthesise audio
or parse MIDI events; those responsibilities live in `audio/`.

## Architecture

```
sound/
  │
  ├── SoundData ── raw PCM audio buffer
  │     ├── samples: Vec<f32> (normalized -1.0 to 1.0)
  │     ├── sample_rate, channels, bit_depth
  │     ├── Per-sample get/set (clamped)
  │     └── Lua UserData: getSample, setSample, getDuration, etc.
  │
  └── MidiState ── SoundFont loading and validation
        ├── soundfont_data: Option<Vec<u8>> (raw SF2 bytes)
        ├── RIFF/sfbk validation on load
        └── set/has/clear_soundfont, soundfont_path
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Re-export shim — `SoundData` and `MidiState` live in `audio/` |

## Submodules

### `sound::mod`

Re-export compatibility shim that brings `SoundData` and `MidiState` from `crate::audio` into the `sound` namespace.

- **`SoundData`** (struct, re-exported from `audio::sound_data`): Decoded f32 PCM audio buffer with per-sample read/write. Fields: `samples: Vec<f32>` (interleaved channels), `sample_rate: u32`, `channels: u16`, `bit_depth: u16`. Methods: `new(sample_count, sample_rate, channels)`, `from_file(path)`, `get_sample(index) → Option<f32>`, `set_sample(index, value)`, `sample_count()`, `sample_rate()`, `channel_count()`, `bit_depth()`, `duration() → f64`, `as_samples() → &[f32]`. Implements `mlua::UserData`.
- **`MidiState`** (struct, re-exported from `audio::midi`): SoundFont (SF2) state tracker. Fields: `soundfont_data: Option<Vec<u8>>`, `soundfont_path: Option<String>`. Methods: `new()`, `set_soundfont(data, path) → Result<(), String>` (validates RIFF/sfbk header), `has_soundfont() → bool`, `clear_soundfont()`, `soundfont_data() → Option<&[u8]>`.

## Key Types

### Structs (re-exported)

#### `audio::sound_data::SoundData`

Decoded audio samples in f32 PCM format. Stores interleaved samples (stereo: L, R, L, R…). Samples are clamped to `[-1.0, 1.0]` on write. Constructed either as a silent buffer (`new`) or decoded from an audio file via rodio (`from_file`). Exposes per-sample access from Lua for procedural audio synthesis, oscillators, and DSP effect processing.

| Field | Type | Description |
|-------|------|-------------|
| `samples` | `Vec<f32>` | Interleaved PCM samples across all channels |
| `sample_rate` | `u32` | Sample rate in Hz (e.g. 44100) |
| `channels` | `u16` | Number of audio channels (1 = mono, 2 = stereo) |
| `bit_depth` | `u16` | Bit depth (always 32 for f32 buffers) |

#### `audio::midi::MidiState`

SoundFont (SF2) loader and validator for the MIDI synthesis path. At most one SoundFont can be active; loading a new one replaces the previous. Validates the RIFF/sfbk header magic before storing the bytes, so malformed SF2 files are rejected before reaching the synthesiser.

| Field | Type | Description |
|-------|------|-------------|
| `soundfont_data` | `Option<Vec<u8>>` | Raw SF2 bytes, or `None` if no SoundFont is loaded |
| `soundfont_path` | `Option<String>` | Path of the loaded SoundFont file, if any |

## Item Summary

| Kind | Count |
|------|-------|
| `struct` (re-exported) | 2 |
| **Total** | **2** |

## Lua API

Exposed under `luna.sound.*` by `src/lua_api/sound_api/`.

