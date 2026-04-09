# Vertical Climber

A Doodle Jump-style infinite vertical climber. The player auto-bounces off any platform it lands on and must steer left and right to hop up to progressively higher platforms. The world scrolls down based on the player's peak height, so falling below the screen means death.

## What It Demonstrates

- One-way platform collision: only apply bounce when `player.vy > 0` (falling) to allow passing through from below
- Procedural infinite platform generation: when the highest placed platform passes a threshold, new ones are generated above
- Three platform types with distinct behaviours: Normal (solid), Moving (slides left/right), Crumbling (breaks after one use)
- Camera that follows only upward: `camera_y` updates only when `player.y < camera_y + margin`, never when falling
- Constant auto-bounce velocity reset: on platform contact `player.vy = JUMP_VEL` without any key press needed
- Spring pickups that replace standard bounce with a `SPRING_VEL = -650` super-jump
- Enemy horizontal patrollers that trigger death on contact

## How to Run

```powershell
cargo run -- demos/vertical_climber
```

## Controls

| Key | Action |
|-----|--------|
| `A` / Left Arrow | Move left |
| `D` / Right Arrow | Move right |
| `R` | Restart after death |
| `Escape` | Quit |

## Notes

- The player wraps horizontally — walking off the left edge reappears on the right.
- Orange crumbling platforms disappear after one bounce; do not rely on them as a resting point.
- Moving platforms oscillate at increasing speed the higher you climb.
