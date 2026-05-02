# tools/dist — Build, Package & Install

Scripts and configuration files for building release binaries, packaging
distribution archives, and installing the engine locally.

## Scripts

| Script | Platform | Purpose |
|---|---|---|
| `release.ps1` | Windows | **Full release pipeline**: debug + release + dist builds, portable ZIP, NSIS installer, VS Code extension → `dist/github-release/` |
| `dist.ps1` | Windows | Dist build → `dist/lurek2d-windows-x86_64/` + `.zip` |
| `dist.sh` | Linux / macOS | Release build → `dist/lurek2d-<os>-<arch>/` + `.tar.gz` |
| `install.ps1` | Windows | Install `lurek.exe` to user PATH |
| `install.sh` | Linux / macOS | Install `lurek2d` to `/usr/local/bin` |
| `installer.nsi` | Windows | NSIS installer script → `dist/lurek2d-*-setup.exe` |
| `pack.ps1` | Windows | Pack a game folder into a `.lurek` archive (PowerShell) |
| `pack.py` | Cross-platform | Pack a game folder into a `.lurek` archive (Python) |

## Quick start — full release

```powershell
# Build everything and assemble GitHub release artifacts
powershell -ExecutionPolicy Bypass -File tools/dist/release.ps1

# Artifacts land in dist/github-release/:
#   lurek2d-windows-x86_64.zip      — portable engine (drag-and-drop)
#   lurek2d-1.0.0-setup.exe         — Windows installer (NSIS)
#   lurek2d-toolkit-1.0.0.vsix      — VS Code extension
#   checksums-sha256.txt            — SHA256 hashes for all files
```

## Step-by-step (individual scripts)

```powershell
# 1. Portable engine ZIP (includes dist profile build + UPX)
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1

# 2. Windows installer (requires NSIS on PATH: scoop install nsis)
makensis tools/dist/installer.nsi

# 3. VS Code extension
cd extensions/vscode ; npm install ; npm run package

# Skip Rust rebuild when only repacking
powershell -ExecutionPolicy Bypass -File tools/dist/release.ps1 -SkipRustBuilds
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1 -SkipBuild

# Install locally (Windows)
powershell -ExecutionPolicy Bypass -File tools/dist/install.ps1

# Linux / macOS release package
bash tools/dist/dist.sh

# Pack a game as .lurek archive
python tools/dist/pack.py content/games/showcase/hello_world/ hello_world.lurek
```

## GitHub Actions (automated release)

Push a tag matching `v*.*.*` to trigger the release workflow:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

The workflow (`.github/workflows/release.yml`) runs the quality gate, builds all
artifacts on Windows runners, and creates a GitHub Release with all three
artifacts and a SHA256 checksum file attached.

## Prerequisites

| Tool | Install | Required for |
|---|---|---|
| Rust (pinned) | `rust-toolchain.toml` | Engine binary |
| UPX 3.x+ | `scoop install upx` | Binary compression in `dist.ps1` |
| NSIS 3.x | `scoop install nsis` | `installer.nsi` |
| Node.js 18+ / npm | `scoop install nodejs` | VS Code extension |

```
