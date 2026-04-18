# Signal Demo

Complete pub-sub event signal system showcase demonstrating the publisher-subscriber pattern with five distinct signal types, cascading chain reactions, and real-time subscriber/event log visualization.

## Run

```
cargo run -- content/games/showcase/signal_demo
```

## Controls

| Key    | Action                      |
| ------ | --------------------------- |
| A      | Fire "player_hit" signal    |
| S      | Fire "score_up" signal      |
| D      | Fire "level_up" signal      |
| F      | Fire "combo_reached" signal |
| Escape | Quit                        |

## Gameplay

Fire signals with keyboard keys and watch the pub-sub system react in real time. Each signal type has multiple subscribers that produce unique visual feedback — health bar decreases, floating score text, background color shifts, particle bursts, and screen flashes. A combo counter increments on score events; reaching 5 triggers "combo_reached" which cascades into a bonus "score_up" — demonstrating chain reactions. When health reaches zero, "game_over" fires automatically, transitioning to the end screen.

### Signal Types
- **player_hit** — decreases health, triggers screen flash, resets combo
- **score_up** — updates score display, spawns floating "+10" text, increments combo
- **level_up** — changes background color, emits particle burst, increases game speed
- **combo_reached** — awards bonus score, triggers special effect, auto-fires "score_up"
- **game_over** — shows death animation, displays final stats, transitions to end screen

### Panels
- **Right panel** — lists all active subscribers per signal with colored status dots
- **Bottom panel** — scrolling event log showing last 15 fired events with timestamps
- **Top-left** — stats: signals fired, subscriber count, chain reaction count

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.time`, `lurek.signal`
