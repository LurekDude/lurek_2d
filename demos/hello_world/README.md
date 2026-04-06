# Hello World

The minimum viable Luna2D game. Draws coloured shapes and text, shows FPS, and demonstrates the basic `luna.load / update / draw / keypressed` callback structure.

## What It Demonstrates

- `luna.graphics.rectangle()` — filled rectangle
- `luna.graphics.circle()` — filled circle
- `luna.graphics.line()` — line primitive
- `luna.graphics.print()` — text rendering with scale
- `luna.graphics.setColor()` / `setBackgroundColor()`
- `luna.timer.getFPS()` — frame rate query
- `luna.keypressed` callback — reacting to input

## How to Run

```powershell
cargo run -- examples/hello_world
```

## Controls

| Key | Action |
|-----|--------|
| Space | Randomise background colour |

## Notes

- Uses `conf.lua` to set a fixed 800×600 window
- Good starting point for new Luna2D projects
