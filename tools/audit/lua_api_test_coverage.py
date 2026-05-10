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
LUA_API_DATA = WORKSPACE_ROOT / "logs" / "data" / "lua_api_data.json"
LUA_TESTS_DIR = WORKSPACE_ROOT / "tests" / "lua"
OUTPUT_JSON = WORKSPACE_ROOT / "logs" / "data" / "lua_api_test_coverage.json"

# Regex for @covers markers:
#   -- @covers lurek.math.sin
#   -- @covers Vec2:length
#   -- @covers LUiWidget.setPosition
COVERS_RE = re.compile(
    r"^--\s*@covers\s+((?:lurek\.\w+(?:\.\w+)+)|(?:\w+:\w+)|(?:\w+\.\w+))\s*$"
)

# Regex for describe("lurek.module.function", ...) and describe("Class:method", ...)
DESCRIBE_RE = re.compile(
    r'describe\(\s*["\']((?:lurek\.\w+(?:\.\w+)+)|(?:\w+:\w+)|(?:\w+\.\w+))["\']'
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

# Legacy/test-helper namespaces that are not canonical function/method symbols
# in lua_api_data.json and should not be reported as orphan markers.
LEGACY_NON_API_PREFIXES = {
    "lurek.scene.transitions",
    "lurek.window.display",
    "lurek.window.mode",
    "lurek.window.cursor",
}


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
    """Scan only unit/ Lua test files for @covers markers.

    Only tests/lua/unit/ files count toward coverage.
    Library, stress, integration and security tests use @library / @stress /
    @integration / @security markers and are intentionally excluded here.

    Returns: {test_file_rel_path: [{"marker": "lurek.math.sin", "line": 5}, ...]}
    """
    results: Dict[str, List[Dict]] = {}

    unit_dir = tests_dir / "unit"
    for lua_file in sorted(unit_dir.rglob("*.lua")):
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


def scan_describe_targets(tests_dir: Path) -> Dict[str, List[Dict]]:
    """Scan unit/ Lua test files for describe("...") API targets."""
    results: Dict[str, List[Dict]] = {}

    unit_dir = tests_dir / "unit"
    for lua_file in sorted(unit_dir.rglob("*.lua")):
        rel = str(lua_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
        targets = []

        try:
            lines = lua_file.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        for i, line in enumerate(lines):
            m = DESCRIBE_RE.search(line)
            if m:
                targets.append({
                    "target": m.group(1),
                    "line": i + 1,
                })

        if targets:
            results[rel] = targets

    return results


def normalize_api_name(lua_name: str) -> str:
    """Normalize an API name for matching.

    "lurek.math.sin" -> "lurek.math.sin"
    "Vec2:length" -> "Vec2:length"
    """
    return lua_name.strip()


def _build_name_maps(
    api_functions: List[Dict],
) -> Tuple[Set[str], Dict[str, str], Dict[str, Dict[str, str]], Set[str]]:
    """Build canonical and alias lookups for API name resolution."""
    canonical_names: Set[str] = set()
    alias_map: Dict[str, str] = {}
    module_method_index: Dict[str, Dict[str, str]] = {}
    known_modules: Set[str] = set()

    for fn in api_functions:
        lua_name = fn["lua_name"]
        canonical_names.add(lua_name)
        known_modules.add(fn["module"])

        if ":" in lua_name:
            cls, sep, meth = lua_name.partition(":")
            if cls.startswith("L") and len(cls) > 1:
                alias_map[cls[1:] + sep + meth] = lua_name
                alias_map[cls + "." + meth] = lua_name
                alias_map[cls[1:] + "." + meth] = lua_name
        elif "." in lua_name and lua_name.startswith("L"):
            cls, _, meth = lua_name.rpartition(".")
            if cls and meth:
                alias_map[cls + ":" + meth] = lua_name
                if cls.startswith("L") and len(cls) > 1:
                    base = cls[1:]
                    alias_map[base + ":" + meth] = lua_name
                    alias_map[base + "." + meth] = lua_name

        if fn["kind"] == "method":
            mod = fn["module"]
            method = fn["name"]
            canonical = fn["lua_name"]
            module_method_index.setdefault(mod, {})
            module_method_index[mod].setdefault(method, canonical)

    return canonical_names, alias_map, module_method_index, known_modules


def _resolve_target(
    marker: str,
    canonical_names: Set[str],
    alias_map: Dict[str, str],
    module_method_index: Dict[str, Dict[str, str]],
    known_modules: Set[str],
) -> str:
    """Resolve marker/describe target into canonical lua_name or sentinel."""
    resolved = marker

    if marker in canonical_names:
        return marker

    if marker in alias_map:
        return alias_map[marker]

    if any(marker == p or marker.startswith(p + ".") for p in LEGACY_NON_API_PREFIXES):
        return "__non_api__"

    # Allow a common typo variant used in some tests: LLClass:method -> LClass:method.
    if marker.startswith("LL") and (":" in marker or "." in marker):
        normalized = "L" + marker[2:]
        if normalized in canonical_names:
            return normalized
        if normalized in alias_map:
            return alias_map[normalized]

    # Handle shorthand module targets used in describe names, e.g.:
    #   audio.newDecoder -> lurek.audio.newDecoder
    #   data.hash        -> lurek.data.hash
    if "." in marker and not marker.startswith("lurek.") and ":" not in marker:
        mod, member = marker.split(".", 1)
        if mod in known_modules:
            candidate = f"lurek.{mod}.{member}"
            if candidate in canonical_names:
                return candidate
            canonical_method = module_method_index.get(mod, {}).get(member)
            if canonical_method:
                return canonical_method
        # Shorthand rooted in a local helper/module alias (e.g. C.newRecipe) is
        # outside canonical lurek.* API coverage and should not be orphaned.
        return "__non_api__"

    # Non-lurek class-style targets (e.g. Pool:play) that do not resolve through
    # known aliases are local helper userdata markers and should not be orphaned.
    if ":" in marker and not marker.startswith("lurek."):
        if marker in alias_map:
            return alias_map[marker]
        return "__non_api__"

    if marker.startswith("lurek."):
        parts = marker.split(".")
        if len(parts) >= 2 and parts[1] not in known_modules:
            # External/non-shipping namespaces (e.g. lurek.turnbattle) are not
            # part of the canonical API dataset for this gate.
            return "__non_api__"
        if len(parts) == 2 and parts[1] in known_modules:
            return "__namespace__"
        if len(parts) >= 4:
            cls_name = parts[-2]
            meth_name = parts[-1]
            dotted_alias = cls_name + ":" + meth_name
            l_alias = "L" + cls_name + ":" + meth_name
            l_dot_alias = "L" + cls_name + "." + meth_name
            cls_dot_alias = cls_name + "." + meth_name
            if dotted_alias in alias_map:
                resolved = alias_map[dotted_alias]
            elif l_alias in canonical_names:
                resolved = l_alias
            elif l_dot_alias in canonical_names:
                resolved = l_dot_alias
            elif l_dot_alias in alias_map:
                resolved = alias_map[l_dot_alias]
            elif cls_dot_alias in alias_map:
                resolved = alias_map[cls_dot_alias]
            elif parts[1] in known_modules:
                # Accept extra namespace segments (e.g. lurek.scene.transitions.fade)
                # by resolving terminal member against module methods.
                canonical_method = module_method_index.get(parts[1], {}).get(meth_name)
                if canonical_method:
                    resolved = canonical_method
        else:
            mod = parts[1] if len(parts) >= 2 else ""
            member = parts[-1] if parts else ""
            canonical_method = module_method_index.get(mod, {}).get(member)
            if canonical_method:
                resolved = canonical_method

            # Class/table describe names (e.g. lurek.patterns.Stack) are
            # namespace-level anchors, not callable API function symbols.
            if resolved == marker and len(parts) == 3 and member[:1].isupper():
                return "__non_api__"

            # Property/constant markers (e.g. lurek.math.pi, lurek.network.MAX_PEERS)
            # are not represented in this function/method coverage index.
            if resolved == marker and len(parts) == 3:
                member = parts[2]
                if member.isupper() or member in {"pi", "tau", "huge"}:
                    return "__non_api__"

        if resolved == marker:
            prefix_dot = marker + "."
            prefix_colon = marker + ":"
            if any(
                name.startswith(prefix_dot) or name.startswith(prefix_colon)
                for name in canonical_names
            ):
                return "__namespace__"

    return resolved


def build_marker_coverage(
    api_functions: List[Dict],
    marker_data: Dict[str, List[Dict]],
) -> Tuple[Set[str], Dict[str, List[str]], List[Dict]]:
    """Match @covers markers against canonical API list.

    Returns:
        covered_names: set of lua_name strings that have markers
        coverage_map: {lua_name: [test_files]}
        orphans: list of {"file", "line", "marker"} for unmatched markers

    Handles two naming conventions:
      - Canonical: LChannel:push, LThread:isRunning (internal L-prefix class names)
      - Test-style: Channel:push, Thread:isRunning  (names without L-prefix)
    Both are accepted. lurek.module.Class.method is resolved to LClass:method.
    """
    canonical_names, alias_map, module_method_index, known_modules = _build_name_maps(api_functions)

    covered_names: Set[str] = set()
    coverage_map: Dict[str, List[str]] = {}
    orphans: List[Dict] = []

    for test_file, markers in marker_data.items():
        for entry in markers:
            marker = entry["marker"]
            resolved = _resolve_target(
                marker,
                canonical_names,
                alias_map,
                module_method_index,
                known_modules,
            )

            if resolved in canonical_names:
                covered_names.add(resolved)
                coverage_map.setdefault(resolved, []).append(test_file)
            elif resolved == "__namespace__":
                # Keep namespace markers out of orphan list, but they do not map to
                # a specific canonical function.
                continue
            elif resolved == "__non_api__":
                # Non-canonical helpers/properties should not be counted as orphans.
                continue
            else:
                orphans.append({
                    "file": test_file,
                    "line": entry["line"],
                    "marker": marker,
                })

    return covered_names, coverage_map, orphans


def build_describe_coverage(
    api_functions: List[Dict],
    describe_data: Dict[str, List[Dict]],
) -> Tuple[Set[str], Dict[str, List[str]], List[Dict]]:
    """Match describe targets against canonical API list."""
    canonical_names, alias_map, module_method_index, known_modules = _build_name_maps(api_functions)

    covered_names: Set[str] = set()
    coverage_map: Dict[str, List[str]] = {}
    unresolved: List[Dict] = []

    for test_file, targets in describe_data.items():
        for entry in targets:
            target = entry["target"]
            resolved = _resolve_target(
                target,
                canonical_names,
                alias_map,
                module_method_index,
                known_modules,
            )

            if resolved in canonical_names:
                covered_names.add(resolved)
                coverage_map.setdefault(resolved, []).append(test_file)
            elif resolved == "__namespace__":
                continue
            elif resolved == "__non_api__":
                continue
            else:
                unresolved.append({
                    "file": test_file,
                    "line": entry["line"],
                    "target": target,
                })

    return covered_names, coverage_map, unresolved


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
    unit_dir = tests_dir / "unit"
    for lua_file in sorted(unit_dir.rglob("*.lua")):
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
    describe_covered: Set[str],
    heuristic_covered_set: Set[str],
    orphans: List[Dict],
    coverage_map: Dict[str, List[str]],
    describe_map: Dict[str, List[str]],
    unresolved_describe: List[Dict],
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
            "describe_covered": 0,
            "heuristic_covered": 0,
            "uncovered": [],
            "test_files": set(),
            "describe_files": set(),
            "functions": [],
        })
        mod_stats[mod]["total"] += 1

        is_marker = fn["lua_name"] in marker_covered
        is_describe = fn["lua_name"] in describe_covered
        is_heuristic = fn["lua_name"] in heuristic_covered_set and not strict
        is_covered = is_marker or is_heuristic

        if fn["lua_name"] in marker_covered:
            mod_stats[mod]["marker_covered"] += 1
            for tf in coverage_map.get(fn["lua_name"], []):
                mod_stats[mod]["test_files"].add(tf)
        if is_describe:
            mod_stats[mod]["describe_covered"] += 1
            for tf in describe_map.get(fn["lua_name"], []):
                mod_stats[mod]["describe_files"].add(tf)
        if is_heuristic:
            mod_stats[mod]["heuristic_covered"] += 1
        if not is_covered:
            mod_stats[mod]["uncovered"].append({
                "lua_name": fn["lua_name"],
                "kind": fn["kind"],
                "file": fn["file"],
                "line": fn["line"],
            })

        mod_stats[mod]["functions"].append({
            "lua_name": fn["lua_name"],
            "kind": fn["kind"],
            "marker_covered": is_marker,
            "describe_covered": is_describe,
            "heuristic_covered": is_heuristic,
            "covered": is_covered,
            "describe_score": 1.0 if is_describe else 0.0,
        })

    # Convert sets to sorted lists for JSON
    modules_out = {}
    for mod_name, stats in sorted(mod_stats.items()):
        total_mod = stats["total"]
        covered_mod = stats["marker_covered"] + (0 if strict else stats["heuristic_covered"])
        modules_out[mod_name] = {
            "total": total_mod,
            "marker_covered": stats["marker_covered"],
            "describe_covered": stats["describe_covered"],
            "heuristic_covered": stats["heuristic_covered"],
            "covered": covered_mod,
            "coverage_pct": round(covered_mod / total_mod * 100, 1) if total_mod else 100.0,
            "describe_coverage_pct": round(stats["describe_covered"] / total_mod * 100, 1) if total_mod else 100.0,
            "describe_score": round(stats["describe_covered"] / total_mod, 3) if total_mod else 1.0,
            "uncovered": stats["uncovered"],
            "test_files": sorted(stats["test_files"]),
            "describe_files": sorted(stats["describe_files"]),
            "functions": stats["functions"],
        }

    return {
        "meta": {
            "generated": datetime.now(timezone.utc).isoformat(),
            "generator": "tools/audit/lua_api_test_coverage.py",
            "mode": "strict" if strict else "hybrid",
            "module_filter": module_filter,
            "total_api_functions": total,
            "marker_covered": len(marker_covered),
            "describe_covered": len(describe_covered),
            "describe_coverage_pct": round(len(describe_covered) / total * 100, 1) if total else 100.0,
            "heuristic_covered": len(heuristic_covered_set) if not strict else 0,
            "total_covered": covered_count,
            "coverage_pct": round(covered_count / total * 100, 1) if total else 100.0,
        },
        "modules": modules_out,
        "orphaned_markers": orphans,
        "unresolved_describe": unresolved_describe,
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
        f"| Describe-covered | {meta['describe_covered']} |",
        f"| Describe coverage | {meta['describe_coverage_pct']}% |",
    ]

    if meta["mode"] == "hybrid":
        lines.append(f"| Heuristic-covered | {meta['heuristic_covered']} |")

    lines.extend([
        f"| Total covered | {meta['total_covered']} |",
        f"| Coverage | {meta['coverage_pct']}% |",
        "",
        "## Per-Module Coverage",
        "",
        "| Module | Total | Marker | Describe | Describe Score | Heuristic | Covered | Coverage |",
        "|--------|-------|--------|----------|----------------|-----------|---------|----------|",
    ])

    for mod_name, stats in sorted(report["modules"].items(),
                                   key=lambda x: x[1]["coverage_pct"]):
        lines.append(
            f"| {mod_name} | {stats['total']} | {stats['marker_covered']} | "
            f"{stats['describe_covered']} | {stats['describe_score']:.3f} | "
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

    if report.get("unresolved_describe"):
        lines.extend([
            "## Unresolved describe() targets",
            "",
        ])
        for item in report["unresolved_describe"]:
            lines.append(
                f"- `{item['target']}` in `{item['file']}:{item['line']}`"
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
    parser.add_argument("--describe-threshold", type=float, default=0.0,
                        help="Describe coverage threshold %% (0 disables gate)")
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

    print("[INFO] Scanning Lua test files for describe() targets...", file=sys.stderr)
    describe_data = scan_describe_targets(LUA_TESTS_DIR)
    total_describe = sum(len(m) for m in describe_data.values())
    print(f"[INFO] Found {total_describe} describe() targets", file=sys.stderr)
    describe_covered, describe_map, unresolved_describe = build_describe_coverage(
        api_functions,
        describe_data,
    )
    print(f"[INFO] Describe coverage: {len(describe_covered)} functions", file=sys.stderr)

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
        api_functions,
        marker_covered,
        describe_covered,
        heuristic_covered_set,
        orphans,
        coverage_map,
        describe_map,
        unresolved_describe,
        args.strict,
        args.module,
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
            f"  Describe-covered:    {meta['describe_covered']}",
            f"  Describe coverage:   {meta['describe_coverage_pct']}%",
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

    # Always save JSON to logs/
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

    describe_pct = report["meta"]["describe_coverage_pct"]
    if args.describe_threshold > 0.0 and describe_pct < args.describe_threshold:
        print(
            f"[WARN] Describe coverage {describe_pct}% is below threshold {args.describe_threshold}%",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
