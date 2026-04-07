---
applyTo: "**/ui/*.lua"
---
# UI Module Rules
- UI elements are drawn in luna.draw() after game world
- Use normalized coordinates (0-1) for responsive layouts
- Always check luna.gfx.getDimensions() for screen-relative positioning
- UI state changes are driven by events, not polling
- Never block luna.update() for UI animations — use tweens
- Font sizes defined as constants at module top
