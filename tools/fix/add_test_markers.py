#!/usr/bin/env python3
"""
Add @covers / @stress / @golden / @security markers to Lurek2D Lua test files.

Scans each .lua test file for lurek.module.function call patterns and injects
marker comments after the header comments block.

Usage:
    python tools/fix/add_test_markers.py [--dry-run]
"""

import re
import sys
from pathlib import Path

# Matches lurek.module.functionName (not just lurek.module)
LUREK_CALL_RE = re.compile(r'lurek\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)')

# Detect existing markers
COVERS_RE = re.compile(r'@covers|@stress|@golden|@security')

# Map test subdirectory to marker type
SUBDIR_MARKER = {
    "stress":   "@stress",
    "golden":   "@golden",
    "security": "@security",
}


def find_lurek_calls(content: str) -> list:
    """Return sorted unique lurek.module.function strings found in content."""
    seen = set()
    results = []
    for m in LUREK_CALL_RE.finditer(content):
        key = f"lurek.{m.group(1)}.{m.group(2)}"
        if key not in seen:
            seen.add(key)
            results.append(key)
    return sorted(results)


def find_header_end(lines: list) -> int:
    """Find the line index just after the initial -- comment block."""
    header_end = 0
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if stripped.startswith("--"):
            header_end = i + 1  # update to one past this comment line
            i += 1
        elif stripped == "":
            i += 1  # skip blank lines within header area
        else:
            break  # first non-comment, non-blank line
    return header_end


def build_marker_lines(calls: list, marker_type: str) -> list:
    """Build the list of marker comment strings."""
    return [f"-- {marker_type} {call}" for call in calls]


def insert_markers(content: str, marker_lines: list) -> str:
    """Insert marker lines into content after the header comment block."""
    lines = content.split("\n")
    insert_at = find_header_end(lines)

    # Avoid duplicate blank lines
    prefix = lines[:insert_at]
    suffix = lines[insert_at:]

    new_lines = prefix + marker_lines + [""] + suffix
    return "\n".join(new_lines)


def process_file(filepath: Path, dry_run: bool = False) -> tuple:
    """Process one Lua test file. Return (changed: bool, reason: str)."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        return False, f"read error: {e}"

    # Skip if already has markers
    if COVERS_RE.search(content):
        return False, "already has markers"

    calls = find_lurek_calls(content)
    if not calls:
        return False, "no lurek.module.function calls found"

    # Determine marker type by subdirectory
    parts = filepath.parts
    subdir = ""
    for p in parts:
        if p in SUBDIR_MARKER:
            subdir = p
            break
    marker_type = SUBDIR_MARKER.get(subdir, "@covers")

    marker_lines = build_marker_lines(calls, marker_type)
    new_content = insert_markers(content, marker_lines)

    if not dry_run:
        try:
            filepath.write_text(new_content, encoding="utf-8")
        except Exception as e:
            return False, f"write error: {e}"

    sample = calls[:3]
    sample_str = ", ".join(sample) + ("..." if len(calls) > 3 else "")
    return True, f"added {len(calls)} {marker_type} marker(s): {sample_str}"


def main():
    dry_run = "--dry-run" in sys.argv
    test_dir = Path("tests/lua")

    if not test_dir.exists():
        print(f"Error: {test_dir} not found. Run from the repo root.")
        sys.exit(1)

    total, changed, skipped = 0, 0, 0

    for lua_file in sorted(test_dir.rglob("*.lua")):
        # Skip the BDD framework
        if lua_file.name == "init.lua":
            continue
        total += 1
        modified, reason = process_file(lua_file, dry_run=dry_run)
        rel = str(lua_file).replace("\\", "/")
        if modified:
            changed += 1
            print(f"  ADDED {rel} -- {reason}")
        else:
            skipped += 1
            print(f"  skip  {rel} -- {reason}")

    action = "Would add" if dry_run else "Added"
    print(f"\n{action} markers to {changed}/{total} files ({skipped} skipped).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
