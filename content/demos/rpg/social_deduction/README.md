# Social Deduction

An Among Us-inspired game with AI crew members and one hidden traitor. The game alternates between a task phase (complete tasks before the timer expires) and a meeting phase (vote out the suspected traitor). AI players roam and complete tasks autonomously; the traitor AI uses sabotage to set back crew progress.

## What It Demonstrates

- AI roaming with random target selection and a movement timer for natural-feeling wandering
- Phase state machine: `"task"` → `"meeting"` driven by timers; meeting triggered at mid-point
- Task completion as a AABB proximity check: player must stand within range of a task marker to interact
- Traitor sabotage mechanic: periodic `sabotage_cooldown` drain reverses crew task progress
- Voting system: `meeting_votes` table tallied at meeting end; most votes eliminates a player
- Vision radius: crew draw only players within `VISION_RADIUS = 180` px to simulate limited line of sight
- Two win conditions checked every frame: all tasks complete (crew wins) or crew majority eliminated (traitor wins)

## How to Run

```powershell
cargo run -- content/demos/social_deduction
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `W` `A` `S` `D` | Move your crewmate |
| Left Click task marker | Complete task (task phase) |
| Left Click player name | Cast vote (meeting phase) |
| `Escape` | Quit |

## Notes

- You are always Player 1 (blue). The traitor is one of the five AI players, randomly assigned each run.
- Task phase lasts 30 seconds; meeting phase lasts 20 seconds.
- AI players vote for random living suspects; you can swing the outcome with your vote.
