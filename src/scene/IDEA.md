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

### ❌ TODO — Parallel Scene Updates (Overlay Mode)
**Source**: features/scene.md — Feature Gaps #1 / Suggestions #2

Top scene only receives update/draw. A pause overlay can't let the background world
continue running. Suggested API:
```lua
lurek.scene.pushOverlay(pauseScene)
-- paused scene still calls update, draws underneath
```

---

### ❌ TODO — Built-In Transition Library
**Source**: features/scene.md — Feature Gaps #2 / Suggestions #3

No pre-built transition effects. Must implement manually. Suggested:
`lurek.scene.transitions.fade`, `.slide`, `.wipe`, `.iris`

---

### ❌ TODO — Scene Preloading
**Source**: features/scene.md — Feature Gaps #4 / Suggestions #4

No async resource loading before scene enters. Potential loading hitch on heavy scenes.
```lua
lurek.scene.preload(sceneName, function() lurek.gfx.newImage("big_map.png") end)
```

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
