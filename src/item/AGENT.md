# src/item/

Generic item data structures — no gameplay semantics, reusable across genres.

## What This Module Contains

Item holds a name, stats map, tags, counters, and metadata. StackManager
coordinates multiple named stacks (draw, discard, hand, etc.). ItemPool
provides weighted random selection. StackBuilder validates construction
against templates.

## Files

| File | Purpose |
|------|---------|
| `item.rs` | Item, ItemTypeDef |
| `stack.rs` | Stack |
| `builder.rs` | StackBuilder |
| `manager.rs` | StackManager |
| `pool.rs` | ItemPool |
| `mod.rs` | Facade — re-exports all sub-modules |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/item_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- Minimal — `math` and `engine` only
- Must NOT import from other Tier 3 modules
