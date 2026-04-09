# Soulslike Precision Combat

A 1v1 boss duel with a stamina resource that governs every action. Light attacks, heavy attacks, dodges, and blocks all cost stamina; running dry leaves you vulnerable. The boss telegraphs attacks before striking and enters a more aggressive phase 2 at 50% HP.

## What It Demonstrates

- Stamina resource shared across attack, dodge, and block actions — all gated by the same pool
- Invincibility frames on dodge: `player.dodging` and `player.iframe` combined block hit detection
- Boss three-phase AI state machine: `"idle"` → `"telegraph"` → `"attack"` → `"recovery"`
- Attack hitbox as a conditional range check in the attack timer window (active frames)
- Screen shake on heavy hits: `shake` table accumulates magnitude and decays over time
- Phase 2 trigger: boss detects `hp <= max_hp / 2` and increases speed and adds new attack patterns
- Particle burst on hit using angle-spread velocity integration

## How to Run

```powershell
cargo run -- demos/soulslike
```

## Controls

| Key | Action | Stamina cost |
|-----|--------|-------------|
| `A` / `D` | Move left / right | — |
| `J` | Light attack | 12 |
| `K` | Heavy attack | 25 |
| `L` | Dodge (i-frames) | 20 |
| `Space` | Block (hold) | 20/sec |
| `R` | Restart after death/victory | — |

## Notes

- Stamina regenerates at 30 per second; avoid spamming or you will get hit while exhausted.
- The boss telegraphs attacks with a red flash before striking — dodge into the attack to punish.
- Phase 2 begins when the boss reaches 150 HP (half); attack patterns become faster and unpredictable.
