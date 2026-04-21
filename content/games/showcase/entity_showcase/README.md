# Entity Showcase

**Category:** showcase

Interactive ECS (Entity Component System) deep dive with six chapters demonstrating core concepts: entity lifecycle, components, systems, queries, events, and stress testing.

## Run

```
cargo run -- content/games/showcase/entity_showcase
```

## Controls

| Key           | Action                                                       |
| ------------- | ------------------------------------------------------------ |
| 1–6           | Switch chapter                                               |
| Space         | Spawn entity (Ch 1, 6)                                       |
| D             | Destroy selected / oldest entity                             |
| P / V / H / K | Toggle Position / Velocity / Health / Color component (Ch 2) |
| Mouse click   | Select entity                                                |
| Escape        | Quit                                                         |

## Chapters

1. **Create / Destroy** — Spawn entities with Space, destroy with D. Watch the live entity counter.
2. **Components** — Add and remove Position, Velocity, Health, and Color components with hotkeys. Inspect selected entity in the component panel.
3. **Systems** — Movement system updates positions from velocity, render system draws entities, health system decays HP over time.
4. **Queries** — Filter entities by component combination; matching entities are highlighted.
5. **Events** — Collision, health-change, and spawn/destroy events visualised in real time.
6. **Stress Test** — Spawn 500 entities with physics-like motion. Performance metrics (FPS, update time, entity count) shown in the HUD.

## Features

- Entity visualization as colored circles with component indicator icons
- Component detail panel (right side) for the selected entity
- Particle bursts on spawn, poof on destroy, sparks on collision
- Tween-driven entity scale on spawn and panel slide transitions
- HUD with entity count, component counts per type, and FPS
- Title screen with chapter selection prompt
- All ECS operations simulated inline — no external ECS crate required

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`
