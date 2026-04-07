# The Great Giana Sisters

A side-scrolling platformer inspired by the notorious 1987 C-64 game that briefly
rivalled Super Mario Bros. Collect gems, stomp enemies, and reach the exit.

## What It Demonstrates

- `luna.graphics.rectangle()` / `luna.graphics.circle()` — tiles, player, enemies, gems
- `luna.input.isKeyDown()` — smooth horizontal movement
- `luna.keypressed()` — jumping
- Tile-based collision detection with full AABB resolution
- Smooth camera scrolling with `lerp`

## Controls

| Key | Action |
|-----|--------|
| Left / Right (or A / D) | Move |
| Space or Up Arrow | Jump |
| R | Restart |
| Escape | Quit |

## Notes

Jump on top of enemies to defeat them and score 200 points. Touching an enemy
from the side or below costs a life. Reach the green EXIT tile to advance to the next level.
