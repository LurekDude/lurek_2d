# Luna2D Changelog

All notable changes to Luna2D are recorded here.

## Versioning scheme

```
MAJOR.MINOR.PATCH
```

| Segment | Increment when… |
|---|---|
| **MAJOR** | Breaking API changes — Lua scripts or engine configuration must be ported |
| **MINOR** | New backwards-compatible features — new `luna.*` APIs, new modules, new default configs |
| **PATCH** | Bug fixes, internal refactors, documentation and tooling changes that do not affect the public API |

Always update this file **in the same commit** as the change. Use the commit type as the section label.

---

## [0.5.0] — 2026-04-08

### Changed
- Version bumped to 0.5.0 — first tracked release.
- **Distribution build** switched from fat-LTO `--profile dist` to `--release` (thin LTO); balanced binary size vs. link time.
- **Windows installer** (`tools/dist/installer.nsi`): now bundles `examples/`, `library/`, `demos/`, and the full `docs/API/` folder. Registers `.lua` file association so double-clicking any Lua script launches it in Luna2D.
- **dist.ps1**: updated to use `cargo build --release` and `build/release/luna2d.exe`; adds `demos/` to the portable package.
- **Icons**: Windows binary now embeds `assets/favicon.ico` (user-supplied). Removed auto-generated icon/splash Python scripts (`gen_icon.py`, `gen_splash.py`, `gen_branding.py`, `gen_svg_assets.py`) — all artwork is now maintained manually in `assets/`.
- **Build.rs**: icon embed path updated to `assets/favicon.ico`.

### Added
- `docs/CHANGELOG.md` — this file; version history starting at 0.5.0.

---

<!-- Template for future entries:

## [X.Y.Z] — YYYY-MM-DD

### Added
- 

### Changed
- 

### Fixed
- 

### Removed
- 

-->
