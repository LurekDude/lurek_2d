#!/usr/bin/env python3
"""
tools/fix/uncomment_examples.py
Lurek2D — Uncomment all code that is hidden inside Lua comment prefixes in
         content/examples/*.lua files.

Root cause of the problem:
  - content/examples/README.md said examples "are not runnable games" — this
    philosophy caused AI agents to write real API calls as comments instead of
    live code, making coverage-validation tools (is_covered) report false hits.
  - expand_examples.py's is_covered() read the full file text including `--`
    lines, so commented-out calls were counted as "covered" (already fixed in
    expand_examples.py in this session).

This script removes the comment prefix from lines that contain real Lua code:

  UNCOMMENT:
    `-- lurek.xxx.yyy()`               →  lurek.xxx.yyy()
    `-- lurek.xxx.yyy("arg")`          →  lurek.xxx.yyy("arg")
    `-- lurek.xxx.yyy() → boolean`     →  local yyy_result = lurek.xxx.yyy()
    `-- local x = expr`               →  local x = expr
    `-- obj:method()`                 →  obj:method()
    `--   indented code`              →  indented code   (removes 2-space indent prefix)
    comment with `— description`      →  converts em-dash to Lua `-- comment`

  KEEP as comment (text, not code):
    Section headers  `-- ─── Name ─────`    (contain ─ or ═ unicode chars)
    Documentation signature lines:
        `-- lurek.xxx.yyy(param_name) → type — long description`
        (has BOTH em-dash suffix description AND identifier-only args)
    Plain English description text

  REMOVE entirely:
    `-- This file is documentation code, not a runnable game.`
    `-- All lurek.xxx API methods demonstrated with code and comments.`

Usage:
    python tools/fix/uncomment_examples.py              # fix all files
    python tools/fix/uncomment_examples.py --dry-run    # preview diffs
    python tools/fix/uncomment_examples.py --module img # one file only
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXAMPLES_DIR = ROOT / "content" / "examples"

# ── Helpers ────────────────────────────────────────────────────────────────── #

# Lines to remove entirely
_REMOVE_PATTERNS: list[re.Pattern] = [
    re.compile(r"^\s*--\s+This file is documentation code, not a runnable game\.\s*$"),
    re.compile(r"^\s*--\s+All luna\.\w+ API methods demonstrated with code and comments\.\s*$"),
    re.compile(r"^\s*--\s+Includes all \d+ \w+.*added in.*\.\s*$"),
]

# Lines that are definitely section headers / structural separators (KEEP)
_SECTION_RE = re.compile(r"^\s*--.*[\u2500\u2501\u2550\u2015\u25A0]")  # box-drawing chars

# EM-DASH used for inline descriptions in API signatures (U+2014)
_EM_DASH = "\u2014"

# Non-breaking hyphen variant sometimes used
_LONG_DASH = "\u2013"


def _has_real_args(args_text: str) -> bool:
    """
    Return True if args_text contains actual Lua values (not just parameter names).
    Empty args (whitespace only) count as "real" (zero-argument call).
    """
    stripped = args_text.strip()
    if not stripped:
        return True  # empty parens: zero-arg call
    # Look for actual value indicators
    if re.search(r'"[^"]*"', stripped):   # string literal
        return True
    if re.search(r"'[^']*'", stripped):   # single-quoted string
        return True
    if re.search(r"\b\d+(?:\.\d+)?\b", stripped):  # number
        return True
    if re.search(r"\b(?:true|false|nil)\b", stripped):  # boolean/nil
        return True
    if re.search(r"\{", stripped):         # table constructor
        return True
    if re.search(r"[+\-\*/%]", stripped):  # arithmetic
        return True
    # All bare identifiers → likely a signature / doc placeholder
    return False


def _var_name_from(fn_name: str) -> str:
    """Derive a local variable name from a function name."""
    n = fn_name
    for prefix in ("get", "is", "has", "new", "create", "make", "fetch", "load"):
        if n.startswith(prefix) and len(n) > len(prefix):
            n = n[len(prefix):]
            break
    # camelCase → snake_case
    n = re.sub(r"([A-Z])", lambda m: "_" + m.group(0).lower(), n).lstrip("_")
    return n or "result"


def _has_return_annotation(line: str) -> tuple[bool, str]:
    """
    Check if a line has `→ type` return annotation.
    Returns (has_annotation, return_type_string).
    """
    m = re.search(r"\s*\u2192\s*(.+?)(?:\s+[\u2014\u2013]|$)", line)
    if m:
        ret_type = m.group(1).strip()
        return True, ret_type
    return False, ""


def _has_em_dash_description(line: str) -> bool:
    """Return True if the line has an em-dash (— or –) inline description."""
    return _EM_DASH in line or _LONG_DASH in line


def _strip_return_annotation(call_part: str) -> str:
    """Remove `→ type` suffix from a call string."""
    return re.sub(r"\s*\u2192\s*\S+.*", "", call_part).rstrip()


def _em_dash_to_comment(text: str) -> str:
    """Convert `expr   — description` → `expr   -- description`."""
    # Replace em-dash (and surrounding spaces) with Lua comment `--`
    text = re.sub(r"\s*\u2014\s*", "  -- ", text)
    text = re.sub(r"\s*\u2013\s*", "  -- ", text)
    return text


# ── Core line transformer ─────────────────────────────────────────────────── #

def transform_line(line: str) -> str | None:
    """
    Process one line.  Returns:
      - None           → remove the line entirely
      - original line  → keep as-is (text comment or already live code)
      - new string     → replacement text (uncommented code)
    """
    raw = line
    stripped = line.strip()

    # Not a comment at all → keep
    if not stripped.startswith("--"):
        return raw

    # ── Remove-entirely patterns ──────────────────────────────────────────── #
    for pat in _REMOVE_PATTERNS:
        if pat.match(stripped):
            return None  # delete line

    # ── Section headers (box-drawing chars) → keep ────────────────────────── #
    if _SECTION_RE.match(stripped):
        return raw

    # ── Detect the comment content ─────────────────────────────────────────── #
    # Strip the leading `-- ` (or `--  ` / `--   ` / `-- ` with 1-3 spaces)
    m_prefix = re.match(r"^(\s*)(--\s{1,3})(.*)", stripped, re.DOTALL)
    if not m_prefix:
        # `--content` with no space or other format → keep
        return raw

    indent = m_prefix.group(1)        # leading whitespace
    _comment_marker = m_prefix.group(2)  # `-- ` etc.
    content = m_prefix.group(3)       # everything after `-- `

    # ── Indented code blocks (`--   code`, 2+ extra spaces) ─────────────── #
    m_indented = re.match(r"^(--\s{2,})(\S)", stripped)
    if m_indented:
        # Remove `-- ` and the extra whitespace (keep 0-width indent reset)
        extra = m_indented.group(1)       # `--  ` or `--   `
        real_code = stripped[len(extra):]  # code without the `--  ` prefix
        real_code = _em_dash_to_comment(real_code)
        return indent + real_code + "\n" if raw.endswith("\n") else indent + real_code

    # ── `-- lurek.xxx.yyy(...)` patterns ──────────────────────────────────── #
    m_luna = re.match(
        r"^(luna\.\w+[\.\:]\w+)\s*\(([^)]*)\)(.*)", content
    )
    if m_luna:
        call_base = m_luna.group(1)       # e.g. `lurek.simulator.pause`
        args_text = m_luna.group(2)       # e.g. `"menu_demo"` or `` or `name`
        remainder = m_luna.group(3).strip()  # e.g. `→ boolean  — description`

        fn_name = call_base.split(".")[-1].split(":")[-1]

        has_real = _has_real_args(args_text)
        has_ret, ret_type = _has_return_annotation(remainder)
        has_desc = _has_em_dash_description(remainder)

        # If args are identifier-only (not real values) AND there's a description
        # → this is a documentation signature line, NOT actual code → KEEP
        if not has_real and has_desc:
            return raw

        # It's real code (empty args OR real values); uncomment it
        call_str = f"{call_base}({args_text})"
        suffix = ""
        prefix = indent

        if has_ret and ret_type and ret_type not in ("nil", "self"):
            varname = _var_name_from(fn_name)
            # Handle multiple return: `→ w, h` or `→ x, y, z`
            if "," in ret_type:
                varname = ", ".join(
                    _var_name_from(v.strip()) for v in ret_type.split(",")
                )
            prefix = indent + f"local {varname} = "
            # remove → annotation from remainder
            remainder_clean = re.sub(r"\s*\u2192\s*\S+.*", "", remainder).strip()
            if remainder_clean:
                suffix = "  " + _em_dash_to_comment(remainder_clean).strip()
        else:
            # Void call — keep any em-dash description as Lua comment
            clean_rem = re.sub(r"\s*\u2192\s*\S+.*", "", remainder).strip()
            if clean_rem:
                suffix = "  " + _em_dash_to_comment(clean_rem).strip()

        new_line = prefix + call_str + suffix
        if raw.endswith("\n"):
            new_line += "\n"
        return new_line

    # ── `-- local x = ...` ────────────────────────────────────────────────── #
    m_local = re.match(r"^(local\s+\w+\s*=\s*)(.+)", content)
    if m_local:
        new_line = indent + content
        new_line = _em_dash_to_comment(new_line)
        if raw.endswith("\n"):
            new_line += "\n"
        return new_line

    # ── `-- obj:method(...)` bare method calls ────────────────────────────── #
    m_method = re.match(
        r"^(\w+(?:\.\w+)*)(:)(\w+)\s*\(([^)]*)\)(.*)", content
    )
    if m_method:
        obj = m_method.group(1)
        sep = m_method.group(2)
        method = m_method.group(3)
        args_text = m_method.group(4)
        remainder = m_method.group(5).strip()

        has_real = _has_real_args(args_text)
        has_ret, ret_type = _has_return_annotation(remainder)
        has_desc = _has_em_dash_description(remainder)

        # Documentation signature line: identifier-only args + description → KEEP
        if not has_real and has_desc:
            return raw

        call_str = f"{obj}{sep}{method}({args_text})"
        suffix = ""
        prefix = indent

        if has_ret and ret_type and ret_type not in ("nil", "self"):
            varname = _var_name_from(method)
            if "," in ret_type:
                varname = ", ".join(
                    _var_name_from(v.strip()) for v in ret_type.split(",")
                )
            prefix = indent + f"local {varname} = "
            clean_rem = re.sub(r"\s*\u2192\s*\S+.*", "", remainder).strip()
            if clean_rem:
                suffix = "  " + _em_dash_to_comment(clean_rem).strip()
        else:
            clean_rem = re.sub(r"\s*\u2192\s*\S+.*", "", remainder).strip()
            if clean_rem:
                suffix = "  " + _em_dash_to_comment(clean_rem).strip()

        new_line = prefix + call_str + suffix
        if raw.endswith("\n"):
            new_line += "\n"
        return new_line

    # Everything else → keep as-is (plain English description)
    return raw


# ── File processor ─────────────────────────────────────────────────────────── #

def process_file(path: Path, dry_run: bool = False) -> bool:
    """Process one file. Returns True if file was (or would be) changed."""
    original_text = path.read_text(encoding="utf-8")
    lines = original_text.splitlines(keepends=True)

    new_lines: list[str] = []
    changed = False
    for line in lines:
        result = transform_line(line)
        if result is None:
            changed = True   # line deleted
            continue
        if result != line:
            changed = True
        new_lines.append(result)

    if not changed:
        return False

    new_text = "".join(new_lines)

    if dry_run:
        # Use ascii-safe repr for diff output to avoid Windows cp1250 errors
        old_lines = original_text.splitlines()
        new_split = new_text.splitlines()
        print(f"  [DRY-RUN] Would change {path.name} "
              f"({len(old_lines)} -> {len(new_split)} lines)")
        printed = 0
        new_i = 0
        for old_line in old_lines:
            if new_i < len(new_split) and old_line == new_split[new_i]:
                new_i += 1
                continue
            if printed < 6:
                print(f"    DEL: {repr(old_line)[:100]}")
                if new_i < len(new_split) and new_split[new_i] != (
                    old_lines[min(old_lines.index(old_line) + 1, len(old_lines) - 1)]
                ):
                    print(f"    ADD: {repr(new_split[new_i])[:100]}")
                    new_i += 1
            printed += 1
        if printed > 6:
            print(f"    ... and {printed - 6} more changes")
    else:
        path.write_text(new_text, encoding="utf-8")

    return True


# ── README fix ─────────────────────────────────────────────────────────────── #

def fix_readme(dry_run: bool) -> None:
    """Remove the 'not runnable games' sentence from content/examples/README.md."""
    readme = EXAMPLES_DIR / "README.md"
    if not readme.exists():
        print(f"[WARN] README not found: {readme}")
        return

    text = readme.read_text(encoding="utf-8")
    # Replace the problematic line (may contain various dash/arrow characters)
    new_text = re.sub(
        r"They are not runnable games[^\n]*they are meant to be read[^\n]*\n",
        "All API calls in these files are live, executable Lua code — not comments.\n",
        text,
        flags=re.IGNORECASE,
    )
    if new_text != text:
        if not dry_run:
            readme.write_text(new_text, encoding="utf-8")
        print(f"[FIX] README.md — removed 'not runnable games' line")
    else:
        print(f"[OK ] README.md — no 'not runnable games' sentence found")


# ── Main ───────────────────────────────────────────────────────────────────── #

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would change, but don't write files")
    parser.add_argument("--module", metavar="NAME",
                        help="Only process files matching this substring")
    args = parser.parse_args()

    if not EXAMPLES_DIR.exists():
        sys.exit(f"ERROR: examples dir not found: {EXAMPLES_DIR}")

    fix_readme(args.dry_run)

    changed = 0
    total = 0
    for path in sorted(EXAMPLES_DIR.glob("*.lua")):
        if args.module and args.module.lower() not in path.stem.lower():
            continue
        total += 1
        was_changed = process_file(path, args.dry_run)
        if was_changed:
            changed += 1
            if not args.dry_run:
                print(f"[FIX] {path.name}")
        else:
            print(f"[OK ] {path.name}")

    action = "Would fix" if args.dry_run else "Fixed"
    print(f"\n{action} {changed}/{total} files")


if __name__ == "__main__":
    main()
