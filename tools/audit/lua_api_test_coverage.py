#!/usr/bin/env python3
"""
lua_api_test_coverage.py — Precise Lua API test coverage analysis.

Cross-references the canonical Lua API surface (from lua_api_data.json) against
test files using both @covers markers and heuristic fallback matching.

Usage:
    python tools/audit/lua_api_test_coverage.py                    # hybrid summary
    python tools/audit/lua_api_test_coverage.py --strict           # markers only
    python tools/audit/lua_api_test_coverage.py --json             # JSON output
    python tools/audit/lua_api_test_coverage.py --module graphics  # single module
    python tools/audit/lua_api_test_coverage.py --suggest          # stub generation
    python tools/audit/lua_api_test_coverage.py --report           # full markdown report
    python tools/audit/lua_api_test_coverage.py --orphans          # show orphaned markers

Exit codes:
    0  - success (or coverage >= threshold)
    1  - coverage below threshold
    2  - fatal error
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
LUA_API_DATA = WORKSPACE_ROOT / "docs" / "logs" / "lua_api_data.json"
LUA_TESTS_DIR = WORKSPACE_ROOT / "tests" / "lua"
OUTPUT_JSON = WORKSPACE_ROOT / "docs" / "logs" / "lua_api_test_coverage.json"

# Regex for @covers markers: -- @covers lurek.math.sin  OR  -- @covers Vec2:length
COVERS_RE = re.compile(
    r"^--\s*@covers\s+((?:lurek\.\w+\.\w+)|(?:\w+:\w+))\s*$"
)

# Regex for @evidence markers
EVIDENCE_RE = re.compile(
    r"^--\s*@evidence\s+(\w+):(.+)\s*$"
)

# Regex for @golden markers
GOLDEN_RE = re.compile(
    r"^--\s*@golden\s+(.+)\s*$"
)

# Regex for @stress markers
STRESS_RE = re.compile(
    r"^--\s*@stress\s+(.+)\s*$"
)


def load_api_data(path: Path) -> Dict:
    """Load the canonical Lua API data from JSON."""
    if not path.exists():
        print(f"[ERROR] API data not found: {path}", file=sys.stderr)
        print("[INFO] Run: python tools/docs/gen_lua_api_data.py", file=sys.stderr)
        sys.exit(2)
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def collect_api_functions(api_data: Dict, module_filter: Optional[str] = None) -> List[Dict]:
    """Extract flat list of all API functions/methods from the JSON data."""
    modules = api_data.get("lua_api", {}).get("modules", {})
    items = []

    for mod_name, mod_data in sorted(modules.items()):
        if module_filter and mod_name != module_filter:
            continue

        # Top-level functions
        for func in mod_data.get("functions", []):
            items.append({
                "module": mod_name,
                "name": func["name"],
                "lua_name": func["lua_name"],
                "kind": func["kind"],
                "owner_type": func.get("owner_type", ""),
                "file": func.get("file", ""),
                "line": func.get("line", 0),
            })

        # Class methods
        for cls_name, cls_data in mod_data.get("classes", {}).items():
            for method in cls_data.get("methods", []):
                items.append({
                    "module": mod_name,
                    "name": method["name"],
                    "lua_name": method["lua_name"],
                    "kind": method["kind"],
                    "owner_type": method.get("owner_type", cls_name),
                    "file": method.get("file", ""),
                    "line": method.get("line", 0),
                })

    return items


def scan_markers(tests_dir: Path) -> Dict[str, List[Dict]]:
    """Scan all Lua test files for @covers markers.

    Returns: {test_file_rel_path: [{"marker": "lurek.math.sin", "line": 5}, ...]}
    """
    results: Dict[str, List[Dict]] = {}

    for lua_file in sorted(tests_dir.rglob("*.lua")):
        rel = str(lua_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
        markers = []

        try:
            lines = lua_file.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        for i, line in enumerate(lines):
            m = COVERS_RE.match(line.strip())
            if m:
                markers.append({
                    "marker": m.group(1),
                    "line": i + 1,
                })

        if markers:
            results[rel] = markers

    return results


def normalize_api_name(lua_name: str) -> str:
    """Normalize an API name for matching.

    "lurek.math.sin" -> "lurek.math.sin"
    "Vec2:length" -> "Vec2:length"
    """
    return lua_name.strip()


def build_marker_coverage(
    api_functions: List[Dict],
    marker_data: Dict[str, List[Dict]],
) -> Tuple[Set[str], Dict[str, List[str]], List[Dict]]:
    """Match @covers markers against canonical API list.

    Returns:
        covered_names: set of lua_name strings that have markers
        coverage_map: {lua_name: [test_files]}
        orphans: list of {"file", "line", "marker"} for unmatched markers
    """
    # Build lookup sets
    canonical_names: Set[str] = set()
    for fn in api_functions:
        canonical_names.add(fn["lua_name"])

    covered_names: Set[str] = set()
    coverage_map: Dict[str, List[str]] = {}
    orphans: List[Dict] = []

    for test_file, markers in marker_data.items():
        for entry in markers:
            marker = entry["marker"]
            if marker in canonical_names:
                covered_names.add(marker)
                coverage_map.setdefault(marker, []).append(test_file)
            else:
                orphans.append({
                    "file": test_file,
                    "line": entry["line"],
                    "marker": marker,
                })

    return covered_names, coverage_map, orphans


def heuristic_coverage(
    api_functions: List[Dict],
    tests_dir: Path,
    already_covered: Set[str],
) -> Set[str]:
    """Heuristic substring matching for functions without @covers markers.

    Only applies to functions NOT already covered by markers.
    """
    # Load all test file contents
    test_contents: Dict[str, str] = {}
    for lua_file in sorted(tests_dir.rglob("*.lua")):
        try:
            test_contents[lua_file.stem] = lua_file.read_text(encoding="utf-8").lower()
        except OSError:
            continue

    heuristic_covered: Set[str] = set()

    for fn in api_functions:
        if fn["lua_name"] in already_covered:
            continue

        fn_name = fn["name"].lower()
        mod = fn["module"]

        # Skip very short names (high false-positive risk)
        if len(fn_name) <= 3:
            continue

        found = False
        # Check module-specific test files first
        for test_name, content in test_contents.items():
            if mod in test_name:
                if fn_name in content:
                    found = True
                    break

        # Check all test files
        if not found:
            for content in test_contents.values():
                if fn_name in content:
                    found = True
                    break

        if found:
            heuristic_covered.add(fn["lua_name"])

    return heuristic_covered


def generate_json_report(
    api_functions: List[Dict],
    marker_covered: Set[str],
    heuristic_covered_set: Set[str],
    orphans: List[Dict],
    coverage_map: Dict[str, List[str]],
    strict: bool,
    module_filter: Optional[str],
) -> Dict:
    """Generate structured JSON coverage report."""
    all_covered = marker_covered if strict else marker_covered | heuristic_covered_set
    total = len(api_functions)
    covered_count = sum(1 for fn in api_functions if fn["lua_name"] in all_covered)

    # Per-module stats
    mod_stats: Dict[str, Dict] = {}
    for fn in api_functions:
        mod = fn["module"]
        mod_stats.setdefault(mod, {
            "total": 0,
            "marker_covered": 0,
            "heuristic_covered": 0,
            "uncovered": [],
            "test_files": set(),
        })
        mod_stats[mod]["total"] += 1

        if fn["lua_name"] in marker_covered:
            mod_stats[mod]["marker_covered"] += 1
            for tf in coverage_map.get(fn["lua_name"], []):
                mod_stats[mod]["test_files"].add(tf)
        elif fn["lua_name"] in heuristic_covered_set and not strict:
            mod_stats[mod]["heuristic_covered"] += 1
        else:
            mod_stats[mod]["uncovered"].append({
                "lua_name": fn["lua_name"],
                "kind": fn["kind"],
                "file": fn["file"],
                "line": fn["line"],
            })

    # Convert sets to sorted lists for JSON
    modules_out = {}
    for mod_name, stats in sorted(mod_stats.items()):
        total_mod = stats["total"]
        covered_mod = stats["marker_covered"] + (0 if strict else stats["heuristic_covered"])
        modules_out[mod_name] = {
            "total": total_mod,
            "marker_covered": stats["marker_covered"],
            "heuristic_covered": stats["heuristic_covered"],
            "covered": covered_mod,
            "coverage_pct": round(covered_mod / total_mod * 100, 1) if total_mod else 100.0,
            "uncovered": stats["uncovered"],
            "test_files": sorted(stats["test_files"]),
        }

    return {
        "meta": {
            "generated": datetime.now(timezone.utc).isoformat(),
            "generator": "tools/audit/lua_api_test_coverage.py",
            "mode": "strict" if strict else "hybrid",
            "module_filter": module_filter,
            "total_api_functions": total,
            "marker_covered": len(marker_covered),
            "heuristic_covered": len(heuristic_covered_set) if not strict else 0,
            "total_covered": covered_count,
            "coverage_pct": round(covered_count / total * 100, 1) if total else 100.0,
        },
        "modules": modules_out,
        "orphaned_markers": orphans,
    }


def generate_markdown_report(report: Dict) -> str:
    """Generate human-readable markdown report from JSON data."""
    meta = report["meta"]
    lines = [
        "# Lua API Test Coverage Report",
        "",
        f"**Generated**: {meta['generated'][:10]}",
        f"**Mode**: {meta['mode']}",
        f"**Total API functions**: {meta['total_api_functions']}",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        f"| Marker-covered | {meta['marker_covered']} |",
    ]

    if meta["mode"] == "hybrid":
        lines.append(f"| Heuristic-covered | {meta['heuristic_covered']} |")

    lines.extend([
        f"| Total covered | {meta['total_covered']} |",
        f"| Coverage | {meta['coverage_pct']}% |",
        "",
        "## Per-Module Coverage",
        "",
        "| Module | Total | Marker | Heuristic | Covered | Coverage |",
        "|--------|-------|--------|-----------|---------|----------|",
    ])

    for mod_name, stats in sorted(report["modules"].items(),
                                   key=lambda x: x[1]["coverage_pct"]):
        lines.append(
            f"| {mod_name} | {stats['total']} | {stats['marker_covered']} | "
            f"{stats['heuristic_covered']} | {stats['covered']} | "
            f"{stats['coverage_pct']}% |"
        )

    lines.append("")

    # Uncovered by module (top gaps)
    uncovered_mods = [
        (mod, stats) for mod, stats in report["modules"].items()
        if stats["uncovered"]
    ]
    uncovered_mods.sort(key=lambda x: x[1]["coverage_pct"])

    if uncovered_mods:
        lines.extend([
            "## Uncovered Functions (lowest coverage first)",
            "",
        ])
        for mod_name, stats in uncovered_mods[:15]:
            lines.append(f"### {mod_name} ({stats['coverage_pct']}%)")
            lines.append("")
            for fn in stats["uncovered"][:20]:
                lines.append(f"- `{fn['lua_name']}` ({fn['kind']})")
            if len(stats["uncovered"]) > 20:
                lines.append(f"- ... and {len(stats['uncovered']) - 20} more")
            lines.append("")

    # Orphaned markers
    if report["orphaned_markers"]:
        lines.extend([
            "## Orphaned Markers (typos or removed APIs)",
            "",
        ])
        for orphan in report["orphaned_markers"]:
            lines.append(
                f"- `{orphan['marker']}` in `{orphan['file']}:{orphan['line']}`"
            )
        lines.append("")

    return "\n".join(lines)


def generate_suggestions(
    api_functions: List[Dict],
    covered: Set[str],
    module_filter: Optional[str],
) -> str:
    """Generate test stub suggestions for uncovered functions."""
    uncovered = [fn for fn in api_functions if fn["lua_name"] not in covered]

    if module_filter:
        uncovered = [fn for fn in uncovered if fn["module"] == module_filter]

    if not uncovered:
        return "# All API functions have test coverage!\n"

    lines = ["# Test Stub Suggestions", ""]

    by_module: Dict[str, List[Dict]] = {}
    for fn in uncovered:
        by_module.setdefault(fn["module"], []).append(fn)

    for mod_name, fns in sorted(by_module.items()):
        lines.append(f"## {mod_name} ({len(fns)} uncovered)")
        lines.append("")
        lines.append("```lua")

        for fn in fns[:15]:
            marker = fn["lua_name"]
            lines.append(f"-- @covers {marker}")

            if fn["kind"] == "method":
                owner = fn.get("owner_type", "obj")
                lines.append(f'it("{fn["name"]} works", function()')
                lines.append(f'    -- local obj = lurek.{mod_name}.new{owner}(...)')
                lines.append(f'    -- local result = obj:{fn["name"]}()')
                lines.append(f'    -- expect_not_nil(result)')
                lines.append(f'end)')
            else:
                lines.append(f'it("{fn["name"]} works", function()')
                lines.append(f'    local result = lurek.{mod_name}.{fn["name"]}()')
                lines.append(f'    expect_not_nil(result)')
                lines.append(f'end)')
            lines.append("")

        if len(fns) > 15:
            lines.append(f"-- ... and {len(fns) - 15} more uncovered functions")

        lines.append("```")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Lurek2D Lua API test coverage analysis (marker-aware)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--strict", action="store_true",
                        help="Only count @covers markers (no heuristic fallback)")
    parser.add_argument("--json", action="store_true",
                        help="Output JSON to stdout")
    parser.add_argument("--report", action="store_true",
                        help="Output full markdown report")
    parser.add_argument("--suggest", action="store_true",
                        help="Generate test stubs for uncovered functions")
    parser.add_argument("--orphans", action="store_true",
                        help="Show only orphaned markers")
    parser.add_argument("--module", metavar="NAME",
                        help="Filter to a specific module")
    parser.add_argument("--threshold", type=float, default=50.0,
                        help="Coverage threshold %% (default: 50)")
    parser.add_argument("--output", metavar="FILE",
                        help="Save output to file")
    args = parser.parse_args()

    # Load canonical API data
    print("[INFO] Loading API data from lua_api_data.json...", file=sys.stderr)
    api_data = load_api_data(LUA_API_DATA)
    api_functions = collect_api_functions(api_data, args.module)
    print(f"[INFO] Found {len(api_functions)} API functions", file=sys.stderr)

    # Scan for @covers markers
    print("[INFO] Scanning Lua test files for @covers markers...", file=sys.stderr)
    marker_data = scan_markers(LUA_TESTS_DIR)
    total_markers = sum(len(m) for m in marker_data.values())
    marked_files = len(marker_data)
    print(f"[INFO] Found {total_markers} markers in {marked_files} files", file=sys.stderr)

    # Build marker coverage
    marker_covered, coverage_map, orphans = build_marker_coverage(
        api_functions, marker_data
    )
    print(f"[INFO] Marker coverage: {len(marker_covered)} functions", file=sys.stderr)

    # Heuristic fallback (unless --strict)
    heuristic_covered_set: Set[str] = set()
    if not args.strict:
        print("[INFO] Running heuristic fallback for unmarked functions...", file=sys.stderr)
        heuristic_covered_set = heuristic_coverage(
            api_functions, LUA_TESTS_DIR, marker_covered
        )
        print(f"[INFO] Heuristic coverage: {len(heuristic_covered_set)} additional", file=sys.stderr)

    # Generate report
    report = generate_json_report(
        api_functions, marker_covered, heuristic_covered_set,
        orphans, coverage_map, args.strict, args.module
    )

    # Output
    if args.orphans:
        if orphans:
            for o in orphans:
                print(f"  {o['file']}:{o['line']} — {o['marker']}")
        else:
            print("No orphaned markers found.")
        return 0

    if args.suggest:
        all_covered = marker_covered | heuristic_covered_set
        output = generate_suggestions(api_functions, all_covered, args.module)
    elif args.json:
        output = json.dumps(report, indent=2)
    elif args.report:
        output = generate_markdown_report(report)
    else:
        # Summary mode
        meta = report["meta"]
        output_lines = [
            f"Lua API Test Coverage ({meta['mode']} mode)",
            f"  Total API functions: {meta['total_api_functions']}",
            f"  Marker-covered:      {meta['marker_covered']}",
        ]
        if not args.strict:
            output_lines.append(
                f"  Heuristic-covered:   {meta['heuristic_covered']}"
            )
        output_lines.extend([
            f"  Total covered:       {meta['total_covered']}",
            f"  Coverage:            {meta['coverage_pct']}%",
            "",
            "Per-module (sorted by coverage):",
        ])
        for mod, stats in sorted(report["modules"].items(),
                                  key=lambda x: x[1]["coverage_pct"]):
            bar_len = int(stats["coverage_pct"] / 5)
            bar = "#" * bar_len + "." * (20 - bar_len)
            output_lines.append(
                f"  {mod:20s} {bar} {stats['coverage_pct']:5.1f}% "
                f"({stats['covered']}/{stats['total']})"
            )
        output = "\n".join(output_lines)

    # Write output
    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"[INFO] Report saved to {args.output}", file=sys.stderr)
    else:
        print(output)

    # Always save JSON to docs/logs/
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"[INFO] JSON data saved to {OUTPUT_JSON}", file=sys.stderr)

    # Threshold check
    coverage_pct = report["meta"]["coverage_pct"]
    if coverage_pct < args.threshold:
        print(
            f"[WARN] Coverage {coverage_pct}% is below threshold {args.threshold}%",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
