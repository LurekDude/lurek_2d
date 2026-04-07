# Horror

An atmospheric psychological horror game set in a hand-crafted tile maze. You carry a flashlight with a finite battery that drains in the dark, and your sanity erodes whenever the light is off. Collect five keys scattered through the maze to unlock the exit while evading a patrolling enemy that chases you on line-of-sight.

## What It Demonstrates

- `luna.keyboard.isDown()` — WASD and arrow-key movement with wall-slide collision
- `luna.mouse.getPosition()` — flashlight cone direction follows the cursor in world space
- `luna.gfx.rectangle()` — tile map, sanity bar, battery bar, and key HUD
- `luna.gfx.setColor()` — darkness overlay tinted by sanity level; distortion tint when sanity is low
- `luna.gfx.polygon()` — flashlight cone rendered as a triangle fan in world space
- `luna.gfx.print()` — key counter, note text pop-ups, win/lose overlays
- `luna.gfx.setBackgroundColor()` — full black to simulate total darkness
- Tile-based collision — `isWall()` maps world coordinates to LEVEL grid characters for per-axis resolution

## How to Run

```powershell
cargo run -- demos/horror
```

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D or Arrow Keys | Move |
| Mouse | Aim flashlight |
| F | Toggle flashlight on/off |
| E | Interact (pick up keys, read notes) |
| Escape | Quit |

## Notes

- The flashlight drains 5 battery/s; recharge stations (tile `2`) restore it at 30 battery/s
- Sanity drains at 3/s in darkness and recovers at 1/s in light; reaching zero triggers a game-over screen
- The enemy follows patrol points between keys; it switches to chase mode when it has line-of-sight to the player
- Screen-shake magnitude (`screenShake`) is applied as a random draw each frame when the enemy is near
