# Hello World

The minimum viable Luna2D game. Draws coloured shapes and text, shows FPS, and demonstrates the basic `luna.load / update / draw / keypressed` callback structure.

## What It Demonstrates

- `luna.gfx.rectangle()` — filled rectangle
- `luna.gfx.circle()` — filled circle
- `luna.gfx.line()` — line primitive
- `luna.gfx.print()` — text rendering with scale
- `luna.gfx.setColor()` / `setBackgroundColor()`
- `luna.time.getFPS()` — frame rate query
- `luna.keypressed` callback — reacting to input

## How to Run

```powershell
cargo run -- demos/hello_world
```

## Controls

| Key | Action |
|-----|--------|
| Space | Randomise background colour |

## Notes

- Uses `conf.lua` to set a fixed 800×600 window
- Good starting point for new Luna2D projects
