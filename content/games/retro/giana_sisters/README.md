# Giana Sisters

**Category:** retro

A side-scrolling platformer inspired by the classic 1987 C-64 game *The Great Giana Sisters*. Run, jump, and stomp your way through three tile-based levels filled with gems, patrolling monsters, breakable blocks, and bouncing powerup stars.

## How to Play

| Action     | Keys                 |
| ---------- | -------------------- |
| Move left  | A / Left Arrow       |
| Move right | D / Right Arrow      |
| Jump       | Space / W / Up Arrow |
| Quit       | Escape               |

- Collect gems for points (+50 each)
- Stomp monsters from above to defeat them (+100) — side contact kills you
- Hit blocks from below to break them or reveal bouncing stars
- Grab a star for 5 seconds of invincibility
- Reach the green exit arch to complete the level
- 3 lives — lose them all and it's game over

## Features

- Three hand-crafted scrolling levels with increasing difficulty
- Horizontal camera tracking with smooth scroll factor
- Gem sparkle, monster stomp poof, block debris, and star trail particles
- Tween-animated gem counter and level-complete flash
- Title screen, level transitions, and game-over state

## Run

```bash
cargo run -- content/games/retro/giana_sisters
```
