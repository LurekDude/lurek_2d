---
name: asset-pipeline
description: "Load this skill when working on Lurek2D asset loading: textures, audio files, Lua scripts, or filesystem sandboxing. It owns the GameFS, image loading, and asset caching patterns. Skip it for rendering or audio playback."
---
# asset-pipeline

## Mission

# Asset Pipeline — Lurek2D Engine

## When To Load

- Loading textures or images from disk
- Working on the `GameFS` sandboxed filesystem
- Implementing asset caching or hot-reloading
- Adding new asset format support

## When To Skip

- Rendering loaded textures → use `gpu-programming` skill
- Audio file playback → use `audio-integration` skill
- Lua script execution → handled by `mlua` integration

## Domain Knowledge

### Owns
- `GameFS` sandboxed filesystem patterns
- Image loading via `image` crate
- Asset path resolution (game directory relative)
- Path traversal protection
- Asset caching strategies

### Live Repository Contracts
- `src/filesystem/vfs.rs` — `GameFS` struct, sandboxed file operations
- `src/render/texture.rs` — image loading, pixel buffer conversion
- `src/audio/source.rs` — audio file loading

### Decision Rules
- **Sandbox enforced**: All file access through `GameFS` — never raw `std::fs` from Lua-accessible code
- **Path traversal blocked**: Reject any path containing `..` or absolute path components
- **Relative to game dir**: All asset paths are relative to the game's root directory
- **Load once**: Textures and audio sources cached by path — don't reload the same file
- **Format detection**: Use file extension for image/audio format detection
- **Image formats**: PNG and JPEG via `image` crate; convert to RGBA8 for GPU texture upload
- **Error handling**: Missing or invalid assets return descriptive `LuaError` — don't panic
- **No write access**: Lua scripts cannot write files — read-only filesystem access

## Companion File Index

- (no companion files extracted)

## References

- See related skills in `.github/skills/`.
