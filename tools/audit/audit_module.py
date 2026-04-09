#!/usr/bin/env python3
"""
audit_module.py — Lurek2D module quality audit tool.

Runs automated structural, docstring, architecture, and code-quality checks
on one or more src/ modules and produces a PASS/WARNING/ERROR verdict per
check.  A module FAILS the audit with 1+ ERROR or 3+ WARNING.

Usage:
    python tools/audit_module.py physics          # single module
    python tools/audit_module.py physics audio     # multiple modules
    python tools/audit_module.py --tier 1          # all Tier 1 modules
    python tools/audit_module.py --tier 2          # all Tier 2 modules
    python tools/audit_module.py --all             # every src/ module
    python tools/audit_module.py --json            # JSON output
    python tools/audit_module.py --all --docs-quality  # write docs/quality/<module>.md
    python tools/audit_module.py --help

Exit codes:
    0  - all audited modules passed
    1  - at least one module failed
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

WORKSPACE = Path(__file__).resolve().parent.parent.parent
SRC = WORKSPACE / "src"
LUA_API = SRC / "lua_api"
TESTS_RUST = WORKSPACE / "tests" / "rust"
TESTS_LUA = WORKSPACE / "tests" / "lua"
DOCS_API = WORKSPACE / "docs" / "API"
WIKI = WORKSPACE / "docs" / "wiki"

# ── Tier assignments (keep in sync with docs/architecture/architecture.md) ──

BASELINE = {"math", "engine"}

# Macros and symbols re-exported at the crate root that are not module names.
# These are always allowed in any tier without triggering R-02.
CRATE_ROOT_EXPORTS = {"log_msg"}

TIER1 = {
    "animation", "audio", "automation", "camera", "compute", "data",
    "debugbridge", "devtools", "docs", "entity", "event", "filesystem",
    "graphics", "image", "input", "localization", "log", "patterns",
    "physics", "thread", "timer", "tween", "window",
}

TIER2 = {
    "ai", "dataframe", "fx", "graph", "gui", "light", "minimap", "modding",
    "network", "overlay", "particle", "pathfinding", "pipeline", "postfx",
    "procgen", "raycaster", "savegame", "scene", "serial", "spine",
    "terminal", "tilemap",
}

# Additional src/ modules not in the official tier table
EXTRA = set()  # All modules have been assigned to BASELINE, TIER1, or TIER2

ALL_TIERS = BASELINE | TIER1 | TIER2 | EXTRA


def get_tier(module: str) -> str:
    if module in BASELINE:
        return "baseline"
    if module in TIER1:
        return "tier1"
    if module in TIER2:
        return "tier2"
    return "unassigned"


# ── Verdict helpers ──

PASS = "PASS"
WARN = "WARNING"
ERROR = "ERROR"
MANUAL = "MANUAL"


class Check:
    def __init__(self, code: str, name: str, verdict: str, detail: str):
        self.code = code
        self.name = name
        self.verdict = verdict
        self.detail = detail

    def to_dict(self):
        return {
            "code": self.code,
            "name": self.name,
            "verdict": self.verdict,
            "detail": self.detail,
        }


# Module-level file cache: each .rs file is read from disk exactly once per
# audit run regardless of how many checks inspect it.  Eliminates the 8×
# redundant reads that caused the VS Code extension-host to run out of memory
# when auditing large module batches.
_FILE_CACHE: dict = {}


def read_text(path: Path) -> str:
    """Return file contents, using the in-process cache to avoid re-reads."""
    if path in _FILE_CACHE:
        return _FILE_CACHE[path]
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        text = ""
    _FILE_CACHE[path] = text
    return text


def clear_file_cache() -> None:
    """Drop the cache between module batches to bound memory usage."""
    _FILE_CACHE.clear()


# ── Single-pass per-file analysis ─────────────────────────────────────────────
#
# All checks that iterate over src/<module>/*.rs files previously each called
# rglob() and read every file independently (up to 8 separate passes).  This
# dataclass holds every finding that can be derived in a SINGLE sequential pass
# over the file set.  The check functions below simply query it.

@dataclass
class ModuleFileAnalysis:
    """All per-file findings for one module, computed in a single pass."""
    files_no_mod_doc: List[str] = field(default_factory=list)      # D-01
    undocumented_items: List[str] = field(default_factory=list)     # D-02
    stub_docs: List[str] = field(default_factory=list)              # D-04
    dep_violations: List[str] = field(default_factory=list)         # R-02
    lua_api_imports: List[str] = field(default_factory=list)        # R-03
    println_hits: List[str] = field(default_factory=list)           # Q-01
    unsafe_violations: List[str] = field(default_factory=list)      # Q-03
    unwrap_hits: List[str] = field(default_factory=list)            # Q-04
    large_files: List[Tuple[str, int]] = field(default_factory=list)
    warning_files: List[Tuple[str, int]] = field(default_factory=list)


_STUB_PATTERNS = ("TODO", "FIXME", "PLACEHOLDER", "Consult the module-level documentation")
_PUB_ITEM_RE = re.compile(r"pub\s+(?:fn|struct|enum|trait|type|const)\s+")
_PUB_ITEM_NAME_RE = re.compile(r"pub\s+(fn|struct|enum|trait|type|const)\s+(\w+)")


def _analyze_module_files(module: str) -> ModuleFileAnalysis:
    """Single-pass analysis: read each .rs file exactly once and collect all findings."""
    analysis = ModuleFileAnalysis()
    tier = get_tier(module)
    mod_dir = SRC / module
    if not mod_dir.is_dir():
        return analysis

    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)          # cache hit after first read
        lines = content.splitlines()
        rel = rs.relative_to(SRC).as_posix()
        stem = rs.stem
        n_lines = len(lines)

        # ── file-size check ────────────────────────────────────────
        if n_lines > 2000:
            analysis.large_files.append((rel, n_lines))
        elif n_lines > 1500:
            analysis.warning_files.append((rel, n_lines))

        if not content.strip():
            continue

        # ── D-01: module-level //! doc ─────────────────────────────
        first_real = [l.strip() for l in lines[:15] if l.strip()]
        if not any(l.startswith("//!") for l in first_real):
            analysis.files_no_mod_doc.append(rel)

        # ── inline state for the line-by-line scan ─────────────────
        prev_was_attr_or_blank = False
        preceding_doc = False

        for i, raw in enumerate(lines):
            stripped = raw.strip()
            is_comment = stripped.startswith("//")
            is_doc = stripped.startswith("///") or stripped.startswith("//!")

            # ── D-02: undocumented pub items ───────────────────────
            if _PUB_ITEM_RE.match(stripped):
                has_doc = False
                for j in range(i - 1, max(i - 6, -1), -1):
                    p = lines[j].strip()
                    if p.startswith("///"):
                        has_doc = True
                        break
                    if p.startswith("#[") or p == "":
                        continue
                    break
                if not has_doc:
                    m = _PUB_ITEM_NAME_RE.match(stripped)
                    if m:
                        analysis.undocumented_items.append(f"{stem}::{m.group(2)}")

            # ── D-04: stub docs ─────────────────────────────────────
            if is_doc:
                for pat in _STUB_PATTERNS:
                    if pat.lower() in stripped.lower():
                        analysis.stub_docs.append(f"{stem}:{i+1}")
                        break

            # ── Q-01: println! ─────────────────────────────────────
            if not is_comment and ("println!" in stripped or "eprintln!" in stripped):
                analysis.println_hits.append(f"{stem}:{i+1}")

            # ── Q-03: unsafe without SAFETY ────────────────────────
            if "unsafe " in raw and not is_comment:
                ctx = "\n".join(lines[max(0, i - 3):i + 1])
                if "SAFETY:" not in ctx and "SAFETY :" not in ctx:
                    analysis.unsafe_violations.append(f"{stem}:{i+1}")

            # ── Q-04: unwrap ───────────────────────────────────────
            if not is_comment and ".unwrap()" in stripped:
                analysis.unwrap_hits.append(f"{stem}:{i+1}")

        # ── R-02 / R-03: dependency direction ─────────────────────
        for imp in re.findall(r"use crate::(\w+)", content):
            if imp == module:
                continue
            if imp == "lua_api":
                analysis.lua_api_imports.append(f"{stem}")
                continue
            if imp in CRATE_ROOT_EXPORTS:
                continue  # crate-root re-exports (macros, helpers) — always allowed
            imp_tier = get_tier(imp)
            if tier == "tier1":
                if imp_tier not in ("baseline",) and imp not in BASELINE:
                    analysis.dep_violations.append(f"{stem}: Tier1 imports {imp}({imp_tier})")
            elif tier == "tier2":
                if imp_tier not in ("baseline", "tier1") and imp not in BASELINE | TIER1:
                    analysis.dep_violations.append(f"{stem}: Tier2 imports {imp}({imp_tier})")

    return analysis




# ── Phase 1: Structure & Registration ──


def check_lib_rs_registration(module: str) -> Check:
    """S-01: Module registered in lib.rs and lua_api/mod.rs."""
    lib_rs = read_text(SRC / "lib.rs")
    pattern = rf"pub\s+mod\s+{re.escape(module)}\s*;"
    if not re.search(pattern, lib_rs):
        return Check("S-01", "lib.rs registration", ERROR,
                      f"`pub mod {module};` not found in src/lib.rs")

    # Check lua_api registration (optional — some modules have no Lua API)
    lua_mod = read_text(LUA_API / "mod.rs")
    api_name = f"{module}_api"
    has_lua_api = re.search(rf"pub\s+mod\s+{re.escape(api_name)}", lua_mod)
    api_file_exists = (
        (LUA_API / f"{api_name}.rs").exists()
        or (LUA_API / api_name).is_dir()
    )

    if api_file_exists and not has_lua_api:
        return Check("S-01", "lib.rs registration", ERROR,
                      f"`{api_name}` file exists but not registered in lua_api/mod.rs")

    detail = f"Registered in lib.rs"
    if has_lua_api:
        detail += f" + lua_api ({api_name})"
    return Check("S-01", "lib.rs registration", PASS, detail)


def check_mod_rs_simplicity(module: str) -> Check:
    """S-02: mod.rs should be a thin barrel file."""
    mod_rs = SRC / module / "mod.rs"
    if not mod_rs.exists():
        return Check("S-02", "mod.rs simplicity", WARN,
                      "No mod.rs found (module may use lib-style layout)")

    content = read_text(mod_rs)
    logic_lines = 0
    for line in content.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("//"):
            continue
        if stripped.startswith("pub mod ") or stripped.startswith("mod "):
            continue
        if stripped.startswith("pub use ") or stripped.startswith("use "):
            continue
        logic_lines += 1

    if logic_lines > 100:
        return Check("S-02", "mod.rs simplicity", ERROR,
                      f"mod.rs has {logic_lines} logic lines — extract to named files")
    if logic_lines > 30:
        return Check("S-02", "mod.rs simplicity", WARN,
                      f"mod.rs has {logic_lines} logic lines — consider extracting")
    return Check("S-02", "mod.rs simplicity", PASS,
                  f"mod.rs is a thin barrel file ({logic_lines} logic lines)")


def check_file_sizes(analysis: ModuleFileAnalysis) -> Check:
    """S-03: No .rs file exceeds 2000 LOC without justification."""
    if analysis.large_files:
        desc = "; ".join(f"{f} ({n} LOC)" for f, n in analysis.large_files)
        return Check("S-03", "File size limits", ERROR, f"Files >2000 LOC: {desc}")
    if analysis.warning_files:
        desc = "; ".join(f"{f} ({n} LOC)" for f, n in analysis.warning_files)
        return Check("S-03", "File size limits", WARN, f"Files >1500 LOC: {desc}")
    return Check("S-03", "File size limits", PASS, "All files within size limits")


def check_file_naming(module: str) -> Check:
    """S-04: File names use standard game-engine terminology."""
    mod_dir = SRC / module
    suspicious: List[str] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        name = rs.stem
        if name.startswith("_") or len(name) > 30 or name.startswith("temp"):
            suspicious.append(rs.name)
    if suspicious:
        return Check("S-04", "File naming", WARN,
                      f"Potentially misleading names: {', '.join(suspicious)}")
    return Check("S-04", "File naming", PASS, "File names follow conventions")


# ── Phase 2: AGENT.md Quality ──

# Canonical AGENT.md sections (must match agent-md skill and actual src/<module>/AGENT.md files).
# See .github/skills/agent-md/SKILL.md for the authoritative template.
REQUIRED_AGENT_SECTIONS = ["Purpose", "Source Files"]
# "Full Specification" may appear as the short form "Full Spec" in older files.
REQUIRED_AGENT_SPEC_SECTION_VARIANTS = ["Full Specification", "Full Spec"]
RECOMMENDED_AGENT_SECTIONS = ["Key Types", "Lua API Summary"]


def check_agent_md(module: str) -> List[Check]:
    """A-01 through A-06: AGENT.md quality checks."""
    results: List[Check] = []
    agent_path = SRC / module / "AGENT.md"

    # A-01: Exists
    if not agent_path.exists():
        results.append(Check("A-01", "AGENT.md exists", ERROR, "AGENT.md not found"))
        # Can't check further
        for code, name in [("A-02", "Template structure"), ("A-03", "Purpose quality"),
                           ("A-04", "Content sync"), ("A-05", "Spec pointer"),
                           ("A-06", "Tier label")]:
            results.append(Check(code, name, ERROR, "Skipped — no AGENT.md"))
        return results

    results.append(Check("A-01", "AGENT.md exists", PASS, str(agent_path.relative_to(WORKSPACE))))
    content = read_text(agent_path)

    # A-02: Required section headings present
    missing_required = [s for s in REQUIRED_AGENT_SECTIONS if f"## {s}" not in content]
    # Accept "Full Specification" OR "Full Spec" as the spec pointer heading
    has_spec = any(f"## {v}" in content for v in REQUIRED_AGENT_SPEC_SECTION_VARIANTS)
    if not has_spec:
        missing_required.append("Full Specification")
    missing_recommended = [s for s in RECOMMENDED_AGENT_SECTIONS if f"## {s}" not in content]
    if missing_required:
        results.append(Check("A-02", "Template structure", ERROR,
                              f"Missing required sections: {', '.join(missing_required)}"))
    elif missing_recommended:
        results.append(Check("A-02", "Template structure", WARN,
                              f"Missing recommended sections: {', '.join(missing_recommended)}"))
    else:
        results.append(Check("A-02", "Template structure", PASS, "All sections present"))

    # A-03: Purpose section quality (replaces old "Summary quality")
    purpose_match = re.search(r"## Purpose\s*\n(.*?)(?=\n## |\Z)", content, re.DOTALL)
    if purpose_match:
        purpose_text = purpose_match.group(1).strip()
        char_count = len(purpose_text)
        if char_count < 80:
            results.append(Check("A-03", "Purpose quality", ERROR,
                                  f"Purpose too short ({char_count} chars, need ≥80)"))
        elif char_count > 1500:
            results.append(Check("A-03", "Purpose quality", WARN,
                                  f"Purpose too long ({char_count} chars, target ≤500)"))
        else:
            results.append(Check("A-03", "Purpose quality", PASS,
                                  f"Purpose section is {char_count} chars"))
    else:
        results.append(Check("A-03", "Purpose quality", ERROR, "No ## Purpose section found"))

    # A-04: Content sync — check Source Files table lists all .rs files
    mod_dir = SRC / module
    rs_files = {f.name for f in mod_dir.glob("*.rs") if f.name != "mod.rs"}
    listed_files = set(re.findall(r"\| `([^`]+\.rs)`", content))
    unlisted = rs_files - listed_files
    if unlisted:
        results.append(Check("A-04", "Content sync", ERROR,
                              f"Files not in Source Files table: {', '.join(sorted(unlisted))}"))
    else:
        results.append(Check("A-04", "Content sync", PASS, "All .rs files listed"))

    # A-05: Spec pointer — AGENT.md must point to docs/specs/<module>.md
    # Lua examples belong in docs/specs/, NOT in AGENT.md (per agent-md skill).
    # We check that a docs/specs/<module>.md companion file exists.
    spec_path = WORKSPACE / "docs" / "specs" / f"{module}.md"
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()

    if spec_path.exists():
        results.append(Check("A-05", "Spec pointer", PASS, f"docs/specs/{module}.md exists"))
    elif has_lua_api:
        results.append(Check("A-05", "Spec pointer", ERROR,
                              f"Module has Lua API but no docs/specs/{module}.md companion file"))
    else:
        results.append(Check("A-05", "Spec pointer", WARN,
                              f"No docs/specs/{module}.md companion file — create one for the full spec"))

    # A-06: Tier label
    tier = get_tier(module)
    has_tier = bool(re.search(r"\*\*Tier\*\*", content))
    if not has_tier:
        results.append(Check("A-06", "Tier label", ERROR, "No Tier property in AGENT.md header"))
    else:
        results.append(Check("A-06", "Tier label", PASS, f"Tier label present (expected: {tier})"))

    return results


# ── Phase 3: Docstrings ──


def check_module_level_docs(analysis: ModuleFileAnalysis) -> Check:
    """D-01: Every .rs file has //! module-level doc comment."""
    missing = analysis.files_no_mod_doc
    if missing:
        return Check("D-01", "Module-level docs", ERROR,
                      f"Missing //! doc in: {', '.join(missing[:5])}"
                      + (f" (+{len(missing)-5} more)" if len(missing) > 5 else ""))
    return Check("D-01", "Module-level docs", PASS, "All files have //! doc comments")


def check_pub_item_docs(analysis: ModuleFileAnalysis) -> Check:
    """D-02: Every pub item has /// doc comment."""
    undocumented = analysis.undocumented_items
    if undocumented:
        shown = undocumented[:8]
        extra = f" (+{len(undocumented)-8} more)" if len(undocumented) > 8 else ""
        return Check("D-02", "Public item docs", ERROR,
                      f"Undocumented pub items: {', '.join(shown)}{extra}")
    return Check("D-02", "Public item docs", PASS, "All pub items have /// docs")


def check_doc_stubs(analysis: ModuleFileAnalysis) -> Check:
    """D-04: No stub/placeholder doc comments."""
    stubs = analysis.stub_docs
    if stubs:
        shown = stubs[:5]
        extra = f" (+{len(stubs)-5} more)" if len(stubs) > 5 else ""
        return Check("D-04", "Doc quality", WARN,
                      f"Stub/placeholder docs found: {', '.join(shown)}{extra}")
    return Check("D-04", "Doc quality", PASS, "No stub docs found")


# ── Phase 4: Architecture Compliance ──


def check_dependency_direction(module: str, analysis: ModuleFileAnalysis) -> Check:
    """R-02: Module imports only from allowed tiers."""
    tier = get_tier(module)
    violations = analysis.dep_violations
    if violations:
        return Check("R-02", "Dependency direction", ERROR,
                      "; ".join(violations[:5]))
    return Check("R-02", "Dependency direction", PASS,
                  f"All imports follow {tier} rules")


def check_no_lua_api_import(module: str, analysis: ModuleFileAnalysis) -> Check:
    """R-03: Domain modules never import lua_api."""
    if module == "lua_api":
        return Check("R-03", "No lua_api import", PASS, "Module IS lua_api — skip")
    hits = analysis.lua_api_imports
    if hits:
        return Check("R-03", "No lua_api import", ERROR,
                      f"{hits[0]} imports lua_api")
    return Check("R-03", "No lua_api import", PASS, "No lua_api imports found")




# ── Phase 5: Test Coverage ──


# ── Phase 3b: Technical Specification ──


def check_spec_file(module: str) -> List[Check]:
    """SP-01 through SP-05: docs/specs/<module>.md content checks."""
    results: List[Check] = []
    spec_path = WORKSPACE / "docs" / "specs" / f"{module}.md"
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()

    # SP-01: spec file exists
    if not spec_path.exists():
        results.append(Check("SP-01", "Spec file exists", ERROR,
                              f"docs/specs/{module}.md is missing — create from template"))
        for code, name in [("SP-02", "Required spec sections"),
                            ("SP-03", "Summary quality"),
                            ("SP-04", "Lua API completeness"),
                            ("SP-05", "Spec quality")]:
            results.append(Check(code, name, ERROR, "Skipped — no spec file"))
        return results

    results.append(Check("SP-01", "Spec file exists", PASS, f"docs/specs/{module}.md exists"))
    content = read_text(spec_path)

    # SP-02: required sections
    REQUIRED_SPEC = ["Summary", "Architecture", "Source Files", "Key Types"]
    missing = [s for s in REQUIRED_SPEC if f"## {s}" not in content]
    if has_lua_api and "## Lua API" not in content:
        missing.append("Lua API")
    if missing:
        results.append(Check("SP-02", "Required spec sections", ERROR,
                              f"Missing sections: {', '.join(missing)}"))
    else:
        results.append(Check("SP-02", "Required spec sections", PASS,
                              "All required sections present"))

    # SP-03: summary quality
    summary_m = re.search(r"## Summary\s*\n(.*?)(?=\n## |\Z)", content, re.DOTALL)
    if summary_m:
        text = summary_m.group(1).strip()
        if len(text) < 300:
            results.append(Check("SP-03", "Summary quality", ERROR,
                                  f"Summary too short ({len(text)} chars, need \u2265300)"))
        elif len(text) > 2000:
            results.append(Check("SP-03", "Summary quality", WARN,
                                  f"Summary very long ({len(text)} chars)"))
        else:
            results.append(Check("SP-03", "Summary quality", PASS,
                                  f"Summary is {len(text)} chars"))
    else:
        results.append(Check("SP-03", "Summary quality", ERROR, "No ## Summary section"))

    # SP-04: Lua API completeness — bidirectional diff
    if has_lua_api and api_file.exists():
        api_content = read_text(api_file)
        bound_fns = re.findall(r'tbl\.set\(\s*"([^"]+)"', api_content)
        missing_fns = [fn for fn in bound_fns if fn not in content]
        # Stale: names that appear in spec ## Lua API section but not in code
        lua_api_section = re.search(r"## Lua API(.*?)(?=\n## |\Z)", content, re.DOTALL)
        stale_fns: List[str] = []
        if lua_api_section and bound_fns:
            spec_api_text = lua_api_section.group(1)
            # Look for function name patterns in the spec: `lurek.module.funcName`
            spec_fn_names = set(re.findall(r"`luna\.\w+\.(\w+)\s*\(", spec_api_text))
            if spec_fn_names:
                code_fn_set = set(bound_fns)
                stale_fns = [fn for fn in spec_fn_names if fn not in code_fn_set]

        details: List[str] = []
        if missing_fns:
            shown = missing_fns[:5]
            extra = f" (+{len(missing_fns)-5} more)" if len(missing_fns) > 5 else ""
            details.append(f"Missing from spec: {', '.join(shown)}{extra} — add to ## Lua API in docs/specs/{module}.md")
        if stale_fns:
            details.append(f"Stale in spec (not in code): {', '.join(stale_fns[:4])} — remove from spec")
        if details:
            results.append(Check("SP-04", "Lua API completeness", ERROR, " | ".join(details)))
        elif bound_fns:
            results.append(Check("SP-04", "Lua API completeness", PASS,
                                  f"All {len(bound_fns)} bound functions in spec"))
        else:
            results.append(Check("SP-04", "Lua API completeness", PASS,
                                  "No tbl.set() bindings found"))
    else:
        results.append(Check("SP-04", "Lua API completeness", PASS,
                              "No Lua API file — skip"
                              if not has_lua_api else "api/ dir layout — manual check"))

    # SP-05: Key Types cross-reference — types in spec vs types in source
    key_types_section = re.search(r"## Key Types(.*?)(?=\n## |\Z)", content, re.DOTALL)
    mod_dir = SRC / module
    code_types = set()
    for rs in mod_dir.rglob("*.rs"):
        for m in re.finditer(r"^pub\s+(?:struct|enum)\s+(\w+)", read_text(rs), re.MULTILINE):
            code_types.add(m.group(1))
    if key_types_section and code_types:
        # Match heading-based type names: ## TypeName, ### foo::bar::TypeName, #### `mod::TypeName`
        # Capture only the last path segment to handle fully-qualified names.
        _SECTION_WORDS = {"Structs", "Enums", "Overview", "Summary", "API", "Types",
                          "Traits", "Functions", "Methods", "Examples"}
        spec_type_names = set()
        for m in re.finditer(r"#{2,5}\s+`?(?:\w+::)*(\w+)`?", key_types_section.group(1)):
            name = m.group(1)
            if name not in _SECTION_WORDS:
                spec_type_names.add(name)
        missing_types = [t for t in code_types if t not in spec_type_names
                         and not t.startswith("_") and not t.endswith("Key")]
        stale_types = [t for t in spec_type_names if t not in code_types and len(t) > 2]
        type_issues: List[str] = []
        if missing_types:
            type_issues.append(f"Types not in spec: {', '.join(sorted(missing_types)[:5])}")
        if stale_types:
            type_issues.append(f"Stale in spec: {', '.join(sorted(stale_types)[:4])}")
        if type_issues:
            results.append(Check("SP-05", "Key Types accuracy", WARN, " | ".join(type_issues)))
        else:
            results.append(Check("SP-05", "Key Types accuracy", PASS,
                                  f"{len(code_types)} types — spec Key Types in sync"))
    else:
        results.append(Check("SP-05", "Key Types accuracy", PASS,
                              "No Key Types section or no public types — skip"))

    # SP-06: spec quality (no stubs)
    # Use exact case matching: PLACEHOLDER and FIXME are all-caps technical markers;
    # "placeholder" and "todo" as lowercase normally appear in legitimate spec prose
    # (UI field descriptions, template variable docs, etc.) and should not be flagged.
    stub_hits = [p for p in ["TODO", "FIXME", "PLACEHOLDER", "Coming soon"]
                 if p in content]
    if stub_hits:
        results.append(Check("SP-06", "Spec quality", WARN,
                              f"Stub content found: {', '.join(stub_hits)}"))
    else:
        results.append(Check("SP-06", "Spec quality", PASS, "No stub content"))

    return results


# ── Phase 4b: Structured Doc Sections ──


def check_structured_sections(module: str) -> Check:
    """D-03: pub structs have # Fields docs, pub enums have # Variants docs."""
    mod_dir = SRC / module
    missing: List[str] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        if "lua_api" in str(rs):
            continue
        content = read_text(rs)
        lines = content.splitlines()
        for i, line in enumerate(lines):
            m = re.match(r"pub\s+(struct|enum)\s+(\w+)", line.strip())
            if not m:
                continue
            kind, name = m.group(1), m.group(2)
            expected = "# Fields" if kind == "struct" else "# Variants"
            has_section = any(expected in lines[j]
                              for j in range(max(0, i - 25), i))
            if not has_section:
                missing.append(f"{rs.stem}::{name} ({expected})")
    if missing:
        shown = missing[:6]
        extra = f" (+{len(missing)-6} more)" if len(missing) > 6 else ""
        return Check("D-03", "Structured doc sections", WARN,
                      f"Missing structured sections: {', '.join(shown)}{extra}")
    return Check("D-03", "Structured doc sections", PASS,
                  "All pub structs/enums have structured doc sections")


# ── Phase 4c: Lua API File Docstrings ──


def check_lua_api_docs(module: str) -> List[Check]:
    """D-06 through D-09: Lua API file documentation checks."""
    results: List[Check] = []
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    skip = "No Lua API file \u2014 skip"

    if not api_file.exists() and not api_dir.is_dir():
        for code, name in [("D-06", "Lua API file docs"),
                            ("D-07", "@param/@return annotations"),
                            ("D-08", "No rustdoc in lua_api"),
                            ("D-09", "Section separators")]:
            results.append(Check(code, name, PASS, skip))
        return results

    if not api_file.exists():
        for code, name in [("D-06", "Lua API file docs"),
                            ("D-07", "@param/@return annotations"),
                            ("D-08", "No rustdoc in lua_api"),
                            ("D-09", "Section separators")]:
            results.append(Check(code, name, PASS, "api/ dir layout \u2014 manual check"))
        return results

    content = read_text(api_file)
    lines = content.splitlines()

    # D-06: //! module-level doc
    first_real = [l.strip() for l in lines[:15] if l.strip()]
    if not any(l.startswith("//!") for l in first_real):
        results.append(Check("D-06", "Lua API file docs", ERROR,
                              f"lua_api/{module}_api.rs missing //! module-level doc"))
    else:
        results.append(Check("D-06", "Lua API file docs", PASS, "//! doc comment present"))

    # D-07: @param/@return before each tbl.set
    missing_annots: List[str] = []
    for i, line in enumerate(lines):
        if 'tbl.set(' not in line:
            continue
        fn_m = re.search(r'tbl\.set\(\s*"([^"]+)"', line)
        if not fn_m:
            continue
        fn_name = fn_m.group(1)
        ctx = "\n".join(lines[max(0, i - 10):i])
        if "@param" not in ctx and "@return" not in ctx:
            missing_annots.append(fn_name)
    if missing_annots:
        shown = missing_annots[:5]
        extra = f" (+{len(missing_annots)-5} more)" if len(missing_annots) > 5 else ""
        results.append(Check("D-07", "@param/@return annotations", WARN,
                              f"Missing @param/@return before: {', '.join(shown)}{extra}"))
    else:
        results.append(Check("D-07", "@param/@return annotations", PASS,
                              "All bindings have @param/@return annotations"))

    # D-08: No rustdoc-style sections in Lua API file
    BANNED = ["# Parameters", "# Returns", "# Fields", "# Variants", "# Errors"]
    violations = [s for s in BANNED if f"\n/// {s}\n" in content or f"\n/// {s}" in content]
    if violations:
        results.append(Check("D-08", "No rustdoc in lua_api", ERROR,
                              f"Rustdoc sections found (use @param/@return): {', '.join(violations)}"))
    else:
        results.append(Check("D-08", "No rustdoc in lua_api", PASS,
                              "No rustdoc sections in Lua API file"))

    # D-09: Section separator comments if \u22653 bindings
    # Accept both Unicode box-drawing (// \u2500\u2500\u2500) and ASCII dash (// ---) separators
    bound_fns = re.findall(r'tbl\.set\(\s*"[^"]+?"', content)
    has_sep = bool(re.search(r"// [-\u2500]{3,}", content))
    if len(bound_fns) >= 3 and not has_sep:
        results.append(Check("D-09", "Section separators", WARN,
                              f"{len(bound_fns)} bindings but no // \u2500\u2500\u2500 separator comments"))
    else:
        results.append(Check("D-09", "Section separators", PASS,
                              "Separators present" if has_sep else "< 3 bindings \u2014 skip"))

    return results


# ── Phase 5: Lua\u2194Rust Bridge Integrity ──


def check_lua_bridge(module: str) -> List[Check]:
    """B-01 through B-06: Lua-Rust bridge integrity checks."""
    results: List[Check] = []
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    skip = "No Lua API \u2014 skip"

    if not api_file.exists() and not api_dir.is_dir():
        for code, name in [("B-01", "Dedicated API file"),
                            ("B-02", "Registration-only"),
                            ("B-03", "impl LuaUserData placement"),
                            ("B-04", "No business logic"),
                            ("B-05", "Rc clone pattern"),
                            ("B-06", "Flat registration body")]:
            results.append(Check(code, name, PASS, skip))
        return results

    suffix = "/" if api_dir.is_dir() else ".rs"
    results.append(Check("B-01", "Dedicated API file", PASS,
                          f"lua_api/{module}_api{suffix} present"))

    if not api_file.exists():
        for code, name in [("B-02", "Registration-only"),
                            ("B-03", "impl LuaUserData placement"),
                            ("B-04", "No business logic"),
                            ("B-05", "Rc clone pattern"),
                            ("B-06", "Flat registration body")]:
            results.append(Check(code, name, PASS, "api/ dir layout \u2014 manual check"))
        return results

    content = read_text(api_file)
    lines = content.splitlines()

    # B-02: Only register() as pub fn; also detect struct definitions
    extra_pub_fns = [f for f in re.findall(r"^pub\s+fn\s+(\w+)", content, re.MULTILINE)
                     if f != "register"]
    pub_structs_in_api = re.findall(r"^pub\s+struct\s+(\w+)", content, re.MULTILINE)
    b02_issues: List[str] = []
    if extra_pub_fns:
        b02_issues.append(f"extra pub fn (move to src/{module}/): " + ", ".join(extra_pub_fns))
    if pub_structs_in_api:
        b02_issues.append(f"struct definitions (move to src/{module}/): " + ", ".join(pub_structs_in_api))
    if b02_issues:
        results.append(Check("B-02", "Registration-only", ERROR,
                              " | ".join(b02_issues)))
    else:
        results.append(Check("B-02", "Registration-only", PASS,
                              "Only register() is pub fn"))

    # B-03: No impl LuaUserData in lua_api file — report exact struct name
    ud_impls = re.findall(r"impl\s+LuaUserData\s+for\s+(\w+)", content)
    if ud_impls:
        structs = ", ".join(ud_impls)
        results.append(Check("B-03", "impl LuaUserData placement", ERROR,
                              f"Move impl LuaUserData for {structs} from "
                              f"lua_api/{module}_api.rs → src/{module}/"))
    else:
        results.append(Check("B-03", "impl LuaUserData placement", PASS,
                              "No LuaUserData impl in lua_api file"))

    # B-04 / B-02b: Scan closures for size and control flow.
    # For each tbl.set("name", lua.create_function(...)) block, measure LOC
    # and look for control-flow keywords. Report: function name, LOC, action.
    large_closures: List[str] = []
    logic_closures: List[str] = []
    in_closure = False
    closure_fn_name = ""
    closure_start_line = 0
    closure_depth = 0
    closure_lines: List[str] = []

    for i, raw in enumerate(lines):
        stripped = raw.strip()

        # Detect start of a new binding — grab the function name from the nearby tbl.set
        if re.search(r"lua\.create_(?:function|method)\b", stripped):
            # Look backward for the tbl.set("name", ...) on the same or preceding lines
            name_m = None
            for j in range(i, max(i - 3, -1), -1):
                name_m = re.search(r'tbl\.set\(\s*"([^"]+)"', lines[j])
                if name_m:
                    break
            in_closure = True
            closure_fn_name = name_m.group(1) if name_m else f"<closure@{i+1}>"
            closure_start_line = i + 1
            closure_depth = 0
            closure_lines = []

        if in_closure:
            closure_lines.append(stripped)
            for ch in raw:
                if ch == "{":
                    closure_depth += 1
                elif ch == "}":
                    closure_depth -= 1
            # Closure ends when depth returns to 0 after opening
            if closure_depth <= 0 and len(closure_lines) > 2:
                loc = len(closure_lines)
                has_flow = any(re.search(r"\b(if |match |for |while |loop )", ln)
                               for ln in closure_lines[1:-1])
                if loc > 15:
                    large_closures.append(
                        f"'{closure_fn_name}' ({loc} LOC, line {closure_start_line}) "
                        f"— extract body to src/{module}/")
                elif has_flow:
                    logic_closures.append(
                        f"'{closure_fn_name}' has if/match/for — extract to src/{module}/")
                in_closure = False

    b04_issues = large_closures[:4] + logic_closures[:2]
    if b04_issues:
        results.append(Check("B-04", "No business logic in closures", WARN,
                              " | ".join(b04_issues)))
    else:
        results.append(Check("B-04", "No business logic in closures", PASS,
                              "Closures appear thin (≤15 LOC, no control flow)"))

    # B-05: state.clone() before move |
    missing_clone: List[str] = []
    for i, line in enumerate(lines):
        if "move |" not in line:
            continue
        ctx = "\n".join(lines[max(0, i - 5):i])
        if "state" in ctx and "state.clone()" not in ctx:
            missing_clone.append(f"line {i + 1}")
    if missing_clone:
        results.append(Check("B-05", "Rc clone pattern", WARN,
                              f"Possible missing state.clone() before move: "
                              + ", ".join(missing_clone[:3])))
    else:
        results.append(Check("B-05", "Rc clone pattern", PASS,
                              "Rc clone pattern looks correct"))

    # B-06: No tbl.set inside nested { } block
    block_wrapped: List[str] = []
    brace_depth = 0
    block_line = None
    for i, line in enumerate(lines):
        for ch in line:
            if ch == "{":
                brace_depth += 1
                if brace_depth == 2 and block_line is None:
                    block_line = i
            elif ch == "}":
                brace_depth = max(0, brace_depth - 1)
                if brace_depth < 2:
                    block_line = None
        if block_line is not None and "tbl.set(" in line:
            block_wrapped.append(f"line {block_line + 1}")
            block_line = None
    if block_wrapped:
        results.append(Check("B-06", "Flat registration body", ERROR,
                              f"tbl.set() inside {{}} block (anti-pattern): "
                              + ", ".join(block_wrapped[:3])))
    else:
        results.append(Check("B-06", "Flat registration body", PASS,
                              "All tbl.set() calls are flat statements"))

    return results


# ── Phase 6b: Tier Label ──


def check_tier_label(module: str) -> Check:
    """R-01: Tier label in AGENT.md matches the tier registry."""
    expected = get_tier(module)
    agent_path = SRC / module / "AGENT.md"
    if not agent_path.exists():
        return Check("R-01", "Tier placement", WARN, "No AGENT.md \u2014 tier label unverifiable")
    content = read_text(agent_path)
    m = re.search(r"\*\*Tier\*\*.*?(Baseline|Tier\s*1|Tier\s*2|Unassigned)",
                  content, re.IGNORECASE)
    if not m:
        return Check("R-01", "Tier placement", WARN,
                      f"No **Tier** row in AGENT.md; expected {expected}")
    found = m.group(1).lower().replace(" ", "")
    normed = ("baseline" if "baseline" in found
              else "tier1" if "1" in found
              else "tier2" if "2" in found
              else "unknown")
    if expected == "unassigned":
        return Check("R-01", "Tier placement", WARN,
                      "Module not in tier registry \u2014 verify placement")
    if normed != expected:
        return Check("R-01", "Tier placement", ERROR,
                      f"AGENT.md tier '{m.group(1)}' \u2260 registry tier '{expected}'")
    return Check("R-01", "Tier placement", PASS, f"Tier label matches: {expected}")


# ── Phase 7b: Test Conventions ──


def check_test_conventions(module: str) -> Check:
    """T-03: Test function naming \u2014 no test_ prefix."""
    for d in [TESTS_RUST / "unit", TESTS_RUST / "ext"]:
        f = d / f"{module}_tests.rs"
        if f.exists():
            content = read_text(f)
            bad = re.findall(r"\bfn\s+(test_\w+)\s*[\(<]", content)
            if bad:
                shown = bad[:5]
                extra = f" (+{len(bad)-5} more)" if len(bad) > 5 else ""
                return Check("T-03", "Test naming", WARN,
                              f"test_ prefix found \u2014 use <subject>_<scenario>_<expected>: "
                              + ", ".join(shown) + extra)
            return Check("T-03", "Test naming", PASS, "Test names follow convention")
    return Check("T-03", "Test naming", PASS, "No Rust test file \u2014 skip")


def check_float_comparisons(module: str) -> Check:
    """T-04: No assert_eq! on f32/f64 values."""
    for d in [TESTS_RUST / "unit", TESTS_RUST / "ext"]:
        f = d / f"{module}_tests.rs"
        if f.exists():
            content = read_text(f)
            lines = content.splitlines()
            violations: List[str] = []
            for i, line in enumerate(lines):
                if "assert_eq!" in line:
                    # Strip comments and string literals before checking for
                    # float literals — avoids false positives from e.g.
                    # version strings "2.0.0" or floats in // comments.
                    bare = re.sub(r'"[^"]*"', '""', line)  # remove string contents
                    bare = re.sub(r"'[^']*'", "''", bare)   # remove char literal contents
                    bare = re.sub(r"//.*$", "", bare)        # strip line comment
                    # (?!\.) prevents matching "2.0" inside "2.0.0" version strings
                    if re.search(r"\b\d+\.\d+(?:f32|f64)?(?!\.)(?!\d)", bare):
                        violations.append(f"line {i + 1}")
            if violations:
                return Check("T-04", "Float comparisons", ERROR,
                              f"assert_eq! with float literals (use abs()<epsilon): "
                              + ", ".join(violations[:5]))
            return Check("T-04", "Float comparisons", PASS, "No float assert_eq! found")
    return Check("T-04", "Float comparisons", PASS, "No Rust test file \u2014 skip")


# ── Phase 8b: Example File & API Coverage ──


def check_example_file(module: str) -> List[Check]:
    """W-01 / W-02: content/examples/<module>.lua exists and covers the full API surface."""
    results: List[Check] = []
    example_file = WORKSPACE / "content" / "examples" / f"{module}.lua"

    if not example_file.exists():
        results.append(Check("W-01", "Example file exists", ERROR,
                              f"content/examples/{module}.lua not found \u2014 create it"))
        results.append(Check("W-02", "API surface coverage", ERROR,
                              "Skipped \u2014 no example file"))
        return results

    results.append(Check("W-01", "Example file exists", PASS,
                          f"content/examples/{module}.lua present"))

    api_file = LUA_API / f"{module}_api.rs"
    if not api_file.exists():
        results.append(Check("W-02", "API surface coverage", PASS,
                              "No Lua API binding file \u2014 skip"))
        return results

    api_content = read_text(api_file)
    example_content = read_text(example_file)
    bound_fns = re.findall(r'tbl\.set\(\s*"([^"]+)"', api_content)
    missing = [fn for fn in bound_fns if fn not in example_content]
    if missing:
        shown = missing[:6]
        extra = f" (+{len(missing)-6} more)" if len(missing) > 6 else ""
        results.append(Check("W-02", "API surface coverage", ERROR,
                              f"Functions absent from content/examples/{module}.lua: "
                              + ", ".join(shown) + extra))
    else:
        results.append(Check("W-02", "API surface coverage", PASS,
                              f"All {len(bound_fns)} bound functions in example"))
    return results


# ── Phase 11b: Config Integration ──


def check_config_integration(module: str) -> Check:
    """I-03: Module has a config flag in ModulesConfig if it has a Lua API."""
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()
    if not has_lua_api:
        return Check("I-03", "Config integration", PASS,
                      "No Lua API \u2014 config flag not expected")
    config_rs = read_text(SRC / "engine" / "config.rs")
    if module in config_rs:
        return Check("I-03", "Config integration", PASS,
                      f"Module referenced in src/engine/config.rs")
    return Check("I-03", "Config integration", WARN,
                  f"Module not in src/engine/config.rs \u2014 add to ModulesConfig if toggleable")


def check_rust_test_exists(module: str) -> Check:
    """T-01: Rust test file exists and is registered in Cargo.toml."""
    test_dirs = [
        TESTS_RUST / "unit",
        TESTS_RUST / "ext",
        TESTS_RUST / "game",
    ]
    found = []
    for d in test_dirs:
        test_file = d / f"{module}_tests.rs"
        if test_file.exists():
            found.append(str(test_file.relative_to(WORKSPACE)))

    if not found:
        return Check("T-01", "Rust test file", ERROR,
                      f"No test file found for module '{module}'")

    # Check Cargo.toml registration
    cargo_toml = read_text(WORKSPACE / "Cargo.toml")
    if f'name = "{module}_tests"' not in cargo_toml:
        return Check("T-01", "Rust test file", ERROR,
                      f"Test file exists but not registered in Cargo.toml")

    return Check("T-01", "Rust test file", PASS, f"Found: {', '.join(found)}")


def check_lua_test_exists(module: str) -> Check:
    """T-02: Lua test file exists and is registered in harness.rs."""
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()

    if not has_lua_api:
        return Check("T-02", "Lua test file", PASS, "Module has no Lua API — skip")

    lua_test = TESTS_LUA / "unit" / f"test_{module}.lua"
    if not lua_test.exists():
        return Check("T-02", "Lua test file", ERROR,
                      f"Module has Lua API but no tests/lua/unit/test_{module}.lua")

    harness = read_text(TESTS_LUA / "harness.rs")
    if f"lua_test_{module}" not in harness:
        return Check("T-02", "Lua test file", ERROR,
                      f"Lua test file exists but lua_test_{module} not in harness.rs")

    return Check("T-02", "Lua test file", PASS,
                  f"tests/lua/unit/test_{module}.lua registered in harness")


# ── Phase 7: Code Quality ──


# ── Phase 7: Code Quality ──


def check_no_println(analysis: ModuleFileAnalysis) -> Check:
    """Q-01: No println! or eprintln! in module code."""
    violations = analysis.println_hits
    if violations:
        return Check("Q-01", "No println!", ERROR,
                      f"println!/eprintln! found: {', '.join(violations[:5])}")
    return Check("Q-01", "No println!", PASS, "No println!/eprintln! calls")


def check_unsafe(analysis: ModuleFileAnalysis) -> Check:
    """Q-03: No unsafe without // SAFETY: comment."""
    violations = analysis.unsafe_violations
    if violations:
        return Check("Q-03", "No unsafe", ERROR,
                      f"unsafe without SAFETY comment: {', '.join(violations[:5])}")
    return Check("Q-03", "No unsafe", PASS, "No undocumented unsafe blocks")


def check_unwrap(analysis: ModuleFileAnalysis) -> Check:
    """Q-04: No bare .unwrap() in non-test code."""
    unwraps = analysis.unwrap_hits
    if unwraps:
        shown = unwraps[:5]
        extra = f" (+{len(unwraps)-5} more)" if len(unwraps) > 5 else ""
        return Check("Q-04", "Error handling", WARN,
                      f".unwrap() calls: {', '.join(shown)}{extra}")
    return Check("Q-04", "Error handling", PASS, "No bare .unwrap() calls")




# ── Phase 6: Docs & Wiki ──


def check_wiki_page(module: str) -> Check:
    """W-05: Wiki page exists for modules with Lua API."""
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()

    if not has_lua_api:
        return Check("W-05", "Wiki page", PASS, "Module has no Lua API — skip")

    # Check common wiki page names
    candidates = [
        WIKI / f"{module.title()}-API.md",
        WIKI / f"{module.capitalize()}-API.md",
        WIKI / f"{module}-API.md",
    ]
    for c in candidates:
        if c.exists():
            return Check("W-05", "Wiki page", PASS, str(c.relative_to(WORKSPACE)))

    return Check("W-05", "Wiki page", WARN,
                  f"No wiki page found (expected docs/wiki/{module.title()}-API.md)")


def check_example_exists(module: str) -> Check:
    """W-03: Example game or test game demonstrates the module."""
    examples_dir = WORKSPACE / "content" / "demos"
    if not examples_dir.is_dir():
        return Check("W-03", "Example game", WARN, "content/demos/ directory not found")

    # Check for module-named example or demo
    candidates = [
        examples_dir / module,
        examples_dir / f"{module}_demo",
    ]
    for c in candidates:
        if c.is_dir():
            return Check("W-03", "Example game", PASS,
                          str(c.relative_to(WORKSPACE)))

    # Check if any example references the module
    for d in sorted(examples_dir.iterdir()):
        if d.is_dir():
            main_lua = d / "main.lua"
            if main_lua.exists():
                content = read_text(main_lua)
                if f"lurek.{module}" in content:
                    return Check("W-03", "Example game", PASS,
                                  f"Referenced in {d.relative_to(WORKSPACE)}/main.lua")

    return Check("W-03", "Example game", WARN,
                  f"No example found that demonstrates module '{module}'")


def check_test_adequacy(module: str) -> Check:
    """T-05 (automated): Compare pub fn count in domain vs #[test] count in test file."""
    mod_dir = SRC / module
    pub_fn_count = 0
    for rs in mod_dir.rglob("*.rs"):
        pub_fn_count += len(re.findall(r"^    pub\s+fn\s+\w+", read_text(rs), re.MULTILINE))
    if pub_fn_count == 0:
        return Check("T-05", "Test adequacy", PASS, "No pub methods counted — skip")

    test_file = None
    for d in [TESTS_RUST / "unit", TESTS_RUST / "ext"]:
        f = d / f"{module}_tests.rs"
        if f.exists():
            test_file = f
            break
    if not test_file:
        return Check("T-05", "Test adequacy", WARN,
                      f"{pub_fn_count} pub methods, 0 Rust tests — create test file")

    test_count = len(re.findall(r"#\[test\]", read_text(test_file)))
    ratio = test_count / pub_fn_count if pub_fn_count else 1.0
    if ratio < 0.3:
        return Check("T-05", "Test adequacy", WARN,
                      f"{test_count} tests / {pub_fn_count} pub methods ({ratio:.0%}) — low coverage")
    return Check("T-05", "Test adequacy", PASS,
                  f"{test_count} tests / {pub_fn_count} pub methods ({ratio:.0%})")


def check_log_prefix(module: str, analysis: ModuleFileAnalysis) -> Check:
    """Q-07: Log calls use log:: prefix (log::info!, log::warn!, etc.)."""
    mod_dir = SRC / module
    bare_log: List[str] = []
    for rs in mod_dir.rglob("*.rs"):
        content = read_text(rs)
        for i, line in enumerate(content.splitlines()):
            stripped = line.strip()
            if stripped.startswith("//"):
                continue
            # Bare info!/warn!/error!/debug! without log:: prefix
            m = re.search(r'(?<!\w)(info|warn|error|debug)!\s*\(', stripped)
            if m and "log::" not in stripped:
                bare_log.append(f"{rs.stem}:{i+1}")
    if bare_log:
        shown = bare_log[:5]
        extra = f" (+{len(bare_log)-5} more)" if len(bare_log) > 5 else ""
        return Check("Q-07", "Log prefix", WARN,
                      f"Bare log macro (add log:: prefix): {', '.join(shown)}{extra}")
    return Check("Q-07", "Log prefix", PASS, "All log calls use log:: prefix")


def check_example_spec_sync(module: str) -> Check:
    """W-04: Functions in docs/specs/<module>.md Lua API table match functions in content/examples/<module>.lua."""
    spec_path = WORKSPACE / "docs" / "specs" / f"{module}.md"
    example_file = WORKSPACE / "examples" / f"{module}.lua"
    api_file = LUA_API / f"{module}_api.rs"
    if not api_file.exists():
        return Check("W-04", "Example–spec sync", PASS, "No Lua API — skip")
    if not spec_path.exists() or not example_file.exists():
        return Check("W-04", "Example–spec sync", PASS, "Missing spec or example — other checks cover this")

    api_content = read_text(api_file)
    bound_fns = set(re.findall(r'tbl\.set\(\s*"([^"]+)"', api_content))
    if not bound_fns:
        return Check("W-04", "Example–spec sync", PASS, "No bound functions")

    example_content = read_text(example_file)
    spec_content = read_text(spec_path)

    in_example = {fn for fn in bound_fns if fn in example_content}
    in_spec = {fn for fn in bound_fns if fn in spec_content}
    only_in_example = in_example - in_spec
    only_in_spec = in_spec - in_example

    issues: List[str] = []
    if only_in_example:
        issues.append(f"In example but not spec: {', '.join(sorted(only_in_example)[:4])} — add to ## Lua API in docs/specs/{module}.md")
    if only_in_spec:
        issues.append(f"In spec but not example: {', '.join(sorted(only_in_spec)[:4])} — add to content/examples/{module}.lua")
    if issues:
        return Check("W-04", "Example–spec sync", WARN, " | ".join(issues))
    return Check("W-04", "Example–spec sync", PASS,
                  f"All {len(in_spec)} functions consistent across spec and example")


def check_agent_source_files_complete(module: str) -> Check:
    """A-04b: AGENT.md Source Files table covers all .rs files including submodule dirs."""
    agent_path = SRC / module / "AGENT.md"
    if not agent_path.exists():
        return Check("A-04b", "Source Files completeness", PASS, "No AGENT.md — other check handles this")
    content = read_text(agent_path)
    mod_dir = SRC / module
    # All .rs files (including in subdirs, not just top-level)
    all_rs = {f.name for f in mod_dir.rglob("*.rs")}
    listed = set(re.findall(r"\| `([^`]+\.rs)`", content))
    unlisted = all_rs - listed
    if unlisted:
        return Check("A-04b", "Source Files completeness (incl. subdirs)", WARN,
                      f"Nested .rs files not listed in AGENT.md: {', '.join(sorted(unlisted)[:6])}")
    return Check("A-04b", "Source Files completeness (incl. subdirs)", PASS,
                  "All nested .rs files listed in AGENT.md")


# ── Orchestrator ──


def audit_module(module: str) -> Tuple[str, List[Check], str]:
    """Run all automated checks for a module. Returns (module, checks, result)."""
    checks: List[Check] = []

    # Single-pass analysis: read every .rs file exactly once and gather all
    # per-file findings.  Individual check functions query this result instead of
    # re-opening files, reducing disk I/O from O(files × checks) to O(files).
    analysis = _analyze_module_files(module)

    # Phase 1: Structure & Registration
    checks.append(check_lib_rs_registration(module))
    checks.append(check_mod_rs_simplicity(module))
    checks.append(check_file_sizes(analysis))
    checks.append(check_file_naming(module))
    checks.append(Check("S-05", "Module necessity", MANUAL,
                          "Requires manual review — could this be pure Lua?"))
    checks.append(Check("S-06", "Large crate deps", MANUAL,
                          "Requires manual review — check Cargo.toml for heavy crates"))

    # Phase 2: AGENT.md Quality
    checks.extend(check_agent_md(module))
    checks.append(check_agent_source_files_complete(module))

    # Phase 3: Technical Specification (docs/specs/<module>.md)
    checks.extend(check_spec_file(module))

    # Phase 4: Docstrings — domain module files
    checks.append(check_module_level_docs(analysis))
    checks.append(check_pub_item_docs(analysis))
    checks.append(check_structured_sections(module))
    checks.append(check_doc_stubs(analysis))
    checks.append(Check("D-05", "Validation tool", MANUAL,
                          "Run: python tools/docs/collect_docs.py --report-missing | grep src/<module>"))

    # Phase 4: Docstrings — Lua API file
    checks.extend(check_lua_api_docs(module))

    # Phase 5: Lua↔Rust Bridge Integrity
    checks.extend(check_lua_bridge(module))

    # Phase 6: Architecture Compliance
    checks.append(check_tier_label(module))
    checks.append(check_dependency_direction(module, analysis))
    checks.append(check_no_lua_api_import(module, analysis))
    checks.append(Check("R-04", "Design assumptions", MANUAL,
                          "Verify against docs/architecture/philosophy.md"))
    checks.append(Check("R-05", "Module overlap", MANUAL,
                          "Check for scope duplication with other modules"))

    # Phase 7: Test Coverage
    checks.append(check_rust_test_exists(module))
    checks.append(check_lua_test_exists(module))
    checks.append(check_test_conventions(module))
    checks.append(check_float_comparisons(module))
    checks.append(check_test_adequacy(module))
    checks.append(Check("T-06", "Golden tests", MANUAL,
                          "Check if module qualifies for golden/snapshot tests"))
    checks.append(Check("T-07", "Tests pass", MANUAL,
                          f"Run: cargo test --test {module}_tests -- --nocapture"))

    # Phase 8: Documentation, Examples & Wiki
    checks.extend(check_example_file(module))
    checks.append(Check("W-03", "Example comments", MANUAL,
                          f"Verify content/examples/{module}.lua has realistic one-line comments per call"))
    checks.append(check_example_spec_sync(module))
    checks.append(check_wiki_page(module))
    checks.append(Check("W-06", "Changelog entry", MANUAL,
                          "Verify recent API changes have docs/CHANGELOG.md entries"))

    # Phase 9: Code Quality
    checks.append(check_no_println(analysis))
    checks.append(Check("Q-02", "Logger levels", MANUAL,
                          "Verify log severity levels are appropriate (debug/info/warn/error)"))
    checks.append(check_unsafe(analysis))
    checks.append(check_unwrap(analysis))
    checks.append(check_log_prefix(module, analysis))
    checks.append(Check("Q-05", "Rust best practices", MANUAL,
                          "Review for anti-patterns: unnecessary clones, redundant allocs"))
    checks.append(Check("Q-06", "Clippy clean", MANUAL,
                          f"Run: cargo clippy --lib -- -D warnings"))

    # Phase 10: Performance
    checks.append(Check("P-01", "Performance doc", MANUAL,
                          "Check docs/ for this module’s performance notes"))
    checks.append(Check("P-02", "Hot-path allocations", MANUAL,
                          "Review update/draw/step paths for heap allocations"))
    checks.append(Check("P-03", "Buffer pre-allocation", MANUAL,
                          "Review Vec/HashMap growth patterns"))

    # Phase 11: Integration & Extension
    checks.append(Check("I-01", "Lua API usability", MANUAL,
                          "Review lurek.* conventions compliance"))
    checks.append(Check("I-02", "Extension panel", MANUAL,
                          "Check for structured data I/O for vscode-extension"))
    checks.append(check_config_integration(module))

    # Phase 12: Localization & Logging
    checks.append(Check("L-01", "Log externalization", MANUAL,
                          "Review log string consistency"))
    checks.append(Check("L-02", "TOML message catalog", MANUAL,
                          "Check for message catalog integration"))

    # Scoring
    errors = sum(1 for c in checks if c.verdict == ERROR)
    warnings = sum(1 for c in checks if c.verdict == WARN)

    if errors >= 1:
        result = "FAIL"
    elif warnings >= 3:
        result = "FAIL"
    else:
        result = "PASS"

    return module, checks, result



def format_quality_report(module: str, checks: List[Check], result: str, date: str) -> str:
    """Generate a Markdown quality report for docs/quality/<module>.md."""
    errors = [c for c in checks if c.verdict == ERROR]
    warnings = [c for c in checks if c.verdict == WARN]
    passes = [c for c in checks if c.verdict == PASS]
    manual = [c for c in checks if c.verdict == MANUAL]

    badge = "🔴 FAIL" if result == "FAIL" else "🟢 PASS"
    lines: List[str] = [
        f"# Module Quality Report: `{module}`",
        "",
        f"> **Status**: {badge}  |  "
        f"**Date**: {date}  |  "
        f"**Score**: {len(passes)} ✅ / {len(warnings)} ⚠️ / "
        f"{len(errors)} ❌ / {len(manual)} 🔵",
        "",
        "---",
        "",
    ]

    if errors or warnings:
        lines += ["## Action Items", ""]
        if errors:
            lines += ["### 🔴 Errors — Must Fix Before Merge", ""]
            for c in errors:
                lines.append(f"- [ ] **{c.code}** — {c.name}: {c.detail}")
            lines.append("")
        if warnings:
            lines += ["### 🟡 Warnings — Should Fix", ""]
            for c in warnings:
                lines.append(f"- [ ] **{c.code}** — {c.name}: {c.detail}")
            lines.append("")

    phase_groups = [
        ("Phase 1 — Structure & Registration",    ["S-"]),
        ("Phase 2 — AGENT.md Quality",            ["A-"]),
        ("Phase 3 — Technical Specification",     ["SP-"]),
        ("Phase 4 — Docstrings",                  ["D-"]),
        ("Phase 5 — Lua↔Rust Bridge",        ["B-"]),
        ("Phase 6 — Architecture Compliance",     ["R-"]),
        ("Phase 7 — Test Coverage",               ["T-"]),
        ("Phase 8 — Documentation & Wiki",        ["W-"]),
        ("Phase 9 — Code Quality",                ["Q-"]),
        ("Phase 10 — Performance",                ["P-"]),
        ("Phase 11 — Integration & Extension",    ["I-"]),
        ("Phase 12 — Localization & Logging",     ["L-"]),
    ]

    lines += ["## Full Check Results", ""]
    for phase_name, prefixes in phase_groups:
        phase_checks = [c for c in checks if any(c.code.startswith(p) for p in prefixes)]
        if not phase_checks:
            continue
        lines += [
            f"### {phase_name}",
            "",
            "| Check | Verdict | Details |",
            "|-------|---------|---------|",
        ]
        icons = {PASS: "✅", WARN: "⚠️", ERROR: "❌", MANUAL: "🔵"}
        for c in phase_checks:
            detail = c.detail.replace("|", r"\|")
            lines.append(f"| **{c.code}** {c.name} | {icons[c.verdict]} {c.verdict} | {detail} |")
        lines.append("")

    lines += [
        "---",
        "",
        "## Verification",
        "",
        "Re-run this report after applying fixes:",
        "",
        "```powershell",
        f"python tools/audit/audit_module.py {module} --docs-quality",
        "```",
        "",
        "Fix all ❌ Errors, then address ⚠️ Warnings until status shows **PASS**.",
        "",
        "_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._",
    ]

    return "\n".join(lines) + "\n"


def resolve_modules(args: argparse.Namespace) -> List[str]:
    """Resolve module list from CLI arguments."""
    if args.all:
        return sorted(m.name for m in SRC.iterdir()
                      if m.is_dir() and not m.name.startswith(".")
                      and m.name not in ("bin",))
    if args.tier is not None:
        tier_map = {0: BASELINE, 1: TIER1, 2: TIER2}
        return sorted(tier_map.get(args.tier, set()))
    if args.modules:
        return args.modules
    return []


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Lurek2D module quality audit",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("modules", nargs="*", help="Module name(s) to audit")
    parser.add_argument("--all", action="store_true",
                        help="Audit all src/ modules")
    parser.add_argument("--tier", type=int, choices=[0, 1, 2],
                        help="Audit all modules in a tier (0=baseline, 1, 2)")
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON")
    parser.add_argument("--output", metavar="FILE",
                        help="Save report to file")
    parser.add_argument("--docs-quality", action="store_true",
                        help="Write per-module Markdown reports to docs/quality/<module>.md")
    args = parser.parse_args()

    modules = resolve_modules(args)
    if not modules:
        parser.print_help()
        print("\nError: specify module name(s), --tier N, or --all", file=sys.stderr)
        return 1

    results = []
    all_passed = True

    for mod in modules:
        mod_dir = SRC / mod
        if not mod_dir.is_dir():
            print(f"Warning: src/{mod}/ does not exist — skipping", file=sys.stderr, flush=True)
            continue

        module_name, checks, result = audit_module(mod)
        results.append({"module": module_name, "checks": [c.to_dict() for c in checks],
                         "result": result})
        if result == "FAIL":
            all_passed = False

        if not args.json:
            import datetime
            quality_dir = WORKSPACE / "docs" / "quality"
            quality_dir.mkdir(parents=True, exist_ok=True)
            date_str = datetime.date.today().isoformat()
            qr = format_quality_report(module_name, checks, result, date_str)
            qpath = quality_dir / f"{module_name}.md"
            qpath.write_text(qr, encoding="utf-8")
            # One short line — never fills the pipe.
            print(f"docs/quality/{module_name}.md [{result}]", flush=True)

        # Release cached file content between modules so memory stays bounded.
        clear_file_cache()

    if len(modules) > 1 and not args.json:
        passed = sum(1 for r in results if r["result"] == "PASS")
        failed = len(results) - passed
        print(f"\n{passed}/{len(results)} passed — {failed} failed — reports in docs/quality/",
              flush=True)

    if args.json:
        output = json.dumps(results, indent=2)
        if args.output:
            Path(args.output).write_text(output, encoding="utf-8")
            print(f"JSON report saved to {args.output}", flush=True)
        else:
            for ln in output.splitlines():
                print(ln, flush=True)

    return 0 if all_passed else 1


if __name__ == "__main__":
    # Reconfigure the EXISTING stdout/stderr wrappers to use UTF-8.
    # This avoids the cp1250 encoding crash on Windows WITHOUT replacing the
    # wrapper objects — replacing them creates a new block-buffered
    # io.TextIOWrapper whose flush on sys.exit() deadlocks VS Code's pipe.
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    except AttributeError:
        pass  # Python < 3.7 or already binary (e.g. pytest capture)
    try:
        sys.exit(main())
    finally:
        # Flush before the interpreter tears down the pipe.
        try:
            sys.stdout.flush()
        except Exception:
            pass
