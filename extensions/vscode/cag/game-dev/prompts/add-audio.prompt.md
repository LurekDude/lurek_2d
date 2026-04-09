---
name: Add Audio
description: Set up audio system with BGM and sound effects.
mode: ask
---

# Add Audio

## Questions
1. BGM style preference?
2. Which events need SFX? (jump, hit, collect, death, menu)
3. How many audio channels needed?

## Skills Loaded
- `audio-manager`

## Steps
1. Route to **audio-designer** for audio architecture
2. Route to **lua-scripter** to implement audio manager
3. Wire SFX triggers to game events
