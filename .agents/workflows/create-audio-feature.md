---
description: "Add one audio feature to the engine: format support, playback controls, or spatial audio."
---

# Create Audio Feature

## Goal
- Implement one bounded audio feature in src/audio/ and its Lua binding.

## Inputs
- Feature goal.
- Target lurek.audio.* shape when public API changes.
- Format, playback, or spatial concern.
- Test target: headless or device.

## Steps
1. Load rust-coding, error-handling, and lua-rust-bridge before acting.
2. Read docs/specs/audio.md, src/audio/, src/lua_api/audio_api.rs, and the nearest audio test before editing.
3. Keep playback on rodio, file access on GameFS, streaming decode off the game thread.
4. Clamp all Lua-facing values at the boundary.
5. Run the narrowest audio test, then widen to the required audio gate.
6. Update docs/specs/audio.md when the contract changes.

## Success Criteria
- [ ] The feature is implemented in src/audio/ with a thin binding in audio_api.rs.
- [ ] Lua-facing values are clamped.
- [ ] The headless test path works.
- [ ] docs/specs/audio.md is updated if the contract changed.

## Anti-patterns
- Bypass rodio for raw PCM.
- Decode on the game thread.
- Skip value clamps at the Lua boundary.
- Use unwrap on file I/O.

## Example Invocation
- /create-audio-feature goal=looping_bgm format=ogg
