---
description: "Load when changing Cargo profiles, debug or release builds, feature flags, build output, or packaging. Skip for CI/CD setup or Rust code changes."
alwaysApply: false
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
- Local build and test loops are wrapped by tools/dev/parallel_cargo.py and workspace tasks; those entry points are the first source of truth.
- build/ holds the user-facing outputs; release and dist flows should not assume target/ is what users consume.
- Cargo profiles in Cargo.toml and rust-toolchain.toml are the baseline truth for build behavior.
- dev is for fast iteration, release is for realistic runtime checks, and dist plus tools/dist/ is the shipping path.
- LuaJIT is the shipping backend and lua54 is a fallback only.
- Tune build size or speed only after confirming which profile, script, and output path the repo uses.
- tools/dist/install.ps1 and dist.ps1 define the Windows-facing install and packaging path.
- Build changes often touch more than Cargo profiles: packaging scripts, install flows, docs, and task descriptions may all need sync.

## References
- Cargo.toml
- rust-toolchain.toml
- build/
- tools/dev/parallel_cargo.py
- tools/dist/
