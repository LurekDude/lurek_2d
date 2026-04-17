#!/usr/bin/env python3
"""Fix Lurek2D TOML layout files.

Operations applied in order:

  1.  Remove all  widget_type = "separator"  widget blocks
      (text-based — preserves all comments and formatting in the rest of the file)

  2.  Detect sibling widgets whose bounding boxes overlap at the same parent level.

  3.  With --fix: auto-repair overlaps by pushing later siblings down to clear the gap,
      then re-snap everything to the 8-pixel grid.
      NOTE: --fix re-emits the entire TOML without original comments.  A backup
      is written next to each changed file as  <stem>.bak.toml  before overwriting.

Usage:
    # Dry-run: show what would change without writing anything
    python tools/ui/fix_layouts.py content/layouts/ --recursive --dry-run

    # Remove separators only (safe — preserves comments)
    python tools/ui/fix_layouts.py content/layouts/ --recursive

    # Remove separators AND fix detected overlaps (re-emits TOML, creates .bak)
    python tools/ui/fix_layouts.py content/layouts/ --recursive --fix

    # Single file
    python tools/ui/fix_layouts.py content/layouts/games/xcom_research.toml --fix

Exit codes:
    0 — success
    1 — one or more files failed
"""
from __future__ import annotations

import argparse
import math
import re
import shutil
import sys
from pathlib import Path
from typing import Any

try:
    import tomllib  # type: ignore[import]
except ModuleNotFoundError:
    try:
        import tomli as tomllib  # type: ignore[import]
    except ModuleNotFoundError:
        print("ERROR: tomllib not found.  Python >= 3.11 includes it stdlib.", file=sys.stderr)
        sys.exit(1)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
GRID = 8  # pixel grid

# Matches the start of an array-of-tables block at the start of a line
_BLOCK_START_RE = re.compile(r"^(\[\[)", re.MULTILINE)

SEP_NEEDLE = 'widget_type = "separator"'


# ---------------------------------------------------------------------------
# 1 — Separator removal (text-based, preserves comments)
# ---------------------------------------------------------------------------

def remove_separators(text: str) -> tuple[str, int]:
    """Remove every [[...]] block that declares ``widget_type = "separator"``.

    Returns (modified_text, number_of_blocks_removed).
    The preamble (everything before the first ``[[``) is preserved intact.
    """
    # Split on positions just before each [[  that starts a line
    parts = re.split(r"(?=^\[\[)", text, flags=re.MULTILINE)

    preamble = parts[0]
    kept: list[str] = [preamble]
    removed = 0

    for block in parts[1:]:
        if SEP_NEEDLE in block:
            removed += 1
        else:
            kept.append(block)

    return "".join(kept), removed


# ---------------------------------------------------------------------------
# 2 — Overlap detection (TOML-parsed)
# ---------------------------------------------------------------------------

Rect = tuple[float, float, float, float]  # x, y, w, h


def _rect(widget: dict[str, Any], parent_x: float = 0.0, parent_y: float = 0.0) -> Rect:
    x = parent_x + float(widget.get("x", 0.0))
    y = parent_y + float(widget.get("y", 0.0))
    w = float(widget.get("w", 0.0))
    h = float(widget.get("h", 0.0))
    return x, y, w, h


def _overlaps(a: Rect, b: Rect) -> bool:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by


def _contains(outer: Rect, inner: Rect) -> bool:
    """Return True if outer fully contains inner (intentional layering pattern)."""
    ox, oy, ow, oh = outer
    ix, iy, iw, ih = inner
    return ox <= ix and oy <= iy and ox + ow >= ix + iw and oy + oh >= iy + ih


def _is_real_overlap(a: Rect, b: Rect) -> bool:
    """Return True only for partial overlaps — NOT pure containment.

    Containment (one widget fully inside another) is an intentional layering
    pattern (e.g. a panel background with sibling labels on top). We only want
    to flag actual layout bugs where two peer widgets are accidentally clipped.
    """
    if not _overlaps(a, b):
        return False
    if _contains(a, b) or _contains(b, a):
        return False
    return True


def _find_overlaps(
    widget: dict[str, Any],
    parent_x: float,
    parent_y: float,
    path: str,
) -> list[tuple[str, dict, dict, float, float]]:
    """Return list of (path, widget_a, widget_b, parent_x, parent_y) for each overlap."""
    own_x = parent_x + float(widget.get("x", 0.0))
    own_y = parent_y + float(widget.get("y", 0.0))

    results = []
    children: list[dict] = widget.get("children", [])
    n = len(children)

    for i in range(n):
        ra = _rect(children[i])
        for j in range(i + 1, n):
            rb = _rect(children[j])
            if _is_real_overlap(ra, rb):
                results.append((path, children[i], children[j], own_x, own_y))

    # Recurse
    for idx, child in enumerate(children):
        child_id = child.get("id") or child.get("widget_type", f"child{idx}")
        results.extend(
            _find_overlaps(child, own_x, own_y, f"{path}.children[{child_id}]")
        )

    return results


def detect_overlaps(data: dict[str, Any]) -> list[tuple[str, dict, dict, float, float]]:
    return _find_overlaps(data["root"], 0.0, 0.0, "root")


# ---------------------------------------------------------------------------
# 3 — Overlap fix (TOML tree, then re-emit)
# ---------------------------------------------------------------------------

def _fix_overlaps_in_children(children: list[dict[str, Any]]) -> int:
    """Resolve partial overlaps within a children list.

    For each overlapping pair, pushes the later widget:
    - Down (increase y) when the overlap is primarily vertical
    - Right (increase x) when the overlap is primarily horizontal

    Returns number of coordinate values changed.
    """
    changes = 0
    # Iterate repeatedly until no more overlaps (max 20 passes to avoid infinite loops)
    for _pass in range(20):
        made_change = False
        n = len(children)
        for i in range(n):
            for j in range(i + 1, n):
                wa = children[i]
                wb = children[j]
                ra = _rect(wa)
                rb = _rect(wb)
                if not _is_real_overlap(ra, rb):
                    continue
                # Choose axis: push in the direction of the SMALLER overlap
                # (minimum displacement to separate the two widgets).
                # Overlaps larger than 2×GRID are intentional layering — skip.
                ax, ay, aw, ah = ra
                bx, by, bw, bh = rb
                x_overlap = min(ax + aw, bx + bw) - max(ax, bx)
                y_overlap = min(ay + ah, by + bh) - max(ay, by)
                if min(x_overlap, y_overlap) > GRID * 2:
                    continue
                if y_overlap <= x_overlap:
                    # Smaller vertical gap → push the lower widget down
                    if by >= ay:
                        new_y = ay + ah
                    else:
                        new_y = by + bh
                    new_y = int(math.ceil(new_y / GRID)) * GRID
                    target = wb if by >= ay else wa
                    if float(target.get("y", 0.0)) < new_y:
                        target["y"] = float(new_y)
                        changes += 1
                        made_change = True
                else:
                    # Smaller horizontal gap → push the rightmost widget right
                    if bx >= ax:
                        new_x = ax + aw
                    else:
                        new_x = bx + bw
                    new_x = int(math.ceil(new_x / GRID)) * GRID
                    target = wb if bx >= ax else wa
                    if float(target.get("x", 0.0)) < new_x:
                        target["x"] = float(new_x)
                        changes += 1
                        made_change = True
        if not made_change:
            break
    return changes


def _fix_overlaps_recursive(widget: dict[str, Any]) -> int:
    changes = _fix_overlaps_in_children(widget.get("children", []))
    for child in widget.get("children", []):
        changes += _fix_overlaps_recursive(child)
    return changes


# ---------------------------------------------------------------------------
# TOML emitter (comment-less but structurally correct)
# ---------------------------------------------------------------------------

def _toml_val(v: Any) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        # Escape backslash and double-quote
        escaped = v.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(v, float):
        # Always emit with decimal point so TOML recognises it as float
        if v == int(v):
            return f"{v:.1f}"
        return repr(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, list):
        inner = ", ".join(_toml_val(x) for x in v)
        return f"[{inner}]"
    return repr(v)


def _emit_widget(
    widget: dict[str, Any],
    path: str,
    out: list[str],
    is_root_table: bool = False,
) -> None:
    if is_root_table:
        out.append(f"\n[{path}]")
    else:
        out.append(f"\n[[{path}]]")

    for k, v in widget.items():
        if k == "children":
            continue
        out.append(f"{k} = {_toml_val(v)}")

    child_path = path + ".children"
    for child in widget.get("children", []):
        _emit_widget(child, child_path, out, is_root_table=False)


def emit_toml(data: dict[str, Any]) -> str:
    out: list[str] = []

    # Top-level scalar keys (e.g. resolution)
    for k, v in data.items():
        if k != "root":
            out.append(f"{k} = {_toml_val(v)}")

    # [root] table
    _emit_widget(data["root"], "root", out, is_root_table=True)

    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------
# File-level processing
# ---------------------------------------------------------------------------

def process_file(path: Path, fix_overlaps: bool, dry_run: bool) -> bool:
    """Process a single TOML layout file.

    Returns True if the file was (or would be) modified.
    """
    text = path.read_text(encoding="utf-8")
    original = text
    modified = False
    label = str(path)

    # ── Step 1: remove separators (text-based) ──────────────────────────────
    new_text, sep_count = remove_separators(text)
    if sep_count:
        print(f"  {label}: removed {sep_count} separator block(s)")
        text = new_text
        modified = True

    # ── Step 2: detect overlaps ──────────────────────────────────────────────
    try:
        data = tomllib.loads(text)
    except Exception as exc:
        print(f"  {label}: TOML parse error — {exc}", file=sys.stderr)
        return False

    if "root" not in data:
        return modified

    overlaps = detect_overlaps(data)
    if overlaps:
        print(f"  {label}: {len(overlaps)} overlap(s) detected:")
        for (op, wa, wb, px, py) in overlaps:
            aid = wa.get("id") or wa.get("widget_type", "?")
            bid = wb.get("id") or wb.get("widget_type", "?")
            ra = _rect(wa)
            rb = _rect(wb)
            print(f"    [{op}]  '{aid}' ({ra[0]:.0f},{ra[1]:.0f}+{ra[2]:.0f}x{ra[3]:.0f})"
                  f"  ⟷  '{bid}' ({rb[0]:.0f},{rb[1]:.0f}+{rb[2]:.0f}x{rb[3]:.0f})")

    # ── Step 3: fix overlaps (optional, re-emits TOML) ──────────────────────
    if fix_overlaps and overlaps:
        n_fixed = _fix_overlaps_recursive(data["root"])
        if n_fixed:
            print(f"  {label}: fixed {n_fixed} overlap(s) — re-emitting TOML (comments lost, .bak written)")
            text = emit_toml(data)
            modified = True

    # ── Write ────────────────────────────────────────────────────────────────
    if modified and not dry_run:
        if fix_overlaps and overlaps:
            # Write backup before clobbering comments
            bak = path.with_suffix(".bak.toml")
            shutil.copy2(path, bak)
        path.write_text(text, encoding="utf-8")

    if modified and dry_run:
        print(f"  {label}: [dry-run] would write changes")

    return modified


# ---------------------------------------------------------------------------
# CLI helpers
# ---------------------------------------------------------------------------

def _collect_files(paths: list[str], recursive: bool) -> list[Path]:
    result: list[Path] = []
    for raw in paths:
        p = Path(raw)
        if p.is_file() and p.suffix == ".toml":
            result.append(p)
        elif p.is_dir():
            pattern = "**/*.toml" if recursive else "*.toml"
            result.extend(sorted(p.glob(pattern)))
        else:
            print(f"WARNING: {raw} not found or not a .toml — skipping", file=sys.stderr)
    return result


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "paths",
        nargs="+",
        metavar="PATH",
        help="TOML file(s) or director(ies) to process",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Recurse into subdirectories",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Auto-fix overlaps by pushing siblings down (re-emits TOML, writes .bak)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report changes without writing any files",
    )
    args = parser.parse_args()

    files = _collect_files(args.paths, args.recursive)
    if not files:
        print("No TOML files found.", file=sys.stderr)
        return 1

    changed = 0
    errors = 0
    for f in files:
        try:
            if process_file(f, fix_overlaps=args.fix, dry_run=args.dry_run):
                changed += 1
        except Exception as exc:
            print(f"ERROR {f}: {exc}", file=sys.stderr)
            errors += 1

    dry_tag = " [dry-run]" if args.dry_run else ""
    print(f"\nDone{dry_tag}. {changed}/{len(files)} file(s) modified.  {errors} error(s).")
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
