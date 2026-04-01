//! Autonomous agent with kinematic state and attached decision subsystems.

use std::collections::HashSet;

use crate::ai::blackboard::Blackboard;

/// Controls which subsystems are ticked during `AIWorld::update`.
///
/// # Variants
/// - `Fsm` — Fsm variant.
/// - `Bt` — Bt variant.
/// - `Steering` — Steering variant.
/// - `FsmSteering` — FsmSteering variant.
/// - `BtSteering` — BtSteering variant.
#[derive(Debug, Clone, PartialEq)]
pub enum DecisionModel {
    /// Ticks StateMachine only.
    Fsm,
    /// Ticks BehaviorTree only.
    Bt,
    /// Ticks SteeringManager only.
    Steering,
    /// Ticks StateMachine first, then SteeringManager.
    FsmSteering,
    /// Ticks BehaviorTree first, then SteeringManager.
    BtSteering,
}

impl DecisionModel {
    /// Parses a Lua string to a DecisionModel variant.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Self>`.
    pub fn parse_str(s: &str) -> Option<Self> {
        match s {
            "fsm" => Some(Self::Fsm),
            "bt" => Some(Self::Bt),
            "steering" => Some(Self::Steering),
            "fsm+steering" => Some(Self::FsmSteering),
            "bt+steering" => Some(Self::BtSteering),
            _ => None,
        }
    }

    /// Returns the Lua string representation.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Fsm => "fsm",
            Self::Bt => "bt",
            Self::Steering => "steering",
            Self::FsmSteering => "fsm+steering",
            Self::BtSteering => "bt+steering",
        }
    }
}

/// Autonomous agent with kinematic state and attached decision subsystems.
///
/// # Fields
/// - `name` — `String`.
/// - `priority` — `i32`.
/// - `position` — `(f32, f32)`.
/// - `velocity` — `(f32, f32)`.
/// - `max_speed` — `f32`.
/// - `max_force` — `f32`.
/// - `decision_model` — `DecisionModel`.
/// - `blackboard` — `Blackboard`.
/// - `tags` — `HashSet<String>`.
/// - `fsm_index` — `Option<usize>`.
/// - `bt_index` — `Option<usize>`.
/// - `steering_index` — `Option<usize>`.
///
/// Created via `AIWorld::add_agent()`. Carries position, velocity, kinematic
/// constraints, an optional FSM/BT/SteeringManager, and a local Blackboard.
pub struct Agent {
    /// Agent name (unique within its AIWorld).
    pub name: String,
    /// Priority for update ordering (higher = ticked earlier).
    pub priority: i32,
    /// World-space position.
    pub position: (f32, f32),
    /// Current velocity vector.
    pub velocity: (f32, f32),
    /// Maximum speed magnitude.
    pub max_speed: f32,
    /// Maximum steering force magnitude.
    pub max_force: f32,
    /// Which subsystems are ticked during update.
    pub decision_model: DecisionModel,
    /// Per-agent local blackboard.
    pub blackboard: Blackboard,
    /// Set of string tags for filtering and group queries.
    pub tags: HashSet<String>,
    /// Index of FSM in the AIWorld's fsm storage (if attached).
    pub fsm_index: Option<usize>,
    /// Index of BehaviorTree in the AIWorld's bt storage (if attached).
    pub bt_index: Option<usize>,
    /// Index of SteeringManager in the AIWorld's steering storage (if attached).
    pub steering_index: Option<usize>,
}

impl Agent {
    /// Creates a new agent with default kinematic state.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Position and velocity start at (0,0). MaxSpeed defaults to 100,
    /// maxForce to 200, decision model to `Fsm`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            priority: 0,
            position: (0.0, 0.0),
            velocity: (0.0, 0.0),
            max_speed: 100.0,
            max_force: 200.0,
            decision_model: DecisionModel::Fsm,
            blackboard: Blackboard::new(),
            tags: HashSet::new(),
            fsm_index: None,
            bt_index: None,
            steering_index: None,
        }
    }
}
