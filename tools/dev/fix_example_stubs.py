#!/usr/bin/env python3
"""Fix --@api-stub: tags in content/examples/ to match API JSON type names,
then remove duplicate stub sections at the bottom of each file.

Steps:
1. Load API JSON to get the mapping of (module, method_name) -> correct stub_id
2. For each example file, find real examples (with `do` blocks) and fix their tags
3. Remove stub sections (lines starting with "-- ---- Stub:") that are now covered
"""
from __future__ import annotations
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API_JSON = ROOT / 'logs' / 'data' / 'lua_api_data.json'
EXAMPLES_DIR = ROOT / 'content' / 'examples'

NAMESPACE_MAP = {
    'system': 'runtime',
}


def load_api_names(jp: Path) -> dict[str, dict[str, str]]:
    """Returns {module: {method_name: correct_stub_id}}"""
    data = json.loads(jp.read_text(encoding='utf-8'))
    mods = data['lua_api']['modules']
    result: dict[str, dict[str, str]] = {}
    for mn, m in mods.items():
        if mn == 'collision':
            continue
        ns = NAMESPACE_MAP.get(mn, mn)
        result.setdefault(mn, {})
        for fn in (m.get('functions') or []):
            stub_id = f"lurek.{ns}.{fn['name']}"
            result[mn][fn['name']] = stub_id
        for cn, cls in (m.get('classes') or {}).items():
            for meth in (cls.get('methods') or []):
                stub_id = f"{cn}:{meth['name']}"
                result[mn][meth['name']] = stub_id
                # Also map with class name prefix
                result[mn][f"{cn}:{meth['name']}"] = stub_id
    return result


def find_module_for_file(filename: str) -> str | None:
    """Map example filename to module key."""
    return filename.replace('.lua', '') if filename.endswith('.lua') else None


def fix_file(filepath: Path, api_names: dict[str, dict[str, str]]) -> tuple[int, int, int]:
    """Fix tags and remove duplicate stubs. Returns (tags_fixed, stubs_removed, lines_removed)."""
    module = find_module_for_file(filepath.name)
    if not module or module not in api_names:
        return 0, 0, 0

    names = api_names[module]
    lines = filepath.read_text(encoding='utf-8').splitlines()

    # Phase 1: Find real examples and their tag lines, build a rename map
    tags_fixed = 0
    real_stub_ids = set()

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped.startswith('--@api-stub:'):
            continue
        marker = stripped[len('--@api-stub:'):].strip()

        # Check if this is a real example (has a `do` block within 3 lines)
        has_do = False
        for j in range(i + 1, min(i + 5, len(lines))):
            if lines[j].strip() == 'do':
                has_do = True
                break

        if not has_do:
            continue  # This is a stub section, skip for now

        # Try to find the correct stub_id for this marker
        # Extract the method name from the marker
        if ':' in marker:
            parts = marker.split(':')
            method_name = parts[-1]
        elif '.' in marker:
            parts = marker.split('.')
            method_name = parts[-1]
        else:
            method_name = marker

        # Look up correct stub_id
        correct_id = names.get(method_name)
        if correct_id and correct_id != marker:
            lines[i] = f"--@api-stub: {correct_id}"
            tags_fixed += 1
            real_stub_ids.add(correct_id)
        elif correct_id == marker:
            real_stub_ids.add(correct_id)
        else:
            # No match found - keep as is
            real_stub_ids.add(marker)

    # Phase 2: Remove duplicate stub sections
    # A stub section starts with "-- ---- Stub:" and ends before the next
    # "-- ---- Stub:" or end of file. Remove ones whose stub_id is in real_stub_ids.
    new_lines = []
    i = 0
    stubs_removed = 0
    lines_removed = 0
    in_stub_section = False
    stub_section_id = None
    stub_section_start = -1

    while i < len(lines):
        stripped = lines[i].strip()

        # Detect start of a stub section
        if stripped.startswith('-- ---- Stub:'):
            # End any previous stub section
            if in_stub_section and stub_section_id and stub_section_id in real_stub_ids:
                stubs_removed += 1
                # Don't add the previous stub section lines (they were skipped)
            elif in_stub_section:
                # Keep this stub section (it's truly missing)
                new_lines.extend(lines[stub_section_start:i])

            in_stub_section = True
            stub_section_start = i

            # Extract the stub_id from the next --@api-stub: line
            stub_section_id = None
            for j in range(i, min(i + 3, len(lines))):
                if lines[j].strip().startswith('--@api-stub:'):
                    stub_section_id = lines[j].strip()[len('--@api-stub:'):].strip()
                    break
            i += 1
            continue

        if not in_stub_section:
            new_lines.append(lines[i])
        i += 1

    # Handle last stub section
    if in_stub_section:
        if stub_section_id and stub_section_id in real_stub_ids:
            stubs_removed += 1
        else:
            new_lines.extend(lines[stub_section_start:])

    lines_removed = len(lines) - len(new_lines)

    # Write back
    if tags_fixed > 0 or stubs_removed > 0:
        # Remove trailing blank lines
        while new_lines and new_lines[-1].strip() == '':
            new_lines.pop()
        new_lines.append('')  # One trailing newline
        filepath.write_text('\n'.join(new_lines), encoding='utf-8')

    return tags_fixed, stubs_removed, lines_removed


def main():
    if not API_JSON.exists():
        print(f"ERROR: {API_JSON} not found. Run gen_lua_api_data.py first.")
        sys.exit(1)

    api_names = load_api_names(API_JSON)
    total_tags = 0
    total_stubs = 0
    total_lines = 0

    for filepath in sorted(EXAMPLES_DIR.glob('*.lua')):
        module = find_module_for_file(filepath.name)
        if not module or module not in api_names:
            continue
        tags_fixed, stubs_removed, lines_removed = fix_file(filepath, api_names)
        if tags_fixed > 0 or stubs_removed > 0:
            print(f"  {filepath.name}: tags_fixed={tags_fixed} stubs_removed={stubs_removed} lines_removed={lines_removed}")
        total_tags += tags_fixed
        total_stubs += stubs_removed
        total_lines += lines_removed

    print(f"\nTotal: tags_fixed={total_tags} stubs_removed={total_stubs} lines_removed={total_lines}")


if __name__ == '__main__':
    main()
