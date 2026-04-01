#!/usr/bin/env python3
"""
quality_report.py — Luna2D master quality report.

Aggregates documentation audit, test coverage, API validation, and module
audit into a single quality dashboard. This is the one-stop script for
assessing overall project health.

Usage:
    python tools/quality_report.py                 # full report
    python tools/quality_report.py --json          # JSON output
    python tools/quality_report.py --output FILE   # save to file
    python tools/quality_report.py --help

Exit codes:
    0  - all gates pass
    1  - one or more gates fail
    2  - fatal error
"""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
TOOLS_DIR = WORKSPACE_ROOT / "tools"


def _run_tool(script: str, extra_args: list = None) -> dict:
    """Run a tools/ script with --json and return parsed output."""
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
        tmp = Path(f.name)

    cmd = [sys.executable, str(TOOLS_DIR / script), "--json", "--output", str(tmp)]
    if extra_args:
        cmd.extend(extra_args)

    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")

    try:
        data = json.loads(tmp.read_text(encoding="utf-8"))
    except Exception:
        data = {"error": f"{script} failed: {result.stderr[:200]}"}
    finally:
        tmp.unlink(missing_ok=True)

    return data


def generate_report(
    doc_data: dict,
    test_data: dict,
    module_data: dict,
    validation_data: dict,
) -> str:
    """Generate the master quality Markdown report."""
    lines = [
        "# Luna2D Quality Report",
        "",
        "## Dashboard",
        "",
        "| Metric | Value | Gate |",
        "|--------|-------|------|",
    ]

    # Doc coverage
    rust_doc = doc_data.get("rust", {})
    lua_doc = doc_data.get("lua_api", {})
    rust_doc_pct = rust_doc.get("coverage_pct", 0)
    lua_doc_pct = lua_doc.get("coverage_pct", 0)
    lines.append(f"| Rust doc coverage | {rust_doc_pct}% | {'PASS' if rust_doc_pct >= 90 else 'FAIL'} |")
    lines.append(f"| Lua API doc coverage | {lua_doc_pct}% | {'PASS' if lua_doc_pct >= 50 else 'FAIL'} |")

    # Test coverage
    rust_test = test_data.get("rust", {})
    lua_test = test_data.get("lua", {})
    rust_test_pct = rust_test.get("coverage_pct", 0)
    lua_test_pct = lua_test.get("coverage_pct", 0)
    lines.append(f"| Rust test coverage | {rust_test_pct}% | {'PASS' if rust_test_pct >= 50 else 'FAIL'} |")
    lines.append(f"| Lua test coverage | {lua_test_pct}% | {'PASS' if lua_test_pct >= 30 else 'FAIL'} |")

    # API validation
    total_issues = 0
    if isinstance(validation_data, dict):
        for game_results in validation_data.values():
            if isinstance(game_results, dict):
                for issues in game_results.values():
                    if isinstance(issues, list):
                        total_issues += len(issues)
    lines.append(f"| API validation issues | {total_issues} | {'PASS' if total_issues == 0 else 'WARN'} |")

    # Module count
    luna_count = len(module_data.get("luna_modules", {}))
    lines.append(f"| Luna2D modules | {luna_count} | — |")

    # Total items
    rust_items = rust_doc.get("total_items", 0)
    lua_fns = lua_doc.get("total_functions", 0)
    lines.append(f"| Total public Rust items | {rust_items} | — |")
    lines.append(f"| Total Lua API functions | {lua_fns} | — |")

    lines.append("")

    # Detailed sections
    lines.extend([
        "## Documentation",
        "",
        f"- **Rust**: {rust_doc.get('documented', 0)}/{rust_items} items documented ({rust_doc_pct}%)",
        f"- **Lua API**: {lua_doc.get('documented', 0)}/{lua_fns} functions documented ({lua_doc_pct}%)",
        f"- **Missing Rust docs**: {rust_doc.get('missing', 0)} items",
        f"- **Missing Lua docs**: {lua_doc.get('missing_count', 0)} functions",
        "",
    ])

    lines.extend([
        "## Test Coverage",
        "",
        f"- **Rust**: {rust_test.get('covered', 0)}/{rust_test.get('total', 0)} functions covered ({rust_test_pct}%)",
        f"- **Lua**: {lua_test.get('covered', 0)}/{lua_test.get('total', 0)} functions covered ({lua_test_pct}%)",
        "",
    ])

    lines.extend([
        "## API Validation",
        "",
        f"- **Issues found**: {total_issues}",
        "",
    ])

    if total_issues > 0 and isinstance(validation_data, dict):
        for game_name, game_results in sorted(validation_data.items()):
            if isinstance(game_results, dict):
                game_issues = sum(
                    len(issues) for issues in game_results.values()
                    if isinstance(issues, list)
                )
                if game_issues > 0:
                    lines.append(f"  - **{game_name}**: {game_issues} issues")
        lines.append("")

    # Overall verdict
    all_pass = (
        rust_doc_pct >= 90
        and lua_doc_pct >= 50
        and rust_test_pct >= 50
        and lua_test_pct >= 30
        and total_issues == 0
    )
    lines.extend([
        "## Overall Verdict",
        "",
        f"**{'PASS' if all_pass else 'FAIL'}**",
        "",
    ])

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Luna2D master quality report",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON")
    parser.add_argument("--output", metavar="FILE",
                        help="Save report to file")
    args = parser.parse_args()

    print("[1/4] Running documentation audit...", file=sys.stderr)
    doc_data = _run_tool("doc_audit.py")

    print("[2/4] Running test coverage analysis...", file=sys.stderr)
    test_data = _run_tool("test_coverage.py")

    print("[3/4] Running module audit...", file=sys.stderr)
    module_data = _run_tool("module_audit.py")

    print("[4/4] Running API validation...", file=sys.stderr)
    validation_data = _run_tool("validate_game.py", ["--all-examples"])

    if args.json:
        report = json.dumps({
            "documentation": doc_data,
            "test_coverage": test_data,
            "modules": module_data,
            "validation": validation_data,
        }, indent=2, ensure_ascii=False)
    else:
        report = generate_report(doc_data, test_data, module_data, validation_data)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    return 0


if __name__ == "__main__":
    sys.exit(main())
