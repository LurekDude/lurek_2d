# Centipede

Shoot the descending centipede creeping through a mushroom field.
Mushrooms block bullets and redirect the worm. Watch for bonus spiders!

## What It Demonstrates

- `lurek.gfx.circle()` / `lurek.gfx.rectangle()` — mushrooms, centipede segments, player
- `lurek.input.isKeyDown()` — 4-directional player movement in player zone
- `lurek.keypressed()` — rapid-fire shooting with cooldown
- `lurek.gfx.print()` — HUD with score, lives, and wave
- Grid-based centipede pathfinding that reverses and descends on obstacles

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys / WASD | Move shooter |
| Space | Fire |
| R | Restart after game over |
| Escape | Quit |

## Notes

Splitting the centipede with a body shot creates a new head at the split point.
Mushrooms require 4 hits to destroy. Spiders wander the player zone and score
300 points when shot. Each wave adds more starting segments.
