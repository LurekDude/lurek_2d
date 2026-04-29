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
- Lurek2D targets desktop only: Windows, Linux, and macOS on x86_64 and ARM.
- Windows is a strong local path here, so PowerShell 5.1 compatibility matters for user-facing scripts.
- Prefer shared winit, wgpu, and rodio behavior before adding cfg-specific branches.
- Use Path and PathBuf plus GameFS rules; never hardcode separators or shell-specific paths in engine code.
- Window startup, file paths, and install scripts are the most likely cross-platform drift points in this repo.
- Keep platform-specific code isolated and prove only the narrow affected surface.
- Desktop-only means Windows, Linux, and macOS behavior should stay aligned for startup, filesystem access, and packaging, but mobile and WASM branches are out of scope.
- Install, dist, and editor tooling often surface platform drift faster than pure engine code in this repo.
- Prefer repo-level helpers and library abstractions before introducing new OS-specific shell or API behavior.
## Companion File Index
- None.

## References
- src/window/
- src/app/
- src/filesystem/
- tools/dist/
- Cargo.toml
