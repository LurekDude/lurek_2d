# Horde Survivor

Vampire Survivors-style top-down horde survival — auto-attack with orbiting projectiles while dodging waves of enemies.

## Run

```
cargo run -- content/games/action/horde_survivor
```

## Controls

| Key       | Action                   |
| --------- | ------------------------ |
| W         | Move up                  |
| A         | Move left                |
| S         | Move down                |
| D         | Move right               |
| 1 / 2 / 3 | Pick upgrade on level up |
| Escape    | Quit                     |

## Gameplay

Move through a large arena while orbiting projectiles auto-attack enemies. Enemies spawn at the screen edges and walk toward you — contact deals damage.

Killed enemies drop XP gems that auto-collect when you walk near them. Fill the XP bar to level up and choose from 3 random upgrades:

- **+2 Projectiles** — more orbiting shots
- **+20% Speed** — faster movement
- **+3 Damage** — harder hits
- **+15px Orbit Radius** — wider attack circle
- **+1 Pierce** — projectiles pass through extra enemies

Four enemy types appear with increasing spawn rates:

- **Walker** — 1 HP, slow
- **Runner** — 2 HP, fast
- **Tank** — 5 HP, slow but large
- **Exploder** — 3 HP, explodes on death hurting nearby enemies and the player

Survive as long as possible. Game over when HP reaches 0 — final stats show kills, time survived, and level reached.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.timer, lurek.event, lurek.particle, lurek.tween, lurek.camera
