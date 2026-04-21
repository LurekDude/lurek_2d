# Soulslike

Precision boss fight with stamina management, dodge i-frames, estus heals, and a 3-phase boss AI.

## Run

```
cargo run -- content/games/action/soulslike
```

## Controls

| Key           | Action                            |
| ------------- | --------------------------------- |
| W / A / S / D | Move                              |
| J             | Light attack (12 dmg, 15 stamina) |
| K             | Heavy attack (25 dmg, 30 stamina) |
| L             | Dodge roll (i-frames, 20 stamina) |
| Space (hold)  | Block (75% damage reduction)      |
| E             | Estus heal (+30 HP, 3 uses)       |
| Enter         | Start / Restart                   |
| Escape        | Quit                              |

## Gameplay

Fight a three-phase boss in a stone-walled arena. Every action costs stamina — running out leaves you exhausted and vulnerable for a full second.

- **Stamina system** — 100 max, regenerates at 30/s when idle. Attacks, blocking, and dodging all consume stamina. Depletion triggers a 1-second exhaustion lockout.
- **Dodge roll** — 0.3 s invincibility window; moves 100 px in your facing direction.
- **Block** — hold Space to reduce incoming damage by 75 %, at the cost of stamina per hit absorbed.
- **Boss phases** — Phase 1 (100–66 % HP): slow 2-hit melee combos. Phase 2 (66–33 %): adds dash attack and ground slam AoE. Phase 3 (33–0 %): enraged red glow, projectile barrage, 3–4 hit combos.
- **Estus heals** — 3 charges per attempt, each restoring 30 HP with a 1-second animation lock.
- **Hitlag** — brief 0.05 s freeze on hit confirms for impact feel.
- **Death** — slow-motion "YOU DIED" fade-to-black with restart prompt.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.timer, lurek.event, lurek.particle, lurek.tween, lurek.camera
