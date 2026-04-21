# Test Infrastructure Roadmap

**Purpose**: Phased implementation plan for the complete test infrastructure overhaul.

## Phase 0 — Foundation (Week 1)

### 0.1 Tooling
- [x] Create `tools/audit/lua_api_test_coverage.py` (marker-aware coverage scanner)
- [x] Verify `gen_lua_api_data.py` → `lua_api_data.json` is up-to-date
- [x] Add `measure()` helper to `tests/lua/init.lua` for stress test standardization
- [x] Add `expect_golden()` helper to `tests/lua/init.lua` for golden comparisons
- [x] Add `expect_canvas_pixel()` helper to `tests/lua/init.lua`

### 0.2 Documentation
- [x] Update `docs/architecture/test-framework.md` with marker system, evidence tiers, golden conventions
- [x] Update `.github/skills/testing-rust/SKILL.md` with new patterns
- [x] Create all `ideas/tests/*.md` design documents (this deliverable)

**Gate**: All 10 design documents created. Coverage scanner runs and produces correct output. ✅ DONE

---

## Phase 1 — Markers and Unit Test Gaps (Weeks 2–3)

### 1.1 Add @covers Markers to Existing Tests
Priority order (lowest coverage first):
1. `test_runtime_system.lua` — add markers for all 22 system functions
2. `test_math.lua` — add markers for Vec2, Mat3, trig, noise functions
3. `test_log.lua` — add markers for all 13 log functions
4. `test_i18n.lua` — add markers for 27 functions
5. `test_physics.lua` — add markers for Body, Joint, World methods
6. `test_filesystem.lua` — add markers for File object methods
7. `test_mods.lua` — add markers for ModManager methods
8. All remaining unit test files — add markers incrementally

### 1.2 Fill Coverage Gaps
Write new tests for functions with 0% marker coverage:
1. `test_runtime_system.lua` — add tests for `getOS`, `getArch`, `getCPUCount`, `getClipboard`, etc.
2. `test_math.lua` — add tests for Vec2/Vec3 methods, Mat3 operations, noise functions
3. `test_log.lua` — add tests for `setLevel`, `setFile`, `trace`, `warn`, `error`
4. `test_network.lua` — add tests for HttpClient methods (mock if needed)

**Gate**: Marker coverage ≥30%. Heuristic+marker coverage ≥85%. All modules have ≥1 @covers marker.

---

## Phase 2 — Error and Edge Case Testing (Week 4)

### 2.1 Error-Path Tests
Add `describe("error handling", ...)` blocks to:
- physics, graphics, entity, tilemap, audio, filesystem, savegame

### 2.2 Nil/Type/Boundary Tests
- Systematic nil argument testing for top-20 modules
- Float boundary values (NaN, inf, -inf)
- Empty collection handling
- Stale object reference testing

**Gate**: Every module with UserData objects has error-path tests. No panic on nil arguments.

---

## Phase 3 — Golden Tests (Weeks 5–6)

### 3.1 Expand Existing
- Expand `test_math_golden.lua` with constants, vec operations, matrix operations

### 3.2 New Golden Tests (Priority Order)
1. `test_data_golden.lua` — JSON/TOML round-trip determinism
2. `test_serial_golden.lua` — binary encoding determinism
3. `test_pathfind_golden_grid.lua` — A* path determinism on fixed grids
4. `test_graph_golden.lua` — BFS/DFS/Dijkstra determinism
5. `test_ai_golden.lua` — FSM transition traces
6. `test_physics_golden.lua` — deterministic simulation (with tolerance)
7. `test_dataframe_golden.lua` — column operation determinism
8. `test_compute_golden.lua` — compute operation results
9. `test_procgen_golden.lua` — seeded generation determinism
10. `test_ecs_golden.lua` — hierarchy operations
11. `test_tilemap_golden.lua` — tile queries

**Gate**: ✅ DONE — 13 golden test files (12 new + animation_golden bonus). All registered in harness.rs.

---

## Phase 4 — Integration Tests (Weeks 7–8)

### 4.1 Fix Misplaced Tests
Move 4 single-module tests from integration/ to unit/:
- test_runtime_system.lua, test_devtools.lua, test_debugbridge.lua, test_docs.lua

### 4.2 New Integration Tests (Priority 1)
1. test_ecs_physics.lua
2. test_ecs_render.lua
3. test_scene_ecs.lua
4. test_scene_camera.lua
5. test_tilemap_camera.lua
6. test_ai_pathfind.lua
7. test_input_camera.lua
8. test_animation_timer.lua

### 4.3 New Integration Tests (Priority 2)
9. test_data_filesystem.lua
10. test_save_tilemap.lua
11. test_event_entity.lua
12. test_tilemap_pathfind.lua
13. test_thread_data.lua

### 4.4 New Integration Tests (Priority 3)
14. test_tween_camera.lua
15. test_tween_ecs.lua
16. test_particle_timer.lua
17. test_light_render.lua
18. test_i18n_ui.lua

**Gate**: ✅ DONE — 43 integration tests total. All registered in harness.rs.

---

## Phase 5 — Stress Tests (Week 9)

### 5.1 New Stress Tests
Add 13 new stress tests (see stress-test-plan.md):
- ai, scene, camera, savegame, timer, signal, animation, serial, tween, image, patterns, filesystem, light

### 5.2 Measurement Framework
- Add `[PERF]` output standard to all stress tests
- Create or update parser script for performance summaries

**Gate**: ✅ DONE — 27 stress tests total. All registered in harness.rs.

---

## Phase 6 — Evidence Testing (Weeks 10–12)

### 6.1 Canvas Pixel Readback (Headless)
Add canvas-based visual evidence tests for:
- Basic shapes: rectangle, circle, line, polygon, arc
- Color operations: setColor, setBackgroundColor
- Canvas: renderTo, getPixel

### 6.2 Runtime Smoke Tests (GPU Required)
Create Rust ext tests in tests/rust/ext/:
- light_smoke_tests.rs — verify light illumination via screenshot
- particle_smoke_tests.rs — verify particle rendering
- postfx_smoke_tests.rs — verify post-processing effects
- audio_smoke_tests.rs — verify audio playback

### 6.3 File Evidence Tests
Add file I/O evidence to:
- filesystem tests (write → read → verify)
- savegame tests (save → load → verify)
- image export tests (save → verify file exists)

**Gate**: Canvas pixel readback tests pass for 5+ drawing functions. At least 2 runtime smoke tests work.

---

## Phase 7 — CI Integration (Week 13)

### 7.1 Pipeline Updates
- Add `lua_api_test_coverage.py --strict --threshold 40` to CI
- Add golden test diff reporting to CI
- Add performance regression detection (compare stress test output)

### 7.2 Quality Gates
- Block merge if marker coverage drops
- Block merge if golden tests fail
- Warn if stress test performance degrades >20%

**Gate**: CI pipeline runs all test categories. Coverage threshold enforced.

---

## Success Metrics

| Metric | Current | Phase 1 | Phase 3 | Phase 7 |
|--------|---------|---------|---------|---------|
| Marker coverage | 0% | ≥30% | ≥50% | ≥70% |
| Heuristic+marker coverage | 80.5% | ≥85% | ≥90% | ≥95% |
| Golden test files | 1 | 1 | 12 | 12 |
| Integration tests | 11 | 11 | 11 | 29+ |
| Stress tests | 12 | 12 | 12 | 25+ |
| Error-path tests | ~5 | ~5 | ~20 | ~45 |
| Evidence tests | 0 | 0 | 5+ | 15+ |
| Runtime smoke tests | 2 | 2 | 2 | 6+ |
