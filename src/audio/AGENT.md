# src/audio/

Audio subsystem providing sound loading, playback, and volume management through rodio.

## What This Module Contains

Mixer wraps rodio for multi-channel playback. AudioSource handles WAV/MP3/OGG/FLAC. Bus routing for master/music/sfx volume. MIDI file parsing via midly. SoundData for PCM sample access.

## Files

| File | Purpose |
|------|---------|
| `bus.rs` | `Bus` implementation |
| `midi.rs` | `Midi` implementation |
| `midi_player.rs` | `MidiPlayer` implementation |
| `mixer.rs` | `Mixer` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `sound_data.rs` | `SoundData` implementation |
| `source.rs` | `Source` implementation |

## Navigation

- **Owner agent**: `Audio-Eng`
- **Tests**: `tests/audio_tests.rs`
- **Lua API bindings**: `src/lua_api/audio_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
