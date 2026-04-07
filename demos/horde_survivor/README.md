# Horde Survivor

A Vampire Survivors–style bullet heaven where orbiting projectiles automatically destroy waves of enemies that grow faster and more numerous over time. Killing enemies drops XP gems; collecting enough triggers a level-up screen with three random upgrade choices. A large scrolling arena means enemies can spawn off-screen from any four edges.

## What It Demonstrates

- `luna.keyboard.isDown()` — eight-directional player movement with normalised diagonal speed
- `luna.graphics.circle()` — player, enemies, projectiles, XP gems, and death particles
- `luna.graphics.rectangle()` — health bar, XP bar, and upgrade-choice panels
- `luna.graphics.print()` — score, kill counter, timer, and upgrade option labels
- `luna.graphics.setBackgroundColor()` — dark space-themed background
- Camera follow — world-space entities are offset by `cam.x / cam.y` each draw frame
- Orbiting weapon system — projectile positions calculated from `player.angle` each update tick
- Upgrade system — stat table driven by a random pool draw, applied immediately to player stats

## How to Run

```powershell
cargo run -- demos/horde_survivor
```

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move player |
| 1 / 2 / 3 | Select upgrade when level-up screen appears |
| Escape | Quit |

## Notes

- Projectiles orbit at `player.orbit_r` radius; the `+10% Orbit` upgrade widens the ring
- `+1 Pierce` lets each projectile hit multiple enemies before "expiring" its hit count
- Enemy spawn rate ramps from 1.2 s down to a minimum of 0.15 s as `game_time` increases
- Enemy HP scales with `game_time / 30`, while XP gem value scales with `game_time / 60`
