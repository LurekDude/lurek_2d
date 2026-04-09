# Maze Defense

A tower defense game where the player controls both the maze and the towers. Place walls to redirect enemies through longer paths, and build shooting towers to eliminate them before they reach the exit. Every wall placement recalculates the BFS shortest path, so mazing strategy is core.

## What It Demonstrates

- BFS pathfinding that recalculates live after every wall placement
- Grid-based build mode toggling between `wall` and `tower` modes
- Wave spawning with escalating enemy HP and speed per wave
- Bullet-enemy circular collision detection with sweep cleanup
- Gold economy: enemies award gold on death, walls and towers have costs
- Path blocking guard: if a wall would seal the exit the placement is rejected
- Screen-space grid drawing with `luna.gfx.drawRect` per cell

## How to Run

```powershell
cargo run -- demos/maze_defense
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click | Place wall or tower (selected mode) |
| `1` | Select wall mode (costs 5 gold) |
| `2` | Select tower mode (costs 20 gold) |
| `N` | Start next wave |
| `Escape` | Quit |

## Notes

- Place walls to create bottlenecks before sending the next wave.
- Towers cannot fire through walls; position them at chokepoints for best coverage.
- Enemy HP and speed scale with wave number — rushing with minimal walls becomes untenable by wave 5.
