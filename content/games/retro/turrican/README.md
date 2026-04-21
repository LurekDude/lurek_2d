# Turrican

Run-and-gun platformer inspired by Manfred Trenz's legendary 1990 C-64/Amiga classic, featuring a dual weapon system and tile-based levels.

## Run

```
cargo run -- content/games/retro/turrican
```

## Controls

| Key       | Action                     |
| --------- | -------------------------- |
| A / D     | Move left / right          |
| Space / W | Jump                       |
| F         | Shoot (normal or spread)   |
| G (hold)  | Energy beam (sweeping arc) |
| Escape    | Quit                       |

## Gameplay

Navigate three tile-based levels as an armored soldier armed with two weapons: a rapid-fire shot (upgraded to a three-way spread via powerups) and a continuous energy beam that sweeps in an arc and drains ammo. Defeat walkers, flyers, and turrets to rack up points while collecting powerups for health, ammo, and the spread shot upgrade. Reach the exit tile at the end of each level to advance. Five hit points, 100 ammo — manage both to survive the gauntlet.

### Enemy Types
- **Walker** — patrols platforms, 1 HP
- **Flyer** — hovers in sine pattern, chases player, 2 HP
- **Turret** — stationary, fires aimed shots at the player, 3 HP

### Powerups
- **Spread Shot** (red diamond) — upgrades normal shot to 3-way spread
- **Health** (green diamond) — restores 2 HP
- **Ammo** (blue diamond) — restores 25 ammo

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `isActionDown` / `wasActionPressed`)

### Added
- Title screen, game over screen, level complete transitions
- Particle effects (bullet impacts, enemy explosions, beam sparks, powerup glow)
- Tween animations (weapon switch flash, level complete banner slide)
- `render` / `render_ui` split with HUD overlay (HP bar, ammo bar, weapon indicator, score, level, FPS)
- Camera horizontal follow
- 3 distinct level layouts with increasing difficulty

### Removed
- Nothing
