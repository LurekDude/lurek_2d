# Bridge Builder

**Category:** strategy

_Engineer bridges across canyons — place beams, manage budgets, and stress-test your designs with heavy vehicles._

## Run

```powershell
cargo run -- content/games/strategy/bridge_builder
```

## Controls

| Input       | Action                         |
| ----------- | ------------------------------ |
| R           | Select Road beam type          |
| S           | Select Steel beam type         |
| C           | Select Cable beam type         |
| T           | Enter test mode (send vehicle) |
| Z           | Undo last beam                 |
| D + Click   | Delete a beam                  |
| Mouse click | Place node / connect nodes     |
| Escape      | Quit                           |

## Gameplay

Side-view canyon crossing puzzle. Two cliffs frame a gap — place nodes in the open space and connect them with beams to build a bridge. Three beam types available:

- **Road** (R, 10g) — vehicles drive on these, horizontal only, gray
- **Steel** (S, 15g) — structural support at any angle, blue
- **Cable** (C, 5g) — tension-only, cannot support compression, light blue

Press T to test: a vehicle drives across from left to right. Beams change color from green to yellow to red as stress increases. If stress exceeds the limit the beam snaps and the bridge collapses. Vehicle reaching the far cliff = success; falling in the river = fail.

8 levels with increasing gap distance and tighter budgets. Level 5+ introduces a heavy truck. Score = remaining budget + structural efficiency bonus.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.window` — sets the window title
- `lurek.render` — canyon terrain, beams, nodes, vehicle, river
- `lurek.input` — action-based key and mouse bindings
- `lurek.timer` — delta time for simulation and animation
- `lurek.camera` — world-space camera for the canyon view
- `lurek.event` — quit handling
- `lurek.particle` — construction sparks, beam break debris, vehicle splash, success confetti
- `lurek.tween` — stress color transitions, vehicle crossing progress, score counter animation
