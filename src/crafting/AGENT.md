# src/crafting/

Recipe-based crafting: stations, quality tiers, ingredients, skill progression.

## What This Module Contains

Single-file module (`mod.rs`). Recipes define ingredients → outputs with time
and skill requirements. CraftingStation holds a CraftQueue for async jobs.
Quality enum spans Normal → Legendary.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | All crafting types, Recipe, CraftingStation, CraftQueue |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/crafting_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- May use `item` and `inventory` types for ingredient resolution
- Must NOT import from other Tier 3 modules directly
