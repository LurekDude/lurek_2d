#!/usr/bin/env python3
"""
fix_docstrings.py — Auto-fill missing # Parameters / # Returns / # Fields /
# Variants sections in existing Lurek2D Rust doc comments.

For items that have NO documentation at all, a minimal starter /// comment is
injected.  For items that have a description but are missing structural sections
the missing sections are appended to the existing doc comment in-place.

Usage:
    python tools/fix_docstrings.py            # fix all issues
    python tools/fix_docstrings.py --dry-run  # preview only, no file writes

Exit codes:
    0 — success (or no changes needed)
    1 — error
"""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Bootstrap: add tools/ to path so we can import collect_docs
# ---------------------------------------------------------------------------
sys.path.insert(0, str(Path(__file__).parent))

from collect_docs import (  # noqa: E402
    ApiItem,
    StructField,
    collect_all,
    SRC_DIR,
    WORKSPACE_ROOT,
    _has_explicit_params,
    _has_return_type,
)

# ---------------------------------------------------------------------------
# Parameter / return-type extraction
# ---------------------------------------------------------------------------

def _extract_params(sig: str) -> list[tuple[str, str]]:
    """Return (name, type_str) pairs for every non-self parameter in sig."""
    # Use a depth-aware scan to find the outermost () so that generics in
    # parameter types (e.g. Option<Vec<f32>>) are handled correctly.
    start = sig.find("(")
    if start == -1:
        return []
    depth = 0
    end = -1
    for idx in range(start, len(sig)):
        ch = sig[idx]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                end = idx
                break

    if end == -1:
        # Signature was truncated (e.g. a type like [f32; 4] caused _collect_signature
        # to stop early before the closing ')').  Use the truncated content anyway —
        # it contains enough for the param names we need.
        params_str = sig[start + 1 :]
    else:
        params_str = sig[start + 1 : end]
    result: list[tuple[str, str]] = []

    # Split by comma at depth 0 (handles generics like Fn(x: i32) -> ())
    parts: list[str] = []
    buf = ""
    angle = 0
    paren = 0
    for ch in params_str:
        if ch in "<([":
            if ch == "<":
                angle += 1
            else:
                paren += 1
            buf += ch
        elif ch in ">)]":
            if ch == ">":
                angle -= 1
            else:
                paren -= 1
            buf += ch
        elif ch == "," and angle == 0 and paren == 0:
            parts.append(buf.strip())
            buf = ""
        else:
            buf += ch
    if buf.strip():
        parts.append(buf.strip())

    for p in parts:
        if not p:
            continue
        # Skip self / &self / &mut self
        if re.match(r"^(&\s*(mut\s+)?)?self\s*$", p):
            continue
        # Strip leading mut
        p2 = re.sub(r"^mut\s+", "", p)
        colon = p2.find(":")
        if colon != -1:
            name = p2[:colon].strip()
            typ = p2[colon + 1 :].strip()
            result.append((name, typ))
        else:
            result.append((p2.strip(), ""))
    return result


def _extract_return_type(sig: str) -> str:
    """Return the return-type string from a fn signature, or '' if none."""
    m = re.search(r"\)\s*->\s*(.+)$", sig.strip())
    if not m:
        return ""
    ret = m.group(1).strip()
    return ret if ret != "()" else ""


# ---------------------------------------------------------------------------
# Source-file manipulation helpers
# ---------------------------------------------------------------------------

def _find_doc_end_line(lines: list[str], item_line_0: int) -> int:
    """
    Walk backwards from item_line_0 (0-based declaration line) over #[...]
    attributes and /// comment lines. Return the 0-based index of the LAST
    /// line found, or -1 if no doc comment exists.
    """
    i = item_line_0 - 1
    last_doc = -1
    while i >= 0:
        stripped = lines[i].strip()
        if stripped.startswith("///"):
            last_doc = i
            i -= 1
        elif stripped.startswith("#[") or stripped.startswith("#!"):
            i -= 1
        else:
            break
    return last_doc


def _indent_of(line: str) -> str:
    """Return the leading whitespace of line."""
    return line[: len(line) - len(line.lstrip())]


# ---------------------------------------------------------------------------
# Section-content builders
# ---------------------------------------------------------------------------

def _build_params_lines(sig: str) -> list[str]:
    params = _extract_params(sig)
    if not params:
        return []
    out = ["///", "/// # Parameters"]
    for name, typ in params:
        if typ:
            out.append(f"/// - `{name}` — `{typ}`.")
        else:
            out.append(f"/// - `{name}` — parameter.")
    return out


def _build_returns_lines(sig: str) -> list[str]:
    ret = _extract_return_type(sig)
    if not ret:
        return []
    return ["///", "/// # Returns", f"/// `{ret}`."]


def _build_fields_lines(item: ApiItem) -> list[str]:
    pub_fields = [f for f in item.fields if f.is_pub]
    if not pub_fields:
        return []
    out = ["///", "/// # Fields"]
    for fld in pub_fields:
        out.append(f"/// - `{fld.name}` — `{fld.type_str}`.")
    return out


def _build_variants_lines(item: ApiItem) -> list[str]:
    if not item.variants:
        return []
    out = ["///", "/// # Variants"]
    for v in item.variants:
        out.append(f"/// - `{v.name}` — {v.name} variant.")
    return out


def _collect_missing_section_lines(item: ApiItem) -> list[str]:
    """Return the extra /// lines to append, based on which sections are absent."""
    has = {s.lower() for s in item.sections}
    new: list[str] = []

    if item.kind == "fn":
        if _has_explicit_params(item.signature) and "parameters" not in has:
            new.extend(_build_params_lines(item.signature))
        if _has_return_type(item.signature) and "returns" not in has:
            new.extend(_build_returns_lines(item.signature))

    elif item.kind == "struct":
        pub_fields = [f for f in item.fields if f.is_pub]
        if pub_fields and "fields" not in has:
            new.extend(_build_fields_lines(item))

    elif item.kind == "enum":
        if item.variants and "variants" not in has:
            new.extend(_build_variants_lines(item))

    return new


def _build_full_stub(item: ApiItem) -> list[str]:
    """Build a complete starter doc comment for an entirely undocumented item."""
    base_name = item.name.split("::")[-1]
    out = [f"/// {base_name}."]

    sect = _collect_missing_section_lines(item)
    out.extend(sect)
    return out


# ---------------------------------------------------------------------------
# File-level fix
# ---------------------------------------------------------------------------

def _fix_file(path: Path, file_items: list[ApiItem], dry_run: bool) -> int:
    """
    Apply missing-section fixes to a single file.

    Items are processed in descending line order so that each insertion does
    not disturb the (still-original) line references of not-yet-processed items
    earlier in the file.

    Returns the number of items that were (or would be) modified.
    """
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    trailing_newline = text.endswith("\n")

    # Sort highest line first so earlier items keep correct indices
    sorted_items = sorted(file_items, key=lambda x: x.line, reverse=True)

    fixes = 0
    for item in sorted_items:
        item_line_0 = item.line - 1  # convert to 0-based

        if not item.description:
            # ── Fully undocumented: inject a new /// comment block ──────────
            stub_lines = _build_full_stub(item)
            if not stub_lines:
                continue
            # Determine indentation from the pub declaration line
            pub_line = lines[item_line_0] if item_line_0 < len(lines) else ""
            indent = _indent_of(pub_line)
            indented = [indent + l for l in stub_lines]
            lines = lines[:item_line_0] + indented + lines[item_line_0:]
            fixes += 1
        else:
            # ── Has docs: append missing sections ──────────────────────────
            new_section_lines = _collect_missing_section_lines(item)
            if not new_section_lines:
                continue

            last_doc = _find_doc_end_line(lines, item_line_0)
            if last_doc == -1:
                # Shouldn't happen (item has description so there must be ///
                # lines), but guard anyway.
                continue

            # Inherit indent from the existing doc comment
            indent = _indent_of(lines[last_doc])
            indented = [indent + l for l in new_section_lines]
            lines = lines[: last_doc + 1] + indented + lines[last_doc + 1 :]
            fixes += 1

    if fixes > 0 and not dry_run:
        result = "\n".join(lines)
        if trailing_newline:
            result += "\n"
        path.write_text(result, encoding="utf-8")

    return fixes


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    dry_run = "--dry-run" in sys.argv

    print(f"[INFO] {'DRY RUN — ' if dry_run else ''}Collecting items from {SRC_DIR} …")
    items = collect_all(SRC_DIR)
    print(f"[INFO] Found {len(items)} public items total.")

    by_file: dict[Path, list[ApiItem]] = defaultdict(list)

    for item in items:
        has = {s.lower() for s in item.sections}
        needs_fix = False

        if not item.description:
            needs_fix = True
        elif item.kind == "fn":
            if _has_explicit_params(item.signature) and "parameters" not in has:
                needs_fix = True
            if _has_return_type(item.signature) and "returns" not in has:
                needs_fix = True
        elif item.kind == "struct":
            pub_fields = [f for f in item.fields if f.is_pub]
            if pub_fields and "fields" not in has:
                needs_fix = True
        elif item.kind == "enum":
            if item.variants and "variants" not in has:
                needs_fix = True

        if needs_fix:
            by_file[item.file].append(item)

    total_items = sum(len(v) for v in by_file.values())
    print(
        f"[INFO] {total_items} items need section fixes across {len(by_file)} files."
    )

    total_fixes = 0
    for rel_path in sorted(by_file):
        abs_path = WORKSPACE_ROOT / rel_path
        n = _fix_file(abs_path, by_file[rel_path], dry_run)
        tag = "[DRY]" if dry_run else "[FIX]"
        print(f"  {tag} {rel_path}: {n} items updated")
        total_fixes += n

    print(f"\n[INFO] Done. {total_fixes} items updated{' (dry run)' if dry_run else ''}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
