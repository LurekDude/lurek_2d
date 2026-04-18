# Cannon Fodder

**Category:** Retro
**Engine:** Lurek2D

A squad-based top-down shooter inspired by Sensible Software's 1993 Amiga classic. Command a squad of soldiers through increasingly dangerous jungle missions.

## How to Play

- **WASD** — Set squad movement direction
- **Space** — All living soldiers fire toward facing direction
- **G** — Throw grenade (3 per mission, 60px blast radius)
- **Escape** — Quit

## Features

- **Squad mechanics**: Control 1–3 soldiers moving as a group toward the target direction
- **Permanent death**: Soldiers killed in a mission stay dead — fewer soldiers means harder fights
- **5 missions**: Escalating enemy counts (6 → 10 → 14 → 18 → 22) — eliminate all enemies and reach the flag
- **Grenades**: Limited supply, area damage — tactical crowd control
- **Scrolling battlefield**: Vertical jungle map with trees as obstacles
- **Particles**: Bullet impacts, explosion fireballs, leaf scatter, blood effects
- **Scoring**: +100 per enemy kill, +50 per grenade kill, +500 per mission complete

## Running

```
cargo run -- content/games/retro/cannon_fodder
```
