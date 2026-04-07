# Luna2D — Cross-Module Feature Analysis Summary

This file aggregates findings from all 38 module-level feature analyses in `ideas/features/`.
It provides a high-level view of structural issues, merge/split candidates, feature gaps, and priorities.

---

## Table of Contents

1. [Module Inventory](#module-inventory)
2. [Merge Candidates](#merge-candidates)
3. [Split Candidates](#split-candidates)
4. [Scope Overlaps](#scope-overlaps)
5. [Rename Suggestions](#rename-suggestions)
6. [Tier Corrections](#tier-corrections)
7. [New Module Suggestions](#new-module-suggestions)
8. [Engine-Wide Feature Gaps](#engine-wide-feature-gaps)
9. [Luna2D Differentiators](#luna2d-differentiators)
10. [Top 20 Priority Features](#top-20-priority-features)
11. [Modules to Consider Moving to Tier 3](#modules-to-consider-moving-to-tier-3)
12. [Per-Module Priority Ranking](#per-module-priority-ranking)

---

## Module Inventory

| Tier | Module | Files | Analysis |
|---|---|---|---|
| Baseline | math | Leaf module | [math.md](math.md) |
| Baseline | engine | Core loop, config | [engine.md](engine.md) |
| 1 | graphics | 18+ files | [graphics.md](graphics.md) |
| 1 | physics | rapier2d | [physics.md](physics.md) |
| 1 | audio | rodio | [audio.md](audio.md) |
| 1 | image | ImageData | [image.md](image.md) |
| 1 | input | Keyboard, mouse, gamepad | [input.md](input.md) |
| 1 | timer | dt, FPS | [timer.md](timer.md) |
| 1 | window | winit wrapper | [window.md](window.md) |
| 1 | entity | ECS-like | [entity.md](entity.md) |
| 1 | event | Pub-sub | [event.md](event.md) |
| 1 | filesystem | GameFS sandbox | [filesystem.md](filesystem.md) |
| 1 | animation | Frame clips | [animation.md](animation.md) |
| 1 | camera | Viewport | [camera.md](camera.md) |
| 1 | data | Typed buffers | [data.md](data.md) |
| 1 | compute | ndarray ops | [compute.md](compute.md) |
| 1 | thread | Worker VMs | [thread.md](thread.md) |
| 1 | automation | Input replay/sim | [automation.md](automation.md) |
| 1 | serial | JSON/TOML/CSV | [serial.md](serial.md) |
| 1 | network | ENet UDP | [network.md](network.md) |
| 2 | scene | Scene graph | [scene.md](scene.md) |
| 2 | particle | Emitters | [particle.md](particle.md) |
| 2 | tilemap | Grid maps | [tilemap.md](tilemap.md) |
| 2 | gui | Widget toolkit | [gui.md](gui.md) |
| 2 | ai | 8 AI paradigms | [ai.md](ai.md) |
| 2 | pathfinding | A*/HPA*/flow | [pathfinding.md](pathfinding.md) |
| 2 | graph | Data structure | [graph.md](graph.md) |
| 2 | dataframe | Columnar data | [dataframe.md](dataframe.md) |
| 2 | savegame | Save manager | [savegame.md](savegame.md) |
| 2 | modding | Mod metadata | [modding.md](modding.md) |
| 2 | minimap | Grid minimap | [minimap.md](minimap.md) |
| 2 | fx | PostFx + overlays | [fx.md](fx.md) |
| 2 | light | 2D lighting | [light.md](light.md) |
| 2 | procgen | Procedural gen | [procgen.md](procgen.md) |
| 2 | raycaster | DDA pseudo-3D | [raycaster.md](raycaster.md) |
| 2 | terminal | Char-cell UI | [terminal.md](terminal.md) |
| 2 | spine | Skeletal anim | [spine.md](spine.md) |
| 2 | pipeline | DAG orchestrator | [pipeline.md](pipeline.md) |

**Not analyzed** (structural, not feature modules): `bin` (launcher), `lua_api` (bridge layer), `sound` (merged into audio analysis).

---

## Merge Candidates

### 1. `data` + `compute` → `buffer`
**Rationale**: `data` provides typed byte buffers. `compute` provides ndarray operations on those buffers. They're the same subsystem split into two modules. No other module depends on `compute` without also depending on `data`. Merged name: `buffer` or `data` (dropping `compute` as separate).
**Impact**: Reduces module count, simplifies mental model.

### 2. `graph` + `pathfinding` → `graph` (with pathfinding sub-namespace)
**Rationale**: `pathfinding` operates on graphs and imports `graph`. They share data structures. `luna.graph.*` + `luna.pathfinding.*` → `luna.graph.*` + `luna.graph.findPath()`. However, pathfinding is complex enough (A*, HPA*, flow fields) to justify its own namespace. **Verdict**: Keep separate but document the relationship clearly.

### 3. `spine` + `animation` → `animation` (with skeleton sub-system)
**Rationale**: Both deal with animation but through different paradigms. A unified animation module with frame-based clips AND skeletal bones would be more discoverable. `luna.animation.newClip()` + `luna.animation.newSkeleton()`. The spine module is thin (11 functions) and would benefit from sharing timeline/keyframe infrastructure.
**Impact**: Medium — requires API restructuring.

### 4. `sound` → already part of `audio`
**Status**: Already merged conceptually. SoundData is documented in the audio spec. No separate spec file exists.

---

## Split Candidates

### 1. `graphics` → `graphics` + `sprite` + `text` + `shader`
**Rationale**: 18+ source files is too large for one module. Natural splits:
- `graphics` core: Canvas, drawing primitives, color, blend modes
- `sprite`: SpriteBatch, atlas, animation frames
- `text`: Font loading, text rendering, glyph cache
- `shader`: Custom WGSL shaders, material system
**Impact**: Large but improves maintainability. Can be done incrementally.

### 2. `audio` → `audio` + `dsp` (later)
**Rationale**: If DSP/FFT features are added (equalization, spectrum analysis), they should be a separate module rather than bloating audio. Not urgent — audio is well-scoped currently.

---

## Scope Overlaps

| Overlap | Modules | Resolution |
|---|---|---|
| Tween animation | `math` (easing functions) + `animation` (tween) | Keep: math owns easing curves, animation applies them. Clear separation. |
| Camera shake | `camera` (shake method) + `fx` (shake overlay) | **Fix**: Remove from one. Camera shake is more intuitive. |
| Cellular automata | `tilemap` (map gen) + `procgen` (cave gen) | **Fix**: Consolidate in `procgen`. Tilemap should consume procgen output. |
| Depth sorting | `scene` (DepthSorter) | **Fix**: Move to `graphics`. Scene should use it, not own it. |
| TOML parsing | `engine` (config) + `serial` (encode/decode) | Keep: Different consumers (engine internals vs game scripts). |
| Viewport | `camera` (viewport) + `window` (pixel size) | Keep: Window owns physical pixels, camera owns logical viewport. |
| Entity relationships | `entity` (RelationshipManager) + `scene` (parent-child) | **Review**: Scene's parent-child tree and entity's relationship graph may serve different use cases, but could confuse users. |

---

## Rename Suggestions

| Current | Suggested | Reason |
|---|---|---|
| `compute` | `ndarray` or merge into `data` | "compute" is too generic — suggests GPU compute shaders |
| `spine` | `skeleton` | "spine" implies Spine SDK compatibility. It's a custom bone system |
| `data` | `buffer` (if merging with compute) | "data" is extremely generic — could mean anything |
| `sound` | N/A (merge into `audio`) | SoundData is just a sub-concept of audio |

---

## Tier Corrections

| Module | Current Tier | Correct Tier | Issue |
|---|---|---|---|
| `light` | Labeled Tier 1 in some docs | Tier 2 | Depends on Tier 1 graphics. Should be Tier 2. |
| `math` → `SpatialHash` | Labeled "leaf" | Imports `engine::log_messages` | Breaks leaf module claim. Remove the log import or move SpatialHash. |

---

## New Module Suggestions

### HIGH PRIORITY

1. **`tween`** — Dedicated tweening module. Currently tween lives in animation and easing in math. A unified `luna.tween.to(target, props, duration, easing)` API (like LÖVE's Flux or Solar2D's transition) would be the most-used game API after drawing.

2. **`input_map`** — Action-based input mapping. Map physical keys to named game actions: `luna.input_map.bind("jump", "space", "gamepad_a")`. Every major engine has this. Luna2D forces raw key checks.

3. **`collision`** — Lightweight collision detection without physics simulation. AABB, circle, polygon overlap tests + spatial hashing. Many games need collision without rigid bodies. Currently must use the full rapier2d physics module.

### MEDIUM PRIORITY

4. **`sprite`** — Extract from graphics. Own SpriteBatch, texture atlas, sprite animation, atlas JSON import. This is 90% of what game developers draw.

5. **`text`** — Rich text rendering. Multi-color, multi-font, inline icons, text wrapping, text effects (wave, shake, typewriter). Currently text rendering is basic.

6. **`debug`** — Consolidate debug tools: FPS overlay, entity inspector, physics debug draw, memory stats, log viewer. Currently scattered across modules.

7. **`localization`** — i18n/l10n support. String tables, plural forms, locale switching, right-to-left text, font fallback for CJK.

### LOWER PRIORITY

8. **`coroutine`** — Lua coroutine helpers. `luna.coroutine.wait(seconds)`, `luna.coroutine.waitFor(condition)`. Enables clean async game logic.

9. **`distribution`** — `.luna` single-file game distribution format. ZIP-based archive containing all game assets. Run with `luna game.luna`.

---

## Engine-Wide Feature Gaps

### Critical (impacts core game development)

1. **No hot reload** — Must restart the engine after any Lua script or asset change. This is the #1 developer productivity gap. Every modern engine has live-reload.
2. **No `.luna` distribution format** — No way to package a game as a single file for distribution.
3. **No Tiled/LDtk import** — The tilemap module can't load industry-standard level editor formats.
4. **No texture atlas JSON/XML import** — Can't load TexturePacker, Aseprite, or ShoeBox atlas files.
5. **No input action mapping** — Must check raw keys. No `isActionPressed("jump")` abstraction.

### Important (impacts specific game genres)

6. **No physics debug draw** — Can't visualize colliders, bodies, joints. Essential for physics game development.
7. **Raycaster extension types not Lua-exposed** — Doors, height maps, lighting exist in Rust but not in Lua.
8. **No skeletal animation timelines** — Spine module has bone hierarchy but no keyframe animation.
9. **No HTTP client** — Can't communicate with web services for leaderboards, analytics, or content.
10. **8-peer network limit** — Too restrictive for many multiplayer games.

### Nice to Have

11. No gradient fills (linear, radial) in graphics
12. No GUI themes/skinning system
13. No GUI layout engine (flexbox, grid)
14. No audio FFT/spectrum analysis
15. No one-way platforms in physics
16. No particle physics interaction
17. No save file encryption
18. No WebSocket support
19. No coroutine async helpers
20. No file watcher for hot reload

---

## Luna2D Differentiators

These features set Luna2D apart from competing engines. Protect and promote them:

| Feature | Why It's Unique |
|---|---|
| **AI module (8 paradigms)** | No other Lua engine has built-in FSM + BT + GOAP + utility + steering + Q-learning + squads + blackboard |
| **Pathfinding (HPA* + flow fields)** | Most engines only offer basic A*. HPA* and flow fields are advanced |
| **Automation** | Deterministic input replay and simulation. No competitor has this |
| **Modding** | Built-in mod metadata system. Most engines leave this to the developer |
| **Savegame** | Built-in save manager with schema versioning and migration. Unique |
| **Minimap** | Built-in minimap module with fog-of-war. Very unusual |
| **Terminal** | Grid-based terminal emulator with widgets. Unique for game engines |
| **Raycaster** | Built-in DDA raycaster for pseudo-3D. No competitor has this |
| **Procgen** | 5 algorithms built-in. Most engines have 0 |
| **16 PostFx effects** | CRT, bloom, vignette, pixelate, etc. Out-of-box visual effects |
| **12 Overlay systems** | Rain, snow, fog, fireflies, etc. Immediate visual atmosphere |
| **Dataframe** | Columnar data processing in a game engine. Unique |
| **Pipeline** | DAG workflow orchestration. Unique but questionable fit |

---

## Top 20 Priority Features

Ranked by impact × effort. Focuses on features that would make games better, not engine internals.

| Rank | Feature | Module | Why |
|---|---|---|---|
| 1 | **Hot reload** | engine | #1 dev productivity. Every modern engine has it. |
| 2 | **Expose raycaster extension types** | raycaster | Code already exists in Rust. Just needs bindings. Highest ROI. |
| 3 | **Input action mapping** | NEW: input_map | Eliminates raw key checks. Every game needs this. |
| 4 | **Tiled/LDtk import** | tilemap | Industry-standard level editors. Unlocks professional workflow. |
| 5 | **Tween module** | NEW: tween | Most-used animation primitive. Currently awkward. |
| 6 | **Texture atlas import** | graphics/sprite | TexturePacker, Aseprite. Standard asset workflow. |
| 7 | **Physics debug draw** | physics | Essential for debugging physics games. Love2D has it. |
| 8 | **HTTP client** | network | Leaderboards, analytics, content delivery. Basic web access. |
| 9 | **`.luna` distribution format** | NEW: distribution | Single-file game packaging. |
| 10 | **Lightweight collision** | NEW: collision | Collision without physics sim. Many games need just overlap tests. |
| 11 | **Skeletal animation timelines** | spine | Make spine module actually usable. |
| 12 | **BSP dungeon generation** | procgen | Top roguelike algorithm. |
| 13 | **One-way platforms** | physics | Platformer genre essential. |
| 14 | **MessagePack** | serial | Compact save data and network payloads. |
| 15 | **GUI themes/skinning** | gui | Professional-looking UIs without manual styling. |
| 16 | **Scrollback buffer** | terminal | Terminal usability improvement. |
| 17 | **Network peer limit increase** | network | Quick fix, big impact for multiplayer. |
| 18 | **Rich text rendering** | graphics/text | Multi-color, inline icons, text effects. |
| 19 | **Entity query optimization** | entity | Performance for large entity counts. |
| 20 | **IK solver** | spine | Essential for skeletal animation. |

---

## Modules to Consider Moving to Tier 3 (Lunasome)

These Tier 2 modules have minimal Rust dependencies and could be pure-Lua libraries:

| Module | Current | Suggested | Rationale |
|---|---|---|---|
| `pipeline` | Tier 2 | Tier 3 | No Rust dependencies. DAG scheduling is pure data structure work. |
| `minimap` | Tier 2 | Tier 3 | CPU-only data model. Grid + colors + fog = pure Lua. |
| `dataframe` | Tier 2 | Maybe Tier 3 | Columnar ops could be Lua. But Rust gives performance. Keep if datasets are large. |

---

## Per-Module Priority Ranking

Summary of improvement priority for each module (how urgently it needs work):

| Priority | Modules |
|---|---|
| **HIGH** | raycaster, network, graphics, physics, input, spine |
| **MEDIUM-HIGH** | animation, tilemap, gui, entity, engine |
| **MEDIUM** | audio, image, camera, scene, ai, pathfinding, procgen, terminal, serial, thread, fx |
| **MEDIUM-LOW** | data, compute, graph, filesystem, savegame, modding, light |
| **LOW** | timer, window, event, automation, minimap, dataframe, pipeline |

---

## Summary

Luna2D has an impressive breadth of **38 modules** — far more than any comparable 2D Lua engine. The main strategic concerns are:

1. **Breadth over depth**: Some modules (spine, modding, pipeline) are thin. Focus on making existing modules production-ready before adding new ones.
2. **Raycaster gap**: The raycaster has features in Rust that aren't Lua-exposed. This is the easiest, highest-ROI fix.
3. **Developer workflow**: Hot reload and input action mapping are the two biggest quality-of-life gaps.
4. **Professional asset pipeline**: Tiled import and texture atlas support would connect Luna2D to standard game development workflows.
5. **Module consolidation**: Merging data+compute, considering spine→animation, and moving pipeline to Tier 3 would reduce complexity.
6. **Protect differentiators**: AI, automation, modding, savegame, terminal, and raycaster are genuinely unique. Don't neglect them.
