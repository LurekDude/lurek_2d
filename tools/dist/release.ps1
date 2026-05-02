#Requires -Version 5.1
<#
.SYNOPSIS
    Full Lurek2D release pipeline: build all profiles, package, install-build,
    build VS Code extension, and assemble GitHub release artifacts.

.DESCRIPTION
    Steps performed:
      1. Debug build   → build/debug/lurek2d.exe
      2. Release build → build/release/lurek2d.exe
      3. Dist build    → build/dist/lurek2d.exe  (size-optimised, UPX-compressed via dist.ps1)
      4. Portable ZIP  → dist/lurek2d-windows-x86_64.zip  (via dist.ps1 -SkipBuild)
      5. NSIS installer → dist/lurek2d-<version>-setup.exe  (requires makensis on PATH)
      6. VS Code extension → dist/lurek2d-toolkit-<version>.vsix  (requires node/npm on PATH)
      7. Assemble      → dist/github-release/  ready to upload to GitHub Releases

    Pass -SkipRustBuilds to reuse existing binaries (useful when only repacking).
    Pass -SkipExtension to skip the VS Code extension build.
    Pass -SkipInstaller to skip NSIS (e.g. if makensis is not installed).

.PARAMETER SkipRustBuilds
    Skip debug/release/dist Rust compilation steps.

.PARAMETER SkipExtension
    Skip VS Code extension build.

.PARAMETER SkipInstaller
    Skip NSIS installer creation.

.PARAMETER OutDir
    Root output directory.  Defaults to dist/ inside the workspace.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools/dist/release.ps1
    powershell -ExecutionPolicy Bypass -File tools/dist/release.ps1 -SkipRustBuilds
    powershell -ExecutionPolicy Bypass -File tools/dist/release.ps1 -SkipInstaller
#>

param(
    [switch]$SkipRustBuilds,
    [switch]$SkipExtension,
    [switch]$SkipInstaller,
    [string]$OutDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WorkspaceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $OutDir) { $OutDir = Join-Path $WorkspaceRoot 'dist' }

$CargoToml = Join-Path $WorkspaceRoot 'Cargo.toml'
if (-not (Test-Path $CargoToml)) {
    Write-Error "Cargo.toml not found. Run from the workspace root or tools/dist/."
    exit 1
}

# Read version from Cargo.toml
$Version = (Select-String -Path $CargoToml -Pattern '^version\s*=\s*"([^"]+)"' | Select-Object -First 1).Matches.Groups[1].Value
if (-not $Version) { $Version = "1.0.0" }

$ReleaseDir = Join-Path $OutDir 'github-release'

# ── Helpers ───────────────────────────────────────────────────────────────────
function Write-Step([string]$Msg) { Write-Host "`n[release] $Msg" -ForegroundColor Cyan }
function Write-OK  ([string]$Msg) { Write-Host "  [ OK ]  $Msg" -ForegroundColor Green }
function Write-Warn([string]$Msg) { Write-Host "  [WARN]  $Msg" -ForegroundColor Yellow }
function Write-Fail([string]$Msg) { Write-Host "  [FAIL]  $Msg" -ForegroundColor Red; exit 1 }

function Invoke-Checked([string]$Command, [string[]]$CmdArgs) {
    & $Command @CmdArgs
    if ($LASTEXITCODE -ne 0) { Write-Fail "'$Command $($CmdArgs -join ' ')' exited $LASTEXITCODE" }
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Magenta
Write-Host "  Lurek2D $Version — Release Pipeline" -ForegroundColor Magenta
Write-Host "=====================================================" -ForegroundColor Magenta

Push-Location $WorkspaceRoot

try {
    # ── Step 1: Debug build ───────────────────────────────────────────────────
    if (-not $SkipRustBuilds) {
        Write-Step "Step 1/6 — Debug build"
        Invoke-Checked python @('tools/dev/parallel_cargo.py', 'build', 'debug')
        Write-OK "Debug build → build/debug/lurek2d.exe"
    } else {
        Write-Warn "Skipping debug build (-SkipRustBuilds)"
    }

    # ── Step 2: Release build ─────────────────────────────────────────────────
    if (-not $SkipRustBuilds) {
        Write-Step "Step 2/6 — Release build"
        Invoke-Checked python @('tools/dev/parallel_cargo.py', 'build', 'release')
        Write-OK "Release build → build/release/lurek2d.exe"
    } else {
        Write-Warn "Skipping release build (-SkipRustBuilds)"
    }

    # ── Step 3+4: Dist build + portable ZIP ──────────────────────────────────
    if (-not $SkipRustBuilds) {
        Write-Step "Step 3/6 — Dist build (size-optimised) + portable ZIP"
        $distArgs = @('-ExecutionPolicy', 'Bypass', '-File', 'tools/dist/dist.ps1', '-OutDir', $OutDir)
        Invoke-Checked powershell $distArgs
    } else {
        Write-Step "Step 3/6 — Repackage only (skip dist build)"
        $distArgs = @('-ExecutionPolicy', 'Bypass', '-File', 'tools/dist/dist.ps1', '-SkipBuild', '-OutDir', $OutDir)
        Invoke-Checked powershell $distArgs
    }
    $ZipPath = Join-Path $OutDir 'lurek2d-windows-x86_64.zip'
    if (Test-Path $ZipPath) {
        Write-OK "Portable ZIP → $ZipPath"
    } else {
        Write-Warn "Expected ZIP not found at $ZipPath"
    }

    # ── Step 5: NSIS installer ────────────────────────────────────────────────
    $InstallerPath = Join-Path $OutDir "lurek2d-$Version-setup.exe"
    if (-not $SkipInstaller) {
        Write-Step "Step 4/6 — NSIS Windows installer"
        if (Get-Command makensis -ErrorAction SilentlyContinue) {
            # Ensure output dir exists for NSIS
            if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
            Invoke-Checked makensis @('tools/dist/installer.nsi')
            if (Test-Path $InstallerPath) {
                $sizeMB = [math]::Round((Get-Item $InstallerPath).Length / 1MB, 1)
                Write-OK "Installer → $InstallerPath ($sizeMB MB)"
            }
        } else {
            Write-Warn "makensis not on PATH — skipping installer. Install NSIS: https://nsis.sourceforge.io"
            $SkipInstaller = $true
        }
    } else {
        Write-Warn "Skipping NSIS installer (-SkipInstaller)"
    }

    # ── Step 6: VS Code extension ─────────────────────────────────────────────
    $ExtVersionRaw = (Get-Content (Join-Path $WorkspaceRoot 'extensions/vscode/package.json') | ConvertFrom-Json).version
    $VsixName = "lurek2d-toolkit-$ExtVersionRaw.vsix"
    $VsixPath = Join-Path $WorkspaceRoot "extensions/vscode/$VsixName"
    if (-not $SkipExtension) {
        Write-Step "Step 5/6 — VS Code extension"
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            Push-Location (Join-Path $WorkspaceRoot 'extensions/vscode')
            try {
                Write-Host "  Installing npm dependencies..."
                Invoke-Checked npm @('install', '--prefer-offline')
                Write-Host "  Building extension..."
                Invoke-Checked npm @('run', 'package')
                # vsce outputs the vsix to cwd
                $VsixActual = Get-ChildItem -Filter '*.vsix' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($VsixActual) {
                    $VsixPath = $VsixActual.FullName
                    Write-OK "Extension → $VsixPath"
                }
            } finally {
                Pop-Location
            }
        } else {
            Write-Warn "npm not on PATH — skipping extension build."
            $SkipExtension = $true
        }
    } else {
        Write-Warn "Skipping VS Code extension (-SkipExtension)"
    }

    # ── Step 7: Assemble GitHub release folder ────────────────────────────────
    Write-Step "Step 6/6 — Assembling GitHub release artifacts"
    if (Test-Path $ReleaseDir) { Remove-Item $ReleaseDir -Recurse -Force }
    New-Item -ItemType Directory -Path $ReleaseDir | Out-Null

    $artifacts = @()

    # Portable engine ZIP
    if (Test-Path $ZipPath) {
        $destZip = Join-Path $ReleaseDir (Split-Path $ZipPath -Leaf)
        Copy-Item $ZipPath $destZip -Force
        $artifacts += $destZip
        Write-OK "Copied portable ZIP"
    }

    # NSIS installer
    if (-not $SkipInstaller -and (Test-Path $InstallerPath)) {
        $destInstaller = Join-Path $ReleaseDir (Split-Path $InstallerPath -Leaf)
        Copy-Item $InstallerPath $destInstaller -Force
        $artifacts += $destInstaller
        Write-OK "Copied Windows installer"
    }

    # VS Code extension
    if (-not $SkipExtension -and (Test-Path $VsixPath)) {
        $destVsix = Join-Path $ReleaseDir (Split-Path $VsixPath -Leaf)
        Copy-Item $VsixPath $destVsix -Force
        $artifacts += $destVsix
        Write-OK "Copied VS Code extension"
    }

    # Write release manifest (SHA256 checksums)
    Write-Step "Generating SHA256 checksums"
    $ChecksumFile = Join-Path $ReleaseDir 'checksums-sha256.txt'
    $checksumLines = foreach ($f in $artifacts) {
        $hash = (Get-FileHash $f -Algorithm SHA256).Hash.ToLower()
        "$hash  $(Split-Path $f -Leaf)"
    }
    $checksumLines | Set-Content $ChecksumFile -Encoding UTF8
    Write-OK "Checksums → $ChecksumFile"

    # ── Summary ───────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host "  Release artifacts ready for GitHub Releases" -ForegroundColor Green
    Write-Host "  Folder: $ReleaseDir" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Magenta
    Get-ChildItem $ReleaseDir | Format-Table Name, @{N='Size (KB)';E={[math]::Round($_.Length/1KB,1)}} -AutoSize

} finally {
    Pop-Location
}
