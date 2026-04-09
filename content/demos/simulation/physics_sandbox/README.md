# Physics Sandbox

A free-form interactive playground for the Lurek2D physics engine. Spawn circles and rectangles, drag them around, connect pairs with distance joints, toggle gravity and wind, and delete anything you no longer need. A useful testbed for understanding how `lurek.physics` bodies behave before using them in a real game.

## What It Demonstrates

- `lurek.physics.newCircleBody()` and `lurek.physics.newBody()` for dynamic objects
- `lurek.physics.setBodySize()` and `lurek.physics.setBodyRestitution()` for shape and bounce tuning
- `lurek.physics.getBody()` to read simulated positions back into Lua each frame
- `lurek.physics.setBodyPosition()` for manual drag (kinematic override during drag)
- `lurek.physics.newJoint()` to connect two bodies with a distance constraint
- `lurek.physics.setGravity()` to toggle gravity on/off at runtime
- Right-click deletion and `Delete` key full-clear patterns

## How to Run

```powershell
cargo run -- content/demos/physics_sandbox
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
