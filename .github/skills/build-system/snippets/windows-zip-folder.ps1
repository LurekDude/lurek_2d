# Full release build + package → dist/lurek2d-windows-x86_64/
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1

# Skip cargo build (repackage already-built binary)
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1 -SkipBuild
