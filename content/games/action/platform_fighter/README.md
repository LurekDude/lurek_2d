# Platform Fighter

Smash Bros-inspired 2-player local platform fighter with damage percentage, knockback scaling, stocks, and blast zones.

## Run

```
cargo run -- content/games/action/platform_fighter
```

## Controls

| Player 1 (Blue) | Action                   | Player 2 (Red) | Action                   |
| --------------- | ------------------------ | -------------- | ------------------------ |
| A / D           | Move left / right        | ← / →          | Move left / right        |
| W               | Jump (double jump)       | ↑              | Jump (double jump)       |
| F               | Normal attack (8%)       | K              | Normal attack (8%)       |
| G               | Special projectile (12%) | L              | Special projectile (12%) |
| Enter           | Start match              | Escape         | Quit                     |

## Gameplay

Two players fight on an arena with floating platforms. Each player starts with 3 stocks and 0% damage.

- **Damage percentage** — hits increase the opponent's damage %. Higher % means more knockback from every hit.
- **Knockback scaling** — at 0% a hit barely moves you; at 150%+ you fly across the screen.
- **Blast zones** — going off any edge of the screen costs a stock. The player respawns at center with 2 seconds of invulnerability (blinking).
- **Normal attack** (F / K) — quick melee hit, 8% damage, small knockback. Air version spikes downward.
- **Special attack** (G / L) — ranged projectile, 12% damage, medium knockback, 1-second cooldown.
- **Double jump** — each player can jump twice before needing to land.
- **Stocks** — 3 lives per player. Lose all stocks and the opponent wins.
- **Platforms** — main ground platform, two floating side platforms, one top center platform.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.timer, lurek.event, lurek.particle, lurek.tween, lurek.camera
