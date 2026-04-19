# IDEA.md — `scene` module

| Field       | Value        |
| ----------- | ------------ |
| Module      | `scene`      |
| Path        | `src/scene/` |
| Date        | 2026-04-18   |
| Plugin Tier | CORE-KEEP    |

---

## Mission Summary

LIFO scene stack with lifecycle callbacks, animated transitions (fade, slide,
wipe, iris, zoom, crossfade), easing curves, overlay mode, named registry,
inter-scene data passing, and a `DepthSorter` for z-ordered draw batching.

## Existing Strengths

- Clean separation: Rust domain holds IDs + transition state; Lua owns scene
  tables and callbacks (`enter`, `leave`, `pause`, `resume`, `update`, `draw`).
- 10 transition types with 6 easing curves — rich out-of-the-box scene flow.
- Overlay mode: non-pausing scenes layered on top of active backgrounds.
- `DepthSorter` with three sort paths: comparison (default), radix (256+
  integral entries), and rayon parallel (10 000+ entries).
- Dirty-flag optimization: `sorted_entries()` is free when no entries added.
- Named scene registry + inter-scene data store.
- Existing test coverage is extensive (render.rs, stack.rs, transition.rs,
  depth_sorter.rs all have inline `#[cfg(test)]` modules).

## Gap List

1. `DepthSorter` lives in scene but is a rendering primitive — arguably
   belongs in `render` or `camera`.
2. Transition rendering duplicates visual effects already in `effect` module.
3. No queued transition chaining (push transition → on complete → push next).
4. `render.rs` returns empty vecs — scene GPU rendering is 100% Lua-driven.
5. No scene preloading / background loading hooks.

## Feature Ideas

1. **Transition Chaining / Sequencer** — Queue multiple transitions to fire
   in sequence. LOVE2D's `hump.gamestate` chains are the reference pattern.
2. **Scene Groups / Layers** — Named groups of scenes that update in parallel
   (e.g. "ui" group + "world" group). Godot's Viewport / SubViewport model
   is a reference.
3. **Background Scene Loading** — Hook into `thread` module for async scene
   preparation before `enter()`. Defold's collection proxies provide this.

## Perf/Quality Ideas

- Benchmark `DepthSorter` radix path at 1 000 / 10 000 / 100 000 entries.
- Profile `get_active_ids()` allocation when overlay mode is active every frame.
- Consider pre-allocating `DepthSorter.entries` to a typical frame count.

## Test Coverage Gaps

- All files have inline tests (depth_sorter, render, stack, transition).
- Missing: overlay interaction stress test (push 10+ overlays, verify active
  IDs list and pop-order correctness).
- Missing: transition easing at boundary values (NaN, negative duration).

## TODO(dedup): scene ↔ ecs overlap

- `SceneStack` is a parallel LIFO ID system to `Universe` entity hierarchy.
  Evaluate whether scenes should be entities with a `"scene"` component.
- `DepthSorter` and `Universe::get_entities_sorted()` both order by depth/layer
  — consider a shared `DepthPipeline` abstraction.

## TODO(dedup): scene ↔ effect transitions

- Scene `TransitionType` (fade, wipe, iris, zoom) overlaps conceptually with
  `effect` module post-processing. Consider delegating transition rendering
  to the effect pipeline and having scene only drive the timing.

## TODO(helper):

- `bounce_out()` helper in `transition.rs` is a general easing utility —
  consider moving to `src/math/easing.rs` alongside tween easing curves.

## TODO(plugin):

- Scene stack is CORE-KEEP — not a plugin candidate.

## References

- `docs/specs/scene.md`
- `src/lua_api/scene_api.rs`
- LOVE2D hump.gamestate: https://github.com/vrld/hump
- Godot SceneTree: https://docs.godotengine.org/en/stable/classes/class_scenetree.html
- Defold collection proxies: https://defold.com/manuals/collection-proxy/ckgrounds.
- `DepthSorter` with three sort paths: comparison (default), radix (256+
  integral entries), and rayon parallel (10 000+ entries).
- Dirty-flag optimization: `sorted_entries()` is free when no entries added.
- Named scene registry + inter-scene data store.
- Existing test coverage is extensive (render.rs, stack.rs, transition.rs,
  depth_sorter.rs all have inline `#[cfg(test)]` modules).

## Gap List

1. `DepthSorter` lives in scene but is a rendering primitive — arguably
   belongs in `render` or `camera`.
2. Transition rendering duplicates visual effects already in `effect` module.
3. No queued transition chaining (push transition → on complete → push next).
4. `render.rs` returns empty vecs — scene GPU rendering is 100% Lua-driven.
5. No scene preloading / background loading hooks.

## Feature Ideas

1. **Transition Chaining / Sequencer** — Queue multiple transitions to fire
   in sequence. LOVE2D's `hump.gamestate` chains are the reference pattern.
2. **Scene Groups / Layers** — Named groups of scenes that update in parallel
   (e.g. "ui" group + "world" group). Godot's Viewport / SubViewport model
   is a reference.
3. **Background Scene Loading** — Hook into `thread` module for async scene
   preparation before `enter()`. Defold's collection proxies provide this.

## Perf/Quality Ideas

- Benchmark `DepthSorter` radix path at 1 000 / 10 000 / 100 000 entries.
- Profile `get_active_ids()` allocation when overlay mode is active every frame.
- Consider pre-allocating `DepthSorter.entries` to a typical frame count.

## Test Coverage Gaps

- All files have inline tests (depth_sorter, render, stack, transition).
- Missing: overlay interaction stress test (push 10+ overlays, verify active
  IDs list and pop-order correctness).
- Missing: transition easing at boundary values (NaN, negative duration).

## TODO(dedup): scene ↔ ecs overlap

- `SceneStack` is a parallel LIFO ID system to `Universe` entity hierarchy.
  Evaluate whether scenes should be entities with a `"scene"` component.
- `DepthSorter` and `Universe::get_entities_sorted()` both order by depth/layer
  — consider a shared `DepthPipeline` abstraction.

## TODO(dedup): scene ↔ effect transitions

- Scene `TransitionType` (fade, wipe, iris, zoom) overlaps conceptually with
  `effect` module post-processing. Consider delegating transition rendering
  to the effect pipeline and having scene only drive the timing.

## TODO(helper):

- `bounce_out()` helper in `transition.rs` is a general easing utility —
  consider moving to `src/math/easing.rs` alongside tween easing curves.

## TODO(plugin):

- Scene stack is CORE-KEEP — not a plugin candidate.

## References

- `docs/specs/scene.md`
- `src/lua_api/scene_api.rs`
- LOVE2D hump.gamestate: https://github.com/vrld/hump
- Godot SceneTree: https://docs.godotengine.org/en/stable/classes/class_scenetree.html
- Defold collection proxies: https://defold.com/manuals/collection-proxy/
