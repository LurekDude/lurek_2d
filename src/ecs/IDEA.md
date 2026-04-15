# IDEA.md — `ecs` module

> Migrated from `ideas/features/entity.md` and `ideas/performance/18-entity-ecs-queries.md`.
> Status checked against `src/ecs/` and `src/lua_api/ecs_api.rs`.
> Lua API lives under `lurek.ecs` (Universe userdata).

---

## Features

### ✅ DONE — Component Exclusion Queries (`queryNot`)
**Source**: features/entity.md — Feature Gaps #1

`queryNot(with, without)` implemented in `ecs_api.rs` (line ~517). Entities with required
components but excluding listed components.

---

### ✅ DONE — System Priority Ordering
**Source**: features/entity.md — Feature Gaps #6

`addSystem(system, {priority=N})` implemented in `ecs_api.rs` (line ~135). Systems execute
in priority order (lower = earlier).

---

### ✅ DONE — Entity Serialization / Deserialization
**Source**: features/entity.md — Feature Gaps #3

`serialize()` and `deserialize(snapshot)` implemented in `ecs_api.rs` (lines ~528–540).
Snapshot of all alive entities to Lua table, loadable back.

---

### ✅ DONE — Component Change Observers (`onComponentAdded`)
**Source**: features/entity.md — Feature Gaps #2

`onComponentAdded(name, cb)` found in `ecs_api.rs` (line ~544). Observer callbacks keyed
by component name exist for add events (`add_observers`, `remove_observers` fields).

---

### ✅ DONE — Blueprint Overrides at Spawn Time
**Source**: features/entity.md — Feature Gaps #7

`spawn_blueprint(name, overrides)` and `extend_blueprint(name, parent, overrides)` both
implemented in `ecs_api.rs` (lines ~431, ~445). `spawnBulk` with overrides also present.

---

### ❌ TODO — Relationship Manager Lua Exposure
**Source**: features/entity.md — Feature Gaps #4

`src/ecs/relationships.rs` exists but no `addRelation`, `getRelated`, or similar API found
in `ecs_api.rs`. Relationships (ownership, social graphs, formations) are usable only from
Rust. Expose to Lua.

---

### ❌ TODO — Component Removed Observer
**Source**: features/entity.md — Feature Gaps #2 (partial)

`remove_observers` field exists in `ecs_api.rs` but no `onComponentRemoved()` Lua binding
was found. Check whether it is registered and document, or implement.

---

### 🔇 LOW — Sparse Set / Archetype Iteration
**Source**: features/entity.md — Feature Gaps #8 / performance/18-entity-ecs-queries.md

Lua-table-oriented components mean no memory layout optimization. For the target audience
(indie / <10k entities) this is acceptable. If profiling reveals iteration as a bottleneck,
investigate archetype groups or sparse-set iteration. Do not optimize prematurely.
