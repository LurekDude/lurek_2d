# Physics Demo

**Category:** simulation
**Engine:** Lurek2D

## Description

A physics playground sandbox where you can spawn shapes, watch them interact with gravity and collisions, drag and throw objects, toggle wind and slow-motion, place ramps, and pin objects in place. Demonstrates AABB collision detection, restitution cycling, friction, energy tracking, and particle effects.

## Controls

| Key        | Action                                       |
| ---------- | -------------------------------------------- |
| **1**      | Spawn circle at mouse position               |
| **2**      | Spawn rectangle at mouse position            |
| **3**      | Spawn triangle at mouse position             |
| **Mouse1** | Click to spawn selected shape / drag objects |
| **G**      | Toggle gravity                               |
| **B**      | Cycle bounce restitution (0.3 / 0.7 / 1.0)   |
| **C**      | Clear all objects                            |
| **M**      | Toggle slow-motion (0.25x)                   |
| **W**      | Toggle horizontal wind force                 |
| **R**      | Place a 45° ramp at mouse position           |
| **P**      | Pin nearest object (becomes static obstacle) |
| **Escape** | Quit                                         |

## Features

- Gravity simulation (400 px/s²) with toggle
- Random shape spawning with proportional mass
- AABB collision detection with configurable restitution
- Friction on ground contact
- Screen-edge wall boundaries
- Click-drag to throw objects with velocity
- Slow-motion mode (0.25x time scale with tween transition)
- Horizontal wind force
- 45° ramp placement
- Object pinning (static obstacles)
- Particle effects: spawn poof, collision sparks, drag trails
- HUD: object count, total energy, gravity/wind/bounce indicators
- Max 200 objects with automatic oldest removal
- Title screen → running state flow

## Running

```bash
cargo run -- content/games/simulation/physics_demo
```
