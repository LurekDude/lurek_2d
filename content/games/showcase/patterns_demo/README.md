# Patterns Demo

**Category:** showcase

Interactive design patterns showcase demonstrating six classic software patterns — EventBus, ObjectPool, CommandStack, ServiceLocator, Factory, and SimpleState — each with live visualization and pseudocode explanation.

## Run

```
cargo run -- content/games/showcase/patterns_demo
```

## Controls

| Key    | Action                                            |
| ------ | ------------------------------------------------- |
| 1–6    | Switch pattern                                    |
| A      | EventBus: fire "player_hit"                       |
| B      | EventBus: fire "score_up"                         |
| C      | EventBus: fire "level_up"                         |
| Space  | ObjectPool: spawn / SimpleState: force transition |
| D      | ObjectPool: release object                        |
| Arrows | CommandStack: move square                         |
| U      | CommandStack: undo                                |
| R      | CommandStack: redo                                |
| S      | ServiceLocator: query services                    |
| F      | Factory: create random entity                     |
| Escape | Quit                                              |

## Patterns

1. **EventBus** — Publish/subscribe: multiple listeners react to events with scrolling log.
2. **ObjectPool** — Pre-allocated pool with spawn/release tracking and pool metrics.
3. **CommandStack** — Undo/redo via command objects; movement history visualized.
4. **ServiceLocator** — Register and query named services; response shown in log.
5. **Factory** — Create Warrior, Mage, or Archer entities from a factory function.
6. **SimpleState** — Traffic light FSM cycling Green→Yellow→Red with auto and manual transitions.

## Features

- Tab bar with active pattern highlight and tween slide transitions
- Left panel: interactive demo visualization (render pass)
- Right panel: pseudocode explanation (render_ui pass)
- Bottom log window: scrolling operation log (100px)
- Particle bursts on actions and state transitions
- Tween-driven tab switch, entity spawn scale, and traffic light color
- Title screen with pattern selection prompt
- FPS counter and camera setup

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.timer`, `lurek.signal`
