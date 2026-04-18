# PostFX Demo

Complete post-processing effects stacking showcase with 10 toggleable effects, adjustable intensity, and real-time before/after comparison.

## Run

```
cargo run -- content/games/showcase/postfx_demo
```

## Controls

| Key          | Action                                        |
| ------------ | --------------------------------------------- |
| B            | Toggle Bloom                                  |
| U            | Toggle Blur                                   |
| C            | Toggle CRT scanlines                          |
| V            | Toggle Vignette                               |
| A            | Toggle Chromatic Aberration                   |
| P            | Toggle Pixelate                               |
| S            | Toggle Sepia                                  |
| G            | Toggle Grayscale                              |
| I            | Toggle Color Invert                           |
| F            | Toggle Film Grain                             |
| Tab          | Cycle selected effect for intensity editing   |
| + / -        | Increase / decrease selected effect intensity |
| Space (hold) | Compare — show original scene without effects |
| R            | Reset all effects to off                      |
| Enter        | Start from title screen                       |
| Escape       | Quit                                          |

## What It Demonstrates

- Post-processing effect simulation via layered draw calls
- Effect stacking — all 10 effects can be active simultaneously
- `lurek.input.bind()` — action-based input mapping for all toggles
- `lurek.tween.to()` — smooth intensity transitions on +/- adjust
- `lurek.particles.newSystem()` — toggle flash and intensity sparkle particles
- `lurek.camera.new()` — camera attach/detach for world-space rendering
- `lurek.time.getFPS()` / `lurek.time.getTime()` — FPS display and animation timing
- `lurek.window.setTitle()` — custom window title
- `lurek.render.setBackgroundColor()` — dark background
- `lurek.signal.quit()` — clean exit
- Render/render_ui split — base scene + effects in `render()`, HUD/effect list in `render_ui()`
- Title → Running state machine with animated effect preview on title screen

## Gameplay

The demo renders a colorful test scene with rotating shapes, gradient backgrounds, a rainbow bar, and grid dots. Press effect keys to stack post-processing overlays. Each effect has adjustable intensity controlled with Tab to select and +/- to modify. Hold Space to instantly compare the processed and original scenes. The right-side HUD panel shows all effects with green indicators for active ones and intensity bars.
