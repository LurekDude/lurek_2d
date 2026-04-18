# Platformer

Classic side-scrolling 2D platformer — run, jump, and stomp through three tile-based levels.

## Run

```
cargo run -- content/games/action/platformer
```

## Controls

| Key           | Action     |
| ------------- | ---------- |
| A / ←         | Move left  |
| D / →         | Move right |
| Space / W / ↑ | Jump       |
| Escape        | Quit       |

## Gameplay

Navigate tile-based levels filled with floating platforms, moving platforms, enemies, coins, and spikes. Reach the goal flag at the end of each level to advance.

- **Coyote time** — a brief 0.1 s window after walking off a ledge where you can still jump.
- **Wall slide** — pressing into a wall while airborne slows your fall, allowing precise landings.
- **Enemy stomping** — landing on top of a walker enemy destroys it; touching one from the side costs a life.
- **Coins** — collect yellow coins scattered across platforms for +100 points each.
- **Spikes** — red tiles on the ground cause instant death on contact.
- **3 levels** of increasing difficulty, 3 lives total, respawn at level start on death.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.time, lurek.signal, lurek.particles, lurek.tween
