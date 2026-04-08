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
            demos/            ← bundled example games
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

$WorkspaceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $OutDir) { $OutDir = Join-Path $WorkspaceRoot 'dist' }

$Version       = "0.5.0"
$ArchName      = "luna2d-windows-x86_64"
$PackageDir    = Join-Path $OutDir $ArchName
$ZipPath       = Join-Path $OutDir "$ArchName.zip"
# Release binary lives in build/release/
$BinarySource  = Join-Path $WorkspaceRoot 'build\release\luna2d.exe'

# -- Helpers -------------------------------------------------------------------
function Write-Step([string]$Msg) { Write-Host "[dist] $Msg" -ForegroundColor Cyan }
function Write-OK  ([string]$Msg) { Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Write-Fail([string]$Msg) { Write-Host "[FAIL] $Msg" -ForegroundColor Red; exit 1 }

# -- 0. Verify workspace -------------------------------------------------------
if (-not (Test-Path (Join-Path $WorkspaceRoot 'Cargo.toml'))) {
    Write-Fail "Must be run from the luna2d workspace root."
}

# -- 1. Verify branding assets ------------------------------------------------
Write-Step "Checking branding assets ..."
$SplashPng = Join-Path $WorkspaceRoot 'assets\splash.png'
$FaviconIco = Join-Path $WorkspaceRoot 'assets\favicon.ico'

if (-not (Test-Path $SplashPng)) {
    Write-Host "[warn] Missing assets\splash.png." -ForegroundColor Yellow
}
if (-not (Test-Path $FaviconIco)) {
    Write-Host "[warn] Missing assets\favicon.ico." -ForegroundColor Yellow
}

# -- 2. Release build ----------------------------------------------------------
if (-not $SkipBuild) {
    Write-Step "Building Luna2D (dist -- size-optimised) -- this may take several minutes ..."
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

# -- 3. Assemble package directory --------------------------------------------
Write-Step "Assembling distribution package at '$PackageDir' ..."
if (Test-Path $PackageDir) { Remove-Item $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

# Copy binary
$DestBinary = Join-Path $PackageDir 'luna2d.exe'
Copy-Item $BinarySource -Destination $DestBinary -Force
$SizeBefore = [math]::Round((Get-Item $DestBinary).Length / 1MB, 2)
Write-OK "Copied luna2d.exe ($SizeBefore MB)"

# -- Optional UPX compression --------------------------------------------------
# UPX packs the executable using LZMA; typical result: 40-55% of original size.
# Install: https://upx.github.io/  (place upx.exe anywhere on PATH)
# Caveats: adds ~100 ms startup decompression; some AV scanners flag UPX'd bins.
$upx = Get-Command upx -ErrorAction SilentlyContinue
if ($upx) {
    Write-Step "UPX found -- compressing luna2d.exe ..."
    & upx --best --lzma $DestBinary 2>&1 | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -eq 0) {
        $SizeAfter = [math]::Round((Get-Item $DestBinary).Length / 1MB, 2)
        Write-OK "UPX compressed: $SizeBefore MB → $SizeAfter MB"
    } else {
        Write-Host "[warn] UPX returned non-zero; binary unchanged." -ForegroundColor Yellow
    }
} else {
    Write-Host "[dist] UPX not found on PATH -- skipping compression (add upx to PATH to enable)." -ForegroundColor DarkGray
}

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

# Copy demos (playable game demos)
$DemosSource = Join-Path $WorkspaceRoot 'demos'
if (Test-Path $DemosSource) {
    $DemosDest = Join-Path $PackageDir 'demos'
    if (Test-Path $DemosDest) { Remove-Item $DemosDest -Recurse -Force }
    Copy-Item $DemosSource -Destination $DemosDest -Recurse -Force
    Write-OK "Copied demos/"
}

# Copy library (Lunasome pure-Lua standard libraries)
$LibrarySource = Join-Path $WorkspaceRoot 'library'
if (Test-Path $LibrarySource) {
    $LibraryDest = Join-Path $PackageDir 'library'
    if (Test-Path $LibraryDest) { Remove-Item $LibraryDest -Recurse -Force }
    Copy-Item $LibrarySource -Destination $LibraryDest -Recurse -Force
    Write-OK "Copied library/"
}

# Copy API docs  (lua-api.md, luna.lua LuaCATS stubs)
$ApiDocsDest = Join-Path $PackageDir 'docs'
New-Item -ItemType Directory -Path $ApiDocsDest -Force | Out-Null
foreach ($apiFile in @('lua-api.md', 'luna.lua')) {
    $src = Join-Path $WorkspaceRoot "docs\API\$apiFile"
    if (Test-Path $src) {
        Copy-Item $src -Destination (Join-Path $ApiDocsDest $apiFile) -Force
        Write-OK "Copied docs/$apiFile"
    }
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
LUNA2D $Version -- Windows Portable Distribution
=================================================

How to run a game
-----------------
  luna2d.exe  my_game\     (with console window -- for developers)
  lunec.bat   my_game\     (no console window  -- for end users)
  lunec.lnk                (shortcut with Luna2D icon -- drag-drop a game folder)

How to show the splash screen (no game)
----------------------------------------
  luna2d.exe
  lunec.bat

Bundled examples
----------------
  examples\   -- single-file API usage scripts (one per luna.* module)

  Use any example as a starting point:
    lunec.bat examples\physics

Lunasome standard libraries (library\)
----------------------------------------
  Pure-Lua game modules you can require from your game scripts.
  Available: battle, cardgame, combat, crafting, dialog, economy,
             inventory, item, quest, stats, and more.

  Usage in your game:
    local inventory = require("library/inventory")
    local quest     = require("library/quest")

API Reference (docs\)
----------------------
  docs\lua-api.md   -- luna.* Lua API reference (Markdown)
  docs\luna.lua     -- LuaCATS type stubs for IDE autocompletion
                      (copy to your project root or configure in .luarc.json)

Writing your own game
---------------------
  1. Create a folder, e.g. my_game\
  2. Add a main.lua with luna.init / luna.process(dt) / luna.render()
  3. Optionally add a conf.toml for [window] title, width, height
  4. Run:  lunec.bat my_game   (or drag the folder onto lunec.lnk)

Full docs & source:  https://github.com/yourname/luna2d
"@
Set-Content -Path (Join-Path $PackageDir 'HOW-TO-RUN.txt') -Value $HowTo -Encoding UTF8
Write-OK "Written HOW-TO-RUN.txt"

# -- 3b. Create lunec.lnk shortcut with Luna2D icon ---------------------------
$IcoPath = Join-Path $PackageDir 'assets\favicon.ico'
if (-not (Test-Path $IcoPath)) {
    $IcoPath = Join-Path $PackageDir 'assets\icon.png'  # fallback: no icon in shortcut
}
if (Test-Path $IcoPath) {
    Write-Step "Creating lunec.lnk shortcut with Luna2D icon ..."
    $ws  = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $PackageDir 'lunec.lnk'))
    $lnk.TargetPath       = Join-Path $PackageDir 'lunec.bat'
    $lnk.WorkingDirectory = $PackageDir
    $lnk.IconLocation     = "$IcoPath,0"
    $lnk.Description      = "Luna2D -- launch game without console window"
    $lnk.WindowStyle      = 1
    $lnk.Save()
    Write-OK "Created lunec.lnk (double-click to run a game, drag-and-drop supported)"
}

# -- 4. Create ZIP -------------------------------------------------------------
Write-Step "Creating ZIP archive at '$ZipPath' ..."
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

# Compress-Archive requires PowerShell 5+
Compress-Archive -Path $PackageDir -DestinationPath $ZipPath -CompressionLevel Optimal
$ZipSizeKB = [math]::Round((Get-Item $ZipPath).Length / 1024)
Write-OK "ZIP created ($ZipSizeKB KB) → $ZipPath"

# -- 5. Summary ----------------------------------------------------------------
Write-Host ""
Write-OK "Distribution package ready:"
Write-Host "  Folder : $PackageDir" -ForegroundColor White
Write-Host "  ZIP    : $ZipPath"    -ForegroundColor White
Write-Host ""
Write-Host "  Distribute the ZIP or the folder contents to end users." -ForegroundColor Yellow
Write-Host "  For a full installer, run:  makensis tools\installer.nsi" -ForegroundColor Yellow
