# Cannon Fodder

A top-down squad-based shooter inspired by Sensible Software's 1993 Amiga classic.
Command a team of soldiers through five increasingly difficult jungle missions.
Eliminate every enemy, then lead your squad to the red flag.

## What It Demonstrates

- `luna.gfx.rectangle()` / `luna.gfx.circle()` — soldier and enemy sprites
- `luna.input.isKeyDown()` — move squad target cursor
- Automatic squad pathfinding using a shared move-target
- Auto-fire AI — soldiers shoot the nearest visible enemy

## Controls

| Key | Action |
|-----|--------|
| WASD or Arrow Keys | Move squad target cursor |
| R | Restart |
| Escape | Quit |

## Notes

Your squad automatically shoots the nearest enemy within range. Capture the **red flag**
after all enemies are eliminated to complete the mission. You lose a soldier each time
one is hit enough times — only three men to start! As missions progress, more enemies
appear but the squad that survives carries over.
