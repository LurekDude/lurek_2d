# Hello World

The minimum viable Lurek2D game. Draws coloured shapes and text, shows FPS, and demonstrates the basic `lurek.load / update / draw / keypressed` callback structure.

## What It Demonstrates

- `lurek.gfx.rectangle()` — filled rectangle
- `lurek.gfx.circle()` — filled circle
- `lurek.gfx.line()` — line primitive
- `lurek.gfx.print()` — text rendering with scale
- `lurek.gfx.setColor()` / `setBackgroundColor()`
- `lurek.time.getFPS()` — frame rate query
- `lurek.keypressed` callback — reacting to input

## How to Run

```powershell
cargo run -- content/demos/hello_world
```

## Controls

| Key | Action |
|-----|--------|
| Space | Randomise background colour |

## Notes

- Uses `conf.lua` to set a fixed 800×600 window
- Good starting point for new Lurek2D projects
