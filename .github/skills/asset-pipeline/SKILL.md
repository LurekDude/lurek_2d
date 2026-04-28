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
- All game-facing file access should go through GameFS.
- Block path traversal and unsafe absolute-path behavior.
- Resolve asset paths relative to the game root.
- Prefer load-once and cache-by-path behavior for reused assets.
- Return clear Lua-visible errors instead of panicking on missing assets.
- Keep loading and decoding separate from playback and rendering concerns.

## Companion File Index
- None.

## References
- src/filesystem/vfs.rs
- src/image/
- src/audio/source.rs