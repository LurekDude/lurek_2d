#!/usr/bin/env python3
"""
patch_audit_module.py — Applies the docs-quality enhancement to audit_module.py.

Run once:
    python tools/audit/patch_audit_module.py
"""
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent.parent
TARGET = WORKSPACE / "tools" / "audit" / "audit_module.py"

# ---------------------------------------------------------------------------
# New check functions to insert
# ---------------------------------------------------------------------------
NEW_CHECK_FUNCTIONS = r'''
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

    # SP-04: Lua API completeness
    if has_lua_api and api_file.exists():
        api_content = read_text(api_file)
        bound_fns = re.findall(r'tbl\.set\(\s*"([^"]+)"', api_content)
        missing_fns = [fn for fn in bound_fns if fn not in content]
        if missing_fns:
            shown = missing_fns[:5]
            extra = f" (+{len(missing_fns)-5} more)" if len(missing_fns) > 5 else ""
            results.append(Check("SP-04", "Lua API completeness", ERROR,
                                  f"Functions missing from spec: {', '.join(shown)}{extra}"))
        elif bound_fns:
            results.append(Check("SP-04", "Lua API completeness", PASS,
                                  f"All {len(bound_fns)} bound functions in spec"))
        else:
            results.append(Check("SP-04", "Lua API completeness", PASS,
                                  "No tbl.set() bindings found"))
    else:
        results.append(Check("SP-04", "Lua API completeness", PASS,
                              "No Lua API file \u2014 skip"
                              if not has_lua_api else "api/ dir layout \u2014 manual check"))

    # SP-05: spec quality (no stubs)
    stub_hits = [p for p in ["TODO", "FIXME", "PLACEHOLDER", "Coming soon"]
                 if p.lower() in content.lower()]
    if stub_hits:
        results.append(Check("SP-05", "Spec quality", WARN,
                              f"Stub content found: {', '.join(stub_hits)}"))
    else:
        results.append(Check("SP-05", "Spec quality", PASS, "No stub content"))

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
    bound_fns = re.findall(r'tbl\.set\(\s*"[^"]+?"', content)
    has_sep = bool(re.search(r"// \u2500+", content))
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

    # B-02: Only register() as pub fn
    extra_pub_fns = [f for f in re.findall(r"^pub\s+fn\s+(\w+)", content, re.MULTILINE)
                     if f != "register"]
    if extra_pub_fns:
        results.append(Check("B-02", "Registration-only", ERROR,
                              f"Extra pub fn in lua_api \u2014 move to src/{module}/: "
                              + ", ".join(extra_pub_fns)))
    else:
        results.append(Check("B-02", "Registration-only", PASS,
                              "Only register() is pub fn"))

    # B-03: No impl LuaUserData in lua_api file
    if "impl LuaUserData" in content:
        results.append(Check("B-03", "impl LuaUserData placement", ERROR,
                              f"impl LuaUserData in lua_api \u2014 move to src/{module}/"))
    else:
        results.append(Check("B-03", "impl LuaUserData placement", PASS,
                              "No LuaUserData impl in lua_api file"))

    # B-04: long closures > 15 LOC (heuristic)
    large_closures: List[str] = []
    closure_start = -1
    closure_len = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if re.search(r"lua\.create_(?:function|method)\b", stripped):
            closure_start = i
            closure_len = 0
        if closure_start >= 0:
            closure_len += 1
            if closure_len > 15:
                large_closures.append(f"line {closure_start + 1}")
                closure_start = -1
        if stripped.endswith("})?)?;") or stripped == "})?;":
            closure_start = -1
    if large_closures:
        results.append(Check("B-04", "No business logic", WARN,
                              f"Long closures (>15 LOC) \u2014 delegate to domain: "
                              + ", ".join(large_closures[:3])))
    else:
        results.append(Check("B-04", "No business logic", PASS,
                              "Closures appear thin (\u226415 LOC)"))

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
                    ctx = "\n".join(lines[max(0, i - 2):i + 2])
                    if re.search(r"\b\d+\.\d+(?:f32|f64)?\b", ctx):
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
    example_file = WORKSPACE / "examples" / f"{module}.lua"

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

'''

# ---------------------------------------------------------------------------
# Replacement orchestrator (full new audit_module body)
# ---------------------------------------------------------------------------
NEW_ORCHESTRATOR = '''def audit_module(module: str) -> Tuple[str, List[Check], str]:
    """Run all automated checks for a module. Returns (module, checks, result)."""
    checks: List[Check] = []

    # Single-pass analysis: read every .rs file exactly once and gather all
    # per-file findings.  Individual check functions query this result instead of
    # re-opening files, reducing disk I/O from O(files \xd7 checks) to O(files).
    analysis = _analyze_module_files(module)

    # Phase 1: Structure & Registration
    checks.append(check_lib_rs_registration(module))
    checks.append(check_mod_rs_simplicity(module))
    checks.append(check_file_sizes(analysis))
    checks.append(check_file_naming(module))
    checks.append(Check("S-05", "Module necessity", MANUAL,
                          "Requires manual review \u2014 could this be pure Lua?"))
    checks.append(Check("S-06", "Large crate deps", MANUAL,
                          "Requires manual review \u2014 check Cargo.toml for heavy crates"))

    # Phase 2: AGENT.md Quality
    checks.extend(check_agent_md(module))

    # Phase 3: Technical Specification (docs/specs/<module>.md)
    checks.extend(check_spec_file(module))

    # Phase 4: Docstrings \u2014 domain module files
    checks.append(check_module_level_docs(analysis))
    checks.append(check_pub_item_docs(analysis))
    checks.append(check_structured_sections(module))
    checks.append(check_doc_stubs(analysis))
    checks.append(Check("D-05", "Validation tool", MANUAL,
                          "Run: python tools/docs/collect_docs.py --report-missing | grep src/<module>"))

    # Phase 4: Docstrings \u2014 Lua API file
    checks.extend(check_lua_api_docs(module))

    # Phase 5: Lua\u2194Rust Bridge Integrity
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
    checks.append(Check("T-05", "Test adequacy", MANUAL,
                          "Verify coverage of all public functions"))
    checks.append(Check("T-06", "Golden tests", MANUAL,
                          "Check if module qualifies for golden/snapshot tests"))
    checks.append(Check("T-07", "Tests pass", MANUAL,
                          f"Run: cargo test --test {module}_tests -- --nocapture"))

    # Phase 8: Documentation, Examples & Wiki
    checks.extend(check_example_file(module))
    checks.append(Check("W-03", "Example comments", MANUAL,
                          f"Verify content/examples/{module}.lua has realistic one-line comments per call"))
    checks.append(Check("W-04", "Example\u2013spec sync", MANUAL,
                          "Verify function list in example matches spec Lua API table"))
    checks.append(check_wiki_page(module))
    checks.append(Check("W-06", "Changelog entry", MANUAL,
                          "Verify recent API changes have docs/CHANGELOG.md entries"))

    # Phase 9: Code Quality
    checks.append(check_no_println(analysis))
    checks.append(Check("Q-02", "Logger levels", MANUAL,
                          "Verify log severity levels are appropriate (debug/info/warn/error)"))
    checks.append(check_unsafe(analysis))
    checks.append(check_unwrap(analysis))
    checks.append(Check("Q-05", "Rust best practices", MANUAL,
                          "Review for anti-patterns: unnecessary clones, redundant allocs"))
    checks.append(Check("Q-06", "Clippy clean", MANUAL,
                          f"Run: cargo clippy --lib -- -D warnings"))

    # Phase 10: Performance
    checks.append(Check("P-01", "Performance doc", MANUAL,
                          "Check docs/ for this module\u2019s performance notes"))
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

'''

# ---------------------------------------------------------------------------
# Quality report formatter
# ---------------------------------------------------------------------------
QUALITY_REPORT_FN = '''
def format_quality_report(module: str, checks: List[Check], result: str, date: str) -> str:
    """Generate a Markdown quality report for docs/quality/<module>.md."""
    errors = [c for c in checks if c.verdict == ERROR]
    warnings = [c for c in checks if c.verdict == WARN]
    passes = [c for c in checks if c.verdict == PASS]
    manual = [c for c in checks if c.verdict == MANUAL]

    badge = "\U0001f534 FAIL" if result == "FAIL" else "\U0001f7e2 PASS"
    lines: List[str] = [
        f"# Module Quality Report: `{module}`",
        "",
        f"> **Status**: {badge}  |  "
        f"**Date**: {date}  |  "
        f"**Score**: {len(passes)} \u2705 / {len(warnings)} \u26a0\ufe0f / "
        f"{len(errors)} \u274c / {len(manual)} \U0001f535",
        "",
        "---",
        "",
    ]

    if errors or warnings:
        lines += ["## Action Items", ""]
        if errors:
            lines += ["### \U0001f534 Errors \u2014 Must Fix Before Merge", ""]
            for c in errors:
                lines.append(f"- [ ] **{c.code}** \u2014 {c.name}: {c.detail}")
            lines.append("")
        if warnings:
            lines += ["### \U0001f7e1 Warnings \u2014 Should Fix", ""]
            for c in warnings:
                lines.append(f"- [ ] **{c.code}** \u2014 {c.name}: {c.detail}")
            lines.append("")

    phase_groups = [
        ("Phase 1 \u2014 Structure & Registration",    ["S-"]),
        ("Phase 2 \u2014 AGENT.md Quality",            ["A-"]),
        ("Phase 3 \u2014 Technical Specification",     ["SP-"]),
        ("Phase 4 \u2014 Docstrings",                  ["D-"]),
        ("Phase 5 \u2014 Lua\u2194Rust Bridge",        ["B-"]),
        ("Phase 6 \u2014 Architecture Compliance",     ["R-"]),
        ("Phase 7 \u2014 Test Coverage",               ["T-"]),
        ("Phase 8 \u2014 Documentation & Wiki",        ["W-"]),
        ("Phase 9 \u2014 Code Quality",                ["Q-"]),
        ("Phase 10 \u2014 Performance",                ["P-"]),
        ("Phase 11 \u2014 Integration & Extension",    ["I-"]),
        ("Phase 12 \u2014 Localization & Logging",     ["L-"]),
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
        icons = {PASS: "\u2705", WARN: "\u26a0\ufe0f", ERROR: "\u274c", MANUAL: "\U0001f535"}
        for c in phase_checks:
            detail = c.detail.replace("|", "\\|")
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
        "Fix all \u274c Errors, then address \u26a0\ufe0f Warnings until status shows **PASS**.",
        "",
        "_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._",
    ]

    return "\n".join(lines) + "\n"

'''

# ---------------------------------------------------------------------------
# Main patch logic
# ---------------------------------------------------------------------------

def apply_patch():
    src = TARGET.read_text(encoding="utf-8")

    # ── 1. Insert new check functions before the existing Phase 5 comment ──
    # Find the marker: the old "Phase 5: Test Coverage" section header
    PHASE5_MARKER = "# \u2500\u2500 Phase 5: Test Coverage \u2500\u2500\n"
    if PHASE5_MARKER not in src:
        # Try ASCII fallback
        PHASE5_MARKER = "# \u2014\u2014 Phase 5: Test Coverage \u2014\u2014\n"
    # Use a reliable anchor: the function definition that follows
    TEST_ANCHOR = "\ndef check_rust_test_exists(module: str) -> Check:\n"
    if TEST_ANCHOR not in src:
        print("ERROR: Could not find check_rust_test_exists anchor")
        return

    # Find everything up to and excluding check_rust_test_exists
    idx = src.index(TEST_ANCHOR)
    # Walk back to find the preceding comment line (the Phase 5 marker)
    before = src[:idx]
    after = src[idx:]

    # Insert new functions right before check_rust_test_exists
    src = before + NEW_CHECK_FUNCTIONS + after

    # ── 2. Fix check_wiki_page code W-02 → W-05 ──
    src = src.replace(
        '"""W-02: Wiki page exists for modules with Lua API."""',
        '"""W-05: Wiki page exists for modules with Lua API."""',
    )
    src = src.replace(
        'return Check("W-02", "Wiki page", PASS, "Module has no Lua API \u2014 skip")',
        'return Check("W-05", "Wiki page", PASS, "Module has no Lua API \u2014 skip")',
    )
    # Handle old version without em-dash
    src = src.replace(
        'return Check("W-02", "Wiki page", PASS, "Module has no Lua API -- skip")',
        'return Check("W-05", "Wiki page", PASS, "Module has no Lua API \u2014 skip")',
    )
    # The body PASS and WARN returns
    src = src.replace(
        'return Check("W-02", "Wiki page", PASS, str(c.relative_to(WORKSPACE)))',
        'return Check("W-05", "Wiki page", PASS, str(c.relative_to(WORKSPACE)))',
    )
    src = src.replace(
        'return Check("W-02", "Wiki page", WARN,\n'
        "                  f\"No wiki page found for module '{module}' (expected wiki/{module.title()}-API.md)\")",
        'return Check("W-05", "Wiki page", WARN,\n'
        f"                  f\"No wiki page found (expected wiki/{{module.title()}}-API.md)\")",
    )
    # Simpler fallback: replace all remaining "W-02", "Wiki page" occurrences
    src = src.replace('"W-02", "Wiki page"', '"W-05", "Wiki page"')

    # ── 3. Replace old orchestrator with new one ──
    OLD_ORCH_START = 'def audit_module(module: str) -> Tuple[str, List[Check], str]:\n    """Run all automated checks for a module. Returns (module, checks, result)."""'
    OLD_ORCH_END = '    return module, checks, result\n'

    if OLD_ORCH_START not in src:
        print("ERROR: Could not find audit_module() definition")
        return

    start_idx = src.index(OLD_ORCH_START)
    # Find the end: last occurrence of OLD_ORCH_END after start_idx
    end_idx = src.index(OLD_ORCH_END, start_idx) + len(OLD_ORCH_END)
    src = src[:start_idx] + "\n" + NEW_ORCHESTRATOR + src[end_idx:]

    # ── 4. Insert format_quality_report before format_report ──
    FORMAT_ANCHOR = "\ndef format_report(module: str, checks: List[Check], result: str) -> str:\n"
    if FORMAT_ANCHOR not in src:
        print("ERROR: Could not find format_report anchor")
        return
    idx = src.index(FORMAT_ANCHOR)
    src = src[:idx] + QUALITY_REPORT_FN + src[idx:]

    # ── 5. Update docstring for --docs-quality ──
    OLD_DOC = '    python tools/audit_module.py --help\n\nExit codes:'
    NEW_DOC = (
        '    python tools/audit_module.py --all --docs-quality  # write docs/quality/<module>.md\n'
        '    python tools/audit_module.py --help\n\nExit codes:'
    )
    src = src.replace(OLD_DOC, NEW_DOC)

    # ── 6. Add --docs-quality arg to argparse ──
    OLD_ARG = '    parser.add_argument("--output", metavar="FILE",\n                        help="Save report to file")\n    args = parser.parse_args()'
    NEW_ARG = (
        '    parser.add_argument("--output", metavar="FILE",\n'
        '                        help="Save report to file")\n'
        '    parser.add_argument("--docs-quality", action="store_true",\n'
        '                        help="Write per-module Markdown reports to docs/quality/<module>.md")\n'
        '    args = parser.parse_args()'
    )
    if OLD_ARG in src:
        src = src.replace(OLD_ARG, NEW_ARG)
    else:
        # Try without trailing newline variation
        print("WARNING: Could not find exact --output argparse block; trying fuzzy insert")
        src = src.replace(
            '    args = parser.parse_args()\n',
            '    parser.add_argument("--docs-quality", action="store_true",\n'
            '                        help="Write per-module Markdown reports to docs/quality/<module>.md")\n'
            '    args = parser.parse_args()\n',
            1,
        )

    # ── 7. Write docs/quality/<module>.md in the main loop ──
    OLD_CLEAR = '        # Release cached file content between modules so memory stays bounded\n        # when auditing many modules with --all or --tier.\n        clear_file_cache()'
    NEW_CLEAR = (
        '        # Write per-module docs/quality/<module>.md if requested\n'
        '        if args.docs_quality:\n'
        '            import datetime\n'
        '            quality_dir = WORKSPACE / "docs" / "quality"\n'
        '            quality_dir.mkdir(parents=True, exist_ok=True)\n'
        '            date_str = datetime.date.today().isoformat()\n'
        '            qr = format_quality_report(module_name, checks, result, date_str)\n'
        '            qpath = quality_dir / f"{module_name}.md"\n'
        '            qpath.write_text(qr, encoding="utf-8")\n'
        '            print(f"  docs/quality/{module_name}.md ({result})", file=sys.stderr)\n'
        '\n'
        '        # Release cached file content between modules so memory stays bounded\n'
        '        # when auditing many modules with --all or --tier.\n'
        '        clear_file_cache()'
    )
    if OLD_CLEAR in src:
        src = src.replace(OLD_CLEAR, NEW_CLEAR)
    else:
        print("WARNING: Could not find clear_file_cache block; docs-quality write not inserted")

    TARGET.write_text(src, encoding="utf-8")
    print(f"Patched {TARGET.relative_to(WORKSPACE)} successfully.")


if __name__ == "__main__":
    apply_patch()
