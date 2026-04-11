---
name: module-audit
description: "Load this skill when performing end-to-end quality audits on Lurek2D src/ modules: docstrings, AGENT.md sync, test coverage, architecture compliance, wiki pages, API docs, performance, and code quality. Skip it for implementing features, writing game scripts, or pure Lua work."
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

Perform a structured, reproducible end-to-end quality audit on one or more Lurek2D `src/` modules. Every check produces a discrete PASS / WARNING / ERROR verdict. A module FAILS the audit with **1+ ERROR** or **3+ WARNING**.

## Pre-requisites

Before running any checks, load these reference documents:

1. `docs/architecture/engine-architecture.md` — tier assignments and dependency rules
2. `docs/architecture/philosophy.md` — binding constraints
3. `src/lib.rs` — module registrations
4. `src/lua_api/mod.rs` — Lua API registrations

## Module Resolution

The user specifies targets as module names, group shortcuts, or `all`:

| Input | Resolves to |
|-------|-------------|
| `physics` | `src/physics/` only |
| `physics, audio` | Both modules |
| `foundations` | `math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns` |
| `all_groups` | `math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns`, `runtime`, `event`, `timer`, `thread`, `network`, `filesystem`, `render`, `audio`, `physics`, `input`, `image`, `window`, `camera`, `light`, `effect`, `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `parallax`, `minimap`, `raycaster`, `ui`, `terminal`, `ai`, `pathfind`, `save`, `mods`, `i18n`, `automation`, `sprite`, `spine` |
| `core-runtime` | `runtime`, `event`, `timer`, `thread`, `network`, `filesystem` |
| `platform-services` | `render`, `audio`, `physics`, `input`, `image`, `window`, `camera`, `light`, `effect` |
| `feature-systems` | `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `parallax`, `minimap`, `raycaster`, `ui`, `terminal`, `ai`, `pathfind`, `save`, `mods`, `i18n`, `automation`, `sprite`, `spine` |
| `edge` | `app`, `lua_api`, `devtools`, `debugbridge`, `docs`, `pipeline`, `bin` |
| `lunasome` | Lua libraries in `content/library/` — different audit checks apply |
| `all` | All `src/` modules |

All modules should be assigned to one of the five groups. Check `docs/architecture/engine-architecture.md` for the canonical group assignment.

## AGENT.md Canonical Format (SHORT)

**AGENT.md is a SHORT file.** All architecture, types, Lua API, and examples live in `docs/specs/<module>.md`. See `.github/skills/agent-md/SKILL.md` for the full two-layer authoring rules.

When checking A-02 (template structure), the canonical short AGENT.md format is:

```markdown
# `<module>` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier N — Description |
| **Status** | Implemented — Full / Partial / Stub |
| **Lua API** | `lurek.<module>` (or `—` if none) |
| **Source** | `src/<module>/` |
| **Rust Tests** | `tests/rust/unit/<module>_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_<module>.lua` (or `—` if none) |
| **Architecture** | `docs/API/<module>-design.md` (if exists, else `—`) |

## Purpose

2–5 sentences. What the module does and its scope boundary. Should let an
agent decide whether to enter this module or a different one.

## Source Files

| File | Purpose |
|------|---------|
| `file.rs` | One-line description |

## Full Specification

→ [`docs/specs/<module>.md`](../../docs/specs/<module>.md)

_Update both this file and `docs/specs/<module>.md` whenever source files,
public types, or Lua bindings change._
```

### Required Sections in AGENT.md (ERROR if missing)
- H1 heading
- Metadata table with `**Tier**` row
- `## Purpose`
- `## Source Files`
- `## Full Specification` with link to `docs/specs/<module>.md`

### What Does NOT Belong in AGENT.md
- `## Summary` (500+ chars) → goes in `docs/specs/<module>.md`
- `## Architecture` / ASCII diagrams → goes in `docs/specs/<module>.md`
- `## Submodules` → goes in `docs/specs/<module>.md`
- `## Key Types` → goes in `docs/specs/<module>.md`
- `## Lua API` table → goes in `docs/specs/<module>.md`
- `## Lua Examples` → goes in `docs/specs/<module>.md`
- `## Item Summary` → goes in `docs/specs/<module>.md`

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
1. Read `docs/architecture/engine-architecture.md` for group assignment
2. Grep `src/<module>/**/*.rs` for `use crate::` imports
3. Verify each import is from an allowed lower group:
   - Foundations: `math` has no deps; other Foundations modules may import only Foundations
   - Core Runtime: may import Foundations only
   - Platform Services: may import Foundations + Core Runtime
   - Feature Systems: may import below groups; same-group OK when acyclic
   - Edge/Integration: may import all groups
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

The audit runner automates checks across 12 phases using a single-pass file analyzer
(each `.rs` file is read exactly once per run). **Every invocation always writes a
per-module Markdown report to `docs/quality/<module>.md`** — nothing large ever
goes to stdout, so the VS Code pipe never blocks.

```powershell
# Single module — writes docs/quality/<module>.md, prints one line
python tools/audit/audit_module.py <module>

# All modules — writes 46 reports, prints one line per module + summary
python tools/audit/audit_module.py --all

# Tier subset
python tools/audit/audit_module.py --group platform-services

# JSON output (structured, for programmatic use)
python tools/audit/audit_module.py <module> --json
```

Exit code: 0 = all PASS, 1 = any FAIL, 2 = argument error.
Run time: ~0.12 s per module, under 5 s for all 46 modules.

### What every report contains (`docs/quality/<module>.md`)

```
# Module Quality Report: `<module>`
> Status: 🔴 FAIL | Score: X ✅ / Y ⚠️ / Z ❌ / N 🔵

## Action Items
### 🔴 Errors — Must Fix Before Merge
- [ ] B-03 — impl LuaUserData placement:
       Move impl LuaUserData for LuaFoo from lua_api/<m>_api.rs → src/<m>/foo.rs
- [ ] B-02 — Registration-only:
       struct definitions (move to src/<m>/): LuaFoo
- [ ] SP-04 — Lua API completeness:
       Missing from spec: load, unload (+2 more) — add to ## Lua API in docs/specs/<m>.md
       Stale in spec (not in code): oldFn — remove from spec
- [ ] W-02 — API surface coverage:
       Missing in content/examples/<m>.lua: load, unload — add with use-case comment
- [ ] T-04 — Float comparisons:
       assert_eq! with floats at: foo_tests.rs:117, foo_tests.rs:119
...

### 🟡 Warnings — Should Fix
- [ ] B-04 — No business logic in closures:
       'load' (28 LOC, line 42) — extract body to src/<m>/
       'save' has if/match/for — extract to src/<m>/

## Full Check Results
[Phase-by-phase table with all verdicts]
```

Automated checks: S-01..S-04, A-01..A-07, A-04b, SP-01..SP-06, D-01..D-09,
B-01..B-06, R-01..R-03, T-01..T-05, W-01..W-02, W-04..W-05, Q-01, Q-03..Q-04,
Q-07, I-03. Manual checks are flagged as `🔵 MANUAL` in the report.

## CAG Audit → Fix → Verify Loop

When an agent needs to fix module quality issues, follow this loop:

### Step 1 — Generate reports

```powershell
# One module
python tools/audit/audit_module.py <module>

# All modules (batch)
python tools/audit/audit_module.py --all
```

### Step 2 — Read the report

Open `docs/quality/<module>.md`. The **Action Items** section at the top lists
every ❌ Error and ⚠️ Warning checkbox with **a precise fix instruction** — file
path, method name, and what to do. Read all errors before writing any code.

### Step 3 — Fix by check ID in priority order

#### B-02 / B-03: struct/impl in lua_api
The report names the exact struct: `impl LuaUserData for LuaFoo`.
1. Move the `struct LuaFoo` definition to `src/<module>/foo.rs`
2. Move the `impl LuaUserData for LuaFoo` block to the same file
3. Add `pub use foo::LuaFoo;` in `src/<module>/mod.rs`
4. Remove from `src/lua_api/<module>_api.rs`

#### B-04: closure body too large
The report names the function and LOC: `'load' (28 LOC, line 42)`.
1. Extract the closure body into a domain method: `pub fn load(...) -> ... { ... }`
   in `src/<module>/mod.rs` or a dedicated file
2. Replace the closure body with a single delegation call:
   `let r = s.borrow_mut().load(arg)?; Ok(r)`

#### SP-04: Functions missing from spec / stale in spec
The report names missing functions explicitly.
1. For each missing: add a row to `## Lua API` in `docs/specs/<module>.md` with
   signature, parameters, return type, and one-line description
2. For each stale: remove the row from `## Lua API`

#### SP-05: Types missing/stale in Key Types
Reports `Types not in spec: Clock, Scheduler`.
1. Add a `### Clock` section to `## Key Types` in `docs/specs/<module>.md`

#### W-02: Missing from content/examples/<module>.lua
The report names the exact function names.
1. Add `lurek.<module>.<funcName>(...)` call to `content/examples/<module>.lua`
2. Prefix each call with a one-line realistic use-case comment

#### W-04: Example–spec sync mismatch
Reports which side has the extra entries.
1. Sync by adding to whichever side is missing

#### T-04: assert_eq! on floats
The report gives exact file:line.
Replace `assert_eq!(a, b)` with `assert!((a - b).abs() < 1e-5)`.

#### T-03: test_ prefix on test names
The report lists the exact function names.
Rename `fn test_foo_bar()` → `fn foo_bar_expected()` using search-replace.

#### D-06: Missing //! on lua_api file
First line of `src/lua_api/<module>_api.rs` must be: `//! <module> Lua API — registers lurek.<module>.* bindings.`

#### D-08: Rustdoc sections in lua_api
Find `# Parameters` / `# Returns` in `src/lua_api/<module>_api.rs`.
Replace with `/// @param name : type` and `/// @return type` format.

#### D-09: Missing section separators
Add `// ── funcName ──────────────────────────────────────` before each `tbl.set` block.

### Step 4 — Re-run and verify

```powershell
python tools/audit/audit_module.py <module>
# Report updated in docs/quality/<module>.md
# Status should show 🟢 PASS when all errors resolved and warnings < 3
```

### Batch fix strategy

For multiple modules, read all reports first to identify patterns, then fix the
most common error type across all modules before re-running batch mode:

```powershell
# Run batch, write reports
python tools/audit/audit_module.py --all

# Read reports to find patterns
Get-Content docs/quality/timer.md, docs/quality/physics.md, docs/quality/audio.md

# After fixing, re-run batch to verify all
python tools/audit/audit_module.py --all --docs-quality
```

## Report Template

The `--docs-quality` flag writes a Markdown report to `docs/quality/<module>.md`.
The `stdout` report format (without `--docs-quality`) shows:

```
════════════════════════════════════════════════════════
  LUREK2D MODULE AUDIT: <module> -- FAIL
════════════════════════════════════════════════════════

  Phase 1 - Structure & Registration
    [+] PASS     S-01  lib.rs registration
    [!] WARNING  S-02  mod.rs simplicity — 45 lines of logic
    [+] PASS     S-03  File size limits
    ...

  Phase 2 - AGENT.md Quality
    [+] PASS     A-01  AGENT.md exists
    [X] ERROR    A-02  Template structure — missing Key Types section
    ...

════════════════════════════════════════════════════════
  SCORE: 32 PASS / 6 WARNING / 5 ERROR / 21 MANUAL -> FAIL
════════════════════════════════════════════════════════

  REQUIRED ACTIONS (ERRORs):
    1. A-02: Add Key Types section to AGENT.md
```

## Batch Mode

When auditing multiple modules with `--all`, the tool:
1. Runs all 64 checks per module
2. Writes `docs/quality/<module>.md` for each module (if `--docs-quality` flag set)
3. Prints a batch summary to stdout:

```
════════════════════════════════════════════════════════
  BATCH AUDIT SUMMARY (46 modules)
════════════════════════════════════════════════════════

  PASS:   timer, math, input, ...
  FAIL:   physics, audio, animation, ...

  PASS: 12 / 46 modules
```

Use `Get-ChildItem docs/quality/` to verify all reports were written.

## Post-Audit Fix Workflow

See **CAG Audit → Fix → Verify Loop** above for the full agent workflow.
Summary of fix priority:

1. **Read** `docs/quality/<module>.md` — the Action Items section is the work queue
2. **Fix ERRORs** — blocking; must fix all before merge
3. **Fix WARNINGs** — reduce until fewer than 3 remain
4. **Re-run** `python tools/audit/audit_module.py <module> --docs-quality` after each fix batch
5. **Never run full build** during fixes — use `cargo check`
6. **Scoped tests only** — `cargo test --test <module>_tests` — never bare `cargo test`
7. **Commit when clean** — only after Status shows 🟢 PASS in `docs/quality/<module>.md`
