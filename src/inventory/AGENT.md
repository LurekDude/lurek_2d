# src/inventory/

Slot-based item container with equipment slots, item sets, and subsystems.

## What This Module Contains

Inventory owns a Vec of typed Slots, optionally grouped into an ItemSet for
set-bonus tracking. Subsystem flags (weight, size, stacking, sets) are
toggled per Inventory instance. Container wraps an ordered slot list.

## Files

| File | Purpose |
|------|---------|
| `item.rs` | Item definition and ItemStack |
| `slot.rs` | Slot, SlotState — bounded single slot |
| `container.rs` | Container — ordered collection of slots |
| `item_set.rs` | ItemSet, SetRequirement, SubsystemFlags |
| `inventory.rs` | Inventory top-level coordinator |
| `mod.rs` | Facade — re-exports all sub-modules |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/inventory_api.rs` (if present)
- **Tests**: `tests/unit/` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- Uses `item` module types
- Must NOT import from other Tier 3 modules directly
