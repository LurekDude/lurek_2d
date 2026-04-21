# Pac-Man

_Navigate a maze, eat dots, avoid four ghosts with distinct AI personalities — classic arcade action with power pellets and chase/scatter modes._

## Run

```powershell
cargo run -- content/games/arcade/pac_man
```

## Controls

| Input  | Action              |
| ------ | ------------------- |
| W / ↑  | Move up             |
| S / ↓  | Move down           |
| A / ←  | Move left           |
| D / →  | Move right          |
| Enter  | Start (title)       |
| R      | Restart (game over) |
| Escape | Quit                |

## Gameplay

Guide Pac-Man through a 28×31 tile maze eating dots (10 pts) and power pellets (50 pts). Four ghosts patrol the maze with distinct AI:

- **Blinky** (red) — chases Pac-Man directly, always targeting his current tile.
- **Pinky** (pink) — ambushes by targeting 4 tiles ahead of Pac-Man's facing direction.
- **Inky** (cyan) — unpredictable; targets a position calculated from Blinky's location and 2 tiles ahead of Pac-Man.
- **Clyde** (orange) — chases when far away (>8 tiles), retreats to his scatter corner when close.

Ghosts alternate between **scatter** mode (patrol assigned corners) and **chase** mode (pursue Pac-Man) on a timer. Eating a power pellet triggers **frightened** mode for ~6 seconds — ghosts turn blue and can be eaten for escalating points (200 → 400 → 800 → 1600). Tunnels on the left/right edges wrap around the maze.

Clear all dots to advance to the next level, where ghosts move faster. You start with 3 lives; losing all ends the game.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.window` — sets the window title.
- `lurek.render` — draws the maze, Pac-Man (circle with wedge mouth), ghosts (rectangle body with circle head and eye pupils), dots, and power pellets.
- `lurek.input` — action-bound directional controls.
- `lurek.tween` — power pellet pulse animation, score pop effect.
- `lurek.particle` — dot pickup sparkle, ghost eaten burst.
- `lurek.timer` — FPS counter, pellet pulse sine wave, frightened flash timing.
- `lurek.event` — clean shutdown on Escape.
- `lurek.camera` — world-space camera attachment for maze rendering.

**Lunasome (`content/library/`) modules**

_None._

## Screenshot

![Pac-Man screenshot](screen.png)
