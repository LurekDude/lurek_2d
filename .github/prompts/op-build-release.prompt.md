---
description: "Build a release binary for Luna2D for a target platform. Use when creating a distributable build. Produces a stripped release binary in target/release/."
---

# Op: Build Release

**Purpose**: Build a release-optimized Luna2D binary for distribution.
**Use When**: Creating a release binary for a specific platform, or verifying the release build is clean.
**Do Not Use When**: During normal development — use `cargo build` (debug) for iteration.
**Scope**: `Cargo.toml`, `rust-toolchain.toml`, `target/release/`.

## Inputs

- `TARGET_TRIPLE` — Rust target triple (e.g., `x86_64-pc-windows-msvc`, `x86_64-unknown-linux-gnu`). Leave blank for native host.
- `VERSION` — version string to verify (optional; will check `Cargo.toml`)

## Steps

1. Verify `Cargo.toml` version matches `VERSION` (if provided)
2. Run all quality gates first:
   ```powershell
   cargo clippy -- -D warnings
   cargo fmt --check
   cargo test
   ```
3. Build release:
   ```powershell
   # Native platform:
   cargo build --release

   # Cross-compile (requires target installed):
   rustup target add <TARGET_TRIPLE>
   cargo build --release --target <TARGET_TRIPLE>
   ```
4. Verify output:
   - Native: `target/release/luna2d.exe` (Windows) or `target/release/luna2d` (Linux)
   - Cross: `target/<TARGET_TRIPLE>/release/luna2d[.exe]`
5. Smoke test the binary:
   ```powershell
   ./target/release/luna2d examples/hello_world
   ```
6. Check binary size:
   ```powershell
   Get-Item target/release/luna2d.exe | Select-Object -Property Length
   ```
   - Typical release binary: 5–15 MB (software rendering stack)
   - Warning if > 50 MB — likely debug symbols leaked into release build

## Outputs

- Release binary at `target/release/luna2d[.exe]`
- Smoke test result (window opened, no panic)
- Binary size reported

## Acceptance

- [ ] `cargo build --release` completes with 0 errors
- [ ] `cargo clippy -- -D warnings` clean before build
- [ ] `cargo test` passes before build
- [ ] Release binary runs `examples/hello_world` without panic
- [ ] Binary size is reasonable (< 50 MB)

## References

**Required Skills**: `rust-coding`, `cross-platform`
**Suggested Agents**: `Developer`
**Related Prompts**: `workflow-release-check.prompt.md`, `run-quality-gates.prompt.md`
**Commands**:
```powershell
cargo build --release
cargo test
./target/release/luna2d examples/hello_world
```
