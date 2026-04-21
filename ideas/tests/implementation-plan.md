# Test Infrastructure Implementation Plan

**Purpose**: Task-level checklist for executing the test infrastructure roadmap.

---

## 1. Tooling & Framework Updates

### 1.1 Coverage Scanner (DONE)
- [x] Create `tools/audit/lua_api_test_coverage.py`
- [x] Parse `lua_api_data.json` for API surface
- [x] Implement `-- @covers` marker scanning with regex
- [x] Implement heuristic fallback for unmarked files
- [x] Support `--json`, `--markdown`, `--strict`, `--suggest` modes
- [x] Validate on Windows (cp1250 encoding fix applied)

### 1.2 BDD Framework Extensions
- [x] Add `measure(name, count, fn)` helper to `tests/lua/init.lua`
  - Returns elapsed time and ops/sec
  - Prints `[PERF] name: N ops in Xs (Y ops/sec)`
- [x] Add `expect_golden(name, data)` helper to `tests/lua/init.lua`
  - Formats data deterministically
  - Compares against inline expected string
- [x] Add `expect_canvas_pixel(canvas, x, y, r, g, b, a, tolerance)` helper
  - Wraps `canvas:getPixel()` with `expect_near` comparisons

### 1.3 Test Harness Updates
- [x] For each new test file, add `#[test] fn lua_test_<category>_<name>()` to `tests/lua/harness.rs`
- [x] Verify all existing test entries are correct and match actual .lua files

---

## 2. Marker Annotation Rollout

### 2.1 Unit Tests (Batch 1 — Lowest Coverage)
| File | Functions to annotate | Est. effort |
|------|----------------------|-------------|
| `test_runtime_system.lua` | 22 | Small |
| `test_math.lua` | 66 (Vec2/Vec3/Mat3/trig/noise) | Medium |
| `test_log.lua` | 13 | Small |
| `test_i18n.lua` | 27 | Small |
| `test_physics.lua` | 50 (Body/Joint/World/Shape) | Medium |
| `test_filesystem.lua` | 25 | Small |
| `test_mods.lua` | 22 | Small |
| `test_network.lua` | 20 | Small |

### 2.2 Unit Tests (Batch 2 — Medium Coverage)
| File | Functions to annotate | Est. effort |
|------|----------------------|-------------|
| `test_input.lua` | 30 | Small |
| `test_timer.lua` | 15 | Small |
| `test_window.lua` | 28 | Small |
| `test_scene.lua` | 25 | Small |
| `test_camera.lua` | 25 | Small |
| `test_animation.lua` | 18 | Small |
| `test_event.lua` | 15 | Small |
| `test_image.lua` | 15 | Small |

### 2.3 Unit Tests (Batch 3 — Higher Coverage)
All remaining unit test files — add markers to verify 100% marker coverage for covered functions.

---

## 3. New Test Files to Create

### 3.1 Golden Tests ✅ DONE — all 13 golden files created
| File | Target module(s) | Expected content | Status |
|------|-----------------|-----------------|--------|
| `tests/lua/golden/test_data_golden.lua` | data | JSON/TOML parse → format roundtrip | ✅ done |
| `tests/lua/golden/test_serial_golden.lua` | serial | Binary encode/decode exact bytes | ✅ done |
| `tests/lua/golden/test_pathfind_golden_grid.lua` | pathfinding | A* on fixed grid → exact path | ✅ done |
| `tests/lua/golden/test_graph_golden.lua` | graph | BFS/DFS/Dijkstra → exact traversal | ✅ done |
| `tests/lua/golden/test_ai_golden.lua` | ai | FSM transition trace | ✅ done |
| `tests/lua/golden/test_physics_golden.lua` | physics | Simulation with fixed dt → near positions | ✅ done |
| `tests/lua/golden/test_compute_golden.lua` | compute | Matrix ops → exact results | ✅ done |
| `tests/lua/golden/test_procgen_golden.lua` | procgen | Seeded generation → exact output | ✅ done |
| `tests/lua/golden/test_ecs_golden.lua` | entity | Hierarchy → exact JSON tree | ✅ done |
| `tests/lua/golden/test_tilemap_golden.lua` | tilemap | Tile queries → exact results | ✅ done |
| `tests/lua/golden/test_dataframe_golden.lua` | dataframe | Column operations → exact results | ✅ done |
| `tests/lua/golden/test_animation_golden.lua` | animation | Frame sequence deterministic | ✅ done (bonus) |
| `tests/lua/golden/test_math_golden.lua` | math | Constants, trig, Vec2, Mat3 | ✅ done (was pre-existing) |

### 3.2 Integration Tests ✅ DONE — all 18 planned files created (43 total)
| File | Modules tested | Scenarios | Status |
|------|---------------|-----------|
| `test_ecs_physics.lua` | entity + physics | Bodies parented to entities, physics-driven movement |
| `test_ecs_render.lua` | entity + graphics | Entity render, sprite attachment, visibility |
| `test_scene_ecs.lua` | scene + entity | Scene add/remove entities, scene transitions |
| `test_scene_camera.lua` | scene + camera | Camera follows scene entities, scene viewport |
| `test_tilemap_camera.lua` | tilemap + camera | Camera scrolls tilemap, tile culling |
| `test_ai_pathfind.lua` | ai + pathfinding | AI agent follows computed path |
| `test_input_camera.lua` | input + camera | Screen-to-world coordinate transform |
| `test_animation_timer.lua` | animation + timer | Timer-driven animation playback |
| `test_data_filesystem.lua` | data + filesystem | Save JSON to file, load it back |
| `test_save_tilemap.lua` | savegame + tilemap | Save map state, restore it |
| `test_event_entity.lua` | signal + entity | Entities emit/receive signals |
| `test_tilemap_pathfind.lua` | tilemap + pathfinding | Grid from tilemap, pathfind on it |
| `test_thread_data.lua` | thread + data | Cross-thread data via Channel |
| `test_tween_camera.lua` | tween + camera | Smooth camera pan/zoom |
| `test_tween_ecs.lua` | tween + entity | Tweened entity position/rotation |
| `test_particle_timer.lua` | particle + timer | Timed particle bursts |
| `test_light_render.lua` | light + graphics | Lights affect draw colors (Canvas readback) |
| `test_i18n_ui.lua` | localization + ui | Localized text in UI elements |

### 3.3 Stress Tests ✅ DONE — all 13 planned + 2 bonus files created (27 total)
| File | Target | Metric | Status |
|------|--------|--------|--------|
| `test_ai_stress.lua` | AI FSM/BT evaluate | 10k evals/sec | ✅ done |
| `test_scene_stress.lua` | Scene add/remove | 1k scenes/sec | ✅ done |
| `test_camera_stress.lua` | Camera update | 50k updates/sec | ✅ done |
| `test_save_stress.lua` | Save/Load cycle | 100 cycles/sec | ✅ done |
| `test_timer_stress.lua` | Timer create/fire | 10k timers/sec | ✅ done |
| `test_event_stress.lua` | Signal emit | 50k emits/sec | ✅ done |
| `test_animation_stress.lua` | Animation update | 10k updates/sec | ✅ done |
| `test_serial_stress.lua` | Serialize/deserialize | 5k cycles/sec | ✅ done |
| `test_tween_stress.lua` | Active tweens | 10k tweens/sec | ✅ done |
| `test_image_stress.lua` | Image create | 1k creates/sec | ✅ done |
| `test_patterns_stress.lua` | Pattern evaluate | 50k evals/sec | ✅ done |
| `test_filesystem_stress.lua` | File write/read | 1k ops/sec | ✅ done |
| `test_light_stress.lua` | Light add/remove | 5k ops/sec | ✅ done |
| `test_render_stress.lua` | Draw call throughput | Various | ✅ done (bonus) |
| `test_thread_stress.lua` | Thread channel throughput | Various | ✅ done (bonus) |

---

## 4. Harness Registration

For every new `.lua` test file, add a corresponding entry in `tests/lua/harness.rs`:

```rust
// Golden tests
#[test] fn lua_test_golden_data() { run_lua_test("golden/test_data_golden.lua"); }
#[test] fn lua_test_golden_serial() { run_lua_test("golden/test_serial_golden.lua"); }
// ... etc

// Integration tests
#[test] fn lua_test_integration_entity_physics() { run_lua_test("integration/test_ecs_physics.lua"); }
// ... etc

// Stress tests
#[test] fn lua_test_stress_ai() { run_lua_test("stress/test_stress_ai.lua"); }
// ... etc
```

---

## 5. Documentation Updates

### 5.1 Architecture Doc ✅ DONE
- [x] Update `docs/architecture/test-framework.md`:
  - [x] Add/verify "Marker Annotations" section with `@covers` syntax
  - [x] Add/verify "Evidence Testing" section with 3 tiers
  - [x] Add Lua Golden Tests sub-section under `## Golden Tests`
  - [x] Fix "Coverage Tooling" section with correct tool paths
  - [x] Update Framework API table with `measure()`, `expect_golden()`, `expect_canvas_pixel()`
  - [x] Update "Measurement Helper" from planned to implemented
  - [x] Update integration test count (43 actual, not 29)
  - [x] Update Table of Contents

### 5.2 CAG Skill ✅ DONE
- [x] Update `.github/skills/testing-rust/SKILL.md`:
  - [x] Expand assertions table with `expect_greater`, `expect_less`, `expect_in_range`, `expect_contains`, `expect_match`, `expect_length`, `expect_deep_equal`
  - [x] Add "Performance and Golden helpers" subsection with `measure()`, `expect_golden()`, `expect_canvas_pixel()` examples
  - [x] Expand "Golden Tests" section with Lua golden test pattern using `expect_golden()`
  - [x] Add "Marker Annotations" section (section 9) with `@covers` syntax, placement rules, describe-block naming
  - [x] Add "Evidence-Based Testing" section (section 10) with all 3 tiers and code examples
  - [x] Add evidence tags table (`@evidence pixel`, `@evidence file`, `@stress`, `@golden`)

### 5.3 Cross-Artifact Sync
- [ ] Verify `docs/specs/*.md` test sections match new patterns
- [ ] Update `tests/README.md` with new test categories

**Note**: Sections 5.1 and 5.2 are now complete. Only the lower-priority sync tasks (5.3) remain.

---

## 6. Execution Order

```
Phase 0: Foundation (this document + tooling) ← WE ARE HERE
    ↓
Phase 1: Markers + Unit Coverage (weeks 2-3)
    ↓
Phase 2: Error/Edge Case Tests (week 4)
    ↓
Phase 3: Golden Tests (weeks 5-6)  ← can parallel with Phase 4
    ↓                                    ↓
Phase 4: Integration Tests (weeks 7-8)  ↓
    ↓────────────────────────────────────↓
Phase 5: Stress Tests (week 9)
    ↓
Phase 6: Evidence Testing (weeks 10-12) ← requires Canvas API investigation
    ↓
Phase 7: CI Integration (week 13)
```

**Parallelization**: Phases 3 and 4 can run in parallel. Phase 5 is independent of Phase 6.

---

## 7. Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Canvas:getPixel() unavailable in headless | High | Fall back to RenderCommand queue inspection |
| LuaJIT string.format differs from Lua 5.4 | Medium | Use fixed-precision formatting in golden tests |
| False-positive heuristic matches mask real gaps | Medium | Prioritize marker rollout over heuristic improvements |
| Integration tests cross module boundaries wrong | Low | Each test imports exactly 2+ `lurek.*` namespaces |
| Stress test timing unstable in CI | Medium | Use ops/sec ratios not absolute times; wide thresholds |
