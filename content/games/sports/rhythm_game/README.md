# Rhythm Game

**Category:** Sports  
**Complexity:** Advanced  
**Engine features:** Input Bindings, Particles, Tween, Camera, State Machine, Render/UI Split

## Description

A 4-lane rhythm game where colored notes scroll down and must be hit in time with the music. Features three difficulty levels with pre-built note charts, hold notes, a combo multiplier system, life bar, and letter grades. Visual feedback includes lane glow, hit flash particles, and pulsing background colors.

## How to Play

| Key     | Action               |
| ------- | -------------------- |
| D       | Lane 1 (red)         |
| F       | Lane 2 (blue)        |
| J       | Lane 3 (green)       |
| K       | Lane 4 (yellow)      |
| Enter   | Confirm selection    |
| Up/Down | Navigate song select |
| Escape  | Quit / Back          |

## Running

```bash
cargo run -- content/games/sports/rhythm_game
```

## Features

- 4 input lanes with colored note tracks
- 3 pre-built songs: Easy Beat (60 notes), Medium Groove (100 notes), Hard Rush (150 notes)
- Timing windows: Perfect (±30ms, 300pts), Good (±60ms, 100pts), Miss (0pts)
- Hold notes: sustain key from head to tail for bonus points
- Combo system: 10+ = 2x, 25+ = 3x, 50+ = 4x multiplier
- Life bar: 100% start, -10% on miss, +2% on perfect, fail at 0%
- Letter grades: S/A/B/C/F based on score percentage
- Particle bursts on hits (gold/green/red by timing)
- Pulsing background and lane glow effects
- Tween-animated score counter, life bar, and hit zone pulse
