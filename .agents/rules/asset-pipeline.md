---
description: "Load when working on asset loading, GameFS, image decode, Lua script loading, or asset cache rules. Skip for rendering logic or audio playback."
alwaysApply: false
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
- Game-facing asset access should resolve through GameFS and stay relative to the game root or mounted content root.
- src/filesystem/ owns sandboxing and path rules, while src/image/ and audio source loaders own decode only.
- Normalize or canonicalize paths before caching so repeated loads hit one stable cache key.
- Missing assets, bad decode, blocked paths, and unsupported formats should surface as clear Lua-visible errors, not panics or silent fallback.
- Keep script loading, image decode, raw bytes access, and audio source loading separate from render, mixer, or scene decisions.
- save/ is runtime state, not a content root for shipping assets.
- content/, library/, mods/, and game folders are content roots in this repo.
- If an asset path comes from Lua, validate it at the boundary.

## References
- src/filesystem/
- src/image/
- src/audio/source.rs
- docs/specs/filesystem.md
