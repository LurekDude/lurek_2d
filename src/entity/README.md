# `src/entity/` — Entity-Component System (ECS)

## Purpose

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

### How It Works

Each entity is identified by a `(index: u32, generation: u32)` pair.  When an
entity is destroyed its slot's generation counter increments.  A Lua script
holding the old entity handle will fail the generation check on the next
`is_alive()` call rather than silently reading stale component data.

The component store is a `mlua::RegistryKey` pointing to a Lua table per
entity.  Rust only holds the registry key — it never reads or writes component
values — keeping the Lua/Rust boundary minimal.  All component access is
therefore native-speed Lua table access with no Rust overhead beyond the
initial handle validity check.  Adding a component is as simple as
`entity.health = 100` from Lua.

### Dependency Direction

```
entity/ ──────► (none at compile time; uses Lua RegistryKey at runtime)
```

**Leaf module** — no compile-time Luna2D dependencies. Component values are stored
as opaque Lua registry references.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `Universe`.

**~5 lines** — pure re-export.

---

### `universe.rs` — `Universe` (ECS Implementation)

**~715 lines** | Complete ECS implementation with ID recycling, bitmap tags,
blueprints with inheritance, and Lua component storage.

#### Entity ID Management

```rust
// ID recycling via free_list
next_id: u64,
free_list: Vec<u64>,
alive: HashSet<u64>,
```

`spawn()` pops from `free_list` first; only increments `next_id` when the free
list is empty. `despawn()` pushes the ID back for reuse.

#### Component Storage

Components are stored as `mlua::RegistryKey` values — the actual data lives in
the Lua registry, and the Universe holds keys to retrieve it. This avoids
serialization overhead for Lua↔Rust component access.

#### Tag System

Bitmap tags using `u64` — each entity's tags are a single `u64` bitmask.
Maximum 63 unique tag types (bit 0 unused). O(1) tag add/remove/check operations.

#### Blueprint System

| Method | Purpose |
|--------|---------|
| `register_blueprint(name, components)` | Template registration |
| `spawn_from_blueprint(name)` | Create entity with preset components |
| Blueprint inheritance | Child merges parent's components, overrides conflicts |

**Helper**: `deep_copy_table` recursively clones Lua tables to ensure blueprint
instances don't share mutable state.

---

## Cross-Cutting Concerns

### Error Handling

Invalid entity IDs (despawned or never created) return `None`/`false` rather than
panicking — entity queries degrade gracefully.

### Lua Integration

The Lua bridge lives in `src/lua_api/entity_api.rs` (~420 lines), exposing the
Universe as `luna.entity.*`.

### Usage from Lua

```lua
-- Create entities
local player = luna.entity.spawn()
luna.entity.setComponent(player, "position", {x = 100, y = 200})
luna.entity.setComponent(player, "health", {current = 100, max = 100})
luna.entity.addTag(player, "player")

-- Blueprint system
luna.entity.registerBlueprint("enemy", {
    position = {x = 0, y = 0},
    health = {current = 50, max = 50},
    ai = {state = "patrol"}
})
local enemy1 = luna.entity.spawnFromBlueprint("enemy")
```
