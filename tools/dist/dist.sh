#!/usr/bin/env bash
# dist.sh — Build and package Lurek2D for Linux / macOS distribution.
#
# Usage:
#   bash tools/dist.sh                    # Build + package to dist/
#   bash tools/dist.sh --skip-build       # Skip the wrapper-backed release build
#   bash tools/dist.sh --out /tmp/rel     # Custom output directory
#   bash tools/dist.sh --help
#
# Output layout:
#   dist/
#     lurek2d-linux-x86_64/            (or macos-aarch64 etc.)
#       lurek2d                        ← engine binary
#       assets/                       ← engine assets
#       content/demos/                     ← bundled example games
#       LICENSE  README.md  HOW-TO-RUN.txt
#     lurek2d-linux-x86_64.tar.gz      ← distributable archive

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
SKIP_BUILD=0
OUT_DIR=""

# ── Arg parsing ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=1; shift ;;
        --out)        OUT_DIR="$2"; shift 2 ;;
        --out=*)      OUT_DIR="${1#--out=}"; shift ;;
        -h|--help)    grep '^#' "$0" | sed 's/^# \?//; s/^!.*//' | head -20; exit 0 ;;
        *)            echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# ── Setup ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(dirname "$(dirname "$SCRIPT_DIR")")"
VERSION="1.0.0"

# Detect target triple
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
TARGET_TRIPLE="${OS}-${ARCH}"
ARCH_NAME="lurek2d-${TARGET_TRIPLE}"

[[ -z "$OUT_DIR" ]] && OUT_DIR="$WORKSPACE/dist"

PACKAGE_DIR="$OUT_DIR/$ARCH_NAME"
TARBALL="$OUT_DIR/${ARCH_NAME}.tar.gz"
BINARY_SOURCE="$WORKSPACE/build/release/lurek2d"

ok()   { echo -e "\033[32m[ OK ]\033[0m  $*"; }
step() { echo -e "\033[36m[dist]\033[0m  $*"; }
fail() { echo -e "\033[31m[FAIL]\033[0m  $*" >&2; exit 1; }

[[ -f "$WORKSPACE/Cargo.toml" ]] || fail "Cargo.toml not found — run from workspace root."

# ── 1. Verify branding assets ────────────────────────────────────────────────
step "Checking branding assets …"
if [[ ! -f "$WORKSPACE/assets/splash.png" ]]; then
  fail "Missing assets/splash.png. Restore the prebuilt raster asset or rebuild it from assets/svg/large_icon.png and assets/svg/banner.png."
fi
if [[ ! -f "$WORKSPACE/assets/icon.png" ]]; then
  fail "Missing assets/icon.png. Restore the prebuilt raster asset or rebuild it from assets/svg/col_icon.png."
fi

# ── 2. Release build ───────────────────────────────────────────────────────────
if [[ $SKIP_BUILD -eq 0 ]]; then
    step "Building Lurek2D (release) …"
  (cd "$WORKSPACE" && python tools/dev/parallel_cargo.py build release)
    ok "Build succeeded."
else
    step "Skipping build (--skip-build set)."
fi

[[ -f "$BINARY_SOURCE" ]] || fail "Binary not found at $BINARY_SOURCE."

# ── 3. Assemble package ────────────────────────────────────────────────────────
step "Assembling distribution package at '$PACKAGE_DIR' …"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

cp "$BINARY_SOURCE" "$PACKAGE_DIR/lurek2d"
chmod +x "$PACKAGE_DIR/lurek2d"
ok "Copied lurek2d binary."

[[ -d "$WORKSPACE/assets"          ]] && cp -r "$WORKSPACE/assets"          "$PACKAGE_DIR/assets"   && ok "Copied assets/"
[[ -d "$WORKSPACE/content/examples" ]] && cp -r "$WORKSPACE/content/examples" "$PACKAGE_DIR/examples" && ok "Copied content/examples/"
[[ -f "$WORKSPACE/README.md" ]] && cp "$WORKSPACE/README.md" "$PACKAGE_DIR/"
[[ -f "$WORKSPACE/LICENSE"   ]]  && cp "$WORKSPACE/LICENSE"  "$PACKAGE_DIR/"

cat > "$PACKAGE_DIR/HOW-TO-RUN.txt" << EOF
LUREK2D $VERSION — ${TARGET_TRIPLE} Distribution
=================================================

How to run a game
-----------------
  ./lurek2d  content/games/showcase/hello_world
  ./lurek2d  path/to/your_game

How to show the splash screen (no game)
----------------------------------------
  ./lurek2d

Bundled examples
----------------
  examples/   — single-file API usage scripts (one per lurek.* module)

Writing your own game
---------------------
  1. Create a folder, e.g. my_game/
  2. Add main.lua with lurek.load() / lurek.update(dt) / lurek.draw()
  3. Run:  ./lurek2d my_game

API reference:  see README.md
Source & docs:  https://github.com/RandomBladeDude/lurek2d
EOF
ok "Written HOW-TO-RUN.txt"

# ── 4. Create tarball ──────────────────────────────────────────────────────────
step "Creating archive at '$TARBALL' …"
rm -f "$TARBALL"
(cd "$OUT_DIR" && tar -czf "$TARBALL" "$ARCH_NAME")
TARBALL_SIZE_KB=$(( $(wc -c < "$TARBALL") / 1024 ))
ok "Archive created (${TARBALL_SIZE_KB} KB) → $TARBALL"

# ── 5. Summary ────────────────────────────────────────────────────────────────
echo ""
ok "Distribution package ready:"
echo "  Folder  : $PACKAGE_DIR"
echo "  Archive : $TARBALL"
echo ""
echo "  Distribute the archive or folder to end users."
