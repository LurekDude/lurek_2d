# Cannon Fodder

Top-down military squad action inspired by Cannon Fodder (Amiga). Lead four soldiers across a tile-based jungle map, click to move the squad, while they auto-fire at any enemy in range.

## What It Demonstrates

- `lurek.render.circle()` / `lurek.render.rectangle()` — soldiers, enemies, bullets, explosions
- `lurek.render.print()` — HUD, squad count, score, alert indicator
- `lurek.input.mousepressed()` — click-to-move squad orders
- `lurek.math.newSpatialHash()` — broad-phase proximity for shoot-range queries
- `lurek.event.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/action/cannon_fodder
```

## Controls

| Key / Button | Action |
|---|---|
| Left Mouse Button | Move squad to clicked position |
| Escape | Quit |

## Notes

- Soldiers auto-aim and shoot the nearest visible enemy within range; no manual fire input needed.
- Enemies alert when a soldier enters their detection radius and begin pursuit.
- Dark-green tiles are impassable obstacles (trees/walls); bullets are also blocked by them.
- The mission is won when all enemies are eliminated; lost if all soldiers are killed.
