# Minimap Demo

A scrollable terrain minimap with fog of war, object markers, pings, and a draggable viewport indicator.

## What It Demonstrates

- `lurek.minimap.new()` — create a minimap canvas
- `lurek.minimap.setTerrain()` — define terrain tile colours
- `lurek.minimap.setFog()` — per-cell fog of war
- `lurek.minimap.addObject()` / `removeObject()` — dynamic entity markers
- `lurek.minimap.addPing()` — temporary highlight animation
- `lurek.minimap.setViewport()` — overlay a viewport rectangle
- `lurek.minimap.draw()` — render the minimap at a given position/scale
- `lurek.keyboard.isDown()` for player movement driving fog reveal

## How to Run

```powershell
cargo run -- content/demos/minimap_demo
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move player (reveals fog) |
| P | Add a ping at player position |

## Notes

- The viewport box on the minimap tracks the player's visible area
- Uses `conf.lua` to configure window size
