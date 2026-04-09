# Sprites / Movement Demo

Moves a coloured rectangle around the screen with keyboard input. Demonstrates real-time position updates, boundary clamping, and mouse-click spawning.

## What It Demonstrates

- `lurek.keyboard.isDown()` — polling multiple keys each frame
- `lurek.mouse.getPosition()` / `lurek.mouse.isDown()` — mouse input
- `lurek.gfx.rectangle()` with fill and outline modes
- Delta-time movement: `pos = pos + speed * dt`
- Boundary clamping to keep entities on screen
- `lurek.gfx.getWidth()` / `getHeight()` — window size query

## How to Run

```powershell
cargo run -- content/demos/sprites
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Arrow keys / WASD | Move rectangle |
| Left click | Spawn a temporary dot |

## Notes

- Named "sprites" but uses pure vector shapes — no image loading required
- Good reference for movement and input polling patterns
