# Debug Bridge Demo

Simulated debug bridge visualization demonstrating runtime inspection concepts: a debug console with typed commands, real-time engine metrics, entity inspector, scrolling frame time graph, memory display, log level filtering, and breakpoint freeze mode.

## Run

```
cargo run -- content/games/showcase/debugbridge_demo
```

## Controls

| Key    | Action                                               |
| ------ | ---------------------------------------------------- |
| 1–5    | Inspect entity (Player, Enemy, Chest, Camera, Light) |
| D      | Set log filter to DEBUG                              |
| I      | Set log filter to INFO                               |
| W      | Set log filter to WARN                               |
| E      | Set log filter to ERROR                              |
| B      | Toggle breakpoint (pause / resume)                   |
| Escape | Quit                                                 |

## Gameplay

This is a showcase rather than a game — it visualises the kind of tooling a debug bridge provides at runtime. The left panel holds a debug console that responds to simulated commands (status, fps, memory, entities, help) and a scrolling log window with color-coded entries filterable by severity level. The right panel shows a live frame-time bar graph, a heap memory usage bar, and an entity inspector that displays component breakdowns for five simulated entities. Press B to trigger a breakpoint that freezes execution and lets you inspect the frozen state.

### Console Commands
- **help** — list available commands
- **status** — engine state, uptime, draw calls
- **fps** — average frame time and FPS
- **memory** — simulated heap usage
- **entities** — list all entities with type and health

### Breakpoint Mode
Pressing B pauses the simulation and emits a red particle burst. While paused, entity inspection still works — press 1–5 to view frozen entity state. Press B again to resume.

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`

## Changes from Original Demo

### Added
- Title screen with glowing "DEBUG BRIDGE" header and grid background
- Three states: TITLE → RUNNING → PAUSED
- Action-based input bindings (`lurek.input.bind`)
- `render` / `render_ui` split — frame graph in render(), all UI panels in render_ui()
- Particle effects: log message pulse, breakpoint flash
- Tween animations: entity inspector highlight, graph smooth scroll
- Camera integration
- `setBackgroundColor`, `setTitle`, `signal.quit`, FPS display
