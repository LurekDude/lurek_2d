---
description: "Build a release binary."
---

# Op Build Release

## Goal
- Build a release binary for Lurek2D for a target platform. Use when creating a distributable build. Produces a stripped release binary in...

## Inputs
- TARGET_TRIPLE Rust target triple (e.g., x86_64-pc-windows-msvc, x86_64-unknown-linux-gnu). Leave blank for native host.
- VERSION version string to verify (optional; will check Cargo.toml)

## Steps
- Load cross-platform, rust-coding before changing any files.
- Verify Cargo.toml version matches VERSION (if provided)
- Run all quality gates first:
- Build release:
- Verify output:
- Native: target/release/lurek2d.exe (Windows) or target/release/lurek2d (Linux)
- Cross: target/<TARGET_TRIPLE>/release/lurek2d[.exe]
- Smoke test the binary:
- Check binary size:
- Typical release binary: 5 10 MB (software rendering stack)
- Warning if > 50 MB likely debug symbols leaked into release build

## Success Criteria
- [ ] Release binary at target/release/lurek2d[.exe]
- [ ] Smoke test result (window opened, no panic)
- [ ] Binary size reported

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /op-build-release <TARGET_TRIPLE>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: cross-platform, rust-coding
- **Inputs required**: TARGET_TRIPLE
