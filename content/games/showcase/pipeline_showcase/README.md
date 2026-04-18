# Pipeline Showcase

Interactive visualization of the full Lurek2D engine callback pipeline — ready, process, process_physics, process_late, render, render_ui — across three scenes that demonstrate different callback usage patterns.

## Run

```
cargo run -- content/games/showcase/pipeline_showcase
```

## Controls

| Key    | Action                                               |
| ------ | ---------------------------------------------------- |
| 1      | Scene 1: Menu (process + render_ui only)             |
| 2      | Scene 2: Simulation (all callbacks — bouncing balls) |
| 3      | Scene 3: Paused (render callbacks only)              |
| F1–F6  | Toggle individual callbacks on/off                   |
| Escape | Quit                                                 |

## Scenes

### Scene 1 — Menu
Only `process` and `render_ui` fire. No physics, no world render. Shows a minimal callback footprint for a menu screen.

### Scene 2 — Simulation
All six callbacks active. Balls bounce with physics, positions update in process, late-process resolves overlaps, world renders in `render`, and stats overlay in `render_ui`.

### Scene 3 — Paused
Only `render` and `render_ui` fire. Process callbacks are skipped — objects freeze in place, demonstrating what happens when the update pipeline is paused.

## Features

- Horizontal flow chart showing callback execution order with live green highlights
- Per-callback timing display (milliseconds per frame)
- Frame counters per callback
- Delta-time readout for each process callback
- F-key toggles let you disable individual callbacks and observe the effect
