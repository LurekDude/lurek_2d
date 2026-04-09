# Tower Sim (Stacking Tower)

A Doodle Tower-style stacking game where a block swings back and forth on a pendulum and the player drops it at the right moment. Overlap with the block below is kept; any overhang is trimmed. Land a Perfect drop (within 4 px offset) for a score bonus and a combo multiplier.

## What It Demonstrates

- Pendulum timing: block X position from `math.sin(time * speed) * amplitude`
- Width trimming: `overlap = min(prev_right, drop_right) − max(prev_left, drop_left)` discards the non-overlapping portion
- Combo system: consecutive Perfects multiply the score bonus; one missed Perfect resets it
- HSV-to-RGB colour conversion: each new block gets a hue derived from `score * 13` deg for a rainbow tower
- Sky background interpolation: five colour stop pairs that lerp based on `score` milestones
- Score milestone transitions: the sky shifts from daylight → dusk → twilight → night → space as the tower grows

## How to Run

```powershell
cargo run -- content/demos/tower_sim
```

## Controls

| Key | Action |
|-----|--------|
| `Space` | Drop the current block |
| `R` | Restart |
| `Escape` | Quit |

## Notes

- A Perfect bonus adds extra score but also narrows the next block width by less — the tower stays wide longer.
- Missing a Perfect does not end the game; only dropping a block with zero overlap ends the run.
- The pendulum speed increases as the tower grows, making high scores increasingly challenging.
