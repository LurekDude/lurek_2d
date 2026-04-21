# Devtools Demo

Developer tools profiling showcase: toggle real-time FPS graphs, memory profilers, entity inspectors, performance heatmaps, and draw call counters while a live ball-physics scene runs underneath.

## What It Demonstrates

- `lurek.render.circle()` / `lurek.render.rectangle()` / `lurek.render.line()` — drawing game objects and UI panels
- `lurek.render.print()` — on-screen text for profiling overlays
- `lurek.particle.newSystem()` — spawn burst and stress-test warning particles
- `lurek.tween.to()` / `lurek.tween.update()` — smooth panel slide-in/out animations
- `lurek.input.bind()` / `lurek.input.wasActionPressed()` — action-based input for all toggles
- `lurek.window.setTitle()` / `lurek.render.setBackgroundColor()` — window setup
- `lurek.event.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/showcase/devtools_demo
```

## Controls

| Key    | Action                                               |
| ------ | ---------------------------------------------------- |
| F1     | Toggle FPS overlay (frame time graph + counter)      |
| F2     | Toggle memory profiler (heap bar, allocation count)  |
| F3     | Toggle entity inspector (ball positions/velocities)  |
| F4     | Toggle performance heatmap (color-coded frame times) |
| F5     | Toggle draw call counter                             |
| Tab    | Cycle through profiling panels one at a time         |
| Space  | Spawn 10 more balls                                  |
| S      | Stress test — spawn 200 balls at once                |
| M      | Toggle slow-motion (0.25x time scale)                |
| E      | Export profiling summary overlay                     |
| Escape | Quit                                                 |

## Notes

- Frame time history uses a 240-sample ring buffer drawn as a line graph with color-coded segments (green < 8 ms, yellow < 16 ms, red > 16 ms).
- Memory tracking is simulated — estimates 72 bytes per ball object and tracks peak usage.
- The stress test (S key) is designed to induce frame drops so the heatmap and FPS graph show meaningful data.
- Panels slide in from the right with tweened animations; Tab cycles through them one at a time.
