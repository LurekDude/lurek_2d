# Roguelite

Hades-style top-down action roguelite — fight through room-based dungeons, collect perks, and face bosses every five rooms.

## Run

```
cargo run -- content/games/action/roguelite
```

## Controls

| Key             | Action              |
| --------------- | ------------------- |
| W / ↑           | Move up             |
| A / ←           | Move left           |
| S / ↓           | Move down           |
| D / →           | Move right          |
| Left Click / J  | Melee slash         |
| Right Click / K | Ranged projectile   |
| Shift           | Dash (invulnerable) |
| 1 / 2 / 3       | Select perk         |
| R               | Restart (game over) |
| Escape          | Quit                |

## Gameplay

Navigate arena rooms and defeat all enemies using melee slashes, ranged projectiles, and a dodge dash. Each room spawns waves of enemies in three types:

- **Melee** — walks directly toward the player and deals contact damage.
- **Ranged** — keeps its distance and fires projectiles at the player.
- **Charger** — winds up briefly then dashes at high speed for heavy damage.

After clearing a room, a door opens and a perk selection screen appears with three random upgrades: increased attack damage, faster movement, HP healing, extra max HP, reduced cooldowns, or a wider melee arc.

Every 5 rooms a **boss** spawns — a larger enemy with multi-phase attack patterns and more health.

The player starts with 5 HP and brief invincibility frames after taking damage. Score is earned from kills and rooms cleared. On death, a full run summary shows rooms cleared, enemies killed, and perks collected.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.time, lurek.signal, lurek.particles, lurek.tween, lurek.camera
