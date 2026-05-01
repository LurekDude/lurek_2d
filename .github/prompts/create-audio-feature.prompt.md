---
description: "Create one bounded audio feature in the engine and sync the exposed contract."
agent: "Developer"
---
# Create Audio Feature

## Goal
- Add one audio feature without leaking into unrelated engine systems.

## Inputs
- Feature goal.
- Target audio path.
- Lua-facing impact.
- Expected validation path.

## Steps
1. Load [skill: lua-api-design](../skills/lua-api-design/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), [skill: asset-pipeline](../skills/asset-pipeline/SKILL.md), and [skill: error-handling](../skills/error-handling/SKILL.md) before acting.
2. Read src/audio/, any matching src/lua_api/audio_api.rs code, docs/specs/audio.md, and nearby tests or examples before editing.
3. Keep loading, mixer, and playback responsibilities clear, surface errors cleanly, and sync the Lua-facing contract only where the feature actually changes it.
4. Run the narrowest audio-focused test or build check first, then regenerate docs or run broader gates only if the public contract changed.

## Success Criteria
- [ ] The prompt goal was completed: Add one audio feature without leaking into unrelated engine systems.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-audio-feature feature=loop_region

## CAG Metadata
Mode: agent
Loads skills: lua-api-design, rust-coding, asset-pipeline, error-handling
Inputs required: Feature goal., Target audio path., Lua-facing impact., Expected validation path.
