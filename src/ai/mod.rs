//! Game AI toolkit: FSM, Behavior Trees, Steering, Pathfinding, Q-Learning, and more.
//!
//! All subsystems are decoupled: agents can be driven by FSM, BT, SteeringManager, or any mix.
//! All computation is pure CPU math — no GPU, audio, or window access required.

/// Autonomous agent with pluggable decision models.
pub mod agent;
/// Behavior tree nodes (sequence, selector, parallel, decorators).
pub mod behavior_tree;
/// Shared key-value store for inter-agent communication.
pub mod blackboard;
/// Queue-based action scheduling with undo support.
pub mod command_queue;
/// Dijkstra-based flow field for crowd pathfinding.
pub mod flowfield;
/// Finite state machine with named states and transitions.
pub mod fsm;
/// Goal-oriented action planning (GOAP) solver.
pub mod goap;
/// Grid-based influence map for spatial reasoning.
pub mod influence_map;
/// Weighted grid pathfinding (A*, Dijkstra) with obstacle support.
pub mod pathgrid;
/// Tabular Q-learning agent for reinforcement learning.
pub mod qlearner;
/// Squad coordination: formation, morale, and group behaviour.
pub mod squad;
/// Steering behaviours (seek, flee, wander, flocking, etc.).
pub mod steering;
/// Utility-AI scorer with weighted action selection.
pub mod utility_ai;
/// Spatial AI world with team assignment and awareness radius.
pub mod world;

pub use agent::{Agent, DecisionModel};
pub use behavior_tree::{BTNode, BTStatus, BehaviorTree, ParallelPolicy};
pub use blackboard::{Blackboard, BlackboardValue};
pub use command_queue::{Command, CommandQueue};
pub use flowfield::FlowField;
pub use fsm::{StateCallbacks, StateMachine, Transition};
pub use goap::{GOAPAction, GOAPGoal, GOAPPlanner};
pub use influence_map::InfluenceMap;
pub use pathgrid::{Cell, PathGrid};
pub use qlearner::QLearner;
pub use squad::{FormationType, Squad};
pub use steering::*;
pub use utility_ai::{Consideration, ResponseCurve, UAAction, UtilityAI};
pub use world::AIWorld;
