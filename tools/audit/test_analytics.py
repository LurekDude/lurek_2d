#!/usr/bin/env python3
"""
test_analytics.py — Lurek2D comprehensive test analytics.

Aggregates coverage data from multiple sources (markers, describe-blocks,
heuristics, evidence tags) into grouped, categorized reports with per-module
and per-method breakdowns, letter grades, and trend comparison.

Usage:
    python tools/audit/test_analytics.py                      # full summary
    python tools/audit/test_analytics.py --json               # JSON export
    python tools/audit/test_analytics.py --module physics     # single module
    python tools/audit/test_analytics.py --worst 10           # 10 worst modules
    python tools/audit/test_analytics.py --trend              # compare to last run
    python tools/audit/test_analytics.py --category rendering # category filter

Exit codes:
    0  - success
    1  - regression detected (--trend mode only)
    2  - fatal error (missing data files)
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
LUA_API_DATA = WORKSPACE_ROOT / "logs" / "data" / "lua_api_data.json"
LUA_TESTS_DIR = WORKSPACE_ROOT / "tests" / "lua"
COVERAGE_JSON = WORKSPACE_ROOT / "logs" / "data" / "lua_api_test_coverage.json"
OUTPUT_JSON = WORKSPACE_ROOT / "logs" / "data" / "test_analytics.json"

# ── Regex patterns ────────────────────────────────────────────────────────────

COVERS_RE = re.compile(r"^--\s*@covers\s+((?:lurek\.\w+\.\w+)|(?:\w+:\w+))\s*$")
EVIDENCE_RE = re.compile(r"^--\s*@evidence\s+(\w+):(.+)\s*$")
STRESS_RE = re.compile(r"^--\s*@stress\b")
GOLDEN_RE = re.compile(r"^--\s*@golden\b")

# describe("lurek.module.func", ...) or describe("ClassName:method", ...)
DESCRIBE_RE = re.compile(
    r'describe\(\s*["\']('
    r"lurek\.\w+\.\w+"         # lurek.module.function
    r"|[\w]+:[\w]+"            # ClassName:method
    r")[\"']",
    re.MULTILINE,
)

IT_RE = re.compile(r'\bit\s*\(\s*["\']')

# ── Module → Category mapping ────────────────────────────────────────────────

CATEGORY_MAP = {
    "graphic":      "Rendering",
    "render":     "Rendering",
    "light":        "Rendering",
    "camera":       "Rendering",
    "particle":     "Rendering",
    "postfx":       "Rendering",
    "effect":       "Rendering",
    "fx":           "Rendering",
    "tilemap":      "Rendering",
    "minimap":      "Rendering",
    "animation":    "Entity/Scene",
    "spine":        "Entity/Scene",
    "tween":        "Entity/Scene",
    "ecs":       "Entity/Scene",
    "scene":        "Entity/Scene",
    "audio":        "Audio",
    "physics":      "Physics",
    "ai":           "AI/Logic",
    "pathfind":  "AI/Logic",
    "graph":        "AI/Logic",
    "automation":   "AI/Logic",
    "patterns":     "AI/Logic",
    "data":         "Data/Persistence",
    "dataframe":    "Data/Persistence",
    "serial":       "Data/Persistence",
    "save":     "Data/Persistence",
    "filesystem":   "Data/Persistence",
    "image":        "Data/Persistence",
    "network":      "Networking",
    "system":       "System",
    "window":       "System",
    "input":        "System",
    "timer":        "System",
    "event":        "System",
    "signal":       "System",
    "thread":       "System",
    "log":          "Scripting",
    "i18n": "Scripting",
    "ui":           "Scripting",
    "ui":          "Scripting",
    "mods":      "Scripting",
    "devtools":     "Scripting",
    "docs":         "Scripting",
    "debugbridge":  "Scripting",
    "terminal":     "Scripting",
    "effect":      "Scripting",
    "math":         "Math/Compute",
    "compute":      "Math/Compute",
    "procgen":      "Math/Compute",
    "raycaster":    "Math/Compute",
    "pipeline":     "Math/Compute",
}


def get_category(module_name: str) -> str:
    """Return the functional category for a module."""
    return CATEGORY_MAP.get(module_name, "Other")


# ── Data loading ──────────────────────────────────────────────────────────────

def load_api_surface(path: Path) -> Dict[str, List[Dict]]:
    """Load canonical API surface grouped by module.

    Returns: {module_name: [{lua_name, name, kind, owner_type}, ...]}
    """
    if not path.exists():
        print(f"[ERROR] API data not found: {path}", file=sys.stderr)
        print("[INFO]  Run: python tools/docs/gen_lua_api_data.py", file=sys.stderr)
        sys.exit(2)

    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    modules_raw = data.get("lua_api", {}).get("modules", {})
    result: Dict[str, List[Dict]] = {}

    for mod_name, mod_data in sorted(modules_raw.items()):
        funcs: List[Dict] = []

        for func in mod_data.get("functions", []):
            funcs.append({
                "lua_name": func["lua_name"],
                "name": func["name"],
                "kind": func.get("kind", "function"),
                "owner_type": func.get("owner_type", ""),
            })

        for cls_name, cls_data in mod_data.get("classes", {}).items():
            for method in cls_data.get("methods", []):
                funcs.append({
                    "lua_name": method["lua_name"],
                    "name": method["name"],
                    "kind": method.get("kind", "method"),
                    "owner_type": method.get("owner_type", cls_name),
                })

        result[mod_name] = funcs

    return result


def load_previous_analytics(path: Path) -> Optional[Dict]:
    """Load previous analytics JSON for trend comparison."""
    if not path.exists():
        return None
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


# ── Scanning ──────────────────────────────────────────────────────────────────

def scan_all_lua_tests(tests_dir: Path) -> Dict[str, str]:
    """Read all Lua test files into memory.

    Returns: {relative_path: file_content}
    """
    contents: Dict[str, str] = {}
    for lua_file in sorted(tests_dir.rglob("*.lua")):
        if lua_file.name == "init.lua":
            continue
        try:
            rel = str(lua_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
            contents[rel] = lua_file.read_text(encoding="utf-8")
        except OSError:
            continue
    return contents


def scan_markers(test_files: Dict[str, str]) -> Dict[str, Set[str]]:
    """Scan for @covers markers.

    Returns: {lua_name: {test_file, ...}}
    """
    coverage: Dict[str, Set[str]] = defaultdict(set)
    for file_path, content in test_files.items():
        for line in content.splitlines():
            m = COVERS_RE.match(line.strip())
            if m:
                coverage[m.group(1)].add(file_path)
    return coverage


def scan_evidence(test_files: Dict[str, str]) -> Dict[str, List[str]]:
    """Scan for @evidence markers.

    Returns: {test_file: [evidence_type, ...]}
    """
    result: Dict[str, List[str]] = {}
    for file_path, content in test_files.items():
        evidence = []
        for line in content.splitlines():
            m = EVIDENCE_RE.match(line.strip())
            if m:
                evidence.append(f"{m.group(1)}:{m.group(2).strip()}")
        if evidence:
            result[file_path] = evidence
    return result


def scan_describe_blocks(test_files: Dict[str, str]) -> Dict[str, Dict]:
    """Scan describe() block names for API function naming convention.

    Returns: {lua_name: {test_count, has_error_test, files, ...}}
    """
    result: Dict[str, Dict] = {}

    for file_path, content in test_files.items():
        for m in DESCRIBE_RE.finditer(content):
            api_name = m.group(1).strip()
            # Extract the block text (approximate: from match to next describe or EOF)
            start = m.end()
            # Find the approximate end of this describe block
            # (simple heuristic: next top-level describe or end of file)
            next_desc = DESCRIBE_RE.search(content, start)
            block_end = next_desc.start() if next_desc else len(content)
            block_text = content[start:block_end]

            it_count = len(IT_RE.findall(block_text))
            has_error = "expect_error" in block_text or "pcall" in block_text
            has_nil = "nil" in block_text

            if api_name not in result:
                result[api_name] = {
                    "test_count": 0,
                    "has_error_test": False,
                    "has_nil_test": False,
                    "files": [],
                }

            entry = result[api_name]
            entry["test_count"] += it_count
            entry["has_error_test"] = entry["has_error_test"] or has_error
            entry["has_nil_test"] = entry["has_nil_test"] or has_nil
            if file_path not in entry["files"]:
                entry["files"].append(file_path)

    return result


def heuristic_check(
    func_name: str, lua_name: str, owner_type: str,
    test_contents: Dict[str, str],
) -> bool:
    """Heuristic: does a function name appear in any test file?"""
    # Try patterns: "lurek.mod.fn", "fn", ":fn" for methods
    lowered = func_name.lower()
    for _path, content in test_contents.items():
        lc = content.lower()
        if lua_name.lower() in lc:
            return True
        if owner_type and f":{lowered}" in lc:
            return True
        # Bare function name in a relevant module test
        if f".{lowered}" in lc or f'"{lowered}"' in lc:
            return True
    return False


def count_test_files(tests_dir: Path) -> Dict[str, int]:
    """Count test files by category."""
    counts: Dict[str, int] = defaultdict(int)
    for lua_file in sorted(tests_dir.rglob("*.lua")):
        if lua_file.name == "init.lua":
            continue
        rel = lua_file.relative_to(tests_dir)
        parts = rel.parts
        if len(parts) >= 1:
            category = parts[0]
            counts[category] += 1
    return counts


def count_it_blocks(test_files: Dict[str, str]) -> int:
    """Count total it() blocks across all test files."""
    total = 0
    for content in test_files.values():
        total += len(IT_RE.findall(content))
    return total


# ── Scoring ───────────────────────────────────────────────────────────────────

def compute_module_score(
    function_count: int,
    marker_covered: int,
    heuristic_covered: int,
    evidence_count: int,
    error_test_count: int,
    has_stress: bool,
    has_golden: bool,
) -> float:
    """Compute module score 0-10 based on weighted criteria."""
    if function_count == 0:
        return 0.0

    marker_pct = marker_covered / function_count * 100
    heuristic_pct = heuristic_covered / function_count * 100

    score = 0.0

    # Heuristic coverage (20% weight, max 2 pts)
    if heuristic_pct >= 80:
        score += 2.0
    elif heuristic_pct >= 50:
        score += 1.0

    # Marker coverage (25% weight, max 2.5 pts)
    if marker_pct >= 30:
        score += 2.5
    elif marker_pct >= 5:
        score += 1.25

    # Evidence (20% weight, max 2 pts)
    if evidence_count >= 3:
        score += 2.0
    elif evidence_count >= 1:
        score += 1.0

    # Error tests (15% weight, max 1.5 pts)
    if error_test_count >= 3:
        score += 1.5
    elif error_test_count >= 1:
        score += 0.75

    # Stress tests (10% weight, max 1 pt)
    if has_stress:
        score += 1.0

    # Golden tests (10% weight, max 1 pt)
    if has_golden:
        score += 1.0

    return score


def score_to_grade(score: float) -> str:
    """Convert numeric score 0-10 to letter grade."""
    if score >= 9:
        return "A"
    elif score >= 7:
        return "B"
    elif score >= 5:
        return "C"
    elif score >= 3:
        return "D"
    else:
        return "F"


# ── Report building ──────────────────────────────────────────────────────────

def build_report(
    api_surface: Dict[str, List[Dict]],
    test_files: Dict[str, str],
    module_filter: Optional[str] = None,
) -> Dict[str, Any]:
    """Build the complete analytics report."""

    # Scan all data sources
    marker_map = scan_markers(test_files)
    evidence_map = scan_evidence(test_files)
    describe_map = scan_describe_blocks(test_files)
    file_counts = count_test_files(LUA_TESTS_DIR)
    total_its = count_it_blocks(test_files)

    # All evidence functions (flattened)
    evidence_funcs: Set[str] = set()
    for _file, ev_list in evidence_map.items():
        for ev in ev_list:
            # Extract function name from evidence if possible
            parts = ev.split(":")
            if len(parts) >= 2:
                evidence_funcs.add(parts[1].strip())

    # Check for stress / golden test files
    stress_modules: Set[str] = set()
    golden_modules: Set[str] = set()
    for file_path, content in test_files.items():
        if "/stress/" in file_path:
            # Extract module from filename: test_<module>_stress.lua
            fname = Path(file_path).stem
            mod = fname.replace("test_", "").replace("_stress", "").replace(
                "_collision", "").replace("_compression", "")
            stress_modules.add(mod)
        if "/golden/" in file_path:
            fname = Path(file_path).stem
            mod = fname.replace("test_", "").replace("_golden", "")
            golden_modules.add(mod)
        # Also check @stress / @golden markers
        for line in content.splitlines():
            if STRESS_RE.match(line.strip()):
                # Try to extract module from file path
                for mod_name in api_surface:
                    if mod_name in file_path:
                        stress_modules.add(mod_name)
            if GOLDEN_RE.match(line.strip()):
                for mod_name in api_surface:
                    if mod_name in file_path:
                        golden_modules.add(mod_name)

    # Build per-module reports
    modules_report: Dict[str, Dict] = {}
    total_functions = 0
    total_marker = 0
    total_heuristic = 0
    total_evidence = 0
    total_error_tests = 0

    for mod_name, functions in sorted(api_surface.items()):
        if module_filter and mod_name != module_filter:
            continue

        func_count = len(functions)
        total_functions += func_count
        marker_count = 0
        heuristic_count = 0
        ev_count = 0
        err_count = 0
        uncovered: List[str] = []

        for fn in functions:
            lua_name = fn["lua_name"]

            # Marker coverage
            is_marker = lua_name in marker_map
            if is_marker:
                marker_count += 1

            # Heuristic coverage
            is_heuristic = is_marker or heuristic_check(
                fn["name"], lua_name, fn.get("owner_type", ""), test_files
            )
            if is_heuristic:
                heuristic_count += 1

            # Describe block coverage
            desc_info = describe_map.get(lua_name)
            if desc_info:
                if desc_info["has_error_test"]:
                    err_count += 1

            # Evidence (check if function name appears in evidence list)
            if lua_name in evidence_funcs or fn["name"] in evidence_funcs:
                ev_count += 1

            if not is_marker and not is_heuristic:
                uncovered.append(lua_name)

        total_marker += marker_count
        total_heuristic += heuristic_count
        total_evidence += ev_count
        total_error_tests += err_count

        has_stress = mod_name in stress_modules
        has_golden = mod_name in golden_modules

        score = compute_module_score(
            func_count, marker_count, heuristic_count,
            ev_count, err_count, has_stress, has_golden,
        )
        grade = score_to_grade(score)

        warnings: List[str] = []
        if marker_count == 0:
            warnings.append("0% marker coverage")
        if ev_count == 0 and get_category(mod_name) == "Rendering":
            warnings.append("No visual evidence for rendering module")
        if not has_stress and func_count >= 20:
            warnings.append("No stress tests for large module")

        modules_report[mod_name] = {
            "name": mod_name,
            "category": get_category(mod_name),
            "function_count": func_count,
            "marker_covered": marker_count,
            "heuristic_covered": heuristic_count,
            "evidence_count": ev_count,
            "error_test_count": err_count,
            "has_stress": has_stress,
            "has_golden": has_golden,
            "score": round(score, 1),
            "grade": grade,
            "warnings": warnings,
            "uncovered": uncovered[:20],  # limit to first 20
        }

    # Build category summaries
    categories: Dict[str, Dict] = defaultdict(lambda: {
        "modules": [], "total_funcs": 0, "marker": 0, "heuristic": 0,
        "evidence": 0, "score_sum": 0.0, "count": 0,
    })

    for mod_name, mod_report in modules_report.items():
        cat = mod_report["category"]
        categories[cat]["modules"].append(mod_name)
        categories[cat]["total_funcs"] += mod_report["function_count"]
        categories[cat]["marker"] += mod_report["marker_covered"]
        categories[cat]["heuristic"] += mod_report["heuristic_covered"]
        categories[cat]["evidence"] += mod_report["evidence_count"]
        categories[cat]["score_sum"] += mod_report["score"]
        categories[cat]["count"] += 1

    category_report: Dict[str, Dict] = {}
    for cat_name, cat_data in sorted(categories.items()):
        avg_score = cat_data["score_sum"] / cat_data["count"] if cat_data["count"] else 0
        cat_marker_pct = (cat_data["marker"] / cat_data["total_funcs"] * 100
                          if cat_data["total_funcs"] else 0)
        cat_heur_pct = (cat_data["heuristic"] / cat_data["total_funcs"] * 100
                        if cat_data["total_funcs"] else 0)
        category_report[cat_name] = {
            "modules": cat_data["modules"],
            "total_functions": cat_data["total_funcs"],
            "marker_coverage_pct": round(cat_marker_pct, 1),
            "heuristic_coverage_pct": round(cat_heur_pct, 1),
            "evidence_count": cat_data["evidence"],
            "avg_score": round(avg_score, 1),
            "grade": score_to_grade(avg_score),
        }

    # Worst modules
    worst = sorted(modules_report.values(), key=lambda r: r["score"])
    worst_names = [m["name"] for m in worst[:10]]

    # Summary
    marker_pct = (total_marker / total_functions * 100) if total_functions else 0
    heuristic_pct = (total_heuristic / total_functions * 100) if total_functions else 0
    evidence_pct = (total_evidence / total_functions * 100) if total_functions else 0
    error_pct = (total_error_tests / total_functions * 100) if total_functions else 0

    return {
        "generated": datetime.now(timezone.utc).isoformat(),
        "version": "1.0",
        "summary": {
            "total_functions": total_functions,
            "total_modules": len(modules_report),
            "marker_coverage_pct": round(marker_pct, 1),
            "heuristic_coverage_pct": round(heuristic_pct, 1),
            "evidence_coverage_pct": round(evidence_pct, 1),
            "error_test_pct": round(error_pct, 1),
            "test_file_count": sum(file_counts.values()),
            "total_it_count": total_its,
            "test_categories": dict(file_counts),
        },
        "categories": category_report,
        "modules": modules_report,
        "worst_modules": worst_names,
    }


# ── Output formatters ────────────────────────────────────────────────────────

def print_summary(report: Dict) -> None:
    """Print executive summary to stdout."""
    s = report["summary"]
    print("=" * 65)
    print(f"  LUREK2D TEST ANALYTICS REPORT")
    print(f"  Generated: {report['generated'][:10]}")
    print(f"  API Surface: {s['total_modules']} modules, {s['total_functions']} functions")
    print(f"  Test Files: {s['test_file_count']} Lua")
    print(f"  Total it() blocks: {s['total_it_count']}")
    print("=" * 65)
    print()
    print("OVERALL COVERAGE")
    print(f"  Marker:     {s['marker_coverage_pct']:5.1f}%  ({int(s['total_functions'] * s['marker_coverage_pct'] / 100)} / {s['total_functions']} explicit)")
    print(f"  Heuristic:  {s['heuristic_coverage_pct']:5.1f}%  ({int(s['total_functions'] * s['heuristic_coverage_pct'] / 100)} / {s['total_functions']} estimated)")
    print(f"  Evidence:   {s['evidence_coverage_pct']:5.1f}%")
    print(f"  Error tests:{s['error_test_pct']:5.1f}%")
    print()


def print_categories(report: Dict) -> None:
    """Print category breakdown table."""
    print("CATEGORY BREAKDOWN")
    print(f"{'Category':<20} {'Modules':>7} {'Funcs':>6} {'Marker':>7} {'Heur':>6} {'Evid':>5} {'Grade':>6}")
    print("-" * 62)
    for cat_name, cat_data in sorted(report["categories"].items()):
        print(
            f"  {cat_name:<18} {len(cat_data['modules']):>5}"
            f"   {cat_data['total_functions']:>5}"
            f"  {cat_data['marker_coverage_pct']:>5.1f}%"
            f" {cat_data['heuristic_coverage_pct']:>5.1f}%"
            f" {cat_data['evidence_count']:>4}"
            f"  {cat_data['grade']:>3}"
        )
    print()


def print_modules(report: Dict, worst_n: Optional[int] = None) -> None:
    """Print per-module detail table."""
    modules = report["modules"]
    if worst_n:
        # Sort by score ascending
        sorted_mods = sorted(modules.values(), key=lambda r: r["score"])[:worst_n]
        print(f"WORST {worst_n} MODULES")
    else:
        sorted_mods = sorted(modules.values(), key=lambda r: r["name"])
        print("ALL MODULES")

    print(f"{'Module':<18} {'Funcs':>5} {'Mark%':>6} {'Heur%':>6}"
          f" {'Evid':>5} {'Err':>4} {'Str':>3} {'Gld':>3} {'Score':>5} {'Grade':>5}")
    print("-" * 73)

    for m in sorted_mods:
        marker_pct = m["marker_covered"] / m["function_count"] * 100 if m["function_count"] else 0
        heur_pct = m["heuristic_covered"] / m["function_count"] * 100 if m["function_count"] else 0
        stress_sym = "Y" if m["has_stress"] else "-"
        golden_sym = "Y" if m["has_golden"] else "-"
        warn_sym = " !!" if m["warnings"] else ""

        print(
            f"  {m['name']:<16} {m['function_count']:>5}"
            f" {marker_pct:>5.1f}% {heur_pct:>5.1f}%"
            f" {m['evidence_count']:>4}"
            f" {m['error_test_count']:>4}"
            f"   {stress_sym}"
            f"   {golden_sym}"
            f" {m['score']:>5.1f}"
            f"    {m['grade']}{warn_sym}"
        )

    # Print warnings for modules that have them
    print()
    warned = [m for m in sorted_mods if m["warnings"]]
    if warned:
        print("WARNINGS")
        for m in warned:
            for w in m["warnings"]:
                print(f"  !! {m['name']}: {w}")
        print()


def print_trend(report: Dict, previous: Optional[Dict]) -> bool:
    """Print trend comparison. Returns True if no regression."""
    if previous is None:
        print("TREND: No previous report found — baseline established.")
        return True

    prev_s = previous.get("summary", {})
    curr_s = report["summary"]

    print("TREND COMPARISON (vs previous run)")
    print("-" * 50)

    def delta(curr: float, prev: float, label: str) -> str:
        d = curr - prev
        sym = "+" if d >= 0 else ""
        return f"  {label:<20} {prev:>6.1f}% -> {curr:>6.1f}%  ({sym}{d:.1f}%)"

    fields = [
        ("marker_coverage_pct", "Marker coverage"),
        ("heuristic_coverage_pct", "Heuristic coverage"),
        ("evidence_coverage_pct", "Evidence coverage"),
        ("error_test_pct", "Error test coverage"),
    ]

    regression = False
    for field, label in fields:
        curr_val = curr_s.get(field, 0)
        prev_val = prev_s.get(field, 0)
        print(delta(curr_val, prev_val, label))
        if curr_val < prev_val - 0.5:  # 0.5% tolerance
            regression = True

    its_delta = curr_s.get("total_it_count", 0) - prev_s.get("total_it_count", 0)
    files_delta = curr_s.get("test_file_count", 0) - prev_s.get("test_file_count", 0)
    print(f"  {'Test files':<20} {'+' if files_delta >= 0 else ''}{files_delta}")
    print(f"  {'Total it() blocks':<20} {'+' if its_delta >= 0 else ''}{its_delta}")

    if regression:
        print("\n  !! REGRESSION DETECTED — coverage decreased")
    else:
        print("\n  No regressions.")

    print()
    return not regression


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Lurek2D test analytics")
    parser.add_argument("--json", action="store_true", help="Output JSON report")
    parser.add_argument("--module", type=str, help="Filter to single module")
    parser.add_argument("--worst", type=int, metavar="N", help="Show N worst modules")
    parser.add_argument("--category", type=str, help="Filter by category")
    parser.add_argument("--trend", action="store_true", help="Compare to previous run")
    args = parser.parse_args()

    # Load API surface
    api_surface = load_api_surface(LUA_API_DATA)

    # Scan tests
    test_files = scan_all_lua_tests(LUA_TESTS_DIR)

    # Build report
    report = build_report(api_surface, test_files, module_filter=args.module)

    if args.json:
        # Save JSON output
        OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        print(f"Report written to {OUTPUT_JSON.relative_to(WORKSPACE_ROOT)}")
        return 0

    # Print report
    print_summary(report)

    if args.category:
        # Filter modules by category
        filtered = {
            k: v for k, v in report["modules"].items()
            if v["category"].lower() == args.category.lower()
        }
        filtered_report = dict(report)
        filtered_report["modules"] = filtered
        print_modules(filtered_report, worst_n=args.worst)
    else:
        print_categories(report)
        print_modules(report, worst_n=args.worst)

    if args.trend:
        previous = load_previous_analytics(OUTPUT_JSON)
        ok = print_trend(report, previous)

        # Save current as new baseline
        OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        if not ok:
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
