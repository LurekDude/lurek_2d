---
description: "Load when handling platform-specific code, cfg gates, or Windows/Linux/macOS differences. Skip for pure game logic or Lua scripts."
alwaysApply: false
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
- Lurek2D targets desktop only: Windows, Linux, and macOS on x86_64 and ARM; portability work should optimize for those three surfaces and ignore mobile or WASM.
- Windows is a strong local path, which makes PowerShell 5.1 compatibility important for user-facing scripts, installers, and dist helpers.
- Prefer shared winit, wgpu, rodio, and filesystem behavior before adding cfg-specific branches.
- Use Path and PathBuf plus GameFS rules everywhere; never hardcode separators or drive assumptions.
- Window startup, file paths, install scripts, dist packaging, and extension tooling are the most common places where platform drift appears first.
- Keep platform-specific code isolated to the narrowest surface and document why the branch exists.
- Shell commands in docs or scripts should be explicit about which shell they target.

## References
- src/window/
- src/app/
- src/filesystem/
- tools/dist/
- Cargo.toml
