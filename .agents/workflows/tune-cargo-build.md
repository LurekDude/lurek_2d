---
description: "Tune Cargo build for speed, size, or LTO for a specific build mode."
---

# Tune Cargo Build

## Goal
- Improve build performance or artifact size for a specific Cargo profile.

## Inputs
- Target profile (dev, release, dist).
- Optimization goal (speed, size, LTO).
- Current measurement or baseline.

## Steps
1. Load build-system before acting.
2. Read Cargo.toml profiles, rust-toolchain.toml, and tools/dist/ before changing anything.
3. Confirm which profile and output path the repo uses for the target goal.
4. Make the smallest change that addresses the goal: profile opt-level, LTO, codegen-units, strip, or UPX flags.
5. Measure the result with the correct build mode and output path.
6. Update docs or task descriptions if user-facing build workflow changed.

## Success Criteria
- [ ] The change is in the correct Cargo profile.
- [ ] The measured result matches the goal.
- [ ] tools/dist/ and local task descriptions are in sync.
- [ ] No other profiles were changed unintentionally.

## Example Invocation
- /tune-cargo-build profile=dist goal=size
