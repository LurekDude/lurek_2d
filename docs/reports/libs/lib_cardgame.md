# `library.cardgame`

*171 functions, 0 module fields documented.*

## Functions

### `getIdCounter()`

Return the current value of the internal ID counter (next ID to assign). Lua doubles are exact up to 2^53 (9007199254740992).

**Returns**

- *number* — Current counter value.

### `resetIdCounter()`

Reset the ID counter to 1.  Call between game sessions to reclaim the integer range.  Does NOT invalidate already-created cards — callers must ensure no stale references remain.

### `defineCardType(name, def)`

Register or overwrite a card type definition.

**Parameters**

- `name` *string* — Type name used as registry key (must be non-empty).
- `def` *table* — CardTypeDef table to store.

### `getCardType(name)`

Look up a card type by name; returns nil if not found.

**Parameters**

- `name` *string* — Registry key.

**Returns**

- *table|nil* — CardTypeDef or nil.

### `getCardTypeNames()`

Return a sorted list of all registered type names.

**Returns**

- *table* — Alphabetically sorted array of name strings.

### `clearCardTypes()`

Clear all card type definitions from the module registry.

### `newCardTypeDef(name)`

Create a new card type definition (blueprint). CardTypeDef fields:

**Parameters**

- `name` *string* — Type name (must be non-empty).

**Returns**

- *table* — CardTypeDef.

### `newCard(card_type)`

Create a new card instance.  Seeds fields from the registry if the type is defined.  Each card receives a unique auto-incrementing integer ID. Card fields:

**Parameters**

- `card_type` *string* — Registered type name.

**Returns**

- *Card*

### `getStat(key)`

Return the numeric stat value for key, or 0 if not set.

**Parameters**

- `key` *string*

**Returns**

- *number*

### `setStat(key, val)`

Set a numeric stat to an exact value.

**Parameters**

- `key` *string*
- `val` *number*

### `addStat(key, delta)`

Add delta to a stat and return the new value.

**Parameters**

- `key` *string*
- `delta` *number*

**Returns**

- *number*

### `removeStat(key)`

Remove a stat entry entirely.

**Parameters**

- `key` *string*

### `hasTag(tag)`

Return true if the tag is present on this card.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `addTag(tag)`

Add a tag if not already present.

**Parameters**

- `tag` *string*

### `removeTag(tag)`

Remove the first occurrence of tag; returns true if it was present.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `getCounter(key)`

Return the named counter value, or 0 if not set.

**Parameters**

- `key` *string*

**Returns**

- *number*

### `setCounter(key, v)`

Set a named counter to an exact value.

**Parameters**

- `key` *string*
- `v` *number*

### `addCounter(key, delta)`

Add delta to a counter and return the new value.

**Parameters**

- `key` *string*
- `delta` *number*

**Returns**

- *number*

### `removeCounter(key)`

Remove a counter entry entirely.

**Parameters**

- `key` *string*

### `getMeta(key)`

Return a metadata string, or nil if not set.

**Parameters**

- `key` *string*

**Returns**

- *string|nil*

### `setMeta(key, val)`

Store an arbitrary metadata string.

**Parameters**

- `key` *string*
- `val` *string*

### `resetStats()`

Reset stats from the registered type definition, discarding per-instance overrides.

### `flip()`

Flip the card face (toggles face_up).

### `tap()`

Tap this card (mark as used/exhausted).

### `untap()`

Untap this card (reset exhausted state).

### `isFaceUp()`

Return true if the card is face-up.

**Returns**

- *boolean*

### `isTapped()`

Return true if the card is tapped.

**Returns**

- *boolean*

### `setRarity(r)`

Set the rarity tier string.

**Parameters**

- `r` *string* — e.g. "common", "rare", "legendary"

### `getRarity()`

Get the rarity tier string.

**Returns**

- *string*

### `setTilePosition(x, y)`

Set the tile grid position for board layout.

**Parameters**

- `x` *number*
- `y` *number*

### `getTilePosition()`

Get the tile grid position.

**Returns**

- *number,* — number  x, y

### `newStack(name)`

Create a new unbounded Stack. Stack fields:

**Parameters**

- `name` *string* — Stack name.

**Returns**

- *Stack*

### `newStackWithCapacity(name, cap)`

Create a new Stack with a fixed capacity limit.

**Parameters**

- `name` *string* — Stack name.
- `cap` *number* — Maximum card count (must be >= 1).

**Returns**

- *Stack*

### `size()`

Return the number of cards.

**Returns**

- *number*

### `isEmpty()`

Return true when the stack contains no cards.

**Returns**

- *boolean*

### `isFull()`

Return true when the stack has reached its capacity limit.

**Returns**

- *boolean*

### `capacity()`

Return the capacity limit, or nil for unlimited.

**Returns**

- *number|nil*

### `setCapacity(cap)`

Set or remove the capacity limit (nil = unlimited).

**Parameters**

- `cap` *number|nil*

### `pushTop(card)`

Push a card onto the top of the stack; returns false when full.

**Parameters**

- `card` *Card*

**Returns**

- *boolean*

### `pushBottom(card)`

Push a card onto the bottom of the stack; returns false when full.

**Parameters**

- `card` *Card*

**Returns**

- *boolean*

### `popTop()`

Remove and return the top card, or nil if empty.

**Returns**

- *Card|nil*

### `popBottom()`

Remove and return the bottom card, or nil if empty.

**Returns**

- *Card|nil*

### `popMany(n)`

Pop up to n cards from the top and return them.

**Parameters**

- `n` *number*

**Returns**

- *table* — Array of Card (may be shorter than n if stack empties).

### `peekTop()`

Return the top card without removing it.

**Returns**

- *Card|nil*

### `peekBottom()`

Return the bottom card without removing it.

**Returns**

- *Card|nil*

### `peekAt(idx)`

Return the card at the given 1-based index without removing it.

**Parameters**

- `idx` *number*

**Returns**

- *Card|nil*

### `insertAt(idx, card)`

Insert card at position idx (1-based, clamped); returns false when full.

**Parameters**

- `idx` *number*
- `card` *Card*

**Returns**

- *boolean*

### `removeAt(idx)`

Remove and return the card at 1-based position idx, or nil if out of range.

**Parameters**

- `idx` *number*

**Returns**

- *Card|nil*

### `moveWithin(from, to)`

Move a card from one 1-based index to another within the same stack.

**Parameters**

- `from` *number*
- `to` *number*

**Returns**

- *boolean*

### `clear()`

Clear all cards and return them.

**Returns**

- *table* — Array of the removed cards.

### `searchByType(card_type)`

Return a list of 1-based indices of cards with the given type name.

**Parameters**

- `card_type` *string*

**Returns**

- *table* — Array of integer indices.

### `searchByTag(tag)`

Return a list of 1-based indices of cards that have the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *table* — Array of integer indices.

### `searchByCategory(cat)`

Return a list of 1-based indices of cards with the given category.

**Parameters**

- `cat` *string*

**Returns**

- *table* — Array of integer indices.

### `findByType(card_type)`

Return the 1-based index of the first card with the given type, or nil.

**Parameters**

- `card_type` *string*

**Returns**

- *number|nil*

### `findByTag(tag)`

Return the 1-based index of the first card with the given tag, or nil.

**Parameters**

- `tag` *string*

**Returns**

- *number|nil*

### `findByCategoryAll(cat)`

Return all Card objects with the given category.

**Parameters**

- `cat` *string*

**Returns**

- *table* — Array of Card objects.

### `findByTypeAll(type_name)`

Return all Card objects with the given type name.

**Parameters**

- `type_name` *string*

**Returns**

- *table* — Array of Card objects.

### `findByTagAll(tag)`

Return all Card objects that have the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *table* — Array of Card objects.

### `removeById(id)`

Remove and return the Card with the given id, or nil if not found.

**Parameters**

- `id` *number*

**Returns**

- *Card|nil*

### `containsId(id)`

Return true if a card with the given id is in the stack.

**Parameters**

- `id` *number*

**Returns**

- *boolean*

### `countByType(t)`

Return the count of cards with the given type name.

**Parameters**

- `t` *string*

**Returns**

- *number*

### `countByCategory(cat)`

Return the count of cards with the given category.

**Parameters**

- `cat` *string*

**Returns**

- *number*

### `countByTag(tag)`

Return the count of cards that have the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *number*

### `sortByStat(stat)`

Sort cards by a named stat in ascending order (in-place).

**Parameters**

- `stat` *string*

### `sortByStatDesc(stat)`

Sort cards by a named stat in descending order (in-place).

**Parameters**

- `stat` *string*

### `sortByCategory()`

Sort cards alphabetically by category field (in-place).

### `sortByName()`

Sort cards alphabetically by name field (in-place).

### `shuffle()`

Shuffle cards into a random order using Fisher-Yates. TODO(P4 lift): replace with lurek.math.shuffle when available so the shuffle becomes seedable and decoupled from the global RNG state.

See: [`lurek.math`](../lua-api.md#lurekmath)

### `items()`

Return the raw card array (by reference).

**Returns**

- *table*

### `peekTopNTypes(n)`

Return the type names of the top n cards (topmost first).

**Parameters**

- `n` *number*

**Returns**

- *table* — Array of type name strings.

### `snapshotCards()`

Return a shallow copy of the card array for later restoration.

**Returns**

- *table*

### `restoreCards(cards)`

Replace the card array with a previously snapshotted copy.

**Parameters**

- `cards` *table*

### `isOrdered()`

Return true when the stack preserves insertion order.

**Returns**

- *boolean*

### `setOrdered(b)`

Set whether the stack preserves order.

**Parameters**

- `b` *boolean*

### `isPublic()`

Return true when the stack contents are publicly visible.

**Returns**

- *boolean*

### `setPublic(b)`

Set whether the stack is publicly visible.

**Parameters**

- `b` *boolean*

### `setName(n)`

Rename the stack.

**Parameters**

- `n` *string*

### `newSlot(name)`

Create a new unbounded Slot. Slot fields:

**Parameters**

- `name` *string* — Slot name.

**Returns**

- *Slot*

### `newSlotWithCapacity(name, cap)`

Create a new Slot with a fixed capacity limit.

**Parameters**

- `name` *string* — Slot name.
- `cap` *number* — Maximum item count (must be >= 1).

**Returns**

- *Slot*

### `isEmpty()`

Return true when the slot contains no items.

**Returns**

- *boolean*

### `isFull()`

Return true when the slot has reached its capacity.

**Returns**

- *boolean*

### `size()`

Return the number of items in the slot.

**Returns**

- *number*

### `capacity()`

Return the capacity limit, or nil for unlimited.

**Returns**

- *number|nil*

### `setCapacity(cap)`

Set or remove the capacity limit (nil = unlimited).

**Parameters**

- `cap` *number|nil*

### `push(card)`

Push a card into the slot; returns true on success, false+error when full.

**Parameters**

- `card` *Card*

**Returns**

- *boolean*

### `pop()`

Remove and return the last pushed card, or nil if empty.

**Returns**

- *Card|nil*

### `removeAt(idx)`

Remove and return the item at 1-based index, or nil if out of range.

**Parameters**

- `idx` *number*

**Returns**

- *Card|nil*

### `peek()`

Return the last pushed item without removing it.

**Returns**

- *Card|nil*

### `peekAt(idx)`

Return the item at 1-based index without removing it.

**Parameters**

- `idx` *number*

**Returns**

- *Card|nil*

### `clear()`

Clear all items and return them.

**Returns**

- *table*

### `getItems()`

Return the raw items array (by reference).

**Returns**

- *table*

### `hasItemWithTag(tag)`

Return true if any item in the slot has the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `hasItemOfType(t)`

Return true if any item in the slot has the given type name.

**Parameters**

- `t` *string*

**Returns**

- *boolean*

### `newCardPool(name)`

Create a new empty CardPool. CardPool fields:

**Parameters**

- `name` *string* — Pool name.

**Returns**

- *CardPool*

### `add(type_name, weight)`

Add a type with a draw weight (minimum 1).

**Parameters**

- `type_name` *string* — Card type name (must be non-empty).
- `weight` *number* — Draw weight (clamped to minimum 1).

### `remove(type_name)`

Remove all entries for the given type name.

**Parameters**

- `type_name` *string*

### `setWeight(type_name, weight)`

Update the weight for an existing type entry (no-op if not found).

**Parameters**

- `type_name` *string*
- `weight` *number*

### `setName(n)`

Rename the pool.

**Parameters**

- `n` *string*

### `setRarityWeight(rarity, weight)`

Set a per-rarity draw weight used by drawByRarity.

**Parameters**

- `rarity` *string*
- `weight` *number*

### `totalWeight()`

Return the sum of all entry weights.

**Returns**

- *number*

### `size()`

Return the number of distinct entries in the pool.

**Returns**

- *number*

### `isEmpty()`

Return true when the pool has no entries.

**Returns**

- *boolean*

### `getWeight(type_name)`

Return the draw weight for a type name, or 0 if not present.

**Parameters**

- `type_name` *string*

**Returns**

- *number*

### `getTypeNames()`

Return an array of all type name strings in pool insertion order.

**Returns**

- *table*

### `drawTypes(n)`

Draw n type names by weighted random selection (with replacement).

**Parameters**

- `n` *number* — Number of draws.

**Returns**

- *table* — Array of type name strings.

### `drawItems(n)`

Draw n Card instances by weighted random selection (with replacement).

**Parameters**

- `n` *number*

**Returns**

- *table* — Array of Card objects.

### `drawUniqueTypes(n)`

Draw up to n unique type names by weighted selection without replacement.

**Parameters**

- `n` *number*

**Returns**

- *table* — Array of distinct type name strings.

### `drawUniqueItems(n)`

Draw up to n unique Card instances by weighted selection without replacement.

**Parameters**

- `n` *number*

**Returns**

- *table* — Array of Card objects.

### `drawItemsSeeded(n, seed)`

Draw n Card instances using a fixed random seed for reproducibility. Saves and restores the global RNG state across the call so callers outside the seeded scope continue to observe the global RNG sequence. TODO(P4 lift): use lurek.math.newRng()/lurek.math.shuffle when available to avoid touching the global RNG entirely.

**Parameters**

- `n` *number*
- `seed` *number*

**Returns**

- *table* — Array of Card objects.

See: [`lurek.math`](../lua-api.md#lurekmath)

### `drawByRarity(distribution)`

Draw cards matching a rarity distribution table {rarity=count,...}.

**Parameters**

- `distribution` *table* — Map of rarity string to draw count.

**Returns**

- *table* — Array of Card objects.

### `newStackManager()`

Create a new empty StackManager.

**Returns**

- *StackManager*

### `addStack(name, stack)`

Register an existing stack under a name.

**Parameters**

- `name` *string*
- `stack` *Stack*

### `createStack(name)`

Create and register a new unbounded stack.

**Parameters**

- `name` *string*

### `createStackCapped(name, cap)`

Create and register a new capacity-limited stack.

**Parameters**

- `name` *string*
- `cap` *number*

### `removeStack(name)`

Deregister and return a stack, or nil if not found.

**Parameters**

- `name` *string*

**Returns**

- *Stack|nil*

### `hasStack(name)`

Return true if a stack with the given name is registered.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `getStack(name)`

Return the registered Stack, or nil if not found.

**Parameters**

- `name` *string*

**Returns**

- *Stack|nil*

### `stackNames()`

Return a sorted list of all registered stack names.

**Returns**

- *table*

### `totalItems()`

Return the total number of cards across all registered stacks.

**Returns**

- *number*

### `moveItem(from_name, idx, to_name)`

Move the card at idx in from_name to the top of to_name.

**Parameters**

- `from_name` *string*
- `idx` *number* — 1-based index.
- `to_name` *string*

**Returns**

- *Card|nil,* — string|nil  Moved card or nil+error.

### `moveItemByType(from_name, card_type, to_name)`

Move the first card of a given type from one stack to another.

**Parameters**

- `from_name` *string*
- `card_type` *string*
- `to_name` *string*

**Returns**

- *Card|nil,* — string|nil

### `moveTop(from_name, to_name)`

Move the top card from one stack to another.

**Parameters**

- `from_name` *string*
- `to_name` *string*

**Returns**

- *Card|nil,* — string|nil

### `newBuildEntry(type_name, count)`

Create a new build entry for use with DeckBuilder.

**Parameters**

- `type_name` *string* — Card type to include.
- `count` *number* — Number of copies.

**Returns**

- *table* — BuildEntry.

### `newDeckBuilder(name)`

Create a new DeckBuilder.

**Parameters**

- `name` *string* — Default name for the constructed deck.

**Returns**

- *DeckBuilder*

### `add(type_name, count)`

Add count copies of type_name to the build list.

**Parameters**

- `type_name` *string* — Card type name (must be non-empty).
- `count` *number* — Number of copies (must be >= 1).

### `addWith(type_name, count, stat_overrides, extra_tags)`

Add count copies with per-card stat overrides and extra tags.

**Parameters**

- `type_name` *string*
- `count` *number*
- `stat_overrides` *table* — Map of stat_name Ôćĺ value.
- `extra_tags` *table* — Array of tag strings.

### `requireType(t)`

Mark a card type as required (must appear at least once in the deck).

**Parameters**

- `t` *string*

### `banType(t)`

Add a type to the ban list; validateEntries will report it as an error.

**Parameters**

- `t` *string*

### `removeBannedType(t)`

Remove a type from the ban list; returns true if it was present.

**Parameters**

- `t` *string*

**Returns**

- *boolean*

### `setMaxCopiesForType(t, max_val)`

Override the global max_copies limit for a specific type.

**Parameters**

- `t` *string*
- `max_val` *number*

### `addRequiredTag(tag, min_count)`

Require that at least min_count cards with the given tag appear.

**Parameters**

- `tag` *string*
- `min_count` *number*

### `addRequiredCategory(cat, min_count, max_count)`

Require a specific count range for cards of a given category.

**Parameters**

- `cat` *string*
- `min_count` *number*
- `max_count` *number|nil*

### `validateEntries()`

Validate the builder's entries against all constraints.

**Returns**

- *table* — Array of error strings (empty = valid).

### `validateStack(stack)`

Validate an already-built Stack against size constraints.

**Parameters**

- `stack` *Stack*

**Returns**

- *table* — Array of error strings.

### `build()`

Build and return a Stack using the builder's own name.

**Returns**

- *Stack*

### `buildNamed(stack_name)`

Build and return a Stack with a custom name.

**Parameters**

- `stack_name` *string*

**Returns**

- *Stack*

### `HistoryAction.pushed(card_type, item_name)`

Create a Pushed action recording which card was pushed.

**Parameters**

- `card_type` *string*
- `item_name` *string*

**Returns**

- *table*

### `HistoryAction.popped(card_type, item_name)`

Create a Popped action recording which card was popped.

**Parameters**

- `card_type` *string*
- `item_name` *string*

**Returns**

- *table*

### `HistoryAction.moved(card_type, item_name, from_stack, to_stack)`

Create a Moved action recording an inter-stack card transfer.

**Parameters**

- `card_type` *string*
- `item_name` *string*
- `from_stack` *string*
- `to_stack` *string*

**Returns**

- *table*

### `HistoryAction.shuffled()`

Create a Shuffled action.

**Returns**

- *table*

### `HistoryAction.sorted(by)`

Create a Sorted action recording the sort field.

**Parameters**

- `by` *string*

**Returns**

- *table*

### `HistoryAction.cleared()`

Create a Cleared action.

**Returns**

- *table*

### `HistoryAction.built(count)`

Create a Built action recording how many cards were built.

**Parameters**

- `count` *number*

**Returns**

- *table*

### `HistoryAction.custom(label)`

Create a user-defined Custom action.

**Parameters**

- `label` *string*

**Returns**

- *table*

### `newStackHistory()`

Create a new unlimited StackHistory.

**Returns**

- *StackHistory*

### `newStackHistoryWithMaxSize(max_size)`

Create a StackHistory that keeps only the most recent max_size entries.

**Parameters**

- `max_size` *number*

**Returns**

- *StackHistory*

### `record(stack_name, action, size_after)`

Append an action entry to the log.

**Parameters**

- `stack_name` *string*
- `action` *table* — A HistoryAction table.
- `size_after` *number* — Stack size after the action.

### `recordCustom(stack_name, label, size_after)`

Append a user-defined label as a Custom action.

**Parameters**

- `stack_name` *string*
- `label` *string*
- `size_after` *number*

### `len()`

Return the number of recorded entries.

**Returns**

- *number*

### `isEmpty()`

Return true when no entries have been recorded.

**Returns**

- *boolean*

### `entries()`

Return the entries array (oldest first).

**Returns**

- *table*

### `last()`

Return the most recent entry, or nil if empty.

**Returns**

- *table|nil*

### `entriesFor(stack_name)`

Return all entries for the given stack name.

**Parameters**

- `stack_name` *string*

**Returns**

- *table* — Array of history entry tables.

### `clear()`

Clear all recorded entries.

### `newCardGroup(label, indices, score)`

Create a new CardGroup with a label, index list, and optional score.

**Parameters**

- `label` *string* — Human-readable group label.
- `indices` *table* — Array of 1-based indices into a card list.
- `score` *number|nil* — Optional numeric score (default 0).

**Returns**

- *CardGroup*

### `itemsFrom(cards)`

Collect the actual card objects referenced by this group's indices.

**Parameters**

- `cards` *table* — Flat array of Card objects.

**Returns**

- *table* — Array of Card objects.

### `size()`

Return the number of cards in the group.

**Returns**

- *number*

### `isEmpty()`

Return true when the group has no cards.

**Returns**

- *boolean*

### `maxStat(cards, stat)`

Return the highest value of a stat across grouped cards.

**Parameters**

- `cards` *table* — flat card list
- `stat` *string*

**Returns**

- *number*

### `totalStat(cards, stat)`

Return the sum of a stat across grouped cards.

**Parameters**

- `cards` *table*
- `stat` *string*

**Returns**

- *number*

### `allHaveTag(cards, tag)`

Return true if every card in the group has the given tag.

**Parameters**

- `cards` *table*
- `tag` *string*

**Returns**

- *boolean*

### `checkDeckLimit(cards)`

Validate that a card list does not exceed per-type max_per_deck limits. Returns nil on success or an error string describing the first violation.

**Parameters**

- `cards` *table* — list of Card objects

**Returns**

- *string|nil*

### `groupByCategory(items)`

Group card-like items by category field. Returns table: category -> {item,...}.

**Parameters**

- `items` *table* — list of objects with a .category field or getCategory()

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

Return each unique tag that appears on more than one item, with the items list.

**Parameters**

- `items` *table*

**Returns**

- *table* — tag -> {item,...}

### `sortedIndicesByStat(items, stat)`

Return 1-based indices sorted by a stat (ascending).

**Parameters**

- `items` *table*
- `stat` *string*

**Returns**

- *table* — indices

### `sortedIndicesByCategory(items)`

Return 1-based indices sorted by category (alphabetical).

**Parameters**

- `items` *table*

**Returns**

- *table* — indices

### `groupByStat(items, stat)`

Group 1-based indices of items by the integer value of a named stat. Returns a map of stat_value (floored to integer) Ôćĺ array of 1-based indices.

**Parameters**

- `items` *table* — List of Card objects.
- `stat` *string* — Stat name to group by.

**Returns**

- *table* — {[stat_value] = {1-based indices}}.

### `groupByTagPrefix(items, prefix)`

Group 1-based indices by the value portion of a prefixed tag. Tags of the form "prefix:value" are grouped under "value". Tags that do not start with prefix: are ignored.

**Parameters**

- `items` *table* — List of Card objects.
- `prefix` *string* — Tag prefix to match (e.g. "suit" matches "suit:hearts").

**Returns**

- *table* — {[tag_value] = {1-based indices}}.

### `findNOfStat(items, stat, n)`

Find all groups where exactly n items share the same integer stat value. Analogous to "n-of-a-kind" detection in card games.

**Parameters**

- `items` *table* — List of Card objects.
- `stat` *string* — Stat name to compare.
- `n` *number* — Exact group size required.

**Returns**

- *table* — Array of CardGroup objects (one per qualifying set).

### `findSequences(items, stat, min_run)`

Find all runs of consecutive integer stat values with length >= min_run. Useful for "straight" or sequential-run detection in card games. Each run is returned as a CardGroup whose indices reference the original list.

**Parameters**

- `items` *table* — List of Card objects.
- `stat` *string* — Stat name to use for sequencing.
- `min_run` *number* — Minimum run length to include.

**Returns**

- *table* — Array of CardGroup objects (one per run found).
