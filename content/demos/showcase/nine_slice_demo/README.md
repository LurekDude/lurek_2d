# Nine-Slice Demo

Demonstrates `luna.gfx.newNineSlice()` for building scalable UI panels and buttons that preserve corner detail while stretching edges and the centre.

## What It Demonstrates

- `luna.gfx.newNineSlice()` — create a 9-patch descriptor
- `luna.gfx.drawNineSlice()` — render at arbitrary size
- Corner slice preservation when scaling
- Runtime resize: adjusting panel dimensions with arrow keys
- Building dialog boxes and button frames from a single slice definition
- `luna.gfx.setColor()` for tinting nine-slice instances

## How to Run

```powershell
cargo run -- demos/nine_slice_demo
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Resize the demo panel |
| Tab | Cycle between panel and button examples |

## Notes

- Slices are defined as pixel insets (left, right, top, bottom)
- Uses `conf.lua` for window configuration
- No image files required — demo uses solid-colour patches
