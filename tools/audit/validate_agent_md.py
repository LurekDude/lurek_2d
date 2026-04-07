#!/usr/bin/env python3
"""
validate_agent_md.py — Luna2D AGENT.md validation and scaffolding tool.

Validates that every src/<module>/AGENT.md has all required sections,
meets content quality standards, and stays in sync with the source files
and Lua API wrapper.

Usage:
    python tools/validate_agent_md.py                      # Validate all modules
    python tools/validate_agent_md.py --module physics     # Validate one module
    python tools/validate_agent_md.py --module audio graphics  # Validate several
    python tools/validate_agent_md.py --all                # Validate every src/ module
    python tools/validate_agent_md.py --scaffold physics   # Print scaffolded AGENT.md
    python tools/validate_agent_md.py --scaffold physics --write  # Scaffold into file
    python tools/validate_agent_md.py --strict             # Treat WARN as ERROR
    python tools/validate_agent_md.py --json               # Machine-readable JSON output

Exit codes:
    0 — all validations passed (or only warnings in non-strict mode)
    1 — one or more ERROR-level findings
    2 — usage / setup error

Check codes:
    M-01  Metadata table (required fields: Tier, Status, Lua API, Source, Rust Tests, Lua Tests)
    M-02  Summary quality (≥500 chars, ~1000 preferred)
    M-03  Architecture section present
    M-04  Source Files table in sync with .rs files on disk
    M-05  Submodules section present
    M-06  Key Types section (Structs + Enums)
    M-07  Lua API section covers the Lua wrapper
    M-08  Lua Examples code block (required when Lua API exists)
    M-09  Item Summary table present
    M-10  References section (similar modules, separation of duties)
    M-11  Notes section (constraints, best practices, unique facts)
    M-12  No TODO placeholders left unfilled
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Tuple

WORKSPACE = Path(__file__).resolve().parent.parent.parent
SRC = WORKSPACE / "src"
LUA_API = SRC / "lua_api"

# ── Tier table (keep in sync with docs/architecture/architecture.md) ─────────

BASELINE = {"math", "engine"}
TIER1 = {
    "animation", "audio", "automation", "camera", "compute", "data",
    "entity", "event", "filesystem", "graphics", "image", "input",
    "physics", "thread", "timer", "window",
}
TIER2 = {
    "ai", "dataframe", "graph", "gui", "minimap", "modding",
    "overlay", "particle", "pathfinding", "postfx", "savegame",
    "scene", "tilemap",
}
EXTRA = {
    "terminal", "spine", "serial", "raycaster", "procgen",
    "pipeline", "network", "light", "fx",
}
ALL_KNOWN = BASELINE | TIER1 | TIER2 | EXTRA

# ── Severity ──────────────────────────────────────────────────────────────────

PASS = "PASS"
WARN = "WARN"
ERROR = "ERROR"


@dataclass
class Finding:
    code: str
    name: str
    severity: str          # PASS | WARN | ERROR
    detail: str

    def to_dict(self) -> dict:
        return {"code": self.code, "name": self.name,
                "severity": self.severity, "detail": self.detail}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def _section_body(content: str, heading: str) -> str:
    """Return the text under '## heading' until the next '## ' or end of file."""
    pattern = rf"## {re.escape(heading)}\s*\n(.*?)(?=\n## |\Z)"
    m = re.search(pattern, content, re.DOTALL)
    return m.group(1).strip() if m else ""


def _has_section(content: str, heading: str) -> bool:
    return bool(re.search(rf"^## {re.escape(heading)}", content, re.MULTILINE))


def _tier_label(module: str) -> str:
    if module in BASELINE:
        return "Baseline"
    if module in TIER1:
        return "Tier 1 — Core Engine Subsystems"
    if module in TIER2:
        return "Tier 2 — Reusable Engine Extensions"
    return "Unassigned"


# ── Source analysis helpers ───────────────────────────────────────────────────

def _rs_files(module_dir: Path) -> List[Path]:
    """Non-mod.rs Rust source files in the module directory."""
    return sorted(
        f for f in module_dir.glob("*.rs") if f.name != "mod.rs"
    )


def _file_doc(path: Path) -> str:
    """Extract the first //! paragraph from a .rs file."""
    lines: List[str] = []
    for line in _read(path).splitlines():
        stripped = line.strip()
        if stripped.startswith("//!"):
            text = stripped[3:].strip()
            if text:
                lines.append(text)
        elif lines:
            break
    return " ".join(lines)


def _pub_structs(content: str) -> List[str]:
    return re.findall(r"^pub struct (\w+)", content, re.MULTILINE)


def _pub_enums(content: str) -> List[str]:
    return re.findall(r"^pub enum (\w+)", content, re.MULTILINE)


def _pub_fns(content: str) -> List[str]:
    return re.findall(r"^pub fn (\w+)", content, re.MULTILINE)


def _lua_api_path(module: str) -> Optional[Path]:
    """Return the Lua API file or directory for the module, or None."""
    file_path = LUA_API / f"{module}_api.rs"
    dir_path  = LUA_API / f"{module}_api"
    if file_path.exists():
        return file_path
    if dir_path.is_dir():
        return dir_path
    return None


def _lua_exposed_fns(module: str) -> List[str]:
    """
    Scan the Lua API source for tbl.set("name", ...) or luna.set("name", ...)
    patterns to list exposed function names.
    """
    api = _lua_api_path(module)
    if api is None:
        return []
    sources: List[str] = []
    if api.is_dir():
        sources = [_read(f) for f in api.rglob("*.rs")]
    else:
        sources = [_read(api)]
    names: List[str] = []
    for src in sources:
        names.extend(re.findall(r'(?:tbl|luna|table)\.set\("([^"]+)"', src))
    return sorted(set(names))


# ── Validation ────────────────────────────────────────────────────────────────

def validate(module: str) -> List[Finding]:
    results: List[Finding] = []
    module_dir = SRC / module
    agent_path = module_dir / "AGENT.md"

    # ── M-00: File exists ──────────────────────────────────────────────────
    if not agent_path.exists():
        results.append(Finding("M-00", "AGENT.md exists", ERROR,
                               f"AGENT.md not found at {agent_path.relative_to(WORKSPACE)}"))
        return results  # can't continue

    content = _read(agent_path)

    # ── M-01: Metadata table ───────────────────────────────────────────────
    required_props = ["Tier", "Status", "Lua API", "Source", "Rust Tests", "Lua Tests"]
    missing_props = [p for p in required_props
                     if not re.search(rf"\*\*{re.escape(p)}\*\*", content)]
    if missing_props:
        results.append(Finding("M-01", "Metadata table", ERROR,
                                f"Missing properties: {', '.join(missing_props)}"))
    else:
        results.append(Finding("M-01", "Metadata table", PASS,
                                "All required metadata properties present"))

    # ── M-02: Summary quality ─────────────────────────────────────────────
    summary_body = _section_body(content, "Summary")
    if not summary_body:
        results.append(Finding("M-02", "Summary quality", ERROR, "## Summary section missing or empty"))
    else:
        char_count = len(summary_body)
        if char_count < 300:
            results.append(Finding("M-02", "Summary quality", ERROR,
                                    f"Summary too short ({char_count} chars; minimum 500 required)"))
        elif char_count < 500:
            results.append(Finding("M-02", "Summary quality", WARN,
                                    f"Summary marginal ({char_count} chars; target is 500–1000)"))
        elif char_count > 1500:
            results.append(Finding("M-02", "Summary quality", WARN,
                                    f"Summary long ({char_count} chars; target is 500–1000, move detail to sections)"))
        else:
            results.append(Finding("M-02", "Summary quality", PASS,
                                    f"Summary is {char_count} chars"))

    # ── M-03: Architecture section ────────────────────────────────────────
    if not _has_section(content, "Architecture"):
        results.append(Finding("M-03", "Architecture section", ERROR,
                                "## Architecture section missing (required ASCII diagram)"))
    else:
        arch = _section_body(content, "Architecture")
        if "```" not in arch:
            results.append(Finding("M-03", "Architecture section", WARN,
                                    "## Architecture present but has no code/diagram block"))
        else:
            results.append(Finding("M-03", "Architecture section", PASS, "Architecture section present"))

    # ── M-04: Source Files in sync ────────────────────────────────────────
    if not _has_section(content, "Source Files"):
        results.append(Finding("M-04", "Source Files sync", ERROR,
                                "## Source Files table missing"))
    else:
        rs_on_disk = {f.name for f in _rs_files(module_dir)}
        rs_listed  = set(re.findall(r"\| `([^`]+\.rs)`", content))
        unlisted   = rs_on_disk - rs_listed
        extra      = rs_listed - rs_on_disk
        if unlisted:
            results.append(Finding("M-04", "Source Files sync", ERROR,
                                    f"Files on disk not in table: {', '.join(sorted(unlisted))}"))
        elif extra:
            results.append(Finding("M-04", "Source Files sync", WARN,
                                    f"Table lists files not on disk: {', '.join(sorted(extra))}"))
        else:
            results.append(Finding("M-04", "Source Files sync", PASS,
                                    f"Source Files table in sync ({len(rs_on_disk)} files)"))

    # ── M-05: Submodules section ──────────────────────────────────────────
    if not _has_section(content, "Submodules"):
        results.append(Finding("M-05", "Submodules section", ERROR,
                                "## Submodules section missing"))
    else:
        results.append(Finding("M-05", "Submodules section", PASS, "Submodules section present"))

    # ── M-06: Key Types ───────────────────────────────────────────────────
    if not _has_section(content, "Key Types"):
        results.append(Finding("M-06", "Key Types section", ERROR,
                                "## Key Types section missing (list all pub structs and enums)"))
    else:
        has_structs = bool(re.search(r"### Structs", content))
        has_enums   = bool(re.search(r"### Enums", content))
        if not has_structs:
            results.append(Finding("M-06", "Key Types section", WARN,
                                    "## Key Types has no '### Structs' subsection"))
        elif not has_enums:
            results.append(Finding("M-06", "Key Types section", WARN,
                                    "## Key Types has no '### Enums' subsection"))
        else:
            results.append(Finding("M-06", "Key Types section", PASS,
                                    "Key Types section has Structs and Enums subsections"))

    # ── M-07: Lua API section ─────────────────────────────────────────────
    api_path = _lua_api_path(module)
    if not _has_section(content, "Lua API"):
        sev = ERROR if api_path else WARN
        results.append(Finding("M-07", "Lua API section", sev,
                                "## Lua API section missing"
                                + (" (Lua wrapper exists!)" if api_path else " (no wrapper — add if intentional)")))
    else:
        api_body = _section_body(content, "Lua API")
        if api_path:
            exposed = _lua_exposed_fns(module)
            # Check at least some function names are mentioned
            mentioned = sum(1 for fn in exposed if fn in api_body)
            if exposed and mentioned == 0:
                results.append(Finding("M-07", "Lua API section", WARN,
                                        f"Lua wrapper exposes {len(exposed)} functions but none are named in ## Lua API"))
            else:
                results.append(Finding("M-07", "Lua API section", PASS,
                                        f"Lua API section present; wrapper exposes {len(exposed)} functions"))
        else:
            results.append(Finding("M-07", "Lua API section", PASS,
                                    "Lua API section present (no Rust wrapper — pure-Lua or internal module)"))

    # ── M-08: Lua Examples ────────────────────────────────────────────────
    has_lua_code = "```lua" in content
    if not has_lua_code:
        sev = ERROR if api_path else WARN
        results.append(Finding("M-08", "Lua Examples", sev,
                                "No ```lua code block found"
                                + (" (required — Lua wrapper exists)" if api_path else "")))
    else:
        results.append(Finding("M-08", "Lua Examples", PASS, "Lua code example present"))

    # ── M-09: Item Summary ────────────────────────────────────────────────
    if not _has_section(content, "Item Summary"):
        results.append(Finding("M-09", "Item Summary", ERROR,
                                "## Item Summary table missing"))
    else:
        results.append(Finding("M-09", "Item Summary", PASS, "Item Summary table present"))

    # ── M-10: References ──────────────────────────────────────────────────
    if not _has_section(content, "References"):
        results.append(Finding("M-10", "References section", ERROR,
                                "## References section missing (similar modules + separation of duties)"))
    else:
        ref_body = _section_body(content, "References")
        if "|" not in ref_body:
            results.append(Finding("M-10", "References section", WARN,
                                    "## References section has no Markdown table"))
        else:
            results.append(Finding("M-10", "References section", PASS, "References section present"))

    # ── M-11: Notes / Constraints ─────────────────────────────────────────
    has_notes = _has_section(content, "Notes") or _has_section(content, "Constraints")
    if not has_notes:
        results.append(Finding("M-11", "Notes section", ERROR,
                                "Neither ## Notes nor ## Constraints section found "
                                "(document hardware quirks, external crate constraints, best practices)"))
    else:
        results.append(Finding("M-11", "Notes section", PASS, "Notes / Constraints section present"))

    # ── M-12: No leftover TODO placeholders ───────────────────────────────
    todo_count = len(re.findall(r"\bTODO\b", content, re.IGNORECASE))
    if todo_count > 0:
        results.append(Finding("M-12", "No TODO placeholders", WARN,
                                f"{todo_count} TODO placeholder(s) left unfilled — replace before merging"))
    else:
        results.append(Finding("M-12", "No TODO placeholders", PASS, "No TODO placeholders found"))

    return results


# ── Scaffolding ───────────────────────────────────────────────────────────────

def scaffold(module: str) -> str:
    """Generate a full AGENT.md scaffold for the given module."""
    module_dir = SRC / module
    tier       = _tier_label(module)
    api_path   = _lua_api_path(module)
    lua_ns     = f"luna.{module}" if api_path else "—"

    # Collect source files
    rs_files = _rs_files(module_dir)

    # Collect types from all .rs files
    all_structs: List[Tuple[str, str]] = []  # (file_stem, name)
    all_enums:   List[Tuple[str, str]] = []
    all_fns:     List[str] = []
    for rs in rs_files:
        src = _read(rs)
        stem = rs.stem
        for s in _pub_structs(src):
            all_structs.append((stem, s))
        for e in _pub_enums(src):
            all_enums.append((stem, e))
        all_fns.extend(_pub_fns(src))

    # Exposed Lua functions
    lua_fns = _lua_exposed_fns(module)
    api_path_label = (str(api_path.relative_to(WORKSPACE)) if api_path else "—")

    lines: List[str] = []

    # ── Title + metadata ─────────────────────────────────────────────────
    lines += [
        f"# `{module}` — Agent Reference",
        "",
        "| Property | Value |",
        "|----------|-------|",
        f"| **Tier** | {tier} |",
        "| **Status** | Implemented — Full |",
        f"| **Lua API** | `{lua_ns}` |",
        f"| **Source** | `src/{module}/` |",
        f"| **Rust Tests** | `tests/unit/{module}_tests.rs` |",
        f"| **Lua Tests** | `tests/lua/unit/test_{module}.lua` |",
        "| **Architecture** | — |",
        "",
    ]

    # ── Summary ──────────────────────────────────────────────────────────
    lines += [
        "## Summary",
        "",
        "TODO: Write a 500–1000 character description covering:",
        f"- What the `{module}` module does (purpose)",
        "- How it works (architecture overview)",
        "- Key design decisions and why they were made",
        "- What is intentionally NOT included (scope boundary)",
        "",
    ]

    # ── Architecture ─────────────────────────────────────────────────────
    lines += [
        "## Architecture",
        "",
        "```",
        f"{module} (module root)",
    ]
    for rs in rs_files:
        doc = _file_doc(rs)
        lines.append(f"  ├── {rs.stem}.rs — {doc or 'TODO: describe'}")
    lines += [
        "```",
        "",
    ]

    # ── Source Files ─────────────────────────────────────────────────────
    lines += [
        "## Source Files",
        "",
        "| File | Purpose |",
        "|------|---------|",
    ]
    for rs in rs_files:
        doc = _file_doc(rs)
        lines.append(f"| `{rs.name}` | {doc or 'TODO: describe'} |")
    lines += ["", ]

    # ── Submodules ────────────────────────────────────────────────────────
    lines += ["## Submodules", ""]
    if rs_files:
        for rs in rs_files:
            stem   = rs.stem
            src    = _read(rs)
            doc    = _file_doc(rs) or "TODO: describe submodule purpose"
            structs = _pub_structs(src)
            enums   = _pub_enums(src)
            lines += [
                f"### `{module}::{stem}`",
                "",
                doc,
                "",
            ]
            for s in structs:
                lines.append(f"- **`{s}`** (struct): TODO: one-line description.")
            for e in enums:
                lines.append(f"- **`{e}`** (enum): TODO: one-line description.")
            if structs or enums:
                lines.append("")
    else:
        lines += ["TODO: Add submodule descriptions.", ""]

    # ── Key Types ─────────────────────────────────────────────────────────
    lines += ["## Key Types", "", "### Structs", ""]
    if all_structs:
        for stem, name in all_structs:
            lines += [
                f"#### `{module}::{stem}::{name}`",
                "",
                "TODO: description from `///` doc comment.",
                "",
            ]
    else:
        lines += ["No public structs.", ""]

    lines += ["### Enums", ""]
    if all_enums:
        for stem, name in all_enums:
            lines += [
                f"#### `{module}::{stem}::{name}`",
                "",
                "TODO: description from `///` doc comment.",
                "",
            ]
    else:
        lines += ["No public enums.", ""]

    # ── Lua API ──────────────────────────────────────────────────────────
    if api_path:
        fn_list = ""
        if lua_fns:
            fn_list = ", ".join(f"`{f}`" for f in lua_fns)
        lines += [
            "## Lua API",
            "",
            f"Exposed under `{lua_ns}.*` by `{api_path_label}`.",
            "",
            "TODO: Describe the overall API surface. List the major categories of functions.",
        ]
        if lua_fns:
            lines += [
                "",
                "Exposed functions include: " + fn_list + ".",
            ]
        lines += [""]
    else:
        lines += [
            "## Lua API",
            "",
            "No Lua API — internal Rust module only.",
            "",
        ]

    # ── Lua Examples ─────────────────────────────────────────────────────
    if api_path and lua_fns:
        first_fn = lua_fns[0] if lua_fns else "someFunction"
        lines += [
            "## Lua Examples",
            "",
            "```lua",
            f"-- Example: Basic {module} usage",
            "function luna.load()",
            f"    -- TODO: replace with real {module} setup",
            f"    local obj = {lua_ns}.{first_fn}()",
            "end",
            "",
            "function luna.update(dt)",
            "    -- TODO: update logic",
            "end",
            "```",
            "",
        ]
    else:
        lines += [
            "## Lua Examples",
            "",
            "```lua",
            "-- TODO: Add usage example",
            "```",
            "",
        ]

    # ── Item Summary ─────────────────────────────────────────────────────
    total = len(all_structs) + len(all_enums) + len(all_fns)
    lines += [
        "## Item Summary",
        "",
        "| Kind | Count |",
        "|------|-------|",
        f"| `struct` | {len(all_structs)} |",
        f"| `enum`   | {len(all_enums)} |",
        f"| `fn`     | {len(all_fns)} |",
        f"| **Total** | **{total}** |",
        "",
    ]

    # ── References ────────────────────────────────────────────────────────
    lines += [
        "## References",
        "",
        "| Module | Relationship | Notes |",
        "|--------|--------------|-------|",
        "| `engine` | Imports from | Uses SharedState, EngineError |",
        "| `math` | Imports from | Vec2, Color, Rect |",
        "| `lua_api` | Imported by | Binds public API to Lua |",
        "",
        "TODO: Add entries for similar modules and explain the separation of duties.",
        "",
    ]

    # ── Notes ─────────────────────────────────────────────────────────────
    lines += [
        "## Notes",
        "",
        "TODO: Document unique facts an agent must know before editing this module:",
        "- External crate constraints (version, thread-safety, API limitations)",
        "- Hardware or OS-specific behaviour (e.g., headless fallback on CI)",
        "- Known limitations or intentional omissions",
        "- Best practices and anti-patterns for this module",
        "- What Lua scripts will break if the API changes",
        "",
    ]

    return "\n".join(lines)


# ── Reporting ─────────────────────────────────────────────────────────────────

_COLORS = {
    ERROR: "\033[31m",
    WARN:  "\033[33m",
    PASS:  "\033[32m",
}
_RESET = "\033[0m"


def _fmt(f: Finding, use_color: bool = True) -> str:
    c = _COLORS.get(f.severity, "") if use_color else ""
    r = _RESET if use_color else ""
    return f"  {c}{f.severity:<5}{r}  [{f.code}] {f.name}: {f.detail}"


def report_module(module: str, findings: List[Finding], color: bool = True) -> int:
    """Print findings for one module. Returns exit code (0 or 1)."""
    errors  = [f for f in findings if f.severity == ERROR]
    warns   = [f for f in findings if f.severity == WARN]
    passes  = [f for f in findings if f.severity == PASS]

    verdict = "FAIL" if errors else ("WARN" if warns else "PASS")
    vc = {
        "FAIL": "\033[31m",
        "WARN": "\033[33m",
        "PASS": "\033[32m",
    }.get(verdict, "") if color else ""
    rc = _RESET if color else ""
    print(f"\n{vc}[{verdict}]{rc}  src/{module}/AGENT.md")
    for f in findings:
        print(_fmt(f, color))
    print(f"  ─── {len(passes)} passed, {len(warns)} warnings, {len(errors)} errors")
    return 1 if errors else 0


# ── Entry point ───────────────────────────────────────────────────────────────

def _discover_modules() -> List[str]:
    """Return all src/ subdirectories that look like modules (have mod.rs or .rs files)."""
    modules = []
    for d in sorted(SRC.iterdir()):
        if d.is_dir() and d.name != "lua_api":
            if any(d.glob("*.rs")):
                modules.append(d.name)
    return modules


def main() -> int:
    # Force UTF-8 output so box-drawing chars from //! comments don't crash on Windows
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    ap = argparse.ArgumentParser(
        description="Validate and scaffold AGENT.md files for Luna2D src/ modules.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--module", "-m", nargs="+", metavar="NAME",
                    help="Module(s) to validate")
    ap.add_argument("--all", "-a", action="store_true",
                    help="Validate all src/ modules")
    ap.add_argument("--scaffold", "-s", metavar="NAME",
                    help="Print a scaffolded AGENT.md for MODULE to stdout (does not validate)")
    ap.add_argument("--write", action="store_true",
                    help="With --scaffold: write the output to src/MODULE/AGENT.md (overwrites!)")
    ap.add_argument("--strict", action="store_true",
                    help="Treat WARN as ERROR (for CI use)")
    ap.add_argument("--json", action="store_true",
                    help="Output results as JSON")
    ap.add_argument("--no-color", action="store_true",
                    help="Suppress ANSI color codes")
    args = ap.parse_args()

    use_color = not args.no_color and sys.stdout.isatty()

    # ── Scaffold mode ─────────────────────────────────────────────────────
    if args.scaffold:
        module = args.scaffold
        module_dir = SRC / module
        if not module_dir.is_dir():
            print(f"ERROR: src/{module}/ does not exist", file=sys.stderr)
            return 2
        text = scaffold(module)
        if args.write:
            out_path = module_dir / "AGENT.md"
            out_path.write_text(text, encoding="utf-8")
            print(f"Written: {out_path.relative_to(WORKSPACE)}")
        else:
            print(text)
        return 0

    # ── Determine modules to validate ─────────────────────────────────────
    if args.all:
        modules = _discover_modules()
    elif args.module:
        modules = args.module
    else:
        # Default: all modules
        modules = _discover_modules()

    if not modules:
        print("No modules to validate — use --module or --all", file=sys.stderr)
        return 2

    # ── Validate ──────────────────────────────────────────────────────────
    all_results: dict = {}
    exit_code = 0

    for module in modules:
        findings = validate(module)

        if args.strict:
            # Promote WARN → ERROR for CI gate
            findings = [
                Finding(f.code, f.name, ERROR if f.severity == WARN else f.severity, f.detail)
                for f in findings
            ]

        all_results[module] = [f.to_dict() for f in findings]
        errors = [f for f in findings if f.severity == ERROR]
        if errors:
            exit_code = 1

    # ── Output ────────────────────────────────────────────────────────────
    if args.json:
        print(json.dumps(all_results, indent=2))
        return exit_code

    total_errors = 0
    total_warns  = 0
    for module in modules:
        findings = [Finding(**d) for d in all_results[module]]
        ec = report_module(module, findings, use_color)
        total_errors += sum(1 for f in findings if f.severity == ERROR)
        total_warns  += sum(1 for f in findings if f.severity == WARN)

    print()
    print(f"Validated {len(modules)} module(s): "
          f"{total_errors} error(s), {total_warns} warning(s)")
    if total_errors:
        print("Use --scaffold <module> to generate a starter AGENT.md for failing modules.")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
