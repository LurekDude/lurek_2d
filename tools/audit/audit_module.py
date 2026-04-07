#!/usr/bin/env python3
"""
audit_module.py — Luna2D module quality audit tool.

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
from pathlib import Path
from typing import Dict, List, Optional, Tuple

WORKSPACE = Path(__file__).resolve().parent.parent.parent
SRC = WORKSPACE / "src"
LUA_API = SRC / "lua_api"
TESTS_RUST = WORKSPACE / "tests" / "rust"
TESTS_LUA = WORKSPACE / "tests" / "lua"
DOCS_API = WORKSPACE / "docs" / "API"
WIKI = WORKSPACE / "wiki"

# ── Tier assignments (keep in sync with docs/architecture/architecture.md) ──

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

# Additional src/ modules not in the official tier table
EXTRA = {
    "terminal", "spine", "serial", "raycaster", "procgen",
    "pipeline", "network", "light", "fx",
}

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


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return ""


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


def check_file_sizes(module: str) -> Check:
    """S-03: No .rs file exceeds 2000 LOC without justification."""
    mod_dir = SRC / module
    if not mod_dir.is_dir():
        return Check("S-03", "File size limits", ERROR, f"Module directory not found: src/{module}/")

    large_files: List[Tuple[str, int]] = []
    warning_files: List[Tuple[str, int]] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        line_count = len(read_text(rs).splitlines())
        rel = rs.relative_to(SRC)
        if line_count > 2000:
            large_files.append((str(rel), line_count))
        elif line_count > 1500:
            warning_files.append((str(rel), line_count))

    if large_files:
        desc = "; ".join(f"{f} ({n} LOC)" for f, n in large_files)
        return Check("S-03", "File size limits", ERROR, f"Files >2000 LOC: {desc}")
    if warning_files:
        desc = "; ".join(f"{f} ({n} LOC)" for f, n in warning_files)
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

REQUIRED_SECTIONS = ["Summary", "Source Files", "Key Types", "Item Summary"]
RECOMMENDED_SECTIONS = ["Architecture", "Submodules", "Lua API", "Lua Examples"]


def check_agent_md(module: str) -> List[Check]:
    """A-01 through A-06: AGENT.md quality checks."""
    results: List[Check] = []
    agent_path = SRC / module / "AGENT.md"

    # A-01: Exists
    if not agent_path.exists():
        results.append(Check("A-01", "AGENT.md exists", ERROR, "AGENT.md not found"))
        # Can't check further
        for code, name in [("A-02", "Template structure"), ("A-03", "Summary quality"),
                           ("A-04", "Content sync"), ("A-05", "Lua examples"),
                           ("A-06", "Tier label")]:
            results.append(Check(code, name, ERROR, "Skipped — no AGENT.md"))
        return results

    results.append(Check("A-01", "AGENT.md exists", PASS, str(agent_path.relative_to(WORKSPACE))))
    content = read_text(agent_path)

    # A-02: Template structure
    missing_required = [s for s in REQUIRED_SECTIONS if f"## {s}" not in content]
    missing_recommended = [s for s in RECOMMENDED_SECTIONS if f"## {s}" not in content]
    if missing_required:
        results.append(Check("A-02", "Template structure", ERROR,
                              f"Missing required sections: {', '.join(missing_required)}"))
    elif missing_recommended:
        results.append(Check("A-02", "Template structure", WARN,
                              f"Missing recommended sections: {', '.join(missing_recommended)}"))
    else:
        results.append(Check("A-02", "Template structure", PASS, "All sections present"))

    # A-03: Summary quality
    summary_match = re.search(r"## Summary\s*\n(.*?)(?=\n## |\Z)", content, re.DOTALL)
    if summary_match:
        summary_text = summary_match.group(1).strip()
        char_count = len(summary_text)
        if char_count < 300:
            results.append(Check("A-03", "Summary quality", ERROR,
                                  f"Summary too short ({char_count} chars, need 300-1000)"))
        elif char_count > 1500:
            results.append(Check("A-03", "Summary quality", WARN,
                                  f"Summary too long ({char_count} chars, target 500-1000)"))
        else:
            results.append(Check("A-03", "Summary quality", PASS,
                                  f"Summary is {char_count} chars"))
    else:
        results.append(Check("A-03", "Summary quality", ERROR, "No Summary section found"))

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

    # A-05: Lua examples
    has_lua_section = "## Lua Examples" in content or "## Lua API" in content
    has_lua_code = "```lua" in content
    has_lua_api = (LUA_API / f"{module}_api.rs").exists() or (LUA_API / module + "_api").is_dir() if module else False

    # Recompute has_lua_api more carefully
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()

    if has_lua_code:
        results.append(Check("A-05", "Lua examples", PASS, "Lua code examples present"))
    elif has_lua_api:
        results.append(Check("A-05", "Lua examples", ERROR,
                              "Module has Lua API but AGENT.md has no Lua code examples"))
    else:
        results.append(Check("A-05", "Lua examples", WARN,
                              "No Lua code examples in AGENT.md"))

    # A-06: Tier label
    tier = get_tier(module)
    has_tier = bool(re.search(r"\*\*Tier\*\*", content))
    if not has_tier:
        results.append(Check("A-06", "Tier label", ERROR, "No Tier property in AGENT.md header"))
    else:
        results.append(Check("A-06", "Tier label", PASS, f"Tier label present (expected: {tier})"))

    return results


# ── Phase 3: Docstrings ──


def check_module_level_docs(module: str) -> Check:
    """D-01: Every .rs file has //! module-level doc comment."""
    mod_dir = SRC / module
    missing: List[str] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        if not content.strip():
            continue
        # Check first 10 non-empty lines for //!
        lines = [l for l in content.splitlines()[:15] if l.strip()]
        has_mod_doc = any(l.strip().startswith("//!") for l in lines)
        if not has_mod_doc:
            missing.append(rs.relative_to(SRC).as_posix())

    if missing:
        return Check("D-01", "Module-level docs", ERROR,
                      f"Missing //! doc in: {', '.join(missing[:5])}"
                      + (f" (+{len(missing)-5} more)" if len(missing) > 5 else ""))
    return Check("D-01", "Module-level docs", PASS, "All files have //! doc comments")


def check_pub_item_docs(module: str) -> Check:
    """D-02: Every pub item has /// doc comment."""
    mod_dir = SRC / module
    undocumented: List[str] = []

    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        lines = content.splitlines()
        for i, line in enumerate(lines):
            stripped = line.strip()
            # Check for pub items
            if re.match(r"pub\s+(fn|struct|enum|trait|type|const)\s+", stripped):
                # Look backwards for /// doc comment
                has_doc = False
                for j in range(i - 1, max(i - 5, -1), -1):
                    prev = lines[j].strip()
                    if prev.startswith("///"):
                        has_doc = True
                        break
                    if prev.startswith("#[") or prev == "":
                        continue
                    break
                if not has_doc:
                    # Extract item name
                    m = re.match(r"pub\s+(fn|struct|enum|trait|type|const)\s+(\w+)", stripped)
                    if m:
                        undocumented.append(f"{rs.stem}::{m.group(2)}")

    if undocumented:
        shown = undocumented[:8]
        extra = f" (+{len(undocumented)-8} more)" if len(undocumented) > 8 else ""
        return Check("D-02", "Public item docs", ERROR,
                      f"Undocumented pub items: {', '.join(shown)}{extra}")
    return Check("D-02", "Public item docs", PASS, "All pub items have /// docs")


def check_doc_stubs(module: str) -> Check:
    """D-04: No stub/placeholder doc comments."""
    mod_dir = SRC / module
    stubs: List[str] = []
    stub_patterns = [
        "TODO",
        "FIXME",
        "Consult the module-level documentation",
        "PLACEHOLDER",
    ]

    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        for i, line in enumerate(lines := content.splitlines()):
            stripped = line.strip()
            if stripped.startswith("///") or stripped.startswith("//!"):
                for pat in stub_patterns:
                    if pat.lower() in stripped.lower():
                        stubs.append(f"{rs.stem}:{i+1}")
                        break

    if stubs:
        shown = stubs[:5]
        extra = f" (+{len(stubs)-5} more)" if len(stubs) > 5 else ""
        return Check("D-04", "Doc quality", WARN,
                      f"Stub/placeholder docs found: {', '.join(shown)}{extra}")
    return Check("D-04", "Doc quality", PASS, "No stub docs found")


# ── Phase 4: Architecture Compliance ──


def check_dependency_direction(module: str) -> Check:
    """R-02: Module imports only from allowed tiers."""
    tier = get_tier(module)
    mod_dir = SRC / module
    violations: List[str] = []

    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        imports = re.findall(r"use crate::(\w+)", content)
        for imp in imports:
            if imp == module:
                continue  # self-import
            if imp == "lua_api":
                violations.append(f"{rs.stem}: imports lua_api (R-03)")
                continue

            imp_tier = get_tier(imp)

            if tier == "baseline" and module == "math":
                if imp not in ("math",):  # math has zero deps
                    violations.append(f"{rs.stem}: math imports {imp}")
            elif tier == "baseline" and module == "engine":
                pass  # engine can import anything within baseline
            elif tier == "tier1":
                if imp_tier not in ("baseline",) and imp not in BASELINE:
                    violations.append(f"{rs.stem}: Tier 1 imports {imp} ({imp_tier})")
            elif tier == "tier2":
                if imp_tier not in ("baseline", "tier1") and imp not in BASELINE | TIER1:
                    violations.append(f"{rs.stem}: Tier 2 imports {imp} ({imp_tier})")

    if violations:
        return Check("R-02", "Dependency direction", ERROR,
                      "; ".join(violations[:5]))
    return Check("R-02", "Dependency direction", PASS,
                  f"All imports follow {tier} rules")


def check_no_lua_api_import(module: str) -> Check:
    """R-03: Domain modules never import lua_api."""
    if module == "lua_api":
        return Check("R-03", "No lua_api import", PASS, "Module IS lua_api — skip")

    mod_dir = SRC / module
    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        if "use crate::lua_api" in content or "crate::lua_api::" in content:
            return Check("R-03", "No lua_api import", ERROR,
                          f"{rs.stem} imports lua_api")
    return Check("R-03", "No lua_api import", PASS, "No lua_api imports found")


# ── Phase 5: Test Coverage ──


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


def check_no_println(module: str) -> Check:
    """Q-01: No println! or eprintln! in module code."""
    mod_dir = SRC / module
    violations: List[str] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        for i, line in enumerate(content.splitlines()):
            stripped = line.strip()
            if stripped.startswith("//"):
                continue
            if "println!" in stripped or "eprintln!" in stripped:
                violations.append(f"{rs.stem}:{i+1}")

    if violations:
        return Check("Q-01", "No println!", ERROR,
                      f"println!/eprintln! found: {', '.join(violations[:5])}")
    return Check("Q-01", "No println!", PASS, "No println!/eprintln! calls")


def check_unsafe(module: str) -> Check:
    """Q-03: No unsafe without // SAFETY: comment."""
    mod_dir = SRC / module
    violations: List[str] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        lines = content.splitlines()
        for i, line in enumerate(lines):
            if "unsafe " in line and not line.strip().startswith("//"):
                # Check surrounding lines for SAFETY comment
                context = "\n".join(lines[max(0, i-3):i+1])
                if "SAFETY:" not in context and "SAFETY :" not in context:
                    violations.append(f"{rs.stem}:{i+1}")

    if violations:
        return Check("Q-03", "No unsafe", ERROR,
                      f"unsafe without SAFETY comment: {', '.join(violations[:5])}")
    return Check("Q-03", "No unsafe", PASS, "No undocumented unsafe blocks")


def check_unwrap(module: str) -> Check:
    """Q-04: No bare .unwrap() in non-test code."""
    mod_dir = SRC / module
    unwraps: List[str] = []
    for rs in sorted(mod_dir.rglob("*.rs")):
        content = read_text(rs)
        for i, line in enumerate(content.splitlines()):
            stripped = line.strip()
            if stripped.startswith("//"):
                continue
            if ".unwrap()" in stripped:
                unwraps.append(f"{rs.stem}:{i+1}")

    if unwraps:
        shown = unwraps[:5]
        extra = f" (+{len(unwraps)-5} more)" if len(unwraps) > 5 else ""
        return Check("Q-04", "Error handling", WARN,
                      f".unwrap() calls: {', '.join(shown)}{extra}")
    return Check("Q-04", "Error handling", PASS, "No bare .unwrap() calls")


# ── Phase 6: Docs & Wiki ──


def check_wiki_page(module: str) -> Check:
    """W-02: Wiki page exists for modules with Lua API."""
    api_file = LUA_API / f"{module}_api.rs"
    api_dir = LUA_API / f"{module}_api"
    has_lua_api = api_file.exists() or api_dir.is_dir()

    if not has_lua_api:
        return Check("W-02", "Wiki page", PASS, "Module has no Lua API — skip")

    # Check common wiki page names
    candidates = [
        WIKI / f"{module.title()}-API.md",
        WIKI / f"{module.capitalize()}-API.md",
        WIKI / f"{module}-API.md",
    ]
    for c in candidates:
        if c.exists():
            return Check("W-02", "Wiki page", PASS, str(c.relative_to(WORKSPACE)))

    return Check("W-02", "Wiki page", WARN,
                  f"No wiki page found for module '{module}' (expected wiki/{module.title()}-API.md)")


def check_example_exists(module: str) -> Check:
    """W-03: Example game or test game demonstrates the module."""
    examples_dir = WORKSPACE / "examples"
    if not examples_dir.is_dir():
        return Check("W-03", "Example game", WARN, "demos/ directory not found")

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
                if f"luna.{module}" in content:
                    return Check("W-03", "Example game", PASS,
                                  f"Referenced in {d.relative_to(WORKSPACE)}/main.lua")

    return Check("W-03", "Example game", WARN,
                  f"No example found that demonstrates module '{module}'")


# ── Orchestrator ──


def audit_module(module: str) -> Tuple[str, List[Check], str]:
    """Run all automated checks for a module. Returns (module, checks, result)."""
    checks: List[Check] = []

    # Phase 1: Structure
    checks.append(check_lib_rs_registration(module))
    checks.append(check_mod_rs_simplicity(module))
    checks.append(check_file_sizes(module))
    checks.append(check_file_naming(module))
    # S-05, S-06 are manual
    checks.append(Check("S-05", "Module necessity", MANUAL, "Requires manual review"))
    checks.append(Check("S-06", "Large crate deps", MANUAL, "Requires manual review"))

    # Phase 2: AGENT.md
    checks.extend(check_agent_md(module))

    # Phase 3: Docstrings
    checks.append(check_module_level_docs(module))
    checks.append(check_pub_item_docs(module))
    checks.append(Check("D-03", "Structured sections", MANUAL,
                          "Check # Fields, # Variants, # Parameters in docstrings"))
    checks.append(check_doc_stubs(module))
    checks.append(Check("D-05", "Validation tool", MANUAL,
                          "Run: python tools/collect_docs.py --report-missing | grep src/<module>"))

    # Phase 4: Architecture
    checks.append(Check("R-01", "Tier placement", MANUAL,
                          f"Assigned tier: {get_tier(module)} — verify against architecture.md"))
    checks.append(check_dependency_direction(module))
    checks.append(check_no_lua_api_import(module))
    checks.append(Check("R-04", "Design assumptions", MANUAL,
                          "Verify against docs/design-assumptions.md"))
    checks.append(Check("R-05", "Module overlap", MANUAL,
                          "Check for scope duplication with other modules"))

    # Phase 5: Tests
    checks.append(check_rust_test_exists(module))
    checks.append(check_lua_test_exists(module))
    checks.append(Check("T-03", "Test naming", MANUAL,
                          "Verify <subject>_<scenario>_<expected> convention"))
    checks.append(Check("T-04", "Float comparisons", MANUAL,
                          "Verify no assert_eq! on f32/f64"))
    checks.append(Check("T-05", "Test adequacy", MANUAL,
                          "Verify coverage of public functions"))
    checks.append(Check("T-06", "Golden tests", MANUAL,
                          "Check if module qualifies for golden tests"))
    checks.append(Check("T-07", "Tests pass", MANUAL,
                          f"Run: cargo test --test {module}_tests"))

    # Phase 6: Docs & Wiki
    checks.append(Check("W-01", "API docs generated", MANUAL,
                          "Check docs/API/ for generated module docs"))
    checks.append(check_wiki_page(module))
    checks.append(check_example_exists(module))

    # Phase 7: Code Quality
    checks.append(check_no_println(module))
    checks.append(Check("Q-02", "Logger levels", MANUAL,
                          "Verify log severity levels are appropriate"))
    checks.append(check_unsafe(module))
    checks.append(check_unwrap(module))
    checks.append(Check("Q-05", "Rust best practices", MANUAL,
                          "Review for anti-patterns"))
    checks.append(Check("Q-06", "Clippy clean", MANUAL,
                          f"Run: cargo clippy --lib -- -D warnings"))

    # Phase 8: Performance
    checks.append(Check("P-01", "Performance doc", MANUAL,
                          "Check docs/performance/ for this module"))
    checks.append(Check("P-02", "Hot-path allocations", MANUAL,
                          "Review update/draw/step paths for heap allocations"))
    checks.append(Check("P-03", "Buffer pre-allocation", MANUAL,
                          "Review Vec/HashMap growth patterns"))

    # Phase 9: Integration
    checks.append(Check("I-01", "Lua API usability", MANUAL,
                          "Review luna.* conventions compliance"))
    checks.append(Check("I-02", "Extension panel", MANUAL,
                          "Check for structured data I/O"))
    checks.append(Check("I-03", "Config integration", MANUAL,
                          "Check conf.lua / ModulesConfig coverage"))

    # Phase 10: Localization & Logging
    checks.append(Check("L-01", "Log externalization", MANUAL,
                          "Review log string consistency"))
    checks.append(Check("L-02", "TOML message catalog", MANUAL,
                          "Check for message catalog integration"))

    # Scoring
    errors = sum(1 for c in checks if c.verdict == ERROR)
    warnings = sum(1 for c in checks if c.verdict == WARN)
    passes = sum(1 for c in checks if c.verdict == PASS)
    manual = sum(1 for c in checks if c.verdict == MANUAL)

    if errors >= 1:
        result = "FAIL"
    elif warnings >= 3:
        result = "FAIL"
    else:
        result = "PASS"

    return module, checks, result


def format_report(module: str, checks: List[Check], result: str) -> str:
    """Format a human-readable audit report."""
    lines = [
        "=" * 60,
        f"  LUNA2D MODULE AUDIT: {module} -- {result}",
        "=" * 60,
        "",
    ]

    # Group by phase
    phases = {
        "Phase 1 - Structure & Registration": ["S-"],
        "Phase 2 - AGENT.md Quality": ["A-"],
        "Phase 3 - Docstrings": ["D-"],
        "Phase 4 - Architecture Compliance": ["R-"],
        "Phase 5 - Test Coverage": ["T-"],
        "Phase 6 - Documentation & Wiki": ["W-"],
        "Phase 7 - Code Quality": ["Q-"],
        "Phase 8 - Performance": ["P-"],
        "Phase 9 - Integration & Extension": ["I-"],
        "Phase 10 - Localization & Logging": ["L-"],
    }

    for phase_name, prefixes in phases.items():
        phase_checks = [c for c in checks
                        if any(c.code.startswith(p) for p in prefixes)]
        if not phase_checks:
            continue
        lines.append(f"  {phase_name}")
        for c in phase_checks:
            icon = {PASS: "+", WARN: "!", ERROR: "X", MANUAL: "?"}[c.verdict]
            lines.append(f"    [{icon}] {c.verdict:7s}  {c.code}  {c.name}")
            if c.verdict != PASS and c.verdict != MANUAL:
                lines.append(f"              -> {c.detail}")
        lines.append("")

    # Score
    errors = sum(1 for c in checks if c.verdict == ERROR)
    warnings = sum(1 for c in checks if c.verdict == WARN)
    passes = sum(1 for c in checks if c.verdict == PASS)
    manual = sum(1 for c in checks if c.verdict == MANUAL)

    lines.append("=" * 60)
    lines.append(f"  SCORE: {passes} PASS / {warnings} WARNING / {errors} ERROR"
                 f" / {manual} MANUAL -> {result}")
    lines.append("=" * 60)

    if errors:
        lines.append("")
        lines.append("  REQUIRED ACTIONS (ERRORs):")
        for i, c in enumerate(c for c in checks if c.verdict == ERROR):
            lines.append(f"    {i+1}. {c.code}: {c.detail}")

    if warnings:
        lines.append("")
        lines.append("  RECOMMENDED IMPROVEMENTS (WARNINGs):")
        for i, c in enumerate(c for c in checks if c.verdict == WARN):
            lines.append(f"    {i+1}. {c.code}: {c.detail}")

    lines.append("")
    return "\n".join(lines)


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
        description="Luna2D module quality audit",
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
    args = parser.parse_args()

    modules = resolve_modules(args)
    if not modules:
        parser.print_help()
        print("\nError: specify module name(s), --tier N, or --all", file=sys.stderr)
        return 1

    results = []
    all_passed = True
    output_lines = []

    for mod in modules:
        mod_dir = SRC / mod
        if not mod_dir.is_dir():
            print(f"Warning: src/{mod}/ does not exist — skipping", file=sys.stderr)
            continue

        module_name, checks, result = audit_module(mod)
        results.append({"module": module_name, "checks": [c.to_dict() for c in checks],
                         "result": result})
        if result == "FAIL":
            all_passed = False

        if not args.json:
            output_lines.append(format_report(module_name, checks, result))

    # Batch summary
    if len(modules) > 1 and not args.json:
        output_lines.append("=" * 60)
        output_lines.append("  BATCH AUDIT SUMMARY")
        output_lines.append("=" * 60)
        output_lines.append("")
        output_lines.append(f"  {'Module':<20s} {'PASS':>5s} {'WARN':>5s} {'ERR':>5s} {'Result':>7s}")
        output_lines.append(f"  {'-'*20} {'-'*5} {'-'*5} {'-'*5} {'-'*7}")
        for r in results:
            p = sum(1 for c in r["checks"] if c["verdict"] == PASS)
            w = sum(1 for c in r["checks"] if c["verdict"] == WARN)
            e = sum(1 for c in r["checks"] if c["verdict"] == ERROR)
            output_lines.append(
                f"  {r['module']:<20s} {p:>5d} {w:>5d} {e:>5d} {r['result']:>7s}")
        passed = sum(1 for r in results if r["result"] == "PASS")
        output_lines.append("")
        output_lines.append(f"  Overall: {passed}/{len(results)} modules passed")
        output_lines.append("")

    if args.json:
        output = json.dumps(results, indent=2)
    else:
        output = "\n".join(output_lines)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Report saved to {args.output}")
    else:
        print(output)

    return 0 if all_passed else 1


if __name__ == "__main__":
    # Force UTF-8 output on Windows to avoid cp1250 encoding errors
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
    # Force UTF-8 output on Windows to avoid cp1250 encoding errors
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
    sys.exit(main())
