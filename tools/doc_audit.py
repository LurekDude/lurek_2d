#!/usr/bin/env python3
"""
doc_audit.py — Luna2D unified documentation audit.

Runs both collect_docs.py and gen_lua_api.py to produce a combined
documentation coverage report. Shows per-module breakdowns for both
Rust source docs and Lua API docs.

Usage:
    python tools/doc_audit.py                  # print summary report
    python tools/doc_audit.py --json           # structured JSON report
    python tools/doc_audit.py --output FILE    # save report to file
    python tools/doc_audit.py --help

Exit codes:
    0  - all items documented (coverage >= threshold)
    1  - documentation gaps found
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


def _run_json_tool(script: str, extra_args: list = None) -> dict:
    """Run a tools/ script with --json and return parsed output."""
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
        tmp = Path(f.name)

    cmd = [sys.executable, str(TOOLS_DIR / script), "--json", "--output", str(tmp)]
    if extra_args:
        cmd.extend(extra_args)

    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if result.returncode != 0:
        print(f"[ERROR] {script} failed:\n{result.stderr}", file=sys.stderr)
        return {}

    try:
        data = json.loads(tmp.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ERROR] Failed to parse {script} output: {e}", file=sys.stderr)
        data = {}
    finally:
        tmp.unlink(missing_ok=True)

    return data


def _analyze_rust_docs(data: dict) -> dict:
    """Analyze Rust documentation coverage from collect_docs.py JSON."""
    items = data.get("items", [])
    module_docs = data.get("module_docs", {})

    by_module = {}
    for item in items:
        # Extract module from file path: src/MODULE/...
        parts = item["file"].split("/")
        mod_name = parts[1] if len(parts) > 2 else "root"

        if mod_name not in by_module:
            by_module[mod_name] = {"total": 0, "documented": 0, "missing": []}

        by_module[mod_name]["total"] += 1
        if item["has_docs"]:
            by_module[mod_name]["documented"] += 1
        else:
            by_module[mod_name]["missing"].append({
                "kind": item["kind"],
                "name": item["name"],
                "file": item["file"],
                "line": item["line"],
            })

    total = len(items)
    documented = sum(1 for i in items if i["has_docs"])

    return {
        "total_items": total,
        "documented": documented,
        "missing": total - documented,
        "coverage_pct": round(documented / total * 100, 1) if total else 100.0,
        "module_docs_count": len(module_docs),
        "by_module": by_module,
    }


def _analyze_lua_api(data: dict) -> dict:
    """Analyze Lua API documentation coverage from gen_lua_api.py JSON."""
    summary = data.get("summary", {})
    functions = data.get("functions", [])

    total = len(functions)
    documented = sum(1 for f in functions if f.get("description"))
    missing = [
        {
            "lua_name": f["lua_name"],
            "module": f["module"],
            "kind": f["kind"],
            "file": f["file"],
            "line": f["line"],
        }
        for f in functions
        if not f.get("description")
    ]

    return {
        "total_functions": total,
        "documented": documented,
        "missing_count": total - documented,
        "coverage_pct": round(documented / total * 100, 1) if total else 100.0,
        "by_module": summary,
        "missing_items": missing[:50],  # cap for readability
    }


def generate_report(rust_analysis: dict, lua_analysis: dict) -> str:
    """Generate a human-readable Markdown report."""
    lines = [
        "# Luna2D Documentation Audit Report",
        "",
        "## Summary",
        "",
        f"| Metric | Count | Coverage |",
        f"|--------|-------|----------|",
        f"| Rust public items | {rust_analysis['total_items']} | {rust_analysis['coverage_pct']}% |",
        f"| Lua API functions | {lua_analysis['total_functions']} | {lua_analysis['coverage_pct']}% |",
        f"| Module-level docs | {rust_analysis['module_docs_count']} | — |",
        "",
    ]

    # Rust doc coverage by module
    lines.append("## Rust Documentation by Module")
    lines.append("")
    lines.append("| Module | Total | Documented | Missing | Coverage |")
    lines.append("|--------|-------|------------|---------|----------|")
    for mod_name, info in sorted(rust_analysis["by_module"].items()):
        pct = round(info["documented"] / info["total"] * 100, 1) if info["total"] else 100.0
        status = "✓" if pct == 100.0 else ""
        lines.append(
            f"| {mod_name} | {info['total']} | {info['documented']} | "
            f"{info['total'] - info['documented']} | {pct}% {status} |"
        )
    lines.append("")

    # Lua API coverage by module
    lines.append("## Lua API Documentation by Module")
    lines.append("")
    lines.append("| Module | Functions | Methods | Documented | Undocumented | Coverage |")
    lines.append("|--------|-----------|---------|------------|--------------|----------|")
    for mod_name, info in sorted(lua_analysis["by_module"].items()):
        pct = round(info["documented"] / info["total"] * 100, 1) if info["total"] else 100.0
        lines.append(
            f"| {mod_name} | {info['functions']} | {info['methods']} | "
            f"{info['documented']} | {info['undocumented']} | {pct}% |"
        )
    lines.append("")

    # Missing Rust docs
    all_missing_rust = []
    for mod_name, info in rust_analysis["by_module"].items():
        all_missing_rust.extend(info["missing"])

    if all_missing_rust:
        lines.append("## Missing Rust Docstrings")
        lines.append("")
        for item in all_missing_rust[:30]:
            lines.append(f"- `{item['kind']} {item['name']}` in `{item['file']}:{item['line']}`")
        if len(all_missing_rust) > 30:
            lines.append(f"- ... and {len(all_missing_rust) - 30} more")
        lines.append("")

    # Missing Lua docs (top items)
    if lua_analysis["missing_items"]:
        lines.append("## Missing Lua API Docstrings (top 50)")
        lines.append("")
        for item in lua_analysis["missing_items"]:
            lines.append(f"- `{item['lua_name']}` ({item['kind']}) in `{item['file']}:{item['line']}`")
        if lua_analysis["missing_count"] > 50:
            lines.append(f"- ... and {lua_analysis['missing_count'] - 50} more")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Luna2D unified documentation audit",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON report")
    parser.add_argument("--output", metavar="FILE",
                        help="Save report to file (default: stdout)")
    parser.add_argument("--threshold", type=float, default=90.0,
                        help="Coverage threshold %% (default: 90)")
    args = parser.parse_args()

    print("[INFO] Running Rust documentation scan...", file=sys.stderr)
    rust_data = _run_json_tool("collect_docs.py")
    if not rust_data:
        return 2

    print("[INFO] Running Lua API scan...", file=sys.stderr)
    lua_data = _run_json_tool("gen_lua_api.py", ["--src", str(WORKSPACE_ROOT / "src" / "lua_api")])
    if not lua_data:
        return 2

    rust_analysis = _analyze_rust_docs(rust_data)
    lua_analysis = _analyze_lua_api(lua_data)

    if args.json:
        report = json.dumps({
            "rust": rust_analysis,
            "lua_api": lua_analysis,
        }, indent=2, ensure_ascii=False)
    else:
        report = generate_report(rust_analysis, lua_analysis)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    # Exit code based on coverage
    rust_ok = rust_analysis["coverage_pct"] >= args.threshold
    lua_ok = lua_analysis["coverage_pct"] >= args.threshold

    if rust_ok and lua_ok:
        print(
            f"[OK] Coverage above {args.threshold}%: "
            f"Rust={rust_analysis['coverage_pct']}%, Lua={lua_analysis['coverage_pct']}%",
            file=sys.stderr,
        )
        return 0
    else:
        print(
            f"[WARN] Coverage below {args.threshold}%: "
            f"Rust={rust_analysis['coverage_pct']}%, Lua={lua_analysis['coverage_pct']}%",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
