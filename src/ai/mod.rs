
//! - Public AI module surface grouping planning, decision, control, memory, and movement subsystems.
//! - Module-level export map for agent state, planners, blackboard, and command flow.
//! - Learning helpers, perception, steering, and squad coordination re-exports.
//! - Compact entry surface re-exporting runtime types for higher engine layers.

/// Core agent type and decision model wiring.
pub mod agent;
/// Behavior tree nodes and execution runtime.
pub mod behavior_tree;
/// Shared key-value memory for AI systems.
pub mod blackboard;
/// Command queue for deferred AI actions.
pub mod command_queue;
/// Finite-state machine helpers.
pub mod fsm;
/// Goal-oriented action planning types.
pub mod goap;
/// Reinforcement learning with a tabular Q-learner.
pub mod qlearner;
/// AI-focused debug and visualization helpers.
pub mod render;
/// Squad membership and formation logic.
pub mod squad;
/// Steering behaviors and movement guidance.
pub mod steering;
/// Utility-AI scoring and action selection.
pub mod utility_ai;
/// Abstract world view consumed by AI logic.
pub mod world;

/// Multi-armed bandit strategies and statistics.
pub mod bandit;
/// Context-steering behavior composition.
pub mod context_steering;
/// Dialogue state, branches, and topic selection.
pub mod dialogue;
/// Encounter pacing and high-level director logic.
pub mod director;
/// Emotion state tracking and decay.
pub mod emotion;
/// Genetic algorithm primitives.
pub mod genetic;
/// Hierarchical task network planning.
pub mod htn;
/// AI level-of-detail switching.
pub mod lod;
/// Monte Carlo tree search support.
pub mod mcts;
/// Need evaluation and advertisement system.
pub mod needs;
/// Feed-forward neural network helpers.
pub mod neural_net;
/// Neuroevolution orchestration.
pub mod neuroevolution;
/// ORCA-based local avoidance.
pub mod orca;
/// Perception stimuli, sensors, and world state.
pub mod perception;
/// Higher-level strategy selection.
pub mod strategy;
/// Personality traits and archetype presets.
pub mod traits;

/// Base agent type and decision-model enum.
pub use agent::{Agent, DecisionModel};
/// Behavior tree nodes, statuses, and policies.
pub use behavior_tree::{BTNode, BTStatus, BehaviorTree, ParallelPolicy};
/// Blackboard storage shared by AI systems.
pub use blackboard::{Blackboard, BlackboardValue};
/// Deferred command queue and command variants.
pub use command_queue::{Command, CommandQueue};
/// Finite-state machine building blocks.
pub use fsm::{StateCallbacks, StateMachine, Transition};
/// GOAP planner inputs and planner type.
pub use goap::{GOAPAction, GOAPGoal, GOAPPlanner};
/// Tabular reinforcement learner.
pub use qlearner::QLearner;
/// Squad container and formation mode.
pub use squad::{FormationType, Squad};
/// Steering behavior primitives and helpers.
pub use steering::*;
/// Utility-AI considerations, response curves, and actions.
pub use utility_ai::{Consideration, ResponseCurve, UAAction, UtilityAI};
/// AI-facing world abstraction.
pub use world::AIWorld;

/// Multi-armed bandit policies and arm stats.
pub use bandit::{Bandit, BanditArm, BanditStrategy};
/// Context-steering behaviors and runtime type.
pub use context_steering::{ContextBehavior, ContextBehaviorKind, ContextSteering};
/// Dialogue decision types.
pub use dialogue::{DialogueAI, DialogueBranch, DialogueTopic};
/// High-level encounter director types.
pub use director::{AIDirector, DirectorConfig, DirectorPhase};
/// Emotion model types.
pub use emotion::{Emotion, EmotionModel};
/// Genetic algorithm public types.
pub use genetic::{Chromosome, GeneticAlgorithm};
/// HTN planner domain and task types.
pub use htn::{HTNDomain, HTNMethod, HTNPlanner, HTNTask, WorldState};
/// AI level-of-detail types.
pub use lod::{AILod, LodTier};
/// Monte Carlo tree search configuration and engine.
pub use mcts::{MCTSConfig, MCTSEngine};
/// Need system state and advertisements.
pub use needs::{Need, NeedAdvertisement, NeedSystem};
/// Neural-network layer and activation types.
pub use neural_net::{Activation, NeuralLayer, NeuralNet};
/// Neuroevolution entry point.
pub use neuroevolution::Neuroevolution;
/// ORCA avoidance solver types.
pub use orca::{ORCAAgent, ORCASolver};
/// Perception events, sensors, and stimulus world.
pub use perception::{DetectedStimulus, Sensor, Stimulus, StimulusType, StimulusWorld};
/// Strategy layer goals and controller.
pub use strategy::{StrategicGoal, StrategyAI};
/// Trait profiles, modifiers, and archetypes.
pub use traits::{TraitArchetypes, TraitModifier, TraitProfile};
