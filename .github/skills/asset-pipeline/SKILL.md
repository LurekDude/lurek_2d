---
name: asset-pipeline
description: "Load this skill when working on Luna2D asset loading: textures, audio files, Lua scripts, or filesystem sandboxing. It owns the GameFS, image loading, and asset caching patterns. Skip it for rendering or audio playback."
---

# Asset Pipeline — Luna2D Engine

## Load When

- Loading textures or images from disk
- Working on the `GameFS` sandboxed filesystem
- Implementing asset caching or hot-reloading
- Adding new asset format support

## Owns

- `GameFS` sandboxed filesystem patterns
- Image loading via `image` crate
- Asset path resolution (game directory relative)
- Path traversal protection
- Asset caching strategies

## Does Not Cover

- Rendering loaded textures → use `software-rendering` skill
- Audio file playback → use `audio-integration` skill
- Lua script execution → handled by `mlua` integration

## Live Repository Contracts

- `src/filesystem/vfs.rs` — `GameFS` struct, sandboxed file operations
- `src/graphics/texture.rs` — image loading, pixel buffer conversion
- `src/audio/source.rs` — audio file loading

## Decision Rules

- **Sandbox enforced**: All file access through `GameFS` — never raw `std::fs` from Lua-accessible code
- **Path traversal blocked**: Reject any path containing `..` or absolute path components
- **Relative to game dir**: All asset paths are relative to the game's root directory
- **Load once**: Textures and audio sources cached by path — don't reload the same file
- **Format detection**: Use file extension for image/audio format detection
- **Image formats**: PNG and JPEG via `image` crate; convert to RGBA8 for GPU texture upload
- **Error handling**: Missing or invalid assets return descriptive `LuaError` — don't panic
- **No write access**: Lua scripts cannot write files — read-only filesystem access
