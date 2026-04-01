# `src/sound/` — Raw Audio Data and SoundFont Management

## Purpose

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

### How It Works

PCM samples are `f32` normalised to [−1.0, 1.0], matching the format rodio
uses internally.  When a `SoundData` instance is handed to the audio module
for playback, it is converted to a rodio `SamplesBuffer<f32>` from the
underlying `Vec<f32>` — a zero-copy path when the sample rate and channel
count match the output device.

`MidiState`'s RIFF validation checks for the 4-byte `"RIFF"` magic at offset 0
and the 4-byte `"sfbk"` format identifier at offset 8.  This is a
minimum-viable validity check sufficient to catch obviously wrong files
(a WAV file accidentally loaded as a SoundFont) without implementing a full
SF2 parser.  A corrupt but structurally valid SF2 will pass this check and may
produce incorrect synthesis output — full SF2 validation is out of scope.

### Dependency Direction

```
sound/ ──────► (none — uses rodio for file decoding)
```

**Leaf module** — no Luna2D dependencies.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `SoundData`, `MidiState`.

**~11 lines** — re-exports.

---

### `sound_data.rs` — `SoundData` (Raw PCM Buffer)

**~187 lines** | Raw audio sample buffer with Lua UserData interface.

#### Struct: `SoundData`

```rust
pub struct SoundData {
    samples: Vec<f32>,    // normalized -1.0 to 1.0
    sample_rate: u32,
    channels: u16,
    bit_depth: u16,
}
```

#### Construction

| Method | Source |
|--------|--------|
| `new(sample_count, rate, channels, depth)` | Silent buffer |
| `from_file(path)` | Decoded via rodio |

#### Methods

| Method | Returns |
|--------|---------|
| `get_sample(index)` | `Option<f32>` |
| `set_sample(index, val)` | Clamped to [-1.0, 1.0] |
| `sample_count()` | Total samples |
| `sample_rate()` | Hz |
| `channel_count()` | 1 (mono) or 2 (stereo) |
| `bit_depth()` | Bits per sample |
| `duration()` | Seconds (samples / rate / channels) |
| `as_samples()` | `&[f32]` slice |
| `get_string()` | Metadata string |

#### Lua UserData

`getSampleCount`, `getSampleRate`, `getChannelCount`, `getDuration`,
`getBitDepth`, `getSample`, `setSample`.

---

### `midi.rs` — `MidiState` (SoundFont Manager)

**~113 lines** | SoundFont file loading with RIFF/sfbk validation.

#### Struct: `MidiState`

```rust
pub struct MidiState {
    soundfont_data: Option<Vec<u8>>,
    soundfont_path: Option<String>,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `new()` | Empty state |
| `set_soundfont(path)` | Load and validate SF2 file |
| `has_soundfont()` | Is a soundfont loaded? |
| `clear_soundfont()` | Unload soundfont |
| `soundfont_path()` | Current SF2 path |
| `soundfont_data()` | Raw bytes reference |

**Validation**: Checks RIFF header and sfbk format identifier before accepting
a SoundFont file. Rejects invalid files with descriptive errors.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/sound_api.rs` (~60 lines), exposing
`SoundData` under `luna.sound.*`.

### Usage from Lua

```lua
-- Create and manipulate raw audio
local sd = luna.sound.newSoundData(44100, 44100, 1, 16)

-- Generate a sine wave
for i = 0, 44099 do
    local t = i / 44100
    sd:setSample(i, math.sin(2 * math.pi * 440 * t))
end
```
