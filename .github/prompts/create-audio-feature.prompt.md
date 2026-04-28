---
description: "Create a new audio feature."
---

# Create Audio Feature

## Goal
- Add a new audio feature to the Lurek2D engine. Use when implementing new audio API functions, new format support, or mixer improvements....

## Inputs
- FEATURE describe the audio capability (e.g., "loop a source", "fade volume over time", "query whether playing")
- API_NAME proposed lurek.audio.* function name (e.g., lurek.audio.setLooping)
- RODIO_APPROACH any known rodio 0.17 API to use (optional; agent will research if blank)

## Steps
- Load lua-api-design before changing any files.
- Load skill audio-integration/SKILL.md
- Load skill lua-api-design/SKILL.md
- Design the lurek.audio.* function signature following existing patterns:
- First arg: source_id: usize returned by newSource()
- Subsequent args: feature-specific parameters
- Implement in src/audio/mixer.rs:
- Use rodio 0.17 API check rodio::Sink methods for looping, volume, pause, etc.
- Handle missing audio hardware gracefully (the Mixer may have stream_handle: None)
- Register the binding in src/lua_api/audio_api.rs:
- Follow the state.clone() move closure pattern
- Return LuaResult<()> or appropriate type

## Success Criteria
- [ ] Updated src/audio/mixer.rs with new method
- [ ] Updated src/lua_api/audio_api.rs with new Lua binding
- [ ] New test in tests/rust/unit/audio_tests.rs
- [ ] Updated docs/api/lurek.md
- [ ] Verified: cargo build clean, cargo test passes

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-audio-feature <function>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design
- **Inputs required**: function
