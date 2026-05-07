#!/usr/bin/env python3
"""lua_spec_coverage.py — Measure how completely docs/specs/<module>.md covers the lurek.* Lua API.

For every src/lua_api/<module>_api.rs that contains ``tbl.set("fn", ...)``
bindings, this tool reports:

  - bound_total:   total functions registered via tbl.set()
  - in_spec:       functions that appear by name in the spec's ## Lua API Reference section
  - missing:       bound functions absent from the spec
  - stale:         spec entries referencing names not found in the code
  - coverage_pct:  (in_spec / bound_total) * 100

Usage:
    python tools/audit/lua_spec_coverage.py              # all modules, text table
    python tools/audit/lua_spec_coverage.py --module ai  # single module
    python tools/audit/lua_spec_coverage.py --json       # JSON output
    python tools/audit/lua_spec_coverage.py --output logs/reports/lua_spec_coverage.md
    python tools/audit/lua_spec_coverage.py --threshold 80  # exit 1 if avg coverage < 80%

Exit codes:
    0  all modules meet threshold (default 0 — never fails unless --threshold is set)
    1  one or more modules below threshold
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional

REPO = Path(__file__).resolve().parent.parent.parent
LUA_API_DIR = REPO / "src" / "lua_api"
SPECS_DIR = REPO / "docs" / "specs"

# Pattern: fallback extraction for direct Lua table registration in *_api.rs.
_TBLSET_RE = re.compile(r'tbl\.set\(\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,')
# Parse only bullet labels in spec `## Lua API Reference` to avoid matching
# code spans used in descriptions.
_BULLET_LABEL_RE = re.compile(r"^\s*-\s*`([^`]+)`")

_LUA_API_DATA_FILE = REPO / "logs" / "data" / "lua_api_data.json"
_LUA_API_BINDINGS_CACHE: Dict[str, List[str]] = {}


def _load_lua_api_bindings() -> Dict[str, List[str]]:
    """Load module -> [Lua function/method names] from lua_api_data.json."""
    global _LUA_API_BINDINGS_CACHE
    if _LUA_API_BINDINGS_CACHE:
        return _LUA_API_BINDINGS_CACHE

    if not _LUA_API_DATA_FILE.exists():
        _LUA_API_BINDINGS_CACHE = {}
        return _LUA_API_BINDINGS_CACHE

    try:
        data = json.loads(_LUA_API_DATA_FILE.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        _LUA_API_BINDINGS_CACHE = {}
        return _LUA_API_BINDINGS_CACHE

    modules = data.get("lua_api", {}).get("modules", {})
    out: Dict[str, List[str]] = {}
    for module, payload in modules.items():
        names: List[str] = []
        for fn in payload.get("functions", []):
            name = fn.get("name")
            if isinstance(name, str) and name:
                names.append(name)
        for cls in payload.get("classes", {}).values():
            for method in cls.get("methods", []):
                name = method.get("name")
                if isinstance(name, str) and name:
                    names.append(name)
        out[module] = names

    _LUA_API_BINDINGS_CACHE = out
    return _LUA_API_BINDINGS_CACHE


def _find_modules() -> List[str]:
    """Discover all modules that have an _api.rs file."""
    names = []
    for f in sorted(LUA_API_DIR.glob("*_api.rs")):
        stem = f.stem  # e.g. "audio_api"
        names.append(stem[: -len("_api")])
    return names


def _bound_functions(api_rs: Path) -> List[str]:
    """Return all bound Lua API names for a module.

    Preferred source is logs/data/lua_api_data.json (generator output used by docs).
    Fallback is legacy tbl.set() extraction for direct module-level bindings.
    """
    module = api_rs.stem[: -len("_api")] if api_rs.stem.endswith("_api") else api_rs.stem
    bindings = _load_lua_api_bindings().get(module)
    if bindings is not None:
        return bindings

    text = api_rs.read_text(encoding="utf-8", errors="replace")
    return _TBLSET_RE.findall(text)


def _spec_api_names(spec_path: Path) -> set[str]:
    """Return function names appearing in the ## Lua API Reference section of a spec file."""
    if not spec_path.exists():
        return set()
    text = spec_path.read_text(encoding="utf-8", errors="replace")
    # Extract the Lua API Reference section only
    m = re.search(r"## Lua API Reference(.*?)(?=\n## |\Z)", text, re.DOTALL)
    if not m:
        return set()
    section = m.group(1)
    names: set[str] = set()
    for line in section.splitlines():
        m_label = _BULLET_LABEL_RE.match(line)
        if not m_label:
            continue
        label = m_label.group(1).strip()

        # Drop call signature if present, e.g. foo(bar) -> foo
        label = label.split("(", 1)[0].strip()

        if ":" in label:
            # Method style: Class:method or lurek.module.Class:method
            names.add(label.rsplit(":", 1)[1])
            continue

        if "." in label:
            # Function style: lurek.module.fn or other dotted identifiers.
            names.add(label.rsplit(".", 1)[1])
            continue

        # Fallback: plain function label.
        if label:
            names.add(label)

    return names


def audit_module(module: str) -> dict:
    """Return a coverage dict for one module."""
    api_rs = LUA_API_DIR / f"{module}_api.rs"
    spec_path = SPECS_DIR / f"{module}.md"

    result: dict = {
        "module": module,
        "api_file": str(api_rs.relative_to(REPO)) if api_rs.exists() else None,
        "spec_file": str(spec_path.relative_to(REPO)) if spec_path.exists() else None,
        "bound_total": 0,
        "in_spec": 0,
        "missing": [],
        "stale": [],
        "coverage_pct": 0.0,
        "status": "ok",
    }

    if not api_rs.exists():
        result["status"] = "no_api_file"
        return result

    if not spec_path.exists():
        result["status"] = "no_spec_file"
        return result

    bound = _bound_functions(api_rs)
    result["bound_total"] = len(bound)

    if not bound:
        result["status"] = "no_bindings"
        return result

    spec_names = _spec_api_names(spec_path)
    bound_set = set(bound)

    missing = [fn for fn in bound if fn not in spec_names]
    stale = [fn for fn in spec_names if fn not in bound_set]

    in_spec = len(bound) - len(missing)
    result["missing"] = sorted(missing)
    result["stale"] = sorted(stale)
    result["in_spec"] = in_spec
    result["coverage_pct"] = round(in_spec / len(bound) * 100, 1) if bound else 100.0

    if missing or stale:
        result["status"] = "gaps"
    else:
        result["status"] = "ok"

    return result


def _render_table(results: List[dict]) -> str:
    """Render a Markdown table from audit results."""
    from datetime import date

    lines = [
        "# Lua Spec Coverage",
        "",
        f"_Auto-generated {date.today().isoformat()} — `python tools/audit/lua_spec_coverage.py`_",
        "",
        "| Module | Bound | In Spec | Missing | Stale | Coverage |",
        "| ------ | ----: | ------: | ------: | ----: | -------: |",
    ]
    for r in results:
        if r["status"] in ("no_api_file", "no_bindings"):
            continue
        cov = f"{r['coverage_pct']}%" if r["status"] != "no_spec_file" else "—"
        miss = str(len(r["missing"])) if r["status"] != "no_spec_file" else "—"
        stale = str(len(r["stale"])) if r["status"] != "no_spec_file" else "—"
        in_s = str(r["in_spec"]) if r["status"] != "no_spec_file" else "—"
        lines.append(
            f"| `{r['module']}` | {r['bound_total']} | {in_s} | {miss} | {stale} | {cov} |"
        )

    lines += [""]

    # Gaps section
    gap_modules = [r for r in results if r.get("missing") or r.get("stale")]
    if gap_modules:
        lines.append("## Gaps")
        lines.append("")
        for r in gap_modules:
            lines.append(f"### `{r['module']}`")
            if r["missing"]:
                listed = ", ".join(f"`{fn}`" for fn in r["missing"][:20])
                more = f" (+{len(r['missing'])-20} more)" if len(r["missing"]) > 20 else ""
                lines.append(f"- **Missing from spec**: {listed}{more}")
            if r["stale"]:
                listed = ", ".join(f"`{fn}`" for fn in r["stale"][:10])
                lines.append(f"- **Stale in spec**: {listed}")
            lines.append("")

    # Summary stats
    with_bindings = [r for r in results if r["bound_total"] > 0]
    if with_bindings:
        covered = [r for r in with_bindings if r["status"] != "no_spec_file"]
        total_bound = sum(r["bound_total"] for r in with_bindings)
        total_in_spec = sum(r["in_spec"] for r in covered)
        avg_pct = round(total_in_spec / total_bound * 100, 1) if total_bound else 0.0
        lines += [
            "## Summary",
            "",
            f"- Modules with Lua bindings: **{len(with_bindings)}**",
            f"- Modules with spec files: **{len(covered)}**",
            f"- Total bound functions: **{total_bound}**",
            f"- Total covered in spec: **{total_in_spec}**",
            f"- Overall coverage: **{avg_pct}%**",
            "",
        ]

    return "\n".join(lines)


def _render_text(results: List[dict]) -> str:
    """Render a human-readable text table."""
    lines = ["Lua Spec Coverage", "=" * 70]
    for r in results:
        if r["status"] in ("no_api_file", "no_bindings"):
            continue
        if r["status"] == "no_spec_file":
            lines.append(f"  {r['module']:25s}  bound={r['bound_total']:3d}  NO SPEC FILE")
            continue
        miss = len(r["missing"])
        stale = len(r["stale"])
        flag = "  [GAPS]" if (miss or stale) else ""
        lines.append(
            f"  {r['module']:25s}  bound={r['bound_total']:3d}  "
            f"in_spec={r['in_spec']:3d}  missing={miss:3d}  stale={stale:2d}  "
            f"{r['coverage_pct']:5.1f}%{flag}"
        )
        if miss:
            shown = r["missing"][:6]
            extra = f" …+{miss-6}" if miss > 6 else ""
            lines.append(f"      missing: {', '.join(shown)}{extra}")
        if stale:
            lines.append(f"      stale:   {', '.join(r['stale'][:4])}")

    with_bindings = [r for r in results if r["bound_total"] > 0]
    covered = [r for r in with_bindings if r["status"] != "no_spec_file"]
    if with_bindings:
        total_bound = sum(r["bound_total"] for r in with_bindings)
        total_in_spec = sum(r["in_spec"] for r in covered)
        avg_pct = round(total_in_spec / total_bound * 100, 1) if total_bound else 0.0
        lines += [
            "=" * 70,
            f"Modules with bindings: {len(with_bindings)}  with spec: {len(covered)}",
            f"Total bound: {total_bound}  covered: {total_in_spec}  overall: {avg_pct}%",
        ]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--module", metavar="NAME", help="Audit only this module")
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument("--output", metavar="PATH", help="Write Markdown report to file")
    parser.add_argument("--threshold", type=float, default=0,
                        help="Exit 1 if overall coverage < THRESHOLD percent")
    args = parser.parse_args()

    if args.module:
        modules = [args.module]
    else:
        modules = _find_modules()

    results = [audit_module(m) for m in modules]

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print(_render_text(results))

    if args.output:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(_render_table(results), encoding="utf-8")
        print(f"\n→ {args.output}")

    if args.threshold > 0:
        with_bindings = [r for r in results if r["bound_total"] > 0]
        covered = [r for r in with_bindings if r["status"] != "no_spec_file"]
        total_bound = sum(r["bound_total"] for r in with_bindings)
        total_in_spec = sum(r["in_spec"] for r in covered)
        avg_pct = total_in_spec / total_bound * 100 if total_bound else 0.0
        if avg_pct < args.threshold:
            print(f"\nFAIL: coverage {avg_pct:.1f}% < threshold {args.threshold}%", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
