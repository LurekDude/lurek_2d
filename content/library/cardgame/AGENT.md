# `cardgame` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/cardgame/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_cardgame.lua` |
| **Depends on** | `lurek.*` public API only |

## Summary

Card-game engine with typed card definitions, stacks, pools, slots, and
analysis helpers. `CardTypeDef` defines the blueprint for a card type including
base stats, tags, rarity tier, and an optional `max_per_deck` cap validated by
`M.checkDeckLimit()`. Individual `Card` instances carry per-card state: numeric
stats (`getStat`/`setStat`/`addStat`), string tags, integer counters, and free
metadata. Card visual state is tracked via `face_up`, `tapped`, and tile
position (`tile_x`, `tile_y`) fields with dedicated helpers (`flip()`, `tap()`,
`untap()`, `setTilePosition()`).

`Stack` is an ordered or unordered card container with optional capacity; it
supports push/pop, peek, index-based removal, and insertion. `Slot` provides a
named single-card stage with optional capacity and type/tag filtering.
`CardPool` holds a weighted draw pool for randomised card distribution;
`DeckBuilder` accumulates cards with per-type validation before constructing a
final deck list.

Analysis helpers (`groupByStat`, `groupByCategory`, `groupByTagPrefix`,
`findNOfStat`, `findSequences`, `findTagGroups`, `findAtLeastNOfStat`,
`sortedIndicesByStat`, `sortedIndicesByCategory`) operate on flat card arrays.
`groupByStat` and `groupByTagPrefix` return index maps; `findNOfStat` and
`findSequences` return `CardGroup` objects that reference slots within the
original list by 1-based index, allowing pattern detection without copying cards.

## Architecture

```
CardTypeDef registry (_card_types)
  │
  └── defines base_stats, base_tags, rarity, max_per_deck

Card (instance)
  ├── stats / counters / tags / metadata
  ├── face_up, tapped
  └── tile_x, tile_y

Stack  ──── ordered/unordered card container with capacity
Slot   ──── named single-card stage with filter
CardPool ── weighted draw pool → drawOne() / drawMany()
DeckBuilder ── validated deck accumulator → build()

CardGroup
  ├── indices into a flat card list
  ├── label, score
  └── helpers: itemsFrom(), maxStat(), totalStat(), allHaveTag()

Analysis free functions
  ├── groupByStat(items,stat)            → {val→indices}
  ├── groupByCategory(items)            → {cat→items}
  ├── groupByTagPrefix(items,prefix)    → {val→indices}
  ├── findNOfStat(items,stat,n)         → [CardGroup]  (exact n)
  ├── findAtLeastNOfStat(items,stat,n)  → [items]      (>= n)
  ├── findSequences(items,stat,min_run) → [CardGroup]  (consecutive run)
  ├── findTagGroups(items)              → {tag→items}
  ├── sortedIndicesByStat(items,stat)   → [indices]
  └── sortedIndicesByCategory(items)   → [indices]

M.HistoryAction  ──  pushed | popped | moved | shuffled | sorted | cleared | built | custom
```

## Source Files

| File | Purpose |
|------|---------|
| `library/cardgame/init.lua` | Full implementation — CardTypeDef, Card, Stack, Slot, CardPool, DeckBuilder, CardGroup, analysis helpers |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|--------|
| `CardTypeDef` | `M.newCardTypeDef(name)` | Blueprint: base stats, rarity, deck limit |
| `Card` | `M.newCard(card_type)` | Mutable instance with stats, tags, counters, visual state |
| `Stack` | `M.newStack(name)` / `M.newStackWithCapacity(name, cap)` | Ordered card container with optional capacity |
| `Slot` | `M.newSlot(name)` / `M.newSlotWithCapacity(name, cap)` | Named single-card stage with filter |
| `CardPool` | `M.newCardPool(name)` | Weighted draw pool |
| `DeckBuilder` | `M.newDeckBuilder(name)` | Validated deck construction helper |
| `CardGroup` | `M.newCardGroup(label, indices, score)` | Index group for pattern analysis |
| `StackHistory` | `M.newStackHistory()` | Append-only change log for stack mutations |
| `M.HistoryAction` | action record factory | Named action record constructors (moved, shuffled, sorted, built, etc.) |
| `M.groupByStat` | free function | Group 1-based indices by integer stat value → `{val={indices}}` |
| `M.groupByCategory` | free function | Group items by category string → `{cat={items}}` |
| `M.groupByTagPrefix` | free function | Group 1-based indices by prefixed tag value → `{val={indices}}` |
| `M.findNOfStat` | free function | Find CardGroups where exactly n items share a stat value |
| `M.findAtLeastNOfStat` | free function | Return items where a named stat is >= n |
| `M.findSequences` | free function | Find CardGroups forming consecutive integer runs of a stat |
| `M.findTagGroups` | free function | Return items grouped by shared tags (>1 member per tag) |
| `M.sortedIndicesByStat` | free function | Return 1-based indices sorted by a named stat (ascending) |
| `M.sortedIndicesByCategory` | free function | Return 1-based indices sorted by category string |
