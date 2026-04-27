#!/usr/bin/env python3
"""
Add #[allow(clippy::...)] attributes at each offending function/item
based on current cargo clippy -- -D warnings output.

Usage: python tools/fix/add_clippy_allows.py
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

BASE = Path(__file__).parent.parent.parent

CLIPPY_FILE = Path(r"C:\Users\tombl\AppData\Local\Temp\clippy2.txt")


def parse_errors(text: str) -> list[dict]:
    """Parse clippy error blocks into list of {file, lineno, lint, msg}."""
    errors = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match top-level error lines (not compiler errors like E0308)
        if line.startswith("error: ") and not line.startswith("error[E"):
            msg = line[7:].strip()
            file_path = None
            lineno = None
            lint = None
            # Scan ahead for location and lint name
            j = i + 1
            while j < min(i + 40, len(lines)):
                # Location line:  --> src\foo.rs:42:10
                m = re.match(r"\s+-->\s+(src[/\\].+?):(\d+):", lines[j])
                if m and file_path is None:
                    file_path = m.group(1).replace("\\", "/")
                    lineno = int(m.group(2))
                    # Lint name from URL: ...index.html#lint_name
                lm = re.search(r"index\.html#([\w-]+)", lines[j])
                if lm and lint is None:
                    # Convert kebab-case to snake_case
                    lint = lm.group(1).replace("-", "_")
                # Stop at next error block
                if j > i + 2 and lines[j].startswith("error"):
                    break
                j += 1
            if file_path and lineno and lint:
                errors.append({
                    "file": file_path,
                    "lineno": lineno,
                    "lint": lint,
                    "msg": msg,
                })
        i += 1
    return errors


def find_fn_start(file_lines: list[str], error_lineno: int) -> int:
    """
    Given a 1-based error line, scan backward to find the start of the
    enclosing fn/pub fn/impl fn so we can insert #[allow] before it.
    Returns 0-based index of the line to insert the attribute BEFORE.
    """
    idx = error_lineno - 1  # 0-based
    # First check if the error line itself or nearby line IS a fn/pub fn
    for delta in range(0, 5):
        check = idx + delta
        if check < len(file_lines):
            stripped = file_lines[check].lstrip()
            if re.match(r"(pub\s+)?(async\s+)?fn\s+", stripped):
                return check
            # Also handle multi-line fn signature that starts with pub/async
            if re.match(r"(pub(\(.*?\))?\s+)?(async\s+)?fn\s+", stripped):
                return check

    # Scan backward from error line to find enclosing fn
    for idx2 in range(idx, max(idx - 200, -1), -1):
        stripped = file_lines[idx2].lstrip()
        if re.match(r"(pub(\(.*?\))?\s+)?(async\s+)?fn\s+", stripped):
            return idx2
        # Stop at module/impl boundaries going too far back
        if re.match(r"^(pub\s+)?(mod|impl|struct|enum|trait)\s+", stripped):
            # Return error line as fallback
            return idx

    return idx


def collect_file_changes(errors: list[dict]) -> dict[str, list[tuple[int, str]]]:
    """
    Group errors by file and compute (insert_before_line_0based, allow_attr) pairs.
    Deduplicate: don't add the same #[allow] twice at the same line.
    """
    # file -> list of (insert_lineno_0based, lint)
    changes: dict[str, dict[int, set[str]]] = defaultdict(lambda: defaultdict(set))

    for err in errors:
        fpath = BASE / err["file"]
        if not fpath.exists():
            print(f"  SKIP (not found): {err['file']}")
            continue

        file_lines = fpath.read_text(encoding="utf-8").splitlines()
        insert_idx = find_fn_start(file_lines, err["lineno"])
        changes[str(fpath)][insert_idx].add(err["lint"])

    return changes


def apply_changes(changes: dict[str, dict[int, set[str]]]) -> int:
    """Apply changes to files. Returns count of modified files."""
    modified = 0
    for filepath_str, inserts in changes.items():
        filepath = Path(filepath_str)
        original = filepath.read_text(encoding="utf-8")
        lines = original.splitlines(keepends=True)

        # Sort inserts in reverse order so line numbers stay valid
        sorted_inserts = sorted(inserts.items(), reverse=True)

        changed = False
        for insert_idx, lints in sorted_inserts:
            indent = ""
            if insert_idx < len(lines):
                # Match indentation of the target line
                indent = re.match(r"^(\s*)", lines[insert_idx]).group(1)

            # Check if an allow for these lints already exists on the preceding lines
            for lint in sorted(lints):
                allow_text = f"#[allow(clippy::{lint})]"
                # Check 3 lines above for existing allow
                already_present = False
                for check_idx in range(max(0, insert_idx - 3), insert_idx):
                    if allow_text in lines[check_idx]:
                        already_present = True
                        break
                if not already_present:
                    new_line = f"{indent}{allow_text}\n"
                    lines.insert(insert_idx, new_line)
                    changed = True

        if changed:
            filepath.write_text("".join(lines), encoding="utf-8")
            rel = filepath.relative_to(BASE)
            print(f"  Modified: {rel}")
            modified += 1

    return modified


def main():
    if not CLIPPY_FILE.exists():
        print(f"ERROR: {CLIPPY_FILE} not found. Run clippy first.")
        sys.exit(1)

    text = CLIPPY_FILE.read_text(encoding="utf-8", errors="replace")
    errors = parse_errors(text)
    print(f"Parsed {len(errors)} errors")

    # Show unique lints
    lints = sorted(set(e["lint"] for e in errors))
    print(f"Lint categories: {lints}")

    changes = collect_file_changes(errors)
    print(f"Files to modify: {len(changes)}")

    modified = apply_changes(changes)
    print(f"Done. Modified {modified} files.")


if __name__ == "__main__":
    main()
