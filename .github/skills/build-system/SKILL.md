---
name: build-system
description: "Load this skill when working with the Luna2D build system: Cargo profiles, debug vs release builds, binary size and speed optimisation, the build/ output directory override, feature flags (lua-jit / lua54), or packaging for distribution via installer scripts. Use for: cargo build, cargo check, cargo run, profile tuning, dist.ps1/dist.sh, NSIS installer. Skip it for CI/CD pipeline setup (use ci-cd-pipeline skill) or writing Rust code."
---

# Build System — Luna2D

## Load When

- Building or running the engine locally for the first time
- Choosing between `cargo build`, `cargo check`, `cargo build --release`, or `cargo build --profile dist`
- Tuning binary size or runtime speed via Cargo profile settings
- Packaging a distribution release with `tools/dist/dist.ps1` or `tools/dist/dist.sh`
- Installing the engine binary locally with `tools/dist/install.ps1` or `tools/dist/install.sh`
- Building an NSIS Windows installer with `tools/dist/installer.nsi`
- Switching between the LuaJIT and Lua 5.4 scripting backends

## Owns

- Cargo profile definitions (`dev`, `release`, `dist`) and their trade-offs
- `build/` output directory override (`.cargo/config.toml`)
- Feature flags: `lua-jit` (default) vs `lua54`
- `cargo check` vs `cargo build` during development loop
- Distribution packaging scripts and installer tooling
- VS Code task shortcuts for common build operations

---

## Output Directory Override

Luna2D redirects Cargo output from the default `target/` to **`build/`** via `.cargo/config.toml`:

```toml
# .cargo/config.toml
[build]
target-dir = "build"
```

| Binary | Path |
|--------|------|
| Debug | `build/debug/luna2d.exe` (Windows) / `build/debug/luna2d` (Unix) |
| Release | `build/release/luna2d.exe` / `build/release/luna2d` |
| Dist | `build/dist/luna2d.exe` / `build/dist/luna2d` |

**Never reference `target/`** — the binaries are not there.

---

## Cargo Profiles

Three profiles are defined in `Cargo.toml`. Use the right one for the task:

| Profile | Command | Use When |
|---------|---------|----------|
| `dev` | `cargo build` | Active development — fast incremental rebuild, debuggable |
| `release` | `cargo build --release` | Performance testing, running demos with full speed |
| `dist` | `cargo build --profile dist` | Packaging a release — smaller binary, fat LTO |

### `[profile.dev]` — what it does

```toml
opt-level = 1          # fast enough for smooth iteration; game code is debuggable
incremental = true     # incremental compilation — much faster rebuilds
debug = "line-tables-only"  # file+line info for backtraces; no full DWARF (saves ~20MB)

[profile.dev.package."*"]
opt-level = 3          # all dependencies at full speed even in dev
```

- `debug = true` locally when you need to inspect variables in a debugger (heavier binary)
- Dependencies at `opt-level = 3` = wgpu/rapier/rodio run fast even in dev builds

### `[profile.release]` — what it does

```toml
opt-level = "z"          # size-first (avoids vectorisation, limits inlining)
lto = true               # thin LTO: cross-crate dead code elimination
codegen-units = 1        # single codegen unit: best dead-code elimination
strip = "symbols"        # strip debug symbols from binary
panic = "abort"          # removes unwinder (~500KB saving)
overflow-checks = false  # speed: debug build already catches overflows
```

- Produces a small, fast binary suitable for end-user runs
- Do NOT use `release` to debug panics — symbols are stripped

### `[profile.dist]` — what it does

```toml
inherits = "release"
opt-level = "z"   # size-optimised (same as release)
lto = true        # fat LTO: full cross-crate analysis (better than thin for binary size)
```

- Use for installer/ZIP packages where download size matters
- Build time is longer than release (fat LTO link) — acceptable for one-shot packaging

---

## Feature Flags — Lua Backend

Luna2D ships two Lua runtime backends. Select at build time with a Cargo feature flag.

| Feature | Command | Backend | Platform |
|---------|---------|---------|----------|
| `lua-jit` *(default)* | `cargo build` | LuaJIT (vendored) | Windows/Linux/macOS x86_64 + ARM |
| `lua54` | `cargo build --no-default-features --features lua54` | Lua 5.4 (vendored) | Fallback / CI |

```toml
# Cargo.toml features section
default = ["lua-jit"]
lua-jit = ["mlua/luajit", "mlua/vendored"]   # primary; JIT compilation
lua54   = ["mlua/lua54",  "mlua/vendored"]   # fallback; pure interpreter
```

**Rule**: Ship with `lua-jit`. Use `lua54` only in CI environments where LuaJIT is unavailable or when explicitly testing Lua 5.4 compatibility.

---

## Development Loop Commands

```powershell
# FASTEST: type-check only — no compilation, ~2-5s incremental
cargo check

# Build debug binary (incremental, ~5-15s after first build)
cargo build

# Run a demo directly (builds if needed)
cargo run -- demos/hello_world

# Build release binary (full optimisation, ~60-120s first build)
cargo build --release

# Run release binary
cargo run --release -- demos/hello_world

# Build distribution binary (fat LTO, ~90-180s)
cargo build --profile dist
```

**Rule**: Use `cargo check` during implementation. Never run `cargo build` just to validate types — it compiles everything including link step.

---

## Distribution Packaging

### Windows — ZIP + Folder

```powershell
# Full release build + package → dist/luna2d-windows-x86_64/
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1

# Skip cargo build (repackage already-built binary)
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1 -SkipBuild
```

Output: `dist/luna2d-windows-x86_64/luna2d.exe` + demos + `dist/luna2d-windows-x86_64.zip`

### Linux / macOS — TAR.GZ

```bash
bash tools/dist/dist.sh
```

Output: `dist/luna2d-<os>-<arch>/` + `.tar.gz`

### Windows Installer (NSIS)

```powershell
# Requires NSIS 3.x on PATH
makensis tools/dist/installer.nsi
```

Output: `dist/luna2d-<version>-setup.exe`

---

## Local Install / Uninstall

```powershell
# Install luna2d.exe to PATH (Windows)
powershell -ExecutionPolicy Bypass -File tools/dist/install.ps1

# Uninstall
powershell -ExecutionPolicy Bypass -File tools/dist/install.ps1 --uninstall
```

```bash
# Install (Linux/macOS)
bash tools/dist/install.sh
```

After install: `luna demos/hello_world` works from any directory.

---

## VS Code Task Shortcuts

These tasks are in `.vscode/tasks.json` (Ctrl+Shift+B or Terminal → Run Task):

| Task | Equivalent command |
|------|--------------------|
| `Build: Debug` | `cargo build` |
| `Build: Release` | `cargo build --release` |
| `Build: Check (fast)` | `cargo check` |
| `Run Debug: Pick Example` | `cargo run -- demos/<pick>` |
| `Run Release: Pick Example` | `cargo run --release -- demos/<pick>` |
| `Dist: Package Windows` | `tools/dist/dist.ps1` |
| `Dist: Package Windows (skip build)` | `tools/dist/dist.ps1 -SkipBuild` |
| `Dist: NSIS Installer (Windows)` | `makensis tools/dist/installer.nsi` |

---

## Common Build Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `error: could not find lua.h` | Missing vendored flag | Ensure feature includes `mlua/vendored` |
| `LINK : fatal error LNK1181` | Incremental build artifact corruption | `Remove-Item build/debug -Recurse; cargo build` |
| Binary at `target/` instead of `build/` | `.cargo/config.toml` not present | Verify `.cargo/config.toml` has `target-dir = "build"` |
| Huge binary in dev (>200MB) | `debug = true` with full DWARF | Use `debug = "line-tables-only"` in `[profile.dev]` |
| `wgpu` validation spew on first run | Missing env filter | Set `RUST_LOG=luna2d=info` to silence wgpu noise |

---

## Cargo.toml Conventions

### Canonical Dependency Set

| Crate | Version | Purpose | Required features |
|-------|---------|---------|-------------------|
| `winit` | `0.30` | Windowing and input | none |
| `wgpu` | `22` | GPU-accelerated 2D rendering | `bytemuck`, `pollster` |
| `mlua` | `0.9` | Lua scripting (vendored) | `lua54`, `vendored` |
| `image` | `0.24` | PNG/JPEG texture loading | none |
| `rodio` | `0.17` | Audio playback | none |
| `log` | `0.4` | Logging facade | none |
| `env_logger` | `0.10` | Log configuration | none |

### Cargo.toml Invariants

- `[[bin]] name = "luna2d"` — binary name must stay `luna2d`
- `[lib] name = "luna2d"` — library name must stay `luna2d` (integration tests import it)
- `edition = "2021"` — do not downgrade to 2018

### Semver Pinning

Use exact minor versions (`"0.30"`, `"0.9"`) — not `"*"` or `">= 0.9"` wildcards. Only bump versions deliberately.

`mlua` must **always** include `vendored` in its features list — never depend on a system Lua installation.

Run `cargo audit` before adding any new crate.

### Avoid

- Adding `serde` unless a feature genuinely requires serialization (e.g., save files)
- Adding `tokio` or `async-std` — the engine is synchronous by design
- Duplicate decoders: if `rodio` can handle a format, do not add another audio decoder crate
- `[patch.crates-io]` entries without a documented reason in a comment
- Dev-dependency accidentally leaking into the library build
