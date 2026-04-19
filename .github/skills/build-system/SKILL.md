---
name: build-system
description: "Load this skill when working with the Lurek2D build system: Cargo profiles, debug vs release builds, binary size and speed optimisation, the build/ output directory override, feature flags (lua-jit / lua54), or packaging for distribution via installer scripts. Use for: cargo build, cargo check, cargo run, profile tuning, dist.ps1/dist.sh, NSIS installer. Skip it for CI/CD pipeline setup (use ci-cd-pipeline skill) or writing Rust code."
---
# build-system

## Mission

# Build System — Lurek2D

## When To Load

- Building or running the engine locally for the first time
- Choosing between `cargo build`, `cargo check`, `cargo build --release`, or `cargo build --profile dist`
- Tuning binary size or runtime speed via Cargo profile settings
- Packaging a distribution release with `tools/dist/dist.ps1` or `tools/dist/dist.sh`
- Installing the engine binary locally with `tools/dist/install.ps1` or `tools/dist/install.sh`
- Building an NSIS Windows installer with `tools/dist/installer.nsi`
- Switching between the LuaJIT and Lua 5.4 scripting backends

## When To Skip

- Skip it for CI/CD pipeline setup (use ci-cd-pipeline skill) or writing Rust code.

## Domain Knowledge

### Owns
- Cargo profile definitions (`dev`, `release`, `dist`) and their trade-offs
- `build/` output directory override (`.cargo/config.toml`)
- Feature flags: `lua-jit` (default) vs `lua54`
- `cargo check` vs `cargo build` during development loop
- Distribution packaging scripts and installer tooling
- VS Code task shortcuts for common build operations

---

### Output Directory Override
Lurek2D redirects Cargo output from the default `target/` to **`build/`** via `.cargo/config.toml`:

> See [templates/output-directory-override.toml](templates/output-directory-override.toml) for the example.

| Binary | Path |
|--------|------|
| Debug | `build/debug/lurek2d.exe` (Windows) / `build/debug/lurek2d` (Unix) |
| Release | `build/release/lurek2d.exe` / `build/release/lurek2d` |
| Dist | `build/dist/lurek2d.exe` / `build/dist/lurek2d` |

**Never reference `target/`** — the binaries are not there.

---

### Cargo Profiles
Three profiles are defined in `Cargo.toml`. Use the right one for the task:

| Profile | Command | Use When |
|---------|---------|----------|
| `dev` | `cargo build` | Active development — fast incremental rebuild, debuggable |
| `release` | `cargo build --release` | Performance testing, running demos with full speed |
| `dist` | `cargo build --profile dist` | Packaging a release — smaller binary, fat LTO |

### `[profile.dev]` — what it does

> See [templates/profile-dev-what-it-does.toml](templates/profile-dev-what-it-does.toml) for the example.

- `debug = true` locally when you need to inspect variables in a debugger (heavier binary)
- Dependencies at `opt-level = 3` = wgpu/rapier/rodio run fast even in dev builds

### `[profile.release]` — what it does

> See [templates/profile-release-what-it-does.toml](templates/profile-release-what-it-does.toml) for the example.

- Produces a small, fast binary suitable for end-user runs
- Do NOT use `release` to debug panics — symbols are stripped

### `[profile.dist]` — what it does

> See [templates/profile-dist-what-it-does.toml](templates/profile-dist-what-it-does.toml) for the example.

- Use for installer/ZIP packages where download size matters
- Build time is longer than release (fat LTO link) — acceptable for one-shot packaging

---

### Feature Flags — Lua Backend
Lurek2D ships two Lua runtime backends. Select at build time with a Cargo feature flag.

| Feature | Command | Backend | Platform |
|---------|---------|---------|----------|
| `lua-jit` *(default)* | `cargo build` | LuaJIT (vendored) | Windows/Linux/macOS x86_64 + ARM |

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [templates/output-directory-override.toml](templates/output-directory-override.toml) — Output Directory Override
- [templates/profile-dev-what-it-does.toml](templates/profile-dev-what-it-does.toml) — `[profile.dev]` — what it does
- [templates/profile-release-what-it-does.toml](templates/profile-release-what-it-does.toml) — `[profile.release]` — what it does
- [templates/profile-dist-what-it-does.toml](templates/profile-dist-what-it-does.toml) — `[profile.dist]` — what it does
- [templates/feature-flags-lua-backend.toml](templates/feature-flags-lua-backend.toml) — Feature Flags — Lua Backend
- [snippets/development-loop-commands.ps1](snippets/development-loop-commands.ps1) — Development Loop Commands
- [snippets/windows-zip-folder.ps1](snippets/windows-zip-folder.ps1) — Windows — ZIP + Folder
- [snippets/linux-macos-tar-gz.sh](snippets/linux-macos-tar-gz.sh) — Linux / macOS — TAR.GZ
- [snippets/windows-installer-nsis.ps1](snippets/windows-installer-nsis.ps1) — Windows Installer (NSIS)
- [snippets/local-install-uninstall.ps1](snippets/local-install-uninstall.ps1) — Local Install / Uninstall
- [snippets/local-install-uninstall-2.sh](snippets/local-install-uninstall-2.sh) — Local Install / Uninstall
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
