# Sensible Soccer

**Category:** Retro
**Engine:** Lurek2D

A fast-paced top-down football game inspired by Sensible Software's legendary 1992 Amiga classic. Control a team of 5 green players against a CPU-controlled red team in quick 3-minute matches with automatic player switching, ball physics, and half-time side swaps.

## How to Play

- **WASD** — Move the controlled player
- **Space** — Kick ball toward facing direction (power shot)
- **F** — Pass to nearest teammate
- **T** — Slide tackle toward the ball
- **Escape** — Quit

## Features

- **Automatic player switching**: You always control the teammate nearest to the ball
- **Ball physics**: Realistic friction (0.88/frame), boundary bouncing, kick power system
- **CPU AI**: Nearest CPU player chases the ball, remaining players hold formation
- **Slide tackling**: Lunge toward the ball with T — risk vs. reward
- **Half-time**: Teams swap sides at 90 seconds; match ends at 180 seconds
- **Alternating kickoff**: Scoring team concedes kickoff to the opponent
- **Particles**: Kick dust, goal celebration bursts, tackle slide dust, ball trail
- **Tween animations**: Goal text zoom-in, half-time transition effects
- **Full pitch markings**: Center circle, halfway line, penalty boxes, goals

## Running

```
cargo run -- content/games/retro/sensible_soccer
```
