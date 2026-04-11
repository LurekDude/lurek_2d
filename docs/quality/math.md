# Module Quality Report: `math`

> **Status**: 🔴 FAIL  |  **Date**: 2026-04-11  |  **Score**: 45 ✅ / 3 ⚠️ / 0 ❌ / 19 🔵

---

## Action Items

### 🟡 Warnings — Should Fix

- [ ] **A-02** — Template structure: Missing recommended sections: Key Types, Lua API Summary
- [ ] **D-04** — Doc quality: Stub/placeholder docs found: easing:8, easing:79, easing:95, easing:106, geometry:44 (+24 more)
- [ ] **B-04** — No business logic in closures: '<closure@1018>' (17 LOC, line 1018) — extract body to src/math/ | '<closure@1375>' (27 LOC, line 1375) — extract body to src/math/ | '<closure@1593>' (21 LOC, line 1593) — extract body to src/math/ | '<closure@2004>' (21 LOC, line 2004) — extract body to src/math/ | '<closure@955>' has if/match/for — extract to src/math/ | '<closure@1410>' has if/match/for — extract to src/math/

## Full Check Results

### Phase 1 — Structure & Registration

| Check | Verdict | Details |
|-------|---------|---------|
| **S-01** lib.rs registration | ✅ PASS | Registered in lib.rs + lua_api (math_api) |
| **S-02** mod.rs simplicity | ✅ PASS | mod.rs is a thin barrel file (2 logic lines) |
| **S-03** File size limits | ✅ PASS | All files within size limits |
| **S-04** File naming | ✅ PASS | File names follow conventions |
| **S-05** Module necessity | 🔵 MANUAL | Requires manual review — could this be pure Lua? |
| **S-06** Large crate deps | 🔵 MANUAL | Requires manual review — check Cargo.toml for heavy crates |

### Phase 2 — AGENT.md Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **A-01** AGENT.md exists | ✅ PASS | src\math\AGENT.md |
| **A-02** Template structure | ⚠️ WARNING | Missing recommended sections: Key Types, Lua API Summary |
| **A-03** Purpose quality | ✅ PASS | Purpose section is 487 chars |
| **A-04** Content sync | ✅ PASS | All .rs files listed |
| **A-05** Spec pointer | ✅ PASS | docs/specs/math.md exists |
| **A-06** Tier label | ✅ PASS | Tier label present (expected: baseline) |
| **A-04b** Source Files completeness (incl. subdirs) | ✅ PASS | All nested .rs files listed in AGENT.md |

### Phase 3 — Technical Specification

| Check | Verdict | Details |
|-------|---------|---------|
| **SP-01** Spec file exists | ✅ PASS | docs/specs/math.md exists |
| **SP-02** Required spec sections | ✅ PASS | All required sections present |
| **SP-03** Summary quality | ✅ PASS | Summary is 1982 chars |
| **SP-04** Lua API completeness | ✅ PASS | All 82 bound functions in spec |
| **SP-05** Key Types accuracy | ✅ PASS | 16 types — spec Key Types in sync |
| **SP-06** Spec quality | ✅ PASS | No stub content |

### Phase 4 — Docstrings

| Check | Verdict | Details |
|-------|---------|---------|
| **D-01** Module-level docs | ✅ PASS | All files have //! doc comments |
| **D-02** Public item docs | ✅ PASS | All pub items have /// docs |
| **D-03** Structured doc sections | ✅ PASS | All pub structs/enums have structured doc sections |
| **D-04** Doc quality | ⚠️ WARNING | Stub/placeholder docs found: easing:8, easing:79, easing:95, easing:106, geometry:44 (+24 more) |
| **D-05** Validation tool | 🔵 MANUAL | Run: python tools/docs/collect_docs.py --report-missing \| grep src/<module> |
| **D-06** Lua API file docs | ✅ PASS | //! doc comment present |
| **D-07** @param/@return annotations | ✅ PASS | All bindings have @param/@return annotations |
| **D-08** No rustdoc in lua_api | ✅ PASS | No rustdoc sections in Lua API file |
| **D-09** Section separators | ✅ PASS | Separators present |

### Phase 5 — Lua↔Rust Bridge

| Check | Verdict | Details |
|-------|---------|---------|
| **B-01** Dedicated API file | ✅ PASS | lua_api/math_api.rs present |
| **B-02** Registration-only | ✅ PASS | Only register() is pub fn (Lua<X> wrapper structs allowed) |
| **B-03** impl LuaUserData placement | ✅ PASS | All impl LuaUserData blocks are in lua_api (correct) |
| **B-04** No business logic in closures | ⚠️ WARNING | '<closure@1018>' (17 LOC, line 1018) — extract body to src/math/ \| '<closure@1375>' (27 LOC, line 1375) — extract body to src/math/ \| '<closure@1593>' (21 LOC, line 1593) — extract body to src/math/ \| '<closure@2004>' (21 LOC, line 2004) — extract body to src/math/ \| '<closure@955>' has if/match/for — extract to src/math/ \| '<closure@1410>' has if/match/for — extract to src/math/ |
| **B-05** Rc clone pattern | ✅ PASS | Rc clone pattern looks correct |
| **B-06** Flat registration body | ✅ PASS | All tbl.set() calls are flat statements |

### Phase 6 — Architecture Compliance

| Check | Verdict | Details |
|-------|---------|---------|
| **R-01** Tier placement | ✅ PASS | Tier label matches: baseline |
| **R-02** Dependency direction | ✅ PASS | All imports follow baseline rules |
| **R-03** No lua_api import | ✅ PASS | Baseline module — may bootstrap the Lua VM |
| **R-04** Design assumptions | 🔵 MANUAL | Verify against docs/architecture/philosophy.md |
| **R-05** Module overlap | 🔵 MANUAL | Check for scope duplication with other modules |

### Phase 7 — Test Coverage

| Check | Verdict | Details |
|-------|---------|---------|
| **T-01** Rust test file | ✅ PASS | Found: tests\rust\unit\math_tests.rs |
| **T-02** Lua test file | ✅ PASS | tests/lua/unit/test_math.lua registered in harness |
| **T-03** Test naming | ✅ PASS | Test names follow convention |
| **T-04** Float comparisons | ✅ PASS | No float assert_eq! found |
| **T-05** Test adequacy | ✅ PASS | 82 tests / 107 pub methods (77%) |
| **T-06** Golden tests | 🔵 MANUAL | Check if module qualifies for golden/snapshot tests |
| **T-07** Tests pass | 🔵 MANUAL | Run: cargo test --test math_tests -- --nocapture |

### Phase 8 — Documentation & Wiki

| Check | Verdict | Details |
|-------|---------|---------|
| **W-01** Example file exists | ✅ PASS | content/examples/math.lua present |
| **W-02** API surface coverage | ✅ PASS | All 82 bound functions in example |
| **W-03** Example comments | 🔵 MANUAL | Verify content/examples/math.lua has realistic one-line comments per call |
| **W-04** Example–spec sync | ✅ PASS | Missing spec or example — other checks cover this |
| **W-05** Wiki page | ✅ PASS | docs\wiki\Math-API.md |
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
| **I-03** Config integration | ✅ PASS | Baseline module — always enabled, no config flag required |

### Phase 12 — Localization & Logging

| Check | Verdict | Details |
|-------|---------|---------|
| **L-01** Log externalization | 🔵 MANUAL | Review log string consistency |
| **L-02** TOML message catalog | 🔵 MANUAL | Check for message catalog integration |

---

## Verification

Re-run this report after applying fixes:

```powershell
python tools/audit/audit_module.py math --docs-quality
```

Fix all ❌ Errors, then address ⚠️ Warnings until status shows **PASS**.

_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._
