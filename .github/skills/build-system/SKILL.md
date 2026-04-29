---
name: build-system
description: "Load this skill when changing Cargo profiles, debug or release builds, feature flags, build output, or packaging. Skip it for CI/CD setup or Rust code changes."
---
# build-system

## Mission
- Own local build commands, Cargo profiles, feature flags, and packaging scripts.

## When To Load
- Build or run the engine locally.
- Choose between dev, release, and dist builds.
- Tune build size or speed.
- Package or install the engine.
- Switch Lua backends.

## When To Skip
- CI/CD setup.
- Rust code changes.

## Domain Knowledge
- Local build and test loops are wrapped by tools/dev/parallel_cargo.py and workspace tasks.
- build/ holds user-facing outputs; release and dist flows should not assume target/ as the final artifact location.
- Cargo profiles in Cargo.toml and rust-toolchain.toml are the first source of truth for build behavior.
- dev is for fast iteration, release is for runtime checks, and dist plus tools/dist/ is the shipping path.
- LuaJIT is the shipping backend; lua54 exists only as fallback and should not shape release defaults.
- Tune build size or speed only after confirming which profile and script the repo actually uses.
- The workspace already exposes build, run, test, docs, and quality tasks; use them as the first source of truth before adding new local build flows.
- tools/dist/install.ps1 and dist.ps1 define the Windows-facing packaging path and should stay aligned with profile.dist and build output layout.
- Build-system owns local profiles, binaries, and packaging scripts; CI wiring belongs elsewhere.
## Companion File Index
- None.

## References
- Cargo.toml
- rust-toolchain.toml
- build/
- tools/dev/parallel_cargo.py
- tools/dist/
