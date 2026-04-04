#!/usr/bin/env bash
# dist.sh — Build and package Luna2D for Linux / macOS distribution.
#
# Usage:
#   bash tools/dist.sh                    # Build + package to dist/
#   bash tools/dist.sh --skip-build       # Skip cargo build
#   bash tools/dist.sh --out /tmp/rel     # Custom output directory
#   bash tools/dist.sh --help
#
# Output layout:
#   dist/
#     luna2d-linux-x86_64/            (or macos-aarch64 etc.)
#       luna2d                        ← engine binary
#       assets/                       ← engine assets
#       examples/                     ← bundled example games
#       LICENSE  README.md  HOW-TO-RUN.txt
#     luna2d-linux-x86_64.tar.gz      ← distributable archive

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
WORKSPACE="$(dirname "$SCRIPT_DIR")"
VERSION="0.4.0"

# Detect target triple
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
TARGET_TRIPLE="${OS}-${ARCH}"
ARCH_NAME="luna2d-${TARGET_TRIPLE}"

[[ -z "$OUT_DIR" ]] && OUT_DIR="$WORKSPACE/dist"

PACKAGE_DIR="$OUT_DIR/$ARCH_NAME"
TARBALL="$OUT_DIR/${ARCH_NAME}.tar.gz"
BINARY_SOURCE="$WORKSPACE/build/release/luna"

ok()   { echo -e "\033[32m[ OK ]\033[0m  $*"; }
step() { echo -e "\033[36m[dist]\033[0m  $*"; }
fail() { echo -e "\033[31m[FAIL]\033[0m  $*" >&2; exit 1; }

[[ -f "$WORKSPACE/Cargo.toml" ]] || fail "Cargo.toml not found — run from workspace root."

# ── 1. Assets ─────────────────────────────────────────────────────────────────
step "Checking generated assets …"
if [[ ! -f "$WORKSPACE/assets/splash.png" ]]; then
    step "splash.png missing — running gen_splash.py …"
    python3 "$WORKSPACE/tools/gen_splash.py" || true
fi
if [[ ! -f "$WORKSPACE/assets/icon.png" ]]; then
    step "icon.png missing — running gen_icon.py …"
    python3 "$WORKSPACE/tools/gen_icon.py" || true
fi

# ── 2. Release build ───────────────────────────────────────────────────────────
if [[ $SKIP_BUILD -eq 0 ]]; then
    step "Building Luna2D (release) …"
    (cd "$WORKSPACE" && cargo build --release)
    ok "Build succeeded."
else
    step "Skipping build (--skip-build set)."
fi

[[ -f "$BINARY_SOURCE" ]] || fail "Binary not found at $BINARY_SOURCE."

# ── 3. Assemble package ────────────────────────────────────────────────────────
step "Assembling distribution package at '$PACKAGE_DIR' …"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

cp "$BINARY_SOURCE" "$PACKAGE_DIR/luna"
chmod +x "$PACKAGE_DIR/luna"
ok "Copied luna binary."

[[ -d "$WORKSPACE/assets"   ]] && cp -r "$WORKSPACE/assets"   "$PACKAGE_DIR/assets"   && ok "Copied assets/"
[[ -d "$WORKSPACE/examples" ]] && cp -r "$WORKSPACE/examples" "$PACKAGE_DIR/examples" && ok "Copied examples/"
[[ -f "$WORKSPACE/README.md" ]] && cp "$WORKSPACE/README.md" "$PACKAGE_DIR/"
[[ -f "$WORKSPACE/LICENSE"  ]]  && cp "$WORKSPACE/LICENSE"  "$PACKAGE_DIR/"

cat > "$PACKAGE_DIR/HOW-TO-RUN.txt" << EOF
LUNA2D $VERSION — ${TARGET_TRIPLE} Distribution
=================================================

How to run a game
-----------------
  ./luna  examples/hello_world
  ./luna  path/to/your_game

How to show the splash screen (no game)
----------------------------------------
  ./luna

Bundled examples
----------------
  examples/hello_world   — shapes, text, FPS counter
  examples/physics_demo  — falling ball with AABB physics
  examples/sprites       — keyboard-controlled sprite

Writing your own game
---------------------
  1. Create a folder, e.g. my_game/
  2. Add main.lua with luna.load() / luna.update(dt) / luna.draw()
  3. Run:  ./luna my_game

API reference:  see README.md
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
