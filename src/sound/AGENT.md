# src/sound/

Decoded audio sample manipulation and MIDI SoundFont state.

## What This Module Contains

SoundData for reading/writing individual PCM samples (waveform generation, effects). MidiState for SF2 SoundFont loading and playback state management.

## Files

| File | Purpose |
|------|---------|
| `midi.rs` | `Midi` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `sound_data.rs` | `SoundData` implementation |

## Navigation

- **Owner agent**: `Audio-Eng`
- **Tests**: `tests/sound_tests.rs`
- **Lua API bindings**: `src/lua_api/sound_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
