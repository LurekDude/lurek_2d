---
description: "Add a new audio feature to the Luna2D engine. Use when implementing new audio API functions, new format support, or mixer improvements. Produces working Rust audio code with Lua bindings."
---

# Create Audio Feature

**Purpose**: Implement new audio functionality across `src/audio/`, `src/lua_api/audio_api.rs`, and `docs/lua_api_reference.md`.
**Use When**: A new audio capability is needed (looping, volume fades, format support, etc.).
**Do Not Use When**: The change is a bug fix to existing audio — use `fix-engine-bug.prompt.md` instead.
**Scope**: `src/audio/`, `src/lua_api/audio_api.rs`, `docs/lua_api_reference.md`.

## Inputs

- `FEATURE` — describe the audio capability (e.g., "loop a source", "fade volume over time", "query whether playing")
- `API_NAME` — proposed `luna.audio.*` function name (e.g., `luna.audio.setLooping`)
- `RODIO_APPROACH` — any known rodio 0.17 API to use (optional; agent will research if blank)

## Steps

1. Load skill `audio-integration/SKILL.md`
2. Load skill `lua-api-design/SKILL.md`
3. Design the `luna.audio.*` function signature following existing patterns:
   - First arg: `source_id: usize` returned by `newSource()`
   - Subsequent args: feature-specific parameters
4. Implement in `src/audio/mixer.rs`:
   - Use `rodio 0.17` API — check `rodio::Sink` methods for looping, volume, pause, etc.
   - Handle missing audio hardware gracefully (the `Mixer` may have `stream_handle: None`)
5. Register the binding in `src/lua_api/audio_api.rs`:
   - Follow the `state.clone()` → `move` closure pattern
   - Return `LuaResult<()>` or appropriate type
6. Write integration test in `tests/audio_tests.rs`
7. Update `docs/lua_api_reference.md` under `## luna.audio`
8. Run `cargo build`, `cargo clippy`, `cargo test`

## Outputs

- Updated `src/audio/mixer.rs` with new method
- Updated `src/lua_api/audio_api.rs` with new Lua binding
- New test in `tests/audio_tests.rs`
- Updated `docs/lua_api_reference.md`
- Verified: `cargo build` clean, `cargo test` passes

## Acceptance

- [ ] `luna.audio.<function>` callable from Lua without panic
- [ ] Graceful no-op when audio hardware is unavailable
- [ ] Test in `tests/audio_tests.rs` covers the new function
- [ ] `docs/lua_api_reference.md` updated
- [ ] `cargo clippy` zero warnings

## References

**Required Skills**: `audio-integration`, `lua-api-design`
**Suggested Agents**: `Audio-Eng`, `Developer`
**Related Prompts**: `create-api-function.prompt.md`
**Commands**:
```powershell
cargo build; cargo clippy; cargo test
```
**Docs**: `docs/lua_api_reference.md`
