# src/entity/

Lightweight entity-component-system with ID recycling, bitmap tags, layers, and blueprints.

## What This Module Contains

Universe manages entity lifecycle with generational IDs. Supports component storage, tag-based filtering, layer assignment, blueprint templates for entity creation, and system dispatch ordering.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports and module-level docs |
| `universe.rs` | `Universe` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/entity_tests.rs`
- **Lua API bindings**: `src/lua_api/entity_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
