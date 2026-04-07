# Hex Strategy

A turn-based hex-grid strategy game where you expand a civilisation across procedurally generated terrain. Each city gathers gold, wood, and food from its surrounding hexes every turn, and you spend resources to found new cities on conquered tiles. Terrain ranges from grassland and forest to mountains and desert, each with distinct resource yields.

## What It Demonstrates

- `luna.math.simplex2d()` — two-octave noise layers that determine terrain type per hex
- `luna.mouse.getPosition()` / `luna.mousepressed()` — pixel-to-hex coordinate conversion for tile selection
- `luna.keyboard.wasPressed()` — `C` to place a city, `N` to end the turn
- `luna.graphics.polygon()` — flat-top hexagon rendering for both fill and outline passes
- `luna.graphics.setColor()` — per-terrain colour lookup and selection highlight
- `luna.graphics.print()` — resource HUD panel and hex info tooltip
- `luna.window.setTitle()` — window caption set at load time
- Cube-coordinate hex math — `hexToPixel` / `pixelToHex` with proper cube rounding for accurate selection

## How to Run

```powershell
cargo run -- demos/hex_strategy
```

## Controls

| Input | Action |
|-------|--------|
| Left Click | Select a hex tile |
| C | Place a city on the selected hex (costs resources) |
| N | End turn (gather resources from all city radii) |
| Escape | Quit |

## Notes

- The map uses flat-top axial coordinates with a radius of 5, producing 91 hexes
- `luna.math.simplex2d()` is sampled at two frequencies: one for elevation (water/mountain) and one for biome (forest/desert)
- Each city gathers resources from its own hex plus all six neighbours each turn
- Cities cost gold and wood; placing one on a water tile is blocked by terrain type
