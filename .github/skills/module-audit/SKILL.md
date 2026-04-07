---
name: module-audit
description: "Load this skill when performing end-to-end quality audits on Luna2D src/ modules: docstrings, AGENT.md sync, test coverage, architecture compliance, wiki pages, API docs, performance, and code quality. Skip it for implementing features, writing game scripts, or pure Lua work."
---

# Module Audit Skill

## Owns

- End-to-end module quality audit workflow for all `src/` modules
- Docstring coverage checks via `python tools/docs/collect_docs.py --report-missing`
- AGENT.md sync verification against source files and Lua API
- Test coverage meta-analysis via `python tools/audit/test_coverage.py`
- Architecture compliance: tier rules, dependency direction, import graph
- Module audit runner: `python tools/audit/audit_module.py <name>` (PASS/WARN/ERROR verdict)
- Wiki page completeness for all audited modules

## Load When

- Performing a quality audit on one or more `src/` modules
- Checking docstring coverage, test coverage, or AGENT.md sync for a module
- Running `python tools/audit/audit_module.py <name>` and interpreting results
- Verifying architecture compliance (tier rules, dependency direction) before merging

## Purpose

Perform a structured, reproducible end-to-end quality audit on one or more Luna2D `src/` modules. Every check produces a discrete PASS / WARNING / ERROR verdict. A module FAILS the audit with **1+ ERROR** or **3+ WARNING**.

## Pre-requisites

Before running any checks, load these reference documents:

1. `docs/architecture/engine-architecture.md` — tier assignments and dependency rules
2. `docs/architecture/philosophy.md` — binding constraints
3. `src/lib.rs` — module registrations
4. `src/lua_api/mod.rs` — Lua API registrations

## Module Resolution

The user specifies targets as module names, tier groups, or `all`:

| Input | Resolves to |
|-------|-------------|
| `physics` | `src/physics/` only |
| `physics, audio` | Both modules |
| `baseline` | `math`, `engine` |
| `tier1` | `animation`, `audio`, `automation`, `camera`, `compute`, `data`, `entity`, `event`, `filesystem`, `graphics`, `image`, `input`, `physics`, `thread`, `timer`, `window` |
| `tier2` | `ai`, `dataframe`, `graph`, `gui`, `minimap`, `modding`, `overlay`, `particle`, `pathfinding`, `postfx`, `savegame`, `scene`, `tilemap` |
| `tier3` | Lua libraries in `library/` — different audit checks apply |
| `all` | All `src/` modules |

Additional modules that exist in `src/` but may not be in the official tier table (e.g., `terminal`, `spine`, `serial`, `raycaster`, `procgen`, `pipeline`, `network`, `light`, `fx`, `postfx`) should be audited using the tier rules inferred from their imports and AGENT.md.

## AGENT.md Canonical Template

When checking A-02 (template structure), the canonical AGENT.md structure is:

```markdown
# `<module>` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier N — Description |
| **Status** | Implemented — Full / Partial / Stub |
| **Lua API** | `luna.<module>` |
| **Source** | `src/<module>/` |
| **Rust Tests** | `tests/rust/unit/<module>_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_<module>.lua` |
| **Architecture** | `docs/API/<module>-design.md` (if exists) |

## Summary

500–1000 characters describing:
- What the module does (purpose)
- How it works (architecture overview)
- What design decisions were made and why
- What is intentionally NOT included (scope boundaries)

## Architecture

```
ASCII diagram of module internals
```

## Source Files

| File | Purpose |
|------|---------|
| `file.rs` | One-line description |

## Submodules

### `<module>::<submodule>`

Description of submodule purpose.

- **`TypeName`** (struct/enum): Brief description.

## Key Types

### Structs

#### `<module>::<type>::StructName`

Brief description.

### Enums

#### `<module>::<type>::EnumName`

Brief description.

## Lua API

Exposed under `luna.<module>.*` by `src/lua_api/<module>_api.rs`.

## Lua Examples

```lua
-- Example: Basic usage of luna.<module>
function luna.init()
    -- setup code
end

function luna.process(dt)
    -- update code
end
```

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | N |
| `enum` | N |
| `fn` | N |
| **Total** | **N** |
```

### Required Sections

These sections MUST be present (ERROR if missing):
- Property table (at top)
- Summary
- Source Files
- Key Types
- Item Summary

### Recommended Sections

These sections SHOULD be present (WARNING if missing):
- Architecture (ASCII diagram)
- Submodules
- Lua API
- Lua Examples

## Check Procedures

### S-01: lib.rs Registration

```
1. Read src/lib.rs
2. Search for `pub mod <module>;`
3. If module has Lua API:
   a. Search src/lua_api/mod.rs for `pub mod <module>_api;`
   b. Search src/lua_api/mod.rs `create_lua_vm()` for registration call
4. PASS if all found, ERROR if any missing
```

### S-02: mod.rs Simplicity

```
1. Read src/<module>/mod.rs
2. Count non-empty, non-comment, non-`pub mod`, non-`pub use` lines
3. If count > 100: ERROR ("mod.rs has business logic — extract to named files")
4. If count > 30: WARNING ("mod.rs has substantial logic — consider extracting")
5. Else: PASS
```

### S-03: File Size Limits

```
1. For each .rs file in src/<module>/:
   a. Count total lines
   b. If >2000 and no justification in AGENT.md: ERROR
   c. If >1500: WARNING
2. PASS if no violations
```

### S-04–S-06: Structural Checks

Run manually by reviewing file names, checking if pure-Lua alternative exists, and scanning `Cargo.toml` for heavy dependencies used only by this module.

### D-01–D-05: Docstring Checks

```
1. Run: python tools/docs/collect_docs.py --report-missing 2>&1 | grep "src/<module>"
2. If any output: ERROR (D-02, D-05)
3. For each .rs file, check first line for //! comment (D-01)
4. For structs: check for `# Fields` section (D-03)
5. For enums: check for `# Variants` section (D-03)
6. For fns: check for `# Parameters` / `# Returns` (D-03)
7. Search for "TODO", "Consult the module-level" stub text (D-04)
```

### T-01–T-07: Test Coverage

```
Test file locations (in order of precedence):
- tests/rust/unit/<module>_tests.rs (most modules)
- tests/rust/ext/<module>_ext_tests.rs (extended tests)
- tests/rust/game/<module>_tests.rs (game system tests)
- tests/rust/stress/<module>_stress_tests.rs (stress tests)
- tests/lua/unit/test_<module>.lua (Lua BDD tests)

Verification:
1. Check Cargo.toml for [[test]] entry matching module name
2. Check tests/lua/harness.rs for lua_test_<module> function
3. Run: cargo test --test <module>_tests -- --nocapture (scoped, fast)
4. Run: cargo test lua_test_<module> (if Lua tests exist)
```

### R-01–R-05: Architecture Compliance

```
1. Read docs/architecture/architecture.md for tier assignment
2. Grep src/<module>/**/*.rs for `use crate::` imports
3. Verify each import is from an allowed tier:
   - Baseline modules: math may import nothing; engine may import math
   - Tier 1: may import math, engine only
   - Tier 2: may import math, engine, Tier 1
4. Verify no `use crate::lua_api` in domain module
5. Cross-reference with other modules for scope overlap
```

### Q-01–Q-06: Code Quality

```
1. grep -r "println!" src/<module>/ → ERROR if found
2. grep -r "eprintln!" src/<module>/ → ERROR if found
3. grep -rn "unsafe" src/<module>/ → check for // SAFETY: comment
4. grep -rn "\.unwrap()" src/<module>/ → WARNING for each (except test code)
5. cargo clippy --lib -- -D warnings → filter for module files
```

## Python Validation Tool

For automated checks, use:
```
python tools/audit/audit_module.py <module_name>
python tools/audit/audit_module.py --all
python tools/audit/audit_module.py --tier 1
```

This tool automates checks S-01 through S-03, D-01, D-02, D-05, R-02, R-03, Q-01, Q-02, Q-03, and T-01, T-02. Manual checks are flagged as `MANUAL` in the output.

## Report Template

```
═══════════════════════════════════════════════════════
  LUNA2D MODULE AUDIT: <module>
═══════════════════════════════════════════════════════

Phase 1 — Structure & Registration
  [PASS]    S-01  lib.rs registration
  [WARNING] S-02  mod.rs simplicity — 45 lines of logic
  [PASS]    S-03  File size limits
  [PASS]    S-04  File naming
  [PASS]    S-05  Module necessity
  [PASS]    S-06  Large crate dependencies

Phase 2 — AGENT.md Quality
  [PASS]    A-01  AGENT.md exists
  [ERROR]   A-02  Template structure — missing Lua Examples section
  [PASS]    A-03  Summary quality — 723 chars
  [WARNING] A-04  Content sync — body.rs not in Source Files table
  [PASS]    A-05  Lua examples
  [PASS]    A-06  Tier label

Phase 3 — Docstrings
  ...

═══════════════════════════════════════════════════════
  SCORE: 22 PASS / 2 WARNING / 1 ERROR → FAIL
═══════════════════════════════════════════════════════

REQUIRED ACTIONS (ERRORs):
  1. A-02: Add Lua Examples section to AGENT.md

RECOMMENDED IMPROVEMENTS (WARNINGs):
  1. S-02: Extract 45 lines of logic from mod.rs into named file
  2. A-04: Add body.rs to Source Files table in AGENT.md
```

## Batch Mode

When auditing multiple modules, produce:
1. Individual module reports (as above)
2. A summary table at the end:

```
═══════════════════════════════════════════════════════
  BATCH AUDIT SUMMARY
═══════════════════════════════════════════════════════

| Module | PASS | WARN | ERROR | Result |
|--------|------|------|-------|--------|
| physics | 26 | 1 | 0 | PASS |
| audio | 24 | 2 | 1 | FAIL |
| math | 27 | 0 | 0 | PASS |

Overall: 2/3 modules passed
```

## Post-Audit Fix Workflow

When the user requests fixes after an audit:

1. **Prioritize**: Fix ERRORs before WARNINGs
2. **Phase order**: Structure → AGENT.md → Docstrings → Tests → Docs/Wiki
3. **Validate incrementally**: After each fix, re-run only the affected check
4. **Never run full build**: Use `cargo check` during fixes
5. **Scoped tests only**: `cargo test --test <module>_tests` — never `cargo test`
6. **Commit when clean**: Only after all ERRORs resolved and WARNINGs < 3
