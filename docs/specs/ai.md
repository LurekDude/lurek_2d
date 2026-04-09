# `ai` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.ai`                                            |
| **Source**      | `src/ai/`                                            |
| **Rust Tests** | `tests/rust/unit/ai_tests.rs`                        |
| **Lua Tests**  | `tests/lua/unit/test_ai.lua`                         |
| **Architecture** | —                                                  |

## Summary

The AI module provides a comprehensive, modular game-intelligence toolkit that Lua scripts can assemble to match the needs of each actor in a scene. Rather than committing to a single AI paradigm it offers five interchangeable decision models — finite state machines for reactive logic, behaviour trees for conditional priority behaviour, steering behaviours for smooth movement, GOAP for goal-oriented NPC planning, utility AI for scored multi-axis action selection, and tabular Q-learning for reinforcement learning — all managed through a central `AIWorld` registry that tracks agents, blackboards, and shared spatial structures.

Beyond per-agent decision-making the module covers collective intelligence: `Squad` formations for group movement (line, wedge, circle, column), a `CommandQueue` for RTS-style ordered command buffering, and an `InfluenceMap` (re-exported from `crate::pathfinding`) for strategic spatial reasoning across named layers with stamp, propagate, and decay operations.

The `Blackboard` is the shared-memory substrate: a hierarchical key-value store where agents and behaviour trees read and write facts. Parent-chain inheritance lets a global game blackboard propagate facts (player position, alert level) to all agent-local blackboards without imposing direct coupling between the systems that produce and consume those facts. Writes always target the local store while reads walk the chain upward until a match is found.

All AI computation is **pure CPU math** — no GPU, audio, or window access required. This means every subsystem can run headlessly in tests without a graphics context. The module depends on `math`, `engine`, and Tier 1 `pathfinding` (for grid, flow-field, and influence-map re-exports). It must not import other Tier 2 modules. Lua callbacks are stored as `mlua::RegistryKey` references. No heap allocation happens per-frame in steady state; vectors are grown at agent/behavior creation time.

Grid pathfinding (`PathGrid`, `Cell`) and flow-field (`FlowField`) types are re-exported from `crate::pathfinding` so that `lurek.ai.*` has a unified AI namespace without separate wrapper files. `InfluenceMap` is also re-exported from `crate::pathfinding::InfluenceMap`.

## Architecture

```
AIWorld (central registry, owns all agents)
  │
  ├── Agent ─── DecisionModel selection
  │     ├── Fsm ─────────► StateMachine (states + guarded transitions)
  │     ├── Bt ──────────► BehaviorTree (composite/decorator/leaf nodes)
  │     ├── Steering ────► SteeringManager (7 Reynolds behaviors)
  │     ├── FsmSteering ─► StateMachine + SteeringManager
  │     └── BtSteering ──► BehaviorTree + SteeringManager
  │
  ├── Blackboard ─── hierarchical key-value store (parent chain)
  │     ├── Global (world level)
  │     ├── Agent-local → parent: Global
  │     └── Squad-level (independent)
  │
  ├── Planning
  │     ├── GOAPPlanner ── A* over boolean precondition/effect space
  │     └── UtilityAI ──── scored action selection via response curves
  │
  ├── Spatial (re-exported from crate::pathfinding)
  │     ├── PathGrid ──── A* with octile heuristic + LoS smoothing
  │     ├── FlowField ─── BFS-based 8-directional movement
  │     └── InfluenceMap ─ named layers with stamp/propagate/decay
  │
  ├── Learning
  │     └── QLearner ──── tabular Q-learning with epsilon-greedy + Bellman
  │
  ├── Group
  │     ├── Squad ─────── formation positioning (Line/Wedge/Circle/Column/None)
  │     └── CommandQueue ─ FIFO command buffer with interrupt and cancel
  │
  └── Steering
        └── SteeringManager ── 7 behaviors combined (Seek/Flee/Arrive/Wander/Pursue/Evade/Flock)
              └── CombineMode: Weighted (sum all) or Priority (first non-zero wins)
```

## Source Files

| File                | Purpose                                                                          |
|---------------------|----------------------------------------------------------------------------------|
| `mod.rs`            | Module declarations, re-exports from `crate::pathfinding` (FlowField, Cell, PathGrid, InfluenceMap) |
| `agent.rs`          | Autonomous agent with kinematic state (position, velocity) and pluggable decision models |
| `behavior_tree.rs`  | Behavior tree with composite (Selector, Sequence, Parallel), decorator (Inverter, Repeater, Succeeder), and leaf (Action, Condition) nodes |
| `blackboard.rs`     | Typed key-value store with optional parent chain for hierarchical lookup         |
| `command_queue.rs`  | RTS-style ordered command queue with enqueue, push-front, replace, and cancel    |
| `fsm.rs`            | Finite state machine with priority-ordered guarded transitions and lifecycle callbacks |
| `goap.rs`           | Goal-Oriented Action Planning using A★ search over boolean world state           |
| `qlearner.rs`       | Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning       |
| `squad.rs`          | Multi-agent formation groups with offset computation (line, wedge, circle, column) |
| `steering.rs`       | Reynolds-style steering behaviors with weighted or priority-based force combination |
| `utility_ai.rs`     | Multi-axis utility scorer with response curves for action selection              |
| `world.rs`          | Top-level AI container that owns agents, maintains name→index lookup, and provides global blackboard |

## Submodules

### `ai::agent`

Autonomous agent with kinematic state and attached decision subsystems.

- **`DecisionModel`** (enum) — Controls which AI subsystems are ticked during `AIWorld::update`. Variants: `Fsm`, `Bt`, `Steering`, `FsmSteering`, `BtSteering`.
- **`Agent`** (struct) — Autonomous AI agent with position, velocity, max_speed, max_force, decision model, local blackboard, tags, and optional FSM/BT/steering indices.

### `ai::behavior_tree`

Behavior tree with composite, decorator, and leaf nodes.

- **`BTStatus`** (enum) — Execution status returned by every BT node: `Success`, `Failure`, `Running`.
- **`ParallelPolicy`** (enum) — Policy for Parallel composite result aggregation: `RequireOne`, `RequireAll`.
- **`BTNode`** (enum) — A node in the behavior tree: composites (`Selector`, `Sequence`, `Parallel`), decorators (`Inverter`, `Repeater`, `Succeeder`), and leaves (`Action`, `Condition`).
- **`BehaviorTree`** (struct) — Root container wrapping an optional root `BTNode` and caching the `BTStatus` from the last tick.

### `ai::blackboard`

Typed key-value store with optional parent chain for hierarchical lookup.

- **`BlackboardValue`** (enum) — A typed value: `Number(f64)`, `Bool(bool)`, `Text(String)`.
- **`Blackboard`** (struct) — Hierarchical key-value store with entries `HashMap<String, BlackboardValue>` and optional parent chain.

### `ai::command_queue`

RTS-style ordered command queue for scheduling unit actions.

- **`Command`** (struct) — A single command with kind, Lua callback, target coordinates, priority, and interruptible flag.
- **`CommandQueue`** (struct) — FIFO queue of `Command` entries with enqueue, push-front, replace, cancel, and advance operations.

### `ai::fsm`

Finite state machine with priority-ordered guarded transitions.

- **`StateCallbacks`** (struct) — Lua lifecycle hooks for a single FSM state: `on_enter`, `on_update`, `on_exit` (all optional `RegistryKey`).
- **`Transition`** (struct) — A directed edge with source, destination, optional guard predicate, and priority.
- **`StateMachine`** (struct) — Manages named states with lifecycle callbacks, priority-ordered guarded transitions, current state tracking, and time-in-state counter.

### `ai::goap`

Goal-Oriented Action Planning (GOAP) using A★ search over boolean world state.

- **`GOAPAction`** (struct) — A GOAP action with name, cost, optional Lua callback, boolean preconditions, and boolean effects.
- **`GOAPGoal`** (struct) — A planning goal with name, priority, and target boolean world state.
- **`GOAPPlanner`** (struct) — A★ planner that finds optimal action sequences to satisfy goals. Holds `Vec<GOAPAction>` and `Vec<GOAPGoal>`. Hard limit of 10,000 A★ iterations.

### `ai::qlearner`

Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning.

- **`QLearner`** (struct) — Maintains a flat Q-table (`Vec<f64>`, `state_count × action_count`). Parameters: α (learning rate), γ (discount factor), ε (exploration rate), epsilon_decay. Supports JSON serialize/deserialize for saving trained policies.

### `ai::squad`

Multi-agent formation groups with offset computation.

- **`FormationType`** (enum) — Formation shapes: `None`, `Line`, `Wedge`, `Circle`, `Column`.
- **`Squad`** (struct) — Named group of agents with members list, optional leader, formation type, spacing, and a shared blackboard.

### `ai::steering`

Reynolds-style steering behaviors with weighted/priority combination.

- **`Force`** (type alias) — `(f32, f32)` — 2D force vector.
- **`CombineMode`** (enum) — How multiple behaviors are combined: `Weighted` (sum all × weight) or `Priority` (first non-zero wins).
- **`SteeringBase`** (struct) — Shared parameters: `weight` and `enabled` flag.
- **`SteeringBehaviorType`** (enum) — All concrete behavior variants: `Seek`, `Flee`, `Arrive`, `Wander`, `Pursue`, `Evade`, `Flock`. Each carries its own parameters plus a `SteeringBase`.
- **`SteeringManager`** (struct) — Manages a list of steering behaviors, combines forces per `CombineMode`, and caches `last_force`.

### `ai::utility_ai`

Multi-axis utility scorer that chooses the action with highest composite score.

- **`ResponseCurve`** (enum) — Mathematical function shapes: `Linear`, `Quadratic`, `Logistic`, `Logit`, `Step`.
- **`Consideration`** (struct) — A single evaluation axis with name, Lua callback, response curve, curve parameters (p1, p2, p3), and weight.
- **`UAAction`** (struct) — A candidate action with name, scorer callback, considerations, and momentum bonus.
- **`UtilityAI`** (struct) — Evaluates candidate actions, caches `last_action` index and `last_scores` array.

### `ai::world`

Top-level AI container that owns agents and ticks them in descending priority order.

- **`AIWorld`** (struct) — Owns `Vec<Agent>`, `HashMap<String, usize>` name-index, and a global `Blackboard`. Provides `add_agent`, `remove_agent`, `update(dt)`.

## Key Types

### Structs

#### `ai::world::AIWorld`

Top-level AI container that owns agents and provides global shared state. Agents are stored in a contiguous `Vec` for cache-friendly iteration. A `HashMap<String, usize>` provides O(1) name-based lookup. The global blackboard is automatically set as the parent of each agent's local blackboard on `add_agent()`.

#### `ai::agent::Agent`

An autonomous AI agent with kinematic state and pluggable decision subsystems. Carries position, velocity, max_speed, max_force, a `DecisionModel`, per-agent blackboard (parent-chained to global), tags for group queries, and optional indices into the world's FSM/BT/steering storage.

#### `ai::behavior_tree::BehaviorTree`

Root container for a behavior tree instance. Wraps an optional root `BTNode` and caches the `BTStatus` from the last tick. The tree is traversed from root each frame, resuming from running nodes.

#### `ai::blackboard::Blackboard`

A hierarchical key-value store for sharing named data between AI subsystems. Supports three value types (`Number`, `Bool`, `Text`). Reads walk the parent chain; writes always target the local store. Used by agents, squads, and the AI world.

#### `ai::command_queue::Command`

A single RTS unit command with `kind` string, Lua `callback` (`fn(dt) → bool`), target coordinates, priority, and `interruptible` flag. Processed one at a time from the front of a `CommandQueue`.

#### `ai::command_queue::CommandQueue`

A FIFO queue of `Command` entries. Supports `enqueue` (back), `push_front` (interrupt), `replace` (clear + enqueue), `cancel_current` (if interruptible), and `advance` (pop front).

#### `ai::utility_ai::Consideration`

A single evaluation axis within a utility action's scoring function. Queries a game-state value via its Lua callback, transforms through a `ResponseCurve`, and multiplies by weight.

#### `ai::goap::GOAPAction`

A GOAP action with name, cost, optional Lua callback, boolean preconditions, and boolean effects. Used as building blocks for A★ plan search.

#### `ai::goap::GOAPGoal`

A planning goal expressed as a desired boolean world state with name and priority. The planner selects the highest-priority goal for planning.

#### `ai::goap::GOAPPlanner`

A★ planner that finds optimal action sequences to satisfy goals over boolean world state. Holds `Vec<GOAPAction>` and `Vec<GOAPGoal>`. Stateless between calls — each `plan()` is a fresh search. Hard limit of 10,000 iterations.

#### `ai::qlearner::QLearner`

Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning. Maintains a flat Q-table (`Vec<f64>`, `state_count × action_count`). Hyperparameters: α=0.1, γ=0.9, ε=0.1, decay=0.995 (defaults). Supports JSON serialization for saving/loading trained policies.

#### `ai::squad::Squad`

A named group of agents with formation positioning and shared blackboard. Tracks agent names (not owned `Agent` structs). Call `get_formation_position(member_idx, leader_pos)` to compute ideal world-space positions per formation type.

#### `ai::fsm::StateCallbacks`

Lua lifecycle hooks for a single FSM state: `on_enter` (once on transition in), `on_update` (every frame), `on_exit` (once on transition out). All optional `RegistryKey` references.

#### `ai::fsm::StateMachine`

A finite state machine with named states, lifecycle callbacks, and priority-ordered guarded transitions. In exactly one state at a time. Transitions sorted by descending priority — first passing guard wins. Tracks `time_in_state` for time-based guards.

#### `ai::fsm::Transition`

A directed edge in the FSM state graph with source, destination, optional guard predicate (`fn(agent, dt) → bool`), and priority for evaluation ordering.

#### `ai::steering::SteeringBase`

Shared parameters common to all steering behavior instances: `weight` multiplier and `enabled` flag. Carried by every `SteeringBehaviorType` variant.

#### `ai::steering::SteeringManager`

Manages a list of `SteeringBehaviorType` instances, combines their forces per `CombineMode` (Weighted or Priority), truncates to `max_force`, and caches the `last_force` result.

#### `ai::utility_ai::UAAction`

A candidate action in the utility AI decision space. Has a name, scorer callback, zero or more `Consideration`s, and a `momentum_bonus` for action inertia.

#### `ai::utility_ai::UtilityAI`

Multi-axis utility scorer. Holds `Vec<UAAction>`, evaluates each action's considerations, applies momentum bonuses, and records the winning action index and score array.

### Enums

#### `ai::agent::DecisionModel`

Controls which AI subsystems are ticked for an agent during `AIWorld::update`. Variants: `Fsm`, `Bt`, `Steering`, `FsmSteering` (FSM first, then steering), `BtSteering` (BT first, then steering). Parsed from Lua strings (`"fsm"`, `"bt"`, `"steering"`, `"fsm+steering"`, `"bt+steering"`).

#### `ai::behavior_tree::BTStatus`

Execution status returned by every BT node: `Success`, `Failure`, `Running`. Composites and decorators use this to decide whether to continue, abort, or resume child traversal.

#### `ai::behavior_tree::ParallelPolicy`

Policy for Parallel composite result aggregation: `RequireOne` (any single child) or `RequireAll` (every child). Parsed from `"requireOne"` / `"requireAll"`.

#### `ai::behavior_tree::BTNode`

A BT node. Composites: `Selector` (first success), `Sequence` (first failure), `Parallel` (policy-based). Decorators: `Inverter`, `Repeater`, `Succeeder`. Leaves: `Action` (Lua callback → status string), `Condition` (Lua predicate → bool). Composite nodes store `running_idx` for multi-frame resume.

#### `ai::blackboard::BlackboardValue`

A typed blackboard value: `Number(f64)`, `Bool(bool)`, `Text(String)`. Matches the primitive types commonly passed between Lua callbacks and the AI subsystem.

#### `ai::steering::CombineMode`

How multiple steering behaviors are combined: `Weighted` (sum all forces × weight, truncate to max_force) or `Priority` (use first non-zero force). Parsed from `"weighted"` / `"priority"`.

#### `ai::steering::SteeringBehaviorType`

All concrete steering behavior variants: `Seek`, `Flee` (with panic distance), `Arrive` (with slowing radius), `Wander` (projected circle), `Pursue` (intercept prediction), `Evade` (threat prediction), `Flock` (separation + alignment + cohesion). Each carries its parameters and a `SteeringBase`.

#### `ai::squad::FormationType`

Formation shapes for squad positioning: `None`, `Line`, `Wedge`, `Circle`, `Column`. Parsed from lowercase Lua strings.

#### `ai::utility_ai::ResponseCurve`

Mathematical function shapes for response curves: `Linear` (p1×x+p2), `Quadratic` (p1×x²+p2×x+p3), `Logistic` (S-curve), `Logit` (inverse sigmoid), `Step` (hard threshold).

## Lua API

The full Lua-facing surface is registered in `src/lua_api/ai_api.rs` under the `lurek.ai` namespace. The API exposes 19 factory functions for creating AI objects and 10 UserData types with method APIs.

### Factory Functions (`lurek.ai.*`)

| Function | Returns | Description |
|----------|---------|-------------|
| `newWorld()` | `AIWorld` | Creates a new AI world container |
| `newBlackboard()` | `Blackboard` | Creates a standalone blackboard |
| `newStateMachine()` | `StateMachine` | Creates a new finite state machine |
| `newBehaviorTree()` | `BehaviorTree` | Creates a new behavior tree |
| `newSelector()` | `BTNode` | Creates a BT selector composite |
| `newSequence()` | `BTNode` | Creates a BT sequence composite |
| `newParallel(successPolicy?, failurePolicy?)` | `BTNode` | Creates a BT parallel composite |
| `newInverter()` | `BTNode` | Creates a BT inverter decorator |
| `newRepeater(count?)` | `BTNode` | Creates a BT repeater decorator |
| `newSucceeder()` | `BTNode` | Creates a BT succeeder decorator |
| `newAction(callback)` | `BTNode` | Creates a BT action leaf |
| `newCondition(callback)` | `BTNode` | Creates a BT condition leaf |
| `newSteeringManager()` | `SteeringManager` | Creates a steering behavior manager |
| `newQLearner(stateCount, actionCount)` | `QLearner` | Creates a tabular Q-learner |
| `newUtilityAI()` | `UtilityAI` | Creates a utility AI evaluator |
| `newGOAPPlanner()` | `GOAPPlanner` | Creates a GOAP planning solver |
| `newInfluenceMap(width, height, cellSize)` | `InfluenceMap` | Creates a multi-layer influence map grid |
| `newSquad(name)` | `Squad` | Creates a named squad |
| `newCommandQueue()` | `CommandQueue` | Creates an RTS-style command queue |

### AIWorld Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addAgent(name)` | `Agent` | Registers a new named agent |
| `getAgent(name)` | `Agent?` | Returns agent handle by name |
| `removeAgent(agent)` | — | Removes an agent by handle |
| `getAgentCount()` | `integer` | Number of registered agents |
| `getGlobalBlackboard()` | `Blackboard` | Snapshot of the world blackboard |
| `update(dt)` | — | Advances all agents by dt seconds |

### Agent Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getName()` | `string` | Agent's registered name |
| `setPosition(x, y)` | — | Sets world-space position |
| `getPosition()` | `number, number` | Current position |
| `setVelocity(x, y)` | — | Sets velocity vector |
| `getVelocity()` | `number, number` | Current velocity |
| `setMaxSpeed(v)` | — | Sets maximum speed cap |
| `getMaxSpeed()` | `number` | Maximum speed cap |
| `setMaxForce(v)` | — | Sets maximum steering force |
| `getMaxForce()` | `number` | Maximum steering force |
| `setPriority(p)` | — | Sets scheduling priority |
| `getPriority()` | `integer` | Scheduling priority |
| `setDecisionModel(model)` | — | Sets active decision model |
| `getDecisionModel()` | `string` | Current decision model name |
| `addTag(tag)` | — | Adds a tag |
| `removeTag(tag)` | — | Removes a tag |
| `hasTag(tag)` | `boolean` | Tag membership check |
| `getBlackboard()` | `Blackboard` | Agent's local blackboard |

### Blackboard Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `setNumber(key, value)` | — | Stores a number |
| `getNumber(key, default?)` | `number` | Retrieves a number (default: 0) |
| `setBool(key, value)` | — | Stores a boolean |
| `getBool(key, default?)` | `boolean` | Retrieves a boolean (default: false) |
| `setString(key, value)` | — | Stores a string |
| `getString(key, default?)` | `string` | Retrieves a string (default: "") |
| `has(key)` | `boolean` | Checks existence (local + parent) |
| `remove(key)` | — | Removes a local entry |
| `clear()` | — | Removes all local entries |
| `getKeys()` | `table` | All local keys as a table |
| `getSize()` | `integer` | Number of local entries |

### StateMachine Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addState(name, opts)` | — | Registers a state with `{onEnter, onUpdate, onExit}` callbacks |
| `addTransition(from, to, guard?, priority?)` | — | Adds a guarded transition |
| `setInitialState(name)` | — | Sets the initial state |
| `getCurrentState()` | `string?` | Current state name |
| `forceState(name)` | — | Forces a state transition |
| `getTimeInState()` | `number` | Seconds in current state |

### BehaviorTree Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `setRoot(node)` | — | Sets the root BTNode |
| `getLastStatus()` | `string` | Status from last tick |

### BTNode Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addChild(child)` | — | Adds child (Selector/Sequence/Parallel only) |
| `getChildCount()` | `integer` | Number of direct children |
| `reset()` | — | Resets running-child memos and repeater counters |
| `setChild(child)` | — | Sets decorator child (Inverter/Repeater/Succeeder) |
| `setCount(n)` | — | Sets repeat count (Repeater only) |
| `getCount()` | `integer` | Repeat count |
| `setSuccessPolicy(policy)` | — | Sets Parallel success policy |
| `setFailurePolicy(policy)` | — | Sets Parallel failure policy |
| `getNodeType()` | `string` | Node type name |

### SteeringManager Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addSeek(tx, ty, weight?)` | — | Adds Seek behavior |
| `addFlee(tx, ty, panicDist?, weight?)` | — | Adds Flee behavior |
| `addArrive(tx, ty, slowingRadius?, weight?)` | — | Adds Arrive behavior |
| `addWander(radius?, dist?, jitter?, weight?)` | — | Adds Wander behavior |
| `addPursue(targetName?, weight?)` | — | Adds Pursue behavior |
| `addEvade(threatName?, weight?)` | — | Adds Evade behavior |
| `addFlock(neighborRadius?, sepW?, alignW?, cohW?, weight?)` | — | Adds Flock behavior |
| `getBehaviorCount()` | `integer` | Number of active behaviors |
| `setCombineMode(mode)` | — | Sets force combination mode |
| `getCombineMode()` | `string` | Current combination mode |
| `getLastSteering()` | `number, number` | Last computed force |
| `calculate(px, py, vx, vy, maxSpeed, maxForce, dt)` | `number, number` | Computes combined steering force |

### QLearner Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `chooseAction(state)` | `integer` | Epsilon-greedy action selection (1-based) |
| `bestAction(state)` | `integer` | Greedy-best action (1-based) |
| `learn(state, action, reward, nextState)` | — | Bellman Q-learning update (1-based) |
| `getQValue(state, action)` | `number` | Q-value for state-action pair (1-based) |
| `setQValue(state, action, value)` | — | Overwrites Q-value (1-based) |
| `endEpisode()` | — | Ends episode, applies epsilon decay |
| `getEpisodeCount()` | `integer` | Completed episodes |
| `getStateCount()` | `integer` | Number of states |
| `getActionCount()` | `integer` | Number of actions |
| `setLearningRate(v)` | — | Sets alpha |
| `getLearningRate()` | `number` | Current alpha |
| `setDiscountFactor(v)` | — | Sets gamma |
| `getDiscountFactor()` | `number` | Current gamma |
| `setExplorationRate(v)` | — | Sets epsilon |
| `getExplorationRate()` | `number` | Current epsilon |
| `setExplorationDecay(v)` | — | Sets epsilon decay multiplier |
| `getExplorationDecay()` | `number` | Current decay multiplier |
| `serialize()` | `string` | JSON-serializes Q-table |
| `deserialize(json)` | — | Restores Q-table from JSON |

### UtilityAI Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addAction(name, scorer, weight?)` | — | Adds a scored action |
| `evaluate()` | `string?` | Evaluates all actions, returns best name |
| `getActionCount()` | `integer` | Number of registered actions |
| `getLastAction()` | `string?` | Name of last chosen action |

### GOAPPlanner Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addAction(name, cost?, callback?)` | — | Adds a GOAP action |
| `setPrecondition(actionName, key, value)` | — | Sets a boolean precondition |
| `setEffect(actionName, key, value)` | — | Sets a boolean effect |
| `addGoal(name, priority?)` | — | Adds a planning goal |
| `setGoalState(goalName, key, value)` | — | Sets a boolean goal condition |
| `plan(worldState, maxDepth?)` | `table` | Runs A★ planning, returns action sequence |
| `getActionCount()` | `integer` | Number of actions |
| `getGoalCount()` | `integer` | Number of goals |

### InfluenceMap Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `addLayer(name)` | — | Adds a named influence layer |
| `hasLayer(name)` | `boolean` | Checks if layer exists |
| `setInfluence(layer, x, y, value)` | — | Sets influence at cell (1-based) |
| `getInfluence(layer, x, y)` | `number` | Gets influence at cell (1-based) |
| `stampInfluence(layer, wx, wy, radius, value, falloff?)` | — | Radial stamp in world-space |
| `propagate(layer, momentum?)` | — | Propagates influence values |
| `decay(layer, factor)` | — | Multiplies all values by decay factor |
| `clearLayer(layer)` | — | Clears a layer |
| `clearAll()` | — | Clears all layers |
| `getMaxPosition(layer)` | `number, number` | World-space position of maximum |
| `getMinPosition(layer)` | `number, number` | World-space position of minimum |
| `queryRect(layer, wx, wy, ww, wh)` | `number` | Summed influence in rectangle |
| `blend(layerA, weightA, layerB, weightB, dest)` | — | Blends two layers into destination |
| `getWidth()` | `integer` | Grid width |
| `getHeight()` | `integer` | Grid height |
| `getCellSize()` | `number` | Cell size in world units |

### Squad Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getName()` | `string` | Squad name |
| `addMember(name)` | — | Adds an agent by name |
| `removeMember(name)` | — | Removes an agent by name |
| `getMemberCount()` | `integer` | Number of members |
| `getMembers()` | `table` | Member names as table |
| `setLeader(name)` | — | Sets the squad leader |
| `getLeader()` | `string?` | Leader name |
| `setFormation(ftype, spacing?)` | — | Sets formation type and spacing |
| `getFormation()` | `string` | Current formation type name |
| `getFormationSpacing()` | `number` | Formation spacing in world units |
| `getFormationPosition(memberIdx, leaderX, leaderY)` | `number, number` | World-space position for member (1-based) |
| `getBlackboard()` | `Blackboard` | Squad's shared blackboard |

### CommandQueue Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `enqueue(kind, callback, opts?)` | — | Appends command to back |
| `pushFront(kind, callback, opts?)` | — | Inserts at front (interrupt) |
| `replace(kind, callback, opts?)` | — | Clears queue, enqueues one command |
| `cancelCurrent()` | `boolean` | Cancels front command if interruptible |
| `clear()` | — | Discards all queued commands |
| `getCount()` | `integer` | Number of queued commands |
| `isEmpty()` | `boolean` | Whether queue is empty |
| `getCurrentType()` | `string?` | Kind of front command |
| `getCurrentTarget()` | `number, number` | Target coordinates of front command |

## Lua Examples

### FSM-based NPC patrol with steering

```lua
function lurek.init()
    world = lurek.ai.newWorld()
    local agent = world:addAgent("guard")
    agent:setPosition(100, 200)
    agent:setMaxSpeed(80)
    agent:setDecisionModel("fsm+steering")

    -- FSM: patrol ↔ chase
    local fsm = lurek.ai.newStateMachine()
    fsm:addState("patrol", {
        onEnter = function(a) print(a:getName() .. " now patrolling") end,
        onUpdate = function(a, dt) end
    })
    fsm:addState("chase", {
        onEnter = function(a) print(a:getName() .. " chasing!") end
    })
    fsm:addTransition("patrol", "chase", function(a, dt)
        return a:getBlackboard():getBool("enemy_spotted")
    end, 10)
    fsm:setInitialState("patrol")

    -- Steering: seek the patrol waypoint
    steering = lurek.ai.newSteeringManager()
    steering:addSeek(400, 300, 1.0)
end

function lurek.process(dt)
    world:update(dt)
end
```

### GOAP planning for a woodcutter NPC

```lua
local planner = lurek.ai.newGOAPPlanner()

planner:addAction("chop_tree", 2.0)
planner:setPrecondition("chop_tree", "has_axe", true)
planner:setEffect("chop_tree", "has_wood", true)

planner:addAction("craft_axe", 4.0)
planner:setPrecondition("craft_axe", "has_iron", true)
planner:setEffect("craft_axe", "has_axe", true)

planner:addAction("mine_iron", 3.0)
planner:setEffect("mine_iron", "has_iron", true)

planner:addGoal("get_wood", 1.0)
planner:setGoalState("get_wood", "has_wood", true)

local plan = planner:plan({ has_axe = false, has_iron = false, has_wood = false }, 10)
-- plan = {"mine_iron", "craft_axe", "chop_tree"}
for i, action in ipairs(plan) do
    print(i, action)
end
```

### Q-learner training loop

```lua
local ql = lurek.ai.newQLearner(16, 4)  -- 16 states, 4 actions
ql:setLearningRate(0.2)
ql:setExplorationRate(0.3)

for episode = 1, 1000 do
    local state = 1
    for step = 1, 50 do
        local action = ql:chooseAction(state)
        local next_state = (state + action - 1) % 16 + 1
        local reward = (next_state == 16) and 10.0 or -0.1
        ql:learn(state, action, reward, next_state)
        state = next_state
        if state == 16 then break end
    end
    ql:endEpisode()
end

-- Save trained policy
local json = ql:serialize()
lurek.fs.write("ai_policy.json", json)
```

## Item Summary

| Kind       | Count  |
|------------|--------|
| `struct`   | 18     |
| `enum`     | 9      |
| `type`     | 1      |
| `fn`       | 97     |
| **Total**  | **125** |

## References

| Module         | Relationship | Notes                                                        |
|----------------|--------------|--------------------------------------------------------------|
| `math`         | Imports from | Used indirectly for Vec2-like operations (tuples used instead) |
| `engine`       | Imports from | Uses log message constants (`BB01`, `CQ01`, `FN01`, `GP01`)  |
| `pathfinding`  | Imports from | Re-exports `FlowField`, `Cell`, `PathGrid`, `InfluenceMap`   |
| `lua_api`      | Imported by  | `src/lua_api/ai_api.rs` binds all types to Lua               |
| `mlua`         | Depends on   | `RegistryKey` stores Lua callbacks in FSM, BT, GOAP, utility AI, commands |

**Similar modules**: The `pathfinding` module provides the raw grid algorithms (A★, flow fields, influence maps) that this module re-exports and wraps for AI use. The `ai` module adds agent decision-making (FSM, BT, steering, Q-learning, utility AI, GOAP) on top of pathfinding primitives.

## Notes

- **All AI is pure CPU math** — no GPU, audio, or window access. Every subsystem runs headlessly in tests.
- **Lua callbacks via RegistryKey** — FSM state callbacks, BT leaf callbacks, GOAP action callbacks, utility AI scorers, and command queue tick callbacks are all stored as `mlua::RegistryKey` references. They are called by the AIWorld update loop, not by the AI types themselves.
- **1-based Lua indices** — QLearner `chooseAction`, `bestAction`, `learn`, `getQValue`, `setQValue` all use 1-based state/action indices at the Lua boundary, internally converting to 0-based via `saturating_sub(1)`. InfluenceMap cell coordinates are also 1-based in Lua.
- **Blackboard cloning** — `getBlackboard()` on Agent and Squad returns a cloned snapshot, not a live reference. Mutations to the returned blackboard do not affect the agent's actual blackboard. This is a Lua API limitation of the current design.
- **No per-frame allocation** — Vectors for agents, behaviors, and commands are grown at creation time. Steady-state update loops do not allocate.
- **GOAP search limits** — The planner enforces a hard limit of 10,000 A★ iterations and a configurable `max_depth` (default 10) to prevent runaway computation.
- **QLearner serialization** — The Q-table can be serialized to JSON (`serialize()`) and restored (`deserialize()`), enabling save/load of trained policies between sessions.
- **Steering multi-agent behaviors** — `Pursue`, `Evade`, and `Flock` return `(0, 0)` from `SteeringBehaviorType::calculate()` because they need other agents' positions. These forces are computed at the `AIWorld` level during `update()`.
- **FormationType strings** — Formations are serialized to/from lowercase Lua strings: `"none"`, `"line"`, `"wedge"`, `"circle"`, `"column"`.
- **CommandQueue opts table** — `enqueue`, `pushFront`, and `replace` accept an optional table with `targetX`, `targetY`, `priority`, and `interruptible` fields.
- **Breaking change surface** — Renaming any `lurek.ai.new*` factory function or changing UserData method signatures will break Lua game scripts. The Q-learner's 1-based index convention is load-bearing.
