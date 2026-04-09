# Tennis Classic

A top-down tennis game with serve mechanics, topspin, and full tennis scoring.
First to 6 games wins the set.

## What It Demonstrates

- `lurek.gfx.rectangle()` / `lurek.gfx.circle()` — court, players, ball
- `lurek.input.isKeyDown()` — smooth player movement in four directions
- `lurek.keypressed()` — serving
- Tennis scoring (0/15/30/40/Deuce/Adv)
- CPU AI that tracks the ball and returns shots

## Controls

| Key | Action |
|-----|--------|
| A / D or Left / Right | Move horizontally |
| W / S or Up / Down | Move vertically (in your half) |
| Space | Topspin boost when hitting / Serve |
| R | Restart |
| Escape | Quit |

## Notes

Move close to the ball to return it. Hold **Space** when hitting for topspin — the
ball travels faster and angles more sharply. Rally count speeds the ball up over time.
Scores are shown on the left: CPU on top, you below.
