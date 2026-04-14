# ai

## General Info

- Module group: `Feature Systems`
- Source path: `src/ai/`
- Lua API path(s): `src/lua_api/ai_api.rs`
- Primary Lua namespace: `lurek.ai`
- Rust test path(s): tests/rust/unit/ai_tests.rs, tests/rust/game/ai_tests.rs
- Lua test path(s): tests/lua/unit/test_ai.lua, tests/lua/golden/test_ai_golden.lua, tests/lua/integration/test_entity_ai.lua, tests/lua/integration/test_ai_physics.lua, tests/lua/integration/test_ai_pathfinding.lua, tests/lua/integration/test_ai_entity_scene.lua, tests/lua/stress/test_ai_stress.lua

## Summary

The `ai` module provides Lurek2D's comprehensive game AI toolkit. It is a Feature Systems tier module that offers a suite of decoupled AI subsystems, each usable independently or composed through the central `AIWorld` / `Agent` framework. All AI computation is pure CPU math with no GPU, audio, or window access, enabling headless testing without a graphics context.

The `AIWorld` owns all `Agent` instances. Each agent carries kinematic state (position, velocity, max speed and force), a `DecisionModel` that selects which subsystems are ticked each frame, and a local `Blackboard` that chains to the world's global blackboard for hierarchical key-value lookup. Agents are ticked in descending priority order during `update(dt)`.

Available AI subsystems: `fsm` — finite state machine with priority-ordered guarded transitions; `behavior_tree` — hierarchical BT with composites, decorators, and leaf callbacks; `steering` — Reynolds-style behaviors (seek, flee, arrive, wander, pursue, evade, flock, separation); `goap` — Goal-Oriented Action Planning using A\* over boolean world state; `utility_ai` — multi-axis utility scorer with response curves; `qlearner` — tabular epsilon-greedy Q-learning; `influence_map` — multi-layer spatial float grid for strategic area analysis; `squad` — squad coordination with formation offset computation; `command_queue` — RTS-style ordered command queue with interrupt and cancel; `blackboard` — hierarchical key-value store for inter-agent data sharing.

Flow-field and grid pathfinding types (`FlowField`, `Cell`, `PathGrid`) are re-exported directly from `crate::pathfind`, so `lurek.ai.*` provides a unified scripting surface without requiring callers to import PathFind separately.

**Scope boundary**: Feature Systems tier. Depends on `math`, `pathfind`, `runtime`. Lua bridge in `src/lua_api/ai_api.rs`.

## Files

- `agent.rs`: Defines the core `Agent` record and the top-level decision-model selection enum used to attach different AI styles to an actor.
- `bandit.rs`: Multi-armed bandit algorithms for AI exploration/exploitation decisions.
- `behavior_tree.rs`: Implements behavior tree nodes, statuses, composite policies, and the execution model for hierarchical decision logic.
- `blackboard.rs`: Provides a hierarchical key-value blackboard for local and shared AI state.
- `command_queue.rs`: Implements queued AI commands with priorities, interruptibility, and callback integration.
- `context_steering.rs`: Context Steering — direction-based interest/danger evaluation for smooth movement.
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
- `BlackboardValue` (`enum`, `blackboard.rs`): The value enum stored in a `Blackboard`.
- `Blackboard` (`struct`, `blackboard.rs`): Hierarchical key-value state store used for AI coordination and memory.
- `Command` (`struct`, `command_queue.rs`): One queued AI command with priority and callback information.
- `CommandQueue` (`struct`, `command_queue.rs`): Ordered queue of AI commands waiting to run or interrupt one another.
- `ContextBehaviorKind` (`enum`, `context_steering.rs`): Variant of a context steering behavior defining how it fills the ring.
- `ContextBehavior` (`struct`, `context_steering.rs`): A single context steering behavior with a weight and enabled flag.
- `ContextSteering` (`struct`, `context_steering.rs`): Radial context steering evaluator producing a smooth, obstacle-aware movement direction.
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

- `DecisionModel::parse_str` (`agent.rs`): Parses a Lua-side string identifier into the corresponding `DecisionModel`.
- `DecisionModel::as_str` (`agent.rs`): Returns the canonical Lua string identifier for this decision model.
- `Agent::new` (`agent.rs`): Creates a new agent with sensible default kinematic state.
- `BanditArm::mean_reward` (`bandit.rs`): Returns the mean estimated reward (0.5 when unpulled).
- `Bandit::new` (`bandit.rs`): Creates a new bandit with `arm_count` arms and the given strategy.
- `Bandit::arm_count` (`bandit.rs`): Returns the number of arms.
- `Bandit::select` (`bandit.rs`): Selects an arm index using the configured strategy.
- `Bandit::update` (`bandit.rs`): Records the observed `reward` for arm `index` and updates arm statistics.
- `Bandit::best_arm` (`bandit.rs`): Returns the index of the arm with the highest mean reward.
- `Bandit::reset` (`bandit.rs`): Resets all arm statistics while keeping arm count and strategy.
- `BTStatus::parse_str` (`behavior_tree.rs`): Converts a Lua status string into a `BTStatus`.
- `BTStatus::as_str` (`behavior_tree.rs`): Returns the canonical Lua string for this status.
- `ParallelPolicy::parse_str` (`behavior_tree.rs`): Parses a Lua string (`"requireOne"` or `"requireAll"`) into a policy.
- `ParallelPolicy::as_str` (`behavior_tree.rs`): Returns the Lua string identifier for this policy.
- `BTNode::reset` (`behavior_tree.rs`): Recursively resets all running-child memos and repeater counters.
- `BTNode::child_count` (`behavior_tree.rs`): Returns the number of direct children this node has.
- `BehaviorTree::new` (`behavior_tree.rs`): Creates a new behavior tree with no root node.
- `Blackboard::new` (`blackboard.rs`): Creates an empty Blackboard with no parent.
- `Blackboard::set_number` (`blackboard.rs`): Sets a number value in the local store.
- `Blackboard::get_number` (`blackboard.rs`): Gets a number value, walking the parent chain.
- `Blackboard::set_bool` (`blackboard.rs`): Sets a boolean value in the local store.
- `Blackboard::get_bool` (`blackboard.rs`): Gets a boolean value, walking the parent chain.
- `Blackboard::set_string` (`blackboard.rs`): Sets a string value in the local store.
- `Blackboard::get_string` (`blackboard.rs`): Gets a string value, walking the parent chain.
- `Blackboard::has` (`blackboard.rs`): Checks if a key exists locally or in any ancestor.
- `Blackboard::remove` (`blackboard.rs`): Removes a key from the local store only.
- `Blackboard::clear` (`blackboard.rs`): Clears all local entries.
- `Blackboard::keys` (`blackboard.rs`): Returns all local key names.
- `Blackboard::size` (`blackboard.rs`): Returns the number of local entries.
- `Blackboard::set_parent` (`blackboard.rs`): Sets the parent Blackboard for hierarchical lookup.
- `Blackboard::parent` (`blackboard.rs`): Returns a reference to the parent Blackboard, if any.
- `CommandQueue::new` (`command_queue.rs`): Creates a new empty command queue.
- `CommandQueue::enqueue` (`command_queue.rs`): Appends a command to the back of the queue.
- `CommandQueue::push_front` (`command_queue.rs`): Inserts a command at the front (interrupts current without clearing).
- `CommandQueue::replace` (`command_queue.rs`): Clears the queue and enqueues one new command.
- `CommandQueue::cancel_current` (`command_queue.rs`): Cancels the current (front) command if it's interruptible.
- `CommandQueue::clear` (`command_queue.rs`): Clears all commands.
- `CommandQueue::count` (`command_queue.rs`): Returns the number of queued commands.
- `CommandQueue::is_empty` (`command_queue.rs`): Returns whether the queue is empty.
- `CommandQueue::current_type` (`command_queue.rs`): Returns the type of the front command, if any.
- `CommandQueue::current_target` (`command_queue.rs`): Returns the target coordinates of the front command.
- `CommandQueue::advance` (`command_queue.rs`): Advances the queue by removing the front command.
- `CommandQueue::enqueue_raw` (`command_queue.rs`): Appends a new command built from raw parameters.
- `CommandQueue::push_front_raw` (`command_queue.rs`): Inserts at the front from raw parameters.
- `CommandQueue::replace_raw` (`command_queue.rs`): Clears the queue and replaces with a single command from raw parameters.
- `ContextSteering::new` (`context_steering.rs`): Creates a new context steering evaluator with `slot_count` direction slots.
- `ContextSteering::slot_count` (`context_steering.rs`): Returns the number of direction slots.
- `ContextSteering::add_interest` (`context_steering.rs`): Adds a behavior that fills the interest ring (where to go).
- `ContextSteering::add_danger` (`context_steering.rs`): Adds a behavior that fills the danger ring (where NOT to go).
- `ContextSteering::add_seek_target` (`context_steering.rs`): Adds a `SeekTarget` interest behavior pointing toward `(tx, ty)`.
- `ContextSteering::add_wander` (`context_steering.rs`): Adds a `Wander` interest behavior.
- `ContextSteering::add_avoid_point` (`context_steering.rs`): Adds an `AvoidPoint` danger behavior.
- `ContextSteering::add_avoid_bounds` (`context_steering.rs`): Adds an `AvoidBounds` danger behavior.
- `ContextSteering::clear_behaviors` (`context_steering.rs`): Clears all behaviors, resetting the evaluator to a blank state.
- `ContextSteering::evaluate` (`context_steering.rs`): Evaluates interest and danger rings from the current agent position and velocity, then returns the chosen direction as a normalized `(dx, dy)` pair.
- `ContextSteering::chosen_direction` (`context_steering.rs`): Returns the chosen direction angle from the last `evaluate` call (radians).
- `ContextSteering::chosen_magnitude` (`context_steering.rs`): Returns the chosen magnitude (net interest score) from the last `evaluate` call.
- `ContextSteering::interest_map` (`context_steering.rs`): Returns a copy of the current interest ring values.
- `ContextSteering::danger_map` (`context_steering.rs`): Returns a copy of the current danger ring values.
- `DirectorPhase::as_str` (`director.rs`): Returns the canonical string label for this phase.
- `AIDirector::new` (`director.rs`): Creates a new director with default configuration starting in `Relief` phase.
- `AIDirector::with_config` (`director.rs`): Creates a director with a custom configuration.
- `AIDirector::tension` (`director.rs`): Returns the current tension level in `[0.0, 1.0]`.
- `AIDirector::phase` (`director.rs`): Returns the current pacing phase.
- `AIDirector::phase_str` (`director.rs`): Returns the current phase as a string label.
- `AIDirector::elapsed` (`director.rs`): Returns the total elapsed time in seconds.
- `AIDirector::total_events` (`director.rs`): Returns the total number of events pushed to this director.
- `AIDirector::push_event` (`director.rs`): Pushes a stress event that raises tension.
- `AIDirector::update` (`director.rs`): Advances the director by `dt` seconds.
- `AIDirector::spawn_rate_factor` (`director.rs`): Returns a spawn rate multiplier for game systems.
- `AIDirector::loot_factor` (`director.rs`): Returns a loot drop multiplier for game systems (highest during relief).
- `AIDirector::ambient_intensity` (`director.rs`): Returns an ambient intensity value `[0.0, 1.0]` for music and atmosphere.
- `AIDirector::set_tension` (`director.rs`): Manually overrides the tension to a specific value (for scripted sequences).
- `AIDirector::reset` (`director.rs`): Resets tension to zero and transitions to Relief phase.
- `Emotion::new` (`emotion.rs`): Creates a new emotion starting at its resting level.
- `Emotion::is_active` (`emotion.rs`): Returns `true` when this emotion's value is at or above `min_visible`.
- `Emotion::trigger` (`emotion.rs`): Bumps the emotion up by `amount`, clamped to `[0.0, 1.0]`.
- `Emotion::set` (`emotion.rs`): Sets the emotion to an exact value, clamped to `[0.0, 1.0]`.
- `Emotion::update` (`emotion.rs`): Advances decay by `dt` seconds, moving toward `resting_level`.
- `EmotionModel::new` (`emotion.rs`): Creates an empty emotion model.
- `EmotionModel::add` (`emotion.rs`): Adds or replaces an emotion by name.
- `EmotionModel::get` (`emotion.rs`): Returns the current value of a named emotion, or `0.0` if not found.
- `EmotionModel::trigger` (`emotion.rs`): Triggers a named emotion by adding `amount` to its current value.
- `EmotionModel::set` (`emotion.rs`): Sets a named emotion to an exact value.
- `EmotionModel::update` (`emotion.rs`): Advances all emotions' decay by `dt` seconds.
- `EmotionModel::dominant` (`emotion.rs`): Returns the name of the dominant (highest active) emotion, or `None` if no emotion is above its `min_visible` threshold.
- `EmotionModel::is_active` (`emotion.rs`): Returns `true` when a named emotion is at or above its `min_visible` threshold.
- `EmotionModel::active_names` (`emotion.rs`): Returns the names of all emotions currently active (above `min_visible`).
- `EmotionModel::count` (`emotion.rs`): Returns the number of emotions registered in this model.
- `EmotionModel::reset` (`emotion.rs`): Resets all emotions to their resting levels.
- `StateMachine::new` (`fsm.rs`): Creates a new empty state machine.
- `StateMachine::add_transition` (`fsm.rs`): Adds a transition and re-sorts by descending priority.
- `StateMachine::current_state` (`fsm.rs`): Returns the current state name, if any.
- `StateMachine::time_in_state` (`fsm.rs`): Returns the time spent in the current state in seconds.
- `StateMachine::add_state_raw` (`fsm.rs`): Adds a named state with optional lifecycle callbacks.
- `StateMachine::add_transition_raw` (`fsm.rs`): Adds a transition with optional guard callback.
- `StateMachine::set_initial_state` (`fsm.rs`): Sets the initial state name.
- `Chromosome::new` (`genetic.rs`): Creates a zeroed chromosome.
- `GeneticAlgorithm::new` (`genetic.rs`): Creates a new GA with a random initial population.
- `GeneticAlgorithm::pop_size` (`genetic.rs`): Returns the population size.
- `GeneticAlgorithm::best` (`genetic.rs`): Returns a reference to the chromosome with highest fitness.
- `GeneticAlgorithm::evolve` (`genetic.rs`): Runs one generation: tournament selection, crossover, mutation, elitism.
- `GOAPPlanner::new` (`goap.rs`): Creates a new empty GOAP planner.
- `GOAPPlanner::plan` (`goap.rs`): Plans a sequence of actions to satisfy the highest-priority goal.
- `GOAPPlanner::plan_for_goal_idx` (`goap.rs`): Plans for a specific goal index.
- `GOAPPlanner::add_action` (`goap.rs`): Adds an action with the given cost and optional Lua callback.
- `GOAPPlanner::add_precondition` (`goap.rs`): Adds a boolean precondition to the named action.
- `GOAPPlanner::add_effect` (`goap.rs`): Adds a boolean effect to the named action.
- `GOAPPlanner::add_goal` (`goap.rs`): Adds a goal with the given name and priority.
- `GOAPPlanner::set_goal_state` (`goap.rs`): Sets a boolean condition on the named goal.
- `HTNTask::name` (`htn.rs`): Returns the name of this task.
- `HTNTask::is_primitive` (`htn.rs`): Returns `true` if this is a primitive task.
- `HTNTask::preconditions_met` (`htn.rs`): Checks whether a primitive's preconditions are satisfied in the given state.
- `HTNTask::apply_effects` (`htn.rs`): Applies this primitive's effects to a mutable world-state clone.
- `HTNMethod::always` (`htn.rs`): Creates a method with no preconditions (always applicable).
- `HTNMethod::with_preconditions` (`htn.rs`): Creates a method with preconditions.
- `HTNMethod::is_applicable` (`htn.rs`): Returns `true` if this method's preconditions are satisfied in `state`.
- `HTNDomain::new` (`htn.rs`): Creates an empty domain.
- `HTNDomain::register` (`htn.rs`): Registers an `HTNTask` in the domain.
- `HTNDomain::add_primitive` (`htn.rs`): Convenience: registers a primitive task with given preconditions and effects.
- `HTNDomain::add_compound` (`htn.rs`): Convenience: registers a compound task with a list of methods.
- `HTNDomain::get` (`htn.rs`): Looks up a task by name.
- `HTNDomain::task_count` (`htn.rs`): Returns the number of registered tasks.
- `HTNPlanner::plan` (`htn.rs`): Plans from `root_task` against `domain` and `initial_state`.
- `LodTier::new` (`lod.rs`): Creates a new LOD tier.
- `AILod::new` (`lod.rs`): Creates a LOD system from a custom tier list.
- `AILod::tier` (`lod.rs`): Returns a reference to the tier at index `i`.
- `AILod::tier_count` (`lod.rs`): Returns the number of tiers.
- `AILod::tier_for` (`lod.rs`): Determines the LOD tier index for an agent at `agent_pos` from `ref_pos`.
- `AILod::assign_tiers` (`lod.rs`): Computes tier indices for a batch of agent positions.
- `AILod::should_update` (`lod.rs`): Returns `true` if an agent in `tier` should be updated on `frame_number`.
- `MCTSEngine::new` (`mcts.rs`): Creates a new MCTS engine with the given configuration.
- `MCTSEngine::config` (`mcts.rs`): Returns a reference to the current configuration.
- `MCTSEngine::search` (`mcts.rs`): Runs MCTS from `root_state` and returns the best action index, or `None` if no actions are available from the root.
- `Need::new` (`needs.rs`): Creates a new need with full satisfaction and the given parameters.
- `Need::is_urgent` (`needs.rs`): Returns `true` when this need's value is below `urgency_threshold`.
- `Need::urgency_score` (`needs.rs`): Returns the urgency score: `urgency_factor * (1.0 - value)`, or `0.0` when disabled.
- `Need::satisfy` (`needs.rs`): Adds `amount` to the current need value, clamped to `[0.0, 1.0]`.
- `Need::deprive` (`needs.rs`): Subtracts `amount` from the current need value (immediate deprivation).
- `Need::update` (`needs.rs`): Advances the need decay by `dt` seconds.
- `NeedAdvertisement::new` (`needs.rs`): Creates a new need advertisement with no cooldown.
- `NeedAdvertisement::is_available` (`needs.rs`): Returns `true` if the advertisement is currently available (no cooldown remaining).
- `NeedAdvertisement::use_it` (`needs.rs`): Marks the advertisement as used, starting the cooldown timer.
- `NeedAdvertisement::update` (`needs.rs`): Advances the cooldown timer by `dt` seconds.
- `NeedAdvertisement::score` (`needs.rs`): Scores this advertisement for an agent at `agent_pos` relative to `need_urgency`.
- `NeedSystem::new` (`needs.rs`): Creates an empty need system.
- `NeedSystem::add_need` (`needs.rs`): Adds a need to this system.
- `NeedSystem::get` (`needs.rs`): Returns a reference to the need with the given name, or `None`.
- `NeedSystem::get_mut` (`needs.rs`): Returns a mutable reference to the need with the given name, or `None`.
- `NeedSystem::update` (`needs.rs`): Advances all needs by `dt` seconds.
- `NeedSystem::most_urgent` (`needs.rs`): Returns the name of the most urgent need (highest `urgency_score`).
- `NeedSystem::satisfy` (`needs.rs`): Satisfies a named need by `amount`.
- `NeedSystem::need_names` (`needs.rs`): Returns a list of all need names in this system.
- `NeedSystem::value_of` (`needs.rs`): Returns the satisfaction value for a named need, or `1.0` if not found.
- `NeedSystem::best_advertisement` (`needs.rs`): Selects the best available advertisement from a slice, considering the urgency of all needs in this system.
- `Activation::from_str` (`neural_net.rs`): Parses a string into an `Activation`.
- `Activation::as_str` (`neural_net.rs`): Returns the canonical lowercase string name.
- `Activation::apply` (`neural_net.rs`): Applies the activation in-place to a mutable slice.
- `NeuralLayer::new` (`neural_net.rs`): Creates a new zeroed layer.
- `NeuralLayer::param_count` (`neural_net.rs`): Returns the total number of weight parameters (weights + biases).
- `NeuralLayer::forward` (`neural_net.rs`): Performs the forward pass: `output = activation(W * input + b)`.
- `NeuralNet::new` (`neural_net.rs`): Creates a new empty neural network.
- `NeuralNet::add_layer` (`neural_net.rs`): Appends a fully-connected layer to the network.
- `NeuralNet::param_count` (`neural_net.rs`): Returns the total number of trainable parameters across all layers.
- `NeuralNet::forward` (`neural_net.rs`): Runs the forward pass and returns output activations.
- `NeuralNet::set_weights` (`neural_net.rs`): Copies all weights from a flat slice into the network's layers.
- `NeuralNet::get_weights` (`neural_net.rs`): Flattens all layer weights and biases into a single `Vec<f32>`.
- `NeuralNet::layer_count` (`neural_net.rs`): Returns the number of layers.
- `Neuroevolution::new` (`neuroevolution.rs`): Creates a new neuroevolution trainer for the given network topology.
- `Neuroevolution::pop_size` (`neuroevolution.rs`): Returns the population size.
- `Neuroevolution::chromosome_to_net` (`neuroevolution.rs`): Builds a `NeuralNet` from the weight chromosome at index `i`.
- `Neuroevolution::set_fitness` (`neuroevolution.rs`): Sets the fitness for chromosome at index `i`.
- `Neuroevolution::evolve` (`neuroevolution.rs`): Advances one generation using the GA.
- `Neuroevolution::best_network` (`neuroevolution.rs`): Returns a `NeuralNet` loaded with the weights of the best chromosome.
- `Neuroevolution::best_fitness` (`neuroevolution.rs`): Returns the fitness of the best chromosome.
- `Neuroevolution::population` (`neuroevolution.rs`): Returns a reference to the raw population chromosomes.
- `ORCAAgent::new` (`orca.rs`): Creates an agent at the given position with zero velocity.
- `ORCASolver::new` (`orca.rs`): Creates a new solver with a given time horizon in seconds.
- `ORCASolver::add_agent` (`orca.rs`): Adds an agent to the solver and returns its index.
- `ORCASolver::remove_agent` (`orca.rs`): Removes the agent at `index` by swapping with the last agent.
- `ORCASolver::agent_count` (`orca.rs`): Returns the number of agents in the solver.
- `ORCASolver::compute` (`orca.rs`): Runs one ORCA frame: for each agent, computes velocity-space half-planes from all neighbours, then finds the velocity closest to `preferred_velocity` that satisfies every half-plane.
- `StimulusType::from_str` (`perception.rs`): Parses a string into a `StimulusType`.
- `StimulusType::as_str` (`perception.rs`): Returns the canonical string name of this stimulus type.
- `StimulusWorld::new` (`perception.rs`): Creates a new empty stimulus world.
- `StimulusWorld::add` (`perception.rs`): Registers a new stimulus in the world.
- `StimulusWorld::add_visual` (`perception.rs`): Convenience method: emits a visual stimulus.
- `StimulusWorld::add_auditory` (`perception.rs`): Convenience method: emits an auditory stimulus.
- `StimulusWorld::add_custom` (`perception.rs`): Convenience method: emits a custom-type stimulus.
- `StimulusWorld::remove` (`perception.rs`): Removes a stimulus by ID.
- `StimulusWorld::update` (`perception.rs`): Decays all stimuli by `dt` and removes those whose intensity has dropped to zero or below.
- `StimulusWorld::stimuli` (`perception.rs`): Returns a reference to all currently active stimuli.
- `StimulusWorld::count` (`perception.rs`): Returns the number of active stimuli.
- `StimulusWorld::clear` (`perception.rs`): Removes all stimuli immediately.
- `Sensor::new` (`perception.rs`): Creates a sensor with default parameters suitable for a typical guard agent.
- `Sensor::can_see` (`perception.rs`): Returns `true` if a given world-space target position is inside this sensor's sight cone (range + angle check).
- `Sensor::can_hear` (`perception.rs`): Returns `true` if an auditory stimulus can be heard from `sensor_pos`.
- `Sensor::detect` (`perception.rs`): Queries the `StimulusWorld` for all stimuli detectable from `sensor_pos` with `facing` heading.
- `Sensor::update_awareness` (`perception.rs`): Updates the awareness level based on the number of stimuli detected this frame.
- `Sensor::is_alert` (`perception.rs`): Returns `true` when awareness has reached or exceeded `alert_threshold`.
- `Sensor::add_custom_range` (`perception.rs`): Registers a detection range for a custom sense channel.
- `QLearner::new` (`qlearner.rs`): Creates a new Q-learner with zero-initialized Q-values.
- `QLearner::choose_action` (`qlearner.rs`): Selects an action using the epsilon-greedy policy.
- `QLearner::best_action` (`qlearner.rs`): Returns the greedy-best action (highest Q-value) for the given state.
- `QLearner::learn` (`qlearner.rs`): Performs one Bellman Q-learning update.
- `QLearner::end_episode` (`qlearner.rs`): Ends the current episode: applies epsilon decay and increments episode count.
- `QLearner::get_q` (`qlearner.rs`): Returns the Q-value for a (state, action) pair, or 0.0 if out of range.
- `QLearner::set_q` (`qlearner.rs`): Overwrites the Q-value for a (state, action) pair.
- `QLearner::serialize` (`qlearner.rs`): Serializes the Q-table to a JSON string (2D array of state rows).
- `QLearner::deserialize` (`qlearner.rs`): Restores the Q-table from a JSON string produced by [`serialize`](Self::serialize).
- `StateMachine::generate_render_commands` (`render.rs`): Generate debug render commands representing the finite state machine.
- `StateMachine::draw_to_image` (`render.rs`): Render the FSM to a CPU image.
- `BehaviorTree::generate_render_commands` (`render.rs`): Generate debug render commands that outline the behavior tree structure.
- `BehaviorTree::draw_to_image` (`render.rs`): Render the behavior tree structure to a CPU image.
- `FormationType::parse_str` (`squad.rs`): Parses a Lua string into a `FormationType`.
- `FormationType::as_str` (`squad.rs`): Returns the canonical lowercase Lua string for this formation type.
- `Squad::new` (`squad.rs`): Creates a new squad with no members, no leader, no formation, and a default spacing of 30 world units.
- `Squad::get_formation_position` (`squad.rs`): Computes the ideal world-space position for the member at `member_idx` given the leader's current position.
- `CombineMode::parse_str` (`steering.rs`): Parses from Lua string.
- `CombineMode::as_str` (`steering.rs`): Returns the Lua string representation.
- `SteeringBehaviorType::base` (`steering.rs`): Returns a reference to the common steering data.
- `SteeringBehaviorType::base_mut` (`steering.rs`): Returns a mutable reference to the common steering data.
- `SteeringBehaviorType::kind` (`steering.rs`): Returns the behavior kind as a Lua-friendly string.
- `SteeringBehaviorType::calculate` (`steering.rs`): Computes the 2D steering force for this behavior given the agent's current kinematic state.
- `SteeringManager::new` (`steering.rs`): Creates a new empty SteeringManager with weighted combination.
- `SteeringManager::calculate` (`steering.rs`): Computes the combined steering force for the given agent state.
- `SteeringManager::add_seek` (`steering.rs`): Adds a Seek behavior targeting `(tx, ty)` with the given weight.
- `SteeringManager::add_flee` (`steering.rs`): Adds a Flee behavior away from `(tx, ty)` within `panic_dist`.
- `SteeringManager::add_arrive` (`steering.rs`): Adds an Arrive behavior targeting `(tx, ty)` with deceleration inside `slowing_radius`.
- `SteeringManager::add_wander` (`steering.rs`): Adds a Wander behavior with the given circle parameters.
- `SteeringManager::add_pursue` (`steering.rs`): Adds a Pursue behavior targeting a named agent.
- `SteeringManager::add_evade` (`steering.rs`): Adds an Evade behavior fleeing from a named threat agent.
- `SteeringManager::add_flock` (`steering.rs`): Adds a Flock behavior for group movement among named neighbors.
- `SteeringManager::set_combine_mode_str` (`steering.rs`): Sets the combination mode from a Lua string (`"weighted"` or `"priority"`).
- `SteeringManager::last_force` (`steering.rs`): Returns the force vector computed during the last `calculate()` call.
- `StrategicGoal::new` (`strategy.rs`): Creates a new goal with full priority and no preconditions.
- `StrategicGoal::require_tag` (`strategy.rs`): Adds a precondition tag requirement.
- `StrategicGoal::is_eligible` (`strategy.rs`): Returns `true` if all precondition tags are present in `active_tags`.
- `StrategyAI::new` (`strategy.rs`): Creates a new strategy AI with the given evaluation interval in seconds.
- `StrategyAI::add_goal` (`strategy.rs`): Adds a goal to the evaluator.
- `StrategyAI::add_goal_named` (`strategy.rs`): Convenience: adds a named goal with default settings.
- `StrategyAI::set_tags` (`strategy.rs`): Sets the active world-state tags used to filter goal eligibility.
- `StrategyAI::add_tag` (`strategy.rs`): Adds a single active tag.
- `StrategyAI::remove_tag` (`strategy.rs`): Removes a tag.
- `StrategyAI::active_goal` (`strategy.rs`): Returns the name of the currently active goal, or `None` if no evaluation has run yet.
- `StrategyAI::update` (`strategy.rs`): Advances the timer by `dt` and evaluates goals when the interval expires.
- `StrategyAI::force_evaluate` (`strategy.rs`): Forces an immediate re-evaluation outside the normal interval.
- `StrategyAI::goal_count` (`strategy.rs`): Returns the number of registered goals.
- `StrategyAI::time_until_next` (`strategy.rs`): Returns seconds remaining until the next scheduled evaluation.
- `TraitModifier::new` (`traits.rs`): Creates a new modifier.
- `TraitModifier::is_expired` (`traits.rs`): Returns `true` if a timed modifier has expired (remaining ≤ 0).
- `TraitModifier::tick` (`traits.rs`): Advances the modifier timer.
- `TraitProfile::new` (`traits.rs`): Creates a new empty trait profile with no base traits and no modifiers.
- `TraitProfile::from_archetype` (`traits.rs`): Creates a trait profile from a named archetype with optional variance jitter.
- `TraitProfile::set` (`traits.rs`): Sets the base value for a trait, clamped to `[0.0, 1.0]`.
- `TraitProfile::get` (`traits.rs`): Returns the effective trait value (base + all active modifier deltas), clamped to `[0.0, 1.0]`.
- `TraitProfile::get_base` (`traits.rs`): Returns the raw base value for a trait without applying modifiers.
- `TraitProfile::add_modifier` (`traits.rs`): Adds an additive modifier to a trait with optional duration.
- `TraitProfile::remove_modifiers_by_source` (`traits.rs`): Removes all modifiers whose `source` field matches the given string.
- `TraitProfile::update` (`traits.rs`): Advances modifier timers by `dt` seconds and removes expired timed modifiers.
- `TraitProfile::trait_names` (`traits.rs`): Returns a `Vec` of all base trait names defined in this profile.
- `TraitProfile::trait_count` (`traits.rs`): Returns the number of base traits defined in this profile.
- `TraitProfile::has` (`traits.rs`): Returns `true` if a base value for `name` has been set.
- `TraitProfile::lerp_toward` (`traits.rs`): Linearly interpolates all base trait values toward those of `other` by factor `t` (clamped to `[0.0, 1.0]`).
- `TraitProfile::archetype` (`traits.rs`): Returns the archetype name this profile was created from, if any.
- `TraitArchetypes::new` (`traits.rs`): Creates an empty archetype registry.
- `TraitArchetypes::register` (`traits.rs`): Registers a named archetype with its trait values.
- `TraitArchetypes::get` (`traits.rs`): Returns the trait map for a named archetype, or `None` if not found.
- `TraitArchetypes::names` (`traits.rs`): Returns a list of all registered archetype names.
- `TraitArchetypes::count` (`traits.rs`): Returns the number of registered archetypes.
- `ResponseCurve::parse_str` (`utility_ai.rs`): Parses from Lua string.
- `ResponseCurve::apply` (`utility_ai.rs`): Transforms a raw input value through this response curve using the given parameters.
- `UtilityAI::new` (`utility_ai.rs`): Creates a new empty UtilityAI.
- `UtilityAI::add_action` (`utility_ai.rs`): Adds an action with the given scorer callback and momentum bonus.
- `UtilityAI::add_consideration` (`utility_ai.rs`): Adds a consideration to the named action.
- `UtilityAI::last_action_name` (`utility_ai.rs`): Returns the name of the last chosen action, or `None` if no evaluation has occurred.
- `UtilityAI::evaluate` (`utility_ai.rs`): Evaluates all actions using Lua scorer callbacks and returns the best action name.
- `AIWorld::new` (`world.rs`): Creates a new empty AIWorld.
- `AIWorld::add_agent` (`world.rs`): Adds a new agent with the given name.
- `AIWorld::remove_agent` (`world.rs`): Removes an agent by name.
- `AIWorld::get_agent_index` (`world.rs`): Returns the index of an agent by name.
- `AIWorld::agent_count` (`world.rs`): Returns the number of agents.
- `AIWorld::global_blackboard` (`world.rs`): Returns a reference to the global blackboard.
- `AIWorld::global_blackboard_mut` (`world.rs`): Returns a mutable reference to the global blackboard.
- `AIWorld::update` (`world.rs`): Advances all agents by `dt` seconds, integrating velocity into position.

## Lua API Reference

- Binding path(s): `src/lua_api/ai_api.rs`
- Namespace: `lurek.ai`

### Module Functions
- `lurek.ai.newWorld`: Creates a new AI world container.
- `lurek.ai.newBlackboard`: Creates a new standalone blackboard.
- `lurek.ai.newStateMachine`: Creates a new finite state machine.
- `lurek.ai.newBehaviorTree`: Creates a new behavior tree.
- `lurek.ai.newSelector`: Creates a BT selector node.
- `lurek.ai.newSequence`: Creates a BT sequence node.
- `lurek.ai.newParallel`: Creates a BT parallel node with optional policies.
- `lurek.ai.newInverter`: Creates a BT inverter decorator.
- `lurek.ai.newRepeater`: Creates a BT repeater decorator.
- `lurek.ai.newSucceeder`: Creates a BT succeeder decorator.
- `lurek.ai.newAction`: Creates a BT action leaf with a Lua callback.
- `lurek.ai.newCondition`: Creates a BT condition leaf with a Lua predicate.
- `lurek.ai.newSteeringManager`: Creates a new steering behavior manager.
- `lurek.ai.newQLearner`: Creates a tabular Q-learner.
- `lurek.ai.newUtilityAI`: Creates a new utility AI evaluator.
- `lurek.ai.newGOAPPlanner`: Creates a new GOAP planning solver.
- `lurek.ai.newInfluenceMap`: Creates a multi-layer influence map grid.
- `lurek.ai.newSquad`: Creates a named squad for formation positioning.
- `lurek.ai.newCommandQueue`: Creates an RTS-style command queue.
- `lurek.ai.newTraitProfile`: Creates a new personality trait profile.
- `lurek.ai.newStimulusWorld`: Creates a new stimulus perception world.
- `lurek.ai.newContextSteering`: Creates a new context steering controller.
- `lurek.ai.newNeedSystem`: Creates a new motivational need system.
- `lurek.ai.newAIDirector`: Creates a new AI pacing director with default config.
- `lurek.ai.newHTNDomain`: Creates a new Hierarchical Task Network domain.
- `lurek.ai.newMCTSEngine`: Creates a new Monte Carlo Tree Search engine.
- `lurek.ai.newEmotionModel`: Creates a new affective emotion model.
- `lurek.ai.newORCASolver`: Creates a new ORCA crowd avoidance solver.
- `lurek.ai.newNeuralNet`: Creates a new feedforward neural network (inference only).
- `lurek.ai.newGeneticAlgorithm`: Creates a new genetic algorithm.
- `lurek.ai.newBandit`: Creates a new multi-armed bandit.
- `lurek.ai.newNeuroevolution`: Creates a neuroevolution trainer (GA for neural network weights).
- `lurek.ai.newStrategyAI`: Creates a new throttled strategy AI.
- `lurek.ai.newAILod`: Creates a new AI LOD controller with default 3-tier config.

### `AIDirector` Methods
- `AIDirector:pushEvent`: Pushes a gameplay event with the given intensity to the director for awareness analysis.
- `AIDirector:update`: Advances the simulation by one time step.
- `AIDirector:tension`: Returns or performs tension.
- `AIDirector:phase`: Returns or performs phase.
- `AIDirector:spawnRateFactor`: Returns or performs spawn rate factor.
- `AIDirector:lootFactor`: Returns or performs loot factor.
- `AIDirector:ambientIntensity`: Returns or performs ambient intensity.
- `AIDirector:setTension`: Sets the tension.
- `AIDirector:reset`: Resets or clears the state.

### `AILod` Methods
- `AILod:tierFor`: Returns or performs tier for.
- `AILod:shouldUpdate`: Returns or performs should update.
- `AILod:tierCount`: Returns or performs tier count.
- `AILod:tierName`: Returns or performs tier name.

### `AIWorld` Methods
- `AIWorld:addAgent`: Registers a new named agent and returns its handle.
- `AIWorld:getAgent`: Returns the agent handle for the given name, or nil.
- `AIWorld:removeAgent`: Removes an agent by its userdata handle.
- `AIWorld:getAgentCount`: Returns the number of registered agents.
- `AIWorld:getGlobalBlackboard`: Returns a snapshot of the world-level blackboard.
- `AIWorld:update`: Advances all agents by dt seconds.
- `AIWorld:type`: Returns the type name of this object.
- `AIWorld:typeOf`: Returns true if this object is of the given type.

### `Agent` Methods
- `Agent:getName`: Returns the agent's registered name.
- `Agent:setPosition`: Sets the agent's world-space position.
- `Agent:getPosition`: Returns the agent's current position.
- `Agent:setVelocity`: Sets the agent's velocity vector.
- `Agent:getVelocity`: Returns the agent's current velocity.
- `Agent:setMaxSpeed`: Sets the maximum speed cap.
- `Agent:getMaxSpeed`: Returns the maximum speed cap.
- `Agent:setMaxForce`: Sets the maximum steering force cap.
- `Agent:getMaxForce`: Returns the maximum steering force cap.
- `Agent:setPriority`: Sets the scheduling priority (higher = earlier).
- `Agent:getPriority`: Returns the agent's scheduling priority.
- `Agent:setDecisionModel`: Sets the active decision model.
- `Agent:getDecisionModel`: Returns the name of the current decision model.
- `Agent:addTag`: Adds a tag to this agent.
- `Agent:removeTag`: Removes a tag from this agent.
- `Agent:hasTag`: Returns true if the agent has the given tag.
- `Agent:getBlackboard`: Returns the agent's local blackboard.
- `Agent:type`: Returns the type name of this object.
- `Agent:typeOf`: Returns true if this object is of the given type.

### `BTNode` Methods
- `BTNode:addChild`: Adds a child node (Selector, Sequence, or Parallel only).
- `BTNode:getChildCount`: Returns the number of direct children.
- `BTNode:reset`: Resets all running-child memos and repeater counters.
- `BTNode:setChild`: Sets the single child of a decorator node.
- `BTNode:setCount`: Sets the repeat count for a Repeater node.
- `BTNode:getCount`: Returns the repeat count, or 0 if not a Repeater.
- `BTNode:setSuccessPolicy`: Sets the success policy for a Parallel node.
- `BTNode:setFailurePolicy`: Sets the failure policy for a Parallel node.
- `BTNode:getNodeType`: Returns the node type as a string.
- `BTNode:type`: Returns the type name of this object.
- `BTNode:typeOf`: Returns true if this object is of the given type.

### `Bandit` Methods
- `Bandit:select`: Returns or performs select.
- `Bandit:update`: Advances the simulation by one time step.
- `Bandit:bestArm`: Returns or performs best arm.
- `Bandit:reset`: Resets or clears the state.
- `Bandit:armCount`: Returns or performs arm count.
- `Bandit:totalPulls`: Returns or performs total pulls.

### `BehaviorTree` Methods
- `BehaviorTree:setRoot`: Sets the root node of this behavior tree.
- `BehaviorTree:getLastStatus`: Returns the status from the last tick.
- `BehaviorTree:type`: Returns the type name of this object.
- `BehaviorTree:typeOf`: Returns true if this object is of the given type.

### `Blackboard` Methods
- `Blackboard:setNumber`: Stores a number under the given key.
- `Blackboard:setBool`: Stores a boolean under the given key.
- `Blackboard:setString`: Stores a string under the given key.
- `Blackboard:has`: Returns true if a value exists under the key.
- `Blackboard:remove`: Removes the entry at key.
- `Blackboard:clear`: Removes all local entries.
- `Blackboard:getKeys`: Returns all local keys as a table.
- `Blackboard:getSize`: Returns the number of local entries.
- `Blackboard:type`: Returns the type name of this object.
- `Blackboard:typeOf`: Returns true if this object is of the given type.

### `CommandQueue` Methods
- `CommandQueue:cancelCurrent`: Cancels the front command if it is interruptible.
- `CommandQueue:clear`: Discards all queued commands.
- `CommandQueue:getCount`: Returns the number of queued commands.
- `CommandQueue:isEmpty`: Returns true if there are no queued commands.
- `CommandQueue:getCurrentType`: Returns the kind of the front command, or nil.
- `CommandQueue:getCurrentTarget`: Returns the target coordinates of the front command.
- `CommandQueue:type`: Returns the type name of this object.
- `CommandQueue:typeOf`: Returns true if this object is of the given type.

### `ContextSteering` Methods
- `ContextSteering:addSeekTarget`: Adds a seek target.
- `ContextSteering:addWander`: Adds a wander behavior with jitter and weight to the context steering evaluator.
- `ContextSteering:addAvoidPoint`: Adds a avoid point.
- `ContextSteering:addAvoidBounds`: Adds a avoid bounds.
- `ContextSteering:clearBehaviors`: Resets or clears the behaviors.
- `ContextSteering:evaluate`: Evaluates and returns the computed result.
- `ContextSteering:chosenMagnitude`: Returns or performs chosen magnitude.
- `ContextSteering:slotCount`: Returns or performs slot count.

### `EmotionModel` Methods
- `EmotionModel:add`: Adds an emotion category with the given name and initial intensity to the model.
- `EmotionModel:trigger`: Returns or performs trigger.
- `EmotionModel:get`: Returns the value.
- `EmotionModel:dominant`: Returns or performs dominant.
- `EmotionModel:isActive`: Returns true if active.
- `EmotionModel:update`: Advances the simulation by one time step.
- `EmotionModel:reset`: Resets or clears the state.

### `GOAPPlanner` Methods
- `GOAPPlanner:getActionCount`: Returns the number of registered actions.
- `GOAPPlanner:getGoalCount`: Returns the number of registered goals.
- `GOAPPlanner:type`: Returns the type name of this object.
- `GOAPPlanner:typeOf`: Returns true if this object is of the given type.

### `GeneticAlgorithm` Methods
- `GeneticAlgorithm:evolve`: Runs one generation of the evolutionary algorithm.
- `GeneticAlgorithm:generation`: Returns or performs generation.
- `GeneticAlgorithm:popSize`: Returns or performs pop size.
- `GeneticAlgorithm:setFitness`: Sets the fitness.
- `GeneticAlgorithm:getGenes`: Returns the genes.
- `GeneticAlgorithm:bestGenes`: Returns or performs best genes.

### `HTNDomain` Methods
- `HTNDomain:addPrimitive`: Adds a primitive.
- `HTNDomain:addCompound`: Adds a compound.
- `HTNDomain:plan`: Runs planning and returns the resulting action sequence.
- `HTNDomain:taskCount`: Returns or performs task count.

### `InfluenceMap` Methods
- `InfluenceMap:addLayer`: Adds a named influence layer.
- `InfluenceMap:hasLayer`: Returns true if the named layer exists.
- `InfluenceMap:decay`: Multiplies all influences by a decay factor.
- `InfluenceMap:clearLayer`: Clears all influence in a layer.
- `InfluenceMap:clearAll`: Clears all layers.
- `InfluenceMap:getMaxPosition`: Returns the world-space position of the maximum value.
- `InfluenceMap:getMinPosition`: Returns the world-space position of the minimum value.
- `InfluenceMap:getWidth`: Returns the grid width.
- `InfluenceMap:getHeight`: Returns the grid height.
- `InfluenceMap:getCellSize`: Returns the cell size in world units.
- `InfluenceMap:type`: Returns the type name of this object.
- `InfluenceMap:typeOf`: Returns true if this object is of the given type.

### `NeedSystem` Methods
- `NeedSystem:addNeed`: Registers a new need with the specified name, urgency, and decay rate in the system.
- `NeedSystem:update`: Advances the simulation by one time step.
- `NeedSystem:mostUrgent`: Returns or performs most urgent.
- `NeedSystem:satisfy`: Returns or performs satisfy.
- `NeedSystem:valueOf`: Returns or performs value of.

### `NeuralNet` Methods
- `NeuralNet:addLayer`: Adds a neural network layer with inputs, outputs, and an activation function.
- `NeuralNet:forward`: Returns or performs forward.
- `NeuralNet:setWeights`: Sets the weights.
- `NeuralNet:getWeights`: Returns the weights.
- `NeuralNet:paramCount`: Returns or performs param count.
- `NeuralNet:layerCount`: Returns or performs layer count.

### `Neuroevolution` Methods
- `Neuroevolution:evolve`: Runs one generation of the evolutionary algorithm.
- `Neuroevolution:setFitness`: Sets the fitness.
- `Neuroevolution:chromosomeToNet`: Returns or performs chromosome to net.
- `Neuroevolution:bestNetwork`: Returns or performs best network.
- `Neuroevolution:bestFitness`: Returns or performs best fitness.
- `Neuroevolution:popSize`: Returns or performs pop size.
- `Neuroevolution:generation`: Returns or performs generation.

### `ORCASolver` Methods
- `ORCASolver:addAgent`: Adds an ORCA agent at the given position with radius and max speed to the solver.
- `ORCASolver:setPreferredVelocity`: Sets the preferred velocity.
- `ORCASolver:setPosition`: Sets the position.
- `ORCASolver:compute`: Computes and returns the result.
- `ORCASolver:getSafeVelocity`: Returns the safe velocity.
- `ORCASolver:agentCount`: Returns or performs agent count.

### `QLearner` Methods
- `QLearner:chooseAction`: Selects an action using epsilon-greedy policy (1-based).
- `QLearner:bestAction`: Returns the greedy-best action for the state (1-based).
- `QLearner:getQValue`: Returns the Q-value for a state-action pair (1-based).
- `QLearner:endEpisode`: Ends the current episode, applying epsilon decay.
- `QLearner:getEpisodeCount`: Returns the number of completed episodes.
- `QLearner:getStateCount`: Returns the number of discrete states.
- `QLearner:getActionCount`: Returns the number of discrete actions.
- `QLearner:setLearningRate`: Sets the learning rate alpha.
- `QLearner:getLearningRate`: Returns the current learning rate.
- `QLearner:setDiscountFactor`: Sets the discount factor gamma.
- `QLearner:getDiscountFactor`: Returns the current discount factor.
- `QLearner:setExplorationRate`: Sets the exploration rate epsilon.
- `QLearner:getExplorationRate`: Returns the current exploration rate.
- `QLearner:setExplorationDecay`: Sets the epsilon decay multiplier.
- `QLearner:getExplorationDecay`: Returns the epsilon decay multiplier.
- `QLearner:serialize`: Serializes the Q-table to a JSON string.
- `QLearner:deserialize`: Restores the Q-table from a JSON string.
- `QLearner:type`: Returns the type name of this object.
- `QLearner:typeOf`: Returns true if this object is of the given type.

### `Squad` Methods
- `Squad:getName`: Returns the squad name.
- `Squad:addMember`: Adds an agent by name to this squad.
- `Squad:removeMember`: Removes an agent by name from this squad.
- `Squad:getMemberCount`: Returns the number of squad members.
- `Squad:getMembers`: Returns the member names as a table.
- `Squad:setLeader`: Sets the squad leader by name.
- `Squad:getLeader`: Returns the leader name, or nil.
- `Squad:getFormation`: Returns the current formation type name.
- `Squad:getFormationSpacing`: Returns the formation spacing in world units.
- `Squad:getBlackboard`: Returns the squad's shared blackboard.
- `Squad:type`: Returns the type name of this object.
- `Squad:typeOf`: Returns true if this object is of the given type.

### `StateMachine` Methods
- `StateMachine:addState`: Registers a named state with optional lifecycle callbacks.
- `StateMachine:setInitialState`: Sets the initial state.
- `StateMachine:getCurrentState`: Returns the current state name, or nil.
- `StateMachine:forceState`: Forces a transition to the named state.
- `StateMachine:getTimeInState`: Returns seconds spent in the current state.
- `StateMachine:type`: Returns the type name of this object.
- `StateMachine:typeOf`: Returns true if this object is of the given type.

### `SteeringManager` Methods
- `SteeringManager:getBehaviorCount`: Returns the number of active behaviors.
- `SteeringManager:setCombineMode`: Sets the force combination mode.
- `SteeringManager:getCombineMode`: Returns the current combination mode.
- `SteeringManager:getLastSteering`: Returns the last computed steering force.
- `SteeringManager:type`: Returns the type name of this object.
- `SteeringManager:typeOf`: Returns true if this object is of the given type.

### `StimulusWorld` Methods
- `StimulusWorld:addVisual`: Adds a visual stimulus at the specified world position with radius and intensity.
- `StimulusWorld:addAuditory`: Adds a auditory.
- `StimulusWorld:remove`: Removes the specified item.
- `StimulusWorld:update`: Advances the simulation by one time step.
- `StimulusWorld:count`: Returns or performs count.
- `StimulusWorld:clear`: Resets or clears the state.

### `StrategyAI` Methods
- `StrategyAI:addGoal`: Adds a strategic goal with priority score to the planner for future evaluation.
- `StrategyAI:addTag`: Adds a string tag to the strategy AI instance for goal filtering and categorization.
- `StrategyAI:removeTag`: Removes the specified tag.
- `StrategyAI:update`: Advances the simulation by one time step.
- `StrategyAI:forceEvaluate`: Returns or performs force evaluate.
- `StrategyAI:activeGoal`: Returns or performs active goal.
- `StrategyAI:timeUntilNext`: Returns or performs time until next.

### `TraitProfile` Methods
- `TraitProfile:set`: Sets the value.
- `TraitProfile:get`: Returns the value.
- `TraitProfile:getBase`: Returns the base.
- `TraitProfile:addModifier`: Adds a modifier.
- `TraitProfile:removeModifiers`: Removes the specified modifiers.
- `TraitProfile:update`: Advances the simulation by one time step.
- `TraitProfile:has`: Returns true if a item is present.
- `TraitProfile:traitCount`: Returns or performs trait count.
- `TraitProfile:archetype`: Returns or performs archetype.

### `UtilityAI` Methods
- `UtilityAI:evaluate`: Evaluates all actions and returns the best action name, or nil.
- `UtilityAI:getActionCount`: Returns the number of registered actions.
- `UtilityAI:getLastAction`: Returns the name of the last chosen action, or nil.
- `UtilityAI:type`: Returns the type name of this object.
- `UtilityAI:typeOf`: Returns true if this object is of the given type.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ai/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
