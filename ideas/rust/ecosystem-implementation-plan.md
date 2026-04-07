# Luna2D Ecosystem Implementation Plan

> **Purpose**: Detailed, task-level implementation plan for all ecosystem changes described in `docs/ecosystem-recommendations.md` (v2, 2026-03-31).
> Each task has: scope, affected files, acceptance criteria, estimated SLoC, dependencies, and priority.

---

## Overview

This plan covers **30 implementation tasks** organized into **6 phases**. Phases are sequenced by dependency: Phase 1 (removals + safe bumps) must complete before Phase 2 (major migrations), etc.

**Total estimated effort**: ~4,000-5,500 new/modified SLoC across all phases.

---

## Phase 1 � Cleanup & Safe Bumps

Remove dead dependencies and apply non-breaking version bumps. No API changes. Low risk.

### Task 1.1 � Remove tiny-skia and minifb ? DONE

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | LOW |
| **Affected files** | `Cargo.toml`, `src/graphics/renderer.rs`, `src/graphics/mod.rs`, any file importing `tiny_skia` or `minifb` |
| **SLoC change** | -200 to -500 (removal) |
| **Dependencies** | None |
| **Agent** | Developer |
| **Status** | **COMPLETE** � renderer.rs stripped to type definitions only (1542�365 lines), archived to `references/legacy/renderer.rs`, minifb_key_to_string removed from keyboard.rs, all docs updated. |

**Steps**:
1. Remove `tiny-skia = "0.11"` and `minifb = "0.27"` from `Cargo.toml` `[dependencies]`.
2. Search all `src/` files for `use tiny_skia` and `use minifb` � remove imports and any code that references them.
3. Archive or delete `src/graphics/renderer.rs` (the legacy CPU renderer). If it contains reference code worth keeping, move to `references/legacy/renderer.rs`.
4. Run `cargo build` � verify clean compilation with zero errors.
5. Run `cargo test` � verify no tests depended on the removed crates.
6. Run `cargo clippy -- -D warnings` � verify no warnings.

**Acceptance gate**: `cargo build && cargo test && cargo clippy -- -D warnings` passes. No `tiny_skia` or `minifb` references remain in `src/`.

---

### Task 1.2 � Safe version bumps (non-breaking)

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `Cargo.toml` only |
| **SLoC change** | 0 (version strings only) |
| **Dependencies** | Task 1.1 |
| **Agent** | Developer |

**Steps**:
1. Update these versions in `Cargo.toml` (semver-compatible, no code changes needed):
   - `lz4_flex`: `"0.11"` � `"0.13"`
   - `rfd`: `"0.14"` � `"0.17"`
   - `pollster`: `"0.3"` � `"0.4"`
   - `arboard`: `"3"` � `"3.6"`
   - `fastrand`: `"2"` � `"2.3"`
   - `slotmap`: `"1"` � `"1.1"`
2. Run `cargo update` to fetch new versions.
3. Run `cargo build && cargo test && cargo clippy -- -D warnings`.

**Acceptance gate**: All crates resolve to new versions. Build, tests, and clippy pass.

---

### Task 1.3 � Add `toml` crate ? DONE

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `Cargo.toml`, `src/lua_api/data_api.rs` (or new `src/lua_api/serialization_api.rs`) |
| **SLoC change** | +50-80 (Lua bindings for TOML encode/decode) |
| **Dependencies** | None |
| **Agent** | Developer |
| **Status** | **COMPLETE** � canonical `luna.data.parseToml()` / `luna.data.encodeToml()` shipped with targeted Rust and Lua coverage, prefixed Lua-facing errors, and synchronized docs. |

**Steps**:
1. Add `toml = "0.8"` to `Cargo.toml` `[dependencies]`.
2. Implement `luna.data.encodeToml(table) � string` and `luna.data.parseToml(string) � table` in the Lua API.
3. Reuse the existing `serde` + Lua table - serde_json::Value conversion pattern.
4. Write integration tests in `tests/data_tests.rs`.
5. Run quality gate.

**Acceptance gate**: `luna.data.encodeToml({key = "value"})` returns TOML string. `luna.data.parseToml(toml_str)` returns Lua table. Tests pass.

---

### Task 1.4 � Add `glam` crate

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | LOW (additive only in this phase) |
| **Affected files** | `Cargo.toml` |
| **SLoC change** | 0 (just add dependency; integration is Phase 4) |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Add `glam = "0.30"` to `Cargo.toml` `[dependencies]`.
2. Verify it compiles alongside existing math code.
3. No code changes yet � glam integration happens in Phase 4.

**Acceptance gate**: `cargo build` succeeds with glam as a dependency.

---

## Phase 2 � Major Dependency Migrations

Breaking version bumps that require code changes. Each is a dedicated migration effort. **Order matters**: mlua first (it affects all Lua API code), then image/rodio/env_logger, then wgpu last (largest).

### Task 2.1 � Migrate mlua 0.9 � 0.11

| Field | Details |
|---|---|
| **Priority** | CRITICAL |
| **Risk** | HIGH � affects all 18,161 SLoC of Lua API bindings |
| **Affected files** | All `src/lua_api/*.rs`, `src/engine/app.rs`, `src/lua_api/mod.rs` |
| **SLoC change** | ~200-500 (API adaptation) |
| **Dependencies** | Phase 1 complete |
| **Agent** | Developer |

**Steps**:
1. Read mlua 0.9 � 0.10 � 0.11 migration guide / changelog.
2. Update `mlua` version in `Cargo.toml` to `"0.11"`.
3. Update feature flags: `luajit`, `vendored` may have moved.
4. Fix all compilation errors � the `send`, `serialize`, `module` features changed.
5. Test `UserData` registration patterns � mlua 0.10+ changed `UserData` method registration.
6. Test all Lua callbacks (`luna.load`, `luna.update`, `luna.draw`, etc.).
7. Run full test suite: `cargo test`.
8. Run all examples: `cargo run -- demos/hello_world`, etc.

**Acceptance gate**: All 18,161+ SLoC of Lua API code compiles and all tests pass. All examples run without errors.

---

### Task 2.2 � Migrate rodio 0.17 � 0.22

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | HIGH � symphonia replaces legacy decoders |
| **Affected files** | `src/audio/mixer.rs`, `src/lua_api/audio_api.rs`, `tests/audio_tests.rs` |
| **SLoC change** | ~100-300 (audio loading/playback adaptation) |
| **Dependencies** | Task 2.1 (mlua migration must be done first) |
| **Agent** | Audio-Eng |

**Steps**:
1. Update `rodio` version in `Cargo.toml` to `"0.22"`.
2. Update `Mixer` to use symphonia-based decoders (the default in rodio 0.22).
3. Verify all audio formats still load: WAV, OGG, MP3, FLAC.
4. Update `Source` trait usage if changed.
5. Run audio tests.

**Acceptance gate**: Audio loading and playback works for all supported formats. `cargo test audio` passes.

---

### Task 2.3 � Migrate image 0.24 � 0.25

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | MEDIUM |
| **Affected files** | `src/image/mod.rs`, `src/graphics/texture.rs`, `src/lua_api/graphics_api.rs` |
| **SLoC change** | ~50-100 (API adaptation) |
| **Dependencies** | Task 2.1 |
| **Agent** | Developer |

**Steps**:
1. Update `image` version in `Cargo.toml` to `"0.25"`.
2. Fix feature flags: `default-features = false, features = ["png", "jpeg", "bmp"]` � verify these features still exist in 0.25.
3. Fix any breaking API changes in image loading/saving code.
4. Run `cargo test graphics image`.

**Acceptance gate**: PNG, JPEG, and BMP loading works. `cargo test` passes.

---

### Task 2.4 � Migrate thiserror 1 � 2

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW-MEDIUM |
| **Affected files** | All files with `#[derive(Error)]` � `src/engine/error.rs` and possibly others |
| **SLoC change** | ~20-50 (derive macro changes) |
| **Dependencies** | None (independent of other migrations) |
| **Agent** | Developer |

**Steps**:
1. Update `thiserror` version to `"2"`.
2. Fix any derive macro changes in `EngineError` and other error types.
3. Run `cargo build && cargo test`.

**Acceptance gate**: All error types compile. Tests pass.

---

### Task 2.5 � Migrate directories 5 � 6

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/filesystem/mod.rs` or wherever `directories` is used |
| **SLoC change** | ~10-20 (method renames) |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Update `directories` version to `"6"`.
2. Fix renamed methods (e.g., `config_dir()` may have moved).
3. Run `cargo build && cargo test filesystem`.

**Acceptance gate**: Filesystem path resolution works on all platforms. Tests pass.

---

### Task 2.6 � Migrate env_logger 0.10 � 0.11

| Field | Details |
|---|---|
| **Priority** | LOW |
| **Risk** | LOW |
| **Affected files** | `src/main.rs`, `src/engine/app.rs` (wherever `env_logger::init()` is called) |
| **SLoC change** | ~5-10 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Update `env_logger` version to `"0.11"`.
2. Fix any init API changes.
3. Run `cargo build && cargo test`.

**Acceptance gate**: Logging works. Build passes.

---

### Task 2.7 � Migrate sysinfo 0.30 � 0.38

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | MEDIUM � major API restructuring |
| **Affected files** | `src/lua_api/system_api.rs` |
| **SLoC change** | ~50-100 (reimplemented system queries) |
| **Dependencies** | Task 2.1 |
| **Agent** | Developer |

**Steps**:
1. Update `sysinfo` version to `"0.38"` with `default-features = false, features = ["system"]`.
2. Rewrite CPU/memory queries to use new API.
3. Add CPU utilization % and memory utilization % queries (replacing static CPU count / memory size).
4. Add Lua bindings: `luna.platform.getCpuUsage()`, `luna.platform.getMemoryUsage()`, `luna.platform.getProcessMemory()`.
5. Keep backwards-compatible: `luna.platform.getProcessorCount()` and `luna.platform.getMemorySize()` still work.
6. Run `cargo test system`.

**Acceptance gate**: `luna.platform.getCpuUsage()` returns a percentage. `luna.platform.getMemoryUsage()` returns used/total. Tests pass.

---

### Task 2.8 � Migrate winit 0.30 � 0.31

| Field | Details |
|---|---|
| **Priority** | LOW |
| **Risk** | LOW-MEDIUM |
| **Affected files** | `src/engine/app.rs`, `src/window/` |
| **SLoC change** | ~20-50 |
| **Dependencies** | Should be done alongside or after wgpu migration |
| **Agent** | Developer |

**Steps**:
1. Update `winit` version to `"0.31"`.
2. Fix any breaking API changes in window creation or event loop.
3. Test on Windows. Verify gamepad, keyboard, mouse, touch still work.
4. Run `cargo test && cargo run -- demos/hello_world`.

**Acceptance gate**: Window creates, input works, examples run. Tests pass.

---

### Task 2.9 � Migrate wgpu 22 � 29

| Field | Details |
|---|---|
| **Priority** | CRITICAL |
| **Risk** | **VERY HIGH** � 7 major versions, massive API churn |
| **Affected files** | `src/graphics/gpu_renderer.rs` (8,148 SLoC), `src/engine/app.rs`, `Cargo.toml` |
| **SLoC change** | ~300-800 (renderer adaptation) |
| **Dependencies** | ALL other Phase 2 tasks should be done first. This is the final migration. |
| **Agent** | Renderer |

**Steps**:
1. Research wgpu 22�23�24�25�26�27�28�29 migration guides.
2. Update `wgpu` version to `"29"`.
3. Update feature flags (wgpu 29 has `std`, `parking_lot` in defaults).
4. Fix surface configuration API (changed multiple times between 22-29).
5. Fix render pass creation API.
6. Fix texture creation and binding API.
7. Fix shader module creation.
8. Fix pipeline layout creation.
9. Run `cargo build` � iteratively fix all compilation errors.
10. Run visual tests � verify rendering output matches expectations.
11. Test on integrated GPU.

**Acceptance gate**: `cargo build && cargo test && cargo clippy -- -D warnings` passes. All examples render correctly. No visual regressions.

---

## Phase 3 � Native Audio Effects

Expand the audio system with native effects. Uses rodio 0.22's Source trait.

### Task 3.1 � Implement native audio DSP effects

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | MEDIUM |
| **Affected files** | `src/audio/effects.rs` (new), `src/audio/mod.rs`, `src/lua_api/audio_api.rs` |
| **SLoC change** | +500-700 |
| **Dependencies** | Task 2.2 (rodio 0.22 migration) |
| **Agent** | Audio-Eng |

**Steps**:
1. Create `src/audio/effects.rs` with these effect types (each implements rodio's `Source` trait):
   - **Echo/Delay**: Circular delay buffer with feedback. Params: `delay_ms`, `feedback` (0.0-1.0), `mix` (0.0-1.0). ~50 SLoC.
   - **Reverb**: Schroeder reverb using 4 comb filters + 2 allpass filters. Params: `room_size`, `damping`, `mix`. ~150 SLoC.
   - **Chorus**: Modulated delay (LFO-controlled). Params: `rate`, `depth`, `mix`. ~80 SLoC.
   - **Distortion**: Soft/hard clipping waveshaper. Params: `drive`, `type` (soft/hard/fuzz). ~30 SLoC.
   - **Compressor**: Dynamic range compression. Params: `threshold`, `ratio`, `attack_ms`, `release_ms`. ~100 SLoC.
   - **3-Band EQ**: Low/mid/high shelf biquad filters. Params: `low_gain`, `mid_gain`, `high_gain`, `low_freq`, `high_freq`. ~150 SLoC.
   - **Bandpass filter**: Combine existing lowpass + highpass. Params: `low_cutoff`, `high_cutoff`. ~30 SLoC.
2. Register effects in Lua API:
   - `luna.audio.newEffect(type, params) � Effect`
   - `source:addEffect(effect)`
   - `effect:setParam(name, value)`
3. Write tests for each effect type (at least: silence in � silence out, impulse response sanity check).

**Acceptance gate**: Each effect type creates, processes audio, and can be chained. Lua API works. Tests pass.

---

## Phase 4 � Math & glam Integration

Integrate glam as the backing math library for hot-path operations.

### Task 4.1 � Integrate glam into Vec2/Mat3

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | MEDIUM � touching core math types used everywhere |
| **Affected files** | `src/math/vec2.rs`, `src/math/mat3.rs`, `src/math/mod.rs` |
| **SLoC change** | ~100-200 (refactoring internal representation) |
| **Dependencies** | Task 1.4 (glam added as dep) |
| **Agent** | Developer |

**Steps**:
1. Change `Vec2` internal fields to wrap a `glam::Vec2`.
2. Delegate hot-path operations: `add`, `sub`, `mul`, `dot`, `normalize`, `length`, `distance`, `lerp` to glam.
3. Keep the Lua API surface unchanged � `luna.math.newVec2(x, y)` still works.
4. Change `Mat3` internal representation to wrap `glam::Mat3`.
5. Delegate transform operations to glam.
6. Run math tests � verify no precision regression.
7. Run all examples � verify visual correctness.

**Acceptance gate**: All math tests pass. Float comparisons within 1e-5 tolerance. All examples render correctly. No Lua API surface change.

---

### Task 4.2 � Expand easing functions

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/math/easing.rs`, `tests/math_tests.rs` |
| **SLoC change** | +150-200 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Add new easing functions to `src/math/easing.rs`:
   - `ease_in_out_elastic`, `ease_in_out_bounce`, `ease_in_out_back` (complete all families)
   - `ease_in_circ`, `ease_out_circ`, `ease_in_out_circ` (circular)
   - `smooth_step`, `smoother_step` (Hermite)
   - `spring(damping, frequency, t)` (spring physics)
   - `bezier(p1x, p1y, p2x, p2y, t)` (cubic B�zier)
   - `catmull_rom(p0, p1, p2, p3, t)` (spline)
2. Register new functions in the `apply(name, t)` lookup.
3. Write tests for each new function.
4. Update Lua bindings if needed.

**Acceptance gate**: All new easing functions accessible via `luna.math.ease(name, t)`. Tests pass for each curve.

---

## Phase 5 � Native Module Expansions

Expand game system modules with more features. All native Rust, no new crates.

### Task 5.1 � Expand noise/procgen

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/math/noise.rs`, `src/math/noise_generator.rs`, `src/math/procgen.rs` |
| **SLoC change** | +650-850 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Implement **value noise** (grid-based interpolated). ~40 SLoC.
2. Implement **blue noise / Poisson disk sampling**. ~80 SLoC.
3. Implement **Voronoi diagram generation**. ~100 SLoC.
4. Implement **Wave Function Collapse (WFC)** basic tile-based. ~300-500 SLoC.
5. Expand **cellular automata** with rule presets. ~60 SLoC.
6. Add **gradient ramp / color mapping**. ~30 SLoC.
7. Add **noise combination operators** (add, mul, min, max, power). ~40 SLoC.
8. Register all in Lua API.
9. Write tests for each algorithm.

**Acceptance gate**: Each algorithm produces deterministic output for a given seed. Lua API exposes all new features. Tests pass.

---

### Task 5.2 � Expand scene management

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/scene/mod.rs`, `src/lua_api/scene_api.rs`, `tests/scene_tests.rs` |
| **SLoC change** | +200-350 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Add **two-phase lifecycle events**: `will_enter`, `did_enter`, `will_leave`, `did_leave`. ~60 SLoC.
2. Add **scene overlays**: `pushOverlay(name, params)`, `popOverlay()`. ~80 SLoC.
3. Add **scene preloading**: `preloadScene(name)`. ~30 SLoC.
4. Add **scene recycling**: `recycleOnLeave` flag, destroy view but keep scene object. ~40 SLoC.
5. Add **more transition effects**: `crossFade`, `zoomIn`, `zoomOut`, `iris`, `irisOpen`. ~80 SLoC.
6. Formalize **inter-scene variables**: `luna.scene.setVariable(key, value)` / `getVariable(key)`. ~20 SLoC.
7. Register all in Lua API.
8. Write tests for lifecycle order, overlays, transitions.

**Acceptance gate**: Scene lifecycle fires events in correct order. Overlays render on top. New transitions work. Tests pass.

---

### Task 5.3 � Expand entity system

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/entity/mod.rs`, `src/lua_api/entity_api.rs`, `tests/entity_tests.rs` |
| **SLoC change** | +200-300 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Add **entity queries**: `universe:query("component1", "component2")` � filtered list. ~60 SLoC.
2. Add **component lifecycle hooks**: `on_add`, `on_remove` callbacks. ~50 SLoC.
3. Add **entity groups/pools**: Named collections with O(1) membership. ~60 SLoC.
4. Add **parent-child hierarchies**: `setParent`, kill cascading. ~80 SLoC.
5. Add **entity serialization**: `serialize()` / `deserialize()`. ~50 SLoC.
6. Register all in Lua API.
7. Write tests.

**Acceptance gate**: Queries return correct filtered results. Lifecycle hooks fire. Kill parent kills children. Serialization round-trips. Tests pass.

---

### Task 5.4 � Expand graph module (petgraph algorithms, native)

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/graph/mod.rs`, `src/lua_api/graph_api.rs`, `tests/graph_tests.rs` |
| **SLoC change** | +350-400 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Implement **Bellman-Ford shortest path** (negative weights). ~80 SLoC.
2. Implement **Tarjan's strongly connected components**. ~60 SLoC.
3. Implement **Kruskal's minimum spanning tree**. ~70 SLoC.
4. Implement **Edmonds-Karp maximum flow**. ~100 SLoC.
5. Implement **topological sort**. ~40 SLoC.
6. Register all in Lua API.
7. Write tests for each algorithm (including edge cases: negative cycles, disconnected graphs).

**Acceptance gate**: Each algorithm produces correct results on test cases. Lua API exposes all. Tests pass.

---

### Task 5.5 � Expand compute module

| Field | Details |
|---|---|
| **Priority** | LOW |
| **Risk** | LOW |
| **Affected files** | `src/compute/mod.rs`, `src/lua_api/compute_api.rs`, `tests/compute_tests.rs` |
| **SLoC change** | +200-300 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Add **cumulative sum / cumulative product** along axes. ~40 SLoC.
2. Add **argsort / partial sort** along axes. ~60 SLoC.
3. Add **histogram / binning**. ~50 SLoC.
4. Add **linear / bilinear interpolation**. ~40 SLoC.
5. Add **clamp / normalize** operations. ~30 SLoC.
6. Add **1D dot product**. ~20 SLoC.
7. Register all in Lua API.
8. Write tests.

**Acceptance gate**: Each operation produces correct results. Lua API exposes all. Tests pass.

---

### Task 5.6 � Expand tilemap (hex grid + object layers)

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/tilemap/mod.rs`, `src/tilemap/hex.rs` (new), `src/lua_api/tilemap_api.rs`, `tests/tilemap_tests.rs` |
| **SLoC change** | +300-400 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Create `src/tilemap/hex.rs` with hex grid utilities:
   - Cube/axial/offset coordinate types. ~40 SLoC.
   - Hex neighbor lookup (6 directions). ~20 SLoC.
   - Hex ring/spiral/line iterators. ~60 SLoC.
   - Hex distance, hex-to-pixel, pixel-to-hex. ~30 SLoC.
2. Add **object layers** to TileMap:
   - Named objects with type, position, size, rotation, properties. ~60 SLoC.
3. Add **tile properties table** � arbitrary key/value per tile ID. ~30 SLoC.
4. Add **layer blend modes** (normal, additive, multiply). ~20 SLoC.
5. Register all in Lua API.
6. Write tests.

**Acceptance gate**: Hex coordinate conversion is correct. Object layers store/retrieve objects. Tile properties accessible. Tests pass.

---

### Task 5.7 � Expand tweening and sprite animation

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/math/tween.rs`, `src/graphics/animation.rs` (or wherever sprite animation lives) |
| **SLoC change** | +250-350 |
| **Dependencies** | Task 4.2 (easing expansion) |
| **Agent** | Developer |

**Steps**:
1. **Tween expansion**:
   - Sequence tweens (chain end-to-end). ~40 SLoC.
   - Parallel tweens (multiple properties simultaneously). ~30 SLoC.
   - Repeat / yoyo modes. ~30 SLoC.
   - Tween callbacks: `onStart`, `onComplete`, `onRepeat`, `onUpdate`. ~40 SLoC.
   - Color tweening (HSL interpolation). ~30 SLoC.
   - Path tweening (waypoints with smoothing). ~40 SLoC.
2. **Sprite animation expansion**:
   - Animation events at specific frames. ~30 SLoC.
   - Animation blending / crossfade. ~40 SLoC.
   - Ping-pong playback mode. ~20 SLoC.
   - Speed curve per animation. ~20 SLoC.
3. Register all in Lua API.
4. Write tests.

**Acceptance gate**: Sequence tweens chain correctly. Yoyo repeats. Animation events fire at correct frames. Tests pass.

---

### Task 5.8 � Implement native binary serialization

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/data/binary.rs` (new), `src/lua_api/data_api.rs`, `tests/data_tests.rs` |
| **SLoC change** | +200 |
| **Dependencies** | None |
| **Agent** | Developer |

**Steps**:
1. Create `src/data/binary.rs` with type-length-value binary format:
   - Encode: nil, bool, i64, f64, string (length-prefixed), table (key-value pairs).
   - Decode: reverse process.
   - ~200 SLoC.
2. Register in Lua API:
   - `luna.data.encodeBinary(table) � ByteData`
   - `luna.data.decodeBinary(ByteData) � table`
3. Write round-trip tests (encode � decode � compare).

**Acceptance gate**: Round-trip serialization preserves all Lua value types. Nested tables work. Tests pass.

---

### Task 5.9 � Expand image processing (PNG workflow)

| Field | Details |
|---|---|
| **Priority** | MEDIUM |
| **Risk** | LOW |
| **Affected files** | `src/image/mod.rs`, `src/lua_api/graphics_api.rs`, `src/graphics/gpu_renderer.rs` |
| **SLoC change** | +100-150 |
| **Dependencies** | Task 2.3 (image 0.25 migration) |
| **Agent** | Developer |

**Steps**:
1. Add **PNG saving**: `ImageData:save(path)` using `image::save_buffer()`. ~20 SLoC.
2. Add **PNG encoding to memory**: `ImageData:encode("png") � ByteData`. ~30 SLoC.
3. Add **screenshot capture**: `luna.gfx.captureScreenshot(path)` that reads the GPU framebuffer and saves to PNG. ~50 SLoC.
4. Add **sub-image extraction**: `ImageData:getSubImage(x, y, w, h)`. ~20 SLoC.
5. Add **image paste/blit**: `ImageData:paste(source, x, y)`. ~20 SLoC.
6. Add **clone**: `ImageData:clone()`. ~10 SLoC.
7. Register all in Lua API.
8. Write tests.

**Acceptance gate**: PNG save/load round-trips. Screenshot captures visible frame. Sub-image extraction works. Tests pass.

---

## Phase 6 � Feature-Gated Tier 3 Additions & Logging

### Task 6.1 � Feature-gate rapier2d

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | MEDIUM |
| **Affected files** | `Cargo.toml`, `src/physics/world.rs`, `src/physics/mod.rs`, `src/lua_api/physics_api.rs` |
| **SLoC change** | ~100-200 (cfg gates + fallback paths) |
| **Dependencies** | None (but recommended after Phase 2 is stable) |
| **Agent** | Physicist |

**Steps**:
1. Add `physics-rapier = ["dep:rapier2d"]` feature flag to `Cargo.toml`.
2. Move rapier2d import behind `#[cfg(feature = "physics-rapier")]`.
3. Ensure AABB physics works when `physics-rapier` is NOT enabled.
4. Verify `cargo build --no-default-features --features lua-jit` works (no rapier).
5. Verify `cargo build --features "lua-jit,physics-rapier"` works (with rapier).

**Acceptance gate**: Build succeeds both with and without `physics-rapier` feature. Physics tests pass in both configurations.

---

### Task 6.2 � Add `tiled` crate (feature-gated)

| Field | Details |
|---|---|
| **Priority** | LOW |
| **Risk** | LOW |
| **Affected files** | `Cargo.toml`, `src/tilemap/tiled_import.rs` (new), `src/lua_api/tilemap_api.rs` |
| **SLoC change** | +100-150 |
| **Dependencies** | Task 5.6 (tilemap expansion) |
| **Agent** | Developer |

**Steps**:
1. Add `tiled = { version = "0.15", optional = true }` to `Cargo.toml`.
2. Add `tiled-import = ["dep:tiled"]` feature flag.
3. Implement `src/tilemap/tiled_import.rs` behind `#[cfg(feature = "tiled-import")]`:
   - `load_tmx(path) � TileMap` � parse TMX and populate native TileMap.
   - Map TMX layers � TileLayer, TMX tilesets � TileSet.
4. Register `luna.tilemap.loadTiled(path)` in Lua API (behind cfg).
5. Write test with a sample TMX file.

**Acceptance gate**: A TMX file loads into a native TileMap. Feature-gated build works both ways. Tests pass.

---

### Task 6.3 � Implement structured logging system

| Field | Details |
|---|---|
| **Priority** | HIGH |
| **Risk** | LOW |
| **Affected files** | `src/engine/logging.rs` (new), `src/lua_api/system_api.rs`, `src/main.rs` |
| **SLoC change** | +200-300 |
| **Dependencies** | Task 2.6 (env_logger migration) |
| **Agent** | Developer |

**Steps**:
1. Create `src/engine/logging.rs` with:
   - Custom `log` backend that outputs JSON when `LUNA_LOG_FORMAT=json`.
   - Format: `{"ts":"ISO8601","level":"INFO","module":"physics","msg":"..."}`.
   - File output: `set_log_file(path)` for persistent logging. ~100 SLoC.
2. Add Lua-side logging API:
   - `luna.log.info(msg)`, `luna.log.warn(msg)`, `luna.log.error(msg)`, `luna.log.debug(msg)`. ~30 SLoC.
   - `luna.log.setFile(path)` � redirect to file. ~20 SLoC.
   - `luna.log.perf(label, fn)` � timed execution logging. ~30 SLoC.
   - `luna.log.event(category, data_table)` � structured analytics event for AI consumption. ~50 SLoC.
3. Write tests for JSON format, file output, Lua integration.

**Acceptance gate**: JSON-formatted log lines parse correctly. File output writes. Lua `luna.log.info("test")` appears in log stream. `luna.log.event("combat", {damage=25})` produces structured JSON. Tests pass.

---

### Task 6.4 � GPU compute exploration

| Field | Details |
|---|---|
| **Priority** | LOW |
| **Risk** | MEDIUM |
| **Affected files** | `src/compute/gpu_compute.rs` (new), `src/lua_api/compute_api.rs` |
| **SLoC change** | +300-500 |
| **Dependencies** | Task 2.9 (wgpu 29 migration) |
| **Agent** | Renderer |

**Steps**:
1. Create `src/compute/gpu_compute.rs` with wgpu compute shader utilities:
   - GPU buffer management for NdArray data.
   - Compute shader for parallel matmul.
   - Compute shader for parallel element-wise operations.
2. Register `luna.compute.gpuMatmul(a, b)` in Lua API.
3. Implement fallback to CPU when GPU compute is unavailable.
4. Benchmark: measure speedup for large arrays (>100K elements).

**Acceptance gate**: GPU matmul produces correct results. Fallback to CPU works. Performance improvement measurable for large arrays.

---

## Phase Summary

| Phase | Tasks | Priority | Risk | Estimated SLoC |
|---|---|---|---|---|
| **1 � Cleanup & Safe Bumps** | 1.1, 1.2, 1.3, 1.4 | HIGH | LOW | ~50-80 added, ~200-500 removed |
| **2 � Major Migrations** | 2.1-2.9 | CRITICAL | HIGH | ~500-1,500 modified |
| **3 � Audio Effects** | 3.1 | HIGH | MEDIUM | +500-700 |
| **4 � Math & glam** | 4.1, 4.2 | HIGH | MEDIUM | +250-400 |
| **5 � Native Expansions** | 5.1-5.9 | MEDIUM | LOW | +2,350-3,100 |
| **6 � Tier 3 & Logging** | 6.1-6.4 | MIXED | MIXED | +700-1,150 |

**Total**: ~4,350-6,930 SLoC of changes across 30 tasks.

---

## Dependency Graph

```
Phase 1 (Cleanup)
+�� 1.1 Remove tiny-skia/minifb
+�� 1.2 Safe bumps � 1.1
+�� 1.3 Add toml crate
L�� 1.4 Add glam crate

Phase 2 (Migrations) � Phase 1
+�� 2.1 mlua 0.9 � 0.11 (FIRST � all Lua API code depends on this)
+�� 2.2 rodio � 0.22 � 2.1
+�� 2.3 image � 0.25 � 2.1
+�� 2.4 thiserror � 2 (independent)
+�� 2.5 directories � 6 (independent)
+�� 2.6 env_logger � 0.11 (independent)
+�� 2.7 sysinfo � 0.38 � 2.1
+�� 2.8 winit � 0.31 (do with or after 2.9)
L�� 2.9 wgpu � 29 (LAST � largest migration)

Phase 3 (Audio Effects) � 2.2
L�� 3.1 Native DSP effects

Phase 4 (Math) � 1.4
+�� 4.1 glam integration
L�� 4.2 Easing expansion

Phase 5 (Expansions) � mostly independent, can parallelize
+�� 5.1 Noise/procgen expansion
+�� 5.2 Scene management expansion
+�� 5.3 Entity system expansion
+�� 5.4 Graph algorithms expansion
+�� 5.5 Compute expansion
+�� 5.6 Tilemap expansion (hex + objects)
+�� 5.7 Tweening + animation expansion � 4.2
+�� 5.8 Binary serialization
L�� 5.9 Image processing (PNG workflow) � 2.3

Phase 6 (Tier 3 & Logging)
+�� 6.1 Feature-gate rapier2d
+�� 6.2 Add tiled crate � 5.6
+�� 6.3 Structured logging � 2.6
L�� 6.4 GPU compute � 2.9
```

---

## Critical Path

The critical path (longest chain of dependent tasks):

**Phase 1.1 � 1.2 � 2.1 (mlua) � 2.2 (rodio) � 3.1 (audio effects)**

And in parallel:

**Phase 1.1 � 1.2 � 2.1 (mlua) � 2.9 (wgpu) � 6.4 (GPU compute)**

The mlua migration (Task 2.1) is the **single most critical blocker** � almost every other Phase 2+ task depends on it. Prioritize it.

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| wgpu 22�29 migration breaks rendering | HIGH | HIGH | Research migration guides per version. Test each intermediate step. |
| mlua 0.9�0.11 breaks Lua bindings | HIGH | MEDIUM | Test every Lua API module individually. Keep 0.9 on a branch as fallback. |
| rodio 0.22 drops support for a format | MEDIUM | LOW | Check symphonia codec support matrix before migrating. |
| glam precision differs from hand-rolled math | LOW | LOW | Float comparison tests already use 1e-5 tolerance. |
| Native audio effects sound bad | MEDIUM | MEDIUM | Use proven DSP algorithms (Schroeder reverb, biquad filters). Reference implementations available. |
| WFC implementation too complex | MEDIUM | MEDIUM | Start with simple overlapping model. Defer tiled model to later. |
| GPU compute not available on integrated GPUs | LOW | MEDIUM | CPU fallback is mandatory for every GPU compute function. |

---

*Last updated: 2026-03-31. This plan accompanies `docs/ecosystem-recommendations.md` v2.*
