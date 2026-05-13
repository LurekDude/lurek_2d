//! steering behavior models and force-combination runtime.
/// 2D force vector (fx, fy).
pub type Force = (f32, f32);

/// Determines how multiple active steering behaviors are combined into a single final force each frame.
#[derive(Debug, Clone, PartialEq)]
pub enum CombineMode {
    /// Sum all forces - weight, truncate to maxForce.
    Weighted,
    /// Use first non-zero force, ignore rest.
    Priority,
}

impl CombineMode {
    /// Parse from Lua string. Returns an error if the source data is malformed or missing.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "priority" => Self::Priority,
            _ => Self::Weighted,
        }
    }

    /// Return the Lua string representation.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Weighted => "weighted",
            Self::Priority => "priority",
        }
    }
}

/// Shared parameters common to all steering behavior instances.
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
    /// A user-defined Lua callback computes a custom steering force.
    Custom {
        /// Opaque ID referencing the Lua callback in the API-layer registry.
        callback_id: u32,
        /// Common steering data (weight and enabled state).
        base: SteeringBase,
    },
}

impl SteeringBehaviorType {
    /// Return a reference to the common steering data.
    pub fn base(&self) -> &SteeringBase {
        match self {
            Self::Seek { base, .. }
            | Self::Flee { base, .. }
            | Self::Arrive { base, .. }
            | Self::Wander { base, .. }
            | Self::Pursue { base, .. }
            | Self::Evade { base, .. }
            | Self::Flock { base, .. }
            | Self::Custom { base, .. } => base,
        }
    }

    /// Return a mutable reference to the common steering data.
    pub fn base_mut(&mut self) -> &mut SteeringBase {
        match self {
            Self::Seek { base, .. }
            | Self::Flee { base, .. }
            | Self::Arrive { base, .. }
            | Self::Wander { base, .. }
            | Self::Pursue { base, .. }
            | Self::Evade { base, .. }
            | Self::Flock { base, .. }
            | Self::Custom { base, .. } => base,
        }
    }

    /// Return the behavior kind as a Lua-friendly string.
    pub fn kind(&self) -> &'static str {
        match self {
            Self::Seek { .. } => "seek",
            Self::Flee { .. } => "flee",
            Self::Arrive { .. } => "arrive",
            Self::Wander { .. } => "wander",
            Self::Pursue { .. } => "pursue",
            Self::Evade { .. } => "evade",
            Self::Flock { .. } => "flock",
            Self::Custom { .. } => "custom",
        }
    }

    /// Computes the 2D steering force for this behavior given the agent's current position, velocity, max speed, and frame delta.
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
            // Custom behavior: force computation handled by LuaSteeringManager::applyCustomSteering.
            // Returns (0, 0) here; the Lua API layer invokes the callback separately.
            Self::Custom { .. } => (0.0, 0.0),
        }
    }
}

/// Manages a list of steering behaviors and combines their forces each frame.
pub struct SteeringManager {
    /// List of steering behaviors.
    pub behaviors: Vec<SteeringBehaviorType>,
    /// How forces are combined.
    pub combine_mode: CombineMode,
    /// Combined force from the last update.
    pub last_force: Force,
    /// Cell size for the optional spatial-hash neighbourhood search.
    pub cell_size: f32,
    /// Whether to use spatial-hash bucketing for neighbourhood queries.
    pub use_spatial_hash: bool,
    /// World-space waypoint list produced by nav-grid/navmesh path queries.
    pub path_waypoints: Vec<(f32, f32)>,
    /// Index of the current waypoint in `path_waypoints`.
    pub path_index: usize,
    /// Radius used to mark a waypoint as reached.
    pub path_reach_radius: f32,
    /// Weight multiplier applied to the path-follow steering force.
    pub path_weight: f32,
}

impl SteeringManager {
    /// Create a new empty SteeringManager with weighted combination.
    pub fn new() -> Self {
        Self {
            behaviors: Vec::new(),
            combine_mode: CombineMode::Weighted,
            last_force: (0.0, 0.0),
            cell_size: 64.0,
            use_spatial_hash: false,
            path_waypoints: Vec::new(),
            path_index: 0,
            path_reach_radius: 12.0,
            path_weight: 1.0,
        }
    }

    /// Computes the combined steering force for the given agent state.
    pub fn calculate(
        &mut self,
        agent_pos: (f32, f32),
        agent_vel: (f32, f32),
        max_speed: f32,
        max_force: f32,
        dt: f32,
    ) -> Force {
        let mut combined = (0.0f32, 0.0f32);
        let path_force = self.calculate_path_force(agent_pos, agent_vel, max_speed);
        match self.combine_mode {
            CombineMode::Weighted => {
                combined.0 += path_force.0 * self.path_weight;
                combined.1 += path_force.1 * self.path_weight;
                for b in &self.behaviors {
                    let f = b.calculate(agent_pos, agent_vel, max_speed, dt);
                    let w = b.base().weight;
                    combined.0 += f.0 * w;
                    combined.1 += f.1 * w;
                }
            }
            CombineMode::Priority => {
                let path_mag = (path_force.0 * path_force.0 + path_force.1 * path_force.1).sqrt();
                if path_mag > 0.001 {
                    combined = (path_force.0 * self.path_weight, path_force.1 * self.path_weight);
                } else {
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

    /// Add a Seek behavior targeting `(tx, ty)` with the given weight.
    pub fn add_seek(&mut self, tx: f32, ty: f32, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Seek {
            target: (tx, ty),
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Add a Flee behavior away from `(tx, ty)` within `panic_dist`.
    pub fn add_flee(&mut self, tx: f32, ty: f32, panic_dist: f32, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Flee {
            target: (tx, ty),
            panic_dist,
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Add an Arrive behavior targeting `(tx, ty)` with deceleration inside `slowing_radius`.
    pub fn add_arrive(&mut self, tx: f32, ty: f32, slowing_radius: f32, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Arrive {
            target: (tx, ty),
            slowing_radius,
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Add a Wander behavior with the given circle parameters.
    pub fn add_wander(&mut self, radius: f32, distance: f32, jitter: f32, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Wander {
            wander_radius: radius,
            wander_distance: distance,
            wander_jitter: jitter,
            wander_angle: 0.0,
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Add a Pursue behavior targeting a named agent.
    pub fn add_pursue(&mut self, target_name: Option<String>, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Pursue {
            target_name,
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Add an Evade behavior fleeing from a named threat agent.
    pub fn add_evade(&mut self, threat_name: Option<String>, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Evade {
            threat_name,
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Add a Flock behavior for group movement among named neighbors.
    pub fn add_flock(&mut self, neighbor_radius: f32, sep: f32, align: f32, coh: f32, weight: f32) {
        self.behaviors.push(SteeringBehaviorType::Flock {
            neighbor_radius,
            sep_weight: sep,
            align_weight: align,
            coh_weight: coh,
            neighbor_names: Vec::new(),
            base: SteeringBase {
                weight,
                enabled: true,
            },
        });
    }

    /// Set the combination mode from a Lua string (`"weighted"` or `"priority"`).
    pub fn set_combine_mode_str(&mut self, mode: &str) {
        self.combine_mode = CombineMode::parse_str(mode);
    }

    /// Return the force vector computed during the last `calculate()` call.
    pub fn last_force(&self) -> Force {
        self.last_force
    }

    /// Set the cell size used by the spatial-hash neighbourhood search.
    pub fn set_cell_size(&mut self, size: f32) {
        self.cell_size = size.max(0.1);
    }

    /// Enables or disables spatial-hash bucketing for neighbourhood queries.
    pub fn set_use_spatial_hash(&mut self, enabled: bool) {
        self.use_spatial_hash = enabled;
    }

    /// Replace the current path-follow waypoints with a new world-space path.
    pub fn set_path(&mut self, waypoints: Vec<(f32, f32)>, reach_radius: f32, weight: f32) {
        self.path_waypoints = waypoints;
        self.path_index = 0;
        self.path_reach_radius = reach_radius.max(0.1);
        self.path_weight = weight.max(0.0);
    }

    /// Clears the active path-follow state.
    pub fn clear_path(&mut self) {
        self.path_waypoints.clear();
        self.path_index = 0;
    }

    /// Return true when there is an unfinished waypoint path.
    pub fn has_active_path(&self) -> bool {
        self.path_index < self.path_waypoints.len()
    }

    /// Return path-follow progress as `(current_index, total_waypoints)`.
    pub fn path_progress(&self) -> (usize, usize) {
        (self.path_index, self.path_waypoints.len())
    }

    fn calculate_path_force(
        &mut self,
        agent_pos: (f32, f32),
        agent_vel: (f32, f32),
        max_speed: f32,
    ) -> Force {
        while self.path_index < self.path_waypoints.len() {
            let wp = self.path_waypoints[self.path_index];
            let dx = wp.0 - agent_pos.0;
            let dy = wp.1 - agent_pos.1;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist <= self.path_reach_radius {
                self.path_index += 1;
            } else {
                break;
            }
        }

        if self.path_index >= self.path_waypoints.len() {
            return (0.0, 0.0);
        }

        let target = self.path_waypoints[self.path_index];
        let dx = target.0 - agent_pos.0;
        let dy = target.1 - agent_pos.1;
        let dist = (dx * dx + dy * dy).sqrt();
        if dist < 0.001 {
            return (0.0, 0.0);
        }

        let is_last = self.path_index + 1 == self.path_waypoints.len();
        let desired_speed = if is_last {
            let slowing_radius = (self.path_reach_radius * 3.0).max(1.0);
            if dist < slowing_radius {
                max_speed * (dist / slowing_radius)
            } else {
                max_speed
            }
        } else {
            max_speed
        };

        let desired_x = (dx / dist) * desired_speed;
        let desired_y = (dy / dist) * desired_speed;
        (desired_x - agent_vel.0, desired_y - agent_vel.1)
    }
}

impl Default for SteeringManager {
    fn default() -> Self {
        Self::new()
    }
}

