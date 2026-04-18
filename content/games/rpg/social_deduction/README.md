# Social Deduction

**Category:** RPG
**Engine:** Lurek2D

## Description

An Among Us-style social deduction game set on a spaceship. Six crew members must complete tasks to keep the ship running — but one of them is a traitor sabotaging the mission from within.

## Gameplay

- **6 players** on a top-down spaceship map (1 player-controlled + 5 AI crew members)
- **Traitor mechanic**: one player is randomly assigned as the traitor (1/6 chance it's you)
- **Task system**: 8 tasks scattered around the map — walk to a task location, press E, and hold for 2 seconds to complete
- **Vision radius**: limited 180px sight range — you can only see nearby areas
- **Emergency meetings**: press M to call a meeting — discuss and vote to eliminate the suspected traitor
- **Voting**: press 1–6 to vote for a player; majority vote eliminates that player, ties result in no elimination
- **Sabotage**: the traitor occasionally triggers sabotage events (e.g., lights out = reduced vision)
- **Win conditions**:
  - **Crew wins** if all 8 tasks are completed
  - **Traitor wins** if enough crew members are eliminated

## Controls

| Key     | Action                                            |
| ------- | ------------------------------------------------- |
| W/A/S/D | Move                                              |
| E       | Interact / Complete task / Eliminate (if traitor) |
| M       | Call emergency meeting                            |
| 1–6     | Vote for player during meeting                    |
| Escape  | Quit                                              |

## Running

```
cargo run -- content/games/rpg/social_deduction
```
