//! # AI Module — Game AI Toolkit (Tier 2)
//!
//! Provides a comprehensive suite of decoupled game AI subsystems for Lurek2D.
//! Each subsystem can be used independently or composed together through the
//! [`Agent`] / [`AIWorld`] framework.
//!
//! ## Architecture Overview
//!
//! The AI module is a **Tier 2 Engine Extension**. It may import `math`, `engine`,
//! and Tier 1 modules (primarily `pathfind` for grid and flow-field re-exports).
//! It must not import other Tier 2 modules or any Tier 3 modules.
//!
//! All AI computation is **pure CPU math** — no GPU, audio, or window access.
//! This means every subsystem can run headlessly in tests without a graphics context.
//!
//! ## Subsystems
//!
//! | Subsystem | Description |
//! |-----------|-------------|
//! | [`fsm`] | Finite state machine with priority-ordered guarded transitions |
//! | [`behavior_tree`] | Hierarchical behavior tree with composites, decorators, and leaf callbacks |
//! | [`steering`] | Reynolds-style steering behaviors (seek, flee, arrive, wander, pursue, evade, flock) |
//! | [`goap`] | Goal-Oriented Action Planning using A★ over boolean world state |
//! | [`utility_ai`] | Multi-axis utility scorer with response curves for action selection |
//! | [`qlearner`] | Tabular epsilon-greedy Q-learning for reinforcement learning |
//! | [`influence_map`] | Multi-layer spatial float grid for strategic area analysis |
//! | [`squad`] | Squad coordination with formation offset computation |
//! | [`command_queue`] | RTS-style ordered command queue with interrupt and cancel |
//! | [`blackboard`] | Hierarchical key-value store for inter-agent data sharing |
//!
//! ## Agent–World Model
//!
//! [`AIWorld`] owns all [`Agent`] instances. Each agent carries kinematic state
//! (position, velocity, max speed/force), a [`DecisionModel`] that selects which
//! subsystems are ticked, and a local [`Blackboard`] that chains to the world's
//! global blackboard for hierarchical lookup.
//!
//! The world ticks agents in descending priority order during `update(dt)`.
//! FSM transitions, BT ticks, and steering force calculations all happen during
//! this pass. The Lua API layer (`lurek.ai.*`) wraps these Rust types.
//!
//! ## Dependencies
//!
//! - `FlowField`, `Cell`, and `PathGrid` are re-exported directly from
//!   `crate::pathfind` so `lurek.ai.*` has a unified surface.
//! - All Lua callbacks are stored as `mlua::RegistryKey` references.
//! - No heap allocation happens per-frame in steady state; vectors are grown at
//!   agent/behavior creation time.

/// Autonomous agent with kinematic state (position, velocity) and pluggable
/// decision models (FSM, BT, steering, or combinations).
pub mod agent;
/// Hierarchical behavior tree with composite nodes (sequence, selector, parallel),
/// decorator nodes (inverter, repeater, succeeder), and leaf nodes (action, condition).
pub mod behavior_tree;
/// Typed key-value store with optional parent-chain lookup, used for sharing
/// named data between agents, squads, and the global AI world.
pub mod blackboard;
/// RTS-style ordered command queue supporting enqueue, interrupt (push-front),
/// replace, and cancel-if-interruptible operations for unit action scheduling.
pub mod command_queue;
/// Finite state machine with named states (enter/update/exit callbacks) and
/// priority-ordered guarded transitions evaluated each frame.
pub mod fsm;
/// Goal-Oriented Action Planning (GOAP) solver using A★ search over boolean
/// world state to find optimal action sequences toward goals.
pub mod goap;
/// Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning
/// with Bellman updates, epsilon decay, and JSON serialization.
pub mod qlearner;
/// Debug render commands and image export for AI subsystems.
pub mod render;
/// Squad coordination: named groups of agents with formation offset computation
/// (line, wedge, circle, column) and a shared squad-level blackboard.
pub mod squad;
/// Reynolds-style autonomous steering behaviors (seek, flee, arrive, wander,
/// pursue, evade, flock) with weighted or priority-based force combination.
pub mod steering;
/// Multi-axis utility scorer: evaluates actions through response-curve
/// considerations and selects the highest-scoring option with momentum inertia.
pub mod utility_ai;
/// Spatial AI container that owns all agents, provides O(1) name-based lookup,
/// holds the global blackboard, and ticks agents in priority order each frame.
pub mod world;

// ── New subsystems ────────────────────────────────────────────────────────
/// Multi-armed bandit: epsilon-greedy, UCB1, and Thompson sampling for online
/// exploration/exploitation decisions.
pub mod bandit;
/// Context steering: radial interest/danger ring evaluation producing smooth,
/// obstacle-aware movement directions without force oscillation.
pub mod context_steering;
/// AI Director: tension-driven dynamic pacing controller with phase state
/// machine (BuildUp/Peak/Sustain/Relief) and spawn/loot factor outputs.
pub mod director;
/// Dialogue AI: topic/branch selector driven by FSM state, BT status,
/// and utility-action scores.
pub mod dialogue;
/// Emotion model: named affective dimensions (anger, fear, joy) that rise on
/// triggers and decay toward resting levels over time.
pub mod emotion;
/// Genetic algorithm: tournament selection, uniform crossover, Gaussian
/// mutation for offline optimisation of neural network weights or parameters.
pub mod genetic;
/// Hierarchical Task Network (HTN) planner: compound task decomposition via
/// ordered methods into primitive action sequences.
pub mod htn;
/// AI Level-of-Detail: distance-based tier assignment and frame skip gating
/// for budget-aware AI update throttling.
pub mod lod;
/// Monte Carlo Tree Search (MCTS): UCT-based game-tree search with
/// configurable closures for actions, apply, and evaluation.
pub mod mcts;
/// Sims-style needs/drives: named satisfaction values that decay over time,
/// urgency scoring, and need advertisement for satisfier selection.
pub mod needs;
/// Feedforward neural network for AI inference (forward pass only; train
/// offline using `genetic` or `neuroevolution`).
pub mod neural_net;
/// Neuroevolution: genetic algorithm wrapper specialised for evolving neural
/// network weight vectors.
pub mod neuroevolution;
/// ORCA: Optimal Reciprocal Collision Avoidance for smooth crowd navigation
/// using per-agent velocity-space half-plane linear programming.
pub mod orca;
/// Perception and sensing: sight cones, hearing radii, stimuli events, and
/// per-agent awareness levels that rise/decay based on detected stimuli.
pub mod perception;
/// Strategic AI: throttled high-level goal evaluator that re-runs every N
/// seconds via a scorer closure, with precondition tag filtering.
pub mod strategy;
/// Named float personality trait profiles with timed additive modifiers and
/// archetype-based instantiation.
pub mod traits;

pub use agent::{Agent, DecisionModel};
pub use behavior_tree::{BTNode, BTStatus, BehaviorTree, ParallelPolicy};
pub use blackboard::{Blackboard, BlackboardValue};
pub use command_queue::{Command, CommandQueue};
pub use fsm::{StateCallbacks, StateMachine, Transition};
pub use goap::{GOAPAction, GOAPGoal, GOAPPlanner};
pub use qlearner::QLearner;
pub use squad::{FormationType, Squad};
pub use steering::*;
pub use utility_ai::{Consideration, ResponseCurve, UAAction, UtilityAI};
pub use world::AIWorld;

pub use bandit::{Bandit, BanditArm, BanditStrategy};
pub use context_steering::{ContextBehavior, ContextBehaviorKind, ContextSteering};
pub use director::{AIDirector, DirectorConfig, DirectorPhase};
pub use dialogue::{DialogueAI, DialogueBranch, DialogueTopic};
pub use emotion::{Emotion, EmotionModel};
pub use genetic::{Chromosome, GeneticAlgorithm};
pub use htn::{HTNDomain, HTNMethod, HTNPlanner, HTNTask, WorldState};
pub use lod::{AILod, LodTier};
pub use mcts::{MCTSConfig, MCTSEngine};
pub use needs::{Need, NeedAdvertisement, NeedSystem};
pub use neural_net::{Activation, NeuralLayer, NeuralNet};
pub use neuroevolution::Neuroevolution;
pub use orca::{ORCAAgent, ORCASolver};
pub use perception::{DetectedStimulus, Sensor, Stimulus, StimulusType, StimulusWorld};
pub use strategy::{StrategicGoal, StrategyAI};
pub use traits::{TraitArchetypes, TraitModifier, TraitProfile};
