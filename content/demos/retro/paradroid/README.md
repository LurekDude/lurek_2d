# Paradroid

A top-down shooter on a space station, inspired by Andrew Braybrook's legendary 1985
C-64 game. Battle enemy droids, then use the Transfer Override minigame to take control
of high-rated robots and boost your capabilities.

## What It Demonstrates

- `luna.gfx.rectangle()` / `luna.gfx.line()` — grid floor and droid sprites
- `luna.gfx.circle()` — transfer range indicator
- `luna.input.isKeyDown()` — 8-directional movement
- `luna.keypressed()` — shooting and initiating transfer
- Procedural room generation with wall collision
- Simple enemy AI chasing the player

## Controls

| Key | Action |
|-----|--------|
| WASD or Arrow Keys | Move |
| Space | Shoot (hold in Transfer minigame) |
| T | Initiate Transfer (when near enemy) |
| R | Restart |
| Escape | Quit |

## Transfer Minigame

Press **T** when adjacent to an enemy droid to start the override sequence.
Hold **Space** to push your bar up, depleting the enemy's bar. If your bar empties first, you take 20 energy damage. Succeed to take control of that droid class.

## Notes

Destroyed droids score points equal to their rating. Higher-level maps spawn
higher-rated droids. Clear all 5 levels to win.
