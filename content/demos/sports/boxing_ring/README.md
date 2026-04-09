# Boxing Ring

Classic two-fighter boxing with jabs, hooks, and blocks over 3 rounds. Outpoint
or knock out the CPU opponent to take the title.

## What It Demonstrates

- `luna.keypressed()` — punch actions with cooldown
- `luna.input.isKeyDown()` — hold to block
- CPU AI with attack/block/approach decisions
- Hit detection with range checks
- Per-round timer and round-win scoring

## Controls

| Key | Action |
|-----|--------|
| A / D or Left / Right | Move left / right |
| Space | Jab (quick, low damage) |
| Z | Hook (slow, high damage) |
| X (hold) | Block (reduces damage by 80%) |
| R | Restart |
| Escape | Quit |

## Notes

Three rounds of 90 seconds each. The fighter with higher HP when the timer runs
out wins the round. A TKO (reaching 0 HP) gives an immediate round win.
Win 2 of 3 rounds to take the match.
