# Mining

A side-view mining game set inside a procedurally generated 50 × 80 tile world. Dig down through dirt, stone, ore, and gem deposits; craft and place ladders to descend safely; and accumulate an inventory of resources as you go deeper. Rarer deposits (ore, gems) appear with increasing probability the deeper you dig.

## What It Demonstrates

- Large destructible tile grid stored in a 2D Lua array, modified in-place on click
- Per-tile mine-time constants (`DIRT` 0.3 s → `GEM` 2.0 s) with a progress accumulator
- Procedural generation: depth-weighted probability distribution for tile types
- Camera follow that scrolls vertically to keep the player centred in the viewport
- Ladder placement and ladder-climbing movement (no gravity while on ladder)
- Inventory HUD that tracks dirt, stone, ore, and gem counts

## How to Run

```powershell
cargo run -- content/demos/mining
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `W` `A` `S` `D` | Move (with gravity when airborne) |
| Click adjacent tile | Begin mining (hold to complete) |
| `L` | Place ladder on empty cell below player |

## Notes

- Gems are extremely rare near the surface; mine down past row 40 for reliable gem spawns.
- Stone tiles take 0.8 seconds each — bring patience or plan a ladder route down before mining horizontally.
- The world is 80 rows tall; the surface sky occupies the top 8 rows.
