# Pinball

A physics-driven pinball table with flippers, circular bumpers, score targets, and a spring-loaded ball launcher. The table uses a 500 × 700 portrait window to give the classic tall pinball proportions. Bumpers have a restitution of 1.8 so they actively propel the ball outward.

## What It Demonstrates

- Physics bodies as a complete game mechanic: every table element is a static `lurek.physics` body
- Flipper simulation using angle-driven kinematic body repositioning per frame
- Circular bumpers with `setBodyRestitution(1.8)` to create repulsion above normal elasticity
- Angled gutter walls built from `newBody` + `setBodySize` positioned along a diagonal
- Launch plunger: `Space` held charges `launch_power`, released applies a vertical impulse to the ball body
- Flash timer on bumper/target hit for visual feedback without a sprite system
- Ball respawn and `balls_left` stock counter

## How to Run

```powershell
cargo run -- content/demos/pinball
```

## Controls

| Key | Action |
|-----|--------|
| Left Arrow or `Z` | Left flipper |
| Right Arrow or `/` | Right flipper |
| Hold `Space` | Charge launcher |
| Release `Space` | Launch ball |

## Notes

- Hold `Space` longer for a stronger launch — `launch_power` fills over ~1 second.
- Bumpers flash briefly on contact; score targets turn grey after being hit.
- The narrow 500 px wide table is intentional — it matches the classic portrait pinball cabinet ratio.
