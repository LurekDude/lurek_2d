# Sensible Soccer

A fast-paced top-down football game inspired by Sensible Software's beloved 1992
Amiga classic. Score more goals than the CPU in 3 minutes to win.

## What It Demonstrates

- `luna.graphics.circle()` / `luna.graphics.rectangle()` — pitch markings, players, ball
- `luna.input.isKeyDown()` — smooth player movement
- `luna.keypressed()` — kicking, tackling, player switching
- Multi-agent CPU AI (chase ball, attack, support)
- Basic ball physics with friction and pitch bounce

## Controls

| Key | Action |
|-----|--------|
| WASD or Arrow Keys | Move selected player |
| Space | Kick toward goal / Tackle |
| Tab | Switch to player nearest the ball |
| R | Restart |
| Escape | Quit |

## Notes

The selected player (yellow highlight) is the one you control. Press **Tab** to quickly
switch to the player closest to the ball. Win by scoring more goals in 3 minutes.
The CPU will try to defend and counter-attack.
