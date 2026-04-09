# Platform Fighter

A two-player Smash Bros-style arena fighter with damage percentage, knockback scaling, stocks, and blast zones. Both players share the same keyboard: Player 1 uses WASD and Player 2 uses Arrow Keys. Knockback grows with accumulated damage — a light punch at 150% damage launches your opponent much farther than the same punch at 10%.

## What It Demonstrates

- Percentage-based knockback: `knockback = (base + damage * scale) * direction`
- Dual-player input with separate key maps stored per player object: `player.keys.left`, `.punch`, etc.
- Platform pass-through: players standing on a platform only collide from above (downward velocity check)
- Blast zone detection on all four edges triggers stock loss and respawn with invincibility frames
- Two attack types (punch vs smash) with different damage, knockback, and animation durations
- Hitstun window that prevents the victim from acting immediately after being hit

## How to Run

```powershell
cargo run -- content/demos/platform_fighter
```

## Controls

| Key | Player 1 | Player 2 |
|-----|----------|----------|
| Move | `W` `A` `S` `D` | Arrow keys |
| Jump | `W` | Up Arrow |
| Punch | `F` | `K` |
| Smash | `G` | `L` |
| Rematch | `R` (either player) | `R` |

## Notes

- You have 3 stocks each — last player with stocks remaining wins.
- Double-jump is available on all characters.
- High damage percentages make even a punch dangerous — play defensively at high percentage.
