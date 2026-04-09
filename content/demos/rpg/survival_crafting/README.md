# Survival Crafting

A top-down survival game on a procedurally generated 25 × 18 tile world. Mine trees and stones, gather food from berry bushes, craft tools and walls, and survive the night when enemies spawn. A day/night cycle governs enemy appearance and visibility.

## What It Demonstrates

- 2D tile grid with seven tile types (grass, stone, tree, water, berry, wall, empty) rendered with colour fills
- Click-to-mine interaction: only adjacent tiles can be mined; mining progress is per-tile
- Day/night cycle: `day_timer` accumulates to `DAY_LENGTH = 60` seconds to flip the `is_day` flag
- Enemy spawning triggered by `is_day == false` with BFS pathfinding toward the player
- Crafting menu (`C`) with recipe validation: recipes require specific inventory counts before enabling
- Wall placement (`P`): converts empty tiles to wall tiles that block movement
- Hunger drain mechanic: `hunger` decreases over time; collect berries or reach zero HP

## How to Run

```powershell
cargo run -- content/demos/survival_crafting
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `W` `A` `S` `D` | Move |
| Left Click adjacent tile | Mine tile (hold to complete) |
| `C` | Open/close crafting menu |
| `P` | Place wall on empty cell under cursor |
| `Escape` | Quit |

## Notes

- Craft a **pickaxe** (3 wood + 2 stone) to mine stone and ores faster.
- Build **walls** (2 wood each) around your base to slow down night enemies.
- You cannot mine water tiles — plan your base location around water sources.
