# `scene` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.scene` |
| **Source** | `src/scene/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The scene module owns the Rust-side state model for scene flow. It exists so games can push, pop, replace, and query scenes through one consistent stack abstraction while leaving the actual scene tables and lifecycle callback execution in the Lua API layer.

Its boundary is intentionally narrow: `SceneStack` tracks IDs, registry entries, shared data keys, and active transition timing, while `DepthSorter` provides a per-frame helper for ordering scene-related draw callbacks. It does not own scene content, entity storage, or renderer-specific transition visuals; those stay in Lua or in the systems the scenes call into.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.scene.* (Lua API — src/lua_api/scene_api.rs)
    |
    v
src/scene/mod.rs
    |- depth_sorter.rs - depth_sorter
    |- render.rs - render
    |- stack.rs - stack
    |- transition.rs - transition
```

---

## Source Files

| File | Purpose |
|------|---------|
| `depth_sorter.rs` | Per-frame depth-ordered callback batcher used by the Lua scene layer. |
| `mod.rs` | Module root and re-export surface for the stack, transition, and depth-sorting types. |
| `render.rs` | Empty render-command and simple CPU-image helpers so `SceneStack` fits shared engine interfaces. |
| `stack.rs` | Scene stack, registry, shared-data bookkeeping, and transition state ownership. |
| `transition.rs` | Transition-type enum plus active transition progress and timer logic. |

---

## Submodules

### `scene::depth_sorter`

Per-frame depth-ordered callback batcher used by the Lua scene layer.

- **`DepthEntry`** (struct): Entry in the depth-sorted draw queue.
- **`DepthSorter`** (struct): Per-frame depth-sorted draw batcher.

### `scene::render`

Empty render-command and simple CPU-image helpers so `SceneStack` fits shared engine interfaces.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `scene::stack`

Scene stack, registry, shared-data bookkeeping, and transition state ownership.

- **`SceneId`** (type): Unique identifier for a scene in the stack.
- **`SceneStack`** (struct): The scene stack manages a LIFO stack of scene references.

### `scene::transition`

Transition-type enum plus active transition progress and timer logic.

- **`TransitionType`** (enum): Visual transition types between scenes.
- **`ActiveTransition`** (struct): Active transition state tracking progress between two scenes.

---

## Key Types

### Public Types

#### `SceneId`

Stable integer identifier used by the Rust stack while Lua owns the actual scene tables.

#### `SceneStack`

Main scene-flow owner for stack order, registry lookups, stored data keys, and active transition state.

#### `TransitionType`

Enum for no transition, fade, and slide directions.

#### `ActiveTransition`

Timer and progress record for one transition in flight.

#### `DepthSorter`

Per-frame sorter for scene draw callbacks or scene objects.

#### `DepthEntry`

Individual depth-sorted entry stored inside `DepthSorter`.

---

## Lua API

Exposed under `lurek.scene.*` by `src/lua_api/scene_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.scene.push` | Pushes a scene table onto the stack with an optional transition. |
| `lurek.scene.pop` | Pops the top scene from the stack with an optional transition. |
| `lurek.scene.switchTo` | Replaces the top scene with a new one, calling leave and enter callbacks. |
| `lurek.scene.clear` | Clears all scenes from the stack, calling leave on each. |
| `lurek.scene.popTo` | Pops scenes until the named scene is on top, calling leave on each removed. |
| `lurek.scene.update` | Updates the top scene and any active transition (legacy name; prefer `process`). |
| `lurek.scene.process` | Calls `scene:ready(self)` on the top scene if not yet fired, then `scene:process(dt)`. |
| `lurek.scene.processPhysics` | Calls `scene:process_physics(dt)` on the topmost scene (fixed timestep). |
| `lurek.scene.processLate` | Calls `scene:process_late(dt)` on the topmost scene (after process, before render). |
| `lurek.scene.draw` | Draws all scenes in the stack from bottom to top (legacy name; prefer `render`). |
| `lurek.scene.render` | Draws all scenes in the stack from bottom to top. |
| `lurek.scene.renderUi` | Draws UI overlay for all scenes in the stack from bottom to top. |
| `lurek.scene.getStackSize` | Returns the number of scenes on the stack. |
| `lurek.scene.isEmpty` | Returns true if the scene stack is empty. |
| `lurek.scene.getCurrent` | Returns the current top scene table, or nil if the stack is empty. |
| `lurek.scene.isTransitioning` | Returns true if a scene transition is currently active. |
| `lurek.scene.getTransitionProgress` | Returns the transition progress from 0.0 to 1.0. |
| `lurek.scene.registerScene` | Registers a scene table by name for later retrieval. |
| `lurek.scene.getRegistered` | Returns a registered scene table by name, or nil if not found. |
| `lurek.scene.hasRegistered` | Returns true if a scene is registered under the given name. |
| `lurek.scene.unregisterScene` | Removes a scene from the registry by name. |
| `lurek.scene.getRegisteredNames` | Returns a list of all registered scene names. |
| `lurek.scene.setData` | Stores a value in the inter-scene data store under the given key. |
| `lurek.scene.getData` | Returns a value from the inter-scene data store, or nil if not found. |
| `lurek.scene.hasData` | Returns true if the given key exists in the data store. |
| `lurek.scene.removeData` | Removes a value from the inter-scene data store by key. |
| `lurek.scene.newDepthSorter` | Creates a new DepthSorter for z-ordered draw batching. |
| `lurek.scene.new` | Creates a scene instance directly from a methods table. |
| `lurek.scene.define` | Creates a reusable scene class — returns a zero-argument constructor function. |

### `DepthSorter` Methods

| Method | Description |
|--------|-------------|
| `depthsorter:add(...)` | Registers a draw callback at the given depth layer. |
| `depthsorter:addObject(...)` | Registers a table object with a draw method at the given depth. |
| `depthsorter:sort(...)` | Sorts all registered callbacks by depth ascending. |
| `depthsorter:flush(...)` | Calls all draw callbacks in sorted depth order, then clears. |
| `depthsorter:clear(...)` | Removes all registered callbacks without calling them. |
| `depthsorter:getCount(...)` | Returns the number of registered draw entries. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.scene.
if lurek.scene then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 1 |
| `fn` (Lua API) | 35 |
| **Total** | **40** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/scene/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
