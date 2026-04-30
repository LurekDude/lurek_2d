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
- Lurek2D targets desktop only: Windows, Linux, and macOS on x86_64 and ARM, so portability work should optimize for those three surfaces and ignore mobile or WASM branches entirely.
- Windows is a strong local path in this repo, which makes PowerShell 5.1 compatibility important for user-facing scripts, installers, and dist helpers.
- Prefer shared winit, wgpu, rodio, and filesystem behavior before adding cfg-specific branches; the portable path should remain the default, not the exception.
- Use Path and PathBuf plus GameFS rules everywhere you can; never hardcode separators, drive assumptions, or shell-specific path logic inside engine code.
- Window startup, file paths, install scripts, dist packaging, and extension tooling are the most common places where platform drift appears first here.
- Keep platform-specific code isolated to the narrowest surface and document why the branch exists; hidden cfg behavior spread across many files becomes hard to reason about quickly.
- Desktop-only support means Windows, Linux, and macOS behavior should stay aligned for startup, filesystem access, logging paths, and packaging outputs.
- Shell commands in docs or scripts should be explicit about which shell they target; PowerShell, bash, and cargo invocations should not be casually mixed.
- Install, dist, and editor tooling often surface cross-platform drift faster than pure engine code, so a portability review should include those outer layers.
- Prefer repo-level helpers and library abstractions before introducing OS-specific APIs; if a branch is unavoidable, prove the exact behavior that differs.
- Cross-platform work here is successful when the common path stays simple and the exceptional branch is both narrow and easy to validate on the affected OS.
## Companion File Index
- None.

## References
- src/window/
- src/app/
- src/filesystem/
- tools/dist/
- Cargo.toml
