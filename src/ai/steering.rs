//! Reynolds-style steering behaviors with weighted/priority combination.
//!
//! This module implements Craig Reynolds' autonomous agent steering behaviors,
//! adapted for 2D game AI. Each behavior produces a 2D force vector that is
//! applied to the agent's velocity by the [`SteeringManager`] (managed at the
//! [`AIWorld`](crate::ai::world::AIWorld) level).
//!
//! ## Available Behaviors
//!
//! - **Seek** — Produces a force toward a target position at maximum speed.
//! - **Flee** — Produces a force away from a threat, with a configurable panic
//!   distance beyond which the agent ignores the threat.
//! - **Arrive** — Like seek, but decelerates within a slowing radius to stop
//!   smoothly at the target instead of oscillating around it.
//! - **Wander** — Projects a circle ahead of the agent and picks a random point
//!   on its circumference, creating natural-looking meandering movement.
//! - **Pursue** — Predicts a moving target's future position and steers toward
//!   the intercept point rather than the current position.
//! - **Evade** — Inverse of pursue: predicts a threat's future position and
//!   steers away from the intercept point.
//! - **Flock** — Combines separation, alignment, and cohesion forces for group
//!   movement (Reynolds boids model).
//!
//! ## Combination Modes
//!
//! Multiple active behaviors are combined via [`CombineMode`]:
//! - **Weighted**: all forces are summed (each multiplied by its weight),
//!   then truncated to `max_force`.
//! - **Priority**: behaviors are evaluated in order; the first non-zero force
//!   is used and remaining behaviors are skipped.

/// 2D force vector (fx, fy). Consult the module-level documentation for the broader usage context and preconditions.
pub type Force = (f32, f32);

/// Determines how multiple active steering behaviors are combined into a
/// single resultant force applied to the agent.
///
/// In **Weighted** mode, all enabled behaviors contribute simultaneously —
/// their forces are summed (each scaled by its weight) and the total is
/// clamped to `max_force`. This works well when behaviors cooperate
/// (e.g., seek + obstacle avoidance).
///
/// In **Priority** mode, behaviors are evaluated in order. The first one
/// that returns a non-zero force "wins" and the rest are skipped. This is
/// useful when behaviors are mutually exclusive (e.g., flee overrides patrol).
///
/// # Variants
/// - `Weighted` — Weighted variant.
/// - `Priority` — Priority variant.
#[derive(Debug, Clone, PartialEq)]
pub enum CombineMode {
    /// Sum all forces × weight, truncate to maxForce.
    Weighted,
    /// Use first non-zero force, ignore rest.
    Priority,
}

impl CombineMode {
    /// Parses from Lua string. Returns an error if the source data is malformed or missing.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "priority" => Self::Priority,
            _ => Self::Weighted,
        }
    }

    /// Returns the Lua string representation. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Weighted => "weighted",
            Self::Priority => "priority",
        }
    }
}

/// Shared parameters common to all steering behavior instances.
///
/// Every [`SteeringBehaviorType`] variant carries a `SteeringBase` that controls
/// the behavior's weight and enabled state. The weight is a multiplier applied
/// to the raw force before combination (Weighted mode) or used as a tie-breaker
/// (Priority mode). Disabled behaviors are skipped entirely during force
/// calculation.
///
/// # Fields
/// - `weight` — `f32`.
/// - `enabled` — `bool`.
#[derive(Debug, Clone)]
pub struct SteeringBase {
    /// Weight multiplier for this behavior's force contribution.
    pub weight: f32,
    /// Whether this behavior is active.
    pub enabled: bool,
}

impl Default for SteeringBase {
    fn default() -> Self {
        Self {
            weight: 1.0,
            enabled: true,
        }
    }
}

/// All concrete steering behavior types supported by the AI system.
///
/// Each variant carries its own parameters (target position, radii, neighbor
/// lists, etc.) plus a shared [`SteeringBase`] for weight and enabled state.
/// The `calculate()` method produces a 2D force vector for any behavior given
/// the agent's current kinematic state.
///
/// Pursue, Evade, and Flock require access to other agents' positions, so their
/// forces are computed at the [`AIWorld`](crate::ai::world::AIWorld) level
/// rather than inside `calculate()` (which returns zero for those variants).
///
/// # Variants
/// - `Seek` — Seek variant.
/// - `Flee` — Flee variant.
/// - `Arrive` — Arrive variant.
/// - `Wander` — Wander variant.
/// - `Pursue` — Pursue variant.
/// - `Evade` — Evade variant.
/// - `Flock` — Flock variant.
#[derive(Debug, Clone)]
pub enum SteeringBehaviorType {
    /// Moves directly toward a target position.
    Seek {
        /// Target position.
        target: (f32, f32),
        /// Common steering data.
        base: SteeringBase,
    },
    /// Moves directly away from a target position within panic distance.
    Flee {
        /// Target position to flee from.
        target: (f32, f32),
        /// Distance beyond which the agent stops fleeing.
        panic_dist: f32,
        /// Common steering data.
        base: SteeringBase,
    },
    /// Moves toward a target, decelerating within the slowing radius.
    Arrive {
        /// Target position.
        target: (f32, f32),
        /// Distance at which deceleration begins.
        slowing_radius: f32,
        /// Common steering data.
        base: SteeringBase,
    },
    /// Random meandering via a projected wander circle.
    Wander {
        /// Radius of the wander circle.
        wander_radius: f32,
        /// Distance the wander circle is projected ahead.
        wander_distance: f32,
        /// Maximum random displacement per frame.
        wander_jitter: f32,
        /// Current wander angle in radians.
        wander_angle: f32,
        /// Common steering data.
        base: SteeringBase,
    },
    /// Intercepts a moving target by predicting its future position.
    Pursue {
        /// Name of the target agent to pursue.
        target_name: Option<String>,
        /// Common steering data.
        base: SteeringBase,
    },
    /// Flees from a predicted future position of a threat agent.
    Evade {
        /// Name of the threat agent to evade.
        threat_name: Option<String>,
        /// Common steering data.
        base: SteeringBase,
    },
    /// Combined separation + alignment + cohesion for group movement.
    Flock {
        /// Radius for neighbor detection.
        neighbor_radius: f32,
        /// Weight for separation component.
        sep_weight: f32,
        /// Weight for alignment component.
        align_weight: f32,
        /// Weight for cohesion component.
        coh_weight: f32,
        /// Names of neighbor agents.
        neighbor_names: Vec<String>,
        /// Common steering data.
        base: SteeringBase,
    },
}

impl SteeringBehaviorType {
    /// Returns a reference to the common steering data.
    ///
    /// # Returns
    /// `&SteeringBase`.
    pub fn base(&self) -> &SteeringBase {
        match self {
            Self::Seek { base, .. }
            | Self::Flee { base, .. }
            | Self::Arrive { base, .. }
            | Self::Wander { base, .. }
            | Self::Pursue { base, .. }
            | Self::Evade { base, .. }
            | Self::Flock { base, .. } => base,
        }
    }

    /// Returns a mutable reference to the common steering data.
    ///
    /// # Returns
    /// `&mut SteeringBase`.
    pub fn base_mut(&mut self) -> &mut SteeringBase {
        match self {
            Self::Seek { base, .. }
            | Self::Flee { base, .. }
            | Self::Arrive { base, .. }
            | Self::Wander { base, .. }
            | Self::Pursue { base, .. }
            | Self::Evade { base, .. }
            | Self::Flock { base, .. } => base,
        }
    }

    /// Returns the behavior kind as a Lua-friendly string.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn kind(&self) -> &'static str {
        match self {
            Self::Seek { .. } => "seek",
            Self::Flee { .. } => "flee",
            Self::Arrive { .. } => "arrive",
            Self::Wander { .. } => "wander",
            Self::Pursue { .. } => "pursue",
            Self::Evade { .. } => "evade",
            Self::Flock { .. } => "flock",
        }
    }

    /// Computes the 2D steering force for this behavior given the agent's
    /// current kinematic state. The force should be added to the agent's
    /// velocity (after weighting and truncation by the SteeringManager).
    ///
    /// For Pursue, Evade, and Flock, this returns `(0.0, 0.0)` because
    /// those behaviors need access to other agents' states, which is
    /// handled at the AIWorld level.
    ///
    /// # Parameters
    /// - `agent_pos` — `(f32, f32)`.
    /// - `agent_vel` — `(f32, f32)`.
    /// - `max_speed` — `f32`.
    /// - `_dt` — `f32`.
    ///
    /// # Returns
    /// `Force`.
    pub fn calculate(
        &self,
        agent_pos: (f32, f32),
        agent_vel: (f32, f32),
        max_speed: f32,
        _dt: f32,
    ) -> Force {
        if !self.base().enabled {
            return (0.0, 0.0);
        }
        match self {
            Self::Seek { target, .. } => {
                let dx = target.0 - agent_pos.0;
                let dy = target.1 - agent_pos.1;
                let dist = (dx * dx + dy * dy).sqrt();
                if dist < 0.001 {
                    return (0.0, 0.0);
                }
                let desired_x = (dx / dist) * max_speed;
                let desired_y = (dy / dist) * max_speed;
                (desired_x - agent_vel.0, desired_y - agent_vel.1)
            }
            Self::Flee {
                target, panic_dist, ..
            } => {
                let dx = agent_pos.0 - target.0;
                let dy = agent_pos.1 - target.1;
                let dist = (dx * dx + dy * dy).sqrt();
                if dist > *panic_dist && *panic_dist > 0.0 {
                    return (0.0, 0.0);
                }
                if dist < 0.001 {
                    return (0.0, 0.0);
                }
                let desired_x = (dx / dist) * max_speed;
                let desired_y = (dy / dist) * max_speed;
                (desired_x - agent_vel.0, desired_y - agent_vel.1)
            }
            Self::Arrive {
                target,
                slowing_radius,
                ..
            } => {
                let dx = target.0 - agent_pos.0;
                let dy = target.1 - agent_pos.1;
                let dist = (dx * dx + dy * dy).sqrt();
                if dist < 0.001 {
                    return (-agent_vel.0, -agent_vel.1);
                }
                let speed = if dist < *slowing_radius {
                    max_speed * (dist / slowing_radius)
                } else {
                    max_speed
                };
                let desired_x = (dx / dist) * speed;
                let desired_y = (dy / dist) * speed;
                (desired_x - agent_vel.0, desired_y - agent_vel.1)
            }
            Self::Wander {
                wander_radius,
                wander_distance,
                wander_angle,
                ..
            } => {
                let speed = (agent_vel.0 * agent_vel.0 + agent_vel.1 * agent_vel.1).sqrt();
                let (heading_x, heading_y) = if speed > 0.001 {
                    (agent_vel.0 / speed, agent_vel.1 / speed)
                } else {
                    (1.0, 0.0)
                };
                let circle_x = agent_pos.0 + heading_x * wander_distance;
                let circle_y = agent_pos.1 + heading_y * wander_distance;
                let target_x = circle_x + wander_angle.cos() * wander_radius;
                let target_y = circle_y + wander_angle.sin() * wander_radius;
                let dx = target_x - agent_pos.0;
                let dy = target_y - agent_pos.1;
                let dist = (dx * dx + dy * dy).sqrt();
                if dist < 0.001 {
                    return (0.0, 0.0);
                }
                let desired_x = (dx / dist) * max_speed;
                let desired_y = (dy / dist) * max_speed;
                (desired_x - agent_vel.0, desired_y - agent_vel.1)
            }
            Self::Pursue { .. } | Self::Evade { .. } | Self::Flock { .. } => {
                // Pursue, Evade, and Flock need access to other agents' positions,
                // which are provided at the AIWorld level during update.
                // The force is computed externally and this returns (0,0) as a baseline.
                (0.0, 0.0)
            }
        }
    }
}

/// Manages a list of steering behaviors and combines their forces each frame.
///
/// # Fields
/// - `behaviors` — `Vec<SteeringBehaviorType>`.
/// - `combine_mode` — `CombineMode`.
/// - `last_force` — `Force`.
pub struct SteeringManager {
    /// List of steering behaviors.
    pub behaviors: Vec<SteeringBehaviorType>,
    /// How forces are combined.
    pub combine_mode: CombineMode,
    /// Combined force from the last update.
    pub last_force: Force,
}

impl SteeringManager {
    /// Creates a new empty SteeringManager with weighted combination.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            behaviors: Vec::new(),
            combine_mode: CombineMode::Weighted,
            last_force: (0.0, 0.0),
        }
    }

    /// Computes the combined steering force for the given agent state.
    ///
    /// # Parameters
    /// - `agent_pos` — `(f32, f32)`.
    /// - `agent_vel` — `(f32, f32)`.
    /// - `max_speed` — `f32`.
    /// - `max_force` — `f32`.
    /// - `dt` — `f32`.
    ///
    /// # Returns
    /// `Force`.
    pub fn calculate(
        &mut self,
        agent_pos: (f32, f32),
        agent_vel: (f32, f32),
        max_speed: f32,
        max_force: f32,
        dt: f32,
    ) -> Force {
        let mut combined = (0.0f32, 0.0f32);
        match self.combine_mode {
            CombineMode::Weighted => {
                for b in &self.behaviors {
                    let f = b.calculate(agent_pos, agent_vel, max_speed, dt);
                    let w = b.base().weight;
                    combined.0 += f.0 * w;
                    combined.1 += f.1 * w;
                }
            }
            CombineMode::Priority => {
                for b in &self.behaviors {
                    let f = b.calculate(agent_pos, agent_vel, max_speed, dt);
                    let mag = (f.0 * f.0 + f.1 * f.1).sqrt();
                    if mag > 0.001 {
                        combined = (f.0 * b.base().weight, f.1 * b.base().weight);
                        break;
                    }
                }
            }
        }
        // Truncate to max_force
        let mag = (combined.0 * combined.0 + combined.1 * combined.1).sqrt();
        if mag > max_force {
            let scale = max_force / mag;
            combined.0 *= scale;
            combined.1 *= scale;
        }
        self.last_force = combined;
        combined
    }
}

impl Default for SteeringManager {
    fn default() -> Self {
        Self::new()
    }
}
