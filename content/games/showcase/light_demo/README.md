# Light Demo

Complete 2D lighting system showcase featuring dynamic point lights, spotlights, flickering torches, shadow-casting wall occluders, and ambient light control with smooth tween transitions.

## Run

```
cargo run -- content/games/showcase/light_demo
```

## Controls

| Key          | Action                                       |
| ------------ | -------------------------------------------- |
| WASD         | Move player light                            |
| 1-4          | Change light color (White/Red/Blue/Green)    |
| Q / E        | Decrease / increase light radius             |
| Mouse Scroll | Adjust light radius                          |
| F            | Toggle spotlight mode (follows mouse)        |
| T            | Toggle wall torches on/off                   |
| R            | Cycle ambient tint (Neutral/Warm/Cool/Eerie) |
| + / -        | Increase / decrease ambient light level      |
| Enter        | Start from title screen                      |
| Escape       | Quit                                         |

## What It Demonstrates

- `lurek.light.newLight()` — point and spot light creation
- `Light:setFlicker()` — built-in torch flicker effect
- `lurek.light.newOccluder()` — shadow-casting wall geometry
- `lurek.light.setAmbient()` — global ambient light control
- `lurek.light.advanceFlickers()` — per-frame flicker update
- `lurek.particle.newSystem()` — torch flame and player glow particles
- `lurek.tween.to()` — smooth ambient and color transitions
- `lurek.input.bind()` — action-based input mapping
- `lurek.camera.new()` — camera attach/detach for world-space rendering
- Render/render_ui split — scene in `render()`, HUD in `render_ui()`

## Gameplay

Navigate a dark room with your light. Ten rectangular walls cast shadows from your light source. Six wall-mounted torches provide flickering orange illumination. Adjust ambient darkness from pitch black (0.0) to fully lit (1.0), switch between point and spotlight modes, cycle through four light colors, and experiment with ambient tints to create different atmospheric moods.

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.light`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`
