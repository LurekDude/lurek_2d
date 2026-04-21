# Bullet Hell

Dodge intricate bullet patterns, graze for bonus points, and bomb your way through relentless waves.

## Run
```
cargo run -- content/games/action/bullet_hell
```

## Controls
| Key     | Action                                |
| ------- | ------------------------------------- |
| W/A/S/D | Move ship                             |
| Space   | Fire                                  |
| Shift   | Focus (slow movement, visible hitbox) |
| X       | Bomb (clears all bullets)             |
| Enter   | Start / Restart                       |
| Escape  | Quit                                  |

## Gameplay
- Player ship with a tiny 2px hitbox for precision dodging
- Graze mechanic: bullets passing within 20px of your hitbox award bonus points and increase your score multiplier
- 3 lives, 3 bombs per life — bombs clear all enemy bullets on screen
- Enemy types: small (aimed shots), medium (spiral patterns), large (radial bursts)
- Mini-boss every 5 waves with multiple bullet emitters
- Curtain patterns create walls of bullets with gaps to weave through
- Score multiplier increases with grazes, resets on death

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.event, lurek.timer, lurek.particle, lurek.tween, lurek.camera
