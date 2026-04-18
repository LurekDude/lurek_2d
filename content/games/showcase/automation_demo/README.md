# Automation Demo

**Category:** showcase

Record, replay, and visualize input automation in real time.

## How to Play

- **R** — Start / stop recording input events (keys, mouse clicks, mouse movement)
- **P** — Play back recorded events with exact timing
- **1 / 2 / 3** — Set playback speed (0.5× / 1× / 2×)
- **C** — Clear all recorded events
- **T** — Run a built-in auto-test sequence that draws a pattern
- **Click** — Draw colored rectangles on the canvas
- **Escape** — Quit

## Features

- Full input recording: keystrokes, mouse clicks, and mouse movement with timestamps
- Faithful playback with adjustable speed control
- Ghost cursor (green circle) traces replayed mouse position
- Key flash boxes visualize replayed keystrokes
- Event timeline bar at the bottom with event markers
- Interactive canvas: click to draw rectangles — automation replays the drawing
- Built-in auto-test draws a geometric pattern to demonstrate the system
- Particle effects for recording pulse, playback trails, and event sparkles
- Tween-driven smooth timeline cursor and ghost cursor interpolation
- HUD with event counter, playback progress, and FPS

## Running

```bash
cargo run -- content/games/showcase/automation_demo
```
