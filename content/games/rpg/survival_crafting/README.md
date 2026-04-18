# Survival Crafting

**Category:** RPG  
**Engine:** Lurek2D

## Description

A grid-based survival crafting game. Gather wood, stone, and berries from the
environment, craft tools and defensive walls, and survive the night cycle when
enemies emerge. Manage hunger, health, and resources to last as many days as
possible.

## Controls

| Key    | Action                         |
| ------ | ------------------------------ |
| WASD   | Move (grid-based)              |
| Space  | Mine adjacent resource tile    |
| C      | Open / close crafting menu     |
| P      | Place wall in facing direction |
| B      | Eat a berry to restore hunger  |
| Enter  | Start game from title screen   |
| Escape | Quit                           |

## Mechanics

- **Resource gathering** — Walk next to trees, stones, or berry bushes and press
  Space to mine. A pickaxe halves mining time.
- **Crafting** — Open the craft menu with C. Build a pickaxe (2 wood + 3 stone)
  or walls (4 wood each).
- **Day/night cycle** — Each day lasts 60 seconds. The screen darkens at night
  and enemies spawn, hunting the player. Walls block enemy movement.
- **Survival** — Hunger drains over time; at zero hunger, health drains instead.
  Eat berries to restore hunger. Survive as many days as you can.

## Running

```bash
cargo run -- content/games/rpg/survival_crafting
```
