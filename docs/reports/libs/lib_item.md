# `library.item`

A pure-Lua replacement for the former `lurek.item` Rust binding.
Provides a type registry, Item objects with tags/stats/meta/owner, capacity-aware
Stacks with positional access, weighted ItemPools with bulk draws, bounded StackHistory,
a StackManager, and functional analysis helpers.

Usage:
local item = require("library.item")
item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={"equippable"} })
local it = item.newItem("sword")
it:addTag("cursed")
print(it:getStat("dmg"))  -- 10


Note (P7 batch C, 0.6.0): the previous file split `M.newStack` and
`M.newStackBuilder` into a base definition followed by a wrapper that
monkey-patched extra methods onto the returned object (former lines
1004-1186 and 1191-1259 respectively). The wrappers were merged into the
original definitions in this revision; functional behaviour is unchanged.

*138 functions, 0 module fields documented.*

See: [`lurek.math`](../lua-api.md#lurekmath), [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson)

## Functions

### `clearTypes()`

Clear all registered item types (useful between tests). **Note**: Already-created Item objects retain their stats, tags, and category from the definition that existed at creation time.  Clearing the registry does NOT retroactively change existing items.

**Returns**

- *nil*

### `defineType(name, def)`

Register a new item type definition.

**Parameters**

- `name` *string* — Unique type name (e.g. "sword").
- `def` *table* — Definition table: `{ name="", category="", base_stats={}, base_tags={}, metadata={} }`.

### `getType(name)`

Retrieve a registered type definition, or nil.

**Parameters**

- `name` *string*

**Returns**

- *table|nil*

### `getTypeNames()`

Return a sorted list of all registered type names.

**Returns**

- *table*

### `newItem(type_name)`

Create a new item instance. Stats and tags are copied from the type definition; modifications are per-instance. If `type_name` is not registered, a warning is logged and the item receives default `misc` category with empty stats/tags.

**Parameters**

- `type_name` *string* — Registered type name (or any string for ad-hoc items).

**Returns**

- *table* — Item object.

### `getType()`

Return the type name.

**Returns**

- *string*

### `getCategory()`

Return the category from the type registry.

**Returns**

- *string*

### `getStat(key)`

Return the value of a stat, or nil if not set.

**Parameters**

- `key` *string*

**Returns**

- *number|nil*

### `setStat(key, val)`

Set or override a stat value.

**Parameters**

- `key` *string*
- `val` *number*

### `addStat(key, delta)`

Add delta to an existing stat (creates stat at delta if absent).

**Parameters**

- `key` *string*
- `delta` *number*

### `removeStat(key)`

Remove a stat entirely.

**Parameters**

- `key` *string*

### `getStats()`

Return all current stats as a shallow copy.

**Returns**

- *table* — key->value map

### `hasTag(tag)`

Return true if this item has the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `addTag(tag)`

Add a tag (no-op if already present).

**Parameters**

- `tag` *string*

### `removeTag(tag)`

Remove a tag. Returns true if tag existed.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `getTags()`

Return all tag names as a sorted array.

**Returns**

- *table*

### `setMeta(key, val)`

Set a metadata value.

**Parameters**

- `key` *string*
- `val` *any*

### `getMeta(key)`

Get a metadata value, or nil.

**Parameters**

- `key` *string*

**Returns**

- *any*

### `setOwner(owner)`

Set the owner reference.

**Parameters**

- `owner` *any*

### `getOwner()`

Return the owner reference.

**Returns**

- *any*

### `getName()`

Return the display name (seeds from type def; may differ from type name).

**Returns**

- *string*

### `setName(n)`

Set the display name.

**Parameters**

- `n` *string*

### `getSlot()`

Return the current slot/position name.

**Returns**

- *string*

### `setSlot(s)`

Set the slot/position name.

**Parameters**

- `s` *string*

### `getCounter(key)`

Get a named integer counter (0 if not set).

**Parameters**

- `key` *string*

**Returns**

- *number*

### `setCounter(key, val)`

Set a named integer counter.

**Parameters**

- `key` *string*
- `val` *number*

### `addCounter(key, delta)`

Add delta to a named counter and return the new value.

**Parameters**

- `key` *string*
- `delta` *number*

**Returns**

- *number*

### `removeCounter(key)`

Remove a named counter entry.

**Parameters**

- `key` *string*

### `getCounters()`

Return all counters as a shallow copy.

**Returns**

- *table* — key -> number

### `clone()`

Deep-copy this item instance (stats, tags, meta, counters, slot, name — NOT owner). TODO(P4 lift): replace with `lurek.data.deepCopy(it)` once that helper ships (P4 lift candidate). The local fallback below preserves identical behaviour and is safe on both LuaJIT and Lua 5.4.

**Returns**

- *table* — new Item

### `newStack(name, capacity)`

Create a named stack with optional capacity limit. Acts as both a LIFO stack and a positional list.

**Parameters**

- `name` *string* — Identifier for debugging.
- `capacity` *number* — Max item count. 0 = unlimited.

**Returns**

- *table* — Stack object.

### `getName()`

Return the stack name.

**Returns**

- *string*

### `size()`

Return number of items.

**Returns**

- *number*

### `getCapacity()`

Return capacity (0 = unlimited).

**Returns**

- *number*

### `setCapacity(n)`

Set or update capacity (0 = unlimited).

**Parameters**

- `n` *number*

### `isFull()`

Return true if at capacity.

**Returns**

- *boolean*

### `clear()`

Remove all items.

### `push(it)`

Push item onto top (returns false if capacity full).

**Parameters**

- `it` *table* — Item object.

**Returns**

- *boolean*

### `pushBottom(it)`

Push item onto bottom. Returns false if full.

**Parameters**

- `it` *table* — Item object.

**Returns**

- *boolean*

### `pop()`

Pop and return top item, or nil if empty.

**Returns**

- *table|nil*

### `popTop()`

Alias for pop.

**Returns**

- *table|nil*

### `popBottom()`

Remove and return bottom item, or nil if empty.

**Returns**

- *table|nil*

### `peekBottom()`

Peek at bottom item without removing it.

**Returns**

- *table|nil*

### `peek()`

Peek at top item without removing it.

**Returns**

- *table|nil*

### `getItem()`

Alias for peek (slot compat).

**Returns**

- *table|nil*

### `peekAt(idx)`

Peek at item at 1-based index without removing. Returns nil if out of range.

**Parameters**

- `idx` *number* — 1-based.

**Returns**

- *table|nil*

### `removeAt(idx)`

Remove and return item at 1-based index. Returns nil if out of range.

**Parameters**

- `idx` *number*

**Returns**

- *table|nil*

### `insertAt(idx, it)`

Insert item at 1-based position. Returns false if full or index invalid.

**Parameters**

- `idx` *number* — Position (1 = bottom, #items+1 = top).
- `it` *table* — Item object.

**Returns**

- *boolean*

### `findFirst(pred)`

Return the first item for which predicate(item) is true. Nil if none.

**Parameters**

- `pred` *function*

**Returns**

- *table|nil*

### `getItems()`

Return a shallow copy of all items (bottom to top).

**Returns**

- *table*

### `isEmpty()`

Return true if the stack has no items.

**Returns**

- *boolean*

### `popMany(n)`

Pop n items from the top. Returns array of items (may be shorter if stack runs out).

**Parameters**

- `n` *number*

**Returns**

- *table*

### `moveWithin(from, to)`

Move item at index `from` to index `to` (both 1-based). Returns false if invalid.

**Parameters**

- `from` *number*
- `to` *number*

**Returns**

- *boolean*

### `searchByType(type_name)`

Return all items whose type matches. Uses item:getType().

**Parameters**

- `type_name` *string*

**Returns**

- *table*

### `searchByTag(tag)`

Return all items that have the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *table*

### `searchByCategory(cat)`

Return all items in the given category.

**Parameters**

- `cat` *string*

**Returns**

- *table*

### `findByType(type_name)`

Return first item with the given type (or nil).

**Parameters**

- `type_name` *string*

**Returns**

- *table|nil*

### `findByTag(tag)`

Return first item with the given tag (or nil).

**Parameters**

- `tag` *string*

**Returns**

- *table|nil*

### `countByType(type_name)`

Count items with the given type.

**Parameters**

- `type_name` *string*

**Returns**

- *number*

### `countByCategory(cat)`

Count items in the given category.

**Parameters**

- `cat` *string*

**Returns**

- *number*

### `countByTag(tag)`

Count items with the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *number*

### `sortByStat(stat)`

Sort items ascending by a numeric stat. Items without the stat sort last.

**Parameters**

- `stat` *string*

### `sortByStatDesc(stat)`

Sort items descending by a numeric stat.

**Parameters**

- `stat` *string*

### `sortByCategory()`

Sort items by category (alphabetical).

### `sortByName()`

Sort items by type name (alphabetical).

### `shuffle()`

Shuffle items in-place (Fisher-Yates). TODO(P4 lift): replace with `lurek.math.shuffle(_items)` once that helper ships (P4 lift candidate; would also fix the LuaJIT vs Lua 5.4 RNG divergence noted in P4_lift_candidates.md).

### `peekTopNTypes(n)`

Return the type names of the top n items (without removing).

**Parameters**

- `n` *number*

**Returns**

- *table* — type name strings, top-first

### `newItemPool()`

Create a weighted loot pool. Supports weighted draw, bulk multi-draw, and unique-draw operations.

**Returns**

- *table* — ItemPool object.

### `size()`

Return number of entries.

**Returns**

- *number*

### `isEmpty()`

Return true if the pool has no entries.

**Returns**

- *boolean*

### `totalWeight()`

Return the sum of all entry weights.

**Returns**

- *number*

### `getEntries()`

Return all entries as array of {type_name, weight}.

**Returns**

- *table*

### `addType(type_name, weight)`

Add a type with a given weight. If type already present, adds another entry.

**Parameters**

- `type_name` *string*
- `weight` *number* — Must be > 0.

### `setWeight(type_name, weight)`

Update the weight of the first matching entry. Returns false if not found.

**Parameters**

- `type_name` *string*
- `weight` *number* — Must be > 0.

**Returns**

- *boolean*

### `remove(type_name)`

Remove the first entry of type_name. Returns false if not found.

**Parameters**

- `type_name` *string*

**Returns**

- *boolean*

### `draw()`

Draw one random item (weighted). Returns nil if pool is empty or total weight is zero.

**Returns**

- *table|nil* — Item object, or nil on empty/zero-weight pool.

### `drawTypes(n)`

Draw n items (with replacement). Entries from an empty pool are skipped (nil).

**Parameters**

- `n` *number*

**Returns**

- *table* — Array of Item objects (may contain nil entries if pool is empty).

### `drawUniqueTypes(n)`

Draw up to n unique type names (no type drawn twice), returns array of Items. If n exceeds the number of distinct types in the pool, returns all distinct types.

**Parameters**

- `n` *number* — Maximum unique types to draw.

**Returns**

- *table* — Array of Item objects (length <= n).

### `newStackBuilder()`

Create a stack builder for constructing stacks from a recipe list.

**Returns**

- *table* — StackBuilder object.

### `add(type_name, count)`

Add items of a type to the recipe.

**Parameters**

- `type_name` *string*
- `count` *number*

### `addWith(type_name, count, stat_overrides, extra_tags)`

Add items with per-item stat overrides and extra tags. Unlike add(), overrides are applied immediately to pre-built item instances.

**Parameters**

- `type_name` *string*
- `count` *number*
- `stat_overrides` *table* — key->value stat map.
- `extra_tags` *table* — list of tag strings.

### `setShuffleOnBuild(enabled)`

Enable or disable Fisher-Yates shuffle after build.

**Parameters**

- `enabled` *boolean*

### `requireType(type_name)`

Require that a specific type appears at least once.

**Parameters**

- `type_name` *string*

### `banType(type_name)`

Ban a specific type from appearing.

**Parameters**

- `type_name` *string*

### `removeBannedType(type_name)`

Remove a ban on a type.

**Parameters**

- `type_name` *string*

### `build(name)`

Build the stack from recipe entries plus addWith items. Applies shuffleOnBuild if enabled.

**Parameters**

- `name` *string* — Stack name.

**Returns**

- *table* — Stack

### `validateEntries()`

Validate the current recipe + addWith items against required/banned constraints. Returns nil on success, or an error string on failure.

**Returns**

- *string|nil*

### `validateStack(stack)`

Validate a pre-built stack against required/banned constraints. Returns nil on success, or an error string on failure.

**Parameters**

- `stack` *table*

**Returns**

- *string|nil*

### `buildNamed(name)`

Build the stack with a custom name (alias for build).

**Parameters**

- `name` *string*

**Returns**

- *table* — Stack

### `newStackHistory(max_entries)`

Create a bounded event history for stack operations.

**Parameters**

- `max_entries` *number* — Maximum entries to retain.

**Returns**

- *table* — StackHistory object.

### `recordPush(source, item_type, size_after)`

Record a push action.

**Parameters**

- `source` *string* — Stack name or label.
- `item_type` *string* — Type name of pushed item.
- `size_after` *number* — Stack size after the push.

### `recordPop(source, item_type, size_after)`

Record a pop action.

**Parameters**

- `source` *string*
- `item_type` *string*
- `size_after` *number*

### `recordClear(source)`

Record a clear action.

**Parameters**

- `source` *string*

### `recordCustom(source, label, size_after)`

Record a custom event.

**Parameters**

- `source` *string*
- `label` *string*
- `size_after` *number*

### `entries()`

Return all recorded entries (oldest first). Each entry has: action, source, item_type, size_after.

**Returns**

- *table*

### `getLastN(n)`

Return the last n entries, or all if n > count.

**Parameters**

- `n` *number*

**Returns**

- *table*

### `clear()`

Clear all log entries.

### `count()`

Return number of entries.

**Returns**

- *number*

### `isEmpty()`

Return true if no events have been recorded.

**Returns**

- *boolean*

### `last()`

Return the most recent entry, or nil if empty.

**Returns**

- *table|nil*

### `entriesFor(source)`

Return all entries matching a specific source name.

**Parameters**

- `source` *string*

**Returns**

- *table*

### `newStackManager()`

Create a named-stack manager.

**Returns**

- *table* — StackManager object.

### `addStack(name, stack)`

Register a stack.

**Parameters**

- `name` *string*
- `stack` *table*

### `getStack(name)`

Retrieve a stack by name.

**Parameters**

- `name` *string*

**Returns**

- *table|nil*

### `removeStack(name)`

Remove a stack. Returns true if existed.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `keys()`

Return all registered stack names.

**Returns**

- *table*

### `hasStack(name)`

Return true if a stack with this name exists.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `createStack(name)`

Create and register a new empty unlimited stack.

**Parameters**

- `name` *string*

### `createStackCapped(name, capacity)`

Create and register a new empty stack with a capacity limit.

**Parameters**

- `name` *string*
- `capacity` *number*

### `totalItems()`

Return total number of items across all stacks.

**Returns**

- *number*

### `moveItem(from, index, to)`

Move item at 1-based index from one stack to the top of another. Returns the moved item on success, or nil plus an error string on failure.

**Parameters**

- `from` *string* — Source stack name.
- `index` *number* — 1-based index.
- `to` *string* — Destination stack name.

**Returns**

- *table|nil*
- *string|nil*

### `moveItemByType(from, item_type, to)`

Move the first item of a given type from one stack to the top of another. Returns the moved item on success, or nil plus an error string on failure.

**Parameters**

- `from` *string* — Source stack name.
- `item_type` *string* — Type name to search for.
- `to` *string* — Destination stack name.

**Returns**

- *table|nil*
- *string|nil*

### `moveTop(from, to)`

Move the top item from one stack to the top of another. Returns the moved item on success, or nil plus an error string on failure.

**Parameters**

- `from` *string*
- `to` *string*

**Returns**

- *table|nil*
- *string|nil*

### `newSlot(name, capacity)`

Create a named slot with optional capacity limit. A slot is a bounded named position that holds zero or more items.

**Parameters**

- `name` *string* — Identifier for this slot.
- `capacity` *number* — Max item count; nil or 0 = unlimited.

**Returns**

- *table* — Slot object.

### `getName()`

Return the slot name.

**Returns**

- *string*

### `size()`

Return number of items in the slot.

**Returns**

- *number*

### `isEmpty()`

Return true if the slot is empty.

**Returns**

- *boolean*

### `isFull()`

Return true if the slot is at capacity.

**Returns**

- *boolean*

### `getCapacity()`

Return capacity (0 = unlimited).

**Returns**

- *number*

### `setCapacity(n)`

Set or update capacity (0 = unlimited).

**Parameters**

- `n` *number*

### `push(it)`

Add an item to the slot. Returns true on success, false if at capacity.

**Parameters**

- `it` *table* — Item object.

**Returns**

- *boolean*

### `pop()`

Remove and return the last item, or nil if empty.

**Returns**

- *table|nil*

### `removeAt(index)`

Remove and return the item at 1-based index, or nil if out of range.

**Parameters**

- `index` *number*

**Returns**

- *table|nil*

### `peek()`

Peek at the last item without removing it.

**Returns**

- *table|nil*

### `peekAt(index)`

Peek at item at 1-based index without removing it.

**Parameters**

- `index` *number*

**Returns**

- *table|nil*

### `clear()`

Remove all items and return them as an array.

**Returns**

- *table*

### `items()`

Return a shallow copy of all items.

**Returns**

- *table*

### `hasItemWithTag(tag)`

Return true if any item has the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `hasItemOfType(item_type)`

Return true if any item is of the given type.

**Parameters**

- `item_type` *string*

**Returns**

- *boolean*

### `findNOfStat(items, stat, n)`

Return 0-based indices of the top N items ranked by a stat (descending).

**Parameters**

- `items` *table* — Array of Item objects.
- `stat` *string* — Stat name.
- `n` *number* — How many to return.

**Returns**

- *table* — Array of 0-based integer indices.

### `groupByStat(items, stat_key)`

Group items by a stat value. Returns map {value -> array of Items}. Items without the stat are grouped under the key false.

**Parameters**

- `items` *table* — Array of Item objects.
- `stat_key` *string*

**Returns**

- *table*

### `groupByTagPrefix(items, prefix)`

Group items by tag prefix. Returns map {prefix_value -> array of Items}. A tag matches if it starts with `prefix` (e.g. prefix "tier:" matches "tier:1", "tier:2"). Items with no matching tag go under key "".

**Parameters**

- `items` *table* — Array of Item objects.
- `prefix` *string* — Tag prefix to filter on.

**Returns**

- *table*

### `findSequences(items, stat_key)`

Find runs (consecutive sequences) of items sharing the same stat value. Returns array of {value, start_idx, length} (1-based start_idx).

**Parameters**

- `items` *table* — Array of Item objects.
- `stat_key` *string*

**Returns**

- *table*

### `groupByCategory(items)`

Group items by category. Returns table: category -> {Item, ...}.

**Parameters**

- `items` *table* — list of Item objects.

**Returns**

- *table*

### `findAtLeastNOfStat(items, stat, n)`

Return items where getStat(stat) >= n.

**Parameters**

- `items` *table*
- `stat` *string*
- `n` *number*

**Returns**

- *table*

### `findTagGroups(items)`

Group items by shared tag prefix. Returns table: prefix -> {Item, ...}. A "tag group" is a set of items that share at least one tag.

**Parameters**

- `items` *table*

**Returns**

- *table* — tag -> {Item, ...}

### `sortedIndicesByStat(items, stat, ascending)`

Return 1-based indices sorted by a stat.

**Parameters**

- `items` *table*
- `stat` *string*
- `ascending` *boolean* — true = lowest first (default), false = highest first.

**Returns**

- *table* — indices

### `sortedIndicesByCategory(items)`

Return 1-based indices sorted by category (alphabetical).

**Parameters**

- `items` *table*

**Returns**

- *table* — indices
