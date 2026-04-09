---
name: Add Enemy
description: Add an enemy entity with AI behavior and combat interaction.
mode: ask
---

# Add Enemy

## Questions
1. Enemy type? (patrol, chase, ranged, boss)
2. How does it interact with the player? (contact damage, projectiles, melee)
3. Should it drop items on death?

## Skills Loaded
- `pathfinding-ai`
- `combat-system`
- `animation-state-machine`

## Steps
1. Create `entities/enemy_{name}.lua`
2. Define AI behavior states
3. Add collision/damage handling
4. Route to **game-tester** for edge case list
