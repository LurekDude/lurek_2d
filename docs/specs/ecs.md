# `ecs` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.ecs` |
| **Source** | `src/ecs/` |
| **Rust Tests** | none found under `tests/` with `ecs` in the path |
| **Lua Tests** | none found under `tests/` with `ecs` in the path |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `ecs` module owns Lurek2D's lightweight entity world and related relationship utilities. Its main job is to create and destroy entities safely, store arbitrary component data in Lua-owned tables, track tags and layers, manage parent-child hierarchies, define blueprints, and dispatch registered systems in a controlled order.

This module exists to give Lua game code a flexible property-bag ECS rather than a rigid Rust archetype ECS. `Universe` handles identity, lifecycle, and indexing concerns while leaving component schemas dynamic. That makes it suitable for script-heavy gameplay code where components and systems evolve quickly and where entity data needs to remain easy to inspect and modify from Lua.

The module intentionally does not own rendering, physics simulation, scene transitions, or specialized gameplay logic. It can store data for those systems and dispatch systems that act on that data, but it does not define how a sprite, collider, or scene should behave. The separate relationship types also do not model gameplay semantics by themselves; they only provide a reusable container for pairwise relation values and named levels.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.ecs.* (Lua API — src/lua_api/ecs_api.rs)
    |
    v
src/ecs/mod.rs
    |- relationships.rs - relationships
    |- universe.rs - universe
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Declares the ECS submodules and re-exports the main world and relationship types. |
| `relationships.rs` | Defines reusable relationship types and the `RelationshipManager` for symmetric pairwise values and named relation levels. |
| `universe.rs` | Defines `Universe`, including generational entity IDs, component storage via Lua registry tables, tags, layers, blueprints, hierarchy management, and ordered system dispatch. |

---

## Submodules

### `ecs::relationships`

Defines reusable relationship types and the `RelationshipManager` for symmetric pairwise values and named relation levels.

- **`RelationType`** (struct): Definition of a named relation type with a fixed set of valid level strings.
- **`Relationship`** (struct): A relationship between two entities: numeric value plus per-type named levels.
- **`RelationshipManager`** (struct): Manages all relation types and the per-pair relationship records.

### `ecs::universe`

Defines `Universe`, including generational entity IDs, component storage via Lua registry tables, tags, layers, blueprints, hierarchy management, and ordered system dispatch.

- **`Universe`** (struct): A self-contained ECS world.

---

## Key Types

### Public Types

#### `Universe`

The main ECS world object that owns entity lifecycle, component storage, tags, layers, blueprints, parent-child links, and registered systems.

#### `RelationshipManager`

A standalone manager for pairwise entity relationships that is separate from `Universe` but often complements ECS-driven gameplay.

#### `Relationship`

The stored record for one normalized entity pair, including a numeric value and per-type named levels.

#### `RelationType`

The definition of one named relationship category and its allowed level strings.

---

## Lua API

Exposed under `lurek.ecs.*` by `src/lua_api/ecs_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.ecs.newUniverse` | Creates a new empty ECS universe. |

### `Universe` Methods

| Method | Description |
|--------|-------------|
| `universe:spawn(...)` | Creates a new entity and returns its packed ID. |
| `universe:kill(...)` | Destroys the entity with the given ID, freeing its slot for reuse. |
| `universe:isAlive(...)` | Returns true if the entity ID is currently alive. |
| `universe:set(...)` | Sets a component value on an entity. |
| `universe:get(...)` | Returns the component value for an entity, or nil if missing. |
| `universe:has(...)` | Returns true if the entity has the named component. |
| `universe:remove(...)` | Removes a component from an entity. |
| `universe:getComponents(...)` | Returns all component names for an entity. |
| `universe:query(...)` | Returns entity IDs that have all listed component names. |
| `universe:each(...)` | Calls callback(id, value) for every entity with the named component. |
| `universe:getEntities(...)` | Returns all alive entity IDs. |
| `universe:getEntityCount(...)` | Returns the number of alive entities. |
| `universe:addSystem(...)` | Adds a system table to the universe. |
| `universe:removeSystem(...)` | Removes a system table from the universe. |
| `universe:update(...)` | Calls update(system, world, dt) on each registered system. |
| `universe:render(...)` | Calls render(system, world) on each registered system. |
| `universe:emit(...)` | Emits a named event to all systems that implement the handler. |
| `universe:getSystemCount(...)` | Returns the number of registered systems. |
| `universe:clear(...)` | Removes all entities, components, tags, layers, and systems. Blueprints are preserved. |
| `universe:release(...)` | Releases all universe state, equivalent to clear. |
| `universe:addTag(...)` | Attaches a string tag to an entity. |
| `universe:removeTag(...)` | Removes a string tag from an entity. |
| `universe:hasTag(...)` | Returns true if the entity carries the given tag. |
| `universe:getTags(...)` | Returns all string tags for an entity. |
| `universe:getEntitiesByTag(...)` | Returns all alive entities with the given string tag. |
| `universe:setLayer(...)` | Sets the layer for an entity. |
| `universe:getLayer(...)` | Returns the layer for an entity, defaulting to zero. |
| `universe:getEntitiesByLayer(...)` | Returns all alive entities on a specific layer. |
| `universe:getEntitiesSorted(...)` | Returns all alive entities sorted by layer then ID. |
| `universe:defineTag(...)` | Defines a bitmap tag name, returning its bit index. |
| `universe:bitmapTag(...)` | Adds a bitmap tag to an entity. |
| `universe:bitmapUntag(...)` | Removes a bitmap tag from an entity. |
| `universe:hasBitmapTag(...)` | Returns true if the entity has the given bitmap tag. |
| `universe:queryBitmapTag(...)` | Returns all alive entities with the given bitmap tag. |
| `universe:queryBitmapAny(...)` | Returns all alive entities with any of the listed bitmap tags. |
| `universe:queryBitmapAll(...)` | Returns all alive entities with all of the listed bitmap tags. |
| `universe:getBitmapTagBit(...)` | Returns the bit index for a bitmap tag name, or nil if undefined. |
| `universe:hasBlueprint(...)` | Returns true if a blueprint with the given name exists. |
| `universe:removeBlueprint(...)` | Removes a blueprint definition. |
| `universe:listBlueprints(...)` | Returns all defined blueprint names. |
| `universe:getBlueprintComponents(...)` | Returns a deep copy of a blueprint's component table, or nil. |
| `universe:getParent(...)` | Returns the parent entity ID, or nil if unparented. |
| `universe:getChildren(...)` | Returns all direct child entity IDs. |
| `universe:killRecursive(...)` | Kills an entity and all its descendants recursively. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.ecs.
if lurek.ecs then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 0 |
| `fn` (Lua API) | 45 |
| **Total** | **49** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/ecs/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
