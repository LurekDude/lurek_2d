# Medical Sim

Hospital management simulation — triage patients, assign staff, upgrade departments, and maintain a 4+ star rating.

## Run

```
cargo run -- content/games/simulation/medical_sim
```

## Controls

| Key         | Action                                                                         |
| ----------- | ------------------------------------------------------------------------------ |
| Mouse Click | Select patient / doctor                                                        |
| 1–4         | Assign selected patient or doctor to department (ER / General / Surgery / ICU) |
| H           | Hire a new doctor (100g)                                                       |
| E           | Buy equipment upgrade for selected department (200g)                           |
| Escape      | Quit                                                                           |

## Gameplay

Patients arrive every few seconds with random conditions ranging from a common cold to a heart attack. Each condition maps to a department (ER, General, Surgery, ICU) and has a specific treatment duration. Click a patient in the waiting area and press 1–4 to assign them to a department. If a doctor is free in that department, treatment begins automatically. Placing a patient in the wrong department doubles the treatment time.

Hire additional doctors (H) and assign them to departments to increase throughput. Purchase equipment upgrades (E) to reduce treatment time by 20 % per department.

Patient satisfaction depends on wait time — patients who wait longer than 60 seconds leave, dropping your star rating. Treat 50 patients while maintaining a 4+ star rating to win.

### Departments
- **ER** (red) — emergencies, fastest treatment needed
- **General** (green) — standard patients, medium priority
- **Surgery** (blue) — complex cases, long treatment time
- **ICU** (white) — critical patients, highest resource cost

### Conditions
| Condition    | Department | Treatment Time |
| ------------ | ---------- | -------------- |
| Cold         | General    | 5 s            |
| Fracture     | ER         | 10 s           |
| Appendicitis | Surgery    | 15 s           |
| Heart Attack | ICU        | 20 s           |

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `wasActionPressed`)

### Added
- Title screen, victory screen, game over screen with state machine
- Particle effects (treatment sparkle, emergency flash, patient arrival glow)
- Tween animations (treatment progress bar, satisfaction animation, gold counter)
- `render` / `render_ui` split with HUD overlay (gold, rating, patients treated, FPS)
- Camera support
