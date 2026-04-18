# Star Voyage

Space exploration RPG inspired by Star Control 2 (PC 1994). Navigate a vast starfield, approach alien worlds to dock, and engage in branching dialog with procedurally placed civilisations.

## What It Demonstrates

- `library.dialog` — typewriter dialog sequencer with branching choices and call nodes
- `lurek.math.newRandomGenerator()` — seeded star field placement
- `lurek.math.lerp()` — smooth camera tracking
- `lurek.gfx.polygon()` — triangle ship rendering
- `lurek.gfx.circle()` — planets with atmosphere glow
- `lurek.gfx.print()` / `lurek.gfx.rectangle()` — dialog box overlay and HUD
- `lurek.input.isDown()` — thrust and rotation
- `lurek.signal.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/rpg/star_voyage
```

## Controls

| Key | Action |
|-----|--------|
| W / Up | Thrust forward |
| A / Left | Rotate left |
| D / Right | Rotate right |
| Space | Dock at nearby planet / advance dialog |
| 1 / 2 / 3 | Select dialog choice |
| Escape | Quit |

## Notes

- The starfield has three parallax layers — distant stars scroll slower than close ones.
- The world wraps at the edges (1400×1000 virtual space).
- Visited planets are marked with a green ring.
- Dialog uses `library.dialog` with `call` nodes for branching NPC responses.
