#!/usr/bin/env bash
# install.sh — Install or uninstall Lurek2D on Linux / macOS
#
# Usage:
#   bash tools/install.sh                       # Install to /usr/local/bin
#   bash tools/install.sh --prefix ~/.local     # Install to ~/.local/bin
#   bash tools/install.sh --uninstall           # Remove /usr/local/bin/lurek2d
#   bash tools/install.sh --prefix ~/.local --uninstall
#
# The script builds the release binary through tools/dev/parallel_cargo.py,
# copies it to <prefix>/bin/lurek2d, and copies the content/demos/ folder to
# <prefix>/share/lurek2d/examples.
# Requires: python, cargo, bash >= 4

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
PREFIX="/usr/local"
UNINSTALL=0

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="$2"; shift 2 ;;
        --prefix=*)
            PREFIX="${1#--prefix=}"; shift ;;
        --uninstall)
            UNINSTALL=1; shift ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

BINARY_DEST="$PREFIX/bin/lurek2d"
EXAMPLES_DEST="$PREFIX/share/lurek2d/games"

ok()   { echo -e "\033[32m[  OK  ]\033[0m $*"; }
step() { echo -e "\033[36m[lurek2d]\033[0m $*"; }
warn() { echo -e "\033[33m[  --  ]\033[0m $*"; }
fail() { echo -e "\033[31m[ FAIL ]\033[0m $*" >&2; exit 1; }

# ── Locate workspace root ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
if [[ ! -f "$WORKSPACE_ROOT/Cargo.toml" ]]; then
    fail "Cannot find Cargo.toml. Run from the lurek2d workspace root."
fi

# ── Uninstall ────────────────────────────────────────────────────────────────
if [[ $UNINSTALL -eq 1 ]]; then
    step "Uninstalling Lurek2D from prefix '$PREFIX' ..."

    if [[ -f "$BINARY_DEST" ]]; then
        rm -f "$BINARY_DEST"
        ok "Removed $BINARY_DEST"
    else
        warn "Binary not found at $BINARY_DEST (already removed?)"
    fi

    if [[ -d "$EXAMPLES_DEST" ]]; then
        rm -rf "$EXAMPLES_DEST"
        ok "Removed $EXAMPLES_DEST"
    else
        warn "Examples not found at $EXAMPLES_DEST"
    fi

    ok "Uninstall complete."
    exit 0
fi

# ── Build ─────────────────────────────────────────────────────────────────────
step "Building Lurek2D (release) — this may take a minute..."
(cd "$WORKSPACE_ROOT" && python tools/dev/parallel_cargo.py build release)
ok "Build succeeded."

BUILT_BINARY="$WORKSPACE_ROOT/build/release/lurek2d"
if [[ ! -f "$BUILT_BINARY" ]]; then
    fail "Expected binary at '$BUILT_BINARY' but it was not found."
fi

# ── Install binary ────────────────────────────────────────────────────────────
BIN_DIR="$PREFIX/bin"
if [[ ! -d "$BIN_DIR" ]]; then
    step "Creating $BIN_DIR ..."
    mkdir -p "$BIN_DIR"
fi

step "Installing binary to '$BINARY_DEST' ..."
cp "$BUILT_BINARY" "$BINARY_DEST"
chmod +x "$BINARY_DEST"
ok "Binary installed."

# ── Install examples ──────────────────────────────────────────────────────────
EXAMPLES_SOURCE="$WORKSPACE_ROOT/content/games"
if [[ -d "$EXAMPLES_SOURCE" ]]; then
    step "Copying examples to '$EXAMPLES_DEST' ..."
    mkdir -p "$EXAMPLES_DEST"
    cp -r "$EXAMPLES_SOURCE/." "$EXAMPLES_DEST/"
    ok "Examples copied."
else
    warn "content/demos/ folder not found — skipping."
fi

# ── PATH advisory ─────────────────────────────────────────────────────────────
if ! command -v lurek2d &>/dev/null; then
    echo ""
    echo "  NOTE: '$BIN_DIR' does not appear to be in your PATH."
    echo "  Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "    export PATH=\"\$PATH:$BIN_DIR\""
    echo ""
fi

ok "Lurek2D installed. Run:  lurek2d content/games/showcase/hello_world"
ok "Or use games from:   $EXAMPLES_DEST"
