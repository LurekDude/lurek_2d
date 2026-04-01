---
name: ai-systems
description: "Load this skill when implementing game AI in Luna2D: FSM state machines, behavior trees, steering behaviors, GOAP planning, Q-learning, influence maps, squads, or utility AI. Skip it for pathfinding grids, physics, or rendering."
---

# AI Systems — Luna2D Engine

## Load When

- Implementing or modifying FSM state machines
- Building behavior trees (sequence, selector, parallel, decorators)
- Adding steering behaviors (seek, flee, wander, flocking)
- Designing GOAP actions, goals, or planners
- Setting up Q-learning agents or reward shaping
- Working with influence maps for spatial AI
- Implementing squad coordination (formations, morale)
- Building utility AI scorers

## Owns

- `src/ai/` module — all AI subsystem code
- `src/lua_api/ai_api.rs` — `luna.ai.*` Lua bindings
- AI decision model selection and composition
- Agent lifecycle (creation, update, destruction)

## Does Not Cover

- Grid pathfinding algorithms → use `pathfinding-systems` skill
- Physics body movement → use `physics-engine` skill
- Entity lifecycle → use `ecs-architecture` skill
- Steering math (Vec2 operations) → use `src/math/`

## Live Repository Contracts

- `src/ai/mod.rs` — module root, re-exports all AI types
- `src/ai/fsm.rs` — `StateMachine`, `StateCallbacks`, `Transition`
- `src/ai/behavior_tree.rs` — `BehaviorTree`, `BTNode`, `BTStatus`, `ParallelPolicy`
- `src/ai/steering.rs` — `SteeringManager`, seek/flee/wander/arrive/pursue/evade/flocking
- `src/ai/goap.rs` — `GOAPPlanner`, `GOAPAction`, `GOAPGoal`
- `src/ai/qlearner.rs` — `QLearner` (tabular Q-learning)
- `src/ai/influence_map.rs` — `InfluenceMap` (grid-based spatial reasoning)
- `src/ai/squad.rs` — `Squad`, `FormationType` (group coordination)
- `src/ai/utility_ai.rs` — `UtilityAI`, `UAAction`, `Consideration`, `ResponseCurve`
- `src/ai/blackboard.rs` — `Blackboard`, `BlackboardValue` (shared key-value store)
- `src/ai/command_queue.rs` — `CommandQueue`, `Command` (action scheduling with undo)
- `src/ai/world.rs` — `AIWorld` (spatial awareness, teams)
- `src/ai/agent.rs` — `Agent`, `DecisionModel` (pluggable AI agent)

## Decision Rules

- **All computation is pure CPU math** — no GPU, audio, or window access in `src/ai/`
- **Agents are decoupled** — an agent can be driven by FSM, BT, Steering, or any combination
- **DecisionModel enum selects behavior** — FSM for state-based, BT for complex trees, Steering for movement
- **Blackboard is the inter-agent bus** — agents share data via `Blackboard` key-value store, not direct references
- **GOAP plans are computed, not cached** — replan when world state changes
- **QLearner is tabular** — suited for small discrete state/action spaces; not for continuous environments
- **InfluenceMap resolution matters** — lower resolution = faster but less precise; match to game scale
- **Squad formation is relative** — positions computed relative to squad leader, not absolute world coordinates
- **UtilityAI scores are normalized** — ResponseCurve maps input [0,1] → output [0,1] for consistent comparison

## Algorithm Selection Guide

| Scenario | Recommended | Why |
|---|---|---|
| Simple NPC states (idle, patrol, chase) | FSM | Low overhead, easy to debug |
| Complex NPC with fallback chains | BehaviorTree | Composable, supports parallel tasks |
| Smooth movement toward targets | Steering (seek/arrive) | Frame-by-frame velocity adjustment |
| Group movement / flocking | Steering (separation, alignment, cohesion) | Emergent flock behavior |
| Planning multi-step actions | GOAP | Finds optimal action sequence |
| Learning from experience | QLearner | Adapts over many episodes |
| Territory control / threat assessment | InfluenceMap | Spatial reasoning on grid |
| Best-action-now from many options | UtilityAI | Weighted parallel evaluation |
| Military unit coordination | Squad | Formation + morale + group orders |

## Best Practices

- Start with FSM for simple NPCs — upgrade to BehaviorTree only when state count exceeds ~8
- Use `Blackboard` for AI data sharing — never reach into another agent's internals
- Keep steering forces small and composable — combine via weighted sums in `SteeringManager`
- GOAP actions should have clear preconditions and effects — fuzzy conditions cause combinatorial explosion
- QLearner episodes should run many iterations — single-episode training produces poor policies

## Anti-Patterns

- **God Agent**: One agent with 50+ FSM states — split into sub-FSMs or switch to BehaviorTree
- **Cross-agent mutation**: Agent A directly modifying Agent B's state — use Blackboard or events
- **Continuous Q-learning**: Using QLearner for continuous state spaces — it's tabular, not deep RL
- **GOAP everything**: Simple patrol/chase NPCs don't need planning — FSM is sufficient
- **Influence map per frame**: Rebuilding entire influence map every frame — propagate incrementally
