# tools/pack.ps1
# =============================================================================
# Pack a Luna2D game directory into a .lunar archive.
#
# A .lunar file is a ZIP archive (low compression) containing all game assets
# with main.lua at the root. Double-clicking it on a machine that has Luna2D
# installed will launch the game via the registered file association.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\pack.ps1 <game_dir> [output]
#
#   <game_dir>  Path to the game folder containing main.lua (required).
#   [output]    Output path for the .lunar file.
#               Defaults to <game_dir_name>.lunar in the current directory.
#
# Examples:
#   tools\pack.ps1 examples\hello_world
#     → hello_world.lunar
#
#   tools\pack.ps1 examples\physics_demo dist\physics_demo.lunar
#     → dist\physics_demo.lunar
# =============================================================================

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$GameDir,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$Output = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Resolve game directory ────────────────────────────────────────────────────
$GameDir = Resolve-Path $GameDir -ErrorAction Stop | Select-Object -ExpandProperty Path

if (-not (Test-Path "$GameDir\main.lua")) {
    Write-Error "ERROR: '$GameDir' does not contain main.lua"
    exit 1
}

# ── Determine output path ─────────────────────────────────────────────────────
if ($Output -eq "") {
    $gameName = Split-Path $GameDir -Leaf
    $Output   = Join-Path (Get-Location) "$gameName.lunar"
}

# Ensure the output directory exists
$outDir = Split-Path $Output -Parent
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# Remove existing archive so we get a clean pack
if (Test-Path $Output) {
    Remove-Item $Output -Force
}

# ── Pack with .NET ZipFile ────────────────────────────────────────────────────
Add-Type -AssemblyName System.IO.Compression.FileSystem

# CompressionLevel: Optimal | Fastest | NoCompression
# Use Fastest (low compression) — games are already-compressed assets (PNG, OGG)
# so smaller compression level means faster packing with almost no size difference.
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $GameDir,
    $Output,
    [System.IO.Compression.CompressionLevel]::Fastest,
    $false   # $false = do NOT include the top-level directory name in entry paths
)

$size = (Get-Item $Output).Length
$sizeKB = [math]::Round($size / 1KB, 1)

Write-Host "Packed: $Output ($sizeKB KB)"
Write-Host "Run with: luna `"$Output`""
