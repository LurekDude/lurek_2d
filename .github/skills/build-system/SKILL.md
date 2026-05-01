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
- Three profiles: `dev` (fast compile, debug assertions, no optimization), `release` (opt-level 3, LTO=thin), `dist` (opt-level 3, LTO=fat, UPX compression, strip symbols). Never benchmark in `dev`. Never ship from `release` — use `dist`.
- Commands: `python tools/dev/parallel_cargo.py build rust` (dev), `cargo build --release`, `cargo build --profile dist`. For packaging: `powershell -File tools/dist/dist.ps1`. For install: `powershell -File tools/dist/install.ps1`.
- Output locations: `dev` → `target/debug/lurek2d.exe`, `release` → `target/release/lurek2d.exe`, final artifacts → `build/debug/` and `build/release/` (copied by build scripts). Packaging scripts read from `build/`, not `target/`.
- LuaJIT is the default Cargo feature for all local and dist builds. Enabling `lua54` is done via `cargo build --no-default-features --features lua54`. CI uses lua54 on platforms where LuaJIT is unavailable. Never swap the default without explicit authorization.
- `build.rs` handles asset embedding and generated code. If `build.rs` is changed, run `cargo clean` before the next build — incremental build cache does not always detect `build.rs` changes.
- `rust-toolchain.toml` pins the Rust version. Never override it with `+nightly` or `+stable` locally to "fix" a build error — the toolchain file is part of the contract and overrides hide real problems.
- UPX compression in `dist.ps1` reduces the binary from ~20 MB to ~5 MB. UPX must be on PATH. The script checks for it and aborts if missing — install via `scoop install upx` on Windows.
- `tools/dev/parallel_cargo.py` wraps cargo for the workspace. Use it for clippy, fmt, test, and doc commands — it handles Cargo target threading and output formatting. Do not use raw `cargo` for repo-level commands.
- The workspace `.vscode/tasks.json` exposes all standard build flows as tasks. When documenting a build step for a contributor, refer to the task label, not a raw command — task labels stay stable as command details change.
- After modifying `Cargo.toml` (dependency bump, feature change, profile change), run the full Quality Gate task to confirm no test regressions from the change.
## Companion File Index
- None.

## References
- Cargo.toml
- rust-toolchain.toml
- build/
- tools/dev/parallel_cargo.py
- tools/dist/
