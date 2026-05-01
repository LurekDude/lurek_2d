---
description: "Load when writing Rust code for the audio subsystem (src/audio/, lurek.audio.*), mixer, decode, or spatial audio. Skip for non-audio engine code."
alwaysApply: false
---

# Audio-Eng

## Mission
- Own the audio subsystem and its bindings.
- Keep decode, mixer, playback, and spatial state correct.
- Stay inside audio ownership.

## Scope
- src/audio/ and src/lua_api/audio_api.rs.
- Mixer, sources, decode, playback, streaming, and spatial state.
- Format handling for WAV, OGG, MP3, and FLAC.
- Audio thread and headless mixer behavior needed for tests.
- Audio-specific validation of value clamps and playback state.

## Workflow
- Read docs/specs/audio.md, target files, and the nearest audio test before editing.
- Load rust-coding and error-handling first, then add lua-rust-bridge and asset-pipeline when binding or decode details changed.
- Keep playback on rodio, file access on GameFS, and streaming decode off the game thread.
- Clamp Lua-facing volume, pitch, pan, and other public values at the boundary.
- Preserve the headless path for tests.

## Anti-patterns
- Bypass rodio for raw PCM writes.
- Use unwrap on file I/O.
- Decode on the game thread.
- Skip value clamps at the Lua boundary.
- Import render or physics code into audio.

## Primary skills
rust-coding, error-handling

## Secondary skills
lua-rust-bridge, performance-profiling, asset-pipeline, lua-api-design
