# `src/ai/` — Game AI Systems

## Purpose

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
  │     └── InfluenceMap ─ named layers with stamp/propagate/decay
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

### How It Works

The `AIWorld` acts as an owner and coordinator rather than a dispatcher — it
holds all agents and their decision models, but Lua drives the tick by calling
`aiWorld:update(dt)` once per frame.  Each agent's decision model is evaluated
in registration order; the `SteeringManager` velocity is applied after all
steering behaviours have contributed their weighted forces.

The five decision models share no common base trait — they are distinct Rust
structs associated with an agent by an enum tag.  This avoids monomorphisation
overhead and keeps switch dispatch fast for the common case where most agents
in a given scene use the same model.

Pathfinding grids are stored as independent `PathGrid` resources inside
`AIWorld`.  Flow fields go further — a single BFS generates a direction field
for the entire grid that all agents in the same group can sample
simultaneously, reducing per-frame pathfinding cost from O(agents × grid) to
O(grid).

### Dependency Direction

```
ai/ ──────► math::Vec2 (for positions/velocities)
```

**Leaf module** — depends only on math types and standard library.
No other Luna2D module dependencies (no engine, no graphics, no physics).

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports all 15 public types from sub-modules. Single import point.

**15 lines** — pure re-exports, no logic.

---

### `world.rs` — `AIWorld` (Central Registry)

**~99 lines** | Container for all AI agents with name-based lookup.

#### Struct: `AIWorld`

```rust
pub struct AIWorld {
    agents: Vec<Agent>,
    name_index: HashMap<String, usize>,
    global_blackboard: Blackboard,
}
```

Methods: `new`, `add_agent`, `remove_agent`, `get_agent`/`get_agent_mut`,
`find_agent_by_name`, `agent_count`, `global_blackboard`/`global_blackboard_mut`.

**Design**: Name index kept in sync with the agents vector for O(1) lookup by name.

---

### `agent.rs` — `Agent` (AI Entity)

**~96 lines** | Represents one AI-controlled entity with a selectable decision model.

#### Struct: `Agent`

```rust
pub struct Agent {
    pub name: String,
    pub x: f32,
    pub y: f32,
    pub speed: f32,
    pub target_x: f32,
    pub target_y: f32,
    pub health: f32,
    pub max_health: f32,
    pub team: u32,
    pub active: bool,
    pub decision_model: DecisionModel,
}
```

#### Enum: `DecisionModel`

```
Fsm ────────── pure finite state machine
Bt ─────────── pure behavior tree
Steering ───── pure steering behaviors
FsmSteering ── FSM + steering combination
BtSteering ─── behavior tree + steering combination
```

---

### `behavior_tree.rs` — `BehaviorTree`

**~211 lines** | Classic behavior tree with 8 node types and tick-based evaluation.

#### Enum: `BTNode`

```
Selector(Vec<BTNode>) ──── try children until one succeeds (OR)
Sequence(Vec<BTNode>) ──── run children until one fails (AND)
Parallel(Vec<BTNode>, ParallelPolicy) ── run all, policy decides success
Inverter(Box<BTNode>) ──── negate child result
Repeater(Box<BTNode>, u32) ── repeat child N times
Succeeder(Box<BTNode>) ─── always return Success
Action(String) ──────────── named leaf action
Condition(String) ────────── named leaf condition
```

#### Enum: `BTStatus`

`Success | Failure | Running`

Methods: `new`, `tick` (recursive evaluation), `add_child`, `set_parallel_policy`.

**Design**: Actions/conditions are identified by string names — the Lua bridge maps
these to callback functions. Tree structure is data-driven and serializable.

---

### `fsm.rs` — `StateMachine`

**~112 lines** | Priority-sorted finite state machine with named states and transitions.

#### Struct: `StateMachine`

```rust
pub struct StateMachine {
    states: HashMap<String, StateCallbacks>,
    current_state: Option<String>,
    transitions: Vec<Transition>,
}
```

#### Struct: `Transition`

```rust
pub struct Transition {
    pub from: String,
    pub to: String,
    pub condition: String,
    pub priority: i32,
}
```

Methods: `new`, `add_state`, `set_state`, `get_state`, `add_transition`,
`check_transitions`, `update`. Transitions are priority-sorted (higher first).

---

### `steering.rs` — `SteeringManager`

**~343 lines** | Combines multiple steering behaviors into a single force vector.

#### Enum: `SteeringBehaviorType`

`Seek | Flee | Arrive | Wander | Pursue | Evade | Flock`

#### Struct: `SteeringManager`

Maintains a list of active behaviors with weights. Supports `CombineMode` for
how multiple forces are blended.

Methods: `new`, `add_behavior`, `remove_behavior`, `calculate` (produces combined
force vector), `set_max_force`, `set_max_speed`.

**Design**: Each behavior produces a Vec2 force. Forces are weighted and summed
(or truncated) based on the combine mode.

---

### `blackboard.rs` — `Blackboard` (Hierarchical KV Store)

**~158 lines** | Key-value store with parent chain for scoped data sharing.

#### Struct: `Blackboard`

```rust
pub struct Blackboard {
    data: HashMap<String, BlackboardValue>,
    parent: Option<Box<Blackboard>>,
}
```

#### Enum: `BlackboardValue`

`Number(f64) | Bool(bool) | Text(String)`

Methods: `new`, `with_parent`, `set`, `get` (walks parent chain), `has`, `remove`,
`clear`, `keys`, `len`.

**Design**: Parent chain enables hierarchical scoping — agent-level overrides
world-level defaults without copying.

---

### `goap.rs` — `GOAPPlanner` (Goal-Oriented Action Planning)

**~262 lines** | A* search over boolean state space to find action sequences
that satisfy goal conditions.

#### Key Types

| Type | Fields |
|------|--------|
| `GOAPAction` | `name`, `preconditions: HashMap<String, bool>`, `effects: HashMap<String, bool>`, `cost: f32` |
| `GOAPGoal` | `name`, `conditions: HashMap<String, bool>`, `priority: f32` |
| `GOAPPlanner` | `actions: Vec<GOAPAction>`, `state: HashMap<String, bool>` |

Methods: `new`, `add_action`, `set_state`, `plan(goal)` → `Option<Vec<String>>`.

**Design**: A* with max 10,000 iterations safety limit. State space is boolean-only
(keys map to true/false). Cost heuristic counts unsatisfied conditions.

---

### `utility_ai.rs` — `UtilityAI`

**~138 lines** | Scored action selection using response curves.

#### Enum: `ResponseCurve`

`Linear | Quadratic | Logistic | Logit | Step`

#### Key Types

| Type | Purpose |
|------|---------|
| `Consideration` | Input value + response curve + weight |
| `UAAction` | Name + Vec<Consideration> + base score |
| `UtilityAI` | Actions list, random threshold for tie-breaking |

Methods: `new`, `add_action`, `add_consideration`, `select_action` → best-scoring
action name.

---

### `pathgrid.rs` — `PathGrid` (A* Pathfinder)

**~291 lines** | Grid-based A* with octile heuristic, corner-cut prevention,
and line-of-sight path smoothing.

Methods: `new`, `set_walkable`, `is_walkable`, `find_path`, `find_path_smooth`
(LoS simplification), `set_cost`, `get_cost`.

**Design**: Octile heuristic (diagonal cost √2) for 8-directional movement.
Corner-cut prevention ensures paths don't clip through diagonal obstacles.

---

### `flowfield.rs` — `FlowField`

**~180 lines** | BFS-based flow field for group movement.

Methods: `new`, `calculate(target)`, `get_direction(x, y)` → Vec2.

**Design**: Single BFS from target fills a direction grid. All agents can then
query their local cell for movement direction — O(1) per agent instead of O(n·pathfind).

---

### `influence_map.rs` — `InfluenceMap`

**~280 lines** | Named layers with stamp/propagate/decay operations for spatial reasoning.

Methods: `new`, `add_layer`, `stamp`, `propagate`, `decay`, `query_rect`, `get_value`,
`clear_layer`.

**Design**: Multiple named layers allow different influence types (threat, resources,
territory) on the same grid. Propagation spreads values to neighbors; decay reduces
over time.

---

### `qlearner.rs` — `QLearner` (Tabular Q-Learning)

**~259 lines** | Tabular reinforcement learning with epsilon-greedy exploration.

Methods: `new`, `update(state, action, reward, next_state)` (Bellman equation),
`select_action(state)` (epsilon-greedy), `get_q_value`, `set_learning_rate`,
`set_discount_factor`, `set_epsilon`, `serialize`/`deserialize` (JSON).

**Design**: State-action pairs stored in a HashMap. Epsilon decays over time for
exploration→exploitation shift. Serialization enables save/load of trained policies.

---

### `squad.rs` — `Squad` (Formation Positioning)

**~105 lines** | Calculates formation positions for groups of agents.

#### Enum: `FormationType`

`Line | Wedge | Circle | Column`

Methods: `new`, `set_formation`, `get_positions(center, count)` → Vec<Vec2>.

**Design**: Pure geometry — given a center point and agent count, returns offset
positions in the chosen formation pattern.

---

### `command_queue.rs` — `CommandQueue`

**~92 lines** | Priority-sorted command buffer for sequential AI actions.

#### Struct: `Command`

```rust
pub struct Command {
    pub kind: String,
    pub callback: Option<String>,
    pub target_x: f32,
    pub target_y: f32,
    pub priority: i32,
    pub interruptible: bool,
}
```

Methods: `new`, `push`, `pop`, `peek`, `clear`, `len`, `is_empty`.

**Design**: Higher-priority commands execute first. Interruptible flag allows
urgent commands to preempt the current action.

---

## Cross-Cutting Concerns

### Thread Safety

All AI types are designed for single-threaded use from the Lua VM. No `Send`/`Sync`
bounds required. `QLearner` JSON serialization is synchronous.

### Error Handling

Most methods return concrete types (not `Result`). Invalid operations silently
return defaults (empty paths, zero vectors) rather than panicking — game AI should
degrade gracefully.

### Lua Integration

The Lua bridge lives in `src/lua_api/ai_api.rs` (~1160 lines), exposing 37 factory
functions under `luna.ai.*` with UserData wrappers for all AI types.

### Usage from Lua

```lua
-- Finite state machine
local fsm = luna.ai.newStateMachine()
fsm:addState("idle", { enter = on_idle_enter, update = on_idle_update })
fsm:addState("chase", { enter = on_chase_enter, update = on_chase_update })
fsm:addTransition("idle", "chase", "see_player")
fsm:setState("idle")

-- Pathfinding
local grid = luna.ai.newPathGrid(100, 100)
grid:setWalkable(5, 5, false)
local path = grid:findPath(0, 0, 99, 99)

-- Behavior tree
local tree = luna.ai.newBehaviorTree()
tree:setRoot(luna.ai.newSelector({
    luna.ai.newSequence({ luna.ai.newCondition("has_target"), luna.ai.newAction("attack") }),
    luna.ai.newAction("patrol")
}))
```
