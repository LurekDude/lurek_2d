#!/usr/bin/env python3
"""
unit_test_api_coverage.py — Lurek2D unit-test API coverage analysis.

Each Lua unit-test `it()` block can declare which API(s) it exercises with an
explicit annotation:

    it("getDelta returns a number", function()
        -- @tests lurek.timer.getDelta
        local dt = lurek.timer.getDelta()
        expect_type("number", dt)
    end)

For class methods use the bare ClassName:method form:

    it("World:step advances physics", function()
        -- @tests World:step
        world:step(1/60)
    end)

Multiple @tests lines are allowed in one it() block if the block exercises
several APIs.

The script also runs a heuristic pass: inside it() blocks it looks for
references matching known lua_names and marks those as heuristic-covered
even without an explicit annotation.

Usage:
    python tools/audit/unit_test_api_coverage.py          # human summary
    python tools/audit/unit_test_api_coverage.py --json   # JSON to stdout
    python tools/audit/unit_test_api_coverage.py --save   # save JSON + md report
    python tools/audit/unit_test_api_coverage.py --module math
    python tools/audit/unit_test_api_coverage.py --strict         # explicit only
    python tools/audit/unit_test_api_coverage.py --gaps           # list uncovered
    python tools/audit/unit_test_api_coverage.py --suggest        # suggest stubs
    python tools/audit/unit_test_api_coverage.py --threshold 30   # fail if < 30%

Exit codes:
    0 — success (or coverage >= threshold)
    1 — coverage below threshold
    2 — fatal error
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, NamedTuple, Optional, Set, Tuple

# ── Paths ─────────────────────────────────────────────────────────────────────

ROOT = Path(__file__).resolve().parents[2]
API_JSON = ROOT / "logs" / "data" / "lua_api_data.json"
LUA_UNIT_TESTS = ROOT / "tests" / "lua" / "unit"
OUTPUT_JSON = ROOT / "logs" / "data" / "unit_test_coverage.json"
OUTPUT_MD = ROOT / "logs" / "reports" / "unit_test_coverage.md"

# ── Data types ─────────────────────────────────────────────────────────────────


class ApiEntry(NamedTuple):
    """A single API function or method."""

    module: str         # e.g. "timer"
    lua_name: str       # e.g. "lurek.timer.getDelta" or "World:step"
    name: str           # short name, e.g. "getDelta" or "step"
    is_method: bool
    owner_type: str     # e.g. "World" (methods only)
    source_file: str    # src/lua_api/xxx_api.rs
    source_line: int


class CoverageResult(NamedTuple):
    """Coverage status of a single API entry."""

    api: ApiEntry
    explicit: bool              # has a -- @tests annotation
    heuristic: bool             # referenced in test code (no annotation)
    test_locations: List[str]   # "file.lua:it_description" entries


# ── API loader ─────────────────────────────────────────────────────────────────


def load_api(module_filter: Optional[str] = None) -> List[ApiEntry]:
    """Load every API entry from the generated JSON."""
    try:
        data = json.loads(API_JSON.read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.exit(f"[ERROR] API JSON not found: {API_JSON}\n"
                 "Run: python tools/docs/gen_lua_api_data.py first.")
    except json.JSONDecodeError as exc:
        sys.exit(f"[ERROR] JSON parse error in {API_JSON}: {exc}")

    modules = data["lua_api"]["modules"]
    entries: List[ApiEntry] = []

    for mod_name, mod in modules.items():
        if module_filter and mod_name != module_filter:
            continue
        src = mod.get("source_file", "")

        for fn in (mod.get("functions") or []):
            entries.append(ApiEntry(
                module=mod_name,
                lua_name=fn["lua_name"],
                name=fn["name"],
                is_method=False,
                owner_type="",
                source_file=fn.get("file", src),
                source_line=fn.get("line", 0),
            ))

        for cls_name, cls in (mod.get("classes") or {}).items():
            for meth in (cls.get("methods") or []):
                entries.append(ApiEntry(
                    module=mod_name,
                    lua_name=meth["lua_name"],
                    name=meth["name"],
                    is_method=True,
                    owner_type=cls_name,
                    source_file=meth.get("file", src),
                    source_line=meth.get("line", 0),
                ))

    return entries


# ── Test file scanner ─────────────────────────────────────────────────────────

# Matches:  -- @tests lurek.module.funcname
#           -- @tests ClassName:methodname
_EXPLICIT_RE = re.compile(
    r"--\s*@tests\s+([a-zA-Z_][\w.:]*(?::[a-zA-Z_]\w*)?)",
    re.IGNORECASE,
)

# Matches it( or it ( at the start of a block
_IT_OPEN_RE = re.compile(r"\bit\s*\(")

# Matches lurek.module.name patterns inside code
_LUREK_REF_RE = re.compile(
    r"\blurek\.([a-z_]\w*)\.([a-zA-Z_]\w*)",
)

# Matches ClassName:method patterns (obj:method() calls)
_METHOD_CALL_RE = re.compile(
    r"\b([A-Z][a-zA-Z_]*)\s*:\s*([a-zA-Z_]\w*)\s*\(",
)


def _parse_it_blocks(content: str) -> List[Tuple[str, str]]:
    """
    Extract (description, body) pairs for every `it()` call in a Lua file.

    Returns a list of (desc, body_text) where body_text is the content between
    the opening `function()` and the closing `end)`.
    """
    results: List[Tuple[str, str]] = []
    i = 0
    length = len(content)

    for m in _IT_OPEN_RE.finditer(content):
        start = m.end()
        if start >= length:
            continue

        # Extract the description (first string argument)
        desc = ""
        desc_m = re.match(r'\s*["\']([^"\']*)["\']', content[start:start + 200])
        if desc_m:
            desc = desc_m.group(1)

        # Find `function()` opening
        func_m = re.search(r"\bfunction\s*\(\s*\)", content[start:start + 300])
        if not func_m:
            continue

        func_start = start + func_m.end()

        # Track function/end depth to find the matching `end)`
        depth = 1
        j = func_start
        while j < length and depth > 0:
            # Skip strings and comments to avoid false matches
            if content[j] == '"' or content[j] == "'":
                q = content[j]
                j += 1
                while j < length and content[j] != q:
                    if content[j] == '\\':
                        j += 1
                    j += 1
                j += 1
                continue
            if content[j:j+2] == '--':
                while j < length and content[j] != '\n':
                    j += 1
                continue
            # Check for `function` keyword (increases depth)
            kw = re.match(r'\bfunction\b', content[j:j+8])
            if kw:
                depth += 1
                j += kw.end()
                continue
            # Check for `end` keyword (decreases depth)
            end_m = re.match(r'\bend\b', content[j:j+3])
            if end_m:
                depth -= 1
                if depth == 0:
                    body = content[func_start:j]
                    results.append((desc, body))
                    break
                j += end_m.end()
                continue
            j += 1

    return results


def scan_file(
    lua_path: Path,
    known_lua_names: Set[str],
    known_methods: Dict[str, Set[str]],  # owner_type -> set of method names
) -> Tuple[Set[str], Set[str], Dict[str, List[str]]]:
    """
    Scan a single Lua test file.

    Returns:
        explicit_set   — lua_names found via -- @tests annotations
        heuristic_set  — lua_names found via code pattern matching
        locations      — lua_name -> list of "file:description" strings
    """
    try:
        content = lua_path.read_text(encoding="utf-8")
    except OSError:
        return set(), set(), {}

    filename = lua_path.name
    explicit_set: Set[str] = set()
    heuristic_set: Set[str] = set()
    locations: Dict[str, List[str]] = defaultdict(list)

    it_blocks = _parse_it_blocks(content)

    # ── Explicit annotations (scan full file) ──────────────────────────────
    for m in _EXPLICIT_RE.finditer(content):
        api_ref = m.group(1).strip()
        # Normalise: strip trailing punctuation
        api_ref = api_ref.rstrip(".,;")
        if api_ref in known_lua_names:
            explicit_set.add(api_ref)
            # Try to find the enclosing it() description
            pos = m.start()
            # Find closest preceding it( to associate a description
            desc = _find_enclosing_it_desc(content, pos)
            loc = f"{filename}:{desc}" if desc else filename
            locations[api_ref].append(loc)

    # ── Heuristic: scan it() block bodies ─────────────────────────────────
    for (desc, body) in it_blocks:
        loc = f"{filename}:{desc}"

        # lurek.module.func references
        for ref_m in _LUREK_REF_RE.finditer(body):
            lua_name = f"lurek.{ref_m.group(1)}.{ref_m.group(2)}"
            if lua_name in known_lua_names and lua_name not in explicit_set:
                heuristic_set.add(lua_name)
                if loc not in locations[lua_name]:
                    locations[lua_name].append(f"{loc} [heuristic]")

        # ClassName:method calls
        for ref_m in _METHOD_CALL_RE.finditer(body):
            owner = ref_m.group(1)
            meth_name = ref_m.group(2)
            lua_name = f"{owner}:{meth_name}"
            if lua_name in known_lua_names and lua_name not in explicit_set:
                heuristic_set.add(lua_name)
                if loc not in locations[lua_name]:
                    locations[lua_name].append(f"{loc} [heuristic]")

        # Also catch class method references on known UserData fields
        # e.g. world:step(dt) — but "world" is lowercase
        # We do a broader pass: look for :methodname( patterns and check
        # if methodname exists in any class
        for meth_m in re.finditer(r'\w+\s*:\s*([a-zA-Z_]\w*)\s*\(', body):
            meth_name = meth_m.group(1)
            for owner_type, method_names in known_methods.items():
                if meth_name in method_names:
                    lua_name = f"{owner_type}:{meth_name}"
                    if lua_name in known_lua_names and lua_name not in explicit_set:
                        heuristic_set.add(lua_name)
                        if loc not in locations[lua_name]:
                            locations[lua_name].append(f"{loc} [heuristic]")

    return explicit_set, heuristic_set, dict(locations)


def _find_enclosing_it_desc(content: str, pos: int) -> str:
    """Find the description string of the it() call that encloses pos."""
    # Look backward for the nearest it( before pos
    before = content[:pos]
    it_matches = list(_IT_OPEN_RE.finditer(before))
    if not it_matches:
        return ""
    last_it = it_matches[-1]
    after_it = content[last_it.end():last_it.end() + 200]
    desc_m = re.match(r'\s*["\']([^"\']*)["\']', after_it)
    return desc_m.group(1) if desc_m else ""


def scan_all_tests(
    test_dir: Path,
    api_entries: List[ApiEntry],
) -> List[CoverageResult]:
    """Scan all Lua test files and return coverage results for every API."""
    # Build lookup structures
    known_lua_names: Set[str] = {e.lua_name for e in api_entries}
    # owner_type -> set of method names (for heuristic obj:method detection)
    known_methods: Dict[str, Set[str]] = defaultdict(set)
    for e in api_entries:
        if e.is_method:
            known_methods[e.owner_type].add(e.name)

    # Aggregate across all test files
    all_explicit: Set[str] = set()
    all_heuristic: Set[str] = set()
    all_locations: Dict[str, List[str]] = defaultdict(list)

    lua_files = sorted(test_dir.rglob("*.lua"))
    for lua_path in lua_files:
        explicit, heuristic, locs = scan_file(lua_path, known_lua_names, known_methods)
        all_explicit.update(explicit)
        all_heuristic.update(heuristic)
        for key, vals in locs.items():
            all_locations[key].extend(vals)

    results: List[CoverageResult] = []
    for entry in api_entries:
        is_explicit = entry.lua_name in all_explicit
        is_heuristic = (not is_explicit) and (entry.lua_name in all_heuristic)
        locs = all_locations.get(entry.lua_name, [])
        results.append(CoverageResult(
            api=entry,
            explicit=is_explicit,
            heuristic=is_heuristic,
            test_locations=locs,
        ))

    return results


# ── Analytics ─────────────────────────────────────────────────────────────────


def build_analytics(results: List[CoverageResult], strict: bool = False) -> dict:
    """Compute summary + per-module breakdown from coverage results."""
    total = len(results)
    explicit_count = sum(1 for r in results if r.explicit)
    heuristic_count = sum(1 for r in results if r.heuristic)
    covered_any = explicit_count + heuristic_count
    uncovered_explicit_count = total - explicit_count
    uncovered_any_count = total - covered_any

    def pct(n: int, d: int) -> float:
        return round(n / d * 100, 2) if d else 100.0

    # Per-module breakdown
    by_module: Dict[str, list] = defaultdict(list)
    for r in results:
        by_module[r.api.module].append(r)

    modules_out = {}
    for mod, mod_results in sorted(by_module.items()):
        mtotal = len(mod_results)
        mexplicit = sum(1 for r in mod_results if r.explicit)
        mheuristic = sum(1 for r in mod_results if r.heuristic)
        many = mexplicit + mheuristic
        modules_out[mod] = {
            "total": mtotal,
            "covered_explicit": mexplicit,
            "covered_heuristic": mheuristic,
            "covered_any": many,
            "uncovered": mtotal - mexplicit,
            "uncovered_any": mtotal - many,
            "pct_explicit": pct(mexplicit, mtotal),
            "pct_any": pct(many, mtotal),
            "uncovered_apis": [
                {
                    "lua_name": r.api.lua_name,
                    "name": r.api.name,
                    "is_method": r.api.is_method,
                    "owner_type": r.api.owner_type,
                    "source_file": r.api.source_file,
                    "source_line": r.api.source_line,
                    "coverage_hint": "heuristic" if r.heuristic else "none",
                    "locations": r.test_locations[:5],
                }
                for r in mod_results
                if not r.explicit
            ],
            "uncovered_any_apis": [
                {
                    "lua_name": r.api.lua_name,
                    "name": r.api.name,
                    "is_method": r.api.is_method,
                    "owner_type": r.api.owner_type,
                    "source_file": r.api.source_file,
                    "source_line": r.api.source_line,
                }
                for r in mod_results
                if not r.explicit and not r.heuristic
            ],
            "explicit_apis": [
                {
                    "lua_name": r.api.lua_name,
                    "coverage": "explicit",
                    "locations": r.test_locations[:5],
                }
                for r in mod_results
                if r.explicit
            ],
            "heuristic_apis": [
                {
                    "lua_name": r.api.lua_name,
                    "coverage": "heuristic",
                    "locations": r.test_locations[:5],
                }
                for r in mod_results
                if r.heuristic
            ],
            "covered_apis": [
                {
                    "lua_name": r.api.lua_name,
                    "coverage": "explicit" if r.explicit else "heuristic",
                    "locations": r.test_locations[:5],  # cap at 5 for readability
                }
                for r in mod_results
                if r.explicit or r.heuristic
            ],
        }

    return {
        "generated": datetime.now(timezone.utc).isoformat(),
        "generator": "tools/audit/unit_test_api_coverage.py",
        "strict_mode": strict,
        "summary": {
            "total_apis": total,
            "covered_explicit": explicit_count,
            "covered_heuristic": heuristic_count,
            "covered_any": covered_any,
            "uncovered": uncovered_explicit_count,
            "uncovered_any": uncovered_any_count,
            "pct_explicit": pct(explicit_count, total),
            "pct_any": pct(covered_any, total),
            "total_modules": len(modules_out),
        },
        "modules": modules_out,
    }


# ── Report formatters ──────────────────────────────────────────────────────────


def format_summary(data: dict, strict: bool) -> str:
    s = data["summary"]
    lines = [
        "╔══════════════════════════════════════════════════════════════╗",
        "║         Lurek2D Unit-Test API Coverage Report                 ║",
        "╚══════════════════════════════════════════════════════════════╝",
        f"",
        f"  Generated:   {data['generated'][:19]}",
        f"  Requirement: explicit @tests annotations define real unit coverage",
        f"  Heuristic hits are shown only as migration hints",
        f"",
        f"  Total APIs:           {s['total_apis']:>6}",
        f"  Covered (explicit):   {s['covered_explicit']:>6}  ({s['pct_explicit']:.1f}%)",
        f"  Heuristic-only hits:  {s['covered_heuristic']:>6}  ({s['pct_any'] - s['pct_explicit']:.1f}%)",
        f"  Missing @tests:       {s['uncovered']:>6}  ({100 - s['pct_explicit']:.1f}%)",
        f"  Zero evidence:        {s['uncovered_any']:>6}  ({100 - s['pct_any']:.1f}%)",
        f"",
        "  Module breakdown (worst → best explicit coverage):",
        "",
    ]
    mods = sorted(
        data["modules"].items(),
        key=lambda kv: kv[1]["pct_explicit"],
    )
    for mod, m in mods:
        bar_len = int(m["pct_explicit"] / 5)   # 20 chars = 100%
        bar = "█" * bar_len + "░" * (20 - bar_len)
        heuristic_badge = f" +{m['covered_heuristic']}h" if m["covered_heuristic"] else ""
        lines.append(
            f"  {mod:<16} [{bar}] {m['pct_explicit']:>5.1f}%"
            f"  {m['covered_explicit']}/{m['total']}{heuristic_badge}"
        )
    return "\n".join(lines)


def format_markdown(data: dict, strict: bool) -> str:
    s = data["summary"]
    now = data["generated"][:19]

    md = [
        "# Lurek2D Unit-Test API Coverage",
        "",
        f"*Generated: {now} · Coverage requirement: explicit `@tests` annotations*",
        "",
        "## Summary",
        "",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Total APIs | {s['total_apis']} |",
        f"| **Covered (explicit `@tests`)** | **{s['covered_explicit']} ({s['pct_explicit']:.1f}%)** |",
        f"| Heuristic-only hits | {s['covered_heuristic']} ({s['pct_any'] - s['pct_explicit']:.1f}%) |",
        f"| Missing explicit `@tests` | {s['uncovered']} ({100 - s['pct_explicit']:.1f}%) |",
        f"| Zero-evidence APIs | {s['uncovered_any']} ({100 - s['pct_any']:.1f}%) |",
        f"| Modules | {s['total_modules']} |",
        "",
        "## Module Coverage",
        "",
        "| Module | Total | Explicit | Heuristic-only | Explicit% | Missing `@tests` | Zero-evidence |",
        "|--------|-------|----------|----------------|-----------|------------------|---------------|",
    ]

    for mod, m in sorted(data["modules"].items()):
        md.append(
            f"| `{mod}` | {m['total']} | {m['covered_explicit']} | {m['covered_heuristic']}"
            f" | {m['pct_explicit']:.1f}% | {m['uncovered']} | {m['uncovered_any']} |"
        )

    md += [
        "",
        "## Missing Explicit `@tests` Coverage",
        "",
        "> These APIs still need an explicit `-- @tests ...` annotation in at least one unit-test `it()` block.",
        "",
    ]

    for mod, m in sorted(data["modules"].items(), key=lambda kv: -kv[1]["uncovered"]):
        if not m["uncovered_apis"]:
            continue
        md.append(f"### `lurek.{mod}` — {m['uncovered']} still need `@tests`")
        md.append("")
        for api in m["uncovered_apis"][:50]:  # cap per module
            if api["is_method"]:
                label = f"`{api['lua_name']}`  *(method on {api['owner_type']})*"
            else:
                label = f"`{api['lua_name']}`"
            if api["coverage_hint"] == "heuristic":
                md.append(f"- {label} — referenced in tests, but still missing an explicit `@tests` annotation")
            else:
                md.append(f"- {label}")
        if len(m["uncovered_apis"]) > 50:
            md.append(f"  *(… {len(m['uncovered_apis']) - 50} more)*")
        md.append("")

    md += [
        "## Zero-Evidence APIs",
        "",
        "> These APIs are neither explicitly annotated nor referenced heuristically in unit tests.",
        "",
    ]

    for mod, m in sorted(data["modules"].items(), key=lambda kv: -kv[1]["uncovered_any"]):
        if not m["uncovered_any_apis"]:
            continue
        md.append(f"### `lurek.{mod}` — {m['uncovered_any']} zero-evidence")
        md.append("")
        for api in m["uncovered_any_apis"][:30]:
            if api["is_method"]:
                label = f"`{api['lua_name']}`  *(method on {api['owner_type']})*"
            else:
                label = f"`{api['lua_name']}`"
            md.append(f"- {label}")
        if len(m["uncovered_any_apis"]) > 30:
            md.append(f"  *(… {len(m['uncovered_any_apis']) - 30} more)*")
        md.append("")

    md += [
        "## Annotation Convention",
        "",
        "Add `-- @tests <lua_name>` inside any `it()` block to explicitly declare",
        "which API that test exercises:",
        "",
        "```lua",
        'it("getDelta returns a number", function()',
        "    -- @tests lurek.timer.getDelta",
        "    local dt = lurek.timer.getDelta()",
        "    expect_type(\"number\", dt)",
        "end)",
        "",
        'it("World:step advances simulation", function()',
        "    -- @tests World:step",
        "    world:step(1/60)",
        "end)",
        "```",
        "",
        "Multiple `@tests` annotations per `it()` block are allowed.  ",
        "Run `python tools/audit/unit_test_api_coverage.py --save` to regenerate this report.",
    ]

    return "\n".join(md)


def format_gaps(data: dict) -> str:
    """Print only the uncovered APIs, grouped by module."""
    lines = [
        "Lurek2D — APIs Missing Explicit @tests Coverage",
        "=" * 50,
        "",
    ]
    for mod, m in sorted(data["modules"].items()):
        if not m["uncovered_apis"]:
            continue
        lines.append(f"[{mod}]  {m['uncovered']} missing @tests / {m['total']} total")
        for api in m["uncovered_apis"]:
            suffix = " [heuristic]" if api["coverage_hint"] == "heuristic" else ""
            lines.append(f"  {api['lua_name']}{suffix}")
        lines.append("")
    return "\n".join(lines)


def format_suggest(data: dict) -> str:
    """Print suggested it() stub templates for uncovered APIs."""
    lines = [
        "-- Lurek2D — suggested unit test stubs for APIs missing explicit @tests coverage",
        "-- Add these to the appropriate tests/lua/unit/test_<module>.lua file",
        "",
    ]
    for mod, m in sorted(data["modules"].items()):
        if not m["uncovered_apis"]:
            continue
        lines.append(f"-- ── {mod} ({'module functions' if True else ''}) ──")
        for api in m["uncovered_apis"][:20]:
            lua_name = api["lua_name"]
            name = api["name"]
            lines += [
                f'it("{lua_name} works", function()',
                f"    -- @tests {lua_name}",
                f"    -- TODO: add assertion for {name}",
                f"end)",
                "",
            ]
        if len(m["uncovered_apis"]) > 20:
            remaining = len(m["uncovered_apis"]) - 20
            lines.append(f"-- ... {remaining} more uncovered in {mod}")
            lines.append("")
    return "\n".join(lines)


# ── Entry point ───────────────────────────────────────────────────────────────


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Lurek2D unit-test API coverage analyser.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split("Exit codes:")[1],
    )
    parser.add_argument("--json", action="store_true", help="Print JSON to stdout")
    parser.add_argument("--save", action="store_true",
                        help=f"Save JSON to {OUTPUT_JSON} and Markdown to {OUTPUT_MD}")
    parser.add_argument("--module", metavar="NAME", help="Filter to a single module")
    parser.add_argument("--strict", action="store_true",
                        help="Retained for compatibility; explicit @tests are always the primary metric")
    parser.add_argument("--gaps", action="store_true", help="Only list uncovered APIs")
    parser.add_argument("--suggest", action="store_true",
                        help="Print it() stub templates for uncovered APIs")
    parser.add_argument("--threshold", type=float, default=0,
                        metavar="PCT",
                        help="Exit 1 if explicit @tests coverage is below this percentage")

    args = parser.parse_args()

    # 1. Load API list
    api_entries = load_api(module_filter=args.module)
    if not api_entries:
        sys.exit("[ERROR] No API entries loaded. Check --module name or re-run gen_lua_api_data.py.")

    # 2. Scan test files
    results = scan_all_tests(LUA_UNIT_TESTS, api_entries)

    # 3. Build analytics
    data = build_analytics(results, strict=args.strict)

    # 4. Output
    if args.json:
        print(json.dumps(data, indent=2))
        return 0

    if args.gaps:
        print(format_gaps(data))
    elif args.suggest:
        print(format_suggest(data))
    else:
        print(format_summary(data, strict=args.strict))

    if args.save:
        OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT_MD.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT_JSON.write_text(json.dumps(data, indent=2), encoding="utf-8")
        md = format_markdown(data, strict=args.strict)
        OUTPUT_MD.write_text(md, encoding="utf-8")
        print(f"\n  Saved JSON  → {OUTPUT_JSON.relative_to(ROOT)}")
        print(f"  Saved report → {OUTPUT_MD.relative_to(ROOT)}")

    # 5. Threshold check
    pct_explicit = data["summary"]["pct_explicit"]
    if args.threshold > 0 and pct_explicit < args.threshold:
        print(f"\n[FAIL] Explicit coverage {pct_explicit:.1f}% is below threshold {args.threshold:.1f}%")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
