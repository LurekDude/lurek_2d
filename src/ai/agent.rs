//! Scope: agent entity model and decision-mode wiring used by AIWorld.
//! This file defines persistent per-agent state: identity, kinematics, tags, and optional subsystem handles.
//! It also defines decision-mode selection used by the update loop to choose FSM, BT, steering, or custom flow.
use std::collections::HashSet;

use crate::ai::blackboard::Blackboard;
use crate::ai::emotion::EmotionModel;
use crate::ai::needs::NeedSystem;
use crate::ai::perception::Sensor;
use crate::ai::traits::TraitProfile;

/// Controls which AI subsystems are ticked for an agent during `AIWorld::update`.
#[derive(Debug, Clone, PartialEq)]
pub enum DecisionModel {
    /// Ticks only the attached StateMachine. Transitions are evaluated each frame, applying guards and triggering enter/update/exit callbacks.
    Fsm,
    /// Ticks only the attached BehaviorTree. The tree is traversed from root each frame, resuming at any running leaf.
    Bt,
    /// Ticks only the attached SteeringManager. Behaviors are combined (weighted sum or priority) to produce a final velocity impulse.
    Steering,
    /// Ticks the StateMachine first (which may update steering targets via blackboard), then runs the SteeringManager to apply forces.
    FsmSteering,
    /// Ticks the BehaviorTree first (which may update steering targets via blackboard or direct writes), then runs the SteeringManager.
    BtSteering,
    /// A user-defined Lua callback drives this agent's decisions.
    Custom {
        /// Opaque ID referencing the Lua callback in the API-layer registry.
        callback_id: u32,
    },
}

impl DecisionModel {
    /// Parses a Lua-side string identifier into the corresponding `DecisionModel`.
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

    /// Returns the canonical Lua string identifier for this decision model.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Fsm => "fsm",
            Self::Bt => "bt",
            Self::Steering => "steering",
            Self::FsmSteering => "fsm+steering",
            Self::BtSteering => "bt+steering",
            Self::Custom { .. } => "custom",
        }
    }
}

/// An autonomous AI agent with kinematic state and pluggable decision subsystems.
pub struct Agent {
    /// Unique name within the owning AIWorld. Used for lookup and Lua API references.
    pub name: String,
    /// Update priority - agents with higher values are ticked first.
    pub priority: i32,
    /// World-space position as (x, y). Updated by steering forces each frame.
    pub position: (f32, f32),
    /// Current velocity vector (vx, vy). Clamped to `max_speed` magnitude.
    pub velocity: (f32, f32),
    /// Maximum speed magnitude in world units per second. Steering behaviors scale forces accordingly.
    pub max_speed: f32,
    /// Maximum steering force magnitude. The combined force from all active behaviors is clamped to this.
    pub max_force: f32,
    /// Determines which subsystems the world ticks for this agent (FSM, BT, steering, hybrid, or custom).
    pub decision_model: DecisionModel,
    /// Per-agent local blackboard for storing state. Parent-chained to the world's global blackboard.
    pub blackboard: Blackboard,
    /// String tags for group queries (e.g., "enemy", "patrol", "ranged"). Used for filtering subsystem updates.
    pub tags: HashSet<String>,
    /// Index into the AIWorld's FSM storage, if this agent has an attached state machine.
    pub fsm_index: Option<usize>,
    /// Index into the AIWorld's BehaviorTree storage, if this agent has an attached tree.
    pub bt_index: Option<usize>,
    /// Index into the AIWorld's SteeringManager storage, if this agent has steering behaviors.
    pub steering_index: Option<usize>,
    /// Optional personality trait profile (aggression, caution, loyalty, etc.). Influences decision-making.
    pub trait_profile: Option<TraitProfile>,
    /// Optional sensor for simulated perception (sight, hearing, custom senses).
    pub sensor: Option<Sensor>,
    /// Optional emotion model for affective state (anger, fear, joy, etc.). Impacts responses.
    pub emotion_model: Option<EmotionModel>,
    /// Optional need system (hunger, safety, rest, etc.). Feeds goal prioritization.
    pub need_system: Option<NeedSystem>,
    /// LOD tier index assigned by [`crate::ai::lod::AILod`]. Tier 0 = full detail; higher tiers skip subsystems.
    pub lod_tier: usize,
}

impl Agent {
    /// Creates a new agent with sensible default kinematic state.
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
            trait_profile: None,
            sensor: None,
            emotion_model: None,
            need_system: None,
            lod_tier: 0,
        }
    }
}
