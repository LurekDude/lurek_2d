---
description: "Add a new audio feature to the Lurek2D engine. Use when implementing new audio API functions, new format support, or mixer improvements...."
agent: Developer
---
# Create Audio Feature

## Goal

Add a new audio feature to the Lurek2D engine. Use when implementing new audio API functions, new format support, or mixer improvements.... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `FEATURE` — describe the audio capability (e.g., "loop a source", "fade volume over time", "query whether playing")
- `API_NAME` — proposed `lurek.audio.*` function name (e.g., `lurek.audio.setLooping`)
- `RODIO_APPROACH` — any known rodio 0.17 API to use (optional; agent will research if blank)

## Steps

1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) before changing any files.
2. Load skill `audio-integration/SKILL.md`
3. Load skill `lua-api-design/SKILL.md`
4. Design the `lurek.audio.*` function signature following existing patterns:
5. First arg: `source_id: usize` returned by `newSource()`
6. Subsequent args: feature-specific parameters
7. Implement in `src/audio/mixer.rs`:
8. Use `rodio 0.17` API — check `rodio::Sink` methods for looping, volume, pause, etc.
9. Handle missing audio hardware gracefully (the `Mixer` may have `stream_handle: None`)
10. Register the binding in `src/lua_api/audio_api.rs`:
11. Follow the `state.clone()` → `move` closure pattern
12. Return `LuaResult<()>` or appropriate type

## Success Criteria

- [ ] Updated `src/audio/mixer.rs` with new method
- [ ] Updated `src/lua_api/audio_api.rs` with new Lua binding
- [ ] New test in `tests/rust/unit/audio_tests.rs`
- [ ] Updated `docs/API/lua-api.md`
- [ ] Verified: `cargo build` clean, `cargo test` passes

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-audio-feature <function>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-api-design
- **Inputs required**: function
