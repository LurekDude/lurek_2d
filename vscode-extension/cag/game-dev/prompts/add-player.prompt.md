---
name: Add Player Character
description: Add a controllable player character with movement, animation, and input handling.
mode: ask
---

# Add Player Character

## Questions
1. Genre context? (platformer, top-down, etc.)
2. Movement style? (physics-based, grid-locked, free movement)
3. Sprite available? (yes: path, no: placeholder)

## Skills Loaded
- `platformer-movement` or `top-down-movement` (based on genre)
- `animation-state-machine`
- `input-handling`

## Steps
1. Create `entities/player.lua` with movement, animation, input
2. Wire player into main.lua
3. Verify: player loads, moves, animates
