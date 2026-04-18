# Minimap Demo

**Category:** showcase

A complete minimap with fog of war demonstration. Explore a large procedurally generated
100×100 tile world while a live minimap tracks your progress, reveals explored terrain,
and highlights points of interest.

## Features

- **Large world** — 100×100 tile grid (1600×1600 pixels) with 5 terrain types
- **Procedural generation** — noise-like random patterns for terrain placement
- **Fog of war** — unexplored tiles are hidden on the minimap; 8-tile reveal radius
- **Three visibility states** — unexplored (black), explored but not visible (dim), visible (full color)
- **Points of interest** — 10 discoverable locations shown as stars on the main view
- **Resizable minimap** — press +/− to zoom between 150–300px
- **Toggle minimap** — press M to show/hide the overlay
- **Discovery tracking** — walk over POIs to collect them with sparkle effects
- **Smooth camera** — tweened player movement and camera follow

## Controls

| Key     | Action              |
| ------- | ------------------- |
| W/A/S/D | Move player         |
| M       | Toggle minimap      |
| +/−     | Zoom minimap in/out |
| Escape  | Quit                |

## Run

```bash
cargo run -- content/games/showcase/minimap_demo
```
