# Light Showcase

An interactive eight-screen tour of Luna2D's 2D dynamic lighting system. Each screen isolates a distinct lighting feature — point lights, spot lights, directional light, flicker effects, attenuation curves, light groups, shadow filter quality, and blend modes — with a movable player-controlled light so you can explore how each parameter changes the result.

## What It Demonstrates

- `luna.light.newLight()` — creating point, spot, and directional light sources with color, intensity, and radius
- `luna.light.setAmbient()` — controlling the base ambient level that fills unlit areas
- `luna.light.clear()` — clearing all lights when switching between showcase screens
- `luna.light.setGroupEnabled()` — batch-toggling lights by `groupId` with a single call
- `luna.light.newLight()` flicker parameters — `flickerSpeed` and `flickerStrength` for torch/fire effects
- `luna.light.newLight()` attenuation parameters — `attConstant`, `attLinear`, `attQuadratic` decay curves
- `luna.keyboard.isDown()` — WASD movement of the player-controlled demonstration light
- `luna.keyboard.wasPressed()` — number keys 1–8 to jump directly to a screen, G to toggle light groups

## How to Run

```powershell
cargo run -- demos/light_showcase
```

## Controls

| Input | Action |
|-------|--------|
| 1 – 8 | Switch to a showcase screen |
| W / A / S / D | Move the white player light |
| G | Toggle light group 1 on/off (screen 6 only) |
| Left / Right Arrow | Previous / next screen |
| Escape | Quit |

## Notes

- Screen 1 — four coloured point lights plus a movable white lantern
- Screen 2 — three spot lights with different `innerAngle` / `outerAngle` configurations
- Screen 3 — sunlight and moonlight as directional lights with a player lantern overlay
- Screen 4 — candle, torch, campfire, and strobe with escalating `flickerSpeed` and `flickerStrength`
- Screen 5 — constant, linear, quadratic, and mixed attenuation compared side by side
- Screen 6 — group 1 torches toggleable with G; group 2 accent lights always on
- Screen 7 — the same scene re-rendered with no shadow filtering, PCF5, and PCF13
- Screen 8 — additive, subtractive, and mix blend modes on overlapping lights
