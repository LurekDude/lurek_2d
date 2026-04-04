---
name: Add Save System
description: Implement save/load functionality for the game.
mode: ask
---

# Add Save System

## Questions
1. What data must be saved? (progress, settings, inventory)
2. Single slot or multiple?
3. Autosave on level transition?

## Skills Loaded
- `save-load`

## Steps
1. Route to **lua-scripter** to implement `saves/save.lua`
2. Add save versioning and migration
3. Add save/load tests
