# Overlay Demo

Demonstrates `luna.gfx.newDrawLayer()` for z-ordered rendering. Layers can be reordered at runtime, enabling dynamic depth sorting for UI and game objects.

## What It Demonstrates

- `luna.gfx.newDrawLayer()` — create a named render layer
- Layer z-order: sorting layers and changing depth at runtime
- `layer:draw()` — submitting draw commands to a layer
- `luna.gfx.flushLayers()` — compositing all layers in z-order
- Selecting and reordering layers with keyboard
- Visual feedback showing layer priorities

## How to Run

```powershell
cargo run -- demos/overlay_demo
```

## Controls

| Key | Action |
|-----|--------|
| 1 / 2 / 3 | Select a rectangle |
| Up / Down | Change selected layer's z-order |
| R | Reset all z-orders |

## Notes

- Uses `conf.lua` for window setup
- Demonstrates a clean pattern for HUD-over-world rendering
