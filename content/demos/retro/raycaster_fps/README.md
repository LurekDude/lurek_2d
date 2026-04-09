# Raycaster FPS

A Wolfenstein-style smooth first-person shooter raycaster demonstrating Luna2D's pseudo-3D capabilities. Renders textured walls, distance fog, billboard item sprites, and dynamic weather overlays — all via the `luna.raycaster` module and a low-resolution render canvas scaled to full window.

## What It Demonstrates

- `luna.raycaster.new()` — creates the DDA grid world
- `rc:castRaysFlat()` — casts all screen columns in one call, returning 5 floats per ray
- `luna.raycaster.projectColumn()` — converts ray distance to wall height + vertical draw range
- `luna.raycaster.distanceShade()` — distance-based fog brightness
- `rc:projectSprite()` — billboard projection for item sprites with depth-buffer occlusion
- `luna.gfx.newCanvas()` / `luna.gfx.setCanvas()` — render-to-texture for low-res upscaling
- `luna.gfx.rectangle()` — procedural wall columns, sprites, and weather particles

## How to Run

```bash
cargo run -- demos/retro/raycaster_fps
```

## Controls

| Key | Action |
|-----|--------|
| W / S | Move forward / back |
| A / D | Strafe left / right |
| Q / E | Rotate left / right |
| F1 | Clear weather |
| F2 | Rain |
| F3 | Snow |
| Escape | Quit |

## Notes

- Renders at 320×180 internally then upscales 3× for a retro pixel-art look
- Side walls (north/south faces) are darkened 35% to simulate directional lighting
- Tex_u from DDA is used to create fake brick band variation without a texture file
- Items are billboard sprites with a simple Lua depth buffer for wall occlusion
- Weather particles are rendered onto the low-res canvas before upscaling so they match pixel density
