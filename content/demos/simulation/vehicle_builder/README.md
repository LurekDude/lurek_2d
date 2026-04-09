# Vehicle Builder

A two-mode vehicle construction game. In **build mode** place chassis, wheels, engine, and wing parts on a 12 × 8 grid within a budget limit. Switch to **test mode** to simulate the vehicle on a physics-driven scrolling test track with ramps and obstacles.

## What It Demonstrates

- Dual-mode architecture: `state = "build"` and `state = "test"` share a parts table but use separate update and draw paths
- Grid snapping in build mode: mouse position mapped to nearest grid cell, part outline preview before placement
- Budget constraint: each part type has a cost; placing a part deducts from the budget and is shown in the HUD
- Physics body generation from parts: chassis → static body, wheels → circle bodies, engine → impulse source
- Per-frame engine force: engine parts call `luna.physics.applyImpulse()` on the chassis body each update
- Wing lift: wing parts add upward force proportional to horizontal velocity
- Scrolling test track generated from a segment table with road surface and obstacle bodies

## How to Run

```powershell
cargo run -- demos/vehicle_builder
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click (build mode) | Place selected part |
| Right Click (build mode) | Remove part |
| `1` – `4` | Select part: Chassis / Wheel / Engine / Wing |
| `Space` | Switch between build and test mode |
| `R` (test mode) | Reset vehicle to start |
| `Escape` | Quit |

## Notes

- Wheels are required for ground movement; engines provide thrust and wings add lift at speed.
- Budget is hard-capped — plan your part layout before placing expensive chassis segments.
- The test track scrolls right automatically; the goal is to travel as far as possible before flipping.
