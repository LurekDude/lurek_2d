---
name: game-ai
description: "Load this skill when designing or implementing AI behaviour for game actors in Lurek2D using the lurek.ai.* API: finite state machines, behaviour trees, GOAP planners, steering behaviours, utility AI, Q-learning, squad formations, command queues, influence maps, or the shared Blackboard. Use for: enemy patrol/chase/flee, NPC decision-making, group tactics, pathfinding integration, AI testing. Skip it for general Rust AI module internals (see docs/specs/ai.md) or pathfinding algorithms (see docs/specs/pathfind.md)."
---
# game-ai

## Mission

# Game AI Design — Lurek2D

## When To Load

- Choosing which AI model to use for a game actor (FSM vs behaviour tree vs GOAP vs utility)
- Building enemy patrol, chase, flee, idle, or attack behaviour
- Designing NPC decision trees or goal-oriented planning
- Implementing group/squad tactics or formation movement
- Adding influence maps or spatial strategy reasoning
- Integrating AI agents with physics and pathfinding
- Testing AI behaviour headlessly

## When To Skip

- Skip it for general Rust AI module internals (see docs/specs/ai.

## Domain Knowledge

### Owns
- Decision model selection guide (when to use FSM vs BTree vs GOAP vs utility AI)
- `lurek.ai.*` Lua API patterns for each model
- Blackboard usage as shared AI memory
- Steering behaviour combinations
- Q-learning setup for simple reinforcement learning
- Squad and command queue patterns for group AI
- Influence map and flow field integration
- AI testing strategies

---

### Decision Model Selection Guide
Choose the simplest model that satisfies the design requirement.

| Model | Best for | Avoid when |
|-------|---------|-----------|
| **FSM** | Small number of discrete states with clear transitions (guard: patrol→alert→attack) | > ~8 states — becomes spaghetti |
| **Behaviour Tree** | Prioritised, reusable, hierarchical actions (patrol UNTIL enemy seen THEN chase AND shoot) | Simple 2-3 state machines — overkill |
| **GOAP** | Open-ended NPC with many possible actions and goals, emergent behaviour | Real-time enemies where planning cost matters |
| **Utility AI** | Multi-axis decisions where multiple actions compete on scored criteria | Binary (yes/no) decisions — FSM is simpler |
| **Steering** | Smooth movement: seek, flee, arrive, wander, flock | Discrete turn-based movement |
| **Q-learning** | Simple adaptive agents that improve with play (tabular, discrete state space) | Large or continuous state spaces — use FSM instead |

---

### AI World Setup
All AI agents live inside an `AIWorld` registry. Create one world per scene.

> See [examples/ai-world-setup.lua](examples/ai-world-setup.lua) for the example.

---

### FSM — Finite State Machine
Best for enemies with clear discrete modes.

> See [examples/fsm-finite-state-machine.lua](examples/fsm-finite-state-machine.lua) for the example.

> See [examples/fsm-finite-state-machine-2.lua](examples/fsm-finite-state-machine-2.lua) for the example.

---

### Behaviour Tree
Best for complex, reusable, hierarchical NPC logic.

> See [examples/behaviour-tree.lua](examples/behaviour-tree.lua) for the example.

### Common node types

| Node | Type | Returns success when |
|------|------|---------------------|
| `bt:sequence({...})` | Composite | ALL children succeed |
| `bt:selector({...})` | Composite | ANY child succeeds |
| `bt:parallel({...}, n)` | Composite | N children succeed simultaneously |
| `bt:inverter(child)` | Decorator | Child returns failure |
| `bt:repeater(child, n)` | Decorator | Child ran N times |
| `bt:succeeder(child)` | Decorator | Always (wraps any child) |
| `bt:condition(fn)` | Leaf | `fn(agent)` returns truthy |
| `bt:action(fn)` | Leaf | `fn(agent)` returns `"success"` |

---

### Blackboard — Shared AI Memory

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [examples/ai-world-setup.lua](examples/ai-world-setup.lua) — AI World Setup
- [examples/fsm-finite-state-machine.lua](examples/fsm-finite-state-machine.lua) — FSM — Finite State Machine
- [examples/fsm-finite-state-machine-2.lua](examples/fsm-finite-state-machine-2.lua) — FSM — Finite State Machine
- [examples/behaviour-tree.lua](examples/behaviour-tree.lua) — Behaviour Tree
- [examples/blackboard-shared-ai-memory.lua](examples/blackboard-shared-ai-memory.lua) — Blackboard — Shared AI Memory
- [examples/steering-behaviours.lua](examples/steering-behaviours.lua) — Steering Behaviours
- [examples/goap-goal-oriented-action-planning.lua](examples/goap-goal-oriented-action-planning.lua) — GOAP — Goal-Oriented Action Planning
- [examples/utility-ai-scored-action-selection.lua](examples/utility-ai-scored-action-selection.lua) — Utility AI — Scored Action Selection
- [examples/squad-group-formation.lua](examples/squad-group-formation.lua) — Squad — Group Formation
- [examples/influence-map-strategic-spatial-reasoning.lua](examples/influence-map-strategic-spatial-reasoning.lua) — Influence Map — Strategic Spatial Reasoning
- [examples/testing-ai.lua](examples/testing-ai.lua) — Testing AI
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
