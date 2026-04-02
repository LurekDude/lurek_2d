# `src/inventory/` — Slot-Based Inventory System

## Purpose

Equipment/item inventory with typed slots, item stacking, item sets with
set bonuses, subsystem toggles (weight, size, stacking, sets), and event hooks.

## Files

| File | Purpose |
|------|---------|
| `item.rs` | `Item`, `ItemStack` — item definition and stacking |
| `slot.rs` | `Slot`, `SlotState` — typed inventory slot |
| `container.rs` | `Container` — ordered collection of slots |
| `item_set.rs` | `ItemSet`, `SetRequirement`, `SubsystemFlags` — set bonus management |
| `inventory.rs` | `Inventory` — top-level with subsystem management |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
