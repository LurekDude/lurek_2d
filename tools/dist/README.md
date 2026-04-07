# tools/dist — Build, Package & Install

Scripts and configuration files for building release binaries, packaging
distribution archives, and installing the engine locally.

## Scripts

| Script | Platform | Purpose |
|---|---|---|
| `dist.ps1` | Windows | Release build → `dist/luna2d-windows-x86_64/` + `.zip` |
| `dist.sh` | Linux / macOS | Release build → `dist/luna2d-<os>-<arch>/` + `.tar.gz` |
| `install.ps1` | Windows | Install `luna.exe` to user PATH |
| `install.sh` | Linux / macOS | Install `luna2d` to `/usr/local/bin` |
| `installer.nsi` | Windows | NSIS installer script → `dist/luna2d-*-setup.exe` |
| `pack.ps1` | Windows | Pack a game folder into a `.lunar` archive (PowerShell) |
| `pack.py` | Cross-platform | Pack a game folder into a `.lunar` archive (Python) |

## Common usage

```powershell
# Windows release package
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1

# Windows release package (skip rebuild)
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1 -SkipBuild

# Linux / macOS release package
bash tools/dist/dist.sh

# Windows installer (requires NSIS on PATH)
makensis tools/dist/installer.nsi

# Install locally (Windows)
powershell -ExecutionPolicy Bypass -File tools/dist/install.ps1

# Install locally (Linux / macOS)
bash tools/dist/install.sh

# Pack a game as .lunar archive
python tools/dist/pack.py demos/hello_world/ hello_world.lunar
```
