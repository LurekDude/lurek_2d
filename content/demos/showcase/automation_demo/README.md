# Automation Demo

Demonstrates the `lurek.simulator` input automation system. The simulator replays scripted sequences of input events (key presses, mouse moves, mouse clicks, text input, scroll wheel) into the engine's event queue, making it useful for testing, replay capture, and guided tutorials.

## What It Shows

- Loading named sequences of actions via `lurek.simulator.load`
- TOML-based script loading as an alternative authoring format
- Starting and stopping replay with `lurek.simulator.play` / `lurek.simulator.stop`
- Inspecting simulator status (`lurek.simulator.isPlaying`, `lurek.simulator.status`)
- All supported action types: `keypress`, `keyrelease`, `mousemove`, `mousepress`, `mouserelease`, `textinput`, `mousewheel`, `wait`

## Controls

| Key | Action |
|-----|--------|
| **Space** | Play / stop the demo sequence |
| **T** | Load and play the TOML-authored sequence |
| **Escape** | Stop the current sequence |

## Run

```sh
cargo run -- content/demos/automation_demo
```
