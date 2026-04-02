# src/resource/

Named resource economy: capacity, flow, decay, interest, upkeep, conversions.

## What This Module Contains

ResourceManager owns a HashMap of named Resources and a list of ConversionRules.
Calling tick(dt) advances all resources and applies conversions. Modifiers
adjust conversion rates for a limited duration. OverflowPolicy controls
what happens when a resource exceeds capacity.

## Files

| File | Purpose |
|------|---------|
| `resource.rs` | Resource, OverflowPolicy |
| `modifier.rs` | ModifierType, Modifier, ConversionRule |
| `manager.rs` | ResourceManager |
| `mod.rs` | Facade — re-exports all sub-modules |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/resource_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- No dependencies on other domain modules
- Must NOT import from other Tier 3 modules directly
