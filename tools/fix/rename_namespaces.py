#!/usr/bin/env python3
"""Rename lurek.* Lua namespaces to match src/ folder names.

Run from the repository root:
    python tools/fix/rename_namespaces.py [--dry-run]
"""
import os
import re
import sys
import argparse
from pathlib import Path

# Ordered from longest/most-specific to shortest to prevent partial matches.
# Each entry: (regex_pattern, replacement_string)
RENAMES = [
    # Longer names first to avoid partial-match issues
    (r"lurek\.savegame",    "lurek.save"),
    (r"lurek\.particles",   "lurek.particle"),
    (r"lurek\.pathfinding", "lurek.pathfind"),
    (r"lurek\.modding",     "lurek.mods"),
    (r"lurek\.localization","lurek.i18n"),
    (r"lurek\.simulator",   "lurek.automation"),
    (r"lurek\.keyboard",    "lurek.input.keyboard"),
    (r"lurek\.gamepad",     "lurek.input.gamepad"),
    (r"lurek\.graphic",     "lurek.render"),
    (r"lurek\.postfx",      "lurek.effect"),
    (r"lurek\.overlay",     "lurek.effect"),
    (r"lurek\.signal",      "lurek.event"),
    (r"lurek\.entity(?!\w)","lurek.ecs"),
    (r"lurek\.engine(?!\w)","lurek.runtime"),
    (r"lurek\.platform",    "lurek.runtime"),
    (r"lurek\.collision",   "lurek.physics"),
    (r"lurek\.codec",       "lurek.serial"),
    (r"lurek\.mouse",       "lurek.input.mouse"),
    (r"lurek\.touch",       "lurek.input.touch"),
    (r"lurek\.gpu",         "lurek.compute"),
    # Word-boundary replacements for short names
    (r"lurek\.fs(?!\w)",    "lurek.filesystem"),
    # lurek.timer → lurek.timer  (negative lookahead: not followed by 'r' or another word char)
    (r"lurek\.time(?!r\b|[A-Za-z0-9_])","lurek.timer"),
    # lurek.image → lurek.image  (not followed by word chars, e.g. not lurek.images)
    (r"lurek\.img(?!\w)",   "lurek.image"),
]

# Compile patterns
COMPILED = [(re.compile(p), r) for p, r in RENAMES]

# File extensions to process
EXTENSIONS = {".lua", ".rs", ".md", ".txt", ".toml", ".py"}

# Directories to skip
SKIP_DIRS = {
    "build", "target", ".git", "node_modules",
    "work",  # scratch files — skip to avoid touching in-progress notes
}

ROOT = Path(__file__).resolve().parents[2]  # repo root


def process_file(path: Path, dry_run: bool) -> int:
    """Return count of replacements made."""
    try:
        original = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return 0

    text = original
    for pattern, replacement in COMPILED:
        text = pattern.sub(replacement, text)

    if text == original:
        return 0

    diff_count = sum(
        1 for a, b in zip(original.splitlines(), text.splitlines()) if a != b
    )
    if not dry_run:
        path.write_text(text, encoding="utf-8")
    return diff_count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Print changes without writing")
    args = parser.parse_args()

    total_files = 0
    total_changes = 0

    for dirpath, dirnames, filenames in os.walk(ROOT):
        # Prune skipped directories in-place
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for filename in filenames:
            filepath = Path(dirpath) / filename
            if filepath.suffix not in EXTENSIONS:
                continue
            changes = process_file(filepath, args.dry_run)
            if changes > 0:
                rel = filepath.relative_to(ROOT)
                action = "WOULD CHANGE" if args.dry_run else "CHANGED"
                print(f"  {action}: {rel} ({changes} lines)")
                total_files += 1
                total_changes += changes

    print(f"\n{'[DRY RUN] ' if args.dry_run else ''}Done: {total_files} files, {total_changes} lines changed.")


if __name__ == "__main__":
    main()
