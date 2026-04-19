---
name: cross-platform
description: "Load this skill when dealing with platform-specific code, conditional compilation, or cross-platform compatibility in Lurek2D. It owns platform abstraction patterns and OS-specific workarounds. Skip it for pure game logic or Lua scripting."
---
# cross-platform

## Mission

# Cross-Platform — Lurek2D Engine

## When To Load

- Adding platform-specific code or `#[cfg(target_os)]` blocks
- Debugging issues on a specific OS (Windows, Linux, macOS)
- Working with winit platform differences
- Handling file path differences across operating systems

## When To Skip

- Game logic → pure Lua, platform-independent
- Rendering → wgpu is cross-platform (Vulkan/DX12/Metal)
- Build system → use `ci-cd-pipeline` skill

## Domain Knowledge

### Owns
- Platform abstraction patterns
- Conditional compilation strategies
- OS-specific workaround documentation
- Path handling for cross-platform compatibility

### Live Repository Contracts
- `src/window/` — winit window creation and event loop (cross-platform)
- `src/filesystem/vfs.rs` — path handling (OS differences)
- `Cargo.toml` — platform-specific dependencies

### Decision Rules
- **Minimize platform code**: Use cross-platform crates (winit, wgpu, rodio) to avoid `#[cfg]` blocks
- **Path handling**: Use `std::path::PathBuf` and `Path` — never hardcode `/` or `\\`
- **Line endings**: Use `\n` in generated content; git handles line ending conversion
- **Window creation**: Let winit handle platform differences — don't add raw Win32/X11/Cocoa code
- **Audio device**: rodio handles platform audio backends — don't add platform-specific audio code
- **File separators**: Use `Path::join()` — never string concatenation for file paths
- **Test on target**: Platform-specific code must be tested on that platform

## Companion File Index

- (no companion files extracted)

## References

- See related skills in `.github/skills/`.
