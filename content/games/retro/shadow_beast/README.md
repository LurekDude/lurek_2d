# Shadow of the Beast

Atmospheric side-scrolling action game inspired by Psygnosis' 1989 Amiga masterpiece. Battle through a dark, beautiful world with 5-layer parallax scrolling, a haunting purple/blue palette, and relentless combat against creatures of the night.

## Run
```
cargo run -- content/games/retro/shadow_beast
```

## Controls
| Key       | Action               |
| --------- | -------------------- |
| A / D     | Move left / right    |
| Space / W | Jump                 |
| F         | Melee attack (punch) |
| Enter     | Start / Restart      |
| Escape    | Quit                 |

## Gameplay
- Side-scrolling action with 5-layer parallax backgrounds (sky, far mountains, mid trees, near hills, ground)
- Atmospheric dark purple/blue color palette with a large glowing moon
- Melee combat with 60px forward punch and 0.3s cooldown
- Three enemy types: ground walkers, flying swoopers, and stationary spike traps
- Player has 5 HP displayed as health icons
- Distance-based scoring with kill bonuses
- Speed increases over time — enemies spawn faster as you progress
- Boss encounter every 3000 distance: large multi-hit enemy
- Particle effects for attack sparks, enemy death bursts, jump dust, and floating atmosphere motes
- Hit damage flash and death fade-to-black via tween system

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.event, lurek.timer, lurek.particle, lurek.tween, lurek.camera
