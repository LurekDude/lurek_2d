# Party Games

A three-minigame party collection with a persistent score. Play through Quick Draw (reaction timing), Memory Match (card pairs), and Dodge Ball (obstacle avoidance) in sequence. Each minigame contributes to a running total displayed on the final scores screen.

## What It Demonstrates

- Multi-state game loop: a single `state` string drives four distinct update/draw branches (`menu`, `quickdraw`, `memory`, `dodge`)
- Reaction-time measurement using `luna.time.getTime()` with a random delay before the signal
- Card-grid shuffle (Fisher-Yates) and flip-pair matching with a reveal-then-check timer
- Procedural ball spawning with delta-time acceleration for the dodge game
- Score accumulation across independent minigames into a shared `totalScore`
- `luna.keyboard.isDown()` and `luna.mouse.getPosition()` used in different minigames

## How to Run

```powershell
cargo run -- demos/party_games
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `M` | Return to minigame menu |
| **Quick Draw**: `Space` | Shoot when the GO signal appears |
| **Memory Match**: Click card | Flip a card |
| **Dodge Ball**: Arrow Left / Right | Move the paddle left or right |

## Notes

- Pressing `Space` before the GO signal in Quick Draw counts as a false start and gives zero points.
- Memory Match score is `200 − (moves × 5)`, so efficiency matters more than speed.
- Dodge Ball ends after 30 seconds; score equals the number of balls dodged.
