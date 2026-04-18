# Party Games

4 mini-game party collection for 2 players: Reaction, Memory, Typing Race, and Math Duel.

## Run
```
cargo run -- content/games/strategy/party_games
```

## Controls
| Key | Action |
|-----|--------|
| Space | Start game / Continue |
| Z | P1 Reaction buzzer |
| Shift | P2 Reaction buzzer |
| 1–4 | P1 Memory input |
| Letter keys | P1 Typing |
| 0–9 | P1 Math answer |
| Escape | Quit |

## Gameplay
3 rounds of 4 mini-games. Reaction: press your buzzer when the signal turns green. Memory: repeat a growing color sequence. Typing Race: type the word first. Math Duel: type the answer to the equation first.

## APIs Used
- `lurek.render` / `lurek.render_ui` — all game screens, overlays
- `lurek.particles` — celebration burst, flash overlay
- `lurek.input` — action bindings for all player controls
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- Single hardcoded mini-game → 4 rotating mini-games across 3 rounds
- Hand-drawn rect flash → `lurek.particles` celebration burst
- Hardcoded key polling → `lurek.input` action bindings

### Added
- Scoreboard screen with winner announcement
- Per-mini-game flash overlay feedback
- Round counter

### Removed
- Nothing from original gameplay

### Open questions
- Sound effects per mini-game event
