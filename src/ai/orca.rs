//! ORCA-style reciprocal collision avoidance for agent velocity updates.
//! Owns `ORCAAgent`, `ORCASolver`, and the internal `HalfPlane` helper.
//! Does not move agents; callers apply the computed `safe_velocity` externally.
/// One agent used by the ORCA solver.
#[derive(Clone)]
pub struct ORCAAgent {
    /// Agent position.
    pub position: (f32, f32),
    /// Current velocity.
    pub velocity: (f32, f32),
    /// Preferred velocity before collision avoidance.
    pub preferred_velocity: (f32, f32),
    /// Velocity chosen by the solver.
    pub safe_velocity: (f32, f32),
    /// Collision radius.
    pub radius: f32,
    /// Maximum speed.
    pub max_speed: f32,
}
impl ORCAAgent {
    /// Create a new agent at `(x, y)`.
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
/// Internal half-plane constraint used by the linear solver.
#[derive(Clone, Copy)]
struct HalfPlane {
    /// Point on the plane.
    point: (f32, f32),
    /// Outward normal.
    normal: (f32, f32),
}
/// Solver that computes collision-free velocities for all registered agents.
pub struct ORCASolver {
    /// Lookahead time used by the constraints.
    pub time_horizon: f32,
    /// Registered agents.
    pub agents: Vec<ORCAAgent>,
}
impl ORCASolver {
    /// Create a solver with a minimum time horizon of 0.1 seconds.
    pub fn new(time_horizon: f32) -> Self {
        Self {
            time_horizon: time_horizon.max(0.1),
            agents: Vec::new(),
        }
    }
    /// Add an agent and return its index.
    pub fn add_agent(&mut self, agent: ORCAAgent) -> usize {
        let idx = self.agents.len();
        self.agents.push(agent);
        idx
    }
    /// Remove and return the agent at `index`, or `None` when out of bounds.
    pub fn remove_agent(&mut self, index: usize) -> Option<ORCAAgent> {
        if index < self.agents.len() {
            Some(self.agents.swap_remove(index))
        } else {
            None
        }
    }
    /// Return the number of registered agents.
    pub fn agent_count(&self) -> usize {
        self.agents.len()
    }
    #[allow(clippy::needless_range_loop)]
    /// Compute safe velocities for all agents.
    pub fn compute(&mut self, _dt: f32) {
        let n = self.agents.len();
        let snapshot: Vec<(f32, f32, f32, f32, f32, f32)> = self
            .agents
            .iter()
            .map(|a| {
                (
                    a.position.0,
                    a.position.1,
                    a.velocity.0,
                    a.velocity.1,
                    a.radius,
                    a.max_speed,
                )
            })
            .collect();
        for i in 0..n {
            let (px, py, vx, vy, ri, max_spd) = snapshot[i];
            let pref = self.agents[i].preferred_velocity;
            let mut planes: Vec<HalfPlane> = Vec::with_capacity(n - 1);
            for j in 0..n {
                if i == j {
                    continue;
                }
                let (opx, opy, ovx, ovy, rj, _) = snapshot[j];
                let rel_pos = (opx - px, opy - py);
                let rel_vel = (vx - ovx, vy - ovy);
                let combined_radius = ri + rj;
                let dist_sq = rel_pos.0 * rel_pos.0 + rel_pos.1 * rel_pos.1;
                let r_sq = combined_radius * combined_radius;
                let hp = if dist_sq >= r_sq {
                    let dist = dist_sq.sqrt();
                    let tau = self.time_horizon.max(0.01);
                    let w = (rel_vel.0 - rel_pos.0 / tau, rel_vel.1 - rel_pos.1 / tau);
                    let w_len_sq = w.0 * w.0 + w.1 * w.1;
                    let dot = w.0 * rel_pos.0 + w.1 * rel_pos.1;
                    let (nx, ny) = if dot < 0.0 && dot * dot > r_sq * w_len_sq / (tau * tau) {
                        let (lx, ly) = (rel_pos.0 / dist, rel_pos.1 / dist);
                        (-lx, -ly)
                    } else {
                        let w_len = w_len_sq.sqrt().max(1e-6);
                        (w.0 / w_len, w.1 / w_len)
                    };
                    let u = (
                        nx * combined_radius / tau - rel_vel.0,
                        ny * combined_radius / tau - rel_vel.1,
                    );
                    HalfPlane {
                        point: (vx + u.0 * 0.5, vy + u.1 * 0.5),
                        normal: (nx, ny),
                    }
                } else {
                    let inv_dist = 1.0 / dist_sq.sqrt().max(1e-6);
                    let nx = -rel_pos.0 * inv_dist;
                    let ny = -rel_pos.1 * inv_dist;
                    HalfPlane {
                        point: (vx, vy),
                        normal: (nx, ny),
                    }
                };
                planes.push(hp);
            }
            let safe = Self::linear_program(pref, max_spd, &planes);
            self.agents[i].safe_velocity = safe;
        }
    }
    /// Project the preferred velocity against the half-plane set and clamp speed.
    fn linear_program(preferred: (f32, f32), max_speed: f32, planes: &[HalfPlane]) -> (f32, f32) {
        let mut vx = preferred.0;
        let mut vy = preferred.1;
        let spd_sq = vx * vx + vy * vy;
        if spd_sq > max_speed * max_speed {
            let s = max_speed / spd_sq.sqrt();
            vx *= s;
            vy *= s;
        }
        for plane in planes {
            let dot = (vx - plane.point.0) * plane.normal.0 + (vy - plane.point.1) * plane.normal.1;
            if dot < 0.0 {
                let proj_len =
                    dot / (plane.normal.0 * plane.normal.0 + plane.normal.1 * plane.normal.1);
                vx -= proj_len * plane.normal.0;
                vy -= proj_len * plane.normal.1;
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
