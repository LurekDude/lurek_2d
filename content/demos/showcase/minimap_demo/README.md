# Minimap Demo

A scrollable terrain minimap with fog of war, object markers, pings, and a draggable viewport indicator.

## What It Demonstrates

- `luna.minimap.new()` — create a minimap canvas
- `luna.minimap.setTerrain()` — define terrain tile colours
- `luna.minimap.setFog()` — per-cell fog of war
- `luna.minimap.addObject()` / `removeObject()` — dynamic entity markers
- `luna.minimap.addPing()` — temporary highlight animation
- `luna.minimap.setViewport()` — overlay a viewport rectangle
- `luna.minimap.draw()` — render the minimap at a given position/scale
- `luna.keyboard.isDown()` for player movement driving fog reveal

## How to Run

```powershell
cargo run -- demos/minimap_demo
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move player (reveals fog) |
| P | Add a ping at player position |

## Notes

- The viewport box on the minimap tracks the player's visible area
- Uses `conf.lua` to configure window size
