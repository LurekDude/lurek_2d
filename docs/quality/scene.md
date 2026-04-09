# Module Quality Report: `scene`

> **Status**: 🔴 FAIL  |  **Date**: 2026-04-09  |  **Score**: 41 ✅ / 5 ⚠️ / 2 ❌ / 19 🔵

---

## Action Items

### 🔴 Errors — Must Fix Before Merge

- [ ] **B-02** — Registration-only: struct definitions (move to src/scene/): LuaDepthSorter
- [ ] **B-03** — impl LuaUserData placement: Move impl LuaUserData for LuaDepthSorter from lua_api/scene_api.rs → src/scene/

### 🟡 Warnings — Should Fix

- [ ] **SP-03** — Summary quality: Summary very long (2499 chars)
- [ ] **D-04** — Doc quality: Stub/placeholder docs found: depth_sorter:11, depth_sorter:26, depth_sorter:49, stack:62, stack:98 (+2 more)
- [ ] **B-04** — No business logic in closures: '<closure@223>' (24 LOC, line 223) — extract body to src/scene/ | '<closure@325>' (21 LOC, line 325) — extract body to src/scene/ | '<closure@304>' has if/match/for — extract to src/scene/ | '<closure@356>' has if/match/for — extract to src/scene/
- [ ] **T-03** — Test naming: test_ prefix found — use <subject>_<scenario>_<expected>: test_transition_type_from_lua_str_all_variants, test_transition_type_from_lua_str_unknown_returns_none, test_active_transition_progress_zero_to_one, test_active_transition_zero_duration_instant, test_active_transition_is_complete (+31 more)
- [ ] **Q-04** — Error handling: .unwrap() calls: stack:118, stack:145, stack:194, stack:403

## Full Check Results

### Phase 1 — Structure & Registration

| Check | Verdict | Details |
|-------|---------|---------|
| **S-01** lib.rs registration | ✅ PASS | Registered in lib.rs + lua_api (scene_api) |
| **S-02** mod.rs simplicity | ✅ PASS | mod.rs is a thin barrel file (0 logic lines) |
| **S-03** File size limits | ✅ PASS | All files within size limits |
| **S-04** File naming | ✅ PASS | File names follow conventions |
| **S-05** Module necessity | 🔵 MANUAL | Requires manual review — could this be pure Lua? |
| **S-06** Large crate deps | 🔵 MANUAL | Requires manual review — check Cargo.toml for heavy crates |

### Phase 2 — AGENT.md Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **A-01** AGENT.md exists | ✅ PASS | src\scene\AGENT.md |
| **A-02** Template structure | ✅ PASS | All sections present |
| **A-03** Purpose quality | ✅ PASS | Purpose section is 521 chars |
| **A-04** Content sync | ✅ PASS | All .rs files listed |
| **A-05** Spec pointer | ✅ PASS | docs/specs/scene.md exists |
| **A-06** Tier label | ✅ PASS | Tier label present (expected: tier2) |
| **A-04b** Source Files completeness (incl. subdirs) | ✅ PASS | All nested .rs files listed in AGENT.md |

### Phase 3 — Technical Specification

| Check | Verdict | Details |
|-------|---------|---------|
| **SP-01** Spec file exists | ✅ PASS | docs/specs/scene.md exists |
| **SP-02** Required spec sections | ✅ PASS | All required sections present |
| **SP-03** Summary quality | ⚠️ WARNING | Summary very long (2499 chars) |
| **SP-04** Lua API completeness | ✅ PASS | All 27 bound functions in spec |
| **SP-05** Key Types accuracy | ✅ PASS | 5 types — spec Key Types in sync |
| **SP-06** Spec quality | ✅ PASS | No stub content |

### Phase 4 — Docstrings

| Check | Verdict | Details |
|-------|---------|---------|
| **D-01** Module-level docs | ✅ PASS | All files have //! doc comments |
| **D-02** Public item docs | ✅ PASS | All pub items have /// docs |
| **D-03** Structured doc sections | ✅ PASS | All pub structs/enums have structured doc sections |
| **D-04** Doc quality | ⚠️ WARNING | Stub/placeholder docs found: depth_sorter:11, depth_sorter:26, depth_sorter:49, stack:62, stack:98 (+2 more) |
| **D-05** Validation tool | 🔵 MANUAL | Run: python tools/docs/collect_docs.py --report-missing \| grep src/<module> |
| **D-06** Lua API file docs | ✅ PASS | //! doc comment present |
| **D-07** @param/@return annotations | ✅ PASS | All bindings have @param/@return annotations |
| **D-08** No rustdoc in lua_api | ✅ PASS | No rustdoc sections in Lua API file |
| **D-09** Section separators | ✅ PASS | Separators present |

### Phase 5 — Lua↔Rust Bridge

| Check | Verdict | Details |
|-------|---------|---------|
| **B-01** Dedicated API file | ✅ PASS | lua_api/scene_api.rs present |
| **B-02** Registration-only | ❌ ERROR | struct definitions (move to src/scene/): LuaDepthSorter |
| **B-03** impl LuaUserData placement | ❌ ERROR | Move impl LuaUserData for LuaDepthSorter from lua_api/scene_api.rs → src/scene/ |
| **B-04** No business logic in closures | ⚠️ WARNING | '<closure@223>' (24 LOC, line 223) — extract body to src/scene/ \| '<closure@325>' (21 LOC, line 325) — extract body to src/scene/ \| '<closure@304>' has if/match/for — extract to src/scene/ \| '<closure@356>' has if/match/for — extract to src/scene/ |
| **B-05** Rc clone pattern | ✅ PASS | Rc clone pattern looks correct |
| **B-06** Flat registration body | ✅ PASS | All tbl.set() calls are flat statements |

### Phase 6 — Architecture Compliance

| Check | Verdict | Details |
|-------|---------|---------|
| **R-01** Tier placement | ✅ PASS | Tier label matches: tier2 |
| **R-02** Dependency direction | ✅ PASS | All imports follow tier2 rules |
| **R-03** No lua_api import | ✅ PASS | No lua_api imports found |
| **R-04** Design assumptions | 🔵 MANUAL | Verify against docs/architecture/philosophy.md |
| **R-05** Module overlap | 🔵 MANUAL | Check for scope duplication with other modules |

### Phase 7 — Test Coverage

| Check | Verdict | Details |
|-------|---------|---------|
| **T-01** Rust test file | ✅ PASS | Found: tests\rust\unit\scene_tests.rs |
| **T-02** Lua test file | ✅ PASS | tests/lua/unit/test_scene.lua registered in harness |
| **T-03** Test naming | ⚠️ WARNING | test_ prefix found — use <subject>_<scenario>_<expected>: test_transition_type_from_lua_str_all_variants, test_transition_type_from_lua_str_unknown_returns_none, test_active_transition_progress_zero_to_one, test_active_transition_zero_duration_instant, test_active_transition_is_complete (+31 more) |
| **T-04** Float comparisons | ✅ PASS | No float assert_eq! found |
| **T-05** Test adequacy | ✅ PASS | 36 tests / 36 pub methods (100%) |
| **T-06** Golden tests | 🔵 MANUAL | Check if module qualifies for golden/snapshot tests |
| **T-07** Tests pass | 🔵 MANUAL | Run: cargo test --test scene_tests -- --nocapture |

### Phase 8 — Documentation & Wiki

| Check | Verdict | Details |
|-------|---------|---------|
| **W-01** Example file exists | ✅ PASS | content/examples/scene.lua present |
| **W-02** API surface coverage | ✅ PASS | All 27 bound functions in example |
| **W-03** Example comments | 🔵 MANUAL | Verify content/examples/scene.lua has realistic one-line comments per call |
| **W-04** Example–spec sync | ✅ PASS | Missing spec or example — other checks cover this |
| **W-05** Wiki page | ✅ PASS | docs\wiki\Scene-API.md |
| **W-06** Changelog entry | 🔵 MANUAL | Verify recent API changes have docs/CHANGELOG.md entries |

### Phase 9 — Code Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **Q-01** No println! | ✅ PASS | No println!/eprintln! calls |
| **Q-02** Logger levels | 🔵 MANUAL | Verify log severity levels are appropriate (debug/info/warn/error) |
| **Q-03** No unsafe | ✅ PASS | No undocumented unsafe blocks |
| **Q-04** Error handling | ⚠️ WARNING | .unwrap() calls: stack:118, stack:145, stack:194, stack:403 |
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
| **I-03** Config integration | ✅ PASS | Module referenced in src/engine/config.rs |

### Phase 12 — Localization & Logging

| Check | Verdict | Details |
|-------|---------|---------|
| **L-01** Log externalization | 🔵 MANUAL | Review log string consistency |
| **L-02** TOML message catalog | 🔵 MANUAL | Check for message catalog integration |

---

## Verification

Re-run this report after applying fixes:

```powershell
python tools/audit/audit_module.py scene --docs-quality
```

Fix all ❌ Errors, then address ⚠️ Warnings until status shows **PASS**.

_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._
