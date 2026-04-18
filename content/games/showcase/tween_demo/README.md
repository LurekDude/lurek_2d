# Tween Demo

**Category:** showcase

Interactive easing curve showcase demonstrating all 12 built-in `lurek.tween` easing types simultaneously. Each easing drives a colored rectangle with a real-time curve graph, speed control, manual scrubbing, and multiple animated property modes.

## Run

```
cargo run -- content/games/showcase/tween_demo
```

## Controls

| Key       | Action                             |
| --------- | ---------------------------------- |
| Space     | Pause / Resume all animations      |
| 1         | Set speed to 0.5x                  |
| 2         | Set speed to 1.0x (default)        |
| 3         | Set speed to 2.0x                  |
| Left      | Step backward 0.05s (while paused) |
| Right     | Step forward 0.05s (while paused)  |
| Up / Down | Select easing for curve graph      |
| P         | Cycle animated property mode       |
| Escape    | Quit                               |

## Easing Types

1. **linear** — Constant speed, no acceleration
2. **inQuad** — Accelerating from zero
3. **outQuad** — Decelerating to zero
4. **inOutQuad** — Accelerate then decelerate
5. **inCubic** — Stronger acceleration from zero
6. **outCubic** — Stronger deceleration to zero
7. **inOutCubic** — Stronger accel/decel
8. **inSine** — Gentle sine-based acceleration
9. **outSine** — Gentle sine-based deceleration
10. **inOutSine** — Gentle sine-based accel/decel
11. **inExpo** — Exponential acceleration
12. **outExpo** — Exponential deceleration

## Property Modes

Press **P** to cycle through what the tweens animate:

- **Position** — Rectangles move left to right (x = 150 → 650)
- **Scale** — Rectangles grow from 0.5x to 2.0x size
- **Rotation** — Simulated rotation via circular offset (0° → 360°)
- **Alpha** — Opacity fades from 0.2 to 1.0
- **Color** — Hue shifts from red through green to blue

## Features

- 12 easing animations running simultaneously
- Bottom panel: interactive curve graph for the selected easing
- White dot tracks current progress on the curve
- Crosshair overlay shows exact time/value position
- Faint linear reference line for comparison
- Particle burst on animation cycle completion
- Particle flash on property mode switch
- Looping: all animations restart automatically after completing
