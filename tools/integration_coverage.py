#!/usr/bin/env python3
"""
integration_coverage.py — Luna2D integration test coverage analysis.

Analyzes integration tests in tests/lua/integration/ to determine which
module-pair combinations have test coverage. Produces a heat map.

Usage:
    python tools/integration_coverage.py                # coverage matrix
    python tools/integration_coverage.py --json         # JSON output
    python tools/integration_coverage.py --output FILE  # save to file
    python tools/integration_coverage.py --help
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, Set, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
INTEGRATION_DIR = WORKSPACE_ROOT / "tests" / "lua" / "integration"

# Module namespace patterns to detect in Lua code
MODULE_PATTERNS = {
    "math": r"luna\.math\.",
    "physics": r"luna\.physics\.",
    "graphics": r"luna\.graphics\.",
    "audio": r"luna\.audio\.",
    "input": r"luna\.input\.",
    "keyboard": r"luna\.keyboard\.",
    "mouse": r"luna\.mouse\.",
    "timer": r"luna\.timer\.",
    "filesystem": r"luna\.filesystem\.",
    "window": r"luna\.window\.",
    "system": r"luna\.system\.",
    "event": r"luna\.event\.",
    "data": r"luna\.data\.",
    "particle": r"luna\.particle\.",
    "tilemap": r"luna\.tilemap\.",
    "compute": r"luna\.compute\.",
    "dataframe": r"luna\.dataframe\.",
    "ai": r"luna\.ai\.",
    "graph": r"luna\.graph\.",
    "sound": r"luna\.sound\.",
    "image": r"luna\.image\.",
}


def analyze_integration_tests() -> Dict[str, Dict]:
    """Analyze integration test files for module usage."""
    results = {}

    if not INTEGRATION_DIR.exists():
        return results

    for lua_file in sorted(INTEGRATION_DIR.glob("*.lua")):
        try:
            content = lua_file.read_text(encoding="utf-8")
        except OSError:
            continue

        modules_used: Set[str] = set()
        for mod_name, pattern in MODULE_PATTERNS.items():
            if re.search(pattern, content):
                modules_used.add(mod_name)

        # Count tests in this file
        test_count = content.count('it("') + content.count("it('")

        results[lua_file.stem] = {
            "file": str(lua_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/"),
            "modules": sorted(modules_used),
            "test_count": test_count,
        }

    return results


def build_pair_matrix(
    test_results: Dict[str, Dict]
) -> Dict[Tuple[str, str], int]:
    """Build a module-pair coverage matrix."""
    pair_counts: Dict[Tuple[str, str], int] = {}
    all_modules = set()

    for test_info in test_results.values():
        mods = test_info["modules"]
        all_modules.update(mods)

        for i, m1 in enumerate(mods):
            for m2 in mods[i + 1:]:
                pair = (min(m1, m2), max(m1, m2))
                pair_counts[pair] = pair_counts.get(pair, 0) + test_info["test_count"]

    return pair_counts


def generate_report(
    test_results: Dict[str, Dict],
    pair_matrix: Dict[Tuple[str, str], int],
) -> str:
    """Generate a Markdown integration coverage report."""
    lines = [
        "# Luna2D Integration Test Coverage",
        "",
        "## Test Files",
        "",
        "| File | Modules | Tests |",
        "|------|---------|-------|",
    ]

    total_tests = 0
    for name, info in sorted(test_results.items()):
        total_tests += info["test_count"]
        lines.append(
            f"| {name} | {', '.join(info['modules'])} | {info['test_count']} |"
        )

    lines.append("")
    lines.append(f"**Total integration tests**: {total_tests}")
    lines.append("")

    # Module pair heat map
    lines.append("## Module-Pair Coverage")
    lines.append("")

    if pair_matrix:
        lines.append("| Module A | Module B | Tests |")
        lines.append("|----------|----------|-------|")
        for (m1, m2), count in sorted(pair_matrix.items()):
            lines.append(f"| {m1} | {m2} | {count} |")
    else:
        lines.append("No module pairs detected in integration tests.")

    lines.append("")

    # Missing pairs
    all_modules = set()
    for info in test_results.values():
        all_modules.update(info["modules"])

    covered_pairs = set(pair_matrix.keys())
    all_possible = set()
    mod_list = sorted(all_modules)
    for i, m1 in enumerate(mod_list):
        for m2 in mod_list[i + 1:]:
            all_possible.add((m1, m2))

    missing = all_possible - covered_pairs
    if missing:
        lines.append("## Untested Module Pairs")
        lines.append("")
        for m1, m2 in sorted(missing):
            lines.append(f"- {m1} + {m2}")

    lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Luna2D integration test coverage analysis",
    )
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--output", metavar="FILE")
    args = parser.parse_args()

    test_results = analyze_integration_tests()

    if not test_results:
        print("[WARN] No integration tests found in tests/lua/integration/",
              file=sys.stderr)

    pair_matrix = build_pair_matrix(test_results)

    if args.json:
        report = json.dumps({
            "tests": test_results,
            "pairs": {f"{k[0]}+{k[1]}": v for k, v in pair_matrix.items()},
        }, indent=2)
    else:
        report = generate_report(test_results, pair_matrix)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    return 0


if __name__ == "__main__":
    sys.exit(main())
