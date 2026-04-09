# tools/dist — Build, Package & Install

Scripts and configuration files for building release binaries, packaging
distribution archives, and installing the engine locally.

## Scripts

| Script | Platform | Purpose |
|---|---|---|
| `dist.ps1` | Windows | Release build → `dist/lurek2d-windows-x86_64/` + `.zip` |
| `dist.sh` | Linux / macOS | Release build → `dist/lurek2d-<os>-<arch>/` + `.tar.gz` |
| `install.ps1` | Windows | Install `lurek.exe` to user PATH |
| `install.sh` | Linux / macOS | Install `lurek2d` to `/usr/local/bin` |
| `installer.nsi` | Windows | NSIS installer script → `dist/lurek2d-*-setup.exe` |
| `pack.ps1` | Windows | Pack a game folder into a `.lurek` archive (PowerShell) |
| `pack.py` | Cross-platform | Pack a game folder into a `.lurek` archive (Python) |

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

# Pack a game as .lurek archive
python tools/dist/pack.py content/demos/hello_world/ hello_world.lurek
```
