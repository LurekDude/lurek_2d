#!/usr/bin/env python3
"""
test_coverage.py — Luna2D test coverage analysis.

Cross-references public Rust items and Lua API functions against test files
to determine which items have test coverage. Uses heuristic name matching.

Usage:
    python tools/test_coverage.py                    # coverage summary
    python tools/test_coverage.py --json             # JSON output
    python tools/test_coverage.py --suggest          # print test stubs for uncovered items
    python tools/test_coverage.py --module graphics  # single module
    python tools/test_coverage.py --help

Exit codes:
    0  - success
    1  - coverage below threshold
    2  - fatal error
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_DIR = WORKSPACE_ROOT / "src"
TESTS_DIR = WORKSPACE_ROOT / "tests" / "rust"
LUA_TESTS_DIR = WORKSPACE_ROOT / "tests" / "lua"
DEFAULT_JSON_OUTPUT = WORKSPACE_ROOT / "docs" / "logs" / "test_coverage.json"


def _snake_to_parts(name: str) -> Set[str]:
    """Split a snake_case or camelCase name into searchable parts."""
    parts = set()
    parts.add(name.lower())
    # snake_case parts
    for p in name.split("_"):
        if p:
            parts.add(p.lower())
    # camelCase split
    camel = re.findall(r'[a-z]+|[A-Z][a-z]*', name)
    for c in camel:
        parts.add(c.lower())
    return parts


def collect_rust_public_fns(src_dir: Path, module_filter: str = None) -> List[dict]:
    """Collect all pub fn items from src/, optionally filtered by module."""
    items = []
    pub_fn_re = re.compile(
        r'^pub(?:\([^)]*\))?\s+'
        r'(?:unsafe\s+|async\s+|const\s+)?'
        r'fn\s+([A-Za-z_][A-Za-z0-9_]*)'
    )
    impl_re = re.compile(r'^impl(?:<[^>]*>)?\s+(?:[\w<>, :&\'*]+\s+for\s+)?([A-Za-z_]\w*)')

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

        current_impl = None
        brace_depth = 0

        for i, line in enumerate(lines):
            stripped = line.strip()
            if not stripped.startswith("//"):
                brace_depth += stripped.count("{") - stripped.count("}")

            impl_m = impl_re.match(stripped)
            if impl_m:
                current_impl = impl_m.group(1)

            if brace_depth <= 0:
                current_impl = None
                brace_depth = 0

            fn_m = pub_fn_re.match(stripped)
            if fn_m:
                fn_name = fn_m.group(1)
                full_name = f"{current_impl}::{fn_name}" if current_impl else fn_name
                items.append({
                    "module": mod_name,
                    "name": fn_name,
                    "full_name": full_name,
                    "file": rel,
                    "line": i + 1,
                    "impl_type": current_impl or "",
                })

    return items


def collect_lua_api_fns(module_filter: str = None) -> List[dict]:
    """Collect all Lua API functions from gen_lua_api.py JSON data."""
    # Import and use gen_lua_api directly (lives in tools/docs/)
    sys.path.insert(0, str(WORKSPACE_ROOT / "tools" / "docs"))
    import gen_lua_api

    all_fns = gen_lua_api.collect_all_functions(WORKSPACE_ROOT / "src" / "lua_api")
    items = []
    for module, funcs in all_fns.items():
        if module_filter and module != module_filter:
            continue
        for func in funcs:
            items.append({
                "module": module,
                "name": func.name,
                "lua_name": func.lua_name,
                "kind": func.kind,
                "owner_type": func.owner_type,
                "file": func.file,
                "line": func.line,
            })
    return items


def _load_test_content(test_file: Path) -> str:
    """Load and lowercase a test file for searching."""
    try:
        return test_file.read_text(encoding="utf-8").lower()
    except OSError:
        return ""


def analyze_rust_coverage(
    pub_fns: List[dict], tests_dir: Path
) -> Tuple[List[dict], List[dict]]:
    """Determine which public Rust functions appear in test files."""
    # Load all test files
    test_contents: Dict[str, str] = {}
    for tf in sorted(tests_dir.rglob("*.rs")):
        test_contents[tf.stem] = _load_test_content(tf)

    covered = []
    uncovered = []

    for fn_info in pub_fns:
        fn_name = fn_info["name"].lower()
        mod = fn_info["module"]
        found = False

        # Check module-specific test file first
        for test_name, content in test_contents.items():
            if mod in test_name or test_name.replace("_tests", "") == mod:
                if fn_name in content:
                    found = True
                    break

        # Also check all test files
        if not found:
            for content in test_contents.values():
                if fn_name in content:
                    found = True
                    break

        if found:
            covered.append(fn_info)
        else:
            uncovered.append(fn_info)

    return covered, uncovered


def analyze_lua_coverage(
    lua_fns: List[dict], lua_tests_dir: Path
) -> Tuple[List[dict], List[dict]]:
    """Determine which Lua API functions appear in Lua test files."""
    test_contents: Dict[str, str] = {}
    for tf in sorted(lua_tests_dir.rglob("*.lua")):
        test_contents[tf.stem] = _load_test_content(tf)

    covered = []
    uncovered = []

    for fn_info in lua_fns:
        fn_name = fn_info["name"].lower()
        mod = fn_info["module"]
        found = False

        # Check module-specific Lua test file
        for test_name, content in test_contents.items():
            if mod in test_name:
                if fn_name in content:
                    found = True
                    break

        # Check all Lua test files
        if not found:
            for content in test_contents.values():
                if fn_name in content:
                    found = True
                    break

        if found:
            covered.append(fn_info)
        else:
            uncovered.append(fn_info)

    return covered, uncovered


def generate_report(
    rust_covered, rust_uncovered,
    lua_covered, lua_uncovered,
    module_filter=None,
) -> str:
    """Generate a Markdown coverage report."""
    lines = ["# Luna2D Test Coverage Report", ""]

    if module_filter:
        lines.append(f"*Filtered to module: `{module_filter}`*")
        lines.append("")

    # Summary
    rust_total = len(rust_covered) + len(rust_uncovered)
    lua_total = len(lua_covered) + len(lua_uncovered)
    rust_pct = round(len(rust_covered) / rust_total * 100, 1) if rust_total else 100.0
    lua_pct = round(len(lua_covered) / lua_total * 100, 1) if lua_total else 100.0

    lines.append("## Summary")
    lines.append("")
    lines.append("| Category | Covered | Total | Coverage |")
    lines.append("|----------|---------|-------|----------|")
    lines.append(f"| Rust public functions | {len(rust_covered)} | {rust_total} | {rust_pct}% |")
    lines.append(f"| Lua API functions | {len(lua_covered)} | {lua_total} | {lua_pct}% |")
    lines.append("")

    # Per-module Rust coverage
    lines.append("## Rust Coverage by Module")
    lines.append("")
    lines.append("| Module | Covered | Total | Coverage |")
    lines.append("|--------|---------|-------|----------|")
    mod_stats: Dict[str, dict] = {}
    for fn in rust_covered:
        mod_stats.setdefault(fn["module"], {"covered": 0, "total": 0})
        mod_stats[fn["module"]]["covered"] += 1
        mod_stats[fn["module"]]["total"] += 1
    for fn in rust_uncovered:
        mod_stats.setdefault(fn["module"], {"covered": 0, "total": 0})
        mod_stats[fn["module"]]["total"] += 1
    for mod_name, stats in sorted(mod_stats.items()):
        pct = round(stats["covered"] / stats["total"] * 100, 1) if stats["total"] else 0
        lines.append(f"| {mod_name} | {stats['covered']} | {stats['total']} | {pct}% |")
    lines.append("")

    # Per-module Lua coverage
    lines.append("## Lua API Coverage by Module")
    lines.append("")
    lines.append("| Module | Covered | Total | Coverage |")
    lines.append("|--------|---------|-------|----------|")
    lua_mod_stats: Dict[str, dict] = {}
    for fn in lua_covered:
        lua_mod_stats.setdefault(fn["module"], {"covered": 0, "total": 0})
        lua_mod_stats[fn["module"]]["covered"] += 1
        lua_mod_stats[fn["module"]]["total"] += 1
    for fn in lua_uncovered:
        lua_mod_stats.setdefault(fn["module"], {"covered": 0, "total": 0})
        lua_mod_stats[fn["module"]]["total"] += 1
    for mod_name, stats in sorted(lua_mod_stats.items()):
        pct = round(stats["covered"] / stats["total"] * 100, 1) if stats["total"] else 0
        lines.append(f"| {mod_name} | {stats['covered']} | {stats['total']} | {pct}% |")
    lines.append("")

    # Uncovered Rust functions (top 50)
    if rust_uncovered:
        lines.append("## Uncovered Rust Functions (top 50)")
        lines.append("")
        for fn in rust_uncovered[:50]:
            lines.append(f"- `{fn['full_name']}` in `{fn['file']}:{fn['line']}`")
        if len(rust_uncovered) > 50:
            lines.append(f"- ... and {len(rust_uncovered) - 50} more")
        lines.append("")

    # Uncovered Lua functions (top 50)
    if lua_uncovered:
        lines.append("## Uncovered Lua API Functions (top 50)")
        lines.append("")
        for fn in lua_uncovered[:50]:
            lines.append(f"- `{fn['lua_name']}` ({fn['kind']}) in `{fn['file']}:{fn['line']}`")
        if len(lua_uncovered) > 50:
            lines.append(f"- ... and {len(lua_uncovered) - 50} more")
        lines.append("")

    return "\n".join(lines)


def generate_suggestions(rust_uncovered, lua_uncovered) -> str:
    """Generate test stub suggestions for uncovered items."""
    lines = ["# Test Suggestions for Uncovered Items", ""]

    if rust_uncovered:
        lines.append("## Rust Test Stubs")
        lines.append("")

        by_module: Dict[str, List[dict]] = {}
        for fn in rust_uncovered:
            by_module.setdefault(fn["module"], []).append(fn)

        for mod_name, fns in sorted(by_module.items()):
            lines.append(f"### {mod_name}")
            lines.append("")
            lines.append("```rust")
            for fn in fns[:10]:
                test_name = f"test_{fn['name'].lower()}"
                lines.append(f"#[test]")
                lines.append(f"fn {test_name}() {{")
                if fn["impl_type"]:
                    lines.append(f"    // Test {fn['impl_type']}::{fn['name']}")
                else:
                    lines.append(f"    // Test {fn['name']}")
                lines.append(f"    todo!()")
                lines.append(f"}}")
                lines.append("")
            lines.append("```")
            lines.append("")

    if lua_uncovered:
        lines.append("## Lua Test Stubs")
        lines.append("")

        by_module: Dict[str, List[dict]] = {}
        for fn in lua_uncovered:
            by_module.setdefault(fn["module"], []).append(fn)

        for mod_name, fns in sorted(by_module.items()):
            lines.append(f"### {mod_name}")
            lines.append("")
            lines.append("```lua")
            lines.append(f'describe("luna.{mod_name}", function()')
            for fn in fns[:10]:
                lines.append(f'  it("{fn["name"]} should work", function()')
                if fn["kind"] == "function":
                    lines.append(f'    local result = luna.{mod_name}.{fn["name"]}()')
                    lines.append(f'    expect_not_nil(result)')
                else:
                    lines.append(f'    -- Test {fn["lua_name"]}()')
                lines.append(f'  end)')
            lines.append(f'end)')
            lines.append("```")
            lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Luna2D test coverage analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON")
    parser.add_argument("--suggest", action="store_true",
                        help="Print test stubs for uncovered items")
    parser.add_argument("--module", metavar="NAME",
                        help="Filter to a specific module")
    parser.add_argument("--output", metavar="FILE",
                        help="Save report to file")
    parser.add_argument("--threshold", type=float, default=50.0,
                        help="Coverage threshold %% (default: 50)")
    args = parser.parse_args()

    print("[INFO] Collecting public Rust functions...", file=sys.stderr)
    rust_fns = collect_rust_public_fns(SRC_DIR, args.module)
    print(f"[INFO] Found {len(rust_fns)} public Rust functions", file=sys.stderr)

    print("[INFO] Collecting Lua API functions...", file=sys.stderr)
    lua_fns = collect_lua_api_fns(args.module)
    print(f"[INFO] Found {len(lua_fns)} Lua API functions", file=sys.stderr)

    print("[INFO] Analyzing Rust test coverage...", file=sys.stderr)
    rust_covered, rust_uncovered = analyze_rust_coverage(rust_fns, TESTS_DIR)

    print("[INFO] Analyzing Lua test coverage...", file=sys.stderr)
    lua_covered, lua_uncovered = analyze_lua_coverage(lua_fns, LUA_TESTS_DIR)

    rust_total = len(rust_covered) + len(rust_uncovered)
    lua_total = len(lua_covered) + len(lua_uncovered)
    rust_pct = round(len(rust_covered) / rust_total * 100, 1) if rust_total else 100.0
    lua_pct = round(len(lua_covered) / lua_total * 100, 1) if lua_total else 100.0

    if args.suggest:
        report = generate_suggestions(rust_uncovered, lua_uncovered)
    elif args.json:
        report = json.dumps({
            "rust": {
                "total": rust_total,
                "covered": len(rust_covered),
                "uncovered": len(rust_uncovered),
                "coverage_pct": rust_pct,
                "uncovered_items": [
                    {"module": f["module"], "name": f["full_name"],
                     "file": f["file"], "line": f["line"]}
                    for f in rust_uncovered
                ],
            },
            "lua": {
                "total": lua_total,
                "covered": len(lua_covered),
                "uncovered": len(lua_uncovered),
                "coverage_pct": lua_pct,
                "uncovered_items": [
                    {"module": f["module"], "lua_name": f["lua_name"],
                     "kind": f["kind"], "file": f["file"], "line": f["line"]}
                    for f in lua_uncovered
                ],
            },
        }, indent=2)
    else:
        report = generate_report(
            rust_covered, rust_uncovered,
            lua_covered, lua_uncovered,
            args.module,
        )

    # Always write JSON metadata to docs/logs/test_coverage.json (unless --json stdout mode)
    if not args.json:
        json_payload = {
            "rust": {
                "total": rust_total,
                "covered": len(rust_covered),
                "uncovered": len(rust_uncovered),
                "coverage_pct": rust_pct,
                "covered_items": [
                    {"module": f["module"], "name": f["full_name"],
                     "file": f["file"], "line": f["line"]}
                    for f in rust_covered
                ],
                "uncovered_items": [
                    {"module": f["module"], "name": f["full_name"],
                     "file": f["file"], "line": f["line"]}
                    for f in rust_uncovered
                ],
            },
            "lua": {
                "total": lua_total,
                "covered": len(lua_covered),
                "uncovered": len(lua_uncovered),
                "coverage_pct": lua_pct,
                "covered_items": [
                    {"module": f["module"], "lua_name": f["lua_name"],
                     "kind": f["kind"], "file": f["file"], "line": f["line"]}
                    for f in lua_covered
                ],
                "uncovered_items": [
                    {"module": f["module"], "lua_name": f["lua_name"],
                     "kind": f["kind"], "file": f["file"], "line": f["line"]}
                    for f in lua_uncovered
                ],
            },
        }
        DEFAULT_JSON_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        DEFAULT_JSON_OUTPUT.write_text(json.dumps(json_payload, indent=2), encoding="utf-8")
        print(f"[OK] Coverage JSON written to docs/logs/test_coverage.json", file=sys.stderr)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    print(
        f"[INFO] Rust coverage: {rust_pct}% | Lua coverage: {lua_pct}%",
        file=sys.stderr,
    )

    if rust_pct >= args.threshold and lua_pct >= args.threshold:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
