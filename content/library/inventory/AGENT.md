# `inventory` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 --- Lunasome (pure Lua, no Rust dependencies) |
| **Source** | \library/inventory/init.lua\ |
| **Lua Tests** | \	ests/lua/library/test_library_inventory.lua\ |
| **Depends on** | \luna.*\ public API only |

## Summary

Slot-based item inventory system with typed containers, item stacking, named
equipment slots, configurable subsystem toggles (weight, size, stacking, sets),
optional item-set bonus detection, and cross-container convenience helpers.

The library mirrors the public surface of \src/inventory/\ while adding Lua-idiomatic
wrappers. All implementation uses pure-Lua closures; there are no Rust dependencies.

## Architecture

Inventory owns multiple named Containers and a separate set of named equip Slots.
Each Container holds Slots in one of three modes: fixed (static count), unlimited
(grows on demand), or expandable (bounded growth). Slots hold an optional ItemStack.
ItemSet objects define set bonuses that activate when all tagged-equipment requirements
are simultaneously met across equip slots.

## Source Files

| File | Purpose |
|------|---------|
| \library/inventory/init.lua\ | Full implementation |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|---------|
| InvItem | newItem(type) | Blueprint: type, tags, weight, size, stack_limit, properties |
| ItemStack | newItemStack(item, qty, max) | Counted stack with add/remove/split/merge |
| Slot | newSlot(type, state) | Single position with type filter, state, and optional stack |
| Container | newContainer(name, mode, count) | Slot collection with removeSlot, addItem, queries |
| Inventory | newInventory() | Top-level with equip slots, item sets, stack management |
| ItemSet | newItemSet(name) | Set-bonus via tagged requirements |
| M.ContainerMode | table | String constants: fixed, unlimited, expandable |
| M.SlotState | table | String constants: Active, Passive, Idle |

## Container Methods

slotCount / getCapacity / getSlot / getSlots / addSlot / removeSlot(idx)
setWeightLimit / getWeightLimit / getCurrentWeight / isFull
addItem / countItem / hasItem / removeItem / findByTag / toItemList / expand

## Inventory Methods

addContainer / getContainer / removeContainer / containerNames
addEquipSlot / getEquipSlot / removeEquipSlot / equipSlotNames / equip / unequip
countItem / hasItem / removeFromAny
transfer(from, fIdx, to, tIdx) / splitStack(c, slot, qty) / mergeStacks(c, from, to) / swap(cA, sA, cB, sB)
addItemSet / getItemSets / getActiveSets
enableSubsystem / disableSubsystem / isSubsystemEnabled

## Subsystem Names

weight | size | stacking | sets

## Test Coverage

72 tests: InvItem, ItemStack, Slot, Container (all modes), ItemSet, Inventory
(containers, equip slots, queries, stack ops: splitStack, mergeStacks, swap,
transfer), Container.removeSlot, Slot state, ContainerMode enum.
