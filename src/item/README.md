# `src/item/` — Generic Item Data Structures

## Purpose

Building blocks for any system that manages named, tagged, stat-carrying objects
organised into stacks/piles. Contains no gameplay assumptions (no player, turn,
trick, rule, or scoring semantics).

## Files

| File | Purpose |
|------|---------|
| `item.rs` | `Item`, `ItemTypeDef` — named game object with stats and tags |
| `stack.rs` | `Stack` — ordered collection of items (draw pile, hand, …) |
| `builder.rs` | `StackBuilder` — template-based stack construction with validation |
| `manager.rs` | `StackManager` — coordinates named stacks |
| `pool.rs` | `ItemPool` — weighted random pool of item types |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
