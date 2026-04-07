# `entity` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.entity`                                        |
| **Source**      | `src/entity/`                                        |
| **Rust Tests** | `tests/rust/unit/entity_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_entity.lua`                     |
| **Architecture** | —                                                  |

## Summary

The entity module provides Luna2D's lightweight entity-component-system (ECS) built around the `Universe` struct — a self-contained ECS world that manages entity lifecycle, components, tags, layers, blueprints, parent-child hierarchies, and ordered system dispatch. Entities are identified by generational packed IDs: the upper 8 bits store a generation counter and the lower 24 bits store the slot index, so a stale entity ID from a previously destroyed entity is detected at the Rust boundary before it can access wrong data. This prevents use-after-free bugs without requiring garbage collection or `unsafe` code.

Component storage is delegated entirely to Lua registry tables indexed by entity slot — there are no Rust-side component types. This hybrid design allows game scripts to attach arbitrary duck-typed data to any entity at any time without schema registration, while Rust enforces ID validity and provides efficient tag-based and component-based queries. The module also includes a generic `RelationshipManager` for tracking symmetric numeric relations and named-state levels between entity pairs, useful for diplomacy, trade, reputation, or any pairwise game mechanic.

The module intentionally avoids the archetype-based storage model used by full ECS frameworks. It is a property-bag system optimised for scripting ergonomics rather than cache-friendly batch iteration. For tight inner loops requiring maximum throughput, native Lua tables may outperform the entity API. The tagging subsystem offers two approaches: unlimited string tags with an inverted index for O(1) lookups, and bitmap tags (up to 63 per Universe) using `u64` bitmasks for fast set-intersection queries.

## Architecture

```
luna.entity.newUniverse()
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│  Universe (self-contained ECS world)                         │
│                                                              │
│  ┌─────────────────────┐   ┌──────────────────────────────┐  │
│  │ Entity Lifecycle     │   │ Component Store (Lua tables) │  │
│  │  spawn() → packed ID │   │  set_component(id, name, v) │  │
│  │  kill() → recycle    │   │  get_component(id, name)     │  │
│  │  is_alive(id)        │   │  query([names]) → [ids]      │  │
│  │  kill_recursive(id)  │   │  each(name, cb)              │  │
│  └─────────────────────┘   └──────────────────────────────┘  │
│                                                              │
│  ┌──────────────────┐   ┌─────────────────────────────────┐  │
│  │ String Tags       │   │ Bitmap Tags (u64 bitmask)      │  │
│  │  add/remove/has   │   │  defineTag → bit index         │  │
│  │  inverted index   │   │  bitmapTag / bitmapUntag       │  │
│  │  getEntitiesByTag │   │  queryBitmapAll / Any          │  │
│  └──────────────────┘   └─────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────┐   ┌─────────────────────────────────┐  │
│  │ Layers (i32)      │   │ Blueprints (template tables)   │  │
│  │  set/get layer    │   │  define / extend / spawn from  │  │
│  │  getByLayer       │   │  inheritance via deep copy     │  │
│  │  getSorted        │   │  preserved across clear()      │  │
│  └──────────────────┘   └─────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────┐   ┌─────────────────────────────────┐  │
│  │ Parent-Child      │   │ Systems (ordered callbacks)     │  │
│  │  setParent        │   │  addSystem / removeSystem      │  │
│  │  getChildren      │   │  update(dt) / draw() / emit()  │  │
│  │  killRecursive    │   │  Lua tables with named methods  │  │
│  └──────────────────┘   └─────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  RelationshipManager (standalone, not embedded in Universe)  │
│                                                              │
│  ┌──────────────────┐   ┌─────────────────────────────────┐  │
│  │ RelationType      │   │ Relationship (per-pair record) │  │
│  │  name, levels     │   │  from_id, to_id, value (f64)   │  │
│  │  default_level    │   │  type_levels: HashMap           │  │
│  └──────────────────┘   └─────────────────────────────────┘  │
│                                                              │
│  set_value / get_value / adjust_value                        │
│  set_level / get_level (named states per type)               │
│  all_relations_for(entity) / relation_count()                │
└──────────────────────────────────────────────────────────────┘
```

## Source Files

| File               | Purpose                                                                     |
|--------------------|-----------------------------------------------------------------------------|
| `mod.rs`           | Module root — declares submodules, re-exports `Universe`, `RelationType`, `Relationship`, `RelationshipManager`, `deep_copy_table` |
| `universe.rs`      | `Universe` struct — entity lifecycle, components, string/bitmap tags, layers, blueprints, parent-child, systems, `deep_copy_table` helper |
| `relationships.rs` | `RelationType`, `Relationship`, `RelationshipManager` — symmetric pair-based relations with numeric values and named-state levels |

## Submodules

### `entity::universe`

Core ECS world with generational ID recycling, components stored in Lua registry tables, dual tag systems, layer ordering, blueprint templates with inheritance, parent-child hierarchies, and ordered system dispatch.

- **`Universe`** (struct) — Self-contained ECS world managing all entity state.
- **`deep_copy_table`** (fn) — Recursively deep-copies a Lua table for blueprint snapshots.

### `entity::relationships`

Generic relationship system for tracking symmetric numeric relations and named-state levels between entity pairs. Entity pair keys are normalised as `(min(a,b), max(a,b))` so `A↔B` and `B↔A` share the same record.

- **`RelationType`** (struct) — Definition of a named relation type with valid level strings and a default level.
- **`Relationship`** (struct) — Per-pair record storing a numeric value and per-type named levels.
- **`RelationshipManager`** (struct) — Container managing type definitions and relationship records, with value/level get/set and query operations.

## Key Types

### Structs

#### `entity::universe::Universe`

Self-contained ECS world. Manages entities as packed `u32` IDs with generational recycling (upper 8 bits = generation, lower 24 bits = slot). Components are stored in Lua registry tables. Supports string tags (unlimited, with inverted index), bitmap tags (up to 63, `u64` bitmask), layers (`i32`), blueprints with inheritance, parent-child hierarchies, and an ordered system dispatch list. Lazy-initialises three Lua registry stores (components, blueprints, systems) on first use.

Key methods: `spawn`, `kill`, `kill_recursive`, `is_alive`, `set_component`, `get_component`, `has_component`, `remove_component`, `query`, `each`, `add_tag`, `get_entities_by_tag`, `define_tag`, `bitmap_tag`, `query_bitmap_all`, `query_bitmap_any`, `set_layer`, `get_entities_sorted`, `define_blueprint`, `extend_blueprint`, `spawn_blueprint`, `set_parent`, `get_children`, `add_system`, `remove_system`, `get_system_count`, `clear`.

#### `entity::relationships::RelationType`

Definition of a named relation type (e.g. `"diplomacy"`) with a fixed set of valid level strings (e.g. `["war", "neutral", "alliance"]`) and a default level. Validates in debug builds that the default level is present in the level set.

Fields: `name: String`, `levels: Vec<String>`, `default_level: String`.

#### `entity::relationships::Relationship`

A single relationship record between two entities. The pair key is normalised so `from_id <= to_id`. Stores a generic `f64` numeric value (e.g. −100 hostile to +100 allied) and a `HashMap<String, String>` of per-type named-state levels.

Fields: `from_id: u32`, `to_id: u32`, `value: f64`, `type_levels: HashMap<String, String>`.

#### `entity::relationships::RelationshipManager`

Manages a collection of `RelationType` definitions and per-pair `Relationship` records. Provides operations to define/remove relation types, get/set/adjust numeric values, get/set named levels with validation, query all relations for an entity, and iterate all records. Entity pair keys are auto-normalised via the `ordered()` helper.

Key methods: `define_type`, `remove_type`, `get_type`, `type_names`, `get_value`, `set_value`, `adjust_value`, `set_level`, `get_level`, `has_relation`, `remove_relation`, `all_relations_for`, `all_relations`, `relation_count`.

### Enums

No public enums in this module.

## Lua API

Exposed under `luna.entity.*` by `src/lua_api/entity_api.rs`. The module registers a single factory function `luna.entity.newUniverse()` that returns a `LuaUniverse` UserData object. All further operations are methods on the Universe instance.

### Factory

| Function                  | Returns    | Description                           |
|---------------------------|------------|---------------------------------------|
| `luna.entity.newUniverse()` | `Universe` | Creates a new empty ECS universe      |

### Universe Methods — Entity Lifecycle

| Method                     | Returns     | Description                                          |
|----------------------------|-------------|------------------------------------------------------|
| `universe:spawn()`        | `integer`   | Creates a new entity, returns its packed ID           |
| `universe:kill(id)`       | `nil`       | Destroys an entity, recycles its slot                 |
| `universe:isAlive(id)`    | `boolean`   | Returns true if the entity ID is currently alive      |
| `universe:killRecursive(id)` | `nil`    | Kills an entity and all descendants recursively       |
| `universe:getEntities()`  | `table`     | Returns all alive entity IDs                          |
| `universe:getEntityCount()` | `integer` | Returns the number of alive entities                  |
| `universe:clear()`        | `nil`       | Removes all entities, components, tags, layers, systems (blueprints preserved) |
| `universe:release()`      | `nil`       | Alias for `clear()`                                   |

### Universe Methods — Components

| Method                                  | Returns    | Description                                           |
|-----------------------------------------|------------|-------------------------------------------------------|
| `universe:set(id, name, value)`         | `nil`      | Sets a component value on an entity                   |
| `universe:get(id, name)`                | `any`      | Returns the component value, or nil if missing        |
| `universe:has(id, name)`                | `boolean`  | Returns true if the entity has the named component    |
| `universe:remove(id, name)`             | `nil`      | Removes a component from an entity                    |
| `universe:getComponents(id)`            | `table`    | Returns all component names for an entity             |
| `universe:query(name1, name2, ...)`     | `table`    | Returns entity IDs that have all listed components    |
| `universe:each(name, callback)`         | `nil`      | Calls `callback(id, value)` for each entity with the component |

### Universe Methods — String Tags

| Method                                | Returns    | Description                                       |
|---------------------------------------|------------|----------------------------------------------------|
| `universe:addTag(id, tag)`            | `nil`      | Attaches a string tag to an entity                  |
| `universe:removeTag(id, tag)`         | `nil`      | Removes a string tag from an entity                 |
| `universe:hasTag(id, tag)`            | `boolean`  | Returns true if the entity carries the given tag    |
| `universe:getTags(id)`                | `table`    | Returns all string tags for an entity               |
| `universe:getEntitiesByTag(tag)`      | `table`    | Returns all alive entities with the given tag       |

### Universe Methods — Bitmap Tags

| Method                                | Returns    | Description                                       |
|---------------------------------------|------------|----------------------------------------------------|
| `universe:defineTag(name)`            | `integer`  | Defines a bitmap tag name, returns its bit index    |
| `universe:bitmapTag(id, name)`        | `nil`      | Adds a bitmap tag to an entity                      |
| `universe:bitmapUntag(id, name)`      | `nil`      | Removes a bitmap tag from an entity                 |
| `universe:hasBitmapTag(id, name)`     | `boolean`  | Returns true if the entity has the bitmap tag       |
| `universe:queryBitmapTag(name)`       | `table`    | Returns all entities with the given bitmap tag      |
| `universe:queryBitmapAny(names)`      | `table`    | Returns entities with any of the listed bitmap tags |
| `universe:queryBitmapAll(names)`      | `table`    | Returns entities with all of the listed bitmap tags |
| `universe:getBitmapTagBit(name)`      | `integer?` | Returns bit index for a tag name, or nil            |

### Universe Methods — Layers

| Method                                   | Returns    | Description                                     |
|------------------------------------------|------------|--------------------------------------------------|
| `universe:setLayer(id, layer)`           | `nil`      | Sets the layer for an entity                      |
| `universe:getLayer(id)`                  | `integer`  | Returns the layer (default 0)                     |
| `universe:getEntitiesByLayer(layer)`     | `table`    | Returns all entities on a specific layer          |
| `universe:getEntitiesSorted()`           | `table`    | Returns all entities sorted by layer then ID      |

### Universe Methods — Blueprints

| Method                                              | Returns    | Description                                          |
|-----------------------------------------------------|------------|------------------------------------------------------|
| `universe:defineBlueprint(name, components)`        | `nil`      | Defines a blueprint from a component table            |
| `universe:extendBlueprint(name, parent, overrides)` | `nil`      | Defines a blueprint extending a parent with overrides |
| `universe:spawnBlueprint(name, overrides?)`         | `integer`  | Spawns an entity from a blueprint                     |
| `universe:hasBlueprint(name)`                       | `boolean`  | Returns true if a blueprint exists                    |
| `universe:removeBlueprint(name)`                    | `nil`      | Removes a blueprint definition                        |
| `universe:listBlueprints()`                         | `table`    | Returns all defined blueprint names                   |
| `universe:getBlueprintComponents(name)`             | `table?`   | Returns a deep copy of a blueprint's components       |

### Universe Methods — Parent-Child Hierarchy

| Method                                | Returns    | Description                                       |
|---------------------------------------|------------|----------------------------------------------------|
| `universe:setParent(child, parent?)`  | `nil`      | Sets or clears the parent of an entity              |
| `universe:getParent(child)`           | `integer?` | Returns the parent entity ID, or nil                |
| `universe:getChildren(parent)`        | `table`    | Returns all direct child entity IDs                 |

### Universe Methods — Systems

| Method                                | Returns    | Description                                             |
|---------------------------------------|------------|---------------------------------------------------------|
| `universe:addSystem(system)`          | `nil`      | Adds a system table to the universe                      |
| `universe:removeSystem(system)`       | `nil`      | Removes a system table by pointer identity               |
| `universe:update(dt)`                 | `nil`      | Calls `system:update(world, dt)` on each system          |
| `universe:draw()`                     | `nil`      | Calls `system:draw(world)` on each system                |
| `universe:emit(event, ...)`           | `nil`      | Emits a named event to all systems with the handler      |
| `universe:getSystemCount()`           | `integer`  | Returns the number of registered systems                 |

## Lua Examples

```lua
function luna.init()
    -- Create a new ECS universe
    world = luna.entity.newUniverse()

    -- Spawn entities with components
    player = world:spawn()
    world:set(player, "position", { x = 100, y = 200 })
    world:set(player, "velocity", { x = 0, y = 0 })
    world:set(player, "health", 100)
    world:addTag(player, "player")
    world:setLayer(player, 1)

    -- Use blueprints for enemy templates
    world:defineBlueprint("goblin", {
        health = 30,
        speed = 50,
        hostile = true
    })
    world:extendBlueprint("goblin_chief", "goblin", {
        health = 100,
        speed = 30
    })

    -- Spawn from blueprint with overrides
    enemy1 = world:spawnBlueprint("goblin")
    enemy2 = world:spawnBlueprint("goblin_chief", { speed = 40 })
    world:addTag(enemy1, "enemy")
    world:addTag(enemy2, "enemy")

    -- Define and use bitmap tags for fast queries
    world:defineTag("visible")
    world:defineTag("collidable")
    world:bitmapTag(player, "visible")
    world:bitmapTag(player, "collidable")
    world:bitmapTag(enemy1, "visible")

    -- Add a movement system
    local movementSystem = {
        update = function(self, w, dt)
            w:each("velocity", function(id, vel)
                if w:has(id, "position") then
                    local pos = w:get(id, "position")
                    pos.x = pos.x + vel.x * dt
                    pos.y = pos.y + vel.y * dt
                    w:set(id, "position", pos)
                end
            end)
        end
    }
    world:addSystem(movementSystem)

    -- Parent-child hierarchy
    weapon = world:spawn()
    world:set(weapon, "damage", 10)
    world:setParent(weapon, player)
end

function luna.process(dt)
    -- Run all systems in registration order
    world:update(dt)

    -- Query entities by component
    local healthEntities = world:query("health", "position")

    -- Query by tag
    local enemies = world:getEntitiesByTag("enemy")

    -- Query by bitmap tag (fast bitmask intersection)
    local visibleAndCollidable = world:queryBitmapAll({"visible", "collidable"})

    -- Get layer-sorted entities for rendering
    local sorted = world:getEntitiesSorted()
end

function luna.render()
    world:draw()
end
```

## Item Summary

| Kind     | Count |
|----------|-------|
| `struct` | 4     |
| `enum`   | 0     |
| `fn`     | 1     |
| **Total** | **5** |

## References

| Module     | Relationship  | Notes                                                              |
|------------|---------------|--------------------------------------------------------------------|
| `engine`   | Imports from  | Uses `log_messages` constants (`EN01_UNIVERSE_INIT`, `EN02_ENTITY_SPAWN`, `RL01`–`RL03`) |
| `math`     | Imports from  | Position components typically use `Vec2` but stored as Lua tables   |
| `lua_api`  | Imported by   | `src/lua_api/entity_api.rs` registers `luna.entity.*` and wraps `Universe` as `LuaUniverse` UserData |
| `ai`       | Related       | AI behaviours (FSMs, behaviour trees) often drive entity state via the component API |
| `scene`    | Related       | Scene systems may manage groups of entities through Universe instances |

The `RelationshipManager` is a standalone Rust-only type not currently exposed to Lua. It is intended for integration by Tier 2/3 modules (e.g. diplomacy, trade, faction systems) that build on top of the entity module.

## Notes

- **Generational IDs**: Entity IDs pack an 8-bit generation counter in the upper bits and a 24-bit slot index in the lower bits. This limits the maximum number of unique entity slots to ~16 million and the recycle count per slot to 256 before wrapping. The generation check prevents stale-handle access after an entity is killed and its slot recycled.
- **Component storage**: Components are stored in Lua registry tables, not Rust containers. This means component access crosses the Rust↔Lua boundary and is slower than native Rust `HashMap` lookups, but gives game scripts freedom to use arbitrary values without schema registration.
- **Bitmap tag limit**: A maximum of 63 bitmap tag definitions are allowed per Universe (stored as bits in a `u64`). String tags have no such limit but are slower for set-intersection queries.
- **Blueprint persistence**: `clear()` and `release()` remove all entities, components, tags, layers, and systems but preserve blueprint definitions. This allows blueprints to be defined once in `luna.load()` and reused across level resets.
- **System dispatch order**: Systems execute in the order they were added via `addSystem()`. Each system is a Lua table with optional `update(self, world, dt)`, `draw(self, world)`, and arbitrary event handler methods dispatched via `emit()`.
- **RelationshipManager**: The `RelationshipManager` type is a Rust-only utility not currently bound to Lua. Relationships are symmetric: pair keys are normalised to `(min(a,b), max(a,b))` so setting `A→B` and `B→A` access the same record.
- **Thread safety**: `Universe` is not `Send` or `Sync` — it holds `RegistryKey` values bound to a specific Lua VM. Never share a Universe across threads.
- **Performance**: This is a property-bag ECS, not an archetype system. `query()` and `each()` scan all alive entities linearly. For performance-critical inner loops with thousands of entities, consider native Lua tables or pre-filtered caches.
