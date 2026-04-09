---
applyTo: "**/*.lua"
---
# Lurek2D Lua Game Conventions
- Use `local` for all game-internal variables and functions
- Never `require` inside function bodies in hot paths
- Always call `lurek.load()` once and cache expensive resources there
- Prefer event-based communication between systems (Event Bus pattern)
- Game-specific errors use `error("context: message")` with a module prefix
- Comments explain WHY something is done, not WHAT it does
- Numbers in physics are in pixels — document units in comments
- Color values are ALWAYS 0-1 range, not 0-255
