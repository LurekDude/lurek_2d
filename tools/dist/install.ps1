#Requires -Version 5.1
<#
.SYNOPSIS
    Install or uninstall the Lurek2D engine locally on Windows.

.DESCRIPTION
    Builds the Lurek2D engine in release mode through tools/dev/parallel_cargo.py, copies the binary to
    %USERPROFILE%\bin (or a custom destination via -Destination), and
    copies the content/demos/ folder so you can run games from any terminal.

    Run with --uninstall / -Uninstall to remove a previous installation.

.PARAMETER Destination
    Target directory for the binary. Defaults to "$env:USERPROFILE\bin".

.PARAMETER Uninstall
    Remove the binary and installed examples from Destination.

.EXAMPLE
    .\tools\install.ps1
    .\tools\install.ps1 -Destination "C:\Programs\lurek2d"
    .\tools\install.ps1 --uninstall
#>

param(
    [string]$Destination = "$env:USERPROFILE\bin",
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BinaryName  = 'lurek2d.exe'
$BinaryDest  = Join-Path $Destination $BinaryName
$ExamplesDest = Join-Path $Destination 'games'

# ── Helper ────────────────────────────────────────────────────────────────────
function Write-Step([string]$Msg) {
    Write-Host "[lurek2d] $Msg" -ForegroundColor Cyan
}

function Write-OK([string]$Msg) {
    Write-Host "[  OK  ] $Msg" -ForegroundColor Green
}

function Write-Fail([string]$Msg) {
    Write-Host "[ FAIL ] $Msg" -ForegroundColor Red
    exit 1
}

# ── Uninstall path ─────────────────────────────────────────────────────────────
if ($Uninstall) {
    Write-Step "Uninstalling Lurek2D from '$Destination' ..."

    if (Test-Path $BinaryDest) {
        Remove-Item $BinaryDest -Force
        Write-OK "Removed $BinaryDest"
    } else {
        Write-Host "[  --  ] Binary not found at $BinaryDest (already removed?)"
    }

    if (Test-Path $ExamplesDest) {
        Remove-Item $ExamplesDest -Recurse -Force
        Write-OK "Removed $ExamplesDest"
    } else {
        Write-Host "[  --  ] Examples folder not found at $ExamplesDest"
    }

    Write-OK "Uninstall complete."
    exit 0
}

# ── Install path ───────────────────────────────────────────────────────────────

# 1. Verify we are at the workspace root
$WorkspaceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$CargoToml = Join-Path $WorkspaceRoot 'Cargo.toml'
if (-not (Test-Path $CargoToml)) {
    Write-Fail "Cannot find Cargo.toml. Run this script from the lurek2d workspace root."
}

# 2. Build release binary
Write-Step "Building Lurek2D (release) — this may take a minute..."
Push-Location $WorkspaceRoot
try {
    python tools/dev/parallel_cargo.py build release 2>&1 | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -ne 0) { Write-Fail "parallel_cargo.py build release failed (exit $LASTEXITCODE)." }
} finally {
    Pop-Location
}
Write-OK "Build succeeded."

# 3. Locate the compiled binary
$BuiltBinary = Join-Path $WorkspaceRoot 'build\release\lurek2d.exe'
if (-not (Test-Path $BuiltBinary)) {
    Write-Fail "Expected binary at '$BuiltBinary' but it was not found."
}

# 4. Create destination directory
if (-not (Test-Path $Destination)) {
    Write-Step "Creating destination directory '$Destination' ..."
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Write-OK "Directory created."
}

# 5. Copy binary
Write-Step "Installing binary to '$BinaryDest' ..."
Copy-Item $BuiltBinary -Destination $BinaryDest -Force
Write-OK "Binary installed."

# 6. Copy games (showcase game demos)
$ExamplesSource = Join-Path $WorkspaceRoot 'content\games'
if (Test-Path $ExamplesSource) {
    Write-Step "Copying content/games to '$ExamplesDest' ..."
    if (Test-Path $ExamplesDest) { Remove-Item $ExamplesDest -Recurse -Force }
    Copy-Item $ExamplesSource -Destination $ExamplesDest -Recurse -Force
    Write-OK "Games copied."
} else {
    Write-Host "[  --  ] content/games/ folder not found — skipping."
}

# 7. PATH advisory
$PathDirs = $env:PATH -split ';'
if ($Destination -notin $PathDirs) {
    Write-Host ""
    Write-Host "  NOTE: '$Destination' is not in your PATH." -ForegroundColor Yellow
    Write-Host "  Add it to your user PATH to run lurek2d from any terminal:" -ForegroundColor Yellow
    Write-Host "    [System.Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$Destination', 'User')" -ForegroundColor DarkYellow
    Write-Host ""
}

Write-OK "Lurek2D installed. Run:  lurek2d content\games\showcase\hello_world"
Write-OK "Or use games from:     $ExamplesDest"
