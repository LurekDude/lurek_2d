# Tower Defense

A classic fixed-path tower defense. Place towers beside a winding waypoint path to eliminate enemies before they reach the exit. Earn gold from kills, spend it on Basic or Cannon towers, and survive escalating waves.

## What It Demonstrates

- Fixed waypoint path with linear interpolation: `lerpPath(t)` maps a scalar `[0, 1]` travel distance to an `(x, y)` position along the eight-waypoint route
- Two tower types: Basic (range 80, single-target) and Cannon (range 120, splash damage AoE)
- Grid-based placement: towers can only be placed on empty cells not occupied by the path
- Wave escalation: enemy HP and count scale with `wave` number
- Gold economy: enemies award gold equal to their HP tier, towers cost 20/40 gold
- Bullet-enemy sweep: each tower fires at nearest enemy in range on a cooldown timer

## How to Run

```powershell
cargo run -- content/demos/tower_defense
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click empty tile | Place selected tower |
| `1` | Select Basic Tower ($20) |
| `2` | Select Cannon Tower ($40) |
| `N` | Start next wave |
| `Escape` | Quit |

## Notes

- Place Cannon towers at choke points — their splash damage is most effective against clustered enemies.
- Enemies do not react to towers; they always follow the fixed waypoint path.
- The path cells are highlighted so you can identify which grid cells are blocked from placement.
