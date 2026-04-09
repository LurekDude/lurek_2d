# Medical Simulation

A surgical workflow minigame where the player operates on a series of five patients. Each surgery follows a strict six-step sequence — clean, cut skin, cut muscle, repair the organ, suture, and clean again. Apply the wrong tool at the wrong step and the patient suffers a complication that reduces your final score per case.

## What It Demonstrates

- Strict state-machine step progression: a `step` counter gates which tools have any effect
- Vitals system: `heart_rate` and `blood_pressure` degrade over time, pressuring the player to work quickly
- Click-region validation distinguishing the tool palette from the body area and the target zone
- Multi-patient progression: completing one patient advances to the next automatically
- Penalty / bonus scoring: score per patient is `200 − (complications × 30)`, floored at 50
- `luna.gfx.drawCircle` and `drawRect` for all UI and body rendering

## How to Run

```powershell
cargo run -- demos/medical_sim
```

## Controls

| Input | Action |
|-------|--------|
| Click tool palette | Select active tool |
| Click patient area | Apply selected tool |
| Click target zone (red) | Use forceps to repair organ (step 4 only) |

## Notes

- The correct tool order is: **antiseptic → scalpel → scalpel → forceps → sutures → antiseptic**.
- The sponge stabilises a patient whose heart rate has dropped below 70 bpm.
- Vitals decline over the full session, not per patient — slow players face deteriorating conditions on later cases.
