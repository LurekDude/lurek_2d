# Sports Manager

A data-driven football management simulation. Build and train an 11-player roster, set your formation, negotiate transfers, and simulate a 10-match season. Match outcomes are calculated from team stat averages — no real-time gameplay involved.

## What It Demonstrates

- Multi-screen navigation driven by a single `state` string with six distinct views
- Procedural player generation: random first/last names from word-list arrays, four stats from a `rand_stat()` distribution
- `team_overall()` function aggregating squad stats while skipping injured players
- Match simulation: randomised scoreline weighted by the ratio of `team_overall(player_team) / team_overall(opponent)`
- Transfer market: `transfer_list` pool generated at season start, `budget` deducted on purchase
- Training system: `+rand_stat()` applied to chosen player stat, capped at 99
- League table sorted by points with goal-difference tiebreak

## How to Run

```powershell
cargo run -- demos/sports_manager
```

## Controls

| Key | Action |
|-----|--------|
| Arrow Up / Down | Navigate menu or list |
| `Enter` | Confirm selection |
| `Tab` | Cycle secondary options (formations) |
| `M` | Return to main menu |
| `Escape` | Quit |

## Notes

- Injured players are excluded from `team_overall()` — field a full squad for best results.
- Transfers cost budget and add the purchased player directly to your roster.
- The season ends after 10 matches; results are shown on the season-end screen.
