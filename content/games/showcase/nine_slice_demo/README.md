# Nine Slice Demo

**Category:** showcase

Interactive demonstration of the 9-slice (9-patch) technique for scalable UI panels.
Resize panels with arrow keys, switch between five visual styles, and compare
9-slice rendering against naive stretching.

## Features

- **9-slice panel rendering** — corners stay fixed (16×16), edges stretch in one axis, center fills both
- **5 panel styles** — Simple Border, Rounded Light, Thick Frame, Double Border, Decorative
- **Interactive resize** — arrow keys adjust panel width/height with smooth tween animation
- **Grid overlay** — press G to visualize the 9 slice zones (corners, edges, center)
- **Comparison view** — press C to see naive stretch vs 9-slice side by side
- **Scale demo row** — bottom of screen shows the same panel at 5 different sizes
- **Auto-wrapping text** — content inside the panel word-wraps to fit the current width
- **Style switch particles** — sparkle effect when changing panel styles

## What It Demonstrates

- `lurek.render.drawRect()` — all panel drawing uses render primitives
- `lurek.render.drawText()` — word-wrapped content inside resizable panels
- `lurek.render.setColor()` — per-style color theming for borders, fills, corners
- `lurek.render.setBackgroundColor()` — dark purple background
- `lurek.input.bind()` / `lurek.input.on()` — action-mapped controls for resize, style, grid, compare
- `lurek.window.setTitle()` — dynamic title with style name, panel size, and FPS
- `lurek.timer.getFPS()` — real-time frame rate display
- `lurek.event.quit()` — clean exit on Escape

## Controls

| Key        | Action                               |
| ---------- | ------------------------------------ |
| Left/Right | Decrease/increase panel width        |
| Up/Down    | Decrease/increase panel height       |
| 1–5        | Switch panel style                   |
| G          | Toggle grid overlay                  |
| C          | Toggle stretch vs 9-slice comparison |
| Escape     | Quit                                 |

## Run

```bash
cargo run -- content/games/showcase/nine_slice_demo
```

## Notes

- All panels are drawn entirely with `drawRect` primitives — no texture atlas or image slicing is used
- The 9-slice technique is essential for UI panels that must scale without distorting corners
- Double Border style (4) draws an additional inner border line for a classic RPG dialog look
