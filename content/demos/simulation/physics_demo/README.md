# Physics Demo

Demonstrates Luna2D's rapier2d-backed physics world: dynamic rigid bodies, a static ground plane, sensors, collision events, and layer filtering.

## What It Demonstrates

- `luna.physics.newWorld()` — create a physics world
- `luna.physics.newCircleBody()` / `newRectBody()` — dynamic bodies
- `luna.physics.newStaticRectBody()` — static ground and walls
- `luna.physics.newCircleSensor()` — trigger zones (no collision response)
- `luna.physics.setLayerFilter()` — selective collision groups
- `luna.physics.getCollisionEvents()` — reading contact begin/end events
- `luna.physics.getPosition()` / `getAngle()` — querying body state
- `luna.physics.step()` — advancing the simulation per frame

## How to Run

```powershell
cargo run -- demos/physics_demo
```

## Controls

| Key | Action |
|-----|--------|
| Space | Spawn a new ball |
| R | Reset the simulation |

## Notes

- Bodies that fall into the sensor zone at the bottom change colour
- Layer-filtered circle is rendered in a different colour to show non-interaction
