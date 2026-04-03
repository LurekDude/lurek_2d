# `entity` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.entity` |
| **Source** | `src/entity/` |
| **Tests** | `tests/entity_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_entity.lua` |

## Summary

The entity module provides the identity and lifecycle layer for Luna2D's
entity system.  Rust tracks entity IDs and their alive/dead status using a
generational index scheme: each slot carries a generation counter that
increments when the slot is recycled, so a stale entity ID from a destroyed
entity is detected at the Rust boundary before it can corrupt component data.
Component storage itself lives entirely in Lua tables indexed by entity ID —
there are no Rust component types — giving game scripts the flexibility to use
arbitrary duck-typed components without any schema registration.

This hybrid design gives the best of both worlds: Rust enforces ID validity
(use-after-free is caught with a clear error message rather than silently
accessing the wrong entity's data) while Lua retains the freedom to attach any
field to any entity at any time, even mid-game, without modifying any Rust
code.  The `EntityWorld` Rust struct is intentionally minimal — it is a
validity guard and iteration source, not a monolithic ECS framework.

## Architecture

```
Universe (ECS container)
  │
  ├── Entity lifecycle
  │     ├── spawn() → u64 ID (recycled from free_list)
  │     ├── despawn() → recycles ID
  │     └── is_alive() → existence check
  │
  ├── Components ── stored as Lua RegistryKey references
  │     ├── set_component(entity, name, lua_value)
  │     ├── get_component(entity, name) → Lua value
  │     └── remove_component(entity, name)
  │
  ├── Tags ── bitmap-based (u64, max 63 unique tags)
  │     ├── add_tag / remove_tag / has_tag
  │     └── get_entities_with_tag → filtered list
  │
  ├── Layers ── named groupings for render/update ordering
  │
  ├── Blueprints ── entity templates with inheritance
  │     ├── register_blueprint(name, components)
  │     ├── spawn_from_blueprint(name) → entity with preset components
  │     └── Inheritance: child blueprint merges parent's components
  │
  └── Systems ── ordered update functions
        ├── add_system(name, callback)
        └── run_systems() → executes all in order
```

## Source Files

| File | Purpose |
|------|---------|
| `relationships.rs` | Generic relationship system for entities |
| `universe.rs` | Universe — a self-contained ECS world. Entities are u32 IDs starting at 1 |

## Submodules

### `entity::relationships`

Generic relationship system for entities.

- **`RelationType`** (struct): Definition of a named relation type with a fixed set of valid level strings.
- **`Relationship`** (struct): A relationship between two entities: numeric value plus per-type named levels.  The relationship is keyed as `(min(a,...
- **`RelationshipManager`** (struct): Manages all relation types and the per-pair relationship records.

### `entity::universe`

Universe — a self-contained ECS world.

- **`Universe`** (struct): A self-contained ECS world. Consult the module-level documentation for the broader usage context and preconditions. ...
- **`deep_copy_table`** (fn): Deep-copies a Lua table recursively. Consult the module-level documentation for the broader usage context and...

## Key Types

### Structs

#### `entity::relationships::RelationType`

Definition of a named relation type with a fixed set of valid level strings.

#### `entity::relationships::Relationship`

A relationship between two entities: numeric value plus per-type named levels.  The relationship is keyed as `(min(a,...

#### `entity::relationships::RelationshipManager`

Manages all relation types and the per-pair relationship records.

#### `entity::universe::Universe`

A self-contained ECS world. Consult the module-level documentation for the broader usage context and preconditions. ...

## Public Functions

- **`deep_copy_table()`** `universe::` — Deep-copies a Lua table recursively. Consult the module-level documentation for the broader usage context and...

## Lua API

Exposed under `luna.entity.*` by `src/lua_api/entity_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `fn` | 1 |
| `mod` | 2 |
| `struct` | 4 |
| **Total** | **7** |

