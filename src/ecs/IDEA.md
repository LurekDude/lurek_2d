# IDEA.md — `ecs` module

| Field       | Value      |
| ----------- | ---------- |
| Module      | `ecs`      |
| Path        | `src/ecs/` |
| Date        | 2026-04-18 |
| Plugin Tier | CORE-KEEP  |

---

## Mission Summary

Lightweight entity-component-system with generational ID recycling, Lua-table
components, string and bitmap tags, layers, parent-child hierarchy, blueprints,
ordered system dispatch, and relationship management. Targets <10 000 entities
at 60 FPS on integrated GPUs.

## Existing Strengths

- Generational packed IDs (8-bit gen + 24-bit slot) prevent stale-handle bugs.
- Dual tag systems: string tags (flexible) + bitmap tags (O(1) multi-tag queries).
- Inverted tag index for O(1) `get_entities_by_tag`.
- Blueprint and extend-blueprint system with deep-copy and override merge.
- Ordered system dispatch with priority sorting.
- Serialization/deserialization round-trip to Lua tables (save/load).
- `RelationshipManager` provides symmetric values + named levels + directed links.
- `query_not()` and `query_bitmap_any/all` cover common ECS filter patterns.
- Observer events (component-add/remove) for reactive systems.

## Gap List

1. No archetype or sparse-set storage — all components live in Lua tables,
   which limits cache locality for very large entity counts.
2. No multi-component query batching (each `query()` iterates all alive entities).
3. No built-in system scheduling (single ordered list, no dependencies or phases).
4. `get_entities_by_tag` returns a `Vec` clone every call — could return an iterator.
5. No world diff/change-detection beyond the add/remove observer events.
6. `universe.rs` is >1 500 lines — consider splitting into sub-files.

## Feature Ideas

1. **Archetype Grouping** — Group entities by component signature for cache-friendly
   iteration. LOVE2D ECS libraries (Concord, Tiny-ECS) use archetype groups.
   Bevy's archetype-based storage proves the pattern at scale.
2. **System Phases / Scheduling Graph** — Let systems declare dependencies and run
   in topological order. Bevy's `SystemSet` and Godot's `_physics_process` /
   `_process` split are references.
3. **World Snapshots / Rollback** — Extend `serialize_to_table` with incremental
   snapshots for rollback netcode. Defold's `go.get`/`go.set` + collection proxies
   hint at the pattern.

## Perf/Quality Ideas

- Benchmark `query()` with 10 000 entities and 5 component names — if >1 ms,
  consider sparse-set fast-path.
- Profile `tag_index` maintenance cost during bulk `kill()` calls.
- Consider `SmallVec` for the free-list and tag lists (typical size <16).

## Test Coverage Gaps

- `universe.rs` has NO inline tests (all tested via Lua harness). Pure-Rust
  tests now in sibling `universe_tests.rs` cover pack_id, spawn, tags, layers,
  hierarchy.
- `relationships.rs` tests added this session.
- Component, blueprint, and system operations need Lua harness coverage
  (registered in `tests/lua/harness.rs`).

## TODO(dedup): ecs ↔ scene overlap

- `SceneStack` and `Universe` both manage hierarchical object lifecycles.
  Consider whether scene-graph nodes should be entities with a `scene`
  component rather than a parallel ID space.
- `DepthSorter` (scene) and `get_entities_sorted` (ecs) both do layer-based
  ordering — evaluate unifying into a single depth pipeline.

## TODO(helper):

- Extract `deep_copy_table` into a shared `src/data/lua_helpers.rs` — it is
  a general utility used by ecs, save, and potentially scene.
- `pack_id` / `unpack_slot` / `unpack_gen` could be a shared `GenerationalId`
  type usable by other modules (animation handles, pool IDs).

## TODO(plugin):

- ECS is CORE-KEEP — not a plugin candidate. If archetype storage is added,
  keep it behind a Cargo feature flag for opt-in.

## References

- `docs/specs/ecs.md`
- `src/lua_api/ecs_api.rs`
- `tests/lua/unit/test_ecs.lua` (if present)
- Bevy ECS: https://bevyengine.org/learn/book/getting-started/ecs/
- Concord (LOVE2D ECS): https://github.com/Tjakka5/Concord
