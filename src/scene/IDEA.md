# IDEA.md — `scene` module

> Migrated from `ideas/features/scene.md` + `ideas/performance/21-gui-scene-events.md`.
> Status checked against `src/scene/` and `src/lua_api/scene_api.rs`.
> Lua namespace: `lurek.scene`.

---

## Features

### ✅ DONE — Scene Stack (Push / Pop / Switch)
**Source**: features/scene.md — Summary

`lurek.scene.push(scene)`, `pop()`, `switch(scene)` implemented.

---

### ✅ DONE — Scene Lifecycle Callbacks
**Source**: features/scene.md — Summary

`enter`, `exit`, `update`, `draw`, `pause`, `resume` callbacks implemented.

---

### ✅ DONE — Named Scene Registry
**Source**: features/scene.md — Summary

`lurek.scene.register(name, scene)` → `lurek.scene.push(name)` by string.

---

### ✅ DONE — Scene Transitions (Fade / Slide / Custom)
**Source**: features/scene.md — Summary

Basic transitions implemented.

---

### ✅ DONE — Scene Data Passing
**Source**: features/scene.md — Summary

Data table passed between scenes on push/switch.

---

### ✅ DONE — Stack Introspection
**Source**: features/scene.md — Summary

`lurek.scene.current()`, `lurek.scene.depth()`, `lurek.scene.list()`.

---

### ✅ DONE — Parallel Scene Updates (Overlay Mode)
**Source**: features/scene.md — Feature Gaps #1 / Suggestions #2

`lurek.scene.pushOverlay(scene)` implemented.  The background scene continues to
receive `process`, `process_physics`, `process_late`, and `render` callbacks every
frame.  `pause` / `resume` are NOT called on the underlying scene.
`lurek.scene.isOverlay()` returns `true` when the top scene is an overlay.
`lurek.scene.getActiveScenes()` returns all active scene tables (all when overlays
are present, top-only otherwise).

Domain: `src/scene/stack.rs` — `push_overlay()`, `is_overlay()`, `get_active_ids()`.
Lua API: `src/lua_api/scene_api.rs` — `pushOverlay`, `isOverlay`, `getActiveScenes`.
Tests: `tests/lua/unit/test_scene_overlay.lua`.

---

### ✅ DONE — Built-In Transition Library
**Source**: features/scene.md — Feature Gaps #2 / Suggestions #3

`lurek.scene.transitions` subtable added with four factory functions:
- `lurek.scene.transitions.fade(duration?)` — cross-dissolve
- `lurek.scene.transitions.slide(direction?, duration?)` — directional slide
- `lurek.scene.transitions.wipe(duration?)` — wipe/curtain
- `lurek.scene.transitions.iris(duration?)` — circular iris reveal

Each factory returns `{type: string, duration: number}` compatible with the
existing `push`/`switchTo`/`pop` transition parameters.

Lua API: `src/lua_api/scene_api.rs` — `transitions` subtable.
Tests: `tests/lua/unit/test_scene_transitions.lua`.

---

### ✅ DONE — Scene Preloading
**Source**: features/scene.md — Feature Gaps #4 / Suggestions #4

`lurek.scene.preload(name, fn)` registers a loader function for a named scene.
The loader is called once (lazily) when `lurek.scene.pushPreloaded(name)` is
first invoked for that name, reducing startup hitch.
`lurek.scene.isPreloaded(name)` returns `true` once the loader has been called.

Lua API: `src/lua_api/scene_api.rs` — `preload`, `isPreloaded`, `pushPreloaded`.
Tests: `tests/lua/unit/test_scene_preload.lua`.

---

### 🤔 CONSIDER — Move DepthSorter to `render` Module
**Source**: features/scene.md — Structural Issues

`DepthSorter` (z-order sorting for draw calls) is a rendering primitive living inside
the scene module. It should be in `render` or `camera`. Move requires Architect review.

---

### 🤔 CONSIDER — Unify Scene Transitions with `effect` Module
**Source**: features/scene.md — Structural Issues

Scene transitions (fade, slide) duplicate visual effects already in `lurek.fx`.
Consider delegating transition rendering to the effect module.
