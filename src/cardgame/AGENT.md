# `cardgame` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.cardgame` |
| **Source** | `src/cardgame/` |
| **Tests** | `tests/cardgame_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_cardgame.lua` |

## Summary

Card data structures, deck management, and stack operations for any
card-based game mechanic. `Card` instances are created from named
`CardTypeDef` blueprints that define default stats and tags; the global
thread-local type registry maps type names to definitions and seeds defaults
at construction time. `Stack` is the primary collection — an ordered
Vec of Cards with configurable max size, filter policies, and optional
`StackHistory` for undo/redo or audit logging. `Slot` is a bounded
single-position container (capacity-1 Stack) with put/take semantics for
equipment-style card placement. `StackManager` groups multiple named Stacks
as a logical unit (hand, draw pile, discard, equipped). `DeckBuilder`
constructs Stacks from template `BuildEntry` lists with constraint
validation. `CardPool` provides weighted random card-type draws. Group
analysis functions in `group.rs` detect patterns in card slices — runs of
consecutive stat values, tag-prefix groups, N-of-a-kind — forming the
foundation for combo detection, set-matching, and scoring logic.

## Architecture

```
CardTypeDef registry (thread-local)
  └── define_card_type(name, ...) / get_card_type(name)
        └── Seeds defaults into Card::new(type_name)

Card (instance)
  ├── type_name: String
  ├── stats: HashMap<String, f64>
  ├── tags: HashSet<String>
  └── face_up: bool

Stack (ordered card collection)
  ├── cards: Vec<Card>
  ├── max_size: Option<usize>
  ├── history: Option<StackHistory>
  └── Operations: push/pop/draw/insert/remove/swap/sort/shuffle

  Slot (bounded single-position)
  └── Wraps Stack(max=1) with put/take API

StackManager (multi-stack container)
  └── stacks: HashMap<String, Stack>
        ── add_stack / get / transfer_between

DeckBuilder (template-driven construction)
  └── entries: Vec<BuildEntry { type_name, count, overrides }>
        ── build(registry) → Result<Stack, String>

CardPool (weighted random draw)
  └── entries: Vec<(type_name, weight)>
        ── draw() → &str

StackHistory (action log / undo)
  └── log: VecDeque<ActionRecord>
        ── HistoryAction: Add|Remove|Move|Swap|Sort|Shuffle|Clear|...

Group analysis (group.rs — stateless functions)
  ├── group_by_stat / group_by_category / group_by_tag_prefix
  ├── find_n_of_stat / find_sequences / find_tag_groups
  └── sorted_indices_by_stat / sorted_indices_by_category
```

## Source Files

| File | Purpose |
|------|---------|
| `builder.rs` | Stack builder — template-based stack construction with validation |
| `card.rs` | Card type definitions, the global type registry, and card instances |
| `group.rs` | Group analysis — stat-based and tag-based grouping of item slices |
| `history.rs` | Change history — append-only log of stack mutations |
| `manager.rs` | Stack manager — organises multiple named `Stack` instances as a unit |
| `pool.rs` | Weighted item-type pool for random selection |
| `slot.rs` | Slot — a bounded named position that holds a small set of items |
| `stack.rs` | Ordered card collection — a stack, pile, hand, zone, or any linear sequence of... |

## Submodules

### `cardgame::builder`

Stack builder — template-based stack construction with validation.

- **`BuildEntry`** (struct): One "slot" in a stack template: an card type plus a count and optional overrides.
- **`DeckBuilder`** (struct): Builds a `Stack` from `BuildEntry` templates and validates construction constraints.  Constraints (min/max size, max...

### `cardgame::card`

Card type definitions, the global type registry, and card instances.

- **`CardTypeDef`** (struct): Template that describes a class of items (the "blueprint").  Stats, tags, and metadata defined here are seeded into...
- **`define_card_type`** (fn): Register (or overwrite) an card type in the thread-local type registry.
- **`get_card_type`** (fn): Look up an card type definition by name. Returns `None` if not found.
- **`get_card_type_names`** (fn): Return all registered type names. This accessor incurs no allocation; call it freely in hot paths.
- **`clear_card_types`** (fn): Remove all entries from the registry. After this call the container is in the same state as immediately after...
- **`Card`** (struct): A single card instance. Consult the module-level documentation for the broader usage context and preconditions.  All...

### `cardgame::group`

Group analysis — stat-based and tag-based grouping of item slices.

- **`CardGroup`** (struct): A labelled subset of an item slice, referenced by index.  Indices refer to positions in the original `&[Card]` slice...
- **`group_by_stat`** (fn): Group item indices by the integer part of a named stat.  Returns a map from `stat_value as i64` to a list of 0-based...
- **`group_by_category`** (fn): Group item indices by category. Consult the module-level documentation for the broader usage context and preconditions....
- **`group_by_tag_prefix`** (fn): Group item indices by a tag prefix (the part before the first `:`).  Tags matching `prefix:value` are grouped under...
- **`find_n_of_stat`** (fn): Find all maximal groups where items share the exact same integer stat value, and the group has exactly `n` members. ...
- **`find_at_least_n_of_stat`** (fn): Find all groups where at least `n` items share the same integer stat value.
- **`find_sequences`** (fn): Find all runs (sequences of consecutive integer stat values) of length ≥ `min_run`.  Sorts items by stat value and...
- **`find_tag_groups`** (fn): Find groups of items that all share the same tag-prefix value and contain at least `min_size` members.  Analogous to...
- **`sorted_indices_by_stat`** (fn): Return a sorted list of 0-based indices; does not modify the slice.  `ascending = true` → lowest stat first.
- **`sorted_indices_by_category`** (fn): Return sorted indices grouped alphabetically by category.

### `cardgame::history`

Change history — append-only log of stack mutations.

- **`HistoryAction`** (enum): The category of change that was recorded.
- **`HistoryEntry`** (struct): A single entry in the history log. Consult the module-level documentation for the broader usage context and...
- **`StackHistory`** (struct): Append-only change log with an optional rolling size limit.

### `cardgame::manager`

Stack manager — organises multiple named `Stack` instances as a unit.

- **`StackManager`** (struct): Manages a collection of named `Stack` instances.  All stack names and their semantics are user-defined.

### `cardgame::pool`

Weighted item-type pool for random selection.

- **`PoolEntry`** (struct): A single entry in an item pool. Consult the module-level documentation for the broader usage context and preconditions.
- **`CardPool`** (struct): A pool of card types for weighted random draws.

### `cardgame::slot`

Slot — a bounded named position that holds a small set of items.

- **`Slot`** (struct): A bounded named position holding zero or more items.  Semantics (what "this slot" means) are entirely user-defined.

### `cardgame::stack`

Ordered card collection — a stack, pile, hand, zone, or any linear sequence of cards.

- **`Stack`** (struct): An ordered collection of cards. Consult the module-level documentation for the broader usage context and preconditions....

## Key Types

### Structs

#### `cardgame::builder::BuildEntry`

One "slot" in a stack template: an card type plus a count and optional overrides.

#### `cardgame::card::Card`

A single card instance. Consult the module-level documentation for the broader usage context and preconditions.  All...

#### `cardgame::group::CardGroup`

A labelled subset of an item slice, referenced by index.  Indices refer to positions in the original `&[Card]` slice...

#### `cardgame::pool::CardPool`

A pool of card types for weighted random draws.

#### `cardgame::card::CardTypeDef`

Template that describes a class of items (the "blueprint").  Stats, tags, and metadata defined here are seeded into...

#### `cardgame::builder::DeckBuilder`

Builds a `Stack` from `BuildEntry` templates and validates construction constraints.  Constraints (min/max size, max...

#### `cardgame::history::HistoryEntry`

A single entry in the history log. Consult the module-level documentation for the broader usage context and...

#### `cardgame::pool::PoolEntry`

A single entry in an item pool. Consult the module-level documentation for the broader usage context and preconditions.

#### `cardgame::slot::Slot`

A bounded named position holding zero or more items.  Semantics (what "this slot" means) are entirely user-defined.

#### `cardgame::stack::Stack`

An ordered collection of cards. Consult the module-level documentation for the broader usage context and preconditions....

#### `cardgame::history::StackHistory`

Append-only change log with an optional rolling size limit.

#### `cardgame::manager::StackManager`

Manages a collection of named `Stack` instances.  All stack names and their semantics are user-defined.

### Enums

#### `cardgame::history::HistoryAction`

The category of change that was recorded.

## Public Functions

- **`clear_card_types()`** `card::` — Remove all entries from the registry. After this call the container is in the same state as immediately after...
- **`define_card_type()`** `card::` — Register (or overwrite) an card type in the thread-local type registry.
- **`find_at_least_n_of_stat()`** `group::` — Find all groups where at least `n` items share the same integer stat value.
- **`find_n_of_stat()`** `group::` — Find all maximal groups where items share the exact same integer stat value, and the group has exactly `n` members. ...
- **`find_sequences()`** `group::` — Find all runs (sequences of consecutive integer stat values) of length ≥ `min_run`.  Sorts items by stat value and...
- **`find_tag_groups()`** `group::` — Find groups of items that all share the same tag-prefix value and contain at least `min_size` members.  Analogous to...
- **`get_card_type()`** `card::` — Look up an card type definition by name. Returns `None` if not found.
- **`get_card_type_names()`** `card::` — Return all registered type names. This accessor incurs no allocation; call it freely in hot paths.
- **`group_by_category()`** `group::` — Group item indices by category. Consult the module-level documentation for the broader usage context and preconditions....
- **`group_by_stat()`** `group::` — Group item indices by the integer part of a named stat.  Returns a map from `stat_value as i64` to a list of 0-based...
- **`group_by_tag_prefix()`** `group::` — Group item indices by a tag prefix (the part before the first `:`).  Tags matching `prefix:value` are grouped under...
- **`sorted_indices_by_category()`** `group::` — Return sorted indices grouped alphabetically by category.
- **`sorted_indices_by_stat()`** `group::` — Return a sorted list of 0-based indices; does not modify the slice.  `ascending = true` → lowest stat first.

## Lua API

Exposed under `luna.cardgame.*` by `src/lua_api/cardgame_api/`.

## cardgame — Card Game Backend Engine

> **Lua namespace:** `luna.cardgame`
> **C++ module:** `src/modules/cardgame/`
> **Purpose:** Generic card game engine providing cards, decks, hands, discard piles, card types, custom stats, custom costs, custom scripted effects, and stack operations. Designed to support TCG/CCG mechanics (Magic: The Gathering, Hearthstone) and simpler card games (Arcomage, Solitaire). No rendering — stores optional asset references for front-end use.

## Reimplementation Notes

- The module is **purely data and logic** — no rendering, no textures, no draw calls. Asset references (card art, sounds) are stored as Lua registry refs and forwarded to the rendering layer by the game
- All indices in Lua are **1-based**; C++ binding adjusts internally
- Card identity uses string-based `cardType` — no integer IDs. Two cards with the same `cardType` are distinct instances with separate state
- **Custom stats** are stored as a flat string→number map on each Card (e.g. `"attack"=3`, `"defense"=2`, `"manaCost"=4`). The module does not interpret stat names — that is game-defined
- **Custom costs** are validated via a Lua callback: `costCheckFn(card, player) → boolean`. The module calls this before allowing a card to be played
- **Custom scripts** (effects) are Lua functions stored via registry ref. Events like `onPlay`, `onDiscard`, `onDraw`, `onDeath`, `onTurnStart`, `onTurnEnd` are dispatched automatically
- **Card types** are defined via `defineCardType()` — a template that new cards are instantiated from. Types carry default stats, tags, cost functions, and effect scripts
- **Deck** supports shuffle (Fisher-Yates), draw, peek, insert-at-position, search, and filter operations
- **Zone** is the generic container — Hand, Battlefield, Graveyard, Exile are all Zones with different rules (capacity, visibility, ordering)
- **StackManager** implements a Last-In-First-Out resolution stack (like MTG's stack) with priority passing, response windows, and automatic resolution
- Serialization: `snapshot()`/`restore()` on all major types for save/load integration with `luna.savegame`
- **Tile support**: Cards can optionally reference tile coordinates for board-based card games (Arcomage tower positions, creature lanes)

## Dependencies

- None (self-contained module; optional integration with `luna.stats` for stat-based effects, `luna.inventory` for card collection management)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newCard` | `cardType: string` | `Card` | Create a card instance from a defined card type |
| `newDeck` | `name?: string` | `Deck` | Create an empty deck |
| `newZone` | `name: string, capacity?: int` | `Zone` | Create a zone (hand, battlefield, graveyard, etc.). Capacity -1 = unlimited |
| `newStackManager` | — | `StackManager` | Create a LIFO resolution stack for effect/spell resolution |
| `newDeckBuilder` | — | `DeckBuilder` | Create a deck builder with validation rules |
| `newCardPool` | `name?: string` | `CardPool` | Create a card pool (collection of available card types for drafting/gacha) |
| `defineCardType` | `name: string, def: table` | — | Define a card type template (see CardType Definition below) |
| `getCardType` | `name: string` | `table \| nil` | Retrieve a card type definition |
| `getCardTypeNames` | — | `table<string>` | List all defined card type names |
| `clearCardTypes` | — | — | Remove all card type definitions |

### CardType Definition Table

```lua
{
    name        = "Fireball",           -- display name
    category    = "spell",              -- card category (free-form string)
    subtype     = "damage",             -- card subtype (free-form string)
    rarity      = "common",             -- rarity tier (free-form string)
    tags        = {"instant", "fire"},   -- array of tag strings
    stats       = {                     -- default stat values
        manaCost = 3,
        damage   = 5,
    },
    costCheck   = function(card, context) -- cost validation callback
        return context.mana >= card:getStat("manaCost")
    end,
    costPay     = function(card, context) -- cost payment callback
        context.mana = context.mana - card:getStat("manaCost")
    end,
    scripts     = {                     -- event callbacks
        onPlay    = function(card, context) ... end,
        onDiscard = function(card, context) ... end,
        onDraw    = function(card, context) ... end,
        onDeath   = function(card, context) ... end,
        onTurnStart = function(card, context) ... end,
        onTurnEnd   = function(card, context) ... end,
        onDamaged   = function(card, source, amount) ... end,
        onHealed    = function(card, source, amount) ... end,
    },
    maxPerDeck  = 4,                    -- max copies in a deck (for DeckBuilder)
    tileSize    = {w=1, h=1},           -- board tile footprint (for board-based games)
}
```

---

## Type: Card

An individual card instance with stats, tags, effects, and state.

### Properties

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getCardType` | — | `string` | Get the card type identifier |
| `getName` | — | `string` | Get the display name |
| `getCategory` | — | `string` | Get the card category |
| `getSubtype` | — | `string` | Get the card subtype |
| `getRarity` | — | `string` | Get the rarity tier |

### Stats

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setStat` | `name: string, value: number` | — | Set a custom stat value |
| `getStat` | `name: string` | `number` | Get a custom stat value (0 if not defined) |
| `hasStat` | `name: string` | `boolean` | Check if a stat is defined |
| `getStats` | — | `table` | Get all stats as `{name=value, ...}` |
| `modifyStat` | `name: string, delta: number` | `number` | Add delta to stat, return new value |
| `resetStats` | — | — | Reset all stats to card type defaults |

### Tags

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addTag` | `tag: string` | — | Add a tag |
| `removeTag` | `tag: string` | — | Remove a tag |
| `hasTag` | `tag: string` | `boolean` | Check for a tag |
| `getTags` | — | `table<string>` | Get all tags |

### State

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setFaceUp` | `faceUp: boolean` | — | Set face-up/face-down state |
| `isFaceUp` | — | `boolean` | Check if face-up |
| `setTapped` | `tapped: boolean` | — | Set tapped/exhausted state |
| `isTapped` | — | `boolean` | Check if tapped |
| `setOwner` | `ownerId: string` | — | Set the owning player ID |
| `getOwner` | — | `string` | Get the owning player ID |
| `setController` | `controllerId: string` | — | Set the controlling player ID (may differ from owner) |
| `getController` | — | `string` | Get the controlling player ID |
| `getZone` | — | `string \| nil` | Get the name of the zone this card is in |

### Counters

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCounter` | `name: string, value: int` | — | Set a named counter (e.g. `"+1/+1"`, `"loyalty"`) |
| `getCounter` | `name: string` | `int` | Get counter value (0 if not set) |
| `modifyCounter` | `name: string, delta: int` | `int` | Modify counter by delta, return new value |
| `getCounters` | — | `table` | Get all counters as `{name=value, ...}` |
| `clearCounters` | — | — | Remove all counters |

### Scripts & Effects

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setScript` | `event: string, fn: function` | — | Override an event script for this instance |
| `getScript` | `event: string` | `function \| nil` | Get the script for an event |
| `fireScript` | `event: string, ...` | `any` | Execute the script for an event, forwarding args |
| `canPlay` | `context: any` | `boolean` | Check if cost requirements are met |
| `payCost` | `context: any` | — | Execute the cost payment callback |

### Cost Mechanics

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCostCheck` | `fn: function` | — | Set custom cost validation: `fn(card, context) → boolean` |
| `setCostPay` | `fn: function` | — | Set custom cost payment: `fn(card, context)` |

### Assets

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setAsset` | `key: string, value: any` | — | Store an asset reference (texture, sound, etc.) via Lua registry |
| `getAsset` | `key: string` | `any \| nil` | Retrieve a stored asset reference |

### Tile Position (for board-based games)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTilePosition` | `x: int, y: int` | — | Set board tile position |
| `getTilePosition` | — | `x: int, y: int` | Get board tile position |
| `setTileSize` | `w: int, h: int` | — | Set tile footprint |
| `getTileSize` | — | `w: int, h: int` | Get tile footprint |

### Serialization

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `snapshot` | — | `table` | Serialize card state |
| `restore` | `data: table` | — | Restore card state from snapshot |
| `clone` | — | `Card` | Deep-copy card instance (scripts are shared, stats/counters are copied) |

---

## Type: Deck

An ordered collection of cards with shuffle, draw, and search operations.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addCard` | `card: Card` | — | Add a card to the top of the deck |
| `addCardBottom` | `card: Card` | — | Add a card to the bottom of the deck |
| `insertCard` | `card: Card, position: int` | — | Insert a card at a 1-based position |
| `drawCard` | — | `Card \| nil` | Remove and return the top card |
| `drawCards` | `count: int` | `table<Card>` | Draw multiple cards from the top |
| `drawCardBottom` | — | `Card \| nil` | Remove and return the bottom card |
| `peekTop` | `count?: int` | `Card \| table<Card>` | Look at top card(s) without removing |
| `peekBottom` | `count?: int` | `Card \| table<Card>` | Look at bottom card(s) without removing |
| `shuffle` | `seed?: int` | — | Fisher-Yates shuffle. Optional seed for deterministic shuffle |
| `getCardCount` | — | `int` | Number of cards in the deck |
| `isEmpty` | — | `boolean` | Check if deck is empty |
| `clear` | — | — | Remove all cards |
| `getCards` | — | `table<Card>` | Get all cards (top to bottom order) |
| `removeCard` | `card: Card` | `boolean` | Remove a specific card instance |
| `findByType` | `cardType: string` | `table<Card>` | Find all cards of a given type |
| `findByTag` | `tag: string` | `table<Card>` | Find all cards with a given tag |
| `findByCategory` | `category: string` | `table<Card>` | Find all cards of a given category |
| `filter` | `fn: function` | `table<Card>` | Filter cards: `fn(card) → boolean` |
| `sort` | `fn: function` | — | Sort cards by comparator: `fn(a, b) → boolean` |
| `contains` | `card: Card` | `boolean` | Check if a specific card instance is in the deck |
| `getName` | — | `string` | Get deck name |
| `setName` | `name: string` | — | Set deck name |
| `snapshot` | — | `table` | Serialize deck state |
| `restore` | `data: table` | — | Restore deck from snapshot |

---

## Type: Zone

A generic card container representing hands, battlefields, graveyards, exile, etc.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Get zone name |
| `setName` | `name: string` | — | Set zone name |
| `addCard` | `card: Card` | `boolean` | Add a card (respects capacity). Returns false if full |
| `removeCard` | `card: Card` | `boolean` | Remove a specific card |
| `getCard` | `index: int` | `Card \| nil` | Get card at 1-based index |
| `getCardCount` | — | `int` | Number of cards in zone |
| `getCards` | — | `table<Card>` | Get all cards |
| `getCapacity` | — | `int` | Get zone capacity (-1 = unlimited) |
| `setCapacity` | `capacity: int` | — | Set zone capacity |
| `isFull` | — | `boolean` | Check if at capacity |
| `isEmpty` | — | `boolean` | Check if empty |
| `clear` | — | — | Remove all cards |
| `findByType` | `cardType: string` | `table<Card>` | Find cards by type |
| `findByTag` | `tag: string` | `table<Card>` | Find cards by tag |
| `filter` | `fn: function` | `table<Card>` | Filter cards |
| `sort` | `fn: function` | — | Sort cards |
| `setOrdered` | `ordered: boolean` | — | If false, iteration order is undefined (for hidden zones) |
| `isOrdered` | — | `boolean` | Check if zone preserves insertion order |
| `setPublic` | `public: boolean` | — | If true, all cards are visible to all players |
| `isPublic` | — | `boolean` | Check zone visibility |
| `moveCard` | `card: Card, targetZone: Zone` | `boolean` | Move a card to another zone (removes from this, adds to target) |
| `moveAllCards` | `targetZone: Zone` | `int` | Move all cards to another zone. Returns count moved |
| `snapshot` | — | `table` | Serialize zone state |
| `restore` | `data: table` | — | Restore zone from snapshot |

---

## Type: StackManager

A LIFO resolution stack for effect/spell resolution (inspired by MTG's stack).

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `push` | `entry: table` | `int` | Push an entry onto the stack. Returns 1-based position. Entry: `{card=Card, effect=string, context=any, controller=string}` |
| `pop` | — | `table \| nil` | Remove and return the top entry |
| `peek` | — | `table \| nil` | View the top entry without removing |
| `resolve` | — | `table \| nil` | Pop the top entry and fire its card's effect script. Returns the resolved entry |
| `resolveAll` | — | `int` | Resolve all entries in LIFO order. Returns count resolved |
| `getEntries` | — | `table` | Get all entries (bottom to top) |
| `getCount` | — | `int` | Number of entries on the stack |
| `isEmpty` | — | `boolean` | Check if stack is empty |
| `clear` | — | — | Clear all entries without resolving |
| `removeEntry` | `index: int` | `boolean` | Remove an entry by 1-based index (for counter-spells) |
| `insertEntry` | `entry: table, index: int` | — | Insert an entry at a specific position |
| `findByCard` | `card: Card` | `table<table>` | Find all entries referencing a card |

---

## Type: DeckBuilder

Validates deck construction rules (card limits, required counts, banned cards, format constraints).

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setMinCards` | `min: int` | — | Set minimum deck size |
| `getMinCards` | — | `int` | Get minimum deck size |
| `setMaxCards` | `max: int` | — | Set maximum deck size |
| `getMaxCards` | — | `int` | Get maximum deck size |
| `setMaxCopies` | `max: int` | — | Set default max copies per card type |
| `getMaxCopies` | — | `int` | Get default max copies |
| `setMaxCopiesForType` | `cardType: string, max: int` | — | Override max copies for a specific card type |
| `addRequiredTag` | `tag: string, min: int` | — | Require at least `min` cards with this tag |
| `addBannedType` | `cardType: string` | — | Ban a card type from the deck |
| `removeBannedType` | `cardType: string` | — | Unban a card type |
| `getBannedTypes` | — | `table<string>` | Get all banned card types |
| `addRequiredCategory` | `category: string, min: int, max?: int` | — | Require category count within [min, max] |
| `validate` | `deck: Deck` | `boolean, table<string>` | Validate a deck. Returns `(true, {})` or `(false, {error messages})` |
| `addCustomRule` | `name: string, fn: function` | — | Add a custom validation rule: `fn(deck) → boolean, string?` |
| `removeCustomRule` | `name: string` | — | Remove a custom rule |

---

## Type: CardPool

A collection of available card types for drafting, pack opening, or gacha mechanics.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addCardType` | `cardType: string, weight?: number` | — | Add a card type with optional weight for random selection (default 1.0) |
| `removeCardType` | `cardType: string` | — | Remove a card type |
| `getCardTypes` | — | `table<string>` | Get all card types in the pool |
| `getCardTypeCount` | — | `int` | Number of card types |
| `setWeight` | `cardType: string, weight: number` | — | Set selection weight for a card type |
| `getWeight` | `cardType: string` | `number` | Get selection weight |
| `setRarityWeight` | `rarity: string, weight: number` | — | Set base weight for all cards of a rarity |
| `drawRandom` | `count: int, seed?: int` | `table<Card>` | Create random card instances from the pool (weighted) |
| `drawByRarity` | `rarityDistribution: table` | `table<Card>` | Draw cards by rarity: `{common=5, rare=2, epic=1}` |
| `getName` | — | `string` | Get pool name |
| `setName` | `name: string` | — | Set pool name |

---

## Usage Example

```lua
-- Define card types
luna.cardgame.defineCardType("fireball", {
    name     = "Fireball",
    category = "spell",
    subtype  = "damage",
    rarity   = "common",
    tags     = {"instant", "fire"},
    stats    = { manaCost = 3, damage = 5 },
    costCheck = function(card, ctx)
        return ctx.mana >= card:getStat("manaCost")
    end,
    costPay = function(card, ctx)
        ctx.mana = ctx.mana - card:getStat("manaCost")
    end,
    scripts = {
        onPlay = function(card, ctx)
            ctx.target:modifyStat("hp", -card:getStat("damage"))
        end,
    },
    maxPerDeck = 4,
})

luna.cardgame.defineCardType("goblin", {
    name     = "Goblin Warrior",
    category = "creature",
    subtype  = "goblin",
    rarity   = "common",
    tags     = {"minion"},
    stats    = { manaCost = 2, attack = 2, defense = 1, hp = 3 },
    scripts = {
        onPlay = function(card, ctx)
            -- Summon to battlefield
        end,
        onDeath = function(card, ctx)
            -- Death rattle effect
        end,
    },
    maxPerDeck = 4,
})

-- Create game zones
local deck     = luna.cardgame.newDeck("Player1 Deck")
local hand     = luna.cardgame.newZone("hand", 7)
local field    = luna.cardgame.newZone("battlefield", 5)
local graveyard = luna.cardgame.newZone("graveyard")
local stack    = luna.cardgame.newStackManager()

-- Build a deck
for i = 1, 20 do
    local card = luna.cardgame.newCard(i <= 10 and "fireball" or "goblin")
    card:setOwner("player1")
    deck:addCard(card)
end
deck:shuffle()

-- Validate with deck builder
local builder = luna.cardgame.newDeckBuilder()
builder:setMinCards(20)
builder:setMaxCards(40)
builder:setMaxCopies(4)
local valid, errors = builder:validate(deck)

-- Draw a hand
local drawn = deck:drawCards(5)
for _, card in ipairs(drawn) do
    hand:addCard(card)
end

-- Play a card via the stack
local card = hand:getCard(1)
local ctx = { mana = 10, target = nil }
if card:canPlay(ctx) then
    card:payCost(ctx)
    hand:removeCard(card)
    stack:push({ card = card, effect = "onPlay", context = ctx, controller = "player1" })
    -- Opponent may respond here
    stack:resolveAll()
    field:addCard(card)
end

-- Arcomage-style: cards with tile positions
local towerCard = luna.cardgame.newCard("tower_upgrade")
towerCard:setTilePosition(1, 1)  -- lane 1, slot 1
towerCard:setStat("towerBonus", 5)
field:addCard(towerCard)

-- Card pool for drafting
local pool = luna.cardgame.newCardPool("standard_set")
pool:addCardType("fireball", 3.0)   -- common, higher weight
pool:addCardType("goblin", 3.0)
local pack = pool:drawRandom(5, 42)  -- 5 random cards, seed 42
```

## Reimplementation Notes

- The module is **purely data and logic** — no rendering, no textures, no draw calls. Asset references (card art, sounds) are stored as Lua registry refs and forwarded to the rendering layer by the game
- All indices in Lua are **1-based**; C++ binding adjusts internally
- Card identity uses string-based `cardType` — no integer IDs. Two cards with the same `cardType` are distinct instances with separate state
- **Custom stats** are stored as a flat string→number map on each Card (e.g. `"attack"=3`, `"defense"=2`, `"manaCost"=4`). The module does not interpret stat names — that is game-defined
- **Custom costs** are validated via a Lua callback: `costCheckFn(card, player) → boolean`. The module calls this before allowing a card to be played
- **Custom scripts** (effects) are Lua functions stored via registry ref. Events like `onPlay`, `onDiscard`, `onDraw`, `onDeath`, `onTurnStart`, `onTurnEnd` are dispatched automatically
- **Card types** are defined via `defineCardType()` — a template that new cards are instantiated from. Types carry default stats, tags, cost functions, and effect scripts
- **Deck** supports shuffle (Fisher-Yates), draw, peek, insert-at-position, search, and filter operations
- **Zone** is the generic container — Hand, Battlefield, Graveyard, Exile are all Zones with different rules (capacity, visibility, ordering)
- **StackManager** implements a Last-In-First-Out resolution stack (like MTG's stack) with priority passing, response windows, and automatic resolution
- Serialization: `snapshot()`/`restore()` on all major types for save/load integration with `luna.savegame`
- **Tile support**: Cards can optionally reference tile coordinates for board-based card games (Arcomage tower positions, creature lanes)

## Dependencies

- None (self-contained module; optional integration with `luna.stats` for stat-based effects, `luna.inventory` for card collection management)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newCard` | `cardType: string` | `Card` | Create a card instance from a defined card type |
| `newDeck` | `name?: string` | `Deck` | Create an empty deck |
| `newZone` | `name: string, capacity?: int` | `Zone` | Create a zone (hand, battlefield, graveyard, etc.). Capacity -1 = unlimited |
| `newStackManager` | — | `StackManager` | Create a LIFO resolution stack for effect/spell resolution |
| `newDeckBuilder` | — | `DeckBuilder` | Create a deck builder with validation rules |
| `newCardPool` | `name?: string` | `CardPool` | Create a card pool (collection of available card types for drafting/gacha) |
| `defineCardType` | `name: string, def: table` | — | Define a card type template (see CardType Definition below) |
| `getCardType` | `name: string` | `table \| nil` | Retrieve a card type definition |
| `getCardTypeNames` | — | `table<string>` | List all defined card type names |
| `clearCardTypes` | — | — | Remove all card type definitions |

### CardType Definition Table

```lua
{
    name        = "Fireball",           -- display name
    category    = "spell",              -- card category (free-form string)
    subtype     = "damage",             -- card subtype (free-form string)
    rarity      = "common",             -- rarity tier (free-form string)
    tags        = {"instant", "fire"},   -- array of tag strings
    stats       = {                     -- default stat values
        manaCost = 3,
        damage   = 5,
    },
    costCheck   = function(card, context) -- cost validation callback
        return context.mana >= card:getStat("manaCost")
    end,
    costPay     = function(card, context) -- cost payment callback
        context.mana = context.mana - card:getStat("manaCost")
    end,
    scripts     = {                     -- event callbacks
        onPlay    = function(card, context) ... end,
        onDiscard = function(card, context) ... end,
        onDraw    = function(card, context) ... end,
        onDeath   = function(card, context) ... end,
        onTurnStart = function(card, context) ... end,
        onTurnEnd   = function(card, context) ... end,
        onDamaged   = function(card, source, amount) ... end,
        onHealed    = function(card, source, amount) ... end,
    },
    maxPerDeck  = 4,                    -- max copies in a deck (for DeckBuilder)
    tileSize    = {w=1, h=1},           -- board tile footprint (for board-based games)
}
```

---

## CardType Definition Table

```lua
{
    name        = "Fireball",           -- display name
    category    = "spell",              -- card category (free-form string)
    subtype     = "damage",             -- card subtype (free-form string)
    rarity      = "common",             -- rarity tier (free-form string)
    tags        = {"instant", "fire"},   -- array of tag strings
    stats       = {                     -- default stat values
        manaCost = 3,
        damage   = 5,
    },
    costCheck   = function(card, context) -- cost validation callback
        return context.mana >= card:getStat("manaCost")
    end,
    costPay     = function(card, context) -- cost payment callback
        context.mana = context.mana - card:getStat("manaCost")
    end,
    scripts     = {                     -- event callbacks
        onPlay    = function(card, context) ... end,
        onDiscard = function(card, context) ... end,
        onDraw    = function(card, context) ... end,
        onDeath   = function(card, context) ... end,
        onTurnStart = function(card, context) ... end,
        onTurnEnd   = function(card, context) ... end,
        onDamaged   = function(card, source, amount) ... end,
        onHealed    = function(card, source, amount) ... end,
    },
    maxPerDeck  = 4,                    -- max copies in a deck (for DeckBuilder)
    tileSize    = {w=1, h=1},           -- board tile footprint (for board-based games)
}
```

---

## Type: Card

An individual card instance with stats, tags, effects, and state.

### Properties

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getCardType` | — | `string` | Get the card type identifier |
| `getName` | — | `string` | Get the display name |
| `getCategory` | — | `string` | Get the card category |
| `getSubtype` | — | `string` | Get the card subtype |
| `getRarity` | — | `string` | Get the rarity tier |

### Stats

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setStat` | `name: string, value: number` | — | Set a custom stat value |
| `getStat` | `name: string` | `number` | Get a custom stat value (0 if not defined) |
| `hasStat` | `name: string` | `boolean` | Check if a stat is defined |
| `getStats` | — | `table` | Get all stats as `{name=value, ...}` |
| `modifyStat` | `name: string, delta: number` | `number` | Add delta to stat, return new value |
| `resetStats` | — | — | Reset all stats to card type defaults |

### Tags

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addTag` | `tag: string` | — | Add a tag |
| `removeTag` | `tag: string` | — | Remove a tag |
| `hasTag` | `tag: string` | `boolean` | Check for a tag |
| `getTags` | — | `table<string>` | Get all tags |

### State

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setFaceUp` | `faceUp: boolean` | — | Set face-up/face-down state |
| `isFaceUp` | — | `boolean` | Check if face-up |
| `setTapped` | `tapped: boolean` | — | Set tapped/exhausted state |
| `isTapped` | — | `boolean` | Check if tapped |
| `setOwner` | `ownerId: string` | — | Set the owning player ID |
| `getOwner` | — | `string` | Get the owning player ID |
| `setController` | `controllerId: string` | — | Set the controlling player ID (may differ from owner) |
| `getController` | — | `string` | Get the controlling player ID |
| `getZone` | — | `string \| nil` | Get the name of the zone this card is in |

### Counters

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCounter` | `name: string, value: int` | — | Set a named counter (e.g. `"+1/+1"`, `"loyalty"`) |
| `getCounter` | `name: string` | `int` | Get counter value (0 if not set) |
| `modifyCounter` | `name: string, delta: int` | `int` | Modify counter by delta, return new value |
| `getCounters` | — | `table` | Get all counters as `{name=value, ...}` |
| `clearCounters` | — | — | Remove all counters |

### Scripts & Effects

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setScript` | `event: string, fn: function` | — | Override an event script for this instance |
| `getScript` | `event: string` | `function \| nil` | Get the script for an event |
| `fireScript` | `event: string, ...` | `any` | Execute the script for an event, forwarding args |
| `canPlay` | `context: any` | `boolean` | Check if cost requirements are met |
| `payCost` | `context: any` | — | Execute the cost payment callback |

### Cost Mechanics

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCostCheck` | `fn: function` | — | Set custom cost validation: `fn(card, context) → boolean` |
| `setCostPay` | `fn: function` | — | Set custom cost payment: `fn(card, context)` |

### Assets

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setAsset` | `key: string, value: any` | — | Store an asset reference (texture, sound, etc.) via Lua registry |
| `getAsset` | `key: string` | `any \| nil` | Retrieve a stored asset reference |

### Tile Position (for board-based games)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTilePosition` | `x: int, y: int` | — | Set board tile position |
| `getTilePosition` | — | `x: int, y: int` | Get board tile position |
| `setTileSize` | `w: int, h: int` | — | Set tile footprint |
| `getTileSize` | — | `w: int, h: int` | Get tile footprint |

### Serialization

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `snapshot` | — | `table` | Serialize card state |
| `restore` | `data: table` | — | Restore card state from snapshot |
| `clone` | — | `Card` | Deep-copy card instance (scripts are shared, stats/counters are copied) |

---

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `fn` | 13 |
| `mod` | 8 |
| `struct` | 12 |
| **Total** | **34** |

