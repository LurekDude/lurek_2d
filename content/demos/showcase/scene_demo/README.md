# Scene Demo

A Lua-side scene state machine: Title Screen → Gameplay → Game Over. Shows how to organise game states without any engine-level scene module.

## What It Demonstrates

- `lurek.scene` — scene/state machine (optional engine module)
- Manual scene tables with `load / update / draw / keypressed` methods
- Scene transition animations using `lurek.math.lerp()`
- `lurek.gfx.print()` with alignment and colour changes per state
- Proper per-scene input handling

## How to Run

```powershell
cargo run -- content/demos/scene_demo
```

## Controls

| Key | Action |
|-----|--------|
| Enter | Advance to next scene |
| Esc | Return to previous scene |

## Notes

- Demonstrates the recommended pattern for multi-screen games
- No external assets required — all rendering uses primitives and text
