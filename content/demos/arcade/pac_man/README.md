# Pac-Man

Navigate the maze, eat all dots, and avoid the 4 ghosts.
Eat a power pellet to turn the tables and devour frightened ghosts.

## What It Demonstrates

- `lurek.gfx.circle()` — pac-man, ghosts, and dots
- `lurek.gfx.rectangle()` — maze walls and header bar
- `lurek.input.isKeyDown()` — directional movement with input buffering
- `lurek.gfx.print()` — score and status overlays

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys | Move Pac-Man |
| R | Restart after game over |
| Escape | Quit |

## Notes

Ghost AI uses simple Manhattan-distance chasing when not frightened, switching to
random wandering when a power pellet is active. Ghosts respawn at the centre when eaten.
