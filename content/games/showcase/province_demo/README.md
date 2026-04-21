# Province Demo

Procedural Voronoi-like province map generator with terrain, ownership, fog of war, pathfinding, and multiple visualization modes.

## What It Demonstrates

- `lurek.render.setBackgroundColor()` — dark background for map contrast
- `lurek.render.rectangle()` — grid-based province cell rendering
- `lurek.render.line()` — pathfinding route and province border drawing
- `lurek.render.print()` — stats panel, detail panel, HUD overlays
- `lurek.input.bind()` — action-mapped controls for mode cycling, fog, generation
- `lurek.input.actionPressed()` — polling bound actions each frame
- `lurek.camera.attach()` / `lurek.camera.detach()` — world-space map rendering
- `lurek.tween.to()` — smooth color transitions and panel slide animations
- `lurek.particle.emit()` — province selection highlight and path sparkle effects
- `lurek.window.setTitle()` — dynamic title with FPS

## How to Run

```bash
cargo run -- content/games/showcase/province_demo
```

## Controls

| Key / Button | Action                                            |
| ------------ | ------------------------------------------------- |
| Left Click   | Select province                                   |
| Right Click  | Pathfind from selected province                   |
| M            | Cycle display mode (terrain / owner / population) |
| F            | Toggle fog of war                                 |
| G            | Generate new map                                  |
| 1            | Assign selected province to Red                   |
| 2            | Assign selected province to Blue                  |
| 3            | Assign selected province to Green                 |
| Escape       | Quit                                              |

## Notes

- Provinces are generated via flood-fill from ~40 random seed points on a 40×30 grid
- Pathfinding uses A* with terrain-based movement costs (mountain=3, forest=2, plains=1)
- Three display modes cycle with M: terrain color, owner color, population heatmap
- Fog of war hides provinces not owned by any player faction
