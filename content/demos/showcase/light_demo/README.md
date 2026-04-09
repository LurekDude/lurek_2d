# Light Demo

Demonstrates the Lurek2D 2D lighting system.

## Features

- **Point lights** — warm player torch with smooth falloff and shadow casting
- **Flickering torches** — six wall torches with animated intensity and position wobble
- **Shadow occluders** — polygon walls that block and cast shadows from lights
- **Blend modes** — additive, subtractive, and mix rendering
- **Falloff modes** — linear, smooth, and constant falloff
- **Ambient lighting** — adjustable scene-wide ambient from near-black to day

## Controls

| Key | Action |
|-----|--------|
| WASD | Move the player light |
| 1 / 2 / 3 | Switch blend mode: add / sub / mix |
| F / G / H | Switch falloff: linear / smooth / constant |
| + / - | Increase / decrease ambient brightness |
| SPACE | Toggle shadow casting on the player light |
| T | Toggle torch lights on / off |
| C | Clear all lights and recreate the scene |

## Run

```powershell
cargo run -- content/demos/light_demo
```
