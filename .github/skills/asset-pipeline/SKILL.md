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
- Game-facing asset access should resolve through GameFS and stay relative to the game root or mounted content root; direct host-path assumptions break the sandbox contract quickly.
- src/filesystem/ owns sandboxing and path rules, while src/image/ and audio source loaders own decode only; render and playback are downstream consumers, not asset-pipeline concerns.
- Normalize or canonicalize paths before caching so repeated loads hit one stable cache key instead of duplicating entries for equivalent caller strings.
- Missing assets, bad decode, blocked paths, and unsupported formats should surface as clear Lua-visible errors, not panics or silent fallback.
- Keep script loading, image decode, raw bytes access, and audio source loading separate from render, mixer, or scene decisions so failures stay attributable to the right layer.
- save/ is runtime state, not a content root for shipping assets, demos, or examples; loader rules should keep that boundary obvious.
- content/, library/, mods/, and game folders are content roots in this repo, and asset rules should preserve those boundaries instead of leaking workstation-specific filesystem layout into Lua APIs.
- Cache invalidation should follow stable path and decode assumptions, not transient caller state such as the current scene or a one-off access pattern.
- If an asset path comes from Lua, validate it at the boundary and preserve the same sandbox semantics across images, scripts, bytes, and audio sources.
- Good asset behavior here makes the loaded root, normalized path, and failure class obvious enough that a game author can correct content quickly.
## Companion File Index
- None.

## References
- src/filesystem/
- src/image/
- src/audio/source.rs
- docs/specs/filesystem.md
