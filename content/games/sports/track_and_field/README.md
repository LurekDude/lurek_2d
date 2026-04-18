# Track & Field

**Category:** sports

Olympic-style track and field athletics game with five events played in sequence: 100m Sprint, Long Jump, Javelin Throw, High Jump, and 110m Hurdles. Compete for Gold, Silver, and Bronze medals in each event and aim for the best total medal tally.

## Run

```
cargo run -- content/games/sports/track_and_field
```

## Controls

| Key    | Action                                       |
| ------ | -------------------------------------------- |
| A / D  | Alternate mash to build running speed        |
| Space  | Jump / throw / set angle (context-sensitive) |
| Escape | Quit                                         |

## Events

1. **100m Sprint** — Mash A/D alternately to run. Race against 3 AI runners. First to cross the line wins.
2. **Long Jump** — Sprint approach, press Space at the board to jump. 3 attempts, best distance counts.
3. **Javelin Throw** — Sprint, press Space to set throw angle (0–45°), press Space again to release. Wind affects trajectory. 3 attempts.
4. **High Jump** — Approach from the side, press Space to jump near the bar. Clear the bar to raise it 5 cm. Three consecutive failures at a height ends the event.
5. **110m Hurdles** — Sprint and time Space presses to clear 10 hurdles. Hitting a hurdle adds a 0.5s penalty.

## Scoring

- Gold (1st), Silver (2nd), Bronze (3rd) medals per event
- Qualifying standards give bonus points
- Stamina carries between events; resting between events recovers some
- Final medal tally shown after all five events
