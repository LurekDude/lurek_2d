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
- GameFS is the access boundary. All asset loads must go through `lurek.fs.*` or the Rust `GameFS` API in `src/filesystem/`. Direct host path access (`std::fs::read`) inside `src/<module>/` is a defect — it bypasses sandbox rules, breaks relative-path portability, and makes content roots non-fungible.
- Path normalization rule: convert `\` to `/`, collapse `..` and `.` segments, and lower-case the extension before building a cache key. The canonical path is the GameFS-relative string after normalization. Two callers with `sprites/hero.png` and `./sprites/hero.png` must hit the same cache slot.
- Layer ownership: `src/filesystem/` = sandbox rules, path normalization, access control. `src/image/` = decode PNG/JPEG/LIMG to raw RGBA. `src/audio/source.rs` = decode WAV/OGG to PCM. Render and mixer consume decoded output; they do not own decode. Script loader is a separate pipeline from asset loader.
- Supported formats: images — PNG, JPEG, LIMG (engine-specific); audio — WAV, OGG; scripts — `.lua` only. Any other format produces a clear error, not silent fallback. When adding a new format, add it to `docs/specs/filesystem.md` under Supported Formats.
- Cache invalidation: the asset cache key is (normalized-path, mount-point-id). Invalidate on unmount or explicit `lurek.fs.cache_clear()`. Never invalidate on scene change unless a new content root is mounted for that scene.
- `save/` directory is runtime state, not a content root. Do not load game assets from `save/`. Assets stored in `save/` are serialized game data (save files, high scores) and may be corrupt or tampered by the user.
- `mods/` directory is a secondary content root with lower priority than the primary game root. A mod asset at `mods/<name>/sprites/hero.png` shadows the game asset at `sprites/hero.png` only when the mod is explicitly mounted.
- Hot-reload: `lurek.fs.watch(path, callback)` watches a file for changes. In release/dist builds, this API is a no-op. Content that depends on hot-reload must not break when the watcher is absent.
- Error contract: asset errors surface as `mlua::Error::RuntimeError` with the pattern `"lurek.image.load: file not found: <normalized-path>"`. Never let a missing asset produce a panic, a blank default, or a log message that the author cannot see.
## Companion File Index
- None.

## References
- src/filesystem/
- src/image/
- src/audio/source.rs
- docs/specs/filesystem.md
