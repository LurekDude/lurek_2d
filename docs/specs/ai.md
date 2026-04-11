# `ai` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.ai` |
| **Source** | `src/ai/` |
| **Rust Tests** | `tests/rust/unit/ai_tests.rs`, `tests/rust/game/ai_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_ai.lua`, `tests/lua/golden/test_ai_golden.lua`, `tests/lua/integration/test_entity_ai.lua`, `tests/lua/integration/test_ai_physics.lua`, `tests/lua/integration/test_ai_pathfinding.lua`, `tests/lua/integration/test_ai_entity_scene.lua`, `tests/lua/stress/test_ai_stress.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `ai` module is Lurek2D's gameplay decision-making toolkit. It brings together multiple AI paradigms including finite state machines, behavior trees, steering, GOAP, utility AI, Q-learning, squad formations, command queues, and blackboard-driven coordination so different game genres can pick the right model instead of being forced into one framework.

It exists to keep decision logic, action scoring, and agent coordination separate from entities, physics, and scripts that only want to consume the results. The module owns the reusable AI algorithms and shared data models; the Lua bridge exposes them, and game code decides how to wire them into actual actors.

It intentionally does not own pathfinding algorithms at the implementation level, rendering beyond optional debug helpers, or any authoritative scene or entity storage. It can reference pathfinding data and provide debug output, but world simulation and movement application stay outside the module.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.ai.* (Lua API — src/lua_api/ai_api.rs)
    |
    v
src/ai/mod.rs
    |- agent.rs - agent
    |- behavior_tree.rs - behavior_tree
    |- blackboard.rs - blackboard
    |- command_queue.rs - command_queue
    |- fsm.rs - fsm
    |- goap.rs - goap
    |- qlearner.rs - qlearner
    |- render.rs - render
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `agent.rs` | Defines the core `Agent` record and the top-level decision-model selection enum used to attach different AI styles to an actor. |
| `behavior_tree.rs` | Implements behavior tree nodes, statuses, composite policies, and the execution model for hierarchical decision logic. |
| `blackboard.rs` | Provides a hierarchical key-value blackboard for local and shared AI state. |
| `command_queue.rs` | Implements queued AI commands with priorities, interruptibility, and callback integration. |
| `fsm.rs` | Defines finite state machine structures, state callbacks, and guarded transitions. |
| `goap.rs` | Implements GOAP planning primitives and planner search over world-state facts. |
| `mod.rs` | Declares the AI submodules and re-exports the main decision-model and support types, including selected pathfinding-facing types. |
| `qlearner.rs` | Provides a tabular Q-learning implementation for trainable action selection. |
| `render.rs` | Generates debug render output for AI state, plans, or decision structures when visual inspection is needed. |
| `squad.rs` | Defines squad grouping, formation handling, and shared blackboard coordination. |
| `steering.rs` | Implements movement steering behaviors such as seek, flee, arrive, wander, pursue, evade, and flocking. |
| `utility_ai.rs` | Implements utility-based action scoring with considerations and response curves. |
| `world.rs` | Defines `AIWorld`, the central registry and coordination surface for agents and shared AI state. |

---

## Submodules

### `ai::agent`

Defines the core `Agent` record and the top-level decision-model selection enum used to attach different AI styles to an actor.

- **`DecisionModel`** (enum): Controls which AI subsystems are ticked for an agent during `AIWorld::update`.
- **`Agent`** (struct): An autonomous AI agent with kinematic state and pluggable decision subsystems.

### `ai::behavior_tree`

Implements behavior tree nodes, statuses, composite policies, and the execution model for hierarchical decision logic.

- **`BTStatus`** (enum): Execution status returned by every behavior tree node after a tick.
- **`ParallelPolicy`** (enum): Policy for determining when a Parallel composite node succeeds or fails.
- **`BTNode`** (enum): A node in the behavior tree.
- **`BehaviorTree`** (struct): Root container for a behavior tree instance.

### `ai::blackboard`

Provides a hierarchical key-value blackboard for local and shared AI state.

- **`BlackboardValue`** (enum): A typed value stored in a blackboard slot.
- **`Blackboard`** (struct): A hierarchical key-value store for sharing named data between AI subsystems.

### `ai::command_queue`

Implements queued AI commands with priorities, interruptibility, and callback integration.

- **`Command`** (struct): A single RTS unit command with metadata and a Lua tick callback.
- **`CommandQueue`** (struct): A FIFO queue of [`Command`] entries for sequential unit action scheduling.

### `ai::fsm`

Defines finite state machine structures, state callbacks, and guarded transitions.

- **`StateCallbacks`** (struct): Lua lifecycle hooks for a single FSM state.
- **`Transition`** (struct): A directed edge in the FSM state graph with an optional guard predicate.
- **`StateMachine`** (struct): A finite state machine that manages named states with lifecycle callbacks and priority-ordered guarded transitions.

### `ai::goap`

Implements GOAP planning primitives and planner search over world-state facts.

- **`GOAPAction`** (struct): A single GOAP action with boolean preconditions and effects.
- **`GOAPGoal`** (struct): A planning goal expressed as a desired boolean world state.
- **`GOAPPlanner`** (struct): A★ planner that finds optimal action sequences to satisfy goals over boolean world state.

### `ai::qlearner`

Provides a tabular Q-learning implementation for trainable action selection.

- **`QLearner`** (struct): Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning.

### `ai::render`

Generates debug render output for AI state, plans, or decision structures when visual inspection is needed.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `ai::squad`

Defines squad grouping, formation handling, and shared blackboard coordination.

- **`FormationType`** (enum): Formation shapes for squad positioning.
- **`Squad`** (struct): A named group of agents with formation positioning and shared state.

### `ai::steering`

Implements movement steering behaviors such as seek, flee, arrive, wander, pursue, evade, and flocking.

- **`Force`** (type): 2D force vector (fx, fy).
- **`CombineMode`** (enum): Determines how multiple active steering behaviors are combined into a single resultant force applied to the agent.
- **`SteeringBase`** (struct): Shared parameters common to all steering behavior instances.
- **`SteeringBehaviorType`** (enum): All concrete steering behavior types supported by the AI system.
- **`SteeringManager`** (struct): Manages a list of steering behaviors and combines their forces each frame.

### `ai::utility_ai`

Implements utility-based action scoring with considerations and response curves.

- **`ResponseCurve`** (enum): Mathematical function shapes for transforming raw consideration inputs into normalized scores.
- **`Consideration`** (struct): A single evaluation axis within a utility action's scoring function.
- **`UAAction`** (struct): A candidate action in the utility AI decision space.
- **`UtilityAI`** (struct): Multi-axis utility scorer that evaluates candidate actions and chooses the one with the highest composite score.

### `ai::world`

Defines `AIWorld`, the central registry and coordination surface for agents and shared AI state.

- **`AIWorld`** (struct): Top-level AI container that owns agents and provides global shared state.

---

## Key Types

### Public Types

#### `AIWorld`

The central AI registry.

#### `Agent`

One autonomous actor record with movement state, limits, selected decision model, and local blackboard.

#### `DecisionModel`

Chooses which AI paradigm an `Agent` is currently using.

#### `StateMachine`

Finite state machine with named states and guarded transitions.

#### `StateCallbacks`

Bundles per-state lifecycle callbacks for FSM behavior.

#### `Transition`

One guarded edge between FSM states.

#### `BehaviorTree`

Hierarchical decision structure for composite, decorator, and leaf AI behavior.

#### `BTNode`

The behavior-tree node enum describing the actual tree shape.

#### `BTStatus`

The execution result returned by behavior-tree steps.

#### `ParallelPolicy`

Defines how parallel behavior-tree nodes determine success or failure.

#### `Blackboard`

Hierarchical key-value state store used for AI coordination and memory.

#### `BlackboardValue`

The value enum stored in a `Blackboard`.

#### `CommandQueue`

Ordered queue of AI commands waiting to run or interrupt one another.

#### `Command`

One queued AI command with priority and callback information.

#### `GOAPPlanner`

Planner that searches action sequences over world-state facts.

#### `GOAPAction`

One GOAP action with preconditions and effects.

#### `GOAPGoal`

Desired end-state description for GOAP planning.

#### `SteeringManager`

Combines steering behaviors to produce movement intent.

#### `SteeringBehaviorType`

Names the available steering behaviors.

#### `CombineMode`

Controls how multiple steering behaviors are merged.

#### `UtilityAI`

Scores candidate actions using considerations and response curves.

#### `Consideration`

One input dimension used in utility scoring.

#### `ResponseCurve`

The curve applied to a consideration value before scoring.

#### `UAAction`

A candidate action inside a utility-AI model.

#### `QLearner`

Tabular reinforcement learner for action value estimation.

#### `Squad`

Group-level AI container for formations and shared decisions.

#### `FormationType`

Identifies the supported squad formation patterns.

---

## Lua API

Exposed under `lurek.ai.*` by `src/lua_api/ai_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.ai.newWorld` | Creates a new AI world container. |
| `lurek.ai.newBlackboard` | Creates a new standalone blackboard. |
| `lurek.ai.newStateMachine` | Creates a new finite state machine. |
| `lurek.ai.newBehaviorTree` | Creates a new behavior tree. |
| `lurek.ai.newSelector` | Creates a BT selector node. |
| `lurek.ai.newSequence` | Creates a BT sequence node. |
| `lurek.ai.newParallel` | Creates a BT parallel node with optional policies. |
| `lurek.ai.newInverter` | Creates a BT inverter decorator. |
| `lurek.ai.newRepeater` | Creates a BT repeater decorator. |
| `lurek.ai.newSucceeder` | Creates a BT succeeder decorator. |
| `lurek.ai.newAction` | Creates a BT action leaf with a Lua callback. |
| `lurek.ai.newCondition` | Creates a BT condition leaf with a Lua predicate. |
| `lurek.ai.newSteeringManager` | Creates a new steering behavior manager. |
| `lurek.ai.newQLearner` | Creates a tabular Q-learner. |
| `lurek.ai.newUtilityAI` | Creates a new utility AI evaluator. |
| `lurek.ai.newGOAPPlanner` | Creates a new GOAP planning solver. |
| `lurek.ai.newInfluenceMap` | Creates a multi-layer influence map grid. |
| `lurek.ai.newSquad` | Creates a named squad for formation positioning. |
| `lurek.ai.newCommandQueue` | Creates an RTS-style command queue. |

### `AIWorld` Methods

| Method | Description |
|--------|-------------|
| `aiworld:addAgent(...)` | Registers a new named agent and returns its handle. |
| `aiworld:getAgent(...)` | Returns the agent handle for the given name, or nil. |
| `aiworld:removeAgent(...)` | Removes an agent by its userdata handle. |
| `aiworld:getAgentCount(...)` | Returns the number of registered agents. |
| `aiworld:getGlobalBlackboard(...)` | Returns a snapshot of the world-level blackboard. |
| `aiworld:update(...)` | Advances all agents by dt seconds. |
| `aiworld:type(...)` | Returns the type name of this object. |
| `aiworld:typeOf(...)` | Returns true if this object is of the given type. |

### `Agent` Methods

| Method | Description |
|--------|-------------|
| `agent:getName(...)` | Returns the agent's registered name. |
| `agent:setPosition(...)` | Sets the agent's world-space position. |
| `agent:getPosition(...)` | Returns the agent's current position. |
| `agent:setVelocity(...)` | Sets the agent's velocity vector. |
| `agent:getVelocity(...)` | Returns the agent's current velocity. |
| `agent:setMaxSpeed(...)` | Sets the maximum speed cap. |
| `agent:getMaxSpeed(...)` | Returns the maximum speed cap. |
| `agent:setMaxForce(...)` | Sets the maximum steering force cap. |
| `agent:getMaxForce(...)` | Returns the maximum steering force cap. |
| `agent:setPriority(...)` | Sets the scheduling priority (higher = earlier). |
| `agent:getPriority(...)` | Returns the agent's scheduling priority. |
| `agent:setDecisionModel(...)` | Sets the active decision model. |
| `agent:getDecisionModel(...)` | Returns the name of the current decision model. |
| `agent:addTag(...)` | Adds a tag to this agent. |
| `agent:removeTag(...)` | Removes a tag from this agent. |
| `agent:hasTag(...)` | Returns true if the agent has the given tag. |
| `agent:getBlackboard(...)` | Returns the agent's local blackboard. |
| `agent:type(...)` | Returns the type name of this object. |
| `agent:typeOf(...)` | Returns true if this object is of the given type. |

### `BTNode` Methods

| Method | Description |
|--------|-------------|
| `btnode:addChild(...)` | Adds a child node (Selector, Sequence, or Parallel only). |
| `btnode:getChildCount(...)` | Returns the number of direct children. |
| `btnode:reset(...)` | Resets all running-child memos and repeater counters. |
| `btnode:setChild(...)` | Sets the single child of a decorator node. |
| `btnode:setCount(...)` | Sets the repeat count for a Repeater node. |
| `btnode:getCount(...)` | Returns the repeat count, or 0 if not a Repeater. |
| `btnode:setSuccessPolicy(...)` | Sets the success policy for a Parallel node. |
| `btnode:setFailurePolicy(...)` | Sets the failure policy for a Parallel node. |
| `btnode:getNodeType(...)` | Returns the node type as a string. |
| `btnode:type(...)` | Returns the type name of this object. |
| `btnode:typeOf(...)` | Returns true if this object is of the given type. |

### `BehaviorTree` Methods

| Method | Description |
|--------|-------------|
| `behaviortree:setRoot(...)` | Sets the root node of this behavior tree. |
| `behaviortree:getLastStatus(...)` | Returns the status from the last tick. |
| `behaviortree:type(...)` | Returns the type name of this object. |
| `behaviortree:typeOf(...)` | Returns true if this object is of the given type. |

### `Blackboard` Methods

| Method | Description |
|--------|-------------|
| `blackboard:setNumber(...)` | Stores a number under the given key. |
| `blackboard:setBool(...)` | Stores a boolean under the given key. |
| `blackboard:setString(...)` | Stores a string under the given key. |
| `blackboard:has(...)` | Returns true if a value exists under the key. |
| `blackboard:remove(...)` | Removes the entry at key. |
| `blackboard:clear(...)` | Removes all local entries. |
| `blackboard:getKeys(...)` | Returns all local keys as a table. |
| `blackboard:getSize(...)` | Returns the number of local entries. |
| `blackboard:type(...)` | Returns the type name of this object. |
| `blackboard:typeOf(...)` | Returns true if this object is of the given type. |

### `CommandQueue` Methods

| Method | Description |
|--------|-------------|
| `commandqueue:cancelCurrent(...)` | Cancels the front command if it is interruptible. |
| `commandqueue:clear(...)` | Discards all queued commands. |
| `commandqueue:getCount(...)` | Returns the number of queued commands. |
| `commandqueue:isEmpty(...)` | Returns true if there are no queued commands. |
| `commandqueue:getCurrentType(...)` | Returns the kind of the front command, or nil. |
| `commandqueue:getCurrentTarget(...)` | Returns the target coordinates of the front command. |
| `commandqueue:type(...)` | Returns the type name of this object. |
| `commandqueue:typeOf(...)` | Returns true if this object is of the given type. |

### `GOAPPlanner` Methods

| Method | Description |
|--------|-------------|
| `goapplanner:getActionCount(...)` | Returns the number of registered actions. |
| `goapplanner:getGoalCount(...)` | Returns the number of registered goals. |
| `goapplanner:type(...)` | Returns the type name of this object. |
| `goapplanner:typeOf(...)` | Returns true if this object is of the given type. |

### `InfluenceMap` Methods

| Method | Description |
|--------|-------------|
| `influencemap:addLayer(...)` | Adds a named influence layer. |
| `influencemap:hasLayer(...)` | Returns true if the named layer exists. |
| `influencemap:decay(...)` | Multiplies all influences by a decay factor. |
| `influencemap:clearLayer(...)` | Clears all influence in a layer. |
| `influencemap:clearAll(...)` | Clears all layers. |
| `influencemap:getMaxPosition(...)` | Returns the world-space position of the maximum value. |
| `influencemap:getMinPosition(...)` | Returns the world-space position of the minimum value. |
| `influencemap:getWidth(...)` | Returns the grid width. |
| `influencemap:getHeight(...)` | Returns the grid height. |
| `influencemap:getCellSize(...)` | Returns the cell size in world units. |
| `influencemap:type(...)` | Returns the type name of this object. |
| `influencemap:typeOf(...)` | Returns true if this object is of the given type. |

### `QLearner` Methods

| Method | Description |
|--------|-------------|
| `qlearner:chooseAction(...)` | Selects an action using epsilon-greedy policy (1-based). |
| `qlearner:bestAction(...)` | Returns the greedy-best action for the state (1-based). |
| `qlearner:getQValue(...)` | Returns the Q-value for a state-action pair (1-based). |
| `qlearner:endEpisode(...)` | Ends the current episode, applying epsilon decay. |
| `qlearner:getEpisodeCount(...)` | Returns the number of completed episodes. |
| `qlearner:getStateCount(...)` | Returns the number of discrete states. |
| `qlearner:getActionCount(...)` | Returns the number of discrete actions. |
| `qlearner:setLearningRate(...)` | Sets the learning rate alpha. |
| `qlearner:getLearningRate(...)` | Returns the current learning rate. |
| `qlearner:setDiscountFactor(...)` | Sets the discount factor gamma. |
| `qlearner:getDiscountFactor(...)` | Returns the current discount factor. |
| `qlearner:setExplorationRate(...)` | Sets the exploration rate epsilon. |
| `qlearner:getExplorationRate(...)` | Returns the current exploration rate. |
| `qlearner:setExplorationDecay(...)` | Sets the epsilon decay multiplier. |
| `qlearner:getExplorationDecay(...)` | Returns the epsilon decay multiplier. |
| `qlearner:serialize(...)` | Serializes the Q-table to a JSON string. |
| `qlearner:deserialize(...)` | Restores the Q-table from a JSON string. |
| `qlearner:type(...)` | Returns the type name of this object. |
| `qlearner:typeOf(...)` | Returns true if this object is of the given type. |

### `Squad` Methods

| Method | Description |
|--------|-------------|
| `squad:getName(...)` | Returns the squad name. |
| `squad:addMember(...)` | Adds an agent by name to this squad. |
| `squad:removeMember(...)` | Removes an agent by name from this squad. |
| `squad:getMemberCount(...)` | Returns the number of squad members. |
| `squad:getMembers(...)` | Returns the member names as a table. |
| `squad:setLeader(...)` | Sets the squad leader by name. |
| `squad:getLeader(...)` | Returns the leader name, or nil. |
| `squad:getFormation(...)` | Returns the current formation type name. |
| `squad:getFormationSpacing(...)` | Returns the formation spacing in world units. |
| `squad:getBlackboard(...)` | Returns the squad's shared blackboard. |
| `squad:type(...)` | Returns the type name of this object. |
| `squad:typeOf(...)` | Returns true if this object is of the given type. |

### `StateMachine` Methods

| Method | Description |
|--------|-------------|
| `statemachine:addState(...)` | Registers a named state with optional lifecycle callbacks. |
| `statemachine:setInitialState(...)` | Sets the initial state. |
| `statemachine:getCurrentState(...)` | Returns the current state name, or nil. |
| `statemachine:forceState(...)` | Forces a transition to the named state. |
| `statemachine:getTimeInState(...)` | Returns seconds spent in the current state. |
| `statemachine:type(...)` | Returns the type name of this object. |
| `statemachine:typeOf(...)` | Returns true if this object is of the given type. |

### `SteeringManager` Methods

| Method | Description |
|--------|-------------|
| `steeringmanager:getBehaviorCount(...)` | Returns the number of active behaviors. |
| `steeringmanager:setCombineMode(...)` | Sets the force combination mode. |
| `steeringmanager:getCombineMode(...)` | Returns the current combination mode. |
| `steeringmanager:getLastSteering(...)` | Returns the last computed steering force. |
| `steeringmanager:type(...)` | Returns the type name of this object. |
| `steeringmanager:typeOf(...)` | Returns true if this object is of the given type. |

### `UtilityAI` Methods

| Method | Description |
|--------|-------------|
| `utilityai:evaluate(...)` | Evaluates all actions and returns the best action name, or nil. |
| `utilityai:getActionCount(...)` | Returns the number of registered actions. |
| `utilityai:getLastAction(...)` | Returns the name of the last chosen action, or nil. |
| `utilityai:type(...)` | Returns the type name of this object. |
| `utilityai:typeOf(...)` | Returns true if this object is of the given type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.ai.
if lurek.ai then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 19 |
| `enum` | 9 |
| `fn` (Lua API) | 144 |
| **Total** | **172** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/ai/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
