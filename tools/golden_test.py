#!/usr/bin/env python3
"""
golden_test.py — Luna2D golden file comparison tests.

Compares output files (text, data, serialized state) against known-good
reference files stored in tests/golden/. Used for regression testing
of deterministic outputs (math tables, physics state, serialized data).

Usage:
    python tools/golden_test.py                    # run all golden tests
    python tools/golden_test.py --update           # regenerate reference files
    python tools/golden_test.py --json             # JSON output
    python tools/golden_test.py --output FILE      # save report to file
    python tools/golden_test.py --help

Exit codes:
    0  - all golden tests pass
    1  - mismatches found
    2  - fatal error
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Dict, List

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
GOLDEN_DIR = WORKSPACE_ROOT / "tests" / "golden"
GOLDEN_ACTUAL_DIR = GOLDEN_DIR / "actual"
GOLDEN_EXPECTED_DIR = GOLDEN_DIR / "expected"


def _file_hash(path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    try:
        h.update(path.read_bytes())
    except OSError:
        return ""
    return h.hexdigest()


def _text_diff(expected: Path, actual: Path) -> List[str]:
    """Compute a simple line diff between two text files."""
    try:
        exp_lines = expected.read_text(encoding="utf-8").splitlines()
        act_lines = actual.read_text(encoding="utf-8").splitlines()
    except OSError:
        return ["Could not read one or both files"]

    diffs = []
    max_lines = max(len(exp_lines), len(act_lines))
    for i in range(min(max_lines, 20)):
        exp = exp_lines[i] if i < len(exp_lines) else "<missing>"
        act = act_lines[i] if i < len(act_lines) else "<missing>"
        if exp != act:
            diffs.append(f"Line {i + 1}:")
            diffs.append(f"  expected: {exp[:100]}")
            diffs.append(f"  actual:   {act[:100]}")

    if len(exp_lines) != len(act_lines):
        diffs.append(f"Line count: expected {len(exp_lines)}, got {len(act_lines)}")

    return diffs


def discover_golden_tests() -> List[dict]:
    """Discover golden test files by scanning expected/ directory."""
    tests = []

    if not GOLDEN_EXPECTED_DIR.exists():
        return tests

    for expected_file in sorted(GOLDEN_EXPECTED_DIR.rglob("*")):
        if expected_file.is_file():
            rel = expected_file.relative_to(GOLDEN_EXPECTED_DIR)
            actual_file = GOLDEN_ACTUAL_DIR / rel

            tests.append({
                "name": str(rel).replace("\\", "/"),
                "expected": str(expected_file),
                "actual": str(actual_file),
                "expected_exists": expected_file.exists(),
                "actual_exists": actual_file.exists(),
            })

    return tests


def run_golden_tests(tests: List[dict]) -> List[dict]:
    """Compare actual files against expected golden files."""
    results = []

    for test in tests:
        expected = Path(test["expected"])
        actual = Path(test["actual"])

        result = {
            "name": test["name"],
            "status": "unknown",
            "expected_hash": "",
            "actual_hash": "",
            "diff": [],
        }

        if not expected.exists():
            result["status"] = "missing_expected"
            results.append(result)
            continue

        if not actual.exists():
            result["status"] = "missing_actual"
            results.append(result)
            continue

        exp_hash = _file_hash(expected)
        act_hash = _file_hash(actual)
        result["expected_hash"] = exp_hash
        result["actual_hash"] = act_hash

        if exp_hash == act_hash:
            result["status"] = "pass"
        else:
            result["status"] = "mismatch"
            # Try text diff
            if expected.suffix in (".txt", ".json", ".csv", ".lua", ".toml"):
                result["diff"] = _text_diff(expected, actual)

        results.append(result)

    return results


def update_golden_files(tests: List[dict]) -> int:
    """Copy actual files to expected/ directory to update golden files."""
    updated = 0
    for test in tests:
        actual = Path(test["actual"])
        expected = Path(test["expected"])

        if actual.exists():
            expected.parent.mkdir(parents=True, exist_ok=True)
            expected.write_bytes(actual.read_bytes())
            updated += 1
            print(f"  Updated: {test['name']}", file=sys.stderr)

    return updated


def generate_report(results: List[dict]) -> str:
    """Generate a Markdown golden test report."""
    lines = [
        "# Luna2D Golden File Test Report",
        "",
    ]

    pass_count = sum(1 for r in results if r["status"] == "pass")
    fail_count = sum(1 for r in results if r["status"] == "mismatch")
    missing_count = sum(1 for r in results if r["status"].startswith("missing"))

    lines.extend([
        "## Summary",
        "",
        f"| Status | Count |",
        f"|--------|-------|",
        f"| Pass | {pass_count} |",
        f"| Mismatch | {fail_count} |",
        f"| Missing | {missing_count} |",
        f"| Total | {len(results)} |",
        "",
    ])

    if fail_count > 0:
        lines.append("## Mismatches")
        lines.append("")
        for r in results:
            if r["status"] == "mismatch":
                lines.append(f"### {r['name']}")
                lines.append(f"- Expected hash: `{r['expected_hash'][:16]}...`")
                lines.append(f"- Actual hash: `{r['actual_hash'][:16]}...`")
                if r["diff"]:
                    lines.append("```")
                    for d in r["diff"][:10]:
                        lines.append(d)
                    lines.append("```")
                lines.append("")

    if missing_count > 0:
        lines.append("## Missing Files")
        lines.append("")
        for r in results:
            if r["status"] == "missing_actual":
                lines.append(f"- {r['name']}: actual file not found")
            elif r["status"] == "missing_expected":
                lines.append(f"- {r['name']}: expected file not found")
        lines.append("")

    lines.extend([
        "## How to Use",
        "",
        "```powershell",
        "# Run golden tests",
        "python tools/golden_test.py",
        "",
        "# Update expected files from actual output",
        "python tools/golden_test.py --update",
        "```",
        "",
    ])

    return "\n".join(lines)


def ensure_dirs():
    """Create golden test directories if they don't exist."""
    GOLDEN_DIR.mkdir(parents=True, exist_ok=True)
    GOLDEN_ACTUAL_DIR.mkdir(parents=True, exist_ok=True)
    GOLDEN_EXPECTED_DIR.mkdir(parents=True, exist_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Luna2D golden file comparison tests",
    )
    parser.add_argument("--update", action="store_true",
                        help="Update expected files from actual")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--output", metavar="FILE")
    args = parser.parse_args()

    ensure_dirs()

    tests = discover_golden_tests()

    if args.update:
        count = update_golden_files(tests)
        print(f"[OK] Updated {count} golden files", file=sys.stderr)
        return 0

    if not tests:
        print("[INFO] No golden test files found. Run with --update after generating actual output.", file=sys.stderr)

    results = run_golden_tests(tests)

    if args.json:
        report = json.dumps(results, indent=2)
    else:
        report = generate_report(results)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    mismatches = sum(1 for r in results if r["status"] == "mismatch")
    return 1 if mismatches > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
