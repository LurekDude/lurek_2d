---
description: Build a release binary for Lurek2D for a target platform. Use when creating a distributable build. Produces a stripped release binary in...
agent: Developer
---
# Op Build Release

## Goal

Build a release binary for Lurek2D for a target platform. Use when creating a distributable build. Produces a stripped release binary in... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `TARGET_TRIPLE` — Rust target triple (e.g., `x86_64-pc-windows-msvc`, `x86_64-unknown-linux-gnu`). Leave blank for native host.
- `VERSION` — version string to verify (optional; will check `Cargo.toml`)

## Steps

1. Load [skill: cross-platform](.github/skills/cross-platform/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Verify `Cargo.toml` version matches `VERSION` (if provided)
3. Run all quality gates first:
4. Build release:
5. Verify output:
6. Native: `target/release/lurek2d.exe` (Windows) or `target/release/lurek2d` (Linux)
7. Cross: `target/<TARGET_TRIPLE>/release/lurek2d[.exe]`
8. Smoke test the binary:
9. Check binary size:
10. Typical release binary: 5–15 MB (software rendering stack)
11. Warning if > 50 MB — likely debug symbols leaked into release build

## Success Criteria

- [ ] Release binary at `target/release/lurek2d[.exe]`
- [ ] Smoke test result (window opened, no panic)
- [ ] Binary size reported

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/op-build-release <TARGET_TRIPLE>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: cross-platform, rust-coding
- **Inputs required**: TARGET_TRIPLE
