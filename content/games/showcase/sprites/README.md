# Sprites Demo

**Category:** showcase

Interactive sprite drawing and animation showcase using procedurally generated pixel art. Demonstrates ImageData creation, sprite rendering with scaling/tinting, frame-based animation, Y-sorted draw order, collectibles, obstacle collision, and movement trails — all without loading external image files.

## Run

```
cargo run -- content/games/showcase/sprites
```

## Controls

| Key    | Action                                   |
| ------ | ---------------------------------------- |
| WASD   | Move character                           |
| +/-    | Scale sprites (1x–4x)                    |
| C      | Cycle color tint (normal/red/blue/green) |
| T      | Toggle movement trail                    |
| Escape | Quit                                     |

## Features

- **Procedural pixel art** — Character (16×16), coins (8×8), trees (16×24), hearts (8×8), stars (8×8) all generated via `lurek.image.newImageData` + `setPixel`.
- **Animation** — Character has 2 walk frames that alternate while moving; coins have 2 rotation frames.
- **Collectibles** — 20 coins scattered randomly; overlap to collect (+1 score) with sparkle particles.
- **Obstacles** — 5 trees block movement; draw order sorted by Y for pseudo-depth.
- **Scaling** — Press +/- to scale all sprites between 1× and 4×.
- **Color tinting** — Press C to cycle character through normal, red, blue, green tints.
- **Movement trail** — Press T to toggle a ghosted trail of the last 5 positions.
- **Particles** — Coin collection sparkle and optional trail particles.
- **Tweens** — Coin hover float animation and collection score popup.
