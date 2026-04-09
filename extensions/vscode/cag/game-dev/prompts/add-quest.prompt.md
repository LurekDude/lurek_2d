---
name: Add Quest
description: Add a quest or objective tracking system.
mode: ask
---

# Add Quest

## Questions
1. Quest type? (main story, side quest, daily)
2. Objective types needed? (reach, collect, kill, talk)
3. Multi-step or single objective?

## Skills Loaded
- `quest-tracker`

## Steps
1. Define quest data in TOML
2. Route to **lua-scripter** to implement quest tracker
3. Add quest journal UI
