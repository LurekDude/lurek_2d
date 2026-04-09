# Pipeline Showcase

Demonstrates the complete Luna2D main-loop callback pipeline using the
`luna.scene` push-down stack, `luna.entity` ECS, and `luna.ui` widget GUI.

## What It Demonstrates

- `luna.scene.push/switchTo/pop` — push-down scene stack with lifecycle callbacks
- `scene:ready()` — one-time setup fired after `enter()`, before the first `process()` tick
- `scene:process(dt)` / `scene:process_physics(dt)` / `scene:process_late(dt)` — full update pipeline
- `scene:render()` / `scene:render_ui()` — separated game-world and HUD render passes
- `luna.entity.newUniverse()` — ECS world; entities carry `pos`, `vel`, `radius`, `color` components
- `luna.ui.newButton` / `luna.ui.newLabel` — retained-mode GUI buttons and status label
- `luna.time.getPhysicsDelta()` — reading the current fixed physics timestep

## How to Run

```bash
cargo run -- demos/showcase/pipeline_showcase
```

## Controls

| Key / Action | Effect |
|---|---|
| Click **▶ Start Simulation** | Switch to the simulation scene |
| Click **← Menu** (in sim) | Switch back to the menu scene |
| `ESC` | Pop the current scene (quit from menu) |

## Scene Structure

```
MenuScene
  enter()       — set background colour
  ready()       — build GUI buttons (once after first process tick)
  process(dt)   — animate title pulse, tick luna.ui
  render()      — draw title text
  render_ui()   — draw GUI widgets, footer label

SimScene
  enter()       — set background colour
  ready()       — create ECS Universe, spawn initial particles, build GUI
  process(dt)   — spawn more particles, tick luna.ui
  process_physics(dt) — integrate particle velocities, bounce off walls
  process_late(dt)    — update HUD status label with live entity count
  render()      — draw all entity particles
  render_ui()   — draw title banner, pipeline legend, GUI widgets
```
