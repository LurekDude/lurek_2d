# Vehicle Builder

Grid-based vehicle construction and physics-driven test track game. Design vehicles from modular parts on a snap-to-grid editor, then switch to a side-scrolling test mode to see how far your creation can go.

## Run

```
cargo run -- content/games/simulation/vehicle_builder
```

## Controls

| Key              | Action                       |
| ---------------- | ---------------------------- |
| F                | Select Frame part            |
| W                | Select Wheel part            |
| E                | Select Engine part           |
| A                | Select Armor part            |
| B (build mode)   | Select Booster part          |
| D + Click        | Delete part                  |
| Left Click       | Place selected part          |
| T                | Switch to Test mode          |
| B (test/results) | Return to Build mode         |
| Space            | Activate booster during test |
| Escape           | Quit                         |

## Gameplay

Build vehicles on a 20×12 grid (32 px cells) using five part types, each with a gold cost against a 300g budget:

- **Frame** (free) — basic structural block, foundation for everything else
- **Wheel** (20g) — placed at the bottom, each wheel adds grip and ground contact
- **Engine** (50g) — powers wheels; each engine provides 100 base speed
- **Armor** (30g) — heavy protection block, absorbs one obstacle hit before breaking
- **Booster** (40g) — press Space during a test run for a 3-second burst at 2× speed

Parts must connect to at least one existing part. Vehicle stats (speed, weight, armor, engine power) update live in the HUD.

### Test Mode

Press T to launch the vehicle onto a side-scrolling test track. The camera follows the vehicle as it drives right at a speed determined by the engine-power-to-weight ratio. Three tracks of increasing difficulty feature ramps, gaps, and walls. Hitting a wall damages the vehicle (armor absorbs hits), falling into a gap ends the run. Score is based on distance traveled. After the run, review results and press B to return to the editor for modifications.

### Particles & Effects

Engine exhaust, booster flames, crash debris, and wheel dust provide visual feedback throughout the test run.
