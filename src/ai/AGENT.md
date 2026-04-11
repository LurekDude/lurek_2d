# ai

## Module Info
- Module name: `ai`
- Module group: `Feature Systems`
- Spec path: `docs/specs/ai.md`
- Lua API path(s): `src/lua_api/ai_api.rs`
- Rust test path(s): `tests/rust/unit/ai_tests.rs`, `tests/rust/game/ai_tests.rs`
- Lua test path(s): `tests/lua/unit/test_ai.lua`, `tests/lua/golden/test_ai_golden.lua`, `tests/lua/integration/test_entity_ai.lua`, `tests/lua/integration/test_ai_physics.lua`, `tests/lua/integration/test_ai_pathfinding.lua`, `tests/lua/integration/test_ai_entity_scene.lua`, `tests/lua/stress/test_ai_stress.lua`

## Module Purpose
The `ai` module is Lurek2D's gameplay decision-making toolkit. It brings together multiple AI paradigms including finite state machines, behavior trees, steering, GOAP, utility AI, Q-learning, squad formations, command queues, and blackboard-driven coordination so different game genres can pick the right model instead of being forced into one framework.

It exists to keep decision logic, action scoring, and agent coordination separate from entities, physics, and scripts that only want to consume the results. The module owns the reusable AI algorithms and shared data models; the Lua bridge exposes them, and game code decides how to wire them into actual actors.

It intentionally does not own pathfinding algorithms at the implementation level, rendering beyond optional debug helpers, or any authoritative scene or entity storage. It can reference pathfinding data and provide debug output, but world simulation and movement application stay outside the module.

## Files
- `mod.rs` - Declares the AI submodules and re-exports the main decision-model and support types, including selected pathfinding-facing types.
- `agent.rs` - Defines the core `Agent` record and the top-level decision-model selection enum used to attach different AI styles to an actor.
- `behavior_tree.rs` - Implements behavior tree nodes, statuses, composite policies, and the execution model for hierarchical decision logic.
- `blackboard.rs` - Provides a hierarchical key-value blackboard for local and shared AI state.
- `command_queue.rs` - Implements queued AI commands with priorities, interruptibility, and callback integration.
- `fsm.rs` - Defines finite state machine structures, state callbacks, and guarded transitions.
- `goap.rs` - Implements GOAP planning primitives and planner search over world-state facts.
- `qlearner.rs` - Provides a tabular Q-learning implementation for trainable action selection.
- `render.rs` - Generates debug render output for AI state, plans, or decision structures when visual inspection is needed.
- `squad.rs` - Defines squad grouping, formation handling, and shared blackboard coordination.
- `steering.rs` - Implements movement steering behaviors such as seek, flee, arrive, wander, pursue, evade, and flocking.
- `utility_ai.rs` - Implements utility-based action scoring with considerations and response curves.
- `world.rs` - Defines `AIWorld`, the central registry and coordination surface for agents and shared AI state.

## Key Types
- `AIWorld` - The central AI registry. It owns agents, shared blackboard access, and world-level coordination of AI state.
- `Agent` - One autonomous actor record with movement state, limits, selected decision model, and local blackboard.
- `DecisionModel` - Chooses which AI paradigm an `Agent` is currently using.
- `StateMachine` - Finite state machine with named states and guarded transitions.
- `StateCallbacks` - Bundles per-state lifecycle callbacks for FSM behavior.
- `Transition` - One guarded edge between FSM states.
- `BehaviorTree` - Hierarchical decision structure for composite, decorator, and leaf AI behavior.
- `BTNode` - The behavior-tree node enum describing the actual tree shape.
- `BTStatus` - The execution result returned by behavior-tree steps.
- `ParallelPolicy` - Defines how parallel behavior-tree nodes determine success or failure.
- `Blackboard` - Hierarchical key-value state store used for AI coordination and memory.
- `BlackboardValue` - The value enum stored in a `Blackboard`.
- `CommandQueue` - Ordered queue of AI commands waiting to run or interrupt one another.
- `Command` - One queued AI command with priority and callback information.
- `GOAPPlanner` - Planner that searches action sequences over world-state facts.
- `GOAPAction` - One GOAP action with preconditions and effects.
- `GOAPGoal` - Desired end-state description for GOAP planning.
- `SteeringManager` - Combines steering behaviors to produce movement intent.
- `SteeringBehaviorType` - Names the available steering behaviors.
- `CombineMode` - Controls how multiple steering behaviors are merged.
- `UtilityAI` - Scores candidate actions using considerations and response curves.
- `Consideration` - One input dimension used in utility scoring.
- `ResponseCurve` - The curve applied to a consideration value before scoring.
- `UAAction` - A candidate action inside a utility-AI model.
- `QLearner` - Tabular reinforcement learner for action value estimation.
- `Squad` - Group-level AI container for formations and shared decisions.
- `FormationType` - Identifies the supported squad formation patterns.
