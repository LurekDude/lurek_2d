# Space Invaders

Defend Earth from wave after wave of alien invaders.
Shoot them before they march all the way down to the ground.

## What It Demonstrates

- `luna.graphics.rectangle()` — invader bodies, player ship, barriers
- `luna.input.isKeyDown()` — smooth horizontal player movement
- `luna.keypressed()` — firing with cooldown
- `luna.graphics.print()` — HUD with score, lives, and wave counter
- Barrier erosion: blocks lose HP and fade as bullets pass through

## Controls

| Key | Action |
|-----|--------|
| Left / Right Arrows (or A / D) | Move ship |
| Space | Fire |
| R | Restart after game over |
| Escape | Quit |

## Notes

Invaders speed up as their numbers thin out. Barriers absorb both incoming and
outgoing fire. Top-row invaders score more points than bottom-row ones.
Each cleared wave starts a harder wave with faster movement.
