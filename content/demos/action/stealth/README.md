# Stealth

A top-down stealth game where the player must reach an exit zone without being spotted by patrolling guards. Guards project a visible cone of vision in their current facing direction; crouch to reduce your detection radius and use hide spots to become invisible.

## What It Demonstrates

- Line-of-sight cone detection with `math.atan2` for guard facing angle and angular threshold for cone width
- Wall occlusion: `canSee()` ray-marches from guard to player and returns false if a wall tile is crossed
- Guard state machine: `"patrol"` → `"alert"` (heard) → `"chase"` (seen) → `"return"` (lost player)
- Crouching reduces the player `detectRadius` used in the detection cone check
- Hide-spot mechanic: tiles tagged as cover suppress all detection regardless of vision cone
- `drawLine` + `drawCircle` to render the vision cone as a filled arc approximation

## How to Run

```powershell
cargo run -- demos/stealth
```

## Controls

| Key | Action |
|-----|--------|
| `W` `A` `S` `D` | Move |
| Hold Left Shift | Crouch (slower movement, smaller detection radius) |
| Reach cyan exit zone | Win |
| `R` | Restart |

## Notes

- Crouching while in a hide spot eliminates detection entirely.
- Guards return to their patrol route after losing the player — wait for them to resume patrol before moving.
- The vision cone angle and range are drawn so you can always see exactly what a guard can see.
