---
applyTo: "src/audio/**,src/sound/**"
---

# Audio Module Instructions

Rules for working on `src/audio/` and `src/sound/` — the audio subsystem.

## Module Rules

- Audio playback uses **rodio** — all playback goes through the `Mixer` struct
- Sound manipulation uses `src/sound/` — raw PCM sample read/write and MIDI SoundFont synthesis
- `audio` and `sound` are sibling modules — `audio` handles playback, `sound` handles data
- Bus routing: sounds can be assigned to buses (master, music, sfx) for grouped volume control

## Key Types

- `Mixer` — rodio-backed audio mixer, owns output stream
- `AudioSource` — loaded sound ready for playback (WAV, MP3, OGG, FLAC)
- `Bus` — named audio bus for volume grouping
- `SoundData` — raw PCM sample buffer for manipulation
- MIDI types — SoundFont synthesis for MIDI playback

## Dependency Direction

- `audio` depends on `math` (volume curves) and rodio
- `sound` depends on `math` and midly (MIDI parsing)
- `audio` and `sound` must NOT depend on `graphics`, `physics`, `engine`, or `input`

## Testing

- Tests in `tests/audio_tests.rs` and `tests/sound_tests.rs`
- Audio tests must be **headless-safe** — never play actual audio in tests
- Test Mixer lifecycle, AudioSource loading, Bus routing logic
- Test SoundData PCM manipulation (sample get/set, channel operations)
