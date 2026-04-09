# Bridge Builder Demo

A structural engineering puzzle. Place connection nodes across a gap, link them with Wood or Steel beams within a budget, then test with a vehicle that crosses the bridge. Beams turn red under stress and can break.

## What It Demonstrates

- Two-mode architecture: `build` phase (mouse-driven node/beam placement) and `test` phase (simulated crossing)
- `luna.physics` — vehicle body rolling across beams during the test phase
- Budget constraint system: each beam deducts from a gold budget based on material and length
- Stress simulation: per-beam stress computed from deflection and load, visualised as colour lerp from white → red
- `luna.mouse.getPosition()` and `luna.mousepressed` for node snapping and beam creation
- Combo detection: click node → click second node → beam auto-placed with duplicate guard
- `luna.gfx.line()` for beam drawing with stress-driven colour tinting

## How to Run

```powershell
cargo run -- demos/bridge_builder
```

## Controls

| Input | Action |
|-------|--------|
| Left click empty space | Place node |
| Left click node then another | Connect with beam |
| 1 | Select Wood material (cheaper, weaker) |
| 2 | Select Steel material (expensive, strong) |
| T | Start test |
| R | Reset bridge |
| Escape | Quit |

## Notes

- Anchor nodes (four cliff corners) are pre-placed and cannot be moved.
- Wood has max stress 1.0; Steel 2.5. Beams exceeding their limit break.
- Budget starts at 500. Wood beams cost 15/unit, Steel 30/unit × length.
