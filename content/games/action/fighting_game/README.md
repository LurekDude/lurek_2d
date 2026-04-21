# Fighting Game

1v1 fighting game with Player vs AI — land combos, build super meter, and win best of 3 rounds.

## Run

```
cargo run -- content/games/action/fighting_game
```

## Controls

| Key    | Action                         |
| ------ | ------------------------------ |
| A / D  | Move left / right              |
| W      | Jump                           |
| F      | Punch (fast, 8 dmg)            |
| G      | Kick (slow, 15 dmg)            |
| H      | Block                          |
| Q      | Super attack (when meter full) |
| Enter  | Start / next round             |
| Escape | Quit                           |

## Gameplay

Two fighters face off on a flat stage. Player 1 (blue) fights an AI opponent (red) in a best-of-3-rounds match. Each fighter starts with 100 HP per round.

- **Combo system** — landing hits within a 0.5 s window chains a combo counter that adds bonus damage per successive hit.
- **Super meter** — builds on hit (+5) and block (+3). When the meter reaches 100, press Q to unleash a 30-damage super attack with knockback.
- **AI behaviour** — the AI approaches when far, attacks when close, and blocks randomly, providing a simple but reactive sparring partner.
- **Hit stun** — successful attacks grant advantage frames; the defender is briefly stunned.
- **Round flow** — after a KO, the round score updates and the next round begins after a short delay with a "ROUND X" announcement. The match ends with "PLAYER WINS" or "AI WINS" after 2 round victories.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.timer, lurek.event, lurek.particle, lurek.tween, lurek.camera
