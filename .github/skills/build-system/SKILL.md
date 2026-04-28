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
- Lurek2D writes build output to build/, not target/.
- Main profiles are dev, release, and dist.
- Use dev for fast local work.
- Use release for fast runtime checks.
- Use dist for shipping packages.
- lua-jit is the default and shipping backend.
- lua54 is fallback only. Do not ship it.
- Fast loop is cargo check, then cargo build, then cargo run.
- Packaging scripts live in tools/dist/.
- If binaries are missing from target/, look in build/.

## Companion File Index
- None.

## References
- .cargo/config.toml
- Cargo.toml
- tools/dist/
