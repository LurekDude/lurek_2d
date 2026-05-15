# ai

## General Info

- Module group: `Feature Systems`
- Source path: `src/ai/`
- Lua API path(s): `src/lua_api/ai_api.rs`
- Primary Lua namespace: `lurek.ai`
- Rust test path(s): tests/rust/unit/ai_tests.rs, tests/rust/game/ai_tests.rs
- Lua test path(s): tests/lua/unit/test_ai.lua, tests/lua/golden/test_ai_golden.lua, tests/lua/integration/test_ecs_ai.lua, tests/lua/integration/test_ai_physics.lua, tests/lua/integration/test_ai_pathfind.lua, tests/lua/integration/test_ai_ecs_scene.lua, tests/lua/stress/test_ai_stress.lua

## Summary

The `ai` module is Lurek2D's Feature Systems tier AI toolkit — a collection of 27 decoupled subsystems that can be used individually or composed through the central `AIWorld` / `Agent` framework. All computation is pure CPU math; there are no GPU, audio, or window dependencies, so every subsystem can run in headless unit tests without a graphics context.

**Core framework.** `AIWorld` is the top-level registry. It owns all `Agent` instances and a shared global `Blackboard`. Each `Agent` carries kinematic state (position, velocity, max speed, max force), a `DecisionModel` enum selecting the active AI paradigm, and a local `Blackboard` that chains to the world-level blackboard for hierarchical key-value lookup. `AIWorld::update(dt)` ticks all agents in descending priority order, integrating velocity into position and invoking any custom-model callbacks.

**Decision-making subsystems.** Ten paradigms are available:
- **FSM** (`fsm.rs`) — finite state machine with named states, lifecycle callbacks (enter/exit/update), and priority-ordered guarded transitions.
- **Behavior Tree** (`behavior_tree.rs`) — hierarchical BT supporting Selector, Sequence, Parallel composites; Inverter, Repeater, Succeeder, Guard decorators; Action and Condition leaves. `BtDebugState` snapshots the active path for visual inspection.
- **Steering** (`steering.rs`) — Reynolds-style movement with Seek, Flee, Arrive, Wander, Pursue, Evade, Flock behaviors. `SteeringManager` blends forces in weighted or priority mode, supports spatial-hash bucketing for large flocks, and can consume nav-grid/navmesh waypoint paths directly through `setPath`.
- **Dialogue AI** (`dialogue.rs`) — topic/branch selector driven by FSM state, BT status, and utility-action scores for deterministic NPC conversation routing.
- **Context Steering** (`context_steering.rs`) — radial interest/danger ring evaluator for smooth obstacle-aware direction selection.
- **GOAP** (`goap.rs`) — Goal-Oriented Action Planning via A* over boolean world-state facts; configurable iteration cap to prevent frame spikes.
- **Utility AI** (`utility_ai.rs`) — multi-axis action scorer with per-consideration response curves (linear, quadratic, sigmoid, exponential, threshold).
- **Q-Learning** (`qlearner.rs`) — tabular epsilon-greedy reinforcement learner; Q-table serialises to/from JSON for persistence.
- **HTN** (`htn.rs`) — Hierarchical Task Network planner decomposing compound tasks into primitive task sequences via preconditioned methods.
- **MCTS** (`mcts.rs`) — Monte Carlo Tree Search for look-ahead decisions in game-tree problems.
- **Command Queue** (`command_queue.rs`) — RTS-style ordered command queue with interruptibility, front-insertion, and cancel.

**Supporting subsystems.** `Blackboard` (hierarchical key-value store); `InfluenceMap` (multi-layer spatial float grid for strategic area heat); `Squad` (formation offset computation, shared blackboard); `AIDirector` (dynamic pacing/tension controller with spawn-rate and loot-drop factors); `EmotionModel` (named affective dimensions with decay); `NeedSystem` (motivational needs with urgency scoring and advertisement selection); `TraitProfile` (named float trait base values with timed additive modifiers and archetype instantiation); `StimulusWorld` / `Sensor` (visual, auditory, and custom perception with awareness levels); `ORCASolver` (Optimal Reciprocal Collision Avoidance for crowd navigation); `NeuralNet` + `Neuroevolution` (feedforward network inference; genetic algorithm training); `GeneticAlgorithm` (generational GA with tournament selection, crossover, mutation, elitism); `Bandit` (multi-armed bandit with epsilon-greedy, UCB, and Thompson strategies); `StrategyAI` (throttled strategic goal evaluator with tag-gated preconditions); `AILod` (distance-tiered LOD for skipping updates on far agents).

**Pathfinding re-exports.** `FlowField`, `Cell`, and `PathGrid` types are re-exported from `crate::pathfind` so that `lurek.ai.*` provides a single scripting surface without requiring separate PathFind module imports.

**Lua surface.** 36 constructor functions under `lurek.ai.*` create every subsystem from Lua. Each type exposes methods through its userdata handle. Key additions: `AIDirector:setTension` for scripted tension sequences; `ContextSteering:addSeekTarget/addAvoidPoint/addAvoidBounds`; `GOAPPlanner:getMaxIterations/setMaxIterations`; `StateMachine:setInitialState`; `TraitProfile:set/get/getBase/addModifier`; `SteeringManager:enableSpatialHash/setSpatialHashCellSize/setPath`; `newDialogueAI` with topic/branch selection methods.

**Scope boundary.** Feature Systems tier. Depends on `math`, `pathfind`, `runtime`. Lua bridge in `src/lua_api/ai_api.rs`. Plugin candidacy under proposed constraint A-05 — see [docs/architecture/plugins.md](../architecture/plugins.md).

## Files

- `agent.rs`: Defines the core `Agent` record and the top-level decision-model selection enum used to attach different AI styles to an actor.
- `bandit.rs`: Multi-armed bandit algorithms for AI exploration/exploitation decisions.
- `behavior_tree.rs`: Implements behavior tree nodes, statuses, composite policies, and the execution model for hierarchical decision logic.
- `blackboard.rs`: Provides a hierarchical key-value blackboard for local and shared AI state.
- `command_queue.rs`: Implements queued AI commands with priorities, interruptibility, and callback integration.
- `context_steering.rs`: Context Steering — direction-based interest/danger evaluation for smooth movement.
- `dialogue.rs`: Dialogue AI selector that combines FSM/BT/Utility context into topic and branch choices.
- `director.rs`: AI Director — dynamic difficulty and pacing controller.
- `emotion.rs`: AI Emotion Model — simulated affective state for expressive agents.
- `fsm.rs`: Defines finite state machine structures, state callbacks, and guarded transitions.
- `genetic.rs`: Genetic Algorithm (GA) for offline AI parameter optimisation.
- `goap.rs`: Implements GOAP planning primitives and planner search over world-state facts.
- `htn.rs`: Hierarchical Task Network (HTN) Planner.
- `lod.rs`: AI Level-of-Detail (LOD) system — budget-aware update throttling.
- `mcts.rs`: Monte Carlo Tree Search (MCTS) for AI decision-making.
- `mod.rs`: Declares the AI submodules and re-exports the main decision-model and support types, including selected pathfinding-facing types.
- `needs.rs`: AI Needs and Motivation System.
- `neural_net.rs`: Minimal feedforward neural network for AI inference.
- `neuroevolution.rs`: Neuroevolution — evolve neural network weights using a genetic algorithm.
- `orca.rs`: ORCA — Optimal Reciprocal Collision Avoidance for smooth crowd navigation.
- `perception.rs`: AI Perception and Sensing System.
- `qlearner.rs`: Provides a tabular Q-learning implementation for trainable action selection.
- `render.rs`: Generates debug render output for AI state, plans, or decision structures when visual inspection is needed.
- `squad.rs`: Defines squad grouping, formation handling, and shared blackboard coordination.
- `steering.rs`: Implements movement steering behaviors such as seek, flee, arrive, wander, pursue, evade, and flocking.
- `strategy.rs`: Strategic AI — high-level goal evaluation and throttled decision-making.
- `traits.rs`: AI Trait and Personality System.
- `utility_ai.rs`: Implements utility-based action scoring with considerations and response curves.
- `world.rs`: Defines `AIWorld`, the central registry and coordination surface for agents and shared AI state.

## Types

- `DecisionModel` (`enum`, `agent.rs`): Chooses which AI paradigm an `Agent` is currently using.
- `Agent` (`struct`, `agent.rs`): One autonomous actor record with movement state, limits, selected decision model, and local blackboard.
- `BanditArm` (`struct`, `bandit.rs`): One arm in a multi-armed bandit.
- `BanditStrategy` (`enum`, `bandit.rs`): Arm selection algorithm for a [`Bandit`].
- `Bandit` (`struct`, `bandit.rs`): Multi-armed bandit with configurable exploration strategy.
- `BTStatus` (`enum`, `behavior_tree.rs`): The execution result returned by behavior-tree steps.
- `ParallelPolicy` (`enum`, `behavior_tree.rs`): Defines how parallel behavior-tree nodes determine success or failure.
- `BTNode` (`enum`, `behavior_tree.rs`): The behavior-tree node enum describing the actual tree shape.
- `BehaviorTree` (`struct`, `behavior_tree.rs`): Hierarchical decision structure for composite, decorator, and leaf AI behavior.
- `BtDebugState` (`struct`, `behavior_tree.rs`): A snapshot of a [`BehaviorTree`]'s current diagnostic state.
- `BlackboardValue` (`enum`, `blackboard.rs`): The value enum stored in a `Blackboard`.
- `Blackboard` (`struct`, `blackboard.rs`): Hierarchical key-value state store used for AI coordination and memory.
- `Command` (`struct`, `command_queue.rs`): One queued AI command with priority and callback information.
- `CommandQueue` (`struct`, `command_queue.rs`): Ordered queue of AI commands waiting to run or interrupt one another.
- `ContextBehaviorKind` (`enum`, `context_steering.rs`): Variant of a context steering behavior defining how it fills the ring.
- `ContextBehavior` (`struct`, `context_steering.rs`): A single context steering behavior with a weight and enabled flag.
- `ContextSteering` (`struct`, `context_steering.rs`): Radial context steering evaluator producing a smooth, obstacle-aware movement direction.
- `DialogueBranch` (`struct`, `dialogue.rs`): Single branch inside a topic.
- `DialogueTopic` (`struct`, `dialogue.rs`): Top-level dialogue topic with an ordered set of branches.
- `DialogueAI` (`struct`, `dialogue.rs`): Topic and branch selector with gate checks and utility scoring.
- `DirectorPhase` (`enum`, `director.rs`): Current pacing phase of the AI Director state machine.
- `DirectorConfig` (`struct`, `director.rs`): Configuration thresholds and decay rates for [`AIDirector`].
- `AIDirector` (`struct`, `director.rs`): Dynamic pacing and difficulty director.
- `Emotion` (`struct`, `emotion.rs`): A single named affective dimension.
- `EmotionModel` (`struct`, `emotion.rs`): Affective state model for an AI agent.
- `StateCallbacks` (`struct`, `fsm.rs`): Bundles per-state lifecycle callbacks for FSM behavior.
- `Transition` (`struct`, `fsm.rs`): One guarded edge between FSM states.
- `StateMachine` (`struct`, `fsm.rs`): Finite state machine with named states and guarded transitions.
- `Chromosome` (`struct`, `genetic.rs`): A candidate solution in a genetic algorithm population.
- `GeneticAlgorithm` (`struct`, `genetic.rs`): Simple generational genetic algorithm.
- `GOAPAction` (`struct`, `goap.rs`): One GOAP action with preconditions and effects.
- `GOAPGoal` (`struct`, `goap.rs`): Desired end-state description for GOAP planning.
- `GOAPPlanner` (`struct`, `goap.rs`): Planner that searches action sequences over world-state facts.
- `WorldState` (`type`, `htn.rs`): Snapshot of agent/world boolean and numeric state used during HTN planning.
- `HTNTask` (`enum`, `htn.rs`): A hierarchical task — either a compound task (decomposable) or a primitive task (executable).
- `HTNMethod` (`struct`, `htn.rs`): One decomposition pathway for a compound task.
- `HTNDomain` (`struct`, `htn.rs`): Registry of all HTN tasks for an agent archetype.
- `HTNPlanner` (`struct`, `htn.rs`): Stateless HTN planner.
- `LodTier` (`struct`, `lod.rs`): One distance band in the AI LOD system.
- `AILod` (`struct`, `lod.rs`): LOD distance tiers and per-frame assignment engine.
- `MCTSConfig` (`struct`, `mcts.rs`): Configuration for the MCTS engine.
- `MCTSEngine` (`struct`, `mcts.rs`): MCTS engine with arena-allocated node tree.
- `Need` (`struct`, `needs.rs`): A single named motivational drive for an AI agent.
- `NeedAdvertisement` (`struct`, `needs.rs`): A world-space announcement that an object or location can satisfy a need.
- `NeedSystem` (`struct`, `needs.rs`): Collection of [`Need`]s for a single agent.
- `Activation` (`enum`, `neural_net.rs`): Element-wise activation function applied at the output of a neural layer.
- `NeuralLayer` (`struct`, `neural_net.rs`): A single fully-connected layer in a neural network.
- `NeuralNet` (`struct`, `neural_net.rs`): Feedforward neural network stack.
- `Neuroevolution` (`struct`, `neuroevolution.rs`): Neuroevolution trainer: evolves a population of neural network weight vectors.
- `ORCAAgent` (`struct`, `orca.rs`): A single agent participating in ORCA collision avoidance.
- `ORCASolver` (`struct`, `orca.rs`): ORCA crowd solver for a flat list of agents.
- `StimulusType` (`enum`, `perception.rs`): The sensory channel of a [`Stimulus`].
- `Stimulus` (`struct`, `perception.rs`): A world-space sensory event that agents can detect.
- `DetectedStimulus` (`struct`, `perception.rs`): Result record produced when a sensor successfully detects a stimulus.
- `StimulusWorld` (`struct`, `perception.rs`): Scene-level registry of active sensory stimuli.
- `Sensor` (`struct`, `perception.rs`): Agent-level sensing configuration and awareness state.
- `QLearner` (`struct`, `qlearner.rs`): Tabular reinforcement learner for action value estimation.
- `FormationType` (`enum`, `squad.rs`): Identifies the supported squad formation patterns.
- `Squad` (`struct`, `squad.rs`): Group-level AI container for formations and shared decisions.
- `Force` (`type`, `steering.rs`): 2D force vector (fx, fy).
- `CombineMode` (`enum`, `steering.rs`): Controls how multiple steering behaviors are merged.
- `SteeringBase` (`struct`, `steering.rs`): Shared parameters common to all steering behavior instances.
- `SteeringBehaviorType` (`enum`, `steering.rs`): Names the available steering behaviors.
- `SteeringManager` (`struct`, `steering.rs`): Combines steering behaviors to produce movement intent.
- `StrategicGoal` (`struct`, `strategy.rs`): Named strategic goal with cost/benefit estimates.
- `StrategyAI` (`struct`, `strategy.rs`): Throttled strategic goal evaluator.
- `TraitModifier` (`struct`, `traits.rs`): A temporary or permanent additive delta applied on top of a base trait value.
- `TraitProfile` (`struct`, `traits.rs`): Named float trait profile for an AI agent.
- `TraitArchetypes` (`struct`, `traits.rs`): Registry of named archetypal trait profiles used for agent instantiation.
- `ResponseCurve` (`enum`, `utility_ai.rs`): The curve applied to a consideration value before scoring.
- `Consideration` (`struct`, `utility_ai.rs`): One input dimension used in utility scoring.
- `UAAction` (`struct`, `utility_ai.rs`): A candidate action inside a utility-AI model.
- `UtilityAI` (`struct`, `utility_ai.rs`): Scores candidate actions using considerations and response curves.
- `AIWorld` (`struct`, `world.rs`): The central AI registry. It owns agents, shared blackboard access, and world-level coordination of AI state.

## Functions

- `DecisionModel::parse_str` (`agent.rs`): Parse a string tag into a `DecisionModel`; returns `None` for unknown tags.
- `DecisionModel::as_str` (`agent.rs`): Return the canonical string tag for this model.
- `Agent::new` (`agent.rs`): Create a new agent with default movement, AI, and support systems.
- `BanditArm::mean_reward` (`bandit.rs`): Return the empirical mean reward; returns 0.5 before the first pull.
- `Bandit::new` (`bandit.rs`): Create a bandit with `arm_count` arms and a fixed RNG seed.
- `Bandit::arm_count` (`bandit.rs`): Return the number of available arms.
- `Bandit::select` (`bandit.rs`): Select an arm index according to the current strategy.
- `Bandit::update` (`bandit.rs`): Update the chosen arm with an observed reward in the range `[0, 1]`.
- `Bandit::best_arm` (`bandit.rs`): Return the greedy best arm by empirical mean reward.
- `Bandit::reset` (`bandit.rs`): Reset all arm statistics and the total pull counter.
- `BTStatus::parse_str` (`behavior_tree.rs`): Parse a string tag into `BTStatus`; unknown strings default to `Running`.
- `BTStatus::as_str` (`behavior_tree.rs`): Return the canonical lowercase string tag for this status.
- `ParallelPolicy::parse_str` (`behavior_tree.rs`): Parse a string tag; unknown strings default to `RequireOne`.
- `ParallelPolicy::as_str` (`behavior_tree.rs`): Return the canonical string tag for this policy.
- `BTNode::reset` (`behavior_tree.rs`): Reset all running indices and repetition counters in this subtree recursively.
- `BTNode::child_count` (`behavior_tree.rs`): Return the number of direct children; leaf nodes return 0.
- `BehaviorTree::new` (`behavior_tree.rs`): Create an empty tree with `last_status` initialised to `Success`.
- `BehaviorTree::debug_state` (`behavior_tree.rs`): Build a `BtDebugState` snapshot from the current tree shape and status.
- `Blackboard::new` (`blackboard.rs`): Create an empty blackboard with no parent.
- `Blackboard::set_number` (`blackboard.rs`): Write a `Number` value under `key`, overwriting any existing entry.
- `Blackboard::get_number` (`blackboard.rs`): Read a `Number` by key; walks the parent chain, returns `default` if absent.
- `Blackboard::set_bool` (`blackboard.rs`): Write a `Bool` value under `key`, overwriting any existing entry.
- `Blackboard::get_bool` (`blackboard.rs`): Read a `Bool` by key; walks the parent chain, returns `default` if absent.
- `Blackboard::set_string` (`blackboard.rs`): Write a `Text` value under `key`, overwriting any existing entry.
- `Blackboard::get_string` (`blackboard.rs`): Read a `Text` by key; walks the parent chain, returns `default` if absent.
- `Blackboard::has` (`blackboard.rs`): Return `true` if `key` exists in this board or any ancestor.
- `Blackboard::remove` (`blackboard.rs`): Remove `key` from the local entries only; parent is not affected.
- `Blackboard::clear` (`blackboard.rs`): Remove all local entries; parent is not affected.
- `Blackboard::keys` (`blackboard.rs`): Return all local key names as a new `Vec`; does not include parent keys.
- `Blackboard::size` (`blackboard.rs`): Return the number of entries in the local board, excluding the parent.
- `Blackboard::set_parent` (`blackboard.rs`): Attach a parent board; looked up when a local key is missing.
- `Blackboard::parent` (`blackboard.rs`): Return a reference to the parent board, or `None` if none is set.
- `CommandQueue::new` (`command_queue.rs`): Create an empty queue.
- `CommandQueue::enqueue` (`command_queue.rs`): Append `cmd` to the back of the queue.
- `CommandQueue::push_front` (`command_queue.rs`): Insert `cmd` at the front, making it the next command to execute.
- `CommandQueue::replace` (`command_queue.rs`): Clear the entire queue and enqueue `cmd` as the sole pending command.
- `CommandQueue::cancel_current` (`command_queue.rs`): Pop the front command if it is interruptible; return `true` on success.
- `CommandQueue::clear` (`command_queue.rs`): Discard all queued commands.
- `CommandQueue::count` (`command_queue.rs`): Return the number of pending commands.
- `CommandQueue::is_empty` (`command_queue.rs`): Return `true` when the queue has no pending commands.
- `CommandQueue::current_type` (`command_queue.rs`): Return the `kind` tag of the front command, or `None` if the queue is empty.
- `CommandQueue::current_target` (`command_queue.rs`): Return the `(target_x, target_y)` of the front command; returns `(0, 0)` if empty.
- `CommandQueue::advance` (`command_queue.rs`): Remove the front command as completed and expose the next one.
- `CommandQueue::enqueue_raw` (`command_queue.rs`): Build a `Command` from raw parts and append it to the back of the queue.
- `CommandQueue::push_front_raw` (`command_queue.rs`): Build a `Command` from raw parts and insert it at the front of the queue.
- `CommandQueue::replace_raw` (`command_queue.rs`): Build a `Command` from raw parts, clear the queue, and set it as the only entry.
- `ContextSteering::new` (`context_steering.rs`): Create a context-steering sampler with at least four slots.
- `ContextSteering::slot_count` (`context_steering.rs`): Return the number of angular slots.
- `ContextSteering::add_interest` (`context_steering.rs`): Add an interest behavior.
- `ContextSteering::add_danger` (`context_steering.rs`): Add a danger behavior.
- `ContextSteering::add_seek_target` (`context_steering.rs`): Add a seek-target interest behavior.
- `ContextSteering::add_wander` (`context_steering.rs`): Add a wander interest behavior.
- `ContextSteering::add_avoid_point` (`context_steering.rs`): Add a point-avoidance danger behavior.
- `ContextSteering::add_avoid_bounds` (`context_steering.rs`): Add a world-bounds avoidance danger behavior.
- `ContextSteering::clear_behaviors` (`context_steering.rs`): Remove all registered behaviors.
- `ContextSteering::evaluate` (`context_steering.rs`): Evaluate all behaviors and return the chosen steering direction vector.
- `ContextSteering::chosen_direction` (`context_steering.rs`): Return the heading in radians chosen by the last evaluation.
- `ContextSteering::chosen_magnitude` (`context_steering.rs`): Return the magnitude chosen by the last evaluation.
- `ContextSteering::interest_map` (`context_steering.rs`): Return a copy of the last computed interest ring.
- `ContextSteering::danger_map` (`context_steering.rs`): Return a copy of the last computed danger ring.
- `DialogueAI::new` (`dialogue.rs`): Create an empty dialogue selector.
- `DialogueAI::set_fsm_state` (`dialogue.rs`): Set the FSM state gate used by topic and branch selection.
- `DialogueAI::set_bt_status` (`dialogue.rs`): Set the behavior-tree status gate used by topic and branch selection.
- `DialogueAI::set_utility_score` (`dialogue.rs`): Store a utility score under `key`.
- `DialogueAI::clear_utility_scores` (`dialogue.rs`): Remove all cached utility scores.
- `DialogueAI::add_topic` (`dialogue.rs`): Add a topic with optional gate requirements and utility key.
- `DialogueAI::add_branch` (`dialogue.rs`): Add a branch to the named topic; returns `false` if the topic is missing.
- `DialogueAI::select_topic` (`dialogue.rs`): Return the best matching topic id, or `None` when no topic matches.
- `DialogueAI::select_branch` (`dialogue.rs`): Return the best matching branch id for `topic_id`, or `None` when none matches.
- `DialogueAI::topic_count` (`dialogue.rs`): Return the number of registered topics.
- `DirectorPhase::as_str` (`director.rs`): Return the canonical string tag for this pacing phase.
- `AIDirector::new` (`director.rs`): Create a director with default config.
- `AIDirector::with_config` (`director.rs`): Create a director with a custom config.
- `AIDirector::tension` (`director.rs`): Return the current tension.
- `AIDirector::phase` (`director.rs`): Return the current phase.
- `AIDirector::phase_str` (`director.rs`): Return the current phase as a string tag.
- `AIDirector::elapsed` (`director.rs`): Return elapsed seconds.
- `AIDirector::total_events` (`director.rs`): Return total events received.
- `AIDirector::push_event` (`director.rs`): Add one event and clamp the resulting tension to `[0, 1]`.
- `AIDirector::update` (`director.rs`): Advance the director and update phase transitions.
- `AIDirector::spawn_rate_factor` (`director.rs`): Return the current spawn rate multiplier.
- `AIDirector::loot_factor` (`director.rs`): Return the current loot multiplier.
- `AIDirector::ambient_intensity` (`director.rs`): Return the current ambient intensity scalar.
- `AIDirector::set_tension` (`director.rs`): Set tension directly and clamp it to `[0, 1]`.
- `AIDirector::reset` (`director.rs`): Reset tension, phase, and timers to their initial state.
- `Emotion::new` (`emotion.rs`): Create a new emotion with clamped resting and visibility levels.
- `Emotion::is_active` (`emotion.rs`): Return `true` when the emotion is above the visible threshold.
- `Emotion::trigger` (`emotion.rs`): Increase the emotion value and clamp it to `[0, 1]`.
- `Emotion::set` (`emotion.rs`): Set the emotion value directly and clamp it to `[0, 1]`.
- `Emotion::update` (`emotion.rs`): Move the emotion toward its resting level over `dt` seconds.
- `EmotionModel::new` (`emotion.rs`): Create an empty emotion model.
- `EmotionModel::add` (`emotion.rs`): Add or replace an emotion by name.
- `EmotionModel::get` (`emotion.rs`): Return the current value for `name`, or 0.0 if missing.
- `EmotionModel::trigger` (`emotion.rs`): Increase the value of the named emotion when present.
- `EmotionModel::set` (`emotion.rs`): Set the value of the named emotion when present.
- `EmotionModel::update` (`emotion.rs`): Advance all emotions toward their resting levels.
- `EmotionModel::dominant` (`emotion.rs`): Return the name of the highest active emotion, or `None` when none are active.
- `EmotionModel::is_active` (`emotion.rs`): Return `true` when the named emotion exists and is active.
- `EmotionModel::active_names` (`emotion.rs`): Return the names of all active emotions.
- `EmotionModel::count` (`emotion.rs`): Return the number of tracked emotions.
- `EmotionModel::reset` (`emotion.rs`): Reset all emotions to their resting levels.
- `StateMachine::new` (`fsm.rs`): Create an empty state machine with no states or transitions.
- `StateMachine::add_transition` (`fsm.rs`): Register a transition and re-sort the transition list by descending priority.
- `StateMachine::current_state` (`fsm.rs`): Return the name of the currently active state, or `None` before the first tick.
- `StateMachine::time_in_state` (`fsm.rs`): Return elapsed seconds since the current state was entered.
- `StateMachine::add_state_raw` (`fsm.rs`): Register a state by name with optional enter, update, and exit registry keys.
- `StateMachine::add_transition_raw` (`fsm.rs`): Build a `Transition` from raw parts and add it via `add_transition`.
- `StateMachine::set_initial_state` (`fsm.rs`): Set the state name that will be activated on the first tick.
- `Chromosome::new` (`genetic.rs`): Create a zeroed chromosome with `gene_count` genes.
- `GeneticAlgorithm::new` (`genetic.rs`): Create a population with random initial genes.
- `GeneticAlgorithm::pop_size` (`genetic.rs`): Return the current population size.
- `GeneticAlgorithm::best` (`genetic.rs`): Return the chromosome with the highest fitness, or `None` if empty.
- `GeneticAlgorithm::evolve` (`genetic.rs`): Build the next generation using elitism, tournament selection, crossover, and mutation.
- `GOAPPlanner::new` (`goap.rs`): Create a planner with an empty action and goal lists and `max_iterations = 10 000`.
- `GOAPPlanner::plan` (`goap.rs`): Plan for the highest-priority goal; return ordered action name list or empty on failure.
- `GOAPPlanner::plan_for_goal_idx` (`goap.rs`): Plan for the goal at `goal_idx`; return ordered action name list or empty on failure.
- `GOAPPlanner::add_action` (`goap.rs`): Register a new action with an empty precondition and effect set.
- `GOAPPlanner::add_precondition` (`goap.rs`): Add a precondition entry to the named action; no-op if the action is not found.
- `GOAPPlanner::add_effect` (`goap.rs`): Add an effect entry to the named action; no-op if the action is not found.
- `GOAPPlanner::add_goal` (`goap.rs`): Register a new goal with an empty desired state map.
- `GOAPPlanner::set_goal_state` (`goap.rs`): Add a desired world-state entry to the named goal; no-op if goal is not found.
- `GOAPPlanner::get_max_iterations` (`goap.rs`): Return the current A* iteration cap.
- `GOAPPlanner::set_max_iterations` (`goap.rs`): Set the A* iteration cap to `n`.
- `HTNTask::name` (`htn.rs`): Return the task name.
- `HTNTask::is_primitive` (`htn.rs`): Return `true` for primitive tasks.
- `HTNTask::preconditions_met` (`htn.rs`): Return `true` when the task preconditions are satisfied.
- `HTNTask::apply_effects` (`htn.rs`): Apply primitive effects to the world state.
- `HTNMethod::always` (`htn.rs`): Create a method with no preconditions.
- `HTNMethod::with_preconditions` (`htn.rs`): Create a method with explicit preconditions.
- `HTNMethod::is_applicable` (`htn.rs`): Return `true` when the method preconditions are satisfied.
- `HTNDomain::new` (`htn.rs`): Create an empty domain.
- `HTNDomain::register` (`htn.rs`): Register a task by its name.
- `HTNDomain::add_primitive` (`htn.rs`): Add a primitive task.
- `HTNDomain::add_compound` (`htn.rs`): Add a compound task.
- `HTNDomain::get` (`htn.rs`): Return a task by name.
- `HTNDomain::task_count` (`htn.rs`): Return the number of tasks in the domain.
- `HTNPlanner::plan` (`htn.rs`): Plan from `root_task` and return a primitive task sequence, or `None` on failure.
- `LodTier::new` (`lod.rs`): Create a tier with the given parameters.
- `AILod::new` (`lod.rs`): Sort tiers by distance and build an `AILod`.
- `AILod::tier` (`lod.rs`): Return tier `i` if it exists.
- `AILod::tier_count` (`lod.rs`): Return the number of tiers.
- `AILod::tier_for` (`lod.rs`): Return the tier index for `agent_pos` relative to `ref_pos`.
- `AILod::assign_tiers` (`lod.rs`): Return one tier index per agent position.
- `AILod::should_update` (`lod.rs`): Return `true` when tier `tier` should update on `frame_number`.
- `MCTSEngine::new` (`mcts.rs`): Create a search engine with the provided config.
- `MCTSEngine::config` (`mcts.rs`): Return the active config.
- `MCTSEngine::search` (`mcts.rs`): Search for the best action and return its id, or `None` when no actions exist.
- `Need::new` (`needs.rs`): Create a need with value initialized to 1.0.
- `Need::is_urgent` (`needs.rs`): Return `true` when the need is enabled and below its urgency threshold.
- `Need::urgency_score` (`needs.rs`): Return a score used for prioritising needs.
- `Need::satisfy` (`needs.rs`): Increase the need value and clamp it to `[0, 1]`.
- `Need::deprive` (`needs.rs`): Decrease the need value and clamp it at 0.
- `Need::update` (`needs.rs`): Apply passive decay over `dt` seconds.
- `NeedAdvertisement::new` (`needs.rs`): Create a new advertisement at `(x, y)`.
- `NeedAdvertisement::is_available` (`needs.rs`): Return `true` when the ad is off cooldown.
- `NeedAdvertisement::use_it` (`needs.rs`): Start the cooldown timer when the ad has a positive cooldown.
- `NeedAdvertisement::update` (`needs.rs`): Advance the cooldown timer.
- `NeedAdvertisement::score` (`needs.rs`): Return a distance-weighted score for the ad.
- `NeedSystem::new` (`needs.rs`): Create an empty need system.
- `NeedSystem::add_need` (`needs.rs`): Add or replace a need by name.
- `NeedSystem::get` (`needs.rs`): Return a need by name, or `None` if missing.
- `NeedSystem::get_mut` (`needs.rs`): Return a mutable need by name, or `None` if missing.
- `NeedSystem::update` (`needs.rs`): Advance all needs by `dt` seconds.
- `NeedSystem::most_urgent` (`needs.rs`): Return the most urgent enabled need name, or `None` when none are enabled.
- `NeedSystem::satisfy` (`needs.rs`): Increase the named need when present.
- `NeedSystem::need_names` (`needs.rs`): Return all tracked need names.
- `NeedSystem::value_of` (`needs.rs`): Return the current value of the named need, or 1.0 if missing.
- `NeedSystem::best_advertisement` (`needs.rs`): Return the best-scoring available advertisement, or `None` if none score positive.
- `Activation::from_str` (`neural_net.rs`): Parse a lowercase activation name; unknown strings map to `Linear`.
- `Activation::as_str` (`neural_net.rs`): Return the canonical activation name.
- `Activation::apply` (`neural_net.rs`): Apply the activation in place to `v`.
- `NeuralLayer::new` (`neural_net.rs`): Create a zeroed dense layer.
- `NeuralLayer::param_count` (`neural_net.rs`): Return the number of learnable parameters in the layer.
- `NeuralLayer::forward` (`neural_net.rs`): Compute the layer output for `input`.
- `NeuralNet::new` (`neural_net.rs`): Create an empty neural net.
- `NeuralNet::add_layer` (`neural_net.rs`): Append a new dense layer.
- `NeuralNet::param_count` (`neural_net.rs`): Return the total number of learnable parameters.
- `NeuralNet::forward` (`neural_net.rs`): Run a forward pass through all layers.
- `NeuralNet::set_weights` (`neural_net.rs`): Load flattened weights and biases; returns `false` when the shape mismatches.
- `NeuralNet::get_weights` (`neural_net.rs`): Return the flattened weights and biases.
- `NeuralNet::layer_count` (`neural_net.rs`): Return the number of layers.
- `Neuroevolution::new` (`neuroevolution.rs`): Create a population for the provided layer spec.
- `Neuroevolution::pop_size` (`neuroevolution.rs`): Return the population size.
- `Neuroevolution::chromosome_to_net` (`neuroevolution.rs`): Build a neural net from chromosome `i`; returns `None` when the index is invalid.
- `Neuroevolution::set_fitness` (`neuroevolution.rs`): Assign fitness to chromosome `i` when present.
- `Neuroevolution::evolve` (`neuroevolution.rs`): Advance the underlying genetic algorithm and generation counter.
- `Neuroevolution::best_network` (`neuroevolution.rs`): Build the network for the best chromosome, or `None` if the population is empty.
- `Neuroevolution::best_fitness` (`neuroevolution.rs`): Return the best fitness in the current population, or 0.0 if empty.
- `Neuroevolution::population` (`neuroevolution.rs`): Return the current chromosome slice.
- `ORCAAgent::new` (`orca.rs`): Create a new agent at `(x, y)`.
- `ORCASolver::new` (`orca.rs`): Create a solver with a minimum time horizon of 0.1 seconds.
- `ORCASolver::add_agent` (`orca.rs`): Add an agent and return its index.
- `ORCASolver::remove_agent` (`orca.rs`): Remove and return the agent at `index`, or `None` when out of bounds.
- `ORCASolver::agent_count` (`orca.rs`): Return the number of registered agents.
- `ORCASolver::compute` (`orca.rs`): Compute safe velocities for all agents.
- `StimulusType::from_str` (`perception.rs`): Parse a stimulus type name; unknown strings become `Custom`.
- `StimulusType::as_str` (`perception.rs`): Return a display string for the stimulus type.
- `StimulusWorld::new` (`perception.rs`): Create an empty stimulus world.
- `StimulusWorld::add` (`perception.rs`): Insert a stimulus and return its assigned id.
- `StimulusWorld::add_visual` (`perception.rs`): Add a visual stimulus.
- `StimulusWorld::add_auditory` (`perception.rs`): Add an auditory stimulus.
- `StimulusWorld::add_custom` (`perception.rs`): Add a custom stimulus type.
- `StimulusWorld::remove` (`perception.rs`): Remove a stimulus by id and return `true` when one was removed.
- `StimulusWorld::update` (`perception.rs`): Decay all stimuli and drop exhausted entries.
- `StimulusWorld::stimuli` (`perception.rs`): Return the active stimuli slice.
- `StimulusWorld::count` (`perception.rs`): Return the number of active stimuli.
- `StimulusWorld::clear` (`perception.rs`): Remove all stimuli.
- `Sensor::new` (`perception.rs`): Create a sensor with default sight, hearing, and awareness settings.
- `Sensor::can_see` (`perception.rs`): Return `true` when the target lies within sight range and the vision cone.
- `Sensor::can_hear` (`perception.rs`): Return `true` when the auditory stimulus is within the effective hearing range.
- `Sensor::detect` (`perception.rs`): Return every stimulus currently detected from `sensor_pos`.
- `Sensor::update_awareness` (`perception.rs`): Raise or decay awareness based on the current number of detections.
- `Sensor::is_alert` (`perception.rs`): Return `true` when awareness reached the alert threshold.
- `Sensor::add_custom_range` (`perception.rs`): Register a detection range override for one custom stimulus label.
- `QLearner::new` (`qlearner.rs`): Create a zeroed Q-table for `state_count` states and `action_count` actions.
- `QLearner::choose_action` (`qlearner.rs`): Return a randomly chosen action (explore) or the greedy best action (exploit).
- `QLearner::best_action` (`qlearner.rs`): Return the action with the highest Q-value for `state`; ties broken by index.
- `QLearner::learn` (`qlearner.rs`): Apply a Bellman update: Q[s,a] ← Q[s,a] + α(r + γ·max Q[s'] − Q[s,a]).
- `QLearner::end_episode` (`qlearner.rs`): Decay epsilon and increment `episode_count`; call once at the end of each episode.
- `QLearner::get_q` (`qlearner.rs`): Return Q[state, action]; returns 0.0 if indices are out of bounds.
- `QLearner::set_q` (`qlearner.rs`): Set Q[state, action] to `value`; no-op if indices are out of bounds.
- `QLearner::serialize` (`qlearner.rs`): Serialize the Q-table to a compact JSON string `[[row0], [row1], ...]`.
- `QLearner::deserialize` (`qlearner.rs`): Parse a JSON Q-table string and overwrite the current table; returns error on shape mismatch.
- `StateMachine::generate_render_commands` (`render.rs`): Build line and box commands for the FSM debug view.
- `StateMachine::draw_to_image` (`render.rs`): Draw the FSM debug view into an `ImageData` buffer.
- `BehaviorTree::generate_render_commands` (`render.rs`): Build render commands for the BT debug view.
- `BehaviorTree::draw_to_image` (`render.rs`): Draw the BT debug view into an `ImageData` buffer.
- `FormationType::parse_str` (`squad.rs`): Parse a lowercase formation name; unknown strings map to `None`.
- `FormationType::as_str` (`squad.rs`): Return the canonical lowercase formation name.
- `Squad::new` (`squad.rs`): Create an empty squad with default spacing.
- `Squad::get_formation_position` (`squad.rs`): Return the target position for one member relative to a leader position.
- `CombineMode::parse_str` (`steering.rs`): Parse a string tag into `CombineMode`; unknown strings map to `Weighted`.
- `CombineMode::as_str` (`steering.rs`): Return the canonical string tag for this mode.
- `SteeringBehaviorType::base` (`steering.rs`): Return the shared base state for the behavior.
- `SteeringBehaviorType::base_mut` (`steering.rs`): Return the mutable shared base state for the behavior.
- `SteeringBehaviorType::kind` (`steering.rs`): Return the canonical behavior kind string.
- `SteeringBehaviorType::calculate` (`steering.rs`): Compute the steering force for this behavior.
- `SteeringManager::new` (`steering.rs`): Create a steering manager with default parameters.
- `SteeringManager::calculate` (`steering.rs`): Combine all enabled behaviors and clamp the result to `max_force`.
- `SteeringManager::add_seek` (`steering.rs`): Add a seek behavior.
- `SteeringManager::add_flee` (`steering.rs`): Add a flee behavior.
- `SteeringManager::add_arrive` (`steering.rs`): Add an arrive behavior.
- `SteeringManager::add_wander` (`steering.rs`): Add a wander behavior.
- `SteeringManager::add_pursue` (`steering.rs`): Add a pursue behavior.
- `SteeringManager::add_evade` (`steering.rs`): Add an evade behavior.
- `SteeringManager::add_flock` (`steering.rs`): Add a flock behavior.
- `SteeringManager::set_combine_mode_str` (`steering.rs`): Set combine mode from a string tag.
- `SteeringManager::last_force` (`steering.rs`): Return the last computed force.
- `SteeringManager::set_cell_size` (`steering.rs`): Set the spatial-hash cell size.
- `SteeringManager::set_use_spatial_hash` (`steering.rs`): Enable or disable spatial hashing.
- `SteeringManager::set_path` (`steering.rs`): Replace the waypoint path and reset traversal state.
- `SteeringManager::clear_path` (`steering.rs`): Clear all waypoints and reset path progress.
- `SteeringManager::has_active_path` (`steering.rs`): Return `true` when there are remaining waypoints.
- `SteeringManager::path_progress` (`steering.rs`): Return `(current_index, waypoint_count)`.
- `StrategicGoal::new` (`strategy.rs`): Create an enabled goal with default priority.
- `StrategicGoal::require_tag` (`strategy.rs`): Add a required tag.
- `StrategicGoal::is_eligible` (`strategy.rs`): Return `true` when all required tags are present and the goal is enabled.
- `StrategyAI::new` (`strategy.rs`): Create a strategy AI that evaluates every `update_interval` seconds.
- `StrategyAI::add_goal` (`strategy.rs`): Add a goal to the evaluation set.
- `StrategyAI::add_goal_named` (`strategy.rs`): Add a goal with the given name.
- `StrategyAI::set_tags` (`strategy.rs`): Replace the active tag set.
- `StrategyAI::add_tag` (`strategy.rs`): Add a tag if it is not already present.
- `StrategyAI::remove_tag` (`strategy.rs`): Remove a tag if it exists.
- `StrategyAI::active_goal` (`strategy.rs`): Return the name of the active goal, or `None` when nothing is selected.
- `StrategyAI::update` (`strategy.rs`): Advance the timer and evaluate goals when the update interval elapses.
- `StrategyAI::force_evaluate` (`strategy.rs`): Force immediate evaluation and reset the timer.
- `StrategyAI::goal_count` (`strategy.rs`): Return the number of goals.
- `StrategyAI::time_until_next` (`strategy.rs`): Return the remaining time until the next scheduled evaluation.
- `TraitModifier::new` (`traits.rs`): Create a modifier for one trait.
- `TraitModifier::is_expired` (`traits.rs`): Return `true` when this modifier has reached zero remaining lifetime.
- `TraitModifier::tick` (`traits.rs`): Advance the modifier timer by `dt` seconds when it is time-limited.
- `TraitProfile::new` (`traits.rs`): Create an empty trait profile.
- `TraitProfile::from_archetype` (`traits.rs`): Build a profile from a registered archetype and optional deterministic variance.
- `TraitProfile::set` (`traits.rs`): Set the base value for one trait and clamp it to `[0, 1]`.
- `TraitProfile::get` (`traits.rs`): Return the resolved value for one trait after applying active modifiers.
- `TraitProfile::get_base` (`traits.rs`): Return the unclamped base value for one trait without modifiers.
- `TraitProfile::add_modifier` (`traits.rs`): Add a temporary modifier to one trait.
- `TraitProfile::remove_modifiers_by_source` (`traits.rs`): Remove all modifiers that originated from the given source tag.
- `TraitProfile::update` (`traits.rs`): Advance active modifier timers and discard expired entries.
- `TraitProfile::trait_names` (`traits.rs`): Return all registered trait names.
- `TraitProfile::trait_count` (`traits.rs`): Return the number of base traits stored in this profile.
- `TraitProfile::has` (`traits.rs`): Return `true` when the profile has a base value for the named trait.
- `TraitProfile::lerp_toward` (`traits.rs`): Move all shared trait values toward another profile by factor `t`.
- `TraitProfile::archetype` (`traits.rs`): Return the archetype name used to initialize this profile, when present.
- `TraitArchetypes::new` (`traits.rs`): Create an empty archetype registry.
- `TraitArchetypes::register` (`traits.rs`): Register or replace one named archetype after clamping all values to `[0, 1]`.
- `TraitArchetypes::get` (`traits.rs`): Return the trait map for one named archetype.
- `TraitArchetypes::names` (`traits.rs`): Return all registered archetype names.
- `TraitArchetypes::count` (`traits.rs`): Return the number of registered archetypes.
- `ResponseCurve::parse_str` (`utility_ai.rs`): Parse a string tag into a `ResponseCurve`; unknown strings map to `Linear`.
- `ResponseCurve::apply` (`utility_ai.rs`): Evaluate the curve at `input` using shape parameters p1, p2, p3.
- `UtilityAI::new` (`utility_ai.rs`): Create a `UtilityAI` with no actions.
- `UtilityAI::add_action` (`utility_ai.rs`): Register a new action with an empty consideration list.
- `UtilityAI::add_consideration` (`utility_ai.rs`): Append a consideration to the named action; no-op if the action is not found.
- `UtilityAI::last_action_name` (`utility_ai.rs`): Return the name of the action selected on the last `evaluate` call, or `None`.
- `UtilityAI::evaluate` (`utility_ai.rs`): Call all action scorers, apply momentum, and return the best action name.
- `AIWorld::new` (`world.rs`): Create an empty AI world.
- `AIWorld::add_agent` (`world.rs`): Add a named agent and return its index; returns an error on duplicate names.
- `AIWorld::remove_agent` (`world.rs`): Remove an agent by name and rebuild the index map.
- `AIWorld::get_agent_index` (`world.rs`): Return the index of an agent by name.
- `AIWorld::agent_count` (`world.rs`): Return the number of agents in the world.
- `AIWorld::global_blackboard` (`world.rs`): Return the shared global blackboard.
- `AIWorld::global_blackboard_mut` (`world.rs`): Return the shared global blackboard mutably.
- `AIWorld::update` (`world.rs`): Advance all agents by integrating velocity over `dt`.

## Lua API Reference

- Binding path(s): `src/lua_api/ai_api.rs`
- Namespace: `lurek.ai`

### Module Functions
- `lurek.ai.newWorld`: Creates an isolated AI world for agents, blackboards, and custom decision callbacks.
- `lurek.ai.newBlackboard`: Creates an empty AI blackboard for typed local facts.
- `lurek.ai.newStateMachine`: Creates an empty finite state machine with Lua-backed states and transitions.
- `lurek.ai.newBehaviorTree`: Creates an empty behavior tree that can receive a root node.
- `lurek.ai.newSelector`: Creates a behavior tree selector node with no children.
- `lurek.ai.newSequence`: Creates a behavior tree sequence node with no children.
- `lurek.ai.newParallel`: Creates a behavior tree parallel node with optional success and failure policies.
- `lurek.ai.newInverter`: Creates a behavior tree inverter decorator with an empty sequence child.
- `lurek.ai.newRepeater`: Creates a behavior tree repeater decorator with an optional repeat count.
- `lurek.ai.newSucceeder`: Creates a behavior tree succeeder decorator with an empty sequence child.
- `lurek.ai.newAction`: Creates a behavior tree action leaf backed by a Lua callback.
- `lurek.ai.newCondition`: Creates a behavior tree condition leaf backed by a Lua callback.
- `lurek.ai.newGuard`: Creates a guard decorator that runs a predicate before ticking its child.
- `lurek.ai.newSteeringManager`: Creates an empty steering manager with support for built-in and custom behaviors.
- `lurek.ai.newQLearner`: Creates a Q-learner with fixed state and action counts.
- `lurek.ai.newUtilityAI`: Creates an empty utility AI action scorer.
- `lurek.ai.newDialogueAI`: Creates an empty dialogue selector for weighted topics and branches.
- `lurek.ai.newGOAPPlanner`: Creates an empty GOAP planner for boolean world-state planning.
- `lurek.ai.newInfluenceMap`: Creates a grid influence map with the supplied cell dimensions and world cell size.
- `lurek.ai.newSquad`: Creates an empty named squad.
- `lurek.ai.newCommandQueue`: Creates an empty command queue for callback-backed AI commands.
- `lurek.ai.newTraitProfile`: Creates an empty trait profile with modifier support.
- `lurek.ai.newStimulusWorld`: Creates an empty stimulus world for visual and auditory stimulus records.
- `lurek.ai.newContextSteering`: Creates a context steering model with the requested directional slot count.
- `lurek.ai.newNeedSystem`: Creates an empty need system for decaying named needs.
- `lurek.ai.newAIDirector`: Creates an AI director for tension, phase, and pacing factor calculations.
- `lurek.ai.newHTNDomain`: Creates an empty hierarchical task network domain.
- `lurek.ai.newMCTSEngine`: Creates a Monte Carlo tree search engine with deterministic configuration.
- `lurek.ai.newEmotionModel`: Creates an empty emotion model for named decaying emotion values.
- `lurek.ai.newORCASolver`: Creates an ORCA avoidance solver with the supplied prediction horizon.
- `lurek.ai.newNeuralNet`: Creates an empty feed-forward neural network.
- `lurek.ai.newGeneticAlgorithm`: Creates a genetic algorithm population with fixed chromosome length.
- `lurek.ai.newBandit`: Creates a multi-armed bandit with a named selection strategy.
- `lurek.ai.newNeuroevolution`: Creates a neuroevolution population from a layer specification table.
- `lurek.ai.newStrategyAI`: Creates a strategy AI that reevaluates goals on a fixed interval.
- `lurek.ai.newAILod`: Creates a default AI level-of-detail tier selector.

### `LAIBlackboard` Methods
- `LAIBlackboard:setNumber`: Stores a numeric fact under the given blackboard key.
- `LAIBlackboard:getNumber`: Returns a numeric blackboard fact or the provided fallback when the key is missing or not numeric.
- `LAIBlackboard:setBool`: Stores a boolean fact under the given blackboard key.
- `LAIBlackboard:getBool`: Returns a boolean blackboard fact or the provided fallback when the key is missing or not boolean.
- `LAIBlackboard:setString`: Stores a string fact under the given blackboard key.
- `LAIBlackboard:getString`: Returns a string blackboard fact or the provided fallback when the key is missing or not a string.
- `LAIBlackboard:has`: Returns whether the blackboard contains any entry for the given key.
- `LAIBlackboard:remove`: Removes the given key from the blackboard if it exists.
- `LAIBlackboard:clear`: Removes every local entry from this blackboard.
- `LAIBlackboard:getKeys`: Returns every local blackboard key in an array-style Lua table.
- `LAIBlackboard:getSize`: Returns the number of entries currently stored in this blackboard.
- `LAIBlackboard:type`: Returns the Lua-visible type name for this blackboard handle.
- `LAIBlackboard:typeOf`: Returns whether this blackboard handle matches a supported type name.

### `LAIDirector` Methods
- `LAIDirector:pushEvent`: Adds an event intensity sample to the director tension model.
- `LAIDirector:update`: Advances director tension decay and phase evaluation.
- `LAIDirector:tension`: Returns the current director tension value.
- `LAIDirector:phase`: Returns the current director phase name.
- `LAIDirector:spawnRateFactor`: Returns the spawn-rate multiplier derived from current tension and phase.
- `LAIDirector:lootFactor`: Returns the loot multiplier derived from current tension and phase.
- `LAIDirector:ambientIntensity`: Returns the ambient intensity derived from current tension and phase.
- `LAIDirector:setTension`: Directly sets the director tension value.
- `LAIDirector:reset`: Resets director tension and phase state to defaults.
- `LAIDirector:type`: Returns the Lua-visible type name for this AI director handle.
- `LAIDirector:typeOf`: Returns whether this AI director handle matches a supported type name.

### `LAILod` Methods
- `LAILod:tierFor`: Returns the LOD tier for an agent position relative to a reference position.
- `LAILod:shouldUpdate`: Returns whether a tier should update on a given frame counter.
- `LAILod:tierCount`: Returns the number of configured AI LOD tiers.
- `LAILod:tierName`: Returns the name of an AI LOD tier when the index is valid.
- `LAILod:type`: Returns the Lua-visible type name for this AI LOD handle.
- `LAILod:typeOf`: Returns whether this AI LOD handle matches a supported type name.

### `LAIWorld` Methods
- `LAIWorld:addAgent`: Creates a named agent in this world and returns a handle that can edit its movement and decision state.
- `LAIWorld:getAgent`: Returns the named agent handle when it exists in this world.
- `LAIWorld:removeAgent`: Removes an agent from this world by using an existing agent handle.
- `LAIWorld:getAgentCount`: Returns the number of agents currently stored in this world.
- `LAIWorld:getGlobalBlackboard`: Returns a blackboard snapshot containing the world's shared AI facts.
- `LAIWorld:update`: Advances the world simulation and invokes custom decision callbacks for agents that use a custom model.
- `LAIWorld:type`: Returns the Lua-visible type name for this AI world handle.
- `LAIWorld:typeOf`: Returns whether this AI world handle matches a supported type name.

### `LAgent` Methods
- `LAgent:getName`: Returns this agent's stable world name.
- `LAgent:setPosition`: Sets this agent's world position when the agent still exists in its world.
- `LAgent:getPosition`: Returns this agent's world position or the origin when the agent has been removed.
- `LAgent:setVelocity`: Sets this agent's velocity vector when the agent still exists in its world.
- `LAgent:getVelocity`: Returns this agent's velocity vector or zero velocity when the agent has been removed.
- `LAgent:setMaxSpeed`: Sets this agent's maximum movement speed when the agent still exists in its world.
- `LAgent:getMaxSpeed`: Returns this agent's maximum movement speed or the default speed for a missing agent.
- `LAgent:setMaxForce`: Sets this agent's maximum steering force when the agent still exists in its world.
- `LAgent:getMaxForce`: Returns this agent's maximum steering force or the default force for a missing agent.
- `LAgent:setPriority`: Sets this agent's integer priority when the agent still exists in its world.
- `LAgent:getPriority`: Returns this agent's integer priority or zero when the agent has been removed.
- `LAgent:setDecisionModel`: Sets this agent's built-in decision model from a string name when the name is recognized.
- `LAgent:getDecisionModel`: Returns this agent's decision model name or the default model name for a missing agent.
- `LAgent:setCustomModel`: Installs a Lua callback as this agent's decision model and stores it in the callback registry.
- `LAgent:addTag`: Adds a tag string to this agent when the agent still exists in its world.
- `LAgent:removeTag`: Removes a tag string from this agent when the agent still exists in its world.
- `LAgent:hasTag`: Returns whether this agent currently has the given tag.
- `LAgent:getBlackboard`: Returns a blackboard snapshot for this agent or an empty blackboard when the agent has been removed.
- `LAgent:type`: Returns the Lua-visible type name for this agent handle.
- `LAgent:typeOf`: Returns whether this agent handle matches a supported type name.

### `LBTNode` Methods
- `LBTNode:addChild`: Adds a child node to a composite selector, sequence, or parallel node.
- `LBTNode:getChildCount`: Returns the number of children owned by this behavior tree node.
- `LBTNode:reset`: Resets this behavior tree node's runtime state.
- `LBTNode:setChild`: Sets the single child of a decorator node such as inverter, repeater, or succeeder.
- `LBTNode:setCount`: Sets the repeat count when this node is a repeater.
- `LBTNode:getCount`: Returns the repeat count for repeater nodes or zero for other node kinds.
- `LBTNode:setSuccessPolicy`: Sets the success policy for a parallel node.
- `LBTNode:setFailurePolicy`: Sets the failure policy for a parallel node.
- `LBTNode:getNodeType`: Returns the behavior tree node kind as a lowercase string.
- `LBTNode:type`: Returns the Lua-visible type name for this behavior tree node handle.
- `LBTNode:typeOf`: Returns whether this behavior tree node handle matches a supported type name.

### `LBandit` Methods
- `LBandit:select`: Selects an arm using the configured bandit strategy.
- `LBandit:update`: Updates one arm with a received reward.
- `LBandit:bestArm`: Returns the arm with the best current estimate.
- `LBandit:reset`: Resets all bandit arm statistics.
- `LBandit:armCount`: Returns the number of arms in this bandit.
- `LBandit:totalPulls`: Returns the total number of arm selections recorded by this bandit.
- `LBandit:type`: Returns the Lua-visible type name for this bandit handle.
- `LBandit:typeOf`: Returns whether this bandit handle matches a supported type name.

### `LBehaviorTree` Methods
- `LBehaviorTree:setRoot`: Sets the behavior tree root by moving a node handle into the tree.
- `LBehaviorTree:getLastStatus`: Returns the last behavior tree status string recorded by the tree.
- `LBehaviorTree:getDebugState`: Returns behavior tree debug counters and status in a Lua table.
- `LBehaviorTree:type`: Returns the Lua-visible type name for this behavior tree handle.
- `LBehaviorTree:typeOf`: Returns whether this behavior tree handle matches a supported type name.

### `LCommandQueue` Methods
- `LCommandQueue:enqueue`: Adds a command callback to the back of the queue.
- `LCommandQueue:pushFront`: Adds a command callback to the front of the queue.
- `LCommandQueue:replace`: Replaces the queue contents with one command callback.
- `LCommandQueue:cancelCurrent`: Cancels the currently active command when one exists.
- `LCommandQueue:clear`: Removes every queued command.
- `LCommandQueue:getCount`: Returns the number of commands currently queued.
- `LCommandQueue:isEmpty`: Returns whether the command queue has no commands.
- `LCommandQueue:getCurrentType`: Returns the type label of the current command when one exists.
- `LCommandQueue:getCurrentTarget`: Returns the current command target coordinates.
- `LCommandQueue:type`: Returns the Lua-visible type name for this command queue handle.
- `LCommandQueue:typeOf`: Returns whether this command queue handle matches a supported type name.

### `LContextSteering` Methods
- `LContextSteering:addSeekTarget`: Adds a context steering target attraction.
- `LContextSteering:addWander`: Adds wander noise to context steering.
- `LContextSteering:addAvoidPoint`: Adds a point avoidance influence to context steering.
- `LContextSteering:addAvoidBounds`: Adds rectangular bounds avoidance to context steering.
- `LContextSteering:clearBehaviors`: Removes all context steering behaviors.
- `LContextSteering:evaluate`: Evaluates context steering and returns the selected movement direction.
- `LContextSteering:chosenMagnitude`: Returns the magnitude of the last selected context steering slot.
- `LContextSteering:slotCount`: Returns the number of directional slots used by this context steering model.
- `LContextSteering:type`: Returns the Lua-visible type name for this context steering handle.
- `LContextSteering:typeOf`: Returns whether this context steering handle matches a supported type name.

### `LDialogueAI` Methods
- `LDialogueAI:setFSMState`: Sets the finite-state-machine state used as dialogue selection context.
- `LDialogueAI:setBTStatus`: Sets the behavior-tree status used as dialogue selection context.
- `LDialogueAI:setUtilityScore`: Stores a utility score used by topics and branches that reference the given key.
- `LDialogueAI:clearUtilityScores`: Removes every stored utility score from this dialogue selector.
- `LDialogueAI:addTopic`: Adds a selectable dialogue topic with optional context filters.
- `LDialogueAI:addBranch`: Adds a selectable branch under an existing dialogue topic.
- `LDialogueAI:selectTopic`: Selects the best currently valid topic using weights and context filters.
- `LDialogueAI:selectBranch`: Selects the best currently valid branch for the given topic.
- `LDialogueAI:getTopicCount`: Returns the number of topics registered in this dialogue selector.
- `LDialogueAI:type`: Returns the Lua-visible type name for this dialogue AI handle.
- `LDialogueAI:typeOf`: Returns whether this dialogue AI handle matches a supported type name.

### `LEmotionModel` Methods
- `LEmotionModel:add`: Adds an emotion definition with resting value, decay, and visibility threshold.
- `LEmotionModel:trigger`: Adds an amount to a named emotion.
- `LEmotionModel:get`: Returns the current value of a named emotion.
- `LEmotionModel:dominant`: Returns the strongest active emotion name when one is available.
- `LEmotionModel:isActive`: Returns whether a named emotion is currently active.
- `LEmotionModel:update`: Advances emotion decay over elapsed time.
- `LEmotionModel:reset`: Resets all emotions toward their default state.
- `LEmotionModel:type`: Returns the Lua-visible type name for this emotion model handle.
- `LEmotionModel:typeOf`: Returns whether this emotion model handle matches a supported type name.

### `LGOAPPlanner` Methods
- `LGOAPPlanner:addAction`: Adds a GOAP action with optional cost and completion callback.
- `LGOAPPlanner:setPrecondition`: Sets one boolean precondition for an existing GOAP action.
- `LGOAPPlanner:setEffect`: Sets one boolean effect produced by an existing GOAP action.
- `LGOAPPlanner:addGoal`: Adds a GOAP goal with an optional priority weight.
- `LGOAPPlanner:setGoalState`: Sets one desired world-state key for an existing GOAP goal.
- `LGOAPPlanner:plan`: Builds a plan from the supplied boolean world state and returns action names in execution order.
- `LGOAPPlanner:getActionCount`: Returns the number of GOAP actions registered in this planner.
- `LGOAPPlanner:getGoalCount`: Returns the number of GOAP goals registered in this planner.
- `LGOAPPlanner:getMaxIterations`: Returns the maximum number of planner iterations allowed during search.
- `LGOAPPlanner:setMaxIterations`: Sets the maximum number of planner iterations allowed during search.
- `LGOAPPlanner:type`: Returns the Lua-visible type name for this GOAP planner handle.
- `LGOAPPlanner:typeOf`: Returns whether this GOAP planner handle matches a supported type name.

### `LGeneticAlgorithm` Methods
- `LGeneticAlgorithm:evolve`: Advances the genetic algorithm by one generation.
- `LGeneticAlgorithm:generation`: Returns the current generation index.
- `LGeneticAlgorithm:popSize`: Returns the population size.
- `LGeneticAlgorithm:setFitness`: Sets the fitness value for a chromosome by zero-based index.
- `LGeneticAlgorithm:getGenes`: Returns the genes for a chromosome by zero-based index.
- `LGeneticAlgorithm:bestGenes`: Returns the genes for the best chromosome in the population.
- `LGeneticAlgorithm:type`: Returns the Lua-visible type name for this genetic algorithm handle.
- `LGeneticAlgorithm:typeOf`: Returns whether this genetic algorithm handle matches a supported type name.

### `LHTNDomain` Methods
- `LHTNDomain:addPrimitive`: Adds a primitive HTN task with preconditions, effects, and cleared facts.
- `LHTNDomain:addCompound`: Adds a compound HTN task with one or more ordered method definitions.
- `LHTNDomain:plan`: Plans from a root HTN task and numeric world state facts.
- `LHTNDomain:taskCount`: Returns the number of tasks defined in this HTN domain.
- `LHTNDomain:type`: Returns the Lua-visible type name for this HTN domain handle.
- `LHTNDomain:typeOf`: Returns whether this HTN domain handle matches a supported type name.

### `LInfluenceMap` Methods
- `LInfluenceMap:addLayer`: Adds an influence layer with the given name if it does not already exist.
- `LInfluenceMap:hasLayer`: Returns whether an influence layer exists.
- `LInfluenceMap:setInfluence`: Sets one cell value in a named influence layer using one-based cell coordinates.
- `LInfluenceMap:getInfluence`: Returns one cell value from a named influence layer using one-based cell coordinates.
- `LInfluenceMap:stampInfluence`: Applies a radial influence stamp to a named layer in world coordinates.
- `LInfluenceMap:propagate`: Propagates influence values across neighboring cells on a named layer.
- `LInfluenceMap:decay`: Multiplies a named layer by a decay factor.
- `LInfluenceMap:clearLayer`: Clears every value in a named influence layer.
- `LInfluenceMap:clearAll`: Clears every influence value in every layer.
- `LInfluenceMap:getMaxPosition`: Returns the cell position with the highest value on a named layer.
- `LInfluenceMap:getMinPosition`: Returns the cell position with the lowest value on a named layer.
- `LInfluenceMap:queryRect`: Returns influence values inside a world-space rectangle on a named layer.
- `LInfluenceMap:blend`: Blends two source layers into a destination layer using independent weights.
- `LInfluenceMap:getWidth`: Returns the influence map width in cells.
- `LInfluenceMap:getHeight`: Returns the influence map height in cells.
- `LInfluenceMap:getCellSize`: Returns the world size represented by each influence map cell.
- `LInfluenceMap:type`: Returns the Lua-visible type name for this influence map handle.
- `LInfluenceMap:typeOf`: Returns whether this influence map handle matches a supported type name.

### `LMCTSEngine` Methods
- `LMCTSEngine:search`: Runs MCTS from a root state using Lua callbacks for actions, transitions, and evaluation.
- `LMCTSEngine:type`: Returns the Lua-visible type name for this MCTS engine handle.
- `LMCTSEngine:typeOf`: Returns whether this MCTS engine handle matches a supported type name.

### `LNeedSystem` Methods
- `LNeedSystem:addNeed`: Adds a need with decay and urgency tuning values.
- `LNeedSystem:update`: Advances need decay over elapsed time.
- `LNeedSystem:mostUrgent`: Returns the name of the most urgent need when any need is active.
- `LNeedSystem:satisfy`: Reduces or satisfies a named need by the supplied amount.
- `LNeedSystem:valueOf`: Returns the current value of a named need.
- `LNeedSystem:type`: Returns the Lua-visible type name for this need system handle.
- `LNeedSystem:typeOf`: Returns whether this need system handle matches a supported type name.

### `LNeuralNet` Methods
- `LNeuralNet:addLayer`: Adds a neural network layer with an activation function.
- `LNeuralNet:forward`: Runs a forward pass and returns output values.
- `LNeuralNet:setWeights`: Replaces the network weights from a flat numeric array.
- `LNeuralNet:getWeights`: Returns the network weights as a flat numeric array.
- `LNeuralNet:paramCount`: Returns the total number of trainable parameters.
- `LNeuralNet:layerCount`: Returns the number of layers in the network.
- `LNeuralNet:type`: Returns the Lua-visible type name for this neural network handle.
- `LNeuralNet:typeOf`: Returns whether this neural network handle matches a supported type name.

### `LNeuroevolution` Methods
- `LNeuroevolution:evolve`: Advances the neuroevolution population by one generation.
- `LNeuroevolution:setFitness`: Sets the fitness value for a chromosome by zero-based index.
- `LNeuroevolution:chromosomeToNet`: Converts one chromosome into a neural network handle when the index is valid.
- `LNeuroevolution:bestNetwork`: Converts the best chromosome into a neural network handle when one exists.
- `LNeuroevolution:bestFitness`: Returns the best fitness value in the population.
- `LNeuroevolution:popSize`: Returns the population size.
- `LNeuroevolution:generation`: Returns the current generation index.
- `LNeuroevolution:type`: Returns the Lua-visible type name for this neuroevolution handle.
- `LNeuroevolution:typeOf`: Returns whether this neuroevolution handle matches a supported type name.

### `LORCASolver` Methods
- `LORCASolver:addAgent`: Adds an ORCA avoidance agent and returns its zero-based solver index.
- `LORCASolver:setPreferredVelocity`: Sets the preferred velocity for an ORCA agent by zero-based index.
- `LORCASolver:setPosition`: Sets the position for an ORCA agent by zero-based index.
- `LORCASolver:compute`: Computes safe velocities for all ORCA agents.
- `LORCASolver:getSafeVelocity`: Returns the computed safe velocity for an ORCA agent.
- `LORCASolver:agentCount`: Returns the number of ORCA agents in this solver.
- `LORCASolver:type`: Returns the Lua-visible type name for this ORCA solver handle.
- `LORCASolver:typeOf`: Returns whether this ORCA solver handle matches a supported type name.

### `LQLearner` Methods
- `LQLearner:chooseAction`: Chooses an action for a one-based state index using the learner's exploration policy.
- `LQLearner:bestAction`: Returns the highest-valued action for a one-based state index without exploration.
- `LQLearner:learn`: Applies one Q-learning update from a transition and reward.
- `LQLearner:getQValue`: Returns the stored Q-value for a one-based state and action pair.
- `LQLearner:setQValue`: Sets the stored Q-value for a one-based state and action pair.
- `LQLearner:endEpisode`: Ends the current learning episode and applies episode bookkeeping.
- `LQLearner:getEpisodeCount`: Returns how many learning episodes have been completed.
- `LQLearner:getStateCount`: Returns the number of states represented by this learner.
- `LQLearner:getActionCount`: Returns the number of actions represented by this learner.
- `LQLearner:setLearningRate`: Sets the Q-learning alpha learning rate.
- `LQLearner:getLearningRate`: Returns the Q-learning alpha learning rate.
- `LQLearner:setDiscountFactor`: Sets the Q-learning gamma discount factor.
- `LQLearner:getDiscountFactor`: Returns the Q-learning gamma discount factor.
- `LQLearner:setExplorationRate`: Sets the exploration rate used by action selection.
- `LQLearner:getExplorationRate`: Returns the exploration rate used by action selection.
- `LQLearner:setExplorationDecay`: Sets the exploration decay multiplier applied across episodes.
- `LQLearner:getExplorationDecay`: Returns the exploration decay multiplier.
- `LQLearner:serialize`: Serializes the Q-learner state to a JSON string.
- `LQLearner:deserialize`: Replaces the Q-learner state from a JSON string.
- `LQLearner:type`: Returns the Lua-visible type name for this Q-learner handle.
- `LQLearner:typeOf`: Returns whether this Q-learner handle matches a supported type name.

### `LSquad` Methods
- `LSquad:getName`: Returns the squad name.
- `LSquad:addMember`: Adds a member name to the squad member list.
- `LSquad:removeMember`: Removes every member entry with the given name.
- `LSquad:getMemberCount`: Returns the number of members in this squad.
- `LSquad:getMembers`: Returns all squad members in an array-style Lua table.
- `LSquad:setLeader`: Sets the squad leader name.
- `LSquad:getLeader`: Returns the squad leader name when one is assigned.
- `LSquad:setFormation`: Sets the squad formation type and optionally updates spacing.
- `LSquad:getFormation`: Returns the current squad formation type name.
- `LSquad:getFormationSpacing`: Returns the spacing used by squad formation positioning.
- `LSquad:getFormationPosition`: Returns a member's target formation position relative to the leader position.
- `LSquad:getBlackboard`: Returns a blackboard snapshot for this squad.
- `LSquad:type`: Returns the Lua-visible type name for this squad handle.
- `LSquad:typeOf`: Returns whether this squad handle matches a supported type name.

### `LStateMachine` Methods
- `LStateMachine:addState`: Adds a state with optional Lua lifecycle callbacks.
- `LStateMachine:addTransition`: Adds a transition between two states with an optional guard callback and priority.
- `LStateMachine:setInitialState`: Sets the initial state and also enters it when the machine has no current state yet.
- `LStateMachine:getCurrentState`: Returns the current state name when the state machine has entered a state.
- `LStateMachine:forceState`: Immediately switches the current state and resets the time spent in state.
- `LStateMachine:getTimeInState`: Returns how long the machine has spent in the current state.
- `LStateMachine:type`: Returns the Lua-visible type name for this state machine handle.
- `LStateMachine:typeOf`: Returns whether this state machine handle matches a supported type name.

### `LSteeringManager` Methods
- `LSteeringManager:addSeek`: Adds a seek behavior that pulls the agent toward a target point.
- `LSteeringManager:addFlee`: Adds a flee behavior that pushes the agent away from a target point inside a panic distance.
- `LSteeringManager:addArrive`: Adds an arrive behavior that slows the agent as it approaches a target point.
- `LSteeringManager:addWander`: Adds a wander behavior that produces jittered exploratory movement.
- `LSteeringManager:addPursue`: Adds a pursue behavior that chases another named agent when a target name is supplied.
- `LSteeringManager:addEvade`: Adds an evade behavior that moves away from another named agent when a threat name is supplied.
- `LSteeringManager:addFlock`: Adds a flocking behavior with separation, alignment, and cohesion weights.
- `LSteeringManager:getBehaviorCount`: Returns the number of steering behaviors configured on this manager.
- `LSteeringManager:setCombineMode`: Sets how steering behavior forces are combined.
- `LSteeringManager:getCombineMode`: Returns the current steering force combination mode.
- `LSteeringManager:getLastSteering`: Returns the last steering force calculated by this manager.
- `LSteeringManager:calculate`: Calculates a steering force for the supplied agent movement state.
- `LSteeringManager:setPath`: Sets a waypoint path behavior from an array of `{x, y}` tables.
- `LSteeringManager:clearPath`: Clears the active waypoint path behavior.
- `LSteeringManager:hasPath`: Returns whether this manager currently has an active waypoint path.
- `LSteeringManager:getPathProgress`: Returns the current one-based waypoint index and total waypoint count.
- `LSteeringManager:type`: Returns the Lua-visible type name for this steering manager handle.
- `LSteeringManager:typeOf`: Returns whether this steering manager handle matches a supported type name.
- `LSteeringManager:setSpatialHashCellSize`: Sets the cell size used by the steering manager spatial hash.
- `LSteeringManager:enableSpatialHash`: Enables or disables spatial hash acceleration for neighbor queries.
- `LSteeringManager:addCustomBehavior`: Adds a custom steering behavior backed by a Lua callback.
- `LSteeringManager:applyCustomSteering`: Runs enabled custom steering callbacks for an agent and returns the weighted combined force.

### `LStimulusWorld` Methods
- `LStimulusWorld:addVisual`: Adds a visual stimulus and returns its identifier.
- `LStimulusWorld:addAuditory`: Adds an auditory stimulus with decay and returns its identifier.
- `LStimulusWorld:remove`: Removes a stimulus by identifier.
- `LStimulusWorld:update`: Advances stimulus decay and lifetime state.
- `LStimulusWorld:count`: Returns the number of active stimuli.
- `LStimulusWorld:clear`: Removes every active stimulus.
- `LStimulusWorld:type`: Returns the Lua-visible type name for this stimulus world handle.
- `LStimulusWorld:typeOf`: Returns whether this stimulus world handle matches a supported type name.

### `LStrategyAI` Methods
- `LStrategyAI:addGoal`: Adds a named strategic goal.
- `LStrategyAI:addTag`: Adds a context tag to this strategy AI.
- `LStrategyAI:removeTag`: Removes a context tag from this strategy AI.
- `LStrategyAI:update`: Advances strategy timing and scores goals when the update interval has elapsed.
- `LStrategyAI:forceEvaluate`: Immediately scores all goals and updates the active goal.
- `LStrategyAI:activeGoal`: Returns the currently active strategic goal when one is selected.
- `LStrategyAI:timeUntilNext`: Returns time remaining until the next scheduled strategy evaluation.
- `LStrategyAI:type`: Returns the Lua-visible type name for this strategy AI handle.
- `LStrategyAI:typeOf`: Returns whether this strategy AI handle matches a supported type name.

### `LTraitProfile` Methods
- `LTraitProfile:set`: Sets the base value for a named trait.
- `LTraitProfile:get`: Returns the current value of a named trait including active modifiers.
- `LTraitProfile:getBase`: Returns the base value of a named trait without temporary modifiers.
- `LTraitProfile:addModifier`: Adds a temporary or permanent modifier to a named trait.
- `LTraitProfile:removeModifiers`: Removes all trait modifiers that match a source label.
- `LTraitProfile:update`: Advances modifier timers and removes expired modifiers.
- `LTraitProfile:has`: Returns whether the profile has a named trait.
- `LTraitProfile:traitCount`: Returns the number of traits stored in the profile.
- `LTraitProfile:archetype`: Returns the best matching archetype name when the profile can classify one.
- `LTraitProfile:type`: Returns the Lua-visible type name for this trait profile handle.
- `LTraitProfile:typeOf`: Returns whether this trait profile handle matches a supported type name.

### `LUtilityAI` Methods
- `LUtilityAI:addAction`: Adds an action scored by a Lua callback and optional momentum weight.
- `LUtilityAI:evaluate`: Evaluates all actions and returns the winning action name when one is available.
- `LUtilityAI:getActionCount`: Returns the number of actions registered in this utility AI.
- `LUtilityAI:getLastAction`: Returns the last winning action name when evaluation has selected one.
- `LUtilityAI:addConsideration`: Adds a consideration scorer and response curve to an existing utility action.
- `LUtilityAI:type`: Returns the Lua-visible type name for this utility AI handle.
- `LUtilityAI:typeOf`: Returns whether this utility AI handle matches a supported type name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ai/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
