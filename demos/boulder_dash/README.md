# Boulder Dash

Recreates the 1984 C-64 classic by First Star Software. Dig through earth,
collect diamonds, and escape through the exit before time runs out — without
being crushed by falling boulders.

## What It Demonstrates

- `luna.graphics.circle()` / `luna.graphics.rectangle()` — map cells, boulders, diamonds
- `luna.input.isKeyDown()` — tile-based movement with cooldown
- Falling physics simulation at a fixed step rate
- `luna.graphics.print()` — diamond counter, timer, and score HUD

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys / WASD | Move / Dig |
| R | Restart |
| Escape | Quit |

## Notes

Boulders fall under gravity and roll off other boulders. You can push
boulders sideways on flat ground. Collect enough diamonds to unlock the exit.
Difficulty increases each level — more boulders, more diamonds required, less time.
