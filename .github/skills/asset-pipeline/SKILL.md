---
name: asset-pipeline
description: "Load this skill when working on asset loading, GameFS, image decode, Lua script loading, or asset cache rules. Skip it for rendering logic or audio playback."
---
# asset-pipeline

## Mission
- Own asset loading, sandboxed file access, and cache rules.

## When To Load
- Change GameFS behavior.
- Load images, audio files, or Lua scripts.
- Add or tune asset cache rules.
- Review path safety for asset access.

## When To Skip
- Render pipeline logic.
- Audio playback logic.

## Domain Knowledge
- Game-facing asset access should resolve through GameFS and stay relative to the game root.
- src/filesystem/ owns sandboxing and path rules; src/image/ and audio source loaders own decode, not playback.
- Normalize paths before caching so repeated loads hit one cache key instead of per-call duplicates.
- Missing assets, bad decode, and blocked paths should surface as clear Lua-visible errors, not panics.
- Keep script loading, image decode, and raw bytes access separate from render and playback decisions.
- save/ is runtime state, not a content root for examples or shipping assets.
- content/, library/, mods, and game folders are content roots; asset rules should preserve those boundaries instead of leaking host filesystem assumptions into Lua-facing APIs.
- Cache invalidation should follow stable path and decode assumptions, not transient caller state.
- Filesystem safety here overlaps with security review, but this skill owns the loading contract rather than the exploit analysis.
## Companion File Index
- None.

## References
- src/filesystem/
- src/image/
- src/audio/source.rs
- docs/specs/filesystem.md
