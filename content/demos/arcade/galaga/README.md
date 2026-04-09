# Galaga

Take on the insect invasion fleet as enemies break formation and swoop down
in diving attack runs. Every cleared wave speeds up the assault.

## What It Demonstrates

- `luna.gfx.rectangle()` / `luna.gfx.circle()` / `luna.gfx.line()` — enemy and ship shapes
- `luna.input.isKeyDown()` — smooth ship movement
- `luna.keypressed()` — firing with bullet-count cap
- Sine-wave diving path with formation return
- Star field rendered with seeded `math.random` for consistent background

## Controls

| Key | Action |
|-----|--------|
| Left / Right Arrows (or A / D) | Move ship |
| Space or Z | Fire |
| R | Restart after game over |
| Escape | Quit |

## Notes

Enemies dive in a sine-wave arc and score double points while diving.
Enemy bullets aim approximately at the player's current position.
Formation sway frequency increases with each wave.
