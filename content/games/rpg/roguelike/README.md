# Roguelike

**Category**: rpg
**Engine**: Lurek2D

## Description

A classic turn-based grid roguelike with procedurally generated dungeons, fog of war, bump combat, and permadeath. Descend through increasingly dangerous floors, fight enemies, collect potions and weapon upgrades, and see how far you can survive.

## Features

- **Turn-based movement** — Arrow keys or WASD, one tile per keypress
- **Procedural dungeons** — Random rooms and corridors generated each floor
- **Fog of war** — 5-cell visibility radius; explored tiles shown dimmer
- **Bump combat** — Walk into enemies to attack; damage = ATK minus DEF
- **Enemy types** — Rats, Goblins, and Orcs with scaling difficulty per floor
- **Pickups** — Health potions (+15 HP) and weapon upgrades (+2 ATK)
- **Permadeath** — Death ends the run; final stats displayed (floors, kills, turns)
- **Leveling** — Every 5 kills grants +2 HP and +1 ATK
- **Particles & tweens** — Death poofs, pickup glow, HP bar drain, damage popups
- **Message log** — Last 5 combat messages displayed at screen bottom

## Controls

| Key               | Action                      |
| ----------------- | --------------------------- |
| Arrow keys / WASD | Move                        |
| Enter             | Start game / Descend stairs |
| Escape            | Quit                        |

## How to Run

```bash
cargo run -- content/games/rpg/roguelike
```
