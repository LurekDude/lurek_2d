# Frogger

Help the frog cross a busy road, then ride logs and turtles across the river
to reach the lily pads at the top.

## What It Demonstrates

- `luna.gfx.rectangle()` / `luna.gfx.circle()` — frog, vehicles, logs, lily pads
- `luna.keypressed()` — hop-based grid movement
- `luna.gfx.print()` — HUD score, lives, and level
- Multiple scrolling lane types: road (avoid obstacles) and river (ride platforms)

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys / WASD | Hop in direction |
| R | Restart after game over |
| Escape | Quit |

## Notes

The frog rides floating logs in the river — fall between them and you lose a life.
All five lily-pad home slots must be filled to advance to the next level.
An already-filled home slot counts as a fatal collision.
