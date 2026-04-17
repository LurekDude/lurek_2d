#!/usr/bin/env python3
"""Snap every pixel-coordinate field in Lurek2D TOML layout files to a grid.

Only the four fields that represent pixel geometry are snapped:
    x, y, w, h

All other numeric fields (min, max, value, depth, etc.) are left unchanged so
that game-logic values are not distorted.

Grid sizes supported:
    4  — fine detail (default)
    8  — standard spacing grid

Usage:
    # Snap all layouts under content/layouts/ to an 8-pixel grid
    python tools/ui/snap_to_grid.py content/layouts/ --grid 8 --recursive

    # Dry-run: print proposed changes without modifying files
    python tools/ui/snap_to_grid.py content/layouts/ --recursive --dry-run

    # Single file
    python tools/ui/snap_to_grid.py content/layouts/games/xcom_geoscape.toml

Exit codes:
    0 — success (0 or more files modified)
    1 — one or more files failed to process
"""
from __future__ import annotations

import argparse
import math
import re
import sys
from pathlib import Path

# Fields that represent *pixel positions or sizes* — the only ones we snap.
_SNAP_KEYS: frozenset[str] = frozenset({"x", "y", "w", "h"})

# Matches a TOML assignment line that starts with one of the snap keys:
#   x = 123.0
#   h = 22
#   w = 300.45
# Group 1 → key, Group 2 → number (integer or float), Group 3 → rest of line
_COORD_RE = re.compile(
    r'^([xywhXYWH])\s*=\s*(\d+(?:\.\d+)?)([ \t]*(#.*)?)$',
    re.MULTILINE,
)


def snap(value: float, grid: int) -> int:
    """Round *value* to the nearest multiple of *grid* (round-half-up)."""
    return int(math.floor(value / grid + 0.5)) * grid


def process_file(path: Path, grid: int, dry_run: bool) -> tuple[int, int]:
    """Snap coordinate fields in *path* to *grid*.

    Returns:
        (changes, total_coords)  — number of values changed, total coords seen.
    """
    text = path.read_text(encoding="utf-8")
    changes = 0
    total = 0

    def replace_coord(m: re.Match) -> str:
        nonlocal changes, total
        key = m.group(1)
        if key not in _SNAP_KEYS:
            return m.group(0)
        raw = float(m.group(2))
        rest = m.group(3) or ""
        snapped = snap(raw, grid)
        # Ensure w/h are at least one grid unit (never collapse to zero)
        if key in ("w", "h"):
            snapped = max(grid, snapped)
        total += 1
        if snapped != int(raw) or (raw != int(raw)):
            changes += 1
            return f"{key} = {snapped}.0{rest}"
        return m.group(0)

    new_text = _COORD_RE.sub(replace_coord, text)

    if not dry_run and new_text != text:
        path.write_text(new_text, encoding="utf-8")

    return changes, total


def collect_toml_files(paths: list[str], recursive: bool) -> list[Path]:
    result: list[Path] = []
    for raw in paths:
        p = Path(raw)
        if p.is_file() and p.suffix == ".toml":
            result.append(p)
        elif p.is_dir():
            pattern = "**/*.toml" if recursive else "*.toml"
            result.extend(sorted(p.glob(pattern)))
        else:
            print(f"WARNING: {raw} not found — skipping", file=sys.stderr)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "paths",
        nargs="+",
        metavar="PATH",
        help="TOML layout file or directory to process",
    )
    parser.add_argument(
        "--grid",
        type=int,
        default=8,
        choices=[4, 8],
        help="Pixel grid size (default: 8)",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Recurse into subdirectories",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print proposed changes without writing files",
    )
    args = parser.parse_args()

    files = collect_toml_files(args.paths, recursive=args.recursive)
    if not files:
        print("No .toml files found.", file=sys.stderr)
        return 1

    total_files_changed = 0
    total_values_changed = 0
    errors: list[str] = []

    for f in files:
        try:
            changed, total = process_file(f, args.grid, dry_run=args.dry_run)
            if changed:
                total_files_changed += 1
                total_values_changed += changed
                tag = "  [dry-run]" if args.dry_run else "  changed "
                print(f"{tag}  {f}  ({changed}/{total} values snapped)")
        except Exception as exc:
            print(f"  FAILED   {f}: {exc}", file=sys.stderr)
            errors.append(str(f))

    # Summary
    label = "(dry-run) would change" if args.dry_run else "changed"
    print(
        f"\nDone. {label} {total_values_changed} value(s) across "
        f"{total_files_changed}/{len(files)} file(s) to {args.grid}px grid."
    )

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
