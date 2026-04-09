# Module Quality Report: `graphics`

> **Status**: 🔴 FAIL  |  **Date**: 2026-04-09  |  **Score**: 31 ✅ / 9 ⚠️ / 8 ❌ / 19 🔵

---

## Action Items

### 🔴 Errors — Must Fix Before Merge

- [ ] **S-03** — File size limits: Files >2000 LOC: graphics/gpu_renderer.rs (4172 LOC)
- [ ] **D-01** — Module-level docs: Missing //! doc in: graphics/color.rs
- [ ] **D-08** — No rustdoc in lua_api: Rustdoc sections found (use @param/@return): # Parameters, # Returns, # Fields
- [ ] **B-02** — Registration-only: struct definitions (move to src/graphics/): LuaImageData, LuaImage, LuaNineSlice, LuaFont, LuaCanvas, LuaSpriteBatch, LuaMesh, LuaShader, LuaQuad, LuaShape
- [ ] **B-03** — impl LuaUserData placement: Move impl LuaUserData for LuaImageData, LuaNineSlice, LuaImage, LuaFont, LuaCanvas, LuaSpriteBatch, LuaMesh, LuaShader, LuaQuad, LuaShape, LuaDrawLayer from lua_api/graphics_api.rs → src/graphics/
- [ ] **B-06** — Flat registration body: tbl.set() inside {} block (anti-pattern): line 171, line 2152
- [ ] **R-02** — Dependency direction: canvas: Tier1 imports log_msg(unassigned); font: Tier1 imports log_msg(unassigned); gpu_renderer: Tier1 imports log_msg(unassigned); mesh: Tier1 imports log_msg(unassigned); shader: Tier1 imports log_msg(unassigned)
- [ ] **T-04** — Float comparisons: assert_eq! with float literals (use abs()<epsilon): line 43, line 313, line 509, line 525, line 880

### 🟡 Warnings — Should Fix

- [ ] **A-02** — Template structure: Missing recommended sections: Key Types, Lua API Summary
- [ ] **A-04b** — Source Files completeness (incl. subdirs): Nested .rs files not listed in AGENT.md: mod.rs
- [ ] **SP-03** — Summary quality: Summary very long (2471 chars)
- [ ] **SP-05** — Key Types accuracy: Types not in spec: AtlasRegion, BatchEntry, BlendMode, Canvas, Color | Stale in spec: Enums, Structs, Type, graphics
- [ ] **D-03** — Structured doc sections: Missing structured sections: renderer::DrawCommand (# Variants)
- [ ] **D-04** — Doc quality: Stub/placeholder docs found: draw_layer:14, draw_layer:26, draw_layer:53, mesh:18, mesh:34 (+5 more)
- [ ] **B-04** — No business logic in closures: '<closure@1437>' (23 LOC, line 1437) — extract body to src/graphics/ | '<closure@1469>' (25 LOC, line 1469) — extract body to src/graphics/ | '<closure@1540>' (31 LOC, line 1540) — extract body to src/graphics/ | '<closure@1589>' (119 LOC, line 1589) — extract body to src/graphics/ | '<closure@1933>' has if/match/for — extract to src/graphics/ | '<closure@1954>' has if/match/for — extract to src/graphics/
- [ ] **T-03** — Test naming: test_ prefix found — use <subject>_<scenario>_<expected>: test_phase01_released_texture_handle_reuse_reports_invalid_texture, test_phase01_released_numeric_texture_handle_reports_invalid_texture, test_phase01_released_font_handle_reuse_reports_invalid_font, test_phase01_released_sprite_batch_handle_reuse_reports_invalid_batch, test_transform_push_queues_push_transform (+71 more)
- [ ] **Q-04** — Error handling: .unwrap() calls: gpu_renderer:964, gpu_renderer:974, gpu_renderer:979, gpu_renderer:984, gpu_renderer:989 (+40 more)

## Full Check Results

### Phase 1 — Structure & Registration

| Check | Verdict | Details |
|-------|---------|---------|
| **S-01** lib.rs registration | ✅ PASS | Registered in lib.rs + lua_api (graphics_api) |
| **S-02** mod.rs simplicity | ✅ PASS | mod.rs is a thin barrel file (3 logic lines) |
| **S-03** File size limits | ❌ ERROR | Files >2000 LOC: graphics/gpu_renderer.rs (4172 LOC) |
| **S-04** File naming | ✅ PASS | File names follow conventions |
| **S-05** Module necessity | 🔵 MANUAL | Requires manual review — could this be pure Lua? |
| **S-06** Large crate deps | 🔵 MANUAL | Requires manual review — check Cargo.toml for heavy crates |

### Phase 2 — AGENT.md Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **A-01** AGENT.md exists | ✅ PASS | src\graphics\AGENT.md |
| **A-02** Template structure | ⚠️ WARNING | Missing recommended sections: Key Types, Lua API Summary |
| **A-03** Purpose quality | ✅ PASS | Purpose section is 385 chars |
| **A-04** Content sync | ✅ PASS | All .rs files listed |
| **A-05** Spec pointer | ✅ PASS | specs/graphics.md exists |
| **A-06** Tier label | ✅ PASS | Tier label present (expected: tier1) |
| **A-04b** Source Files completeness (incl. subdirs) | ⚠️ WARNING | Nested .rs files not listed in AGENT.md: mod.rs |

### Phase 3 — Technical Specification

| Check | Verdict | Details |
|-------|---------|---------|
| **SP-01** Spec file exists | ✅ PASS | specs/graphics.md exists |
| **SP-02** Required spec sections | ✅ PASS | All required sections present |
| **SP-03** Summary quality | ⚠️ WARNING | Summary very long (2471 chars) |
| **SP-04** Lua API completeness | ✅ PASS | No tbl.set() bindings found |
| **SP-05** Key Types accuracy | ⚠️ WARNING | Types not in spec: AtlasRegion, BatchEntry, BlendMode, Canvas, Color \| Stale in spec: Enums, Structs, Type, graphics |
| **SP-06** Spec quality | ✅ PASS | No stub content |

### Phase 4 — Docstrings

| Check | Verdict | Details |
|-------|---------|---------|
| **D-01** Module-level docs | ❌ ERROR | Missing //! doc in: graphics/color.rs |
| **D-02** Public item docs | ✅ PASS | All pub items have /// docs |
| **D-03** Structured doc sections | ⚠️ WARNING | Missing structured sections: renderer::DrawCommand (# Variants) |
| **D-04** Doc quality | ⚠️ WARNING | Stub/placeholder docs found: draw_layer:14, draw_layer:26, draw_layer:53, mesh:18, mesh:34 (+5 more) |
| **D-05** Validation tool | 🔵 MANUAL | Run: python tools/docs/collect_docs.py --report-missing \| grep src/<module> |
| **D-06** Lua API file docs | ✅ PASS | //! doc comment present |
| **D-07** @param/@return annotations | ✅ PASS | All bindings have @param/@return annotations |
| **D-08** No rustdoc in lua_api | ❌ ERROR | Rustdoc sections found (use @param/@return): # Parameters, # Returns, # Fields |
| **D-09** Section separators | ✅ PASS | Separators present |

### Phase 5 — Lua↔Rust Bridge

| Check | Verdict | Details |
|-------|---------|---------|
| **B-01** Dedicated API file | ✅ PASS | lua_api/graphics_api.rs present |
| **B-02** Registration-only | ❌ ERROR | struct definitions (move to src/graphics/): LuaImageData, LuaImage, LuaNineSlice, LuaFont, LuaCanvas, LuaSpriteBatch, LuaMesh, LuaShader, LuaQuad, LuaShape |
| **B-03** impl LuaUserData placement | ❌ ERROR | Move impl LuaUserData for LuaImageData, LuaNineSlice, LuaImage, LuaFont, LuaCanvas, LuaSpriteBatch, LuaMesh, LuaShader, LuaQuad, LuaShape, LuaDrawLayer from lua_api/graphics_api.rs → src/graphics/ |
| **B-04** No business logic in closures | ⚠️ WARNING | '<closure@1437>' (23 LOC, line 1437) — extract body to src/graphics/ \| '<closure@1469>' (25 LOC, line 1469) — extract body to src/graphics/ \| '<closure@1540>' (31 LOC, line 1540) — extract body to src/graphics/ \| '<closure@1589>' (119 LOC, line 1589) — extract body to src/graphics/ \| '<closure@1933>' has if/match/for — extract to src/graphics/ \| '<closure@1954>' has if/match/for — extract to src/graphics/ |
| **B-05** Rc clone pattern | ✅ PASS | Rc clone pattern looks correct |
| **B-06** Flat registration body | ❌ ERROR | tbl.set() inside {} block (anti-pattern): line 171, line 2152 |

### Phase 6 — Architecture Compliance

| Check | Verdict | Details |
|-------|---------|---------|
| **R-01** Tier placement | ✅ PASS | Tier label matches: tier1 |
| **R-02** Dependency direction | ❌ ERROR | canvas: Tier1 imports log_msg(unassigned); font: Tier1 imports log_msg(unassigned); gpu_renderer: Tier1 imports log_msg(unassigned); mesh: Tier1 imports log_msg(unassigned); shader: Tier1 imports log_msg(unassigned) |
| **R-03** No lua_api import | ✅ PASS | No lua_api imports found |
| **R-04** Design assumptions | 🔵 MANUAL | Verify against docs/architecture/philosophy.md |
| **R-05** Module overlap | 🔵 MANUAL | Check for scope duplication with other modules |

### Phase 7 — Test Coverage

| Check | Verdict | Details |
|-------|---------|---------|
| **T-01** Rust test file | ✅ PASS | Found: tests\rust\unit\graphics_tests.rs |
| **T-02** Lua test file | ✅ PASS | tests/lua/unit/test_graphics.lua registered in harness |
| **T-03** Test naming | ⚠️ WARNING | test_ prefix found — use <subject>_<scenario>_<expected>: test_phase01_released_texture_handle_reuse_reports_invalid_texture, test_phase01_released_numeric_texture_handle_reports_invalid_texture, test_phase01_released_font_handle_reuse_reports_invalid_font, test_phase01_released_sprite_batch_handle_reuse_reports_invalid_batch, test_transform_push_queues_push_transform (+71 more) |
| **T-04** Float comparisons | ❌ ERROR | assert_eq! with float literals (use abs()<epsilon): line 43, line 313, line 509, line 525, line 880 |
| **T-05** Test adequacy | ✅ PASS | 112 tests / 86 pub methods (130%) |
| **T-06** Golden tests | 🔵 MANUAL | Check if module qualifies for golden/snapshot tests |
| **T-07** Tests pass | 🔵 MANUAL | Run: cargo test --test graphics_tests -- --nocapture |

### Phase 8 — Documentation & Wiki

| Check | Verdict | Details |
|-------|---------|---------|
| **W-01** Example file exists | ✅ PASS | examples/graphics.lua present |
| **W-02** API surface coverage | ✅ PASS | All 0 bound functions in example |
| **W-03** Example comments | 🔵 MANUAL | Verify examples/graphics.lua has realistic one-line comments per call |
| **W-04** Example–spec sync | ✅ PASS | No bound functions |
| **W-05** Wiki page | ✅ PASS | wiki\Graphics-API.md |
| **W-06** Changelog entry | 🔵 MANUAL | Verify recent API changes have docs/CHANGELOG.md entries |

### Phase 9 — Code Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **Q-01** No println! | ✅ PASS | No println!/eprintln! calls |
| **Q-02** Logger levels | 🔵 MANUAL | Verify log severity levels are appropriate (debug/info/warn/error) |
| **Q-03** No unsafe | ✅ PASS | No undocumented unsafe blocks |
| **Q-04** Error handling | ⚠️ WARNING | .unwrap() calls: gpu_renderer:964, gpu_renderer:974, gpu_renderer:979, gpu_renderer:984, gpu_renderer:989 (+40 more) |
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
| **I-01** Lua API usability | 🔵 MANUAL | Review luna.* conventions compliance |
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
python tools/audit/audit_module.py graphics --docs-quality
```

Fix all ❌ Errors, then address ⚠️ Warnings until status shows **PASS**.

_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._
