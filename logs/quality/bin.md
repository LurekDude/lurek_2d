# Module Quality Report: `bin`

> **Status**: 🔴 FAIL  |  **Date**: 2026-04-11  |  **Score**: 41 ✅ / 3 ⚠️ / 4 ❌ / 19 🔵

---

## Action Items

### 🔴 Errors — Must Fix Before Merge

- [ ] **S-01** — lib.rs registration: `pub mod bin;` not found in src/lib.rs
- [ ] **T-01** — Rust test file: No test file found for module 'bin'
- [ ] **W-01** — Example file exists: content/examples/bin.lua not found — create it
- [ ] **W-02** — API surface coverage: Skipped — no example file

### 🟡 Warnings — Should Fix

- [ ] **S-02** — mod.rs simplicity: No mod.rs found (module may use lib-style layout)
- [ ] **A-02** — Template structure: Missing recommended sections: Key Types, Lua API Summary
- [ ] **R-01** — Tier placement: No **Tier** row in AGENT.md; expected unassigned

## Full Check Results

### Phase 1 — Structure & Registration

| Check | Verdict | Details |
|-------|---------|---------|
| **S-01** lib.rs registration | ❌ ERROR | `pub mod bin;` not found in src/lib.rs |
| **S-02** mod.rs simplicity | ⚠️ WARNING | No mod.rs found (module may use lib-style layout) |
| **S-03** File size limits | ✅ PASS | All files within size limits |
| **S-04** File naming | ✅ PASS | File names follow conventions |
| **S-05** Module necessity | 🔵 MANUAL | Requires manual review — could this be pure Lua? |
| **S-06** Large crate deps | 🔵 MANUAL | Requires manual review — check Cargo.toml for heavy crates |

### Phase 2 — AGENT.md Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **A-01** AGENT.md exists | ✅ PASS | src\bin\AGENT.md |
| **A-02** Template structure | ⚠️ WARNING | Missing recommended sections: Key Types, Lua API Summary |
| **A-03** Purpose quality | ✅ PASS | Purpose section is 428 chars |
| **A-04** Content sync | ✅ PASS | All .rs files listed |
| **A-05** Spec pointer | ✅ PASS | docs/specs/bin.md exists |
| **A-06** Tier label | ✅ PASS | Tier label present (expected: unassigned) |
| **A-04b** Source Files completeness (incl. subdirs) | ✅ PASS | All nested .rs files listed in AGENT.md |

### Phase 3 — Technical Specification

| Check | Verdict | Details |
|-------|---------|---------|
| **SP-01** Spec file exists | ✅ PASS | docs/specs/bin.md exists |
| **SP-02** Required spec sections | ✅ PASS | All required sections present |
| **SP-03** Summary quality | ✅ PASS | Summary is 1579 chars |
| **SP-04** Lua API completeness | ✅ PASS | No Lua API file — skip |
| **SP-05** Key Types accuracy | ✅ PASS | No Key Types section or no public types — skip |
| **SP-06** Spec quality | ✅ PASS | No stub content |

### Phase 4 — Docstrings

| Check | Verdict | Details |
|-------|---------|---------|
| **D-01** Module-level docs | ✅ PASS | All files have //! doc comments |
| **D-02** Public item docs | ✅ PASS | All pub items have /// docs |
| **D-03** Structured doc sections | ✅ PASS | All pub structs/enums have structured doc sections |
| **D-04** Doc quality | ✅ PASS | No stub docs found |
| **D-05** Validation tool | 🔵 MANUAL | Run: python tools/docs/collect_docs.py --report-missing \| grep src/<module> |
| **D-06** Lua API file docs | ✅ PASS | No Lua API file — skip |
| **D-07** @param/@return annotations | ✅ PASS | No Lua API file — skip |
| **D-08** No rustdoc in lua_api | ✅ PASS | No Lua API file — skip |
| **D-09** Section separators | ✅ PASS | No Lua API file — skip |

### Phase 5 — Lua↔Rust Bridge

| Check | Verdict | Details |
|-------|---------|---------|
| **B-01** Dedicated API file | ✅ PASS | No Lua API — skip |
| **B-02** Registration-only | ✅ PASS | No Lua API — skip |
| **B-03** impl LuaUserData placement | ✅ PASS | No Lua API — skip |
| **B-04** No business logic | ✅ PASS | No Lua API — skip |
| **B-05** Rc clone pattern | ✅ PASS | No Lua API — skip |
| **B-06** Flat registration body | ✅ PASS | No Lua API — skip |

### Phase 6 — Architecture Compliance

| Check | Verdict | Details |
|-------|---------|---------|
| **R-01** Tier placement | ⚠️ WARNING | No **Tier** row in AGENT.md; expected unassigned |
| **R-02** Dependency direction | ✅ PASS | All imports follow unassigned rules |
| **R-03** No lua_api import | ✅ PASS | No lua_api imports found |
| **R-04** Design assumptions | 🔵 MANUAL | Verify against docs/architecture/philosophy.md |
| **R-05** Module overlap | 🔵 MANUAL | Check for scope duplication with other modules |

### Phase 7 — Test Coverage

| Check | Verdict | Details |
|-------|---------|---------|
| **T-01** Rust test file | ❌ ERROR | No test file found for module 'bin' |
| **T-02** Lua test file | ✅ PASS | Module has no Lua API — skip |
| **T-03** Test naming | ✅ PASS | No Rust test file — skip |
| **T-04** Float comparisons | ✅ PASS | No Rust test file — skip |
| **T-05** Test adequacy | ✅ PASS | No pub methods counted — skip |
| **T-06** Golden tests | 🔵 MANUAL | Check if module qualifies for golden/snapshot tests |
| **T-07** Tests pass | 🔵 MANUAL | Run: cargo test --test bin_tests -- --nocapture |

### Phase 8 — Documentation & Wiki

| Check | Verdict | Details |
|-------|---------|---------|
| **W-01** Example file exists | ❌ ERROR | content/examples/bin.lua not found — create it |
| **W-02** API surface coverage | ❌ ERROR | Skipped — no example file |
| **W-03** Example comments | 🔵 MANUAL | Verify content/examples/bin.lua has realistic one-line comments per call |
| **W-04** Example–spec sync | ✅ PASS | No Lua API — skip |
| **W-05** Wiki page | ✅ PASS | Module has no Lua API — skip |
| **W-06** Changelog entry | 🔵 MANUAL | Verify recent API changes have docs/CHANGELOG.md entries |

### Phase 9 — Code Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **Q-01** No println! | ✅ PASS | No println!/eprintln! calls |
| **Q-02** Logger levels | 🔵 MANUAL | Verify log severity levels are appropriate (debug/info/warn/error) |
| **Q-03** No unsafe | ✅ PASS | No undocumented unsafe blocks |
| **Q-04** Error handling | ✅ PASS | No bare .unwrap() calls |
| **Q-07** Log prefix | ✅ PASS | All log calls use log:: prefix |
| **Q-05** Rust best practices | 🔵 MANUAL | Review for anti-patterns: unnecessary clones, redundant allocs |
| **Q-06** Clippy clean | 🔵 MANUAL | Run: cargo clippy --lib -- -D warnings |

### Phase 10 — Performance

| Check | Verdict | Details |
|-------|---------|---------|
| **P-01** Performance doc | 🔵 MANUAL | Check docs/ for this module’s performance notes |
| **P-02** Hot-path allocations | 🔵 MANUAL | Review update/draw/step paths for heap allocations |
| **P-03** Buffer pre-allocation | 🔵 MANUAL | Review Vec/HashMap growth patterns |

### Phase 11 — Integration & Extension

| Check | Verdict | Details |
|-------|---------|---------|
| **I-01** Lua API usability | 🔵 MANUAL | Review lurek.* conventions compliance |
| **I-02** Extension panel | 🔵 MANUAL | Check for structured data I/O for vscode-extension |
| **I-03** Config integration | ✅ PASS | No Lua API — config flag not expected |

### Phase 12 — Localization & Logging

| Check | Verdict | Details |
|-------|---------|---------|
| **L-01** Log externalization | 🔵 MANUAL | Review log string consistency |
| **L-02** TOML message catalog | 🔵 MANUAL | Check for message catalog integration |

---

## Verification

Re-run this report after applying fixes:

```powershell
python tools/audit/audit_module.py bin --docs-quality
```

Fix all ❌ Errors, then address ⚠️ Warnings until status shows **PASS**.

_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._
