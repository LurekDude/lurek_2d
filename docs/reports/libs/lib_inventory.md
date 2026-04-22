# `library.inventory`

A pure-Lua replacement for the former `lurek.inventory` Rust binding.
Provides ItemStack, Container (fixed/unlimited/expandable), InvItem with tags,
Slot and SlotState, ItemSet, and a full Inventory with equip slots and subsystem flags.

Usage:
local inventory = require("library.inventory")
local bag = inventory.newContainer("bag", "unlimited", 0)
local sword = inventory.newItem("sword")
sword:setWeight(3.5)
sword:setStackLimit(1)
bag:addItem(sword, 1)

*90 functions, 0 module fields documented.*

See: [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson) — serialise inventory snapshots for save round-trip, [`lurek.serial.fromJson`](../lua-api.md#lurekcodecfromjson) — restore inventory snapshots, [`lurek.save.SaveManager`](../lua-api.md#lureksavegamesavemanager) — register inventory state via a SaveManager collector, [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus) — optional change-event bus from `inv:getEventBus()`, [`lurek.data.deepCopy`](../lua-api.md#lurekdatadeepcopy) — P4 lift candidate — `item:clone()` will delegate when available

## Functions

### `newItem(type_name)`

Create a lightweight inventory item definition. Each item has a type, weight, size, stack limit, tag set, and a property map.

**Parameters**

- `type_name` *string* — Item type identifier (e.g. "sword").

**Returns**

- *table* — InvItem object.

### `getType()`

Return the type name.

**Returns**

- *string*

### `getWeight()`

Return item weight.

**Returns**

- *number*

### `setWeight(w)`

Set physical weight (must be non-negative).

**Parameters**

- `w` *number* — Weight value.

### `getSizeW()`

Return grid width.

**Returns**

- *number*

### `getSizeH()`

Return grid height.

**Returns**

- *number*

### `setSize(w, h)`

Set grid size (both dimensions clamped to >= 1).

**Parameters**

- `w` *number* — Width.
- `h` *number* — Height.

### `getStackLimit()`

Return maximum items per stack.

**Returns**

- *number*

### `setStackLimit(n)`

Set maximum stack size (clamped to >= 1).

**Parameters**

- `n` *number* — Maximum stack count.

### `hasTag(tag)`

Return true if the item has the given tag.

**Parameters**

- `tag` *string* — Tag name.

**Returns**

- *boolean*

### `addTag(tag)`

Add a tag (no-op if already present).

**Parameters**

- `tag` *string* — Tag name to add.

### `removeTag(tag)`

Remove a tag. Returns true if tag existed.

**Parameters**

- `tag` *string* — Tag name to remove.

**Returns**

- *boolean*

### `getTags()`

Return all tag names as an array.

**Returns**

- *table*

### `setProperty(key, val)`

Set a generic property.

**Parameters**

- `key` *string* — Property key.
- `val` *any* — Property value.

### `getProperty(key)`

Get a generic property.

**Parameters**

- `key` *string* — Property key.

**Returns**

- *any*

### `clone()`

Deep-copy this item definition. TODO(P4 lift): once `lurek.data.deepCopy` ships, replace the manual field-by-field rebuild below with `_data_deep_copy(item)` so that arbitrary user-attached fields are preserved automatically.

**Returns**

- *table* — copy of InvItem

See: [`lurek.data.deepCopy`](../lua-api.md#lurekdatadeepcopy)

### `newItemStack(inv_item, quantity, max_quantity)`

Create a counted stack of a single item type.

**Parameters**

- `inv_item` *table* — InvItem definition.
- `quantity` *number* — Initial count (clamped to 0..max).
- `max_quantity` *number* — Maximum stack size (clamped to >= 1).

**Returns**

- *table* — ItemStack object.

### `getItem()`

Return the underlying InvItem.

**Returns**

- *table*

### `getQuantity()`

Return current quantity.

**Returns**

- *number*

### `setQuantity(n)`

Directly set quantity (clamped 0..max).

**Parameters**

- `n` *number* — New quantity.

### `getStackLimit()`

Return max quantity.

**Returns**

- *number*

### `isFull()`

Return true when stack holds max items.

**Returns**

- *boolean*

### `isEmpty()`

Return true when stack is empty.

**Returns**

- *boolean*

### `add(n)`

Add n items. Returns overflow (items that did not fit).

**Parameters**

- `n` *number* — Items to add.

**Returns**

- *number* — overflow count

### `remove(n)`

Remove n items. Returns count actually removed.

**Parameters**

- `n` *number* — Items to remove.

**Returns**

- *number*

### `split(n)`

Split n items off into a new stack. Returns nil if n invalid.

**Parameters**

- `n` *number* — Items to split off.

**Returns**

- *table|nil* — new ItemStack

### `merge(other)`

Merge another stack into this one. Returns leftover count.

**Parameters**

- `other` *table* — ItemStack to merge from.

**Returns**

- *number*

### `newSlot(slot_type, state)`

Create a single inventory slot (holds one ItemStack).

**Parameters**

- `slot_type` *string* — Filter type ("any" = accept all).
- `state` *string* — SlotState value.

**Returns**

- *table* — Slot object.

### `getSlotType()`

Return slot type filter.

**Returns**

- *string*

### `getState()`

Return current state.

**Returns**

- *string*

### `setState(s)`

Set state.

**Parameters**

- `s` *string* — SlotState constant.

### `isEmpty()`

Return true if no item is held.

**Returns**

- *boolean*

### `getStack()`

Return the held ItemStack, or nil.

**Returns**

- *table|nil*

### `getItem()`

Return the held InvItem (unwrapped), or nil.

**Returns**

- *table|nil*

### `canAccept(item)`

Return true if the item fits size constraints and type filter. Items are accepted if the slot type is "any", or the item type matches the slot type, or the item carries a tag matching the slot type.

**Parameters**

- `item` *table* — InvItem to test.

**Returns**

- *boolean*

### `setStack(s)`

Place an ItemStack. Returns false if item not accepted.

**Parameters**

- `s` *table* — ItemStack to place.

**Returns**

- *boolean*

### `takeStack()`

Remove and return the held stack.

**Returns**

- *table|nil*

### `clear()`

Clear the slot.

### `newContainer(name, mode, slot_count, max_slots)`

Create a named container managing a list of slots. For expandable mode, `max_slots` caps how far `expand()` can grow.

**Parameters**

- `name` *string* — Container identifier.
- `mode` *string* — "fixed" | "unlimited" | "expandable".
- `slot_count` *number* — Initial number of slots (ignored for unlimited).
- `max_slots` *number* — Upper slot cap for expandable mode (defaults to slot_count).

**Returns**

- *table* — Container object.

### `getName()`

Return the container name.

**Returns**

- *string*

### `getMode()`

Return the container mode string.

**Returns**

- *string*

### `slotCount()`

Return the number of slots.

**Returns**

- *number*

### `getCapacity()`

Return max slot count. 0 = unbounded.

**Returns**

- *number*

### `setWeightLimit(w)`

Set weight limit (must be non-negative). 0 = unlimited.

**Parameters**

- `w` *number* — Weight limit.

### `getWeightLimit()`

Return weight limit. 0 = unlimited.

**Returns**

- *number*

### `getCurrentWeight()`

Return current total weight.

**Returns**

- *number*

### `totalWeight()`

Alias for getCurrentWeight.

**Returns**

- *number*

### `isFull()`

Return true if all slots are occupied (fixed/expandable) or weight limit reached.

**Returns**

- *boolean*

### `getSlot(idx)`

Get a slot by 1-based index.

**Parameters**

- `idx` *number* — 1-based slot index.

**Returns**

- *table|nil*

### `getSlots()`

Return all slots array.

**Returns**

- *table*

### `addSlot(sl)`

Add slot (respects mode limits).

**Parameters**

- `sl` *table* — Slot object.

### `setCapacity(n)`

Set the upper slot capacity (expandable mode only). Clamped so it cannot be less than the current slot count.

**Parameters**

- `n` *number* — New maximum slot count.

### `expand(n)`

Expand by n new empty slots (expandable mode only). Returns true if any added. Respects the max-slot capacity; stops adding once the limit is reached.

**Parameters**

- `n` *number* — Number of slots to add.

**Returns**

- *boolean*

### `addItem(inv_item, quantity)`

Auto-place item quantity. Merges into ALL existing matching stacks first, then fills empty slots. For unlimited containers, auto-grows as needed.

**Parameters**

- `inv_item` *table* — InvItem definition.
- `quantity` *number* — Number of items to add (must be > 0).

**Returns**

- *boolean* — true if fully placed.

### `countItem(type_name)`

Count all items of a given type across all slots.

**Parameters**

- `type_name` *string* — Item type to count.

**Returns**

- *number*

### `hasItem(type_name, qty)`

Return true if >= qty of type_name present.

**Parameters**

- `type_name` *string* — Item type.
- `qty` *number* — Required count.

**Returns**

- *boolean*

### `removeItem(type_name, qty)`

Remove up to qty items of type_name. Returns count removed.

**Parameters**

- `type_name` *string* — Item type to remove.
- `qty` *number* — Maximum items to remove.

**Returns**

- *number*

### `findByTag(tag)`

Return all items with the given tag.

**Parameters**

- `tag` *string* — Tag to filter by.

**Returns**

- *table* — Array of InvItem.

### `toItemList()`

Return a summary list of {type_name, quantity} aggregated across slots.

**Returns**

- *table* — Array of {type_name, total_qty}

### `removeSlot(idx)`

Remove the slot at a 1-based index. Shifts subsequent slots down.

**Parameters**

- `idx` *number* — 1-based slot index.

**Returns**

- *boolean* — true if the slot was removed, false if out of range.

### `newItemSet(name)`

Create a named item set (bonus condition). All requirements must be satisfied simultaneously for the set to be active.

**Parameters**

- `name` *string* — Display name.

**Returns**

- *table* — ItemSet object.

### `getName()`

Return the set name.

**Returns**

- *string*

### `addRequirement(tag, slot_filter)`

Add a requirement: at least one equip slot must hold an item with `tag`.

**Parameters**

- `tag` *string* — Required tag.
- `slot_filter` *string* — Check only this slot name, or "" for any.

### `getRequirements()`

Return all requirements as array of {tag, slot_filter}.

**Returns**

- *table*

### `isSatisfied(equip_slots)`

Check if all requirements are satisfied given an equip_slots table {name -> Slot}.

**Parameters**

- `equip_slots` *table* — Map of slot name to Slot.

**Returns**

- *boolean*

### `newInventory()`

Create a top-level inventory managing containers, equip slots, item sets, and subsystem flags.

**Returns**

- *table* — Inventory object.

### `getEventBus()`

Return (or lazily create) an optional `lurek.patterns` EventBus that callers can subscribe to for inventory change notifications. Returns nil when the engine binding is unavailable. The library does not auto-emit events on this bus; callers may emit on it from their own wrappers without affecting baseline test behaviour.

**Returns**

- *table|nil* — EventBus instance, or nil when unavailable.

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus)

### `addContainer(name, container)`

Register a container. Replaces any existing container with the same name.

**Parameters**

- `name` *string* — Container name.
- `container` *table* — Container object.

### `getContainer(name)`

Get a container by name.

**Parameters**

- `name` *string* — Container name.

**Returns**

- *table|nil*

### `removeContainer(name)`

Remove a container. Returns true if it existed.

**Parameters**

- `name` *string* — Container name.

**Returns**

- *boolean*

### `containerNames()`

Return container names in insertion order.

**Returns**

- *table*

### `addEquipSlot(name, slot)`

Add or replace a named equip slot.

**Parameters**

- `name` *string* — Slot name.
- `slot` *table* — Slot object.

### `getEquipSlot(name)`

Get an equip slot by name.

**Parameters**

- `name` *string* — Slot name.

**Returns**

- *table|nil*

### `removeEquipSlot(name)`

Remove an equip slot. Returns true if it existed.

**Parameters**

- `name` *string* — Slot name.

**Returns**

- *boolean*

### `equipSlotNames()`

Return equip slot names in insertion order.

**Returns**

- *table*

### `equip(slot_name, stack)`

Equip an ItemStack into the named slot. Returns false if slot missing or item rejected.

**Parameters**

- `slot_name` *string* — Equip slot name.
- `stack` *table* — ItemStack to equip.

**Returns**

- *boolean*

### `unequip(slot_name)`

Unequip a slot and return its InvItem (not the full stack). Returns nil if empty.

**Parameters**

- `slot_name` *string* — Equip slot name.

**Returns**

- *table|nil* — InvItem

### `addItemSet(iset)`

Register an item set.

**Parameters**

- `iset` *table* — ItemSet object.

### `getItemSets()`

Return all registered item sets.

**Returns**

- *table*

### `getActiveSets()`

Return only the currently active item sets (all requirements met).

**Returns**

- *table*

### `enableSubsystem(name)`

Enable a named subsystem ("weight", "size", "stacking", "sets").

**Parameters**

- `name` *string* — Subsystem name.

### `disableSubsystem(name)`

Disable a named subsystem.

**Parameters**

- `name` *string* — Subsystem name.

### `isSubsystemEnabled(name)`

Return true if the named subsystem is active.

**Parameters**

- `name` *string* — Subsystem name.

**Returns**

- *boolean*

### `countItem(type_name)`

Count items of a type across ALL containers.

**Parameters**

- `type_name` *string* — Item type.

**Returns**

- *number*

### `hasItem(type_name, qty)`

Return true if total count >= qty across all containers.

**Parameters**

- `type_name` *string* — Item type.
- `qty` *number* — Required count.

**Returns**

- *boolean*

### `removeFromAny(type_name, qty)`

Remove qty items of type_name from whichever containers have them.

**Parameters**

- `type_name` *string* — Item type.
- `qty` *number* — Items to remove.

**Returns**

- *boolean* — true if full amount removed.

### `transfer(from_name, from_idx, to_name, to_idx)`

Transfer a stack from one container slot to another (1-based indices).

**Parameters**

- `from_name` *string* — Source container name.
- `from_idx` *number* — Source slot index (1-based).
- `to_name` *string* — Destination container name.
- `to_idx` *number* — Destination slot index (1-based).

**Returns**

- *boolean* — true on success.

### `splitStack(container_name, slot_idx, quantity)`

Split `quantity` items from the stack at `slot_idx` in `container_name` into the first empty compatible slot in the same container. Returns true if the split succeeded.

**Parameters**

- `container_name` *string* — Container name.
- `slot_idx` *number* — 1-based slot index of the source stack.
- `quantity` *number* — Number of items to split off.

**Returns**

- *boolean*

### `mergeStacks(container_name, from_slot, to_slot)`

Merge the stack at `from_slot` into `to_slot` within `container_name`. If the destination is empty, the source stack is moved into it. Returns true if any items were merged or moved.

**Parameters**

- `container_name` *string* — Container name.
- `from_slot` *number* — 1-based source slot index.
- `to_slot` *number* — 1-based destination slot index.

**Returns**

- *boolean*

### `swap(container_a, slot_a, container_b, slot_b)`

Swap items between two container slots (may be in different containers). Returns true on success.

**Parameters**

- `container_a` *string* — First container name.
- `slot_a` *number* — 1-based slot index in container_a.
- `container_b` *string* — Second container name.
- `slot_b` *number* — 1-based slot index in container_b.

**Returns**

- *boolean*
