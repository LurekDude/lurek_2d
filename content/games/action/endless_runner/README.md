# Endless Runner

Auto-scrolling side-view runner — dodge tall barriers, slide under low beams, leap across gaps, and collect coins while the world accelerates.

## Run

```
cargo run -- content/games/action/endless_runner
```

## Controls

| Key            | Action                        |
| -------------- | ----------------------------- |
| Space / W / Up | Jump (double jump after 500m) |
| S / Down       | Slide                         |
| Enter          | Start / Restart               |
| Escape         | Quit                          |

## Gameplay

The player sprints rightward automatically at increasing speed (300 → 600). Three obstacle types force different reactions: tall barriers require jumping, low barriers require sliding, and gaps require leaping across. Golden coins float in the air near obstacles — each one adds +50 to the score.

After reaching 500 meters, a double jump unlocks, letting the player chain two jumps for harder sequences. Speed increases by 20 every 500m, capping at 600. Score combines distance (meters) plus coin bonuses. High score persists across attempts within the session.

Three parallax background layers (mountains, trees, ground detail) scroll at different rates for depth. Landing produces dust particles, coin pickups trigger golden sparkles, and death plays a tumbling poof.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.time, lurek.signal, lurek.particles, lurek.tween

## Notes

- Double jump is intentionally gated at 500m to create a difficulty curve shift
- Gap obstacles use centre-of-player detection so grazing the edge is forgiving
- The death animation rotates and drops the player off-screen before switching to the DEAD state
- Parallax scrolls gently even on the title screen for visual appeal
