# Shadow of the Beast

An atmospheric side-scrolling action game inspired by Psygnosis's visually stunning 1989
Amiga classic. Battle through three stages of increasingly powerful beasts and their bosses
to break the ancient curse.

## What It Demonstrates

- `luna.gfx.rectangle()` / `luna.gfx.circle()` — silhouette art style
- Multi-layer parallax scrolling using different scroll speed factors
- `luna.input.isKeyDown()` — smooth player movement and scrolling
- `luna.keypressed()` — jump and attack
- Boss enemies with HP bars, stage-based difficulty scaling

## Controls

| Key | Action |
|-----|--------|
| A / D or Left / Right | Walk |
| Space or W | Jump |
| X | Attack |
| R | Restart |
| Escape | Quit |

## Notes

The world scrolls as you move right. Defeat **5 regular enemies** to trigger a stage boss
(large, 8 HP). Each of the 3 stages is harder — faster spawns, more enemies. Clear all
3 to break the curse.
