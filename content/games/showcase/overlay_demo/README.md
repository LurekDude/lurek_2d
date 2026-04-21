# Overlay Demo

Screen overlay effects showcase demonstrating weather particles, time-of-day tinting, fog, and vignette — all composable and intensity-adjustable.

## What It Demonstrates

- `lurek.input.bind()` — action-mapped keys for weather toggles, time cycling, fog/vignette, intensity
- `lurek.particle.newSystem()` — rain, snow, hail, dust, leaves, ash, pollen, fog motes as particle systems
- `lurek.tween.to()` — smooth time-of-day color transitions and intensity changes
- `lurek.camera.attach()` / `lurek.camera.detach()` — camera for scene, detached for HUD
- `lurek.render.setBackgroundColor()` — dynamic sky color based on time of day
- `lurek.window.setTitle()` — window title with active overlay count
- `lurek.event.quit()` — clean exit on Escape

## How to Run

```bash
cargo run -- content/games/showcase/overlay_demo
```

## Controls

| Key    | Action                                        |
| ------ | --------------------------------------------- |
| 1      | Toggle rain                                   |
| 2      | Toggle snow                                   |
| 3      | Toggle hail                                   |
| 4      | Toggle dust                                   |
| 5      | Toggle leaves                                 |
| 6      | Toggle ash                                    |
| 7      | Toggle pollen                                 |
| T      | Cycle time of day (dawn → day → dusk → night) |
| F      | Toggle fog                                    |
| V      | Toggle vignette                               |
| + / =  | Increase overlay intensity                    |
| -      | Decrease overlay intensity                    |
| C      | Clear all overlays                            |
| Escape | Quit                                          |

## Notes

- Multiple overlays can be active simultaneously and are composited additively
- Intensity affects all active overlays uniformly (0.1–1.0 range)
- Time-of-day transitions use tweened color blending for smooth shifts
- Weather particles are full particle systems with physics-like drift, not simple sprites
