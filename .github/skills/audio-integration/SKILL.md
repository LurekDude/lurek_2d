---
name: audio-integration
description: "Load this skill when working on Luna2D audio: rodio integration, sound loading, playback control, mixer management, or audio format support. Skip it for graphics, physics, or input handling."
---

# Audio Integration — Luna2D Engine

## Load When

- Modifying `src/audio/` module code
- Adding audio format support
- Working on playback control (play, pause, stop, volume)
- Debugging audio issues (no sound, glitches, format errors)

## Owns

- rodio integration patterns for Luna2D
- Audio source loading and caching
- Mixer and sink management
- Volume control and audio state
- Supported format handling (WAV, OGG, MP3, FLAC)

## Does Not Cover

- Game loop timing → use `game-loop` skill
- Lua API surface design → use `lua-api-design` skill
- File I/O patterns → handled by `filesystem` module

## Live Repository Contracts

- `src/audio/mixer.rs` — `Mixer` struct wrapping rodio `OutputStream`, `Sink` management
- `src/audio/source.rs` — `AudioSource` for loaded audio data
- `src/lua_api/audio_api.rs` — `luna.audio.*` Lua bindings

## Decision Rules

- **Use rodio exclusively**: No raw audio output or custom audio backends
- **Sink per sound**: Each playing sound gets its own rodio `Sink` for independent control
- **Graceful fallback**: If audio device is unavailable, log warning and continue — don't crash
- **Volume range**: 0.0 (silent) to 1.0 (full volume), clamped at the API boundary
- **Load once, play many**: Audio data loaded into memory once; `Sink::append()` for replay
- **File access**: Load audio through `GameFS` for sandboxed file access
- **Format detection**: Use file extension for format detection; rodio handles decoding
- **Cleanup**: Track all active Sinks; stop and drop when sound completes or is explicitly stopped
