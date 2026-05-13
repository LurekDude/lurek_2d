//! AI module composition root and re-export surface for engine runtime.
/// Autonomous agent with kinematic state (position, velocity) and pluggable
pub mod agent;
/// Hierarchical behavior tree with composite nodes (sequence, selector, parallel),
pub mod behavior_tree;
/// Typed key-value store with optional parent-chain lookup, used for sharing
pub mod blackboard;
/// RTS-style ordered command queue supporting enqueue, interrupt (push-front),
pub mod command_queue;
/// Finite state machine with named states (enter/update/exit callbacks) and
pub mod fsm;
/// Goal-Oriented Action Planning (GOAP) solver using A* search over boolean
pub mod goap;
/// Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning
pub mod qlearner;
/// Debug render commands and image export for AI subsystems.
pub mod render;
/// Squad coordination: named groups of agents with formation offset computation
pub mod squad;
/// Reynolds-style autonomous steering behaviors (seek, flee, arrive, wander,
pub mod steering;
/// Multi-axis utility scorer: evaluates actions through response-curve
pub mod utility_ai;
/// Spatial AI container that owns all agents, provides O(1) name-based lookup,
pub mod world;

// -- New subsystems --
/// Multi-armed bandit: epsilon-greedy, UCB1, and Thompson sampling for online
pub mod bandit;
/// Context steering: radial interest/danger ring evaluation producing smooth,
pub mod context_steering;
/// AI Director: tension-driven dynamic pacing controller with phase state
pub mod director;
/// Dialogue AI: topic/branch selector driven by FSM state, BT status,
pub mod dialogue;
/// Emotion model: named affective dimensions (anger, fear, joy) that rise on
pub mod emotion;
/// Genetic algorithm: tournament selection, uniform crossover, Gaussian
pub mod genetic;
/// Hierarchical Task Network (HTN) planner: compound task decomposition via
pub mod htn;
/// AI Level-of-Detail: distance-based tier assignment and frame skip gating
pub mod lod;
/// Monte Carlo Tree Search (MCTS): UCT-based game-tree search with
pub mod mcts;
/// Sims-style needs/drives: named satisfaction values that decay over time,
pub mod needs;
/// Feedforward neural network for AI inference (forward pass only; train
pub mod neural_net;
/// Neuroevolution: genetic algorithm wrapper specialised for evolving neural
pub mod neuroevolution;
/// ORCA: Optimal Reciprocal Collision Avoidance for smooth crowd navigation
pub mod orca;
/// Perception and sensing: sight cones, hearing radii, stimuli events, and
pub mod perception;
/// Strategic AI: throttled high-level goal evaluator that re-runs every N
pub mod strategy;
/// Named float personality trait profiles with timed additive modifiers and
pub mod traits;

/// Agent model and decision mode exports.
pub use agent::{Agent, DecisionModel};
/// Behavior tree node/status/runtime exports.
pub use behavior_tree::{BTNode, BTStatus, BehaviorTree, ParallelPolicy};
/// Blackboard container and typed value exports.
pub use blackboard::{Blackboard, BlackboardValue};
/// Command queue command and queue exports.
pub use command_queue::{Command, CommandQueue};
/// FSM callbacks, machine, and transition exports.
pub use fsm::{StateCallbacks, StateMachine, Transition};
/// GOAP action, goal, and planner exports.
pub use goap::{GOAPAction, GOAPGoal, GOAPPlanner};
/// Tabular Q-learning runtime export.
pub use qlearner::QLearner;
/// Squad and formation shape exports.
pub use squad::{FormationType, Squad};
/// Steering behavior and helper exports.
pub use steering::*;
/// Utility AI action scoring exports.
pub use utility_ai::{Consideration, ResponseCurve, UAAction, UtilityAI};
/// World container export for AI runtime state.
pub use world::AIWorld;

/// Multi-armed bandit strategy exports.
pub use bandit::{Bandit, BanditArm, BanditStrategy};
/// Context steering behavior and solver exports.
pub use context_steering::{ContextBehavior, ContextBehaviorKind, ContextSteering};
/// Director pacing controller exports.
pub use director::{AIDirector, DirectorConfig, DirectorPhase};
/// Dialogue topic, branch, and selector exports.
pub use dialogue::{DialogueAI, DialogueBranch, DialogueTopic};
/// Emotion state and model exports.
pub use emotion::{Emotion, EmotionModel};
/// Genetic chromosome and algorithm exports.
pub use genetic::{Chromosome, GeneticAlgorithm};
/// HTN task decomposition and planner exports.
pub use htn::{HTNDomain, HTNMethod, HTNPlanner, HTNTask, WorldState};
/// AI level-of-detail tiering exports.
pub use lod::{AILod, LodTier};
/// Monte Carlo tree search exports.
pub use mcts::{MCTSConfig, MCTSEngine};
/// Needs model and advertisement exports.
pub use needs::{Need, NeedAdvertisement, NeedSystem};
/// Neural net layers and activation exports.
pub use neural_net::{Activation, NeuralLayer, NeuralNet};
/// Neuroevolution runtime export.
pub use neuroevolution::Neuroevolution;
/// ORCA crowd-avoidance exports.
pub use orca::{ORCAAgent, ORCASolver};
/// Perception sensors and stimuli exports.
pub use perception::{DetectedStimulus, Sensor, Stimulus, StimulusType, StimulusWorld};
/// Strategic planning exports.
pub use strategy::{StrategicGoal, StrategyAI};
/// Trait profile and modifier exports.
pub use traits::{TraitArchetypes, TraitModifier, TraitProfile};
