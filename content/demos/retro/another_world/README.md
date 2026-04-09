# Another World

A cinematic puzzle-platformer inspired by Eric Chahi's landmark 1991 Amiga masterpiece.
Navigate three alien scenes, defeat a guardian using your energy gun, and reach the exit.

## What It Demonstrates

- `lurek.gfx.rectangle()` / `lurek.gfx.circle()` — silhouette-style visuals
- `lurek.input.isKeyDown()` — movement and held shield
- `lurek.keypressed()` — jump, shoot, shield
- Scene-based room transitions
- Deflectable enemy projectiles using the energy shield

## Controls

| Key | Action |
|-----|--------|
| A / D or Left / Right | Walk |
| Space or W | Jump |
| X | Fire energy bolt |
| Z (hold) | Activate shield |
| R | Restart |
| Escape | Quit |

## Notes

Activate your **shield** while an enemy bolt hits it to deflect it back, damaging
the enemy's own shield — then fire to finish them. The blue glow shows your exit
once the enemy is defeated. Each scene has a story caption on entry.

Shield charges are shown in the top right — you have only 3.
