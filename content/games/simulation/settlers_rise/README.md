# Settlers Rise

Settlement-building simulation inspired by The Settlers 2 (Amiga 1998). Place production buildings on a procedurally generated map, watch settlers carry goods back to your HQ, and grow your resource economy.

## What It Demonstrates

- `lurek.math.newNoiseGenerator()` — procedural terrain generation
- `lurek.math.newRandomGenerator()` — seeded terrain variation
- `lurek.math.lerp()` — smooth settler movement interpolation
- `lurek.pathfind.newGrid()` — grid-based walkability map for settlers
- `lurek.gfx.rectangle()` / `lurek.gfx.circle()` / `lurek.gfx.print()` — tile map, buildings, settlers, HUD
- `lurek.input.getPosition()` — hover-tile highlight under mouse cursor
- `lurek.signal.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/simulation/settlers_rise
```

## Controls

| Key / Button | Action |
|---|---|
| Left Mouse Button | Place selected building |
| Tab | Cycle through building types |
| Escape | Quit |

## Notes

- Each building produces its resource on a timer; a settler then walks the goods back to HQ.
- Buildings cost wood and stone — check the bottom panel before placing.
- Water tiles (blue) and forest/rock tiles are impassable; only place buildings on grass or road tiles.
- Yellow hover highlight shows valid (bright) or invalid (dim) placement.
