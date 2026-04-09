# Asteroids

Navigate a ship through a field of tumbling asteroids.
Shoot them to split them — large ones become medium, medium become small.

## What It Demonstrates

- `luna.gfx.line()` — vector-style asteroid outlines and ship wireframe
- `luna.input.isKeyDown()` — thrust and rotation
- `luna.keypressed()` — shooting with bullet lifetime
- Screen wrapping for ship and bullets
- Inertial physics with drag for authentic feel

## Controls

| Key | Action |
|-----|--------|
| Left / Right Arrows | Rotate ship |
| Up Arrow | Thrust forward |
| Space or Z | Fire |
| R | Restart after game over |
| Escape | Quit |

## Notes

The ship uses an inertial model — thrust applies acceleration and momentum carries the ship
even when you stop thrusting. Explosions produce colour particles using manual emission.
Invincibility grace period after respawn prevents immediate death.
