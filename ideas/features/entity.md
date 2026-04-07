# entity — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/entity.md`
**Files**: ECS (Entity-Component-System)

## Purpose

Entity management system with generational IDs, component storage, parent-child hierarchies, blueprints, and system scheduling. Luna2D's ECS is Lua-table-oriented rather than archetype-based.

## Current Feature Summary

- `Universe` manages all entities via generational IDs (index + generation for safe invalidation)
- Components stored as Lua tables — no static typing
- Blueprints: named entity templates for batch creation
- Parent-child hierarchy with automatic cleanup
- Tags: zero-data markers for filtering
- Systems: named update functions called on matching component sets
- `RelationshipManager`: tracks entity relationships (not exposed to Lua yet)
- Entity iteration with component-based queries
- Group operations: destroy all with tag, get all with components

## Feature Gaps

1. **No component exclusion queries**: Can query "all entities with Health AND Position" but not "all entities with Health but NOT Dead." Exclusion filtering is standard ECS.
2. **No component change observers**: No way to react when a component is added, removed, or modified. Must poll each frame.
3. **No entity serialization**: Can't save/load entity state to disk. Must manually marshal components.
4. **RelationshipManager not Lua-exposed**: `RelationshipManager` exists in Rust but users can't define entity relationships from Lua. Wasted potential.
5. **No component pools/archetypes**: Components are Lua tables — no memory layout optimization. Fine for <10k entities; poor for large simulations.
6. **No system ordering/priority**: Systems run in registration order. No explicit priority or dependency graph.
7. **No entity prefabs with overrides**: Blueprints create entities from templates but can't override individual fields at creation time easily.
8. **No sparse set iteration**: Iteration visits all entities, not just those with matching components. O(n) scan vs O(k) sparse set.

## Structural Issues

- **Lua-table components vs typed components**: Design choice to use Lua tables means flexibility but no type safety or performance optimization. This is fine for Luna2D's target audience (indie/hobbyist) but limits scale.
- **Systems are simple**: Systems are just named functions — no query builders, no exclusive/shared access, no parallelism. Compared to Bevy's ECS this is very basic.
- **Clean module boundary**: Entity correctly doesn't import physics, graphics, etc. Components are user-defined.

## Suggestions

1. **Expose RelationshipManager to Lua**: `entity:addRelation(other, type)` / `entity:getRelated(type)` — enables social graphs, ownership chains, formation groups.
2. **Add component exclusion**: `universe:queryNot({"Health"}, {"Dead"})` — entities with Health but not Dead.
3. **Add entity serialization**: `universe:serialize()` → table that can be saved/loaded. Critical for save systems.
4. **Add change observers**: `universe:onComponentAdded("Health", fn)` / `universe:onComponentRemoved(...)` — reactive patterns.
5. **Add blueprint overrides**: `universe:spawn("enemy", {health=200, speed=3})` — create from blueprint with field overrides.
6. **Add system priority**: `universe:addSystem("render", fn, {priority=10, after="physics"})`.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| ECS | ✅ (Lua tables) | ❌ | ❌ (display tree) | ✅ (full archetype) |
| Generational IDs | ✅ | N/A | N/A | ✅ |
| Blueprints | ✅ | N/A | ❌ | ✅ (prefabs) |
| Parent-child | ✅ | N/A | ✅ | ✅ |
| Change detection | ❌ | N/A | ❌ | ✅ |
| Query exclusion | ❌ | N/A | N/A | ✅ |
| Serialization | ❌ | N/A | ❌ | ✅ (reflect) |
| System ordering | ❌ | N/A | N/A | ✅ |

## Priority

**MEDIUM** — Entity is usable. Exposing RelationshipManager, adding serialization, and component exclusion queries are the most impactful improvements. The Lua-table component model is a conscious design trade-off.
