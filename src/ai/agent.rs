//! Autonomous agent with kinematic state and attached decision subsystems.
//!
//! An [`Agent`] is the fundamental unit of AI behavior in Lurek2D. Each agent
//! carries its own position, velocity, kinematic constraints (max speed and force),
//! and a [`DecisionModel`] that determines which AI subsystems are ticked during
//! the world's `update(dt)` pass.
//!
//! Agents are always owned by an [`AIWorld`](crate::ai::world::AIWorld) and are
//! created via `AIWorld::add_agent()`. They are never instantiated standalone in
//! production — the world manages their lifecycle, priority ordering, and
//! blackboard parent-chain wiring.
//!
//! ## Decision Models
//!
//! The [`DecisionModel`] enum selects which combination of subsystems the world
//! ticks for this agent each frame:
//!
//! - `Fsm` — only the [`StateMachine`](crate::ai::fsm::StateMachine)
//! - `Bt` — only the [`BehaviorTree`](crate::ai::behavior_tree::BehaviorTree)
//! - `Steering` — only the [`SteeringManager`](crate::ai::steering::SteeringManager)
//! - `FsmSteering` — FSM first, then steering
//! - `BtSteering` — BT first, then steering
//!
//! ## Blackboard Hierarchy
//!
//! Each agent has a local [`Blackboard`]. When created via `AIWorld::add_agent()`,
//! the local blackboard's parent is set to the world's global blackboard, forming
//! a two-level lookup chain: local → global. Writes always go to the local store;
//! reads walk the chain until a match is found.

use std::collections::HashSet;

use crate::ai::blackboard::Blackboard;
use crate::ai::emotion::EmotionModel;
use crate::ai::needs::NeedSystem;
use crate::ai::perception::Sensor;
use crate::ai::traits::TraitProfile;

/// Controls which AI subsystems are ticked for an agent during `AIWorld::update`.
///
/// Each variant maps to a specific combination of decision-making subsystems.
/// The world checks this field to decide whether to tick the agent's FSM,
/// BehaviorTree, SteeringManager, or a combination thereof. The order matters:
/// when both FSM/BT and steering are active, the decision layer runs first
/// (potentially setting steering targets), then steering computes forces.
///
/// Lua scripts set this via `agent:setDecisionModel("fsm+steering")` etc.
/// Custom models are set via `agent:setCustomModel(fn)` in Lua.
///
/// # Variants
/// - `Fsm` — Fsm variant.
/// - `Bt` — Bt variant.
/// - `Steering` — Steering variant.
/// - `FsmSteering` — FsmSteering variant.
/// - `BtSteering` — BtSteering variant.
/// - `Custom` — Custom variant.
#[derive(Debug, Clone, PartialEq)]
pub enum DecisionModel {
    /// Ticks only the attached StateMachine. Transitions are evaluated each frame
    /// in descending priority order; the first passing guard triggers a state change.
    Fsm,
    /// Ticks only the attached BehaviorTree. The tree is traversed from root each
    /// frame, resuming from the last "running" node if applicable.
    Bt,
    /// Ticks only the attached SteeringManager. Behaviors are combined (weighted
    /// or priority) and the resulting force is applied to velocity.
    Steering,
    /// Ticks the StateMachine first (which may update steering targets via
    /// blackboard), then applies the SteeringManager forces.
    FsmSteering,
    /// Ticks the BehaviorTree first (which may update steering targets via
    /// blackboard), then applies the SteeringManager forces.
    BtSteering,
    /// A user-defined Lua callback drives this agent's decisions.
    /// The callback is stored by the Lua API layer; this field holds only the
    /// opaque ID into that layer's [`CallbackRegistry`].
    Custom {
        /// Opaque ID referencing the Lua callback in the API-layer registry.
        callback_id: u32,
    },
}

impl DecisionModel {
    /// Parses a Lua-side string identifier into the corresponding `DecisionModel`.
    ///
    /// Accepted strings: `"fsm"`, `"bt"`, `"steering"`, `"fsm+steering"`, `"bt+steering"`.
    /// Returns `None` for unrecognized input, allowing the Lua binding to emit
    /// a descriptive error rather than silently defaulting.
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

    /// Returns the canonical Lua string identifier for this decision model.
    ///
    /// Used when serializing agent state back to Lua or for debugging output.
    /// Round-trips with [`parse_str`](Self::parse_str) for all variants except
    /// `Custom`, which is set programmatically via `agent:setCustomModel(fn)`.
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
            Self::Custom { .. } => "custom",
        }
    }
}

/// An autonomous AI agent with kinematic state and pluggable decision subsystems.
///
/// Each agent lives inside an [`AIWorld`](crate::ai::world::AIWorld) and carries:
///
/// - **Kinematic state**: position, velocity, max_speed, max_force — used by
///   steering behaviors to compute and clamp movement forces.
/// - **Decision model**: selects which subsystems (FSM, BT, steering) are ticked.
/// - **Subsystem indices**: optional indices into the world's FSM/BT/steering
///   storage arrays, linking this agent to its attached decision-makers.
/// - **Blackboard**: local key-value store with a parent chain to the world's
///   global blackboard for hierarchical data lookup.
/// - **Tags**: string-based labels for group queries and filtering (e.g.,
///   `"enemy"`, `"flying"`, `"boss"`).
///
/// Agents are ticked in descending `priority` order by the world's update loop.
/// Higher priority agents run first, allowing leaders to update blackboard state
/// before followers read it.
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
/// - `trait_profile` — `Option<TraitProfile>`.
/// - `sensor` — `Option<Sensor>`.
/// - `emotion_model` — `Option<EmotionModel>`.
/// - `need_system` — `Option<NeedSystem>`.
/// - `lod_tier` — `usize`.
pub struct Agent {
    /// Unique name within the owning AIWorld. Used for lookup and Lua API references.
    pub name: String,
    /// Update priority — agents with higher values are ticked first.
    /// Useful for ensuring leaders update before squad members.
    pub priority: i32,
    /// World-space position as (x, y). Updated by steering forces each frame.
    pub position: (f32, f32),
    /// Current velocity vector (vx, vy). Clamped to `max_speed` magnitude.
    pub velocity: (f32, f32),
    /// Maximum speed magnitude in world units per second. Steering behaviors
    /// compute desired velocities relative to this cap.
    pub max_speed: f32,
    /// Maximum steering force magnitude. The combined force from all active
    /// steering behaviors is truncated to this value before being applied.
    pub max_force: f32,
    /// Determines which subsystems the world ticks for this agent.
    pub decision_model: DecisionModel,
    /// Per-agent local blackboard. Parent-chained to the world's global
    /// blackboard so reads cascade upward while writes stay local.
    pub blackboard: Blackboard,
    /// String tags for group queries (e.g., "enemy", "patrol", "ranged").
    /// Tags are case-sensitive and matched exactly.
    pub tags: HashSet<String>,
    /// Index into the AIWorld's FSM storage, if this agent has an attached
    /// StateMachine. `None` means no FSM is attached.
    pub fsm_index: Option<usize>,
    /// Index into the AIWorld's BehaviorTree storage, if this agent has an
    /// attached BehaviorTree. `None` means no BT is attached.
    pub bt_index: Option<usize>,
    /// Index into the AIWorld's SteeringManager storage, if this agent has
    /// an attached SteeringManager. `None` means no steering is attached.
    pub steering_index: Option<usize>,
    /// Optional personality trait profile (aggression, caution, loyalty, …).
    /// `None` means the agent uses no trait-based modulation.
    pub trait_profile: Option<TraitProfile>,
    /// Optional sensor for simulated perception (sight, hearing, custom senses).
    /// `None` means the agent uses omniscient/direct blackboard querying.
    pub sensor: Option<Sensor>,
    /// Optional emotion model for affective state (anger, fear, joy …).
    /// `None` means no emotion-driven animation or dialogue.
    pub emotion_model: Option<EmotionModel>,
    /// Optional need system (hunger, safety, rest, …).
    /// `None` means the agent has no motivational drives.
    pub need_system: Option<NeedSystem>,
    /// LOD tier index assigned by [`crate::ai::lod::AILod`]. Tier 0 = full
    /// every-frame AI; higher tiers mean less frequent updates.
    pub lod_tier: usize,
}

impl Agent {
    /// Creates a new agent with sensible default kinematic state.
    ///
    /// The agent starts at the origin `(0, 0)` with zero velocity.
    /// Default kinematic constraints: `max_speed = 100`, `max_force = 200`.
    /// Decision model defaults to `Fsm`. No FSM, BT, or steering is attached
    /// until explicitly set via the Lua API or Rust code.
    ///
    /// The blackboard starts empty with no parent. `AIWorld::add_agent()` will
    /// wire the parent to the world's global blackboard after creation.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decision_model_parse_round_trip() {
        for &s in &["fsm", "bt", "steering", "fsm+steering", "bt+steering"] {
            let dm = DecisionModel::parse_str(s).unwrap();
            assert_eq!(dm.as_str(), s);
        }
    }

    #[test]
    fn decision_model_unknown_returns_none() {
        assert!(DecisionModel::parse_str("bogus").is_none());
    }

    #[test]
    fn agent_new_defaults() {
        let a = Agent::new("test");
        assert_eq!(a.name, "test");
        assert_eq!(a.position, (0.0, 0.0));
        assert_eq!(a.velocity, (0.0, 0.0));
        assert_eq!(a.decision_model, DecisionModel::Fsm);
    }
}
