# Integration Test Plan

**Status**: ✅ IMPLEMENTED — All 18 planned integration tests created. 43 total integration tests now exist in `tests/lua/integration/`. All registered in `tests/lua/harness.rs`.

**Purpose**: Expand integration tests from 15 to 58+ by identifying natural module couplings across the full engine API surface. Target: double the planned 29-test set with deeper, game-engine-realistic couplings.

## Current Integration Tests (15)

| File | Modules Tested | Quality |
|------|---------------|---------|
| test_ai_physics.lua | ai + physics | Good |
| test_tilemap_physics.lua | tilemap + physics | Good |
| test_entity_ai.lua | entity + ai | Good |
| test_compute_dataframe.lua | compute + dataframe | Good |
| test_save_entity.lua | savegame + entity | Good |
| test_math_physics.lua | math + physics | Good |
| test_math_graphics.lua | math + graphics | Good |
| test_physics_timer.lua | physics + timer | Good |
| test_timer_math.lua | timer + math | Good |
| test_system.lua | system (single module) | **Misplaced** — should be unit test |
| test_devtools.lua | devtools (single module) | **Misplaced** — should be unit test |
| test_debugbridge.lua | debugbridge (single module) | **Misplaced** — should be unit test |
| test_docs.lua | docs (single module) | **Misplaced** — should be unit test |
| test_drawlayer.lua | graphics draw layers | `#[ignore]` — pending sprite module |
| test_data_system.lua | data + system | Good |

**Issues found**: 4 tests are misplaced single-module tests. True integration count: **11**.

---

## Module Coupling Matrix

Natural couplings based on API design and game-dev patterns:

### Tier 1: High Coupling (frequently used together)

| Module A | Module B | Coupling Reason | Existing Test? |
|----------|----------|-----------------|----------------|
| entity | physics | Physics bodies attached to entities | No |
| entity | graphics | Drawing entity sprites | No |
| entity | animation | Animated entity sprites | No |
| scene | entity | Scene graph contains entities | No |
| scene | camera | Camera follows scene hierarchy | No |
| tilemap | camera | Camera scrolling over tilemap | No |
| tilemap | entity | Entities on tile grid | No |
| particle | graphics | Particles rendered via draw commands | No |
| input | camera | Camera controlled by input | No |
| physics | camera | Camera following physics body | No |

### Tier 2: Medium Coupling (common game patterns)

| Module A | Module B | Coupling Reason | Existing Test? |
|----------|----------|-----------------|----------------|
| savegame | physics | Save/restore physics world state | No |
| savegame | tilemap | Save/restore tilemap state | No |
| animation + timer | — | Frame-rate-independent animation | No |
| data + filesystem | — | Load/save JSON config files | No |
| signal + entity | — | Entity events (created, destroyed) | No |
| ai + pathfinding | — | AI agents using pathfinding | No |
| light + graphics | — | Light affecting rendered objects | No |
| tilemap + pathfinding | — | Pathfinding on tile grid | No |
| entity + scene + physics | — | 3-way: scene manages physics entities | No |

### Tier 3: Specialized Coupling

| Module A | Module B | Coupling Reason |
|----------|----------|-----------------|
| thread + data | — | Worker thread serializes data |
| tween + camera | — | Smooth camera transitions |
| tween + entity | — | Tweening entity properties |
| particle + timer | — | Time-based particle emission |
| terminal + data | — | Terminal displays formatted data |
| modding + filesystem | — | Mod discovery and loading |
| localization + gui | — | Localized UI text |

---

## New Integration Tests (18 proposed)

### Priority 1 — Core Game Patterns (8 tests)

#### test_entity_physics.lua
```
Modules: entity + physics
Scenario: Create entity → attach physics body → step world → verify entity position updated
Tests: body-entity sync, collision events on entities, removing entity removes body
```

#### test_entity_graphics.lua
```
Modules: entity + graphics  
Scenario: Create entity → set sprite/draw component → verify draw commands generated
Tests: entity position → draw position sync, visibility toggle, z-ordering
```

#### test_scene_entity.lua
```
Modules: scene + entity
Scenario: Create scene → add entity nodes → traverse hierarchy → verify parent-child transforms
Tests: add/remove entities from scene, scene traversal order, nested transforms
```

#### test_scene_camera.lua
```
Modules: scene + camera
Scenario: Create scene → set camera → verify viewport transforms
Tests: camera position affects visible nodes, zoom changes visible area, camera bounds
```

#### test_tilemap_camera.lua
```
Modules: tilemap + camera
Scenario: Create tilemap → set camera → query visible tiles
Tests: camera scroll reveals different tiles, zoom changes tile count, culling works
```

#### test_ai_pathfinding.lua
```
Modules: ai + pathfinding
Scenario: AI agent navigates grid using A* pathfinding
Tests: agent requests path → follows waypoints → reaches goal; path recalculation on obstacle
```

#### test_input_camera.lua
```
Modules: input + camera
Scenario: Simulate input events → camera responds
Tests: arrow keys move camera, scroll wheel zooms, camera limits enforced
```

#### test_animation_timer.lua
```
Modules: animation + timer
Scenario: Animation advances based on timer delta
Tests: animation frame advances with delta time, pause timer pauses animation, speed scaling
```

### Priority 2 — Data & Persistence (5 tests)

#### test_data_filesystem.lua
```
Modules: data + filesystem
Scenario: Serialize data to JSON → write to file → read back → deserialize → verify
Tests: JSON round-trip via filesystem, TOML config loading, binary data write/read
```

#### test_savegame_tilemap.lua
```
Modules: savegame + tilemap
Scenario: Create tilemap → modify tiles → save → clear → load → verify tiles restored
Tests: tile data persistence, layer state persistence, tilemap properties round-trip
```

#### test_signal_entity.lua
```
Modules: signal + entity
Scenario: Entity emits events → signal handlers respond
Tests: entity created event, entity destroyed event, component added/removed events
```

#### test_tilemap_pathfinding.lua
```
Modules: tilemap + pathfinding
Scenario: Convert tilemap to navigation grid → pathfind on it
Tests: walkable tiles → valid paths, wall tiles → blocked paths, cost from tile properties
```

#### test_thread_data.lua
```
Modules: thread + data
Scenario: Worker thread serializes data via Channel
Tests: send table to worker → worker processes → sends result back; JSON over Channel
```

### Priority 3 — UI & Visual (5 tests)

#### test_tween_camera.lua
```
Modules: tween + camera
Scenario: Tween camera position/zoom smoothly
Tests: tween start → camera moves → tween complete; easing functions affect trajectory
```

#### test_tween_entity.lua
```
Modules: tween + entity
Scenario: Tween entity properties (position, scale, rotation)
Tests: entity position interpolated correctly, multiple simultaneous tweens, tween chaining
```

#### test_particle_timer.lua
```
Modules: particle + timer
Scenario: Particle emission rate based on timer
Tests: emit N particles per second, emission stops when timer pauses, burst at time
```

#### test_light_graphics.lua
```
Modules: light + graphics
Scenario: Light affects draw commands
Tests: point light created → lights list contains it, ambient change updates state
```

#### test_localization_ui.lua
```
Modules: localization + ui (if GUI text rendering available headless)
Scenario: UI labels display localized text
Tests: set locale → UI text updates, missing key → fallback text, pluralization in UI
```

---

## Misplaced Test Cleanup

Move the following from `integration/` to `unit/` (or merge into existing unit tests):

| Current File | Action |
|-------------|--------|
| test_system.lua | Merge into test_system.lua unit test |
| test_devtools.lua | Merge into test_devtools.lua unit test |
| test_debugbridge.lua | Merge into test_debugbridge.lua unit test |
| test_docs.lua | Merge into test_docs.lua unit test |

---

## Summary

| Category | Current | Phase 1 Plan | Phase 2 Plan (Doubled) | Net New |
|----------|---------|----------|---------|---------|
| True integration tests | 11 | 29 | 58 | +47 |
| Misplaced tests to fix | 4 | 0 | 0 | -4 |
| Module pairs/triples covered | 11 | 29 | 58 | +47 |

---

## Phase 2 — Doubled Integration Test Set (29 Additional)

These tests cover deeper engine couplings, 3-way module interactions, and game-system patterns not addressed in Phase 1. Priority ranked by real game development frequency.

### Group A: Graphics Pipeline Integrations (9 tests)

#### test_graphics_camera.lua
```
Modules: graphics + camera
Scenario: Verify draw calls are viewport-transformed by active camera
Tests: draw rect → camera project/unproject → screen coords correct, camera zoom changes pixel scale
Evidence: Canvas pixel readback at transformed positions
```

#### test_graphics_light.lua
```
Modules: graphics + light
Scenario: Ambient and point lights affect scene luminance visible in rendered output
Tests: no lights → max ambient only; add point light near rect → brighter pixels at that region
Evidence: Canvas pixel readback — compare lit vs unlit brightness values
```

#### test_graphics_effect.lua
```
Modules: graphics + effect
Scenario: Post-processing effects applied to drawn content
Tests: draw plain rect → apply blur effect → pixel values have spread; color adjust → hue shift
Evidence: Canvas pixel readback before/after effect application
```

#### test_graphics_animation.lua
```
Modules: graphics + animation  
Scenario: Animation drives which sprite frame is drawn
Tests: animation at frame 0 draws expected region, advance to frame N draws correct region
Evidence: Canvas pixel readback verifies different pixel regions per frame
```

#### test_graphics_particle.lua
```
Modules: graphics + particle
Scenario: Particles emit draw commands into the graphics pipeline
Tests: emitter emits → draw commands contain particle draw calls → canvas has non-empty pixels
Evidence: Canvas pixel readback — at least one non-transparent pixel after emission
```

#### test_graphics_tilemap.lua
```
Modules: graphics + tilemap
Scenario: Tilemap requests draw commands for visible tile region
Tests: tile draw region matches camera viewport, tile spacing correct in pixel space
Evidence: Canvas pixel readback verifies tile grid alternating pixels
```

#### test_canvas_postfx.lua
```
Modules: graphics (canvas) + postfx
Scenario: Canvas is used as render-to-texture target, PostFX reads from it
Tests: render scene to canvas → apply PostFX pass → output canvas has modified pixels
Evidence: Pixel comparison before/after PostFX pass
```

#### test_image_graphics.lua
```
Modules: image + graphics
Scenario: Processed image (resize/crop/flip) is drawn via graphics API
Tests: load image → image module resize → draw via gfx.draw → pixel at center is expected color
Evidence: Canvas pixel readback at draw position
```

#### test_spine_animation.lua
```
Modules: spine + animation
Scenario: Spine skeleton plays animations and blends states
Tests: skeleton setAnimation → tick dt → attachment positions change; blend two animations
Tests: bone positions change per frame, attachment visibility changes per animation
Evidence: Read bone transform state per frame (no GPU needed for state readback)
```

---

### Group B: Audio Integration Tests (4 tests)

#### test_audio_timer.lua
```
Modules: audio + timer
Scenario: Timer drives audio cue scheduling and crossfade timing
Tests: timer fires → audio source plays; crossfade uses delta time; rhythm-locked playback at exact ms
Tests: Source state is "playing" after scheduled start, "stopped" after scheduled stop
```

#### test_audio_event.lua
```
Modules: audio + event
Scenario: Game events trigger audio playback
Tests: emit "player.hit" event → audio.play("hit.wav") triggers; bus volume changes on event
Tests: event order correct (event fired after play call returns)
```

#### test_audio_data.lua
```
Modules: audio + data
Scenario: Audio metadata/playlist stored and restored via data module
Tests: build playlist table → toJSON → fromJSON → recreate same source list; metadata round-trip
```

#### test_audio_filesystem.lua
```
Modules: audio + filesystem  
Scenario: Audio sources loaded from GameFS sandbox
Tests: load sound from game folder → plays from correct path; invalid path → descriptive LuaError
Tests: streaming source reads chunks from filesystem without full load
```

---

### Group C: AI & World Simulation (5 tests)

#### test_ai_entity_scene.lua
```
Modules: ai + entity + scene (3-way)
Scenario: AI agents are entities in a scene, AI drives entity transform
Tests: AI FSM state → entity position updates; scene query returns only agent entities; parent removes AI too
```

#### test_ai_signal.lua
```
Modules: ai + signal
Scenario: AI agents broadcast state changes as signals
Tests: FSM transitions → signal emitted with state name; signal listeners update game state accordingly
Tests: signal order matches FSM transition order
```

#### test_pathfinding_entity.lua
```
Modules: pathfinding + entity
Scenario: Entities follow pathfinding-computed routes
Tests: entity has path component → moves along waypoints each frame; entity reaches goal position
Tests: path recomputed when blocked entity moves
```

#### test_pathfinding_tilemap_entity.lua
```
Modules: pathfinding + tilemap + entity (3-way)
Scenario: Tilemap defines walkable grid, entity uses pathfinding to navigate it
Tests: walkable tiles allow paths, wall tiles block; entity follows route through tilemap
Tests: tile change (wall added) → path becomes invalid → recomputed
```

#### test_ai_scene_camera.lua
```
Modules: ai + scene + camera (3-way)
Scenario: Camera follows AI-driven entity through scene
Tests: AI agent entity moves → camera tracks → scene scroll correct; scene culling based on camera
```

---

### Group D: Persistence & State (5 tests)

#### test_savegame_entity_scene.lua
```
Modules: savegame + entity + scene (3-way)
Scenario: Full scene with entities is saved and restored
Tests: create scene → add 10 entities with components → save → destroy all → load → verify 10 entities
Tests: entity component data preserved; scene hierarchy preserved
```

#### test_savegame_animation.lua
```
Modules: savegame + animation
Scenario: Animation state is saved mid-frame and restored
Tests: play animation to frame 5 → save → load → animation resumes from frame 5
Tests: animation speed and loop state preserved
```

#### test_data_compute.lua
```
Modules: data + compute
Scenario: GPU compute results serialized to data for persistence
Tests: compute → get results → toJSON → fromJSON → values match; large result sets round-trip cleanly
```

#### test_thread_filesystem.lua
```
Modules: thread + filesystem
Scenario: Background thread reads/writes files without blocking main VM
Tests: spawn thread → thread writes file → main VM reads it back; channel confirms completion
Tests: concurrent file writes from multiple threads (serialized by OS — no corruption)
```

#### test_savegame_modding.lua
```
Modules: savegame + modding
Scenario: Mod-added data is preserved in save files (forward compatibility)
Tests: save file with mod data → unload mod → load file → mod data preserved as opaque blob
Tests: load file on unmodded game → mod data ignored gracefully
```

---

### Group E: UI, Localization & Input (4 tests)

#### test_ui_input.lua
```
Modules: ui + input
Scenario: UI widgets respond to simulated input events
Tests: simulate mouse click at button position → button "onClick" callback fires
Tests: keyboard navigation (Tab → next widget); keyboard shortcut triggers action
```

#### test_ui_localization_data.lua
```
Modules: ui + localization + data (3-way)
Scenario: UI text sourced from locale data loaded from data module
Tests: load locale JSON → set locale → UI label displays localized string
Tests: switch locale at runtime → UI labels update; missing key → fallback to default
```

#### test_gui_animation.lua
```
Modules: gui + animation
Scenario: UI elements have animated transitions
Tests: button hover → animation plays; menu open/close triggers slide animation
Tests: animation speed correct relative to delta time
```

#### test_input_tween.lua
```
Modules: input + tween
Scenario: Input events start tweens (e.g. double-click zooms smoothly)
Tests: simulate click → tween starts with correct from/to values; tween in progress → further input queued
```

---

### Group F: Procedural & Rendering Pipeline (6 tests)

#### test_procgen_tilemap.lua
```
Modules: procgen + tilemap
Scenario: Procedural generator fills a tilemap with generated content
Tests: dungeon generate → tile IDs match expected room/corridor structure (seeded); cave generate → walls at edges
Tests: tilemap dimensions match procgen output size
```

#### test_procgen_entity.lua
```
Modules: procgen + entity
Scenario: Procedural generation spawns entities at generated positions
Tests: seeded generate → entity count and positions deterministic; names generated from procgen list
```

#### test_tween_animation.lua
```
Modules: tween + animation
Scenario: Tweens control animation playback speed and blend weight
Tests: tween animationSpeed 0→1 over 1s → linear speed increase; tween blend weight for layer blending
```

#### test_postfx_camera.lua
```
Modules: postfx + camera
Scenario: PostFX effects applied per-camera (each camera has own FX chain)
Tests: camera A has blur, camera B has none → renders differ; disable camera A FX → renders match
Evidence: Canvas pixel readback with per-camera FX chain
```

#### test_minimap_tilemap_camera.lua
```
Modules: minimap + tilemap + camera (3-way)
Scenario: Minimap shows tilemap area with main camera viewport indicator
Tests: minimap renders tilemap overview; camera rect shown correctly on minimap; scale correct
Evidence: Canvas pixel readback verifies minimap content vs tilemap structure
```

#### test_raycaster_tilemap.lua
```
Modules: raycaster + tilemap (if raycaster walks tilemap grid)
Scenario: Raycaster reads wall tiles from tilemap for 2.5D rendering
Tests: solid tiles → ray hits; open tiles → ray passes through; render column heights deterministic (seeded)
```

---

## Registration in harness.rs (Phase 2 additions)

```rust
// Group A: Graphics Pipeline
#[test] fn lua_integration_graphics_camera() { run_lua_test("integration/test_graphics_camera.lua"); }
#[test] fn lua_integration_graphics_light() { run_lua_test("integration/test_graphics_light.lua"); }
#[test] fn lua_integration_graphics_effect() { run_lua_test("integration/test_graphics_effect.lua"); }
#[test] fn lua_integration_graphics_animation() { run_lua_test("integration/test_graphics_animation.lua"); }
#[test] fn lua_integration_graphics_particle() { run_lua_test("integration/test_graphics_particle.lua"); }
#[test] fn lua_integration_graphics_tilemap() { run_lua_test("integration/test_graphics_tilemap.lua"); }
#[test] fn lua_integration_canvas_postfx() { run_lua_test("integration/test_canvas_postfx.lua"); }
#[test] fn lua_integration_image_graphics() { run_lua_test("integration/test_image_graphics.lua"); }
#[test] fn lua_integration_spine_animation() { run_lua_test("integration/test_spine_animation.lua"); }
// Group B: Audio
#[test] fn lua_integration_audio_timer() { run_lua_test("integration/test_audio_timer.lua"); }
#[test] fn lua_integration_audio_event() { run_lua_test("integration/test_audio_event.lua"); }
#[test] fn lua_integration_audio_data() { run_lua_test("integration/test_audio_data.lua"); }
#[test] fn lua_integration_audio_filesystem() { run_lua_test("integration/test_audio_filesystem.lua"); }
// Group C: AI
#[test] fn lua_integration_ai_entity_scene() { run_lua_test("integration/test_ai_entity_scene.lua"); }
#[test] fn lua_integration_ai_signal() { run_lua_test("integration/test_ai_signal.lua"); }
#[test] fn lua_integration_pathfinding_entity() { run_lua_test("integration/test_pathfinding_entity.lua"); }
#[test] fn lua_integration_pathfinding_tilemap_entity() { run_lua_test("integration/test_pathfinding_tilemap_entity.lua"); }
#[test] fn lua_integration_ai_scene_camera() { run_lua_test("integration/test_ai_scene_camera.lua"); }
// Group D: Persistence
#[test] fn lua_integration_savegame_entity_scene() { run_lua_test("integration/test_savegame_entity_scene.lua"); }
#[test] fn lua_integration_savegame_animation() { run_lua_test("integration/test_savegame_animation.lua"); }
#[test] fn lua_integration_data_compute() { run_lua_test("integration/test_data_compute.lua"); }
#[test] fn lua_integration_thread_filesystem() { run_lua_test("integration/test_thread_filesystem.lua"); }
#[test] fn lua_integration_savegame_modding() { run_lua_test("integration/test_savegame_modding.lua"); }
// Group E: UI & Input
#[test] fn lua_integration_ui_input() { run_lua_test("integration/test_ui_input.lua"); }
#[test] fn lua_integration_ui_localization_data() { run_lua_test("integration/test_ui_localization_data.lua"); }
#[test] fn lua_integration_gui_animation() { run_lua_test("integration/test_gui_animation.lua"); }
#[test] fn lua_integration_input_tween() { run_lua_test("integration/test_input_tween.lua"); }
// Group F: Procedural & Rendering
#[test] fn lua_integration_procgen_tilemap() { run_lua_test("integration/test_procgen_tilemap.lua"); }
#[test] fn lua_integration_procgen_entity() { run_lua_test("integration/test_procgen_entity.lua"); }
#[test] fn lua_integration_tween_animation() { run_lua_test("integration/test_tween_animation.lua"); }
#[test] fn lua_integration_postfx_camera() { run_lua_test("integration/test_postfx_camera.lua"); }
#[test] fn lua_integration_minimap_tilemap_camera() { run_lua_test("integration/test_minimap_tilemap_camera.lua"); }
#[test] fn lua_integration_raycaster_tilemap() { run_lua_test("integration/test_raycaster_tilemap.lua"); }
```
