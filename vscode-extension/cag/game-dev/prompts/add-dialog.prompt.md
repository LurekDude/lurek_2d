---
name: Add Dialog
description: Add NPC conversation or dialog system to the game.
mode: ask
---

# Add Dialog

## Questions
1. Character voice/tone?
2. Dialog goal? (story, shop, quest-giver, tutorial)
3. Branching or linear?

## Skills Loaded
- `dialogue-system`

## Steps
1. Route to **narrative-writer** for dialog tree
2. Export to TOML format
3. Route to **lua-scripter** for dialog runner integration
