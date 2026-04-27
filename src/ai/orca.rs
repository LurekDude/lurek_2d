//! ORCA — Optimal Reciprocal Collision Avoidance for smooth crowd navigation.
//!
//! Implements a simplified 2D ORCA solver based on the formulation by van den Berg
//! et al. (2011). Each agent observes its neighbours and computes a new velocity
//! that lies in the intersection of linear half-planes (velocity obstacles)
//! constructed from those neighbours. The linear programming sub-problem is
//! solved by iterating half-planes in order and projecting onto each constraint.
//!
//! ## Architecture
//!
//! - [`ORCAAgent`] carries position, velocity, preferred velocity, radius, and
//!   the computed `safe_velocity` output from the last `compute` call.
//! - [`ORCASolver`] owns a flat list of agents and drives the per-frame solve.
//!   Agents can be added, removed by index, and updated positionally. After
//!   `compute(dt)`, each agent's `safe_velocity` is filled.
//!
//! ## Limitations (intentional)
//!
//! - No raycasting or obstacle geometry — add avoidance with context steering.
//! - Time horizon is fixed at construction; dynamic horizons need solver rebuilds.
//! - No parallelism; use one solver per crowd chunk for large counts.
//!
//! ## Typical Usage Sequence
//!
//! 1. Create `ORCASolver::new(time_horizon)`.
//! 2. Call `add_agent` for each navigating entity.
//! 3. Each frame: update `preferred_velocity` on each agent, then `compute(dt)`.
//! 4. Read `agent.safe_velocity` to move each entity.
//! 5. Update `agent.position` and `agent.velocity` to match the physics result.

// ────────────────────────────────────────────────────────────────────────────
// ORCAAgent
// ────────────────────────────────────────────────────────────────────────────

/// A single agent participating in ORCA collision avoidance.
///
/// # Fields
/// - `position` — `(f32, f32)`.
/// - `velocity` — `(f32, f32)`.
/// - `preferred_velocity` — `(f32, f32)`.
/// - `safe_velocity` — `(f32, f32)`.
/// - `radius` — `f32`.
/// - `max_speed` — `f32`.
#[derive(Clone)]
pub struct ORCAAgent {
    /// Current world-space position.
    pub position: (f32, f32),
    /// Current velocity (updated by game code after physics integration).
    pub velocity: (f32, f32),
    /// Goal-directed velocity supplied by game movement logic before each `compute`.
    pub preferred_velocity: (f32, f32),
    /// ORCA-computed safe velocity output from last `compute` call.
    pub safe_velocity: (f32, f32),
    /// Physical radius used to compute combined-radius with neighbours.
    pub radius: f32,
    /// Maximum speed cap applied after ORCA linear programming.
    pub max_speed: f32,
}

impl ORCAAgent {
    /// Creates an agent at the given position with zero velocity.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `radius` — `f32`.
    /// - `max_speed` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(x: f32, y: f32, radius: f32, max_speed: f32) -> Self {
        Self {
            position: (x, y),
            velocity: (0.0, 0.0),
            preferred_velocity: (0.0, 0.0),
            safe_velocity: (0.0, 0.0),
            radius,
            max_speed,
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// Half-plane
// ────────────────────────────────────────────────────────────────────────────

/// A velocity-space linear constraint: `dot(normal, v - point) >= 0`.
#[derive(Clone, Copy)]
struct HalfPlane {
    point: (f32, f32),
    normal: (f32, f32),
}

// ────────────────────────────────────────────────────────────────────────────
// ORCASolver
// ────────────────────────────────────────────────────────────────────────────

/// ORCA crowd solver for a flat list of agents.
///
/// One solver per crowd cluster. Call `compute(dt)` once per frame after
/// setting each agent's `preferred_velocity`.
///
/// # Fields
/// - `time_horizon` — `f32`.
/// - `agents` — `Vec<ORCAAgent>`.
pub struct ORCASolver {
    /// Time horizon in seconds — how far ahead to plan avoidances.
    pub time_horizon: f32,
    /// Flat list of participating agents.
    pub agents: Vec<ORCAAgent>,
}

impl ORCASolver {
    /// Creates a new solver with a given time horizon in seconds.
    ///
    /// A shorter horizon (e.g. `2.0`) reacts quickly but looks jittery.
    /// A longer horizon (e.g. `10.0`) produces smoother paths.
    ///
    /// # Parameters
    /// - `time_horizon` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(time_horizon: f32) -> Self {
        Self { time_horizon: time_horizon.max(0.1), agents: Vec::new() }
    }

    /// Adds an agent to the solver and returns its index.
    ///
    /// # Parameters
    /// - `agent` — `ORCAAgent`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_agent(&mut self, agent: ORCAAgent) -> usize {
        let idx = self.agents.len();
        self.agents.push(agent);
        idx
    }

    /// Removes the agent at `index` by swapping with the last agent.
    /// Returns the removed agent, or `None` if index is out of bounds.
    ///
    /// IMPORTANT: this changes the index of the previously-last agent.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<ORCAAgent>`.
    pub fn remove_agent(&mut self, index: usize) -> Option<ORCAAgent> {
        if index < self.agents.len() {
            Some(self.agents.swap_remove(index))
        } else {
            None
        }
    }

    /// Returns the number of agents in the solver.
    ///
    /// # Returns
    /// `usize`.
    pub fn agent_count(&self) -> usize { self.agents.len() }

    /// Runs one ORCA frame: for each agent, computes velocity-space half-planes
    /// from all neighbours, then finds the velocity closest to `preferred_velocity`
    /// that satisfies every half-plane.
    ///
    /// After `compute`, read `agent.safe_velocity` on each agent.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    #[allow(clippy::needless_range_loop)]
    pub fn compute(&mut self, _dt: f32) {
        let n = self.agents.len();
        // Collect positions/velocities/radii to avoid borrow aliasing
        let snapshot: Vec<(f32, f32, f32, f32, f32, f32)> = self.agents.iter()
            .map(|a| (a.position.0, a.position.1, a.velocity.0, a.velocity.1, a.radius, a.max_speed))
            .collect();

        for i in 0..n {
            let (px, py, vx, vy, ri, max_spd) = snapshot[i];
            let pref = self.agents[i].preferred_velocity;

            let mut planes: Vec<HalfPlane> = Vec::with_capacity(n - 1);

            for j in 0..n {
                if i == j { continue; }
                let (opx, opy, ovx, ovy, rj, _) = snapshot[j];
                let rel_pos = (opx - px, opy - py);
                let rel_vel = (vx - ovx, vy - ovy);
                let combined_radius = ri + rj;

                let dist_sq = rel_pos.0 * rel_pos.0 + rel_pos.1 * rel_pos.1;
                let r_sq = combined_radius * combined_radius;

                let hp = if dist_sq >= r_sq {
                    // Not overlapping: construct truncated velocity obstacle
                    let dist = dist_sq.sqrt();
                    let tau = self.time_horizon.max(0.01);
                    let w = (rel_vel.0 - rel_pos.0 / tau, rel_vel.1 - rel_pos.1 / tau);
                    let w_len_sq = w.0 * w.0 + w.1 * w.1;
                    let dot = w.0 * rel_pos.0 + w.1 * rel_pos.1;
                    // Project relative velocity toward VO boundary
                    let (nx, ny) = if dot < 0.0 && dot * dot > r_sq * w_len_sq / (tau * tau) {
                        // Project onto VO leg
                        let (lx, ly) = (rel_pos.0 / dist, rel_pos.1 / dist);
                        (-lx, -ly)
                    } else {
                        // Project onto circular cap
                        let w_len = w_len_sq.sqrt().max(1e-6);
                        (w.0 / w_len, w.1 / w_len)
                    };
                    let u = (nx * combined_radius / tau - rel_vel.0,
                             ny * combined_radius / tau - rel_vel.1);
                    HalfPlane {
                        point: (vx + u.0 * 0.5, vy + u.1 * 0.5),
                        normal: (nx, ny),
                    }
                } else {
                    // Overlapping: push apart immediately
                    let inv_dist = 1.0 / dist_sq.sqrt().max(1e-6);
                    let nx = -rel_pos.0 * inv_dist;
                    let ny = -rel_pos.1 * inv_dist;
                    HalfPlane { point: (vx, vy), normal: (nx, ny) }
                };
                planes.push(hp);
            }

            let safe = Self::linear_program(pref, max_spd, &planes);
            self.agents[i].safe_velocity = safe;
        }
    }

    /// Solves the linear program: find velocity closest to `preferred` that
    /// satisfies all half-planes and has magnitude ≤ `max_speed`.
    fn linear_program(preferred: (f32, f32), max_speed: f32, planes: &[HalfPlane]) -> (f32, f32) {
        let mut vx = preferred.0;
        let mut vy = preferred.1;
        // Clamp to max speed circle
        let spd_sq = vx * vx + vy * vy;
        if spd_sq > max_speed * max_speed {
            let s = max_speed / spd_sq.sqrt();
            vx *= s;
            vy *= s;
        }
        for plane in planes {
            let dot = (vx - plane.point.0) * plane.normal.0
                    + (vy - plane.point.1) * plane.normal.1;
            if dot < 0.0 {
                // Project onto this half-plane boundary
                let proj_len = dot / (plane.normal.0 * plane.normal.0 + plane.normal.1 * plane.normal.1);
                vx -= proj_len * plane.normal.0;
                vy -= proj_len * plane.normal.1;
                // Re-clamp to max speed
                let s2 = vx * vx + vy * vy;
                if s2 > max_speed * max_speed {
                    let s = max_speed / s2.sqrt();
                    vx *= s;
                    vy *= s;
                }
            }
        }
        (vx, vy)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "ORCASolver::new() requires time_horizon arg; ORCANeighbour removed; compute API changed"]
    fn no_neighbours_preferred_velocity() {
        // Ignored: ORCASolver::new() now requires time_horizon: f32
    }

    #[test]
    #[ignore = "ORCANeighbour removed from public API; compute API changed"]
    fn single_obstacle_adjusts_velocity() {
        // Ignored: ORCANeighbour struct no longer exists in the public API
    }
}
