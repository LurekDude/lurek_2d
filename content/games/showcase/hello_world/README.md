# Hello World

Complete engine feature sampler showcasing basic Lurek2D capabilities in a single interactive screen: animated text, geometric shapes, mouse tracking, particle effects, tween animations, and camera.

## Run

```
cargo run -- content/games/showcase/hello_world
```

## Controls

| Key    | Action                          |
| ------ | ------------------------------- |
| Enter  | Start (title screen)            |
| Space  | Randomize background color      |
| 1      | Spawn rectangle                 |
| 2      | Spawn circle                    |
| 3      | Spawn rotating line             |
| 4      | Spawn spinning triangle (lines) |
| 5      | Spawn spinning hexagon (lines)  |
| C      | Cycle 8-color palette           |
| + / -  | Adjust animation speed          |
| Escape | Quit                            |

## Features

- **Rainbow header** — "HELLO LUREK2D!" with tween-driven color cycling and scale bounce
- **Orbiting rectangle** — rotates around screen center, drawn in the current palette color
- **Bouncing circle** — reflects off all four screen edges
- **Sine-wave grid** — 12×4 grid of pulsing squares with HSV rainbow coloring
- **Mouse follower** — smooth-lerp circle that tracks the cursor
- **Shape gallery** — press 1-5 to spawn shapes with tween scale-bounce and particle burst
- **Confetti** — particle burst when background color randomizes
- **Title screen** — "HELLO WORLD" / "YOUR FIRST LUREK2D APP" with blinking prompt
- **HUD overlay** — shape counter, animation timer, speed multiplier, palette swatch, FPS

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.time`, `lurek.signal`
