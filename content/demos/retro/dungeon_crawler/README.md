# Dungeon Crawler

An Eye of Beholder / Dungeon Master style grid-stepping first-person dungeon crawler. The player snaps through the dungeon one tile at a time, turning in 90° increments, with smooth animated lerp between steps. Features textured walls, flickering torch lights, distance fog, collectible orbs, and weather atmosphere.

## What It Demonstrates

- `luna.raycaster.new()` / `rc:setCells()` — grid-based dungeon world
- `rc:castRaysFlat()` — full-viewport column casting at 90° FOV
- `luna.raycaster.projectColumn()` — wall segment projection
- `luna.raycaster.distanceShade()` — distance fog
- `rc:projectSprite()` — billboard torches and collectible orbs with depth occlusion
- `luna.gfx.newCanvas()` / `luna.gfx.setCanvas()` — 3D view in left panel, HUD in right panel
- `luna.gfx.rectangle()` — all rendering: walls, sprites, minimap tiles, weather drips

## How to Run

```bash
cargo run -- demos/retro/dungeon_crawler
```

## Controls

| Key | Action |
|-----|--------|
| W | Step forward |
| S | Step backward |
| Q | Turn left 90° |
| E | Turn right 90° |
| F1 | Normal (steady torches) |
| F2 | Wind (flickering torches) |
| F3 | Rain (rain drips + flicker) |
| Escape | Quit |

## Notes

- Grid step movement with smooth lerp (LERP_SPEED = 8×): moves feel responsive but not instant
- Consecutive keypresses while animating are queued so you don't need to wait for each step
- Torch light uses per-column inverse-distance² falloff calculated in Lua (Rust PointLight is not yet Lua-bound)
- Minimap in the right panel shows visited walls and player position in real-time
- Angle accumulates without wrap so turn animation never snaps across the ±π boundary
