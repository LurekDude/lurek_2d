# `ai` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Reusable Engine Extensions |
| **Lua API** | `luna.ai` |
| **Source** | `src/ai/` |
| **Tests** | `tests/ai_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_ai.lua` |

## Summary

The AI module provides a comprehensive, modular game-intelligence toolkit that
Lua scripts can assemble to match the needs of each actor in a scene.  Rather
than committing to a single AI paradigm it offers five interchangeable decision
models — finite state machines for reactive logic, behaviour trees for
conditional priority behaviour, steering behaviours for smooth movement, and
hybrid combinations of all three — all managed through a central `AIWorld`
registry that tracks agents, blackboards, and shared spatial structures.

Beyond per-agent decision-making the module covers collective intelligence:
`Squad` formations for group movement, a `CommandQueue` for ordered command
buffering, GOAP planning for goal-oriented NPCs, and `QLearner` for tabular
reinforcement learning when you want enemies to adapt to player behaviour over
time.  Spatial AI structures — A* pathfinding grids, BFS flow fields, and
named influence maps — are shared across all agents in the world, avoiding
redundant computation when dozens of actors navigate the same level.

Grid pathfinding (`SimpleGrid`, `SimpleCell`) and flow-field (`FlowField`)
types are re-exported from `crate::pathfinding` so that `luna.ai.*` has a
unified AI namespace without separate wrapper files.

The `Blackboard` is the shared-memory substrate: a hierarchical key-value
store where agents and behaviour trees read and write facts.  Parent-chain
inheritance lets a global game blackboard propagate facts (player position,
alert level) to all agent-local blackboards without imposing direct coupling
between the systems that produce and consume those facts.

## Architecture

```
AIWorld (central registry)
  │
  ├── Agent ─── DecisionModel selection
  │     ├── Fsm ─────────► StateMachine
  │     ├── Bt ──────────► BehaviorTree
  │     ├── Steering ────► SteeringManager
  │     ├── FsmSteering ─► StateMachine + SteeringManager
  │     └── BtSteering ──► BehaviorTree + SteeringManager
  │
  ├── Blackboard ─── hierarchical key-value store (parent chain)
  │
  ├── Planning
  │     ├── GOAPPlanner ── A* over boolean precondition/effect space
  │     └── UtilityAI ──── scored action selection via response curves
  │
  ├── Spatial
  │     ├── PathGrid ──── A* with octile heuristic + LoS smoothing
  │     ├── FlowField ─── BFS-based 8-directional movement
  │     └── InfluenceMap ─ named layers with stamp/propagate/decay (re-exported from `crate::pathfinding`)
  │
  ├── Learning
  │     └── QLearner ──── tabular Q-learning with epsilon-greedy
  │
  ├── Group
  │     ├── Squad ─────── formation positioning (Line/Wedge/Circle/Column)
  │     └── CommandQueue ─ priority-sorted command buffer
  │
  └── Steering
        └── SteeringManager ── 7 behaviors combined (Seek/Flee/Arrive/Wander/Pursue/Evade/Flock)
```

## Source Files

| File | Purpose |
|------|---------|
| `agent.rs` | Autonomous agent with kinematic state and attached decision subsystems |
| `behavior_tree.rs` | Behavior Tree with composite, decorator, and leaf nodes |
| `blackboard.rs` | Typed key-value store with optional parent chain for hierarchical lookup |
| `command_queue.rs` | RTS-style ordered command queue for scheduling unit actions |
| `fsm.rs` | Finite State Machine with priority-ordered guarded transitions |
| `goap.rs` | Goal-Oriented Action Planning (GOAP) using A★ search over boolean world state |
| ~~`influence_map.rs`~~ | **Moved** to `src/pathfinding/influence_map.rs` — re-exported as `crate::ai::InfluenceMap` |
| `qlearner.rs` | Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning |
| `squad.rs` | Multi-agent formation groups with offset computation |
| `steering.rs` | Reynolds-style steering behaviors with weighted/priority combination |
| `utility_ai.rs` | Multi-axis utility scorer that chooses the action with highest composite score |
| `world.rs` | Container that owns agents and ticks them in descending priority order each... |

## Submodules

### `ai::agent`

Autonomous agent with kinematic state and attached decision subsystems.

- **`DecisionModel`** (enum): Controls which AI subsystems are ticked for an agent during `AIWorld::update`.  Each variant maps to a specific...
- **`Agent`** (struct): An autonomous AI agent with kinematic state and pluggable decision subsystems.  Each agent lives inside an...

### `ai::behavior_tree`

Behavior Tree with composite, decorator, and leaf nodes.

- **`BTStatus`** (enum): Execution status returned by every behavior tree node after a tick.  The three-valued return type is the foundation of...
- **`ParallelPolicy`** (enum): Policy for determining when a Parallel composite node succeeds or fails.  Parallel nodes tick all children every frame...
- **`BTNode`** (enum): A node in the behavior tree. Nodes are organized into three categories:  **Composites** (have multiple children): -...
- **`BehaviorTree`** (struct): Root container for a behavior tree instance.  Wraps an optional root [`BTNode`] and caches the [`BTStatus`] from the...

### `ai::blackboard`

Typed key-value store with optional parent chain for hierarchical lookup.

- **`BlackboardValue`** (enum): A typed value stored in a blackboard slot.  Three types are supported, matching the primitive types commonly passed...
- **`Blackboard`** (struct): A hierarchical key-value store for sharing named data between AI subsystems.  Used by agents, squads, and the AI world...

### `ai::command_queue`

RTS-style ordered command queue for scheduling unit actions.

- **`Command`** (struct): A single RTS unit command with metadata and a Lua tick callback.  Commands are stored in a [`CommandQueue`] and...
- **`CommandQueue`** (struct): A FIFO queue of [`Command`] entries for sequential unit action scheduling.  Commands are consumed from the front. The...

### `ai::fsm`

Finite State Machine with priority-ordered guarded transitions.

- **`StateCallbacks`** (struct): Lua lifecycle hooks for a single FSM state.  Each state can have up to three callbacks, all optional. The AIWorld calls...
- **`Transition`** (struct): A directed edge in the FSM state graph with an optional guard predicate.  Transitions are stored in the...
- **`StateMachine`** (struct): A finite state machine that manages named states with lifecycle callbacks and priority-ordered guarded transitions. ...

### `ai::goap`

Goal-Oriented Action Planning (GOAP) using A★ search over boolean world state.

- **`GOAPAction`** (struct): A single GOAP action with boolean preconditions and effects.  Actions are the building blocks of GOAP plans. Each...
- **`GOAPGoal`** (struct): A planning goal expressed as a desired boolean world state.  Goals represent what the agent wants to achieve. The...
- **`GOAPPlanner`** (struct): A★ planner that finds optimal action sequences to satisfy goals over boolean world state.  The planner holds a set of...

### `ai::influence_map` → moved

`InfluenceMap` now lives in `src/pathfinding/influence_map.rs` and is re-exported from `crate::ai` for backward compatibility.
See [`pathfinding::influence_map`](#pathfindinginfluence_map) for the full API reference.

### `ai::qlearner`

Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning.

- **`QLearner`** (struct): Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning.  Maintains a flat Q-table mapping every...

### `ai::squad`

Multi-agent formation groups with offset computation.

- **`FormationType`** (enum): Formation shapes for squad positioning. Consult the module-level documentation for the broader usage context and...
- **`Squad`** (struct): A named group of agents with formation positioning and shared state.  The squad tracks agent names (not owned `Agent`...

### `ai::steering`

Reynolds-style steering behaviors with weighted/priority combination.

- **`Force`** (type): 2D force vector (fx, fy). Consult the module-level documentation for the broader usage context and preconditions.
- **`CombineMode`** (enum): Determines how multiple active steering behaviors are combined into a single resultant force applied to the agent.  In...
- **`SteeringBase`** (struct): Shared parameters common to all steering behavior instances.  Every [`SteeringBehaviorType`] variant carries a...
- **`SteeringBehaviorType`** (enum): All concrete steering behavior types supported by the AI system.  Each variant carries its own parameters (target...
- **`SteeringManager`** (struct): Manages a list of steering behaviors and combines their forces each frame.

### `ai::utility_ai`

Multi-axis utility scorer that chooses the action with highest composite score.

- **`ResponseCurve`** (enum): Mathematical function shapes for transforming raw consideration inputs into normalized scores.  Response curves allow...
- **`Consideration`** (struct): A single evaluation axis within a utility action's scoring function.  Each consideration queries a game-state value via...
- **`UAAction`** (struct): A candidate action in the utility AI decision space.  Each action has a name (returned to the game when chosen), an...
- **`UtilityAI`** (struct): Multi-axis utility scorer that evaluates candidate actions and chooses the one with the highest composite score.  The...

### `ai::world`

Container that owns agents and ticks them in descending priority order each frame.

- **`AIWorld`** (struct): Top-level AI container that owns agents and provides global shared state.  Agents are stored in a contiguous `Vec` for...

## Key Types

### Structs

#### `ai::world::AIWorld`

Top-level AI container that owns agents and provides global shared state.  Agents are stored in a contiguous `Vec` for...

#### `ai::agent::Agent`

An autonomous AI agent with kinematic state and pluggable decision subsystems.  Each agent lives inside an...

#### `ai::behavior_tree::BehaviorTree`

Root container for a behavior tree instance.  Wraps an optional root [`BTNode`] and caches the [`BTStatus`] from the...

#### `ai::blackboard::Blackboard`

A hierarchical key-value store for sharing named data between AI subsystems.  Used by agents, squads, and the AI world...

#### `ai::command_queue::Command`

A single RTS unit command with metadata and a Lua tick callback.  Commands are stored in a [`CommandQueue`] and...

#### `ai::command_queue::CommandQueue`

A FIFO queue of [`Command`] entries for sequential unit action scheduling.  Commands are consumed from the front. The...

#### `ai::utility_ai::Consideration`

A single evaluation axis within a utility action's scoring function.  Each consideration queries a game-state value via...

#### `ai::goap::GOAPAction`

A single GOAP action with boolean preconditions and effects.  Actions are the building blocks of GOAP plans. Each...

#### `ai::goap::GOAPGoal`

A planning goal expressed as a desired boolean world state.  Goals represent what the agent wants to achieve. The...

#### `ai::goap::GOAPPlanner`

A★ planner that finds optimal action sequences to satisfy goals over boolean world state.  The planner holds a set of...

#### `pathfinding::influence_map::InfluenceMap` (re-exported as `ai::InfluenceMap`)

A multi-layer spatial float grid for influence mapping and strategic reasoning.
Moved to `src/pathfinding/influence_map.rs`; accessible as `luna2d::ai::InfluenceMap` via re-export.

#### `ai::qlearner::QLearner`

Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning.  Maintains a flat Q-table mapping every...

#### `ai::squad::Squad`

A named group of agents with formation positioning and shared state.  The squad tracks agent names (not owned `Agent`...

#### `ai::fsm::StateCallbacks`

Lua lifecycle hooks for a single FSM state.  Each state can have up to three callbacks, all optional. The AIWorld calls...

#### `ai::fsm::StateMachine`

A finite state machine that manages named states with lifecycle callbacks and priority-ordered guarded transitions. ...

#### `ai::steering::SteeringBase`

Shared parameters common to all steering behavior instances.  Every [`SteeringBehaviorType`] variant carries a...

#### `ai::steering::SteeringManager`

Manages a list of steering behaviors and combines their forces each frame.

#### `ai::fsm::Transition`

A directed edge in the FSM state graph with an optional guard predicate.  Transitions are stored in the...

#### `ai::utility_ai::UAAction`

A candidate action in the utility AI decision space.  Each action has a name (returned to the game when chosen), an...

#### `ai::utility_ai::UtilityAI`

Multi-axis utility scorer that evaluates candidate actions and chooses the one with the highest composite score.  The...

### Enums

#### `ai::behavior_tree::BTNode`

A node in the behavior tree. Nodes are organized into three categories:  **Composites** (have multiple children): -...

#### `ai::behavior_tree::BTStatus`

Execution status returned by every behavior tree node after a tick.  The three-valued return type is the foundation of...

#### `ai::blackboard::BlackboardValue`

A typed value stored in a blackboard slot.  Three types are supported, matching the primitive types commonly passed...

#### `ai::steering::CombineMode`

Determines how multiple active steering behaviors are combined into a single resultant force applied to the agent.  In...

#### `ai::agent::DecisionModel`

Controls which AI subsystems are ticked for an agent during `AIWorld::update`.  Each variant maps to a specific...

#### `ai::squad::FormationType`

Formation shapes for squad positioning. Consult the module-level documentation for the broader usage context and...

#### `ai::behavior_tree::ParallelPolicy`

Policy for determining when a Parallel composite node succeeds or fails.  Parallel nodes tick all children every frame...

#### `ai::utility_ai::ResponseCurve`

Mathematical function shapes for transforming raw consideration inputs into normalized scores.  Response curves allow...

#### `ai::steering::SteeringBehaviorType`

All concrete steering behavior types supported by the AI system.  Each variant carries its own parameters (target...

### Type Aliases

#### `ai::steering::Force`

2D force vector (fx, fy). Consult the module-level documentation for the broader usage context and preconditions.

## Lua API

Exposed under `luna.ai.*` by `src/lua_api/ai_api/`.

## Design Notes

- # AI Module — Game AI Toolkit (Tier 2)  Provides a comprehensive suite of decoupled game AI subsystems for Luna2D. Each subsystem can be used independently or composed together through the [`Agent`] / [`AIWorld`] framework.  ## Architecture Overview  The AI module is a **Tier 2 Engine Extension**. It may import `math`, `engine`, and Tier 1 modules (primarily `pathfinding` for grid and flow-field re-exports). It must not import other Tier 2 modules or any Tier 3 modules.  All AI computation is **pure CPU math** — no GPU, audio, or window access. This means every subsystem can run headlessly in tests without a graphics context.  ## Subsystems  | Subsystem | Description | |-----------|-------------| | [`fsm`] | Finite state machine with priority-ordered guarded transitions | | [`behavior_tree`] | Hierarchical behavior tree with composites, decorators, and leaf callbacks | | [`steering`] | Reynolds-style steering behaviors (seek, flee, arrive, wander, pursue, evade, flock) | | [`goap`] | Goal-Oriented Action Planning using A★ over boolean world state | | [`utility_ai`] | Multi-axis utility scorer with response curves for action selection | | [`qlearner`] | Tabular epsilon-greedy Q-learning for reinforcement learning | | [`influence_map`] | Multi-layer spatial float grid for strategic area analysis | | [`squad`] | Squad coordination with formation offset computation | | [`command_queue`] | RTS-style ordered command queue with interrupt and cancel | | [`blackboard`] | Hierarchical key-value store for inter-agent data sharing |  ## Agent–World Model  [`AIWorld`] owns all [`Agent`] instances. Each agent carries kinematic state (position, velocity, max speed/force), a [`DecisionModel`] that selects which subsystems are ticked, and a local [`Blackboard`] that chains to the world's global blackboard for hierarchical lookup.  The world ticks agents in descending priority order during `update(dt)`. FSM transitions, BT ticks, and steering force calculations all happen during this pass. The Lua API layer (`luna.ai.*`) wraps these Rust types.  ## Dependencies  - [`pathgrid`] and [`flowfield`] are thin re-exports from `crate::pathfinding`   (a Tier 2 sibling — re-exported here so `luna.ai.*` has a unified surface). - All Lua callbacks are stored as `mlua::RegistryKey` references. - No heap allocation happens per-frame in steady state; vectors are grown at   agent/behavior creation time.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 9 |
| `mod` | 14 |
| `struct` | 20 |
| `type` | 1 |
| **Total** | **44** |

