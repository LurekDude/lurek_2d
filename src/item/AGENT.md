# `item` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.item` |
| **Source** | `src/item/` |
| **Tests** | `tests/item_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_item.lua` |

## Summary

The item module provides the building blocks for any game system that manages
named, tagged, stat-carrying objects organised into ordered collections.  It is
intentionally free of gameplay assumptions: there is no concept of player,
turn, rule, or scoring.  A collection could represent a card hand, an
inventory, a merchant's stock, a dice pool, or a loot pile — the module makes
no distinction.  Game-specific semantics are encoded in item type names, tags,
and numeric stats, all defined by the game script at runtime.

`Item` is a single instance with a type name, a stats map (`HashMap<String,
f64>`), and a tags set (`HashSet<String>`).  `ItemTypeDef` is the blueprint
that seeds defaults when an item of a given type is created; the global
thread-local type registry maps type names to their definitions.  `Stack` is
the primary collection: an ordered `Vec<Item>` with configurable capacity,
filter policies, and optional `StackHistory` for undo/redo or audit logging.
`Slot` is a bounded single-position container (capacity-1 stack with clear
pick-put semantics).  `StackBuilder` constructs stacks from template
`BuildEntry` lists with constraint validation.  `StackManager` groups multiple
named stacks as a logical unit (inventory with "main", "hotbar", "equipped"
sections).  `Pool` provides weighted random item-type selection.  `ItemGroup`
and the group-analysis functions in `group.rs` find patterns in item slices
(runs of consecutive stat values, items sharing a tag prefix, groups of N with
matching stats) — the foundation for combo detection, set-matching, and
achievement evaluation logic.

## Architecture

```
ItemTypeDef registry (thread-local)
  │
  └── define_item_type(name, ...) / get_item_type(name)
        └── Seeds defaults into Item::new(type_name)

Item (instance)
  ├── type_name: String
  ├── stats: HashMap<String, f64>
  └── tags: HashSet<String>

Stack (ordered collection)
  ├── items: Vec<Item>
  ├── max_size: Option<usize>
  ├── filter: Option<fn(&Item) -> bool>
  ├── history: Option<StackHistory>
  └── Operations: push / pop / insert / remove / swap / sort / shuffle

  Slot (bounded single position)
  └── Wraps Stack(max=1) with put/take API

StackManager (multi-stack container)
  └── stacks: HashMap<String, Stack>
        ── add_stack / get / transfer_between

StackBuilder (template-driven construction)
  └── entries: Vec<BuildEntry { type_name, count, overrides }>
        ── build(registry) → Result<Stack, String>

Pool (weighted random selection)
  └── entries: Vec<(type_name, weight)>
        ── pick() → &str

StackHistory (audit log)
  └── log: VecDeque<HistoryEntry>
        ── HistoryAction: Add | Remove | Move | Swap | Sort | Clear | ...

Group analysis (group.rs — stateless functions)
  ├── group_by_stat / group_by_category / group_by_tag_prefix
  ├── find_n_of_stat / find_sequences / find_tag_groups
  └── sorted_indices_by_stat / sorted_indices_by_category
```

## Source Files

| File | Purpose |
|------|---------|
| `builder.rs` | Stack builder — template-based stack construction with validation |
| `group.rs` | Group analysis — stat-based and tag-based grouping of item slices |
| `history.rs` | Change history — append-only log of stack mutations |
| `item.rs` | Generic item type definitions, the global type registry, and item instances |
| `manager.rs` | Stack manager — organises multiple named `Stack` instances as a unit |
| `pool.rs` | Weighted item-type pool for random selection |
| `slot.rs` | Slot — a bounded named position that holds a small set of items |
| `stack.rs` | Ordered item collection — a stack, pile, hand, queue, or any linear sequence of... |

## Submodules

### `item::builder`

Stack builder — template-based stack construction with validation.

- **`BuildEntry`** (struct): One "slot" in a stack template: an item type plus a count and optional overrides.
- **`StackBuilder`** (struct): Builds a `Stack` from `BuildEntry` templates and validates construction constraints.  Constraints (min/max size, max...

### `item::group`

Group analysis — stat-based and tag-based grouping of item slices.

- **`ItemGroup`** (struct): A labelled subset of an item slice, referenced by index.  Indices refer to positions in the original `&[Item]` slice...
- **`group_by_stat`** (fn): Group item indices by the integer part of a named stat.  Returns a map from `stat_value as i64` to a list of 0-based...
- **`group_by_category`** (fn): Group item indices by category. Consult the module-level documentation for the broader usage context and preconditions....
- **`group_by_tag_prefix`** (fn): Group item indices by a tag prefix (the part before the first `:`).  Tags matching `prefix:value` are grouped under...
- **`find_n_of_stat`** (fn): Find all maximal groups where items share the exact same integer stat value, and the group has exactly `n` members. ...
- **`find_at_least_n_of_stat`** (fn): Find all groups where at least `n` items share the same integer stat value.
- **`find_sequences`** (fn): Find all runs (sequences of consecutive integer stat values) of length ≥ `min_run`.  Sorts items by stat value and...
- **`find_tag_groups`** (fn): Find groups of items that all share the same tag-prefix value and contain at least `min_size` members.  Analogous to...
- **`sorted_indices_by_stat`** (fn): Return a sorted list of 0-based indices; does not modify the slice.  `ascending = true` → lowest stat first.
- **`sorted_indices_by_category`** (fn): Return sorted indices grouped alphabetically by category.

### `item::history`

Change history — append-only log of stack mutations.

- **`HistoryAction`** (enum): The category of change that was recorded.
- **`HistoryEntry`** (struct): A single entry in the history log. Consult the module-level documentation for the broader usage context and...
- **`StackHistory`** (struct): Append-only change log with an optional rolling size limit.

### `item::item`

Generic item type definitions, the global type registry, and item instances.

- **`ItemTypeDef`** (struct): Template that describes a class of items (the "blueprint").  Stats, tags, and metadata defined here are seeded into...
- **`define_item_type`** (fn): Register (or overwrite) an item type in the thread-local type registry.
- **`get_item_type`** (fn): Look up an item type definition by name. Returns `None` if not found.
- **`get_item_type_names`** (fn): Return all registered type names. This accessor incurs no allocation; call it freely in hot paths.
- **`clear_item_types`** (fn): Remove all entries from the registry. After this call the container is in the same state as immediately after...
- **`Item`** (struct): A single item instance. Consult the module-level documentation for the broader usage context and preconditions.  All...

### `item::manager`

Stack manager — organises multiple named `Stack` instances as a unit.

- **`StackManager`** (struct): Manages a collection of named `Stack` instances.  All stack names and their semantics are user-defined.

### `item::pool`

Weighted item-type pool for random selection.

- **`PoolEntry`** (struct): A single entry in an item pool. Consult the module-level documentation for the broader usage context and preconditions.
- **`ItemPool`** (struct): A pool of item types for weighted random draws.

### `item::slot`

Slot — a bounded named position that holds a small set of items.

- **`Slot`** (struct): A bounded named position holding zero or more items.  Semantics (what "this slot" means) are entirely user-defined.

### `item::stack`

Ordered item collection — a stack, pile, hand, queue, or any linear sequence of items.

- **`Stack`** (struct): An ordered collection of items. Consult the module-level documentation for the broader usage context and preconditions....

## Key Types

### Structs

#### `item::builder::BuildEntry`

One "slot" in a stack template: an item type plus a count and optional overrides.

#### `item::history::HistoryEntry`

A single entry in the history log. Consult the module-level documentation for the broader usage context and...

#### `item::item::Item`

A single item instance. Consult the module-level documentation for the broader usage context and preconditions.  All...

#### `item::group::ItemGroup`

A labelled subset of an item slice, referenced by index.  Indices refer to positions in the original `&[Item]` slice...

#### `item::pool::ItemPool`

A pool of item types for weighted random draws.

#### `item::item::ItemTypeDef`

Template that describes a class of items (the "blueprint").  Stats, tags, and metadata defined here are seeded into...

#### `item::pool::PoolEntry`

A single entry in an item pool. Consult the module-level documentation for the broader usage context and preconditions.

#### `item::slot::Slot`

A bounded named position holding zero or more items.  Semantics (what "this slot" means) are entirely user-defined.

#### `item::stack::Stack`

An ordered collection of items. Consult the module-level documentation for the broader usage context and preconditions....

#### `item::builder::StackBuilder`

Builds a `Stack` from `BuildEntry` templates and validates construction constraints.  Constraints (min/max size, max...

#### `item::history::StackHistory`

Append-only change log with an optional rolling size limit.

#### `item::manager::StackManager`

Manages a collection of named `Stack` instances.  All stack names and their semantics are user-defined.

### Enums

#### `item::history::HistoryAction`

The category of change that was recorded.

## Public Functions

- **`clear_item_types()`** `item::` — Remove all entries from the registry. After this call the container is in the same state as immediately after...
- **`define_item_type()`** `item::` — Register (or overwrite) an item type in the thread-local type registry.
- **`find_at_least_n_of_stat()`** `group::` — Find all groups where at least `n` items share the same integer stat value.
- **`find_n_of_stat()`** `group::` — Find all maximal groups where items share the exact same integer stat value, and the group has exactly `n` members. ...
- **`find_sequences()`** `group::` — Find all runs (sequences of consecutive integer stat values) of length ≥ `min_run`.  Sorts items by stat value and...
- **`find_tag_groups()`** `group::` — Find groups of items that all share the same tag-prefix value and contain at least `min_size` members.  Analogous to...
- **`get_item_type()`** `item::` — Look up an item type definition by name. Returns `None` if not found.
- **`get_item_type_names()`** `item::` — Return all registered type names. This accessor incurs no allocation; call it freely in hot paths.
- **`group_by_category()`** `group::` — Group item indices by category. Consult the module-level documentation for the broader usage context and preconditions....
- **`group_by_stat()`** `group::` — Group item indices by the integer part of a named stat.  Returns a map from `stat_value as i64` to a list of 0-based...
- **`group_by_tag_prefix()`** `group::` — Group item indices by a tag prefix (the part before the first `:`).  Tags matching `prefix:value` are grouped under...
- **`sorted_indices_by_category()`** `group::` — Return sorted indices grouped alphabetically by category.
- **`sorted_indices_by_stat()`** `group::` — Return a sorted list of 0-based indices; does not modify the slice.  `ascending = true` → lowest stat first.

## Lua API

Exposed under `luna.item.*` by `src/lua_api/item_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `fn` | 13 |
| `mod` | 8 |
| `struct` | 12 |
| **Total** | **34** |

