# Module Quality Report: `tilemap`

> **Status**: 🔴 FAIL  |  **Date**: 2026-04-09  |  **Score**: 36 ✅ / 7 ⚠️ / 5 ❌ / 19 🔵

---

## Action Items

### 🔴 Errors — Must Fix Before Merge

- [ ] **SP-04** — Lua API completeness: Missing from spec: FLOOR, NORTH_WALL, WEST_WALL, OBJECT, newMapScript (+2 more) — add to ## Lua API in docs/specs/tilemap.md
- [ ] **B-02** — Registration-only: struct definitions (move to src/tilemap/): LuaTileSet, LuaTileMap, LuaAutoTileSheet, LuaChunkMap, LuaIsoMap, LuaMapBlock, LuaMapGroup, LuaMapScript, LuaMapGen
- [ ] **B-03** — impl LuaUserData placement: Move impl LuaUserData for LuaTileSet, LuaTileMap, LuaAutoTileSheet, LuaChunkMap, LuaIsoMap, LuaMapBlock, LuaMapGroup, LuaMapScript, LuaMapGen from lua_api/tilemap_api.rs → src/tilemap/
- [ ] **B-06** — Flat registration body: tbl.set() inside {} block (anti-pattern): line 30, line 845, line 1680
- [ ] **T-04** — Float comparisons: assert_eq! with float literals (use abs()<epsilon): line 1384, line 1385, line 1387, line 1455, line 1456

### 🟡 Warnings — Should Fix

- [ ] **S-03** — File size limits: Files >1500 LOC: tilemap/mapgen.rs (1570 LOC)
- [ ] **SP-05** — Key Types accuracy: Types not in spec: AutoTileLayout, AutoTileSheet, ChunkMap, Edge, Facing | Stale in spec: Standalone
- [ ] **D-03** — Structured doc sections: Missing structured sections: autotile_sheet::AutoTileSheet (# Fields), isomap::IsoMap (# Fields), mapgen::ScriptStep (# Fields)
- [ ] **D-04** — Doc quality: Stub/placeholder docs found: isomap:51, large_map_renderer:213, mapgen:795, polygon_map:18, polygon_map:289 (+10 more)
- [ ] **D-07** — @param/@return annotations: Missing @param/@return before: width, height
- [ ] **B-04** — No business logic in closures: '<closure@1519>' (17 LOC, line 1519) — extract body to src/tilemap/ | '<closure@1898>' (112 LOC, line 1898) — extract body to src/tilemap/ | '<closure@2018>' (36 LOC, line 2018) — extract body to src/tilemap/ | '<closure@1680>' has if/match/for — extract to src/tilemap/ | '<closure@1729>' has if/match/for — extract to src/tilemap/
- [ ] **Q-04** — Error handling: .unwrap() calls: chunk:398, mapgen:1324, mapgen:1377, mapgen:1378, mapgen:1382 (+16 more)

## Full Check Results

### Phase 1 — Structure & Registration

| Check | Verdict | Details |
|-------|---------|---------|
| **S-01** lib.rs registration | ✅ PASS | Registered in lib.rs + lua_api (tilemap_api) |
| **S-02** mod.rs simplicity | ✅ PASS | mod.rs is a thin barrel file (6 logic lines) |
| **S-03** File size limits | ⚠️ WARNING | Files >1500 LOC: tilemap/mapgen.rs (1570 LOC) |
| **S-04** File naming | ✅ PASS | File names follow conventions |
| **S-05** Module necessity | 🔵 MANUAL | Requires manual review — could this be pure Lua? |
| **S-06** Large crate deps | 🔵 MANUAL | Requires manual review — check Cargo.toml for heavy crates |

### Phase 2 — AGENT.md Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **A-01** AGENT.md exists | ✅ PASS | src\tilemap\AGENT.md |
| **A-02** Template structure | ✅ PASS | All sections present |
| **A-03** Purpose quality | ✅ PASS | Purpose section is 1252 chars |
| **A-04** Content sync | ✅ PASS | All .rs files listed |
| **A-05** Spec pointer | ✅ PASS | docs/specs/tilemap.md exists |
| **A-06** Tier label | ✅ PASS | Tier label present (expected: tier2) |
| **A-04b** Source Files completeness (incl. subdirs) | ✅ PASS | All nested .rs files listed in AGENT.md |

### Phase 3 — Technical Specification

| Check | Verdict | Details |
|-------|---------|---------|
| **SP-01** Spec file exists | ✅ PASS | docs/specs/tilemap.md exists |
| **SP-02** Required spec sections | ✅ PASS | All required sections present |
| **SP-03** Summary quality | ✅ PASS | Summary is 1257 chars |
| **SP-04** Lua API completeness | ❌ ERROR | Missing from spec: FLOOR, NORTH_WALL, WEST_WALL, OBJECT, newMapScript (+2 more) — add to ## Lua API in docs/specs/tilemap.md |
| **SP-05** Key Types accuracy | ⚠️ WARNING | Types not in spec: AutoTileLayout, AutoTileSheet, ChunkMap, Edge, Facing \| Stale in spec: Standalone |
| **SP-06** Spec quality | ✅ PASS | No stub content |

### Phase 4 — Docstrings

| Check | Verdict | Details |
|-------|---------|---------|
| **D-01** Module-level docs | ✅ PASS | All files have //! doc comments |
| **D-02** Public item docs | ✅ PASS | All pub items have /// docs |
| **D-03** Structured doc sections | ⚠️ WARNING | Missing structured sections: autotile_sheet::AutoTileSheet (# Fields), isomap::IsoMap (# Fields), mapgen::ScriptStep (# Fields) |
| **D-04** Doc quality | ⚠️ WARNING | Stub/placeholder docs found: isomap:51, large_map_renderer:213, mapgen:795, polygon_map:18, polygon_map:289 (+10 more) |
| **D-05** Validation tool | 🔵 MANUAL | Run: python tools/docs/collect_docs.py --report-missing \| grep src/<module> |
| **D-06** Lua API file docs | ✅ PASS | //! doc comment present |
| **D-07** @param/@return annotations | ⚠️ WARNING | Missing @param/@return before: width, height |
| **D-08** No rustdoc in lua_api | ✅ PASS | No rustdoc sections in Lua API file |
| **D-09** Section separators | ✅ PASS | Separators present |

### Phase 5 — Lua↔Rust Bridge

| Check | Verdict | Details |
|-------|---------|---------|
| **B-01** Dedicated API file | ✅ PASS | lua_api/tilemap_api.rs present |
| **B-02** Registration-only | ❌ ERROR | struct definitions (move to src/tilemap/): LuaTileSet, LuaTileMap, LuaAutoTileSheet, LuaChunkMap, LuaIsoMap, LuaMapBlock, LuaMapGroup, LuaMapScript, LuaMapGen |
| **B-03** impl LuaUserData placement | ❌ ERROR | Move impl LuaUserData for LuaTileSet, LuaTileMap, LuaAutoTileSheet, LuaChunkMap, LuaIsoMap, LuaMapBlock, LuaMapGroup, LuaMapScript, LuaMapGen from lua_api/tilemap_api.rs → src/tilemap/ |
| **B-04** No business logic in closures | ⚠️ WARNING | '<closure@1519>' (17 LOC, line 1519) — extract body to src/tilemap/ \| '<closure@1898>' (112 LOC, line 1898) — extract body to src/tilemap/ \| '<closure@2018>' (36 LOC, line 2018) — extract body to src/tilemap/ \| '<closure@1680>' has if/match/for — extract to src/tilemap/ \| '<closure@1729>' has if/match/for — extract to src/tilemap/ |
| **B-05** Rc clone pattern | ✅ PASS | Rc clone pattern looks correct |
| **B-06** Flat registration body | ❌ ERROR | tbl.set() inside {} block (anti-pattern): line 30, line 845, line 1680 |

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
| **T-01** Rust test file | ✅ PASS | Found: tests\rust\unit\tilemap_tests.rs |
| **T-02** Lua test file | ✅ PASS | tests/lua/unit/test_tilemap.lua registered in harness |
| **T-03** Test naming | ✅ PASS | Test names follow convention |
| **T-04** Float comparisons | ❌ ERROR | assert_eq! with float literals (use abs()<epsilon): line 1384, line 1385, line 1387, line 1455, line 1456 |
| **T-05** Test adequacy | ✅ PASS | 159 tests / 228 pub methods (70%) |
| **T-06** Golden tests | 🔵 MANUAL | Check if module qualifies for golden/snapshot tests |
| **T-07** Tests pass | 🔵 MANUAL | Run: cargo test --test tilemap_tests -- --nocapture |

### Phase 8 — Documentation & Wiki

| Check | Verdict | Details |
|-------|---------|---------|
| **W-01** Example file exists | ✅ PASS | content/examples/tilemap.lua present |
| **W-02** API surface coverage | ✅ PASS | All 34 bound functions in example |
| **W-03** Example comments | 🔵 MANUAL | Verify content/examples/tilemap.lua has realistic one-line comments per call |
| **W-04** Example–spec sync | ✅ PASS | Missing spec or example — other checks cover this |
| **W-05** Wiki page | ✅ PASS | docs\wiki\Tilemap-API.md |
| **W-06** Changelog entry | 🔵 MANUAL | Verify recent API changes have docs/CHANGELOG.md entries |

### Phase 9 — Code Quality

| Check | Verdict | Details |
|-------|---------|---------|
| **Q-01** No println! | ✅ PASS | No println!/eprintln! calls |
| **Q-02** Logger levels | 🔵 MANUAL | Verify log severity levels are appropriate (debug/info/warn/error) |
| **Q-03** No unsafe | ✅ PASS | No undocumented unsafe blocks |
| **Q-04** Error handling | ⚠️ WARNING | .unwrap() calls: chunk:398, mapgen:1324, mapgen:1377, mapgen:1378, mapgen:1382 (+16 more) |
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
python tools/audit/audit_module.py tilemap --docs-quality
```

Fix all ❌ Errors, then address ⚠️ Warnings until status shows **PASS**.

_Auto-generated by `tools/audit/audit_module.py`. Do not edit manually._
