#Requires -Version 5.1
<#
.SYNOPSIS
    Build and package Luna2D for Windows distribution.

.DESCRIPTION
    Runs a full release build, then assembles a portable distribution folder and
    a ZIP archive ready to ship alongside game projects.

    Output layout:
        dist/
          luna2d-windows-x86_64/
            luna2d.exe           ← engine binary
            assets/              ← engine assets (splash, icon)
            examples/            ← bundled example games
            LICENSE
            README.md
            HOW-TO-RUN.txt
          luna2d-windows-x86_64.zip   ← ready to upload / distribute

.PARAMETER OutDir
    Root output folder.  Default: dist/ inside the workspace.

.PARAMETER SkipBuild
    Skip cargo build (use an already-compiled binary).  Useful for CI.

.EXAMPLE
    .\tools\dist.ps1
    .\tools\dist.ps1 -SkipBuild
    .\tools\dist.ps1 -OutDir "C:\releases"
#>

param(
    [string]$OutDir   = "",
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WorkspaceRoot = Split-Path $PSScriptRoot -Parent
if (-not $OutDir) { $OutDir = Join-Path $WorkspaceRoot 'dist' }

$Version       = "0.4.0"
$ArchName      = "luna2d-windows-x86_64"
$PackageDir    = Join-Path $OutDir $ArchName
$ZipPath       = Join-Path $OutDir "$ArchName.zip"
$BinarySource  = Join-Path $WorkspaceRoot 'build\release\luna2d.exe'

# ── Helpers ───────────────────────────────────────────────────────────────────
function Write-Step([string]$Msg) { Write-Host "[dist] $Msg" -ForegroundColor Cyan }
function Write-OK  ([string]$Msg) { Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Write-Fail([string]$Msg) { Write-Host "[FAIL] $Msg" -ForegroundColor Red; exit 1 }

# ── 0. Verify workspace ───────────────────────────────────────────────────────
if (-not (Test-Path (Join-Path $WorkspaceRoot 'Cargo.toml'))) {
    Write-Fail "Must be run from the luna2d workspace root."
}

# ── 1. (Optional) generate assets ────────────────────────────────────────────
Write-Step "Checking generated assets …"
$SplashPng = Join-Path $WorkspaceRoot 'assets\splash.png'
$IconIco   = Join-Path $WorkspaceRoot 'assets\icon.ico'

if (-not (Test-Path $SplashPng)) {
    Write-Step "splash.png missing — running gen_splash.py …"
    python (Join-Path $WorkspaceRoot 'tools\gen_splash.py')
}
if (-not (Test-Path $IconIco)) {
    Write-Step "icon.ico missing — running gen_icon.py …"
    python (Join-Path $WorkspaceRoot 'tools\gen_icon.py')
}

# ── 2. Release build ──────────────────────────────────────────────────────────
if (-not $SkipBuild) {
    Write-Step "Building Luna2D (release) — this may take a minute …"
    Push-Location $WorkspaceRoot
    try {
        cargo build --release 2>&1 | ForEach-Object { Write-Host "    $_" }
        if ($LASTEXITCODE -ne 0) { Write-Fail "cargo build --release failed." }
    } finally { Pop-Location }
    Write-OK "Build succeeded."
} else {
    Write-Step "Skipping build (--SkipBuild set)."
}

if (-not (Test-Path $BinarySource)) {
    Write-Fail "Binary not found at '$BinarySource'. Run without -SkipBuild."
}

# ── 3. Assemble package directory ────────────────────────────────────────────
Write-Step "Assembling distribution package at '$PackageDir' …"
if (Test-Path $PackageDir) { Remove-Item $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

# Copy binary
Copy-Item $BinarySource -Destination (Join-Path $PackageDir 'luna2d.exe') -Force
Write-OK "Copied luna2d.exe"

# Copy lunec.bat launcher (no-console shortcut)
$LunecBat = Join-Path $WorkspaceRoot 'lunec.bat'
if (Test-Path $LunecBat) {
    Copy-Item $LunecBat -Destination (Join-Path $PackageDir 'lunec.bat') -Force
    Write-OK "Copied lunec.bat"
}

# Copy engine assets (splash, icons)
$AssetsSource = Join-Path $WorkspaceRoot 'assets'
if (Test-Path $AssetsSource) {
    $AssetsDest = Join-Path $PackageDir 'assets'
    if (Test-Path $AssetsDest) { Remove-Item $AssetsDest -Recurse -Force }
    Copy-Item $AssetsSource -Destination $AssetsDest -Recurse -Force
    Write-OK "Copied assets/"
}

# Copy examples
$ExamplesSource = Join-Path $WorkspaceRoot 'examples'
if (Test-Path $ExamplesSource) {
    $ExamplesDest = Join-Path $PackageDir 'examples'
    if (Test-Path $ExamplesDest) { Remove-Item $ExamplesDest -Recurse -Force }
    Copy-Item $ExamplesSource -Destination $ExamplesDest -Recurse -Force
    Write-OK "Copied examples/"
}

# Copy docs
foreach ($f in @('README.md', 'LICENSE')) {
    $src = Join-Path $WorkspaceRoot $f
    if (Test-Path $src) {
        Copy-Item $src -Destination (Join-Path $PackageDir $f) -Force
    }
}

# Write how-to-run
$HowTo = @"
LUNA2D $Version — Windows Portable Distribution
=================================================

How to run a game
-----------------
  luna2d.exe  examples\hello_world     (with console window — for developers)
  lunec.bat   examples\hello_world     (no console window  — for end users)
  lunec.lnk                            (shortcut with Luna2D icon — drag-drop a game folder)

How to show the splash screen (no game)
----------------------------------------
  luna2d.exe
  lunec.bat

Bundled examples
----------------
  examples\hello_world   — shapes, text, FPS counter
  examples\physics_demo  — falling ball with AABB physics
  examples\sprites       — keyboard-controlled sprite

Writing your own game
---------------------
  1. Create a folder, e.g. my_game\
  2. Add a main.lua with luna.load() / luna.update(dt) / luna.draw()
  3. Run:  lunec.bat my_game   (or drag the folder onto lunec.lnk)

API reference:  see README.md or https://github.com/yourname/luna2d
"@
Set-Content -Path (Join-Path $PackageDir 'HOW-TO-RUN.txt') -Value $HowTo -Encoding UTF8
Write-OK "Written HOW-TO-RUN.txt"

# ── 3b. Create lunec.lnk shortcut with Luna2D icon ───────────────────────────
$IcoPath = Join-Path $PackageDir 'assets\icon.ico'
if (Test-Path $IcoPath) {
    Write-Step "Creating lunec.lnk shortcut with Luna2D icon …"
    $ws  = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $PackageDir 'lunec.lnk'))
    $lnk.TargetPath       = Join-Path $PackageDir 'lunec.bat'
    $lnk.WorkingDirectory = $PackageDir
    $lnk.IconLocation     = "$IcoPath,0"
    $lnk.Description      = "Luna2D — launch game without console window"
    $lnk.WindowStyle      = 1
    $lnk.Save()
    Write-OK "Created lunec.lnk (double-click to run a game, drag-and-drop supported)"
}

# ── 4. Create ZIP ─────────────────────────────────────────────────────────────
Write-Step "Creating ZIP archive at '$ZipPath' …"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

# Compress-Archive requires PowerShell 5+
Compress-Archive -Path $PackageDir -DestinationPath $ZipPath -CompressionLevel Optimal
$ZipSizeKB = [math]::Round((Get-Item $ZipPath).Length / 1024)
Write-OK "ZIP created ($ZipSizeKB KB) → $ZipPath"

# ── 5. Summary ────────────────────────────────────────────────────────────────
Write-Host ""
Write-OK "Distribution package ready:"
Write-Host "  Folder : $PackageDir" -ForegroundColor White
Write-Host "  ZIP    : $ZipPath"    -ForegroundColor White
Write-Host ""
Write-Host "  Distribute the ZIP or the folder contents to end users." -ForegroundColor Yellow
Write-Host "  For a full installer, run:  makensis tools\installer.nsi" -ForegroundColor Yellow
