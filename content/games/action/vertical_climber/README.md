# Vertical Climber

Endless Doodle Jump-style vertical platformer — auto-bounce upward through procedurally generated platforms, dodge enemies, and climb as high as you can.

## Run

```
cargo run -- content/games/action/vertical_climber
```

## Controls

| Key       | Action       |
| --------- | ------------ |
| A / ←     | Move left    |
| D / →     | Move right   |
| Space / W | Shoot upward |
| Escape    | Quit         |

## Gameplay

The player automatically bounces when landing on platforms — there is no jump button. Guide the climber left and right to land on platforms and ascend ever higher.

- **Screen wrapping** — moving off the left edge teleports you to the right, and vice versa.
- **Normal platforms** (green) — solid and always present.
- **Moving platforms** (blue) — oscillate horizontally across the screen.
- **Crumbling platforms** (brown) — break apart after you land on them and fall away as debris.
- **Spring platforms** (yellow) — launch the player twice as high with a coil-stretch animation.
- **Enemies** — small red circles that patrol platforms; touching one is fatal. Shoot them with Space/W.
- **Procedural generation** — platforms spawn above the camera as you climb; difficulty increases with altitude (fewer normal platforms, more crumbling and moving ones).
- **Score** — based on maximum height reached. High score is tracked within the session.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.time, lurek.signal, lurek.particles, lurek.tween, lurek.camera
