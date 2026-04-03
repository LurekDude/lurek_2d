# inventory — Virtual Inventory System

> **Lua namespace:** `luna.inventory`
> **C++ module:** `src/modules/inventory/`
> **Purpose:** Full-featured RPG inventory system with items, stacking, slots with state and capacity, containers (fixed/unlimited/expandable), equipment slots, item sets with set bonuses, weight limits, subsystem toggles, and Lua callback hooks.

## Reimplementation Notes

- All slot indices in Lua are **1-based**; the C++ binding subtracts 1 internally
- `equip()` takes an `ItemStack`, but `unequip()` returns an `Item` (asymmetric contract)
- `Container:expand()` returns `boolean` (not count of slots added)
- `Item:clone()` does **NOT** clone `resourceRef` or `userDataRef` — both are `nil` in the clone
- `Item:getSize()`/`Slot:getCapacity()` return **two values** `(w, h)`, not a table
- Lua registry refs are used for `resourceRef`, `userDataRef`, `bonusRef`, and all callbacks
- `fireCallback` is fully variadic — forwards all extra args to the callback and returns its results
- `weightLimit = 0` means **no limit**, not zero capacity
- Subsystem names are plain strings (not an enum): `"weight"`, `"size"`, `"stacking"`, `"sets"`
- `ItemSet:isActive(inventory)` checks all requirements against ALL slots and containers
- `SlotState` values: `"active"`, `"passive"`, `"idle"` (string-based, not enum in Lua)
- `ContainerMode` values: `"fixed"`, `"unlimited"`, `"expandable"` (string-based)

## Dependencies

- `engine::Object` base (reference counted)
- `engine::Module` system for module registration
- No external library dependencies

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newItem` | `type: string` | `Item` | Create an item with the given type identifier |
| `newItemStack` | `item: Item, quantity?: int=1, maxQuantity?: int=item:getStackLimit()` | `ItemStack` | Create a stack wrapping an item |
| `newSlot` | `slotType?: string="any", state?: string="idle"` | `Slot` | Create a slot with type filter and initial state |
| `newContainer` | `name: string, mode?: string="fixed", slotCount?: int=0` | `Container` | Create a container with the specified mode |
| `newInventory` | — | `Inventory` | Create an empty inventory |
| `newItemSet` | `name: string` | `ItemSet` | Create a named item set |

---

## Item Type

Represents a single item definition with properties, tags, and optional Lua data references.

### Internal Structure

```
itemType:     string
tags:         string[]
weight:       double
sizeW, sizeH: int
stackLimit:   int
resourceRef:  int (Lua registry ref, LUA_NOREF = nil)
userDataRef:  int (Lua registry ref, LUA_NOREF = nil)
```

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getItemType` | — | `string` | Get the item type identifier |
| `setItemType` | `type: string` | — | Set the item type identifier |
| `getTags` | — | `table<string>` | Get all tags as an array |
| `hasTag` | `tag: string` | `boolean` | Check if item has a specific tag |
| `addTag` | `tag: string` | — | Add a tag |
| `removeTag` | `tag: string` | — | Remove a tag |
| `getWeight` | — | `number` | Get item weight |
| `setWeight` | `w: number` | — | Set item weight |
| `getSize` | — | `w: int, h: int` | Get item grid size (two return values) |
| `setSize` | `w: int, h: int` | — | Set item grid size |
| `getStackLimit` | — | `number` | Get maximum stack count |
| `setStackLimit` | `n: int` | — | Set maximum stack count |
| `getResourceRef` | — | `any \| nil` | Get stored Lua value (e.g. texture, sprite) |
| `setResourceRef` | `value: any` | — | Store any Lua value in registry |
| `getUserData` | — | `any \| nil` | Get stored Lua user data |
| `setUserData` | `value: any` | — | Store any Lua value in registry |
| `clone` | — | `Item` | Deep-copy item (tags, properties). **resourceRef and userDataRef are NOT cloned** |

---

## ItemStack Type

Wraps an Item with a quantity and maximum quantity, supporting split/merge operations.

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getItem` | — | `Item \| nil` | Get the underlying item |
| `getQuantity` | — | `number` | Get current quantity |
| `setQuantity` | `n: int` | — | Set quantity directly |
| `getMaxQuantity` | — | `number` | Get maximum stack size |
| `add` | `n: int` | `number` | Add n items; returns **leftover** that didn't fit |
| `remove` | `n: int` | `number` | Remove n items; returns **count actually removed** |
| `isFull` | — | `boolean` | Check if quantity == maxQuantity |
| `split` | `n: int` | `ItemStack \| nil` | Split off n items into a new stack; nil if can't split |
| `merge` | `other: ItemStack` | `number` | Merge other stack into this one; returns **leftover** from other |
| `clone` | — | `ItemStack` | Clone the stack (clones item too) |

---

## Slot Type

A container position that holds an optional ItemStack, with type filtering and three states.

### SlotState values
`"active"`, `"passive"`, `"idle"`

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSlotType` | — | `string` | Get the slot's type filter (e.g. `"weapon"`, `"any"`) |
| `setSlotType` | `type: string` | — | Set the type filter |
| `getState` | — | `string` | Get current state (`"active"`, `"passive"`, `"idle"`) |
| `setState` | `state: string` | — | Set state (must be valid or Lua error) |
| `getCapacity` | — | `w: int, h: int` | Get slot capacity dimensions (two return values) |
| `setCapacity` | `w: int, h: int` | — | Set slot capacity dimensions |
| `isEmpty` | — | `boolean` | Check if slot has no stack |
| `getStack` | — | `ItemStack \| nil` | Get the held stack |
| `getItem` | — | `Item \| nil` | Shortcut: get the item from the held stack |
| `setStack` | `stack: ItemStack` | `boolean` | Place a stack; returns false if not accepted |
| `clear` | — | — | Remove the held stack |
| `canAccept` | `item: Item` | `boolean` | Check if this slot would accept the item |

---

## Container Type

A named collection of slots with three modes: fixed, unlimited, or expandable.

### ContainerMode values
`"fixed"`, `"unlimited"`, `"expandable"`

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Get container name |
| `getMode` | — | `string` | Get mode string |
| `getSlotCount` | — | `number` | Number of slots |
| `getSlot` | `index: int` | `Slot \| nil` | Get slot (1-based); nil if out of range |
| `addSlot` | `slot: Slot` | — | Append a slot (no-op if at capacity for fixed mode) |
| `removeSlot` | `index: int` | — | Remove slot at index (1-based) |
| `addItem` | `item: Item, quantity?: int=1` | `boolean` | Auto-place item into first compatible slot; merges stacks |
| `getWeightLimit` | — | `number` | Get weight limit (0 = no limit) |
| `setWeightLimit` | `limit: number` | — | Set weight limit |
| `getCurrentWeight` | — | `number` | Sum of (item.weight × stack.quantity) for all slots |
| `getMaxSlots` | — | `number` | Get maximum slot count |
| `setMaxSlots` | `n: int` | — | Set maximum slot count |
| `expand` | `n: int` | `boolean` | Add n empty slots (expandable mode only). Returns `true` if any added, `false` if at cap |
| `getSlots` | — | `table<Slot>` | Array of all slots |

---

## Inventory Type

Top-level container manager with named containers, equipment slots, item sets, subsystem toggles, and callback hooks.

### Subsystem names (strings)
`"weight"`, `"size"`, `"stacking"`, `"sets"`

### Callback event names
`"on_equip"`, `"on_unequip"`, `"on_add"`, `"on_remove"`, `"on_set_activate"`, `"on_set_deactivate"`, `"on_overweight"`, `"on_use"`

### Container Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addContainer` | `name: string, container: Container` | — | Register a named container |
| `getContainer` | `name: string` | `Container \| nil` | Look up container by name |
| `removeContainer` | `name: string` | — | Remove named container |
| `getContainerNames` | — | `table<string>` | List all container names |

### Equipment Slots

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addEquipSlot` | `name: string, slot: Slot` | — | Register a named equipment slot |
| `getEquipSlot` | `name: string` | `Slot \| nil` | Look up equip slot by name |
| `removeEquipSlot` | `name: string` | — | Remove named equip slot |
| `getEquipSlotNames` | — | `table<string>` | List all equip slot names |
| `equip` | `slotName: string, stack: ItemStack` | `boolean` | Equip a stack; returns false if slot not found or incompatible |
| `unequip` | `slotName: string` | `Item \| nil` | Unequip and return the **Item** (not the stack) |

### Subsystems

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `enableSubsystem` | `name: string` | — | Enable a subsystem |
| `disableSubsystem` | `name: string` | — | Disable a subsystem |
| `isSubsystemEnabled` | `name: string` | `boolean` | Check if subsystem is active |

### Item Sets

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addItemSet` | `set: ItemSet` | — | Register an item set |
| `getItemSets` | — | `table<ItemSet>` | Get all registered item sets |
| `getActiveSets` | — | `table<ItemSet>` | Get only sets whose requirements are currently met |

### Transfer Operations

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `transfer` | `fromContainer: string, fromSlot: int, toContainer: string, toSlot: int` | `boolean` | Move item between containers/slots (1-based) |
| `swap` | `containerA: string, slotA: int, containerB: string, slotB: int` | `boolean` | Swap items between two slots (1-based) |
| `splitStack` | `container: string, slotIdx: int, quantity: int` | `boolean` | Split items off a stack (1-based) |
| `mergeStacks` | `container: string, fromSlot: int, toSlot: int` | `boolean` | Merge from→to stacks (1-based) |

### Callbacks

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCallback` | `event: string, func: function` | — | Register callback for event (replaces existing) |
| `removeCallback` | `event: string` | — | Remove callback for event |
| `fireCallback` | `event: string, ...args` | `...` | Fire callback with args; returns callback's return values |

---

## ItemSet Type

Defines a set bonus with tag-based requirements and optional slot filters.

### Internal Structure

```
name:         string
requirements: {tag: string, slotFilter: string}[]
bonusRef:     int (Lua registry ref, LUA_NOREF = nil)
```

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Get set name |
| `getRequirementCount` | — | `number` | Number of requirements |
| `addRequirement` | `tag: string, slotFilter?: string=""` | — | Add a requirement (empty slotFilter = any slot) |
| `getRequirements` | — | `table<{tag: string, slotFilter: string}>` | Get all requirements |
| `isActive` | `inventory: Inventory` | `boolean` | Check if all requirements are met |
| `getBonusRef` | — | `any \| nil` | Get stored bonus data (any Lua value) |
| `setBonusRef` | `value: any` | — | Store bonus data (e.g. stats table) |

---

## Type Summary

| Type | Factory | Methods |
|---|---|---|
| `Item` | `newItem(type)` | 17 |
| `ItemStack` | `newItemStack(item, qty?, maxQty?)` | 10 |
| `Slot` | `newSlot(slotType?, state?)` | 12 |
| `Container` | `newContainer(name, mode?, slotCount?)` | 14 |
| `Inventory` | `newInventory()` | 25 |
| `ItemSet` | `newItemSet(name)` | 7 |

---

## Game Design Role

- **RPG / action games**: Classic inventory grids with equipment slots, weight budgets, and item sets that grant stat bonuses.
- **Survival / crafting**: Container-based storage (backpack, chest, hotbar) with weight limits and expandable slots.
- **Turn-based tactics**: Equipment slots that affect unit stats; set bonuses for matched gear.
- **Puzzle games**: Slot-based item puzzles where capacity and type constraints drive gameplay.
- **Roguelike**: Randomised loot with stack limits; quick swap between containers mid-run.

---

## Module Boundaries

**vs luna.entity** — Entity is a generic ECS. An Inventory can be attached as a component on a player or chest entity. Inventory manages items; Entity manages the game object that *has* items.

**vs luna.stats** — Stats defines numeric attributes (strength, defence). When an item is equipped, its stat bonuses flow into `luna.stats`. Inventory manages which items are equipped; Stats applies the resulting modifiers.

**vs luna.gui** — GUI provides visual widgets for grid layouts, drag-and-drop. Inventory provides the *data model* (slots, stacks, containers). Connect them via callbacks: `on_add`/`on_remove` refresh the GUI.

**vs luna.savegame** — Savegame serialises the inventory to disk. Register a collector: `collectFn = function() return inventory:serialize() end`.

**vs luna.doll** — Doll visualises equipped items as layered sprites on a character. When `equip()` fires, update the Doll to attach the matching Part.

---

## Recipes & Workflows

- **RPG inventory**: Backpack container (fixed, 20 slots) + equipment slots (head, chest, weapon, shield). `on_equip` callback applies stat bonuses.
- **Survival crafting**: Hotbar container (fixed, 10 slots) + main backpack (expandable, starts at 20, max 40). Weight subsystem enabled.
- **Loot system**: Generate random Items with tags; `addItem()` auto-places into first compatible slot. If backpack full, fire `on_overweight` callback to prompt the player.
- **Shop / trade**: Two Inventories side-by-side. `transfer()` moves items between player and merchant containers.
- **Crafting bench**: Check recipe ingredients via tag lookup, remove consumed items, create result item.

---

## Edge Cases & Pitfalls

- **Nested container depth**: Containers holding items that reference other containers can create deep nesting. Keep nesting shallow (recommended max 2–3 levels) to avoid complex serialisation and UI issues.
- **Weight vs slot capacity**: When the weight subsystem is enabled, an item can be *light enough* but the slot's *size capacity* still too small. Both checks apply: `canAccept()` checks slot type, `addItem()` checks weight budget.
- **Item object lifetime**: Calling `clear()` on a slot does not destroy the Item or ItemStack — they remain in Lua memory until garbage collected. If you need explicit cleanup (e.g. to trigger `on_remove`), use `transfer()` to a discard container instead.
- **`equip()` vs `unequip()` asymmetry**: `equip()` accepts an `ItemStack`, but `unequip()` returns an `Item` (not a stack). If quantity matters, wrap the returned item in a new stack.
- **Clone limitations**: `Item:clone()` does NOT copy `resourceRef` or `userDataRef` — both are `nil` in the clone. Re-assign references after cloning.

---

## Planned / To Implement

- **Crafting subsystem**: Recipe definitions with input items/tags → output item. Auto-consume from designated container.
- **Item durability**: Per-item durability counter; items degrade on use and can break (fire `on_break` callback).
- **Network sync**: Replicate inventory state over `luna.network` for multiplayer item trading.
- **UI binding helpers**: Higher-level API to generate GUI widget trees directly from an Inventory layout.
