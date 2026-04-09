# Physics Sandbox

A free-form interactive playground for the Luna2D physics engine. Spawn circles and rectangles, drag them around, connect pairs with distance joints, toggle gravity and wind, and delete anything you no longer need. A useful testbed for understanding how `luna.physics` bodies behave before using them in a real game.

## What It Demonstrates

- `luna.physics.newCircleBody()` and `luna.physics.newBody()` for dynamic objects
- `luna.physics.setBodySize()` and `luna.physics.setBodyRestitution()` for shape and bounce tuning
- `luna.physics.getBody()` to read simulated positions back into Lua each frame
- `luna.physics.setBodyPosition()` for manual drag (kinematic override during drag)
- `luna.physics.newJoint()` to connect two bodies with a distance constraint
- `luna.physics.setGravity()` to toggle gravity on/off at runtime
- Right-click deletion and `Delete` key full-clear patterns

## How to Run

```powershell
cargo run -- demos/physics_sandbox
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `C` | Spawn circle at mouse position |
| `R` | Spawn rectangle at mouse position |
| Left Click + Drag | Drag an object |
| Right Click | Delete the object under cursor |
| `Delete` | Remove all objects |
| `G` | Toggle gravity on/off |
| `Space` | Pause/unpause simulation |
| `J` then click two objects | Create distance joint between them |
| `B` | Toggle bounce mode (changes restitution for new spawns) |
| `+` / `-` | Increase / decrease spawn size |

## Notes

- Joints are rendered as a line between the two connected body centres.
- Drag uses `setBodyPosition` to move the body; releasing it back into the simulation preserves accumulated velocity.
- Pausing with `Space` freezes the physics step but keeps rendering live — useful for inspecting overlap.
