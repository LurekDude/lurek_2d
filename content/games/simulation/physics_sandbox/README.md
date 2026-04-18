# Physics Sandbox

Free-form physics playground where you build structures and destroy them with explosions, heavy balls, and gravity manipulation.

## Run

```
cargo run -- content/games/simulation/physics_sandbox
```

## Controls

| Key         | Action                                               |
| ----------- | ---------------------------------------------------- |
| B           | Build mode — click+drag to create rectangles         |
| D           | Destroy mode — click to explode                      |
| Shift+Click | Place as static (build mode)                         |
| Space       | Launch heavy ball toward cursor                      |
| G           | Toggle gravity on/off                                |
| Arrow keys  | Change gravity direction                             |
| R           | Rope mode — click two objects to connect with spring |
| C           | Cycle build color                                    |
| 1           | Spawn small circle (mass 1)                          |
| 2           | Spawn medium rectangle (mass 3)                      |
| 3           | Spawn heavy square (mass 8)                          |
| 4           | Spawn bouncy ball (restitution 1.0)                  |
| X           | Clear all objects                                    |
| Escape      | Quit                                                 |

## Gameplay

Enter build mode to construct walls, floors, and supports from rectangles — hold Shift to make them static anchors. Switch to destroy mode and click to unleash an explosion that sends nearby objects flying. Launch heavy wrecking balls with Space. Toggle gravity or change its direction with G and arrow keys. Connect objects with springy ropes using R mode. Spawn preset shapes with 1–4 for quick experimentation. Maximum 300 objects on screen.

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.time`, `lurek.signal`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `wasActionPressed` / `isActionDown`)

### Added
- Title screen with mode instructions
- Particle effects (explosion bursts, collision sparks, ball launch trails)
- Tween animations (gravity direction transition, mode switch indicator)
- `render` / `render_ui` split with HUD overlay (object count, FPS, mode, gravity direction)
- Camera support, background color, window title
