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
- Supported targets: Windows x86_64, Linux x86_64, macOS x86_64, macOS ARM64. No mobile, no WASM (binding constraint A-02). Any cfg gate for `target_os = "android"` or `target_arch = "wasm32"` is out of scope and should not be added.
- Windows is the primary development and CI platform. PowerShell 5.1 is the minimum shell version for scripts and dist helpers. Scripts must not use PowerShell 7-only syntax (e.g., `??=`, `ForEach-Object -Parallel`). When in doubt, test in PS 5.1.
- Platform drift checklist for path handling: (1) use `std::path::Path` and `PathBuf`, (2) never use `\` as a path separator literal, (3) never use `:` or drive letters in GameFS paths, (4) never call `std::fs` directly in engine modules (use GameFS). A path that works on Windows by accident but breaks on Linux is a defect.
- `winit` and `wgpu` abstract most platform differences for window and GPU. When a window/GPU issue is platform-specific, check `winit`/`wgpu` issue trackers before adding a `cfg` branch in engine code.
- Platform-specific code pattern: isolate in a `platform/` submodule or behind a `cfg` block with a `// Platform-specific:` comment explaining why the branch exists and what the alternative behavior is on other targets. Undocumented `cfg` branches are invisible maintenance debt.
- Audio differences: `rodio` has platform-specific output device enumeration. Windows uses WASAPI, Linux uses ALSA/PipeWire, macOS uses CoreAudio. The Lua API surface is identical on all platforms. `lurek.audio.devices()` is the platform-specific surface — test it separately on each target.
- Install script behavior: `tools/dist/install.ps1` targets Windows only. Linux installation is manual or via a future Makefile. Document clearly which install path applies to which platform rather than using conditionals that silently no-op.
- CI platform testing minimum: Windows x86_64 (mandatory), Linux x86_64 (mandatory). macOS can use the free GitHub Actions macOS runner but is optional given resource cost.
- When adding a cfg-gated feature, add a corresponding test or smoke scenario that exercises the cfg path on the affected platform. An untested cfg branch will regress at next update.
## Companion File Index
- None.

## References
- src/window/
- src/app/
- src/filesystem/
- tools/dist/
- Cargo.toml
