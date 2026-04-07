# Donkey Kong

Climb ladders and leap over rolling barrels to rescue Pauline at the top.
Based on Nintendo's 1981 arcade classic.

## What It Demonstrates

- `luna.graphics.rectangle()` / `luna.graphics.circle()` — platforms, barrels, characters
- `luna.input.isKeyDown()` — walk and climb
- `luna.keypressed()` — jumping
- `luna.graphics.print()` — score, lives, level HUD
- Sloped platform physics with ladder entry/exit detection

## Controls

| Key | Action |
|-----|--------|
| Left / Right Arrows (or A / D) | Walk |
| Up Arrow (or W) | Climb ladder up |
| Down Arrow (or S) | Climb ladder down |
| Space (or Up) | Jump |
| R | Restart after game over |
| Escape | Quit |

## Notes

Barrels roll down sloped platforms and fall off to lower levels.
Jumping over a barrel scores a small bonus. Donkey Kong throws
barrels faster with each level increase.
