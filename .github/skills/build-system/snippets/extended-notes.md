> See [templates/feature-flags-lua-backend.toml](templates/feature-flags-lua-backend.toml) for the example.

**Rule**: Ship with `lua-jit`. Use `lua54` only in CI environments where LuaJIT is unavailable or when explicitly testing Lua 5.4 compatibility.

---

### Development Loop Commands
> See [snippets/development-loop-commands.ps1](snippets/development-loop-commands.ps1) for the example.

**Rule**: Use `cargo check` during implementation. Never run `cargo build` just to validate types — it compiles everything including link step.

---

### Distribution Packaging
### Windows — ZIP + Folder

> See [snippets/windows-zip-folder.ps1](snippets/windows-zip-folder.ps1) for the example.

Output: `dist/lurek2d-windows-x86_64/lurek2d.exe` + demos + `dist/lurek2d-windows-x86_64.zip`

### Linux / macOS — TAR.GZ

> See [snippets/linux-macos-tar-gz.sh](snippets/linux-macos-tar-gz.sh) for the example.

Output: `dist/lurek2d-<os>-<arch>/` + `.tar.gz`

### Windows Installer (NSIS)

> See [snippets/windows-installer-nsis.ps1](snippets/windows-installer-nsis.ps1) for the example.

Output: `dist/lurek2d-<version>-setup.exe`

---

### Local Install / Uninstall
> See [snippets/local-install-uninstall.ps1](snippets/local-install-uninstall.ps1) for the example.

> See [snippets/local-install-uninstall-2.sh](snippets/local-install-uninstall-2.sh) for the example.

After install: `luna content/demos/hello_world` works from any directory.

---

### VS Code Task Shortcuts
These tasks are in `.vscode/tasks.json` (Ctrl+Shift+B or Terminal → Run Task):

| Task | Equivalent command |
|------|--------------------|
| `Build: Debug` | `cargo build` |
| `Build: Release` | `cargo build --release` |
| `Build: Check (fast)` | `cargo check` |
| `Run Debug: Pick Example` | `cargo run -- content/demos/<pick>` |
| `Run Release: Pick Example` | `cargo run --release -- content/demos/<pick>` |
| `Dist: Package Windows` | `tools/dist/dist.ps1` |
| `Dist: Package Windows (skip build)` | `tools/dist/dist.ps1 -SkipBuild` |
| `Dist: NSIS Installer (Windows)` | `makensis tools/dist/installer.nsi` |

---

### Common Build Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| `error: could not find lua.h` | Missing vendored flag | Ensure feature includes `mlua/vendored` |
| `LINK : fatal error LNK1181` | Incremental build artifact corruption | `Remove-Item build/debug -Recurse; cargo build` |
| Binary at `target/` instead of `build/` | `.cargo/config.toml` not present | Verify `.cargo/config.toml` has `target-dir = "build"` |
| Huge binary in dev (>200MB) | `debug = true` with full DWARF | Use `debug = "line-tables-only"` in `[profile.dev]` |
| `wgpu` validation spew on first run | Missing env filter | Set `RUST_LOG=lurek2d=info` to silence wgpu noise |

---

### Cargo.toml Conventions
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

- `[[bin]] name = "lurek2d"` — binary name must stay `lurek2d`
- `[lib] name = "lurek2d"` — library name must stay `lurek2d` (integration tests import it)
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
