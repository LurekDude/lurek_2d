# Metroidvania

Side-scrolling exploration platformer with interconnected rooms, ability unlocks, and multiple enemy types.

## Run

```
cargo run -- content/games/action/metroidvania
```

## Controls

| Key           | Action                              |
| ------------- | ----------------------------------- |
| A / ←         | Move left                           |
| D / →         | Move right                          |
| Space / W / ↑ | Jump (wall jump when touching wall) |
| Shift         | Dash (once unlocked)                |
| Escape        | Quit                                |

## Gameplay

Explore a 3×3 grid of interconnected rooms. Walk off a screen edge to transition into the adjacent room. Each room is a 20×15 tile grid (16 px tiles, 320×240 logical scaled to 800×600).

The player starts with basic movement and wall-jumping. Two abilities are hidden in the world:

- **Dash** (room 1,1) — press Shift for a quick horizontal burst that can break through purple dash-gates.
- **Double Jump** (room 2,0) — jump a second time in mid-air.

Three enemy types patrol the rooms:

- **Walkers** — pace back and forth on platforms.
- **Flyers** — hover in place and chase the player when nearby.
- **Turrets** — stationary enemies that fire projectiles at intervals.

The player has 5 HP. Contact with enemies or projectiles deals 1 damage with brief invincibility frames. HP pickups scattered through rooms restore 1 HP each. Losing all HP returns to the title screen.

A minimap in the corner tracks which rooms have been visited.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.time, lurek.signal, lurek.particles, lurek.tween, lurek.camera

## Notes

- Rooms are defined as 20×15 tile arrays; tiles: 0=air, 1=wall, 2=platform, 3=dash-gate.
- Camera follows the player within each room and snaps on room transitions.
- Dash-gates (purple blocks) can only be broken after finding the dash ability.
