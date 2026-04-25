#!/usr/bin/env python3
"""
gen_test_docs.py — Generate human-readable test documentation for Lurek2D.

Reads logs/data/test_coverage.json (produced by test_coverage.py) and generates
Markdown documents describing what each module tests, coverage statistics, and
a prioritised list of uncovered items.

Usage:
    python tools/gen_test_docs.py                          # logs/reports/test_docs.md (all)
    python tools/gen_test_docs.py --mode rust              # logs/reports/test_docs_rust.md
    python tools/gen_test_docs.py --mode lua               # logs/reports/test_docs_lua.md
    python tools/gen_test_docs.py --output FILE            # custom output path
    python tools/gen_test_docs.py --input FILE             # custom input JSON path
    python tools/gen_test_docs.py --help

Exit codes:
    0 — success
    1 — fatal error (missing input)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_INPUT = WORKSPACE_ROOT / "logs" / "data" / "test_coverage.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "logs" / "reports" / "test_docs.md"
DEFAULT_OUTPUT_RUST = WORKSPACE_ROOT / "logs" / "reports" / "test_docs_rust.md"
DEFAULT_OUTPUT_LUA = WORKSPACE_ROOT / "logs" / "reports" / "test_docs_lua.md"
TESTS_DIR = WORKSPACE_ROOT / "tests" / "rust"

# Matches a Rust test function
_TEST_FN_RE = re.compile(r"^(?:pub\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")


def _collect_test_function_docs(tests_dir: Path) -> dict[str, dict[str, str]]:
    """
    Scan tests/*.rs and extract test function names with their doc comments.

    Returns: {module_name: {fn_name: doc_string}}
    """
    result: dict[str, dict[str, str]] = {}

    for rs_file in sorted(tests_dir.rglob("*.rs")):
        mod_name = rs_file.stem  # e.g. "physics_tests"
        docs: dict[str, str] = {}

        try:
            lines = rs_file.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        i = 0
        while i < len(lines):
            stripped = lines[i].strip()

            # Collect comment block above a #[test]
            if stripped == "#[test]" or stripped.startswith("#[test]"):
                # Look back for doc/comment lines
                comment_lines: list[str] = []
                for j in range(i - 1, max(i - 8, -1), -1):
                    prev = lines[j].strip()
                    if prev.startswith("///") or prev.startswith("//!"):
                        comment_lines.insert(0, prev.lstrip("/").strip())
                    elif prev.startswith("//"):
                        comment_lines.insert(0, prev.lstrip("/").strip())
                    elif prev.startswith("#["):
                        continue  # allow stacked attributes
                    elif prev:
                        break

                # Find the fn name (may be 1-2 lines after #[test])
                for k in range(i + 1, min(i + 4, len(lines))):
                    fn_m = _TEST_FN_RE.match(lines[k].strip())
                    if fn_m:
                        fn_name = fn_m.group(1)
                        docs[fn_name] = " ".join(comment_lines) if comment_lines else ""
                        break
            i += 1

        if docs:
            result[mod_name] = docs

    return result


def _module_short_name(mod_name: str) -> str:
    """Convert 'physics_tests' -> 'physics'."""
    return mod_name.replace("_tests", "").replace("_test", "")


def _bar(pct: float, width: int = 20) -> str:
    filled = int(pct / 100 * width)
    return "#" * filled + "-" * (width - filled)


def _generate_rust_section(data: dict, fn_docs: dict[str, dict[str, str]]) -> list[str]:
    """Generate the Rust tests section lines."""
    rust = data.get("rust", {})
    r_total = rust.get("total", 0)
    r_covered = rust.get("covered", 0)
    r_pct = rust.get("coverage_pct", 0.0)

    lines: list[str] = []
    lines.append(f"*Coverage: {r_covered}/{r_total} public functions tested ({r_pct}%) `{_bar(r_pct)}`*")
    lines.append("")
    lines.append("## Tests by Module")
    lines.append("")

    by_module: dict[str, dict] = {}
    for item in rust.get("covered_items", []):
        mod = _module_short_name(item.get("module", "unknown"))
        by_module.setdefault(mod, {"covered": [], "uncovered": []})
        by_module[mod]["covered"].append(item)
    for item in rust.get("uncovered_items", []):
        mod = _module_short_name(item.get("module", "unknown"))
        by_module.setdefault(mod, {"covered": [], "uncovered": []})
        by_module[mod]["uncovered"].append(item)

    for mod_name in sorted(by_module.keys()):
        data_mod = by_module[mod_name]
        n_covered = len(data_mod["covered"])
        n_total = n_covered + len(data_mod["uncovered"])
        pct = round(n_covered / n_total * 100, 1) if n_total else 0.0

        lines.append(f"### `{mod_name}` — {n_covered}/{n_total} ({pct}%)")
        lines.append("")

        test_mod_key = f"{mod_name}_tests"
        if test_mod_key in fn_docs:
            lines.append("**Test functions:**")
            lines.append("")
            for fn_name, doc in sorted(fn_docs[test_mod_key].items()):
                if doc:
                    lines.append(f"- `{fn_name}` — {doc}")
                else:
                    lines.append(f"- `{fn_name}`")
            lines.append("")

        if data_mod["uncovered"]:
            lines.append(f"**Uncovered public functions** ({len(data_mod['uncovered'])}):")
            lines.append("")
            for item in data_mod["uncovered"][:20]:
                lines.append(f"- `{item['name']}` in `{item['file']}:{item['line']}`")
            if len(data_mod["uncovered"]) > 20:
                lines.append(f"- *...and {len(data_mod['uncovered']) - 20} more*")
            lines.append("")

    lines.append("## How to Improve Coverage")
    lines.append("")
    lines.append("1. Run `python tools/test_coverage.py --suggest` to get test stubs for uncovered items")
    lines.append("2. Add test functions to the relevant `tests/rust/<module>_tests.rs` file")
    lines.append("3. Add `///` doc comments above each `#[test]` fn to explain what it verifies")
    lines.append("4. Re-run `python tools/gen_test_docs.py --mode rust` to regenerate")
    lines.append("")
    return lines


def _generate_lua_section(data: dict) -> list[str]:
    """Generate the Lua API tests section lines."""
    lua = data.get("lua", {})
    l_total = lua.get("total", 0)
    l_covered = lua.get("covered", 0)
    l_pct = lua.get("coverage_pct", 0.0)

    lines: list[str] = []
    lines.append(f"*Coverage: {l_covered}/{l_total} Lua API functions tested ({l_pct}%) `{_bar(l_pct)}`*")
    lines.append("")
    lines.append("## Tests by Module")
    lines.append("")

    lua_by_module: dict[str, dict] = {}
    for item in lua.get("covered_items", []):
        mod = item.get("module", "unknown")
        lua_by_module.setdefault(mod, {"covered": [], "uncovered": []})
        lua_by_module[mod]["covered"].append(item)
    for item in lua.get("uncovered_items", []):
        mod = item.get("module", "unknown")
        lua_by_module.setdefault(mod, {"covered": [], "uncovered": []})
        lua_by_module[mod]["uncovered"].append(item)

    for mod_name in sorted(lua_by_module.keys()):
        data_mod = lua_by_module[mod_name]
        n_covered = len(data_mod["covered"])
        n_total = n_covered + len(data_mod["uncovered"])
        pct = round(n_covered / n_total * 100, 1) if n_total else 0.0

        lines.append(f"### `{mod_name}` — {n_covered}/{n_total} ({pct}%)")
        lines.append("")

        if data_mod["uncovered"]:
            lines.append(f"**Uncovered Lua API functions** ({len(data_mod['uncovered'])}):")
            lines.append("")
            for item in data_mod["uncovered"][:20]:
                lines.append(f"- `lurek.{mod_name}.{item.get('lua_name', item.get('name', '?'))}`")
            if len(data_mod["uncovered"]) > 20:
                lines.append(f"- *...and {len(data_mod['uncovered']) - 20} more*")
            lines.append("")

    lines.append("## How to Improve Coverage")
    lines.append("")
    lines.append("1. Write `describe`/`it`/`expect_*` blocks in `tests/lua/unit/test_<module>.lua`")
    lines.append("2. Ensure every `lurek.*` function has at least one test")
    lines.append("3. Re-run `python tools/gen_test_docs.py --mode lua` to regenerate")
    lines.append("")
    return lines


def generate_markdown(data: dict, fn_docs: dict[str, dict[str, str]], mode: str = "all") -> str:
    rust = data.get("rust", {})
    lua = data.get("lua", {})

    lines: list[str] = []

    if mode == "rust":
        lines.append("# Lurek2D Rust Test Documentation")
        lines.append("")
        lines.append("> Auto-generated by `tools/gen_test_docs.py --mode rust`. Do not edit manually.")
        lines.append("> Re-run: `python tools/gen_test_docs.py --mode rust`")
        lines.append("")
        lines += _generate_rust_section(data, fn_docs)
    elif mode == "lua":
        lines.append("# Lurek2D Lua API Test Documentation")
        lines.append("")
        lines.append("> Auto-generated by `tools/gen_test_docs.py --mode lua`. Do not edit manually.")
        lines.append("> Re-run: `python tools/gen_test_docs.py --mode lua`")
        lines.append("")
        lines += _generate_lua_section(data)
    else:
        r_total = rust.get("total", 0)
        r_covered = rust.get("covered", 0)
        r_pct = rust.get("coverage_pct", 0.0)
        l_total = lua.get("total", 0)
        l_covered = lua.get("covered", 0)
        l_pct = lua.get("coverage_pct", 0.0)

        lines.append("# Lurek2D Test Documentation")
        lines.append("")
        lines.append("> Auto-generated by `tools/gen_test_docs.py`. Do not edit manually.")
        lines.append("")
        lines.append("## Coverage Summary")
        lines.append("")
        lines.append("| Layer | Covered | Total | Coverage |")
        lines.append("|-------|---------|-------|----------|")
        lines.append(f"| Rust public functions | {r_covered} | {r_total} | {r_pct}% `{_bar(r_pct)}` |")
        lines.append(f"| Lua API functions | {l_covered} | {l_total} | {l_pct}% `{_bar(l_pct)}` |")
        lines.append("")
        lines.append("## Rust Tests by Module")
        lines.append("")
        lines += _generate_rust_section(data, fn_docs)
        lines.append("## Lua API Tests by Module")
        lines.append("")
        lines += _generate_lua_section(data)

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate human-readable test documentation from test_coverage.json",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--input", metavar="FILE", default=str(DEFAULT_INPUT),
                        help=f"Input JSON path (default: {DEFAULT_INPUT})")
    parser.add_argument("--output", metavar="FILE", default=None,
                        help="Output Markdown path (default depends on --mode)")
    parser.add_argument("--mode", choices=["rust", "lua", "all"], default="all",
                        help="Which section to generate: rust, lua, or all (default: all)")
    args = parser.parse_args()

    # Determine output path based on mode
    if args.output is not None:
        # Expand relative paths from the workspace root
        out_path = Path(args.output)
        if not out_path.is_absolute():
            out_path = WORKSPACE_ROOT / out_path
    elif args.mode == "rust":
        out_path = DEFAULT_OUTPUT_RUST
    elif args.mode == "lua":
        out_path = DEFAULT_OUTPUT_LUA
    else:
        out_path = DEFAULT_OUTPUT

    input_path = Path(args.input)
    if not input_path.is_file():
        print(f"ERROR: Input file not found: {input_path}", file=sys.stderr)
        print("Run: python tools/test_coverage.py  (to generate logs/data/test_coverage.json first)",
              file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(input_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        print(f"ERROR: Failed to read {input_path}: {exc}", file=sys.stderr)
        sys.exit(1)

    fn_docs = _collect_test_function_docs(TESTS_DIR)
    md = generate_markdown(data, fn_docs, mode=args.mode)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(md, encoding="utf-8")

    rust_pct = data.get("rust", {}).get("coverage_pct", 0)
    lua_pct = data.get("lua", {}).get("coverage_pct", 0)
    try:
        rel = out_path.relative_to(WORKSPACE_ROOT)
    except ValueError:
        rel = out_path
    print(f"[OK] Test docs ({args.mode}) written → {rel}")
    print(f"     Rust coverage: {rust_pct}% | Lua coverage: {lua_pct}%")


if __name__ == "__main__":
    main()
