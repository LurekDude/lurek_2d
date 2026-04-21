# Light Showcase

**Category:** showcase

Multi-screen interactive showcase of 8 lighting techniques available in the Lurek2D `lurek.light` API: point lights, spot lights, directional light, flicker effects, attenuation curves, light groups, shadow filtering, and blend modes.

## Run

```
cargo run -- content/games/showcase/light_showcase
```

## Controls

| Key          | Action                                      |
| ------------ | ------------------------------------------- |
| 1–8          | Jump to screen                              |
| Left / Right | Cycle screens                               |
| Mouse        | Move interactive light (screens 1, 2, 3, 5) |
| Escape       | Quit                                        |

## Screens

1. **Point Lights** — 5 colored point lights orbiting center, adjustable radius via mouse Y.
2. **Spot Lights** — 3 spotlights with cone angles performing a rotating sweep.
3. **Directional Light** — Sunlight simulation with automatic day/night cycle.
4. **Flicker Effects** — Candle, torch, neon, strobe — 4 flicker patterns side by side.
5. **Attenuation** — Same light with linear, quadratic, and cubic falloff in 3 comparison panels.
6. **Light Groups** — Red, blue, and green light groups; toggle each group independently.
7. **Shadow Filtering** — Hard shadows vs soft shadows vs no shadows in 3 comparison panels.
8. **Blend Modes** — Additive, multiply, and screen blend modes shown in 3 comparison panels.

## Features

- Title screen with technique selection prompt
- Per-screen ambient dust / spark / glow mote particles
- Tween-driven screen transition slides and light parameter animations
- Split-screen comparison layout for screens 5, 7, 8
- HUD with screen title, description, navigation hints, and FPS
- Mouse-interactive light positioning on applicable screens
- Camera and background color tuned for dark-scene lighting visibility

## APIs Used

`lurek.light`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.window`, `lurek.event`
