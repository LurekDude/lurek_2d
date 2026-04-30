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
- Local build and test loops are wrapped by tools/dev/parallel_cargo.py and workspace tasks, so those entry points are the first source of truth for how developers are expected to build, run, and validate changes.
- build/ holds the user-facing outputs in this repo; release and dist flows should not assume target/ is the artifact users or packaging scripts consume directly.
- Cargo profiles in Cargo.toml and the toolchain in rust-toolchain.toml are the baseline truth for build behavior, optimization level, and compatibility expectations.
- dev is for fast iteration, release is for realistic runtime checks, and dist plus tools/dist/ is the shipping path; mixing their responsibilities usually produces misleading timing or packaging results.
- LuaJIT is the shipping backend and lua54 is a fallback only, so local defaults, release commands, and packaging assumptions should continue to treat LuaJIT as the primary runtime.
- Tune build size or speed only after confirming which profile, script, and output path the repo actually uses; otherwise you optimize a path that users never run.
- The workspace already exposes build, run, test, docs, and quality tasks, including no-rebuild launch flows; reuse them before adding new wrapper scripts or alternate local commands.
- tools/dist/install.ps1 and dist.ps1 define the Windows-facing install and packaging path and should stay aligned with profile.dist, UPX usage, and the build output layout.
- Build changes often touch more than Cargo profiles: packaging scripts, install flows, docs, and task descriptions may all need sync when a build surface changes.
- Prefer explicit feature and profile choices over hidden environment assumptions so local builds remain reproducible.
## Companion File Index
- None.

## References
- Cargo.toml
- rust-toolchain.toml
- build/
- tools/dev/parallel_cargo.py
- tools/dist/
