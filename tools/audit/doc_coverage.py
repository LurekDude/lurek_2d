#!/usr/bin/env python3
"""
doc_coverage.py — Lurek2D documentation coverage analytics.

Scans all public Rust items in src/ and all lurek.* Lua API functions,
counts those with doc comments (/// or ---), and reports coverage metrics.

Outputs:
  - Summary to stdout (total, covered, missing count, coverage %)
  - JSON metadata to logs/data/doc_coverage.json (use --output to change)

Usage:
    python tools/doc_coverage.py                 # summary + write JSON
    python tools/doc_coverage.py --report-missing  # list all missing items (exit 1 if any)
    python tools/doc_coverage.py --json          # print JSON to stdout instead of file
    python tools/doc_coverage.py --output FILE   # custom JSON output path
    python tools/doc_coverage.py --module NAME   # filter to one Rust module
    python tools/doc_coverage.py --lua-only      # only analyse Lua API coverage
    python tools/doc_coverage.py --rust-only     # only analyse Rust coverage
    python tools/doc_coverage.py --help

Exit codes:
    0  — success (or all items documented when --report-missing is used)
    1  — missing docs found (--report-missing only)
    2  — fatal error
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from datetime import datetime, timezone

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_DIR = WORKSPACE_ROOT / "src"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "logs" / "doc_coverage.json"

# Matches pub item declarations in Rust source
_PUB_ITEM_RE = re.compile(
    r"^pub(?:\([^)]*\))?\s+"
    r"(?:unsafe\s+|async\s+|const\s+|extern\s+\"[^\"]*\"\s+)?"
    r"(struct|enum|fn|trait|type|const|static|mod)"
    r"\s+([A-Za-z_][A-Za-z0-9_]*)"
)

# Matches lurek.* function registrations in Lua API source.
# _LUA_SET_RE matches lurek.set("name", ...) — catches functions AND module mounts.
# _LUA_SET2_RE matches only the well-known API table variables used in register()
#   functions (tbl, graphics, keyboard, mouse, gamepad, touch, overlay_tbl, system).
#   This avoids false positives from local return-table builders like t.set("x", ...)
#   or stats.set("drawcalls", ...) inside method closures.
_LUA_SET_RE = re.compile(r'lurek\.set\s*\(\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,')
_LUA_SET2_RE = re.compile(
    r'\b(?:tbl|graphics|keyboard|mouse|gamepad|touch|overlay_tbl|system)'
    r'\.set\s*\(\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,'
)
# Matches module-mount lines like `lurek.set("timer", tbl)?;` — these are namespace
# mounts, not individual function registrations, and need no per-function doc.
# Handles: bare variable names (tbl, parallax, ...)  AND `.clone()` variants (tbl.clone()).
_LUA_MOUNT_RE = re.compile(
    r'lurek\.set\s*\(\s*"[^"]+"\s*,\s*'
    r'[A-Za-z_][A-Za-z0-9_]*(?:\.clone\(\))?\s*\)'
)


# ──────────────────────────────────────────────────────────────────────────────
# Rust coverage
# ──────────────────────────────────────────────────────────────────────────────

def _collect_rust_items(src_dir: Path, module_filter: str | None) -> list[dict]:
    """Walk src/ and collect all public items with doc status."""
    items: list[dict] = []
    for rs_file in sorted(src_dir.rglob("*.rs")):
        rel = str(rs_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
        parts = rel.split("/")
        mod_name = parts[1] if len(parts) > 2 else "root"

        if module_filter and mod_name != module_filter:
            continue

        try:
            lines = rs_file.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        for i, line in enumerate(lines):
            stripped = line.strip()
            m = _PUB_ITEM_RE.match(stripped)
            if not m:
                continue
            kind = m.group(1)
            name = m.group(2)

            # Skip test modules and private-by-convention names
            if name.startswith("_") or kind == "mod":
                continue

            # Check if the line immediately before (walking back past blank lines)
            # has a /// doc comment
            has_doc = False
            for j in range(i - 1, max(i - 6, -1), -1):
                prev = lines[j].strip()
                if prev.startswith("///"):
                    has_doc = True
                    break
                if prev and not prev.startswith("//") and not prev.startswith("#["):
                    break  # hit real code — no doc comment

            items.append({
                "source": "rust",
                "module": mod_name,
                "file": rel,
                "line": i + 1,
                "kind": kind,
                "name": name,
                "has_doc": has_doc,
            })
    return items


# ──────────────────────────────────────────────────────────────────────────────
# Lua API coverage
# ──────────────────────────────────────────────────────────────────────────────

def _collect_lua_items(src_dir: Path) -> list[dict]:
    """Walk src/lua_api/ and collect exposed lurek.* functions with doc status."""
    lua_api_dir = src_dir / "lua_api"
    if not lua_api_dir.is_dir():
        return []

    items: list[dict] = []
    for rs_file in sorted(lua_api_dir.rglob("*.rs")):
        try:
            lines = rs_file.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        rel = str(rs_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")

        for i, line in enumerate(lines):
            stripped = line.strip()
            # Look for lurek.set("function_name", ...)
            m = _LUA_SET_RE.search(stripped) or _LUA_SET2_RE.search(stripped)
            if not m:
                continue
            fn_name = m.group(1)

            # Skip module-mount lines: lurek.set("module", tbl_var) — these are
            # namespace mounts, not individual API functions; they carry no
            # per-function doc obligation.
            if _LUA_MOUNT_RE.search(stripped):
                continue

            # Skip local-scope table builders: if `let tbl = lua.create_table()`
            # appears within the preceding 8 lines AND there is no `//` comment
            # appearing AFTER that create_table() call, then `tbl` is a temporary
            # return-value table (e.g. inside a method closure or a helper function),
            # not the register() API table.  The AFTER constraint is critical: a `///`
            # docstring for a parent dt.set() registration may appear a few lines
            # above the create_table() but must not count as a doc for the inner tbl.
            create_table_last = -1
            for k in range(max(i - 12, 0), i):
                if "let tbl = lua.create_table()" in lines[k]:
                    create_table_last = k
            has_nearby_create = create_table_last >= 0
            # Only count a comment as legitimising the tbl.set if it appears
            # AFTER the most recent create_table() call in the window.
            has_nearby_comment = any(
                (
                    lines[k].strip().startswith("/// ")
                    or lines[k].strip().startswith("// -- ")
                )
                and k > create_table_last
                for k in range(max(i - 4, 0), i)
            )
            if has_nearby_create and not has_nearby_comment:
                continue

            # Look backwards for a // comment describing the function
            has_doc = False
            for j in range(i - 1, max(i - 4, -1), -1):
                prev = lines[j].strip()
                if prev.startswith("//"):
                    has_doc = True
                    break
                if prev and not prev.startswith("#["):
                    break

            items.append({
                "source": "lua_api",
                "module": rs_file.stem,
                "file": rel,
                "line": i + 1,
                "kind": "fn",
                "name": fn_name,
                "has_doc": has_doc,
            })
    return items


# ──────────────────────────────────────────────────────────────────────────────
# Reporting
# ──────────────────────────────────────────────────────────────────────────────

def _summary(items: list[dict]) -> dict:
    total = len(items)
    covered = sum(1 for it in items if it["has_doc"])
    missing = total - covered
    pct = (covered / total * 100) if total else 0.0
    return {"total": total, "covered": covered, "missing": missing, "pct": round(pct, 1)}


def _print_summary(label: str, stats: dict) -> None:
    bar_len = 30
    filled = int(stats["pct"] / 100 * bar_len)
    bar = "#" * filled + "-" * (bar_len - filled)
    print(f"  {label:20s}  [{bar}]  {stats['covered']}/{stats['total']}  ({stats['pct']}%)")


def main() -> None:  # noqa: C901
    parser = argparse.ArgumentParser(
        description="Report docstring coverage for Lurek2D public API items.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--report-missing", action="store_true",
                        help="List items missing docs; exit 1 if any found")
    parser.add_argument("--json", action="store_true",
                        help="Print JSON to stdout instead of writing to file")
    parser.add_argument("--output", metavar="FILE", default=str(DEFAULT_OUTPUT),
                        help=f"JSON output path (default: {DEFAULT_OUTPUT})")
    parser.add_argument("--module", metavar="NAME",
                        help="Restrict Rust analysis to a single module directory name")
    parser.add_argument("--lua-only", action="store_true",
                        help="Only analyse Lua API bindings coverage")
    parser.add_argument("--rust-only", action="store_true",
                        help="Only analyse Rust public item coverage")
    args = parser.parse_args()

    if not SRC_DIR.is_dir():
        print(f"ERROR: src/ not found at {SRC_DIR}", file=sys.stderr)
        sys.exit(2)

    # Collect items
    rust_items: list[dict] = []
    lua_items: list[dict] = []

    if not args.lua_only:
        rust_items = _collect_rust_items(SRC_DIR, args.module)
    if not args.rust_only:
        lua_items = _collect_lua_items(SRC_DIR)

    all_items = rust_items + lua_items

    # Build JSON metadata
    rust_stats = _summary(rust_items)
    lua_stats = _summary(lua_items)
    all_stats = _summary(all_items)

    missing_items = [it for it in all_items if not it["has_doc"]]

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "summary": {
            "rust": rust_stats,
            "lua_api": lua_stats,
            "total": all_stats,
        },
        "missing": missing_items,
        "items": all_items,
    }

    # --json: print to stdout
    if args.json:
        print(json.dumps(payload, indent=2))
        return

    # --report-missing: list gaps
    if args.report_missing:
        if missing_items:
            print(f"Missing doc comments ({len(missing_items)} items):")
            for it in missing_items:
                print(f"  [{it['source']}:{it['module']}] {it['file']}:{it['line']}  {it['kind']} {it['name']}")
            sys.exit(1)
        else:
            print("All public items have doc comments.")
        return

    # Default: write JSON and print summary
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    print("Lurek2D Documentation Coverage")
    print("=" * 60)
    _print_summary("Rust public items", rust_stats)
    _print_summary("Lua API bindings", lua_stats)
    print("-" * 60)
    _print_summary("Total", all_stats)
    print("=" * 60)
    print(f"Metadata written -> {out_path.relative_to(WORKSPACE_ROOT)}")
    if missing_items:
        print(f"Run with --report-missing to list {len(missing_items)} uncovered item(s).")


if __name__ == "__main__":
    main()
