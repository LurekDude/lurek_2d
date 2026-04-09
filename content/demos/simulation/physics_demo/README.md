# Physics Demo

Demonstrates Lurek2D's rapier2d-backed physics world: dynamic rigid bodies, a static ground plane, sensors, collision events, and layer filtering.

## What It Demonstrates

- `lurek.physics.newWorld()` — create a physics world
- `lurek.physics.newCircleBody()` / `newRectBody()` — dynamic bodies
- `lurek.physics.newStaticRectBody()` — static ground and walls
- `lurek.physics.newCircleSensor()` — trigger zones (no collision response)
- `lurek.physics.setLayerFilter()` — selective collision groups
- `lurek.physics.getCollisionEvents()` — reading contact begin/end events
- `lurek.physics.getPosition()` / `getAngle()` — querying body state
- `lurek.physics.step()` — advancing the simulation per frame

## How to Run

```powershell
cargo run -- content/demos/physics_demo
```

## Controls

| Key | Action |
|-----|--------|
| Space | Spawn a new ball |
| R | Reset the simulation |

## Notes

- Bodies that fall into the sensor zone at the bottom change colour
- Layer-filtered circle is rendered in a different colour to show non-interaction
