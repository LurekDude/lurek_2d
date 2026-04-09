# Snake

Guide the snake to eat food and grow longer — but don't bite your own tail
or run into a wall. Game wraps horizontally and vertically.

## What It Demonstrates

- `lurek.gfx.rectangle()` / `lurek.gfx.circle()` — drawing snake segments and food
- `lurek.keypressed()` — direction changes with 180° reversal prevention
- `lurek.gfx.print()` — live score and high-score tracking
- Timer-based grid movement with speed scaling by score

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys | Change direction |
| WASD | Alternative direction keys |
| R | Restart |
| Escape | Quit |

## Notes

Speed increases every 5 food items eaten. Three food items are on screen
simultaneously, so the player always has a nearby target. High score persists
within the session.
