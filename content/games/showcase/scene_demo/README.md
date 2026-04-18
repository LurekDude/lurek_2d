# Scene Demo

Scene state machine with enter/exit callbacks, three transition effects, and a collect-the-coins mini-game — all wired through a reusable scene manager.

## What It Demonstrates

- `lurek.input.bind()` — action-based input for navigation, movement, transitions, debug toggle
- `lurek.render.*` — per-scene world-space drawing (coins, player, backgrounds)
- `lurek.render.print()` — per-scene UI overlays (menus, scores, debug panel)
- `lurek.particle.newSystem()` — coin collect sparkle, transition particles, menu hover glow
- `lurek.tween.to()` — button highlight scaling, transition alpha, score popup float
- `lurek.camera.new()` — gameplay camera with attach/detach
- `lurek.window.setTitle()` — dynamic title per scene
- `lurek.render.setBackgroundColor()` — unique background colour per scene
- `lurek.signal.quit()` — clean exit from menu
- `lurek.time.getFPS()` — FPS counter in debug overlay

## How to Run

```bash
cargo run -- content/games/showcase/scene_demo
```

## Controls

| Key           | Action                                          |
| ------------- | ----------------------------------------------- |
| Up / Down     | Navigate menus                                  |
| Enter         | Select / Confirm / Restart                      |
| W / A / S / D | Move player (gameplay)                          |
| T             | Cycle transition type (Fade / Slide / Dissolve) |
| D             | Toggle debug panel                              |
| Escape        | Quit                                            |

## Notes

- Three transition types: fade-to-black, slide-left, dissolve (random pixel reveal)
- Settings scene adjusts difficulty (1–3) and volume (0–100) with immediate visual feedback
- Debug panel (D key) shows last 5 scene transitions, current scene name, FPS, and transition type
- Each scene has independent enter/exit lifecycle with resource cleanup
