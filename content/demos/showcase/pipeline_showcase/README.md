# Pipeline Showcase

Demonstrates the complete Lurek2D main-loop callback pipeline using the
`lurek.scene` push-down stack, `lurek.entity` ECS, and `lurek.ui` widget GUI.

## What It Demonstrates

- `lurek.scene.push/switchTo/pop` — push-down scene stack with lifecycle callbacks
- `scene:ready()` — one-time setup fired after `enter()`, before the first `process()` tick
- `scene:process(dt)` / `scene:process_physics(dt)` / `scene:process_late(dt)` — full update pipeline
- `scene:render()` / `scene:render_ui()` — separated game-world and HUD render passes
- `lurek.entity.newUniverse()` — ECS world; entities carry `pos`, `vel`, `radius`, `color` components
- `lurek.ui.newButton` / `lurek.ui.newLabel` — retained-mode GUI buttons and status label
- `lurek.time.getPhysicsDelta()` — reading the current fixed physics timestep

## How to Run

```bash
cargo run -- content/demos/showcase/pipeline_showcase
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
  process(dt)   — animate title pulse, tick lurek.ui
  render()      — draw title text
  render_ui()   — draw GUI widgets, footer label

SimScene
  enter()       — set background colour
  ready()       — create ECS Universe, spawn initial particles, build GUI
  process(dt)   — spawn more particles, tick lurek.ui
  process_physics(dt) — integrate particle velocities, bounce off walls
  process_late(dt)    — update HUD status label with live entity count
  render()      — draw all entity particles
  render_ui()   — draw title banner, pipeline legend, GUI widgets
```
