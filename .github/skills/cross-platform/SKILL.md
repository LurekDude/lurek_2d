---
name: cross-platform
description: "Load this skill when handling platform-specific code, cfg gates, or Windows/Linux/macOS differences. Skip it for pure game logic or Lua scripts."
---
# cross-platform

## Mission
- Own platform-specific Rust behavior and compatibility rules.

## When To Load
- Add cfg-gated code.
- Handle OS-specific file or window behavior.
- Review Windows, Linux, or macOS differences.
- Check portability of a build or runtime change.

## When To Skip
- Pure game logic.
- Lua script work.

## Domain Knowledge
- Prefer shared code paths before adding cfg splits.
- Use Path and PathBuf, not hardcoded separators.
- Let winit, wgpu, and rodio absorb platform differences when possible.
- Keep platform-specific code small and isolated.
- Do not add raw platform APIs unless the repo already needs them.
- Test the narrowest affected platform surface first.

## Companion File Index
- None.

## References
- src/window/
- src/filesystem/vfs.rs
- Cargo.toml