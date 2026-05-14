
use std::f32::consts::{PI, TAU};
/// Behavior kind used by context steering slots.
#[derive(Clone)]
pub enum ContextBehaviorKind {
    /// Interest toward a target point.
    SeekTarget {
        /// Target X coordinate.
        x: f32,
        /// Target Y coordinate.
        y: f32,
    },
    /// Danger around a point within a radius.
    AvoidPoint {
        /// Point X coordinate.
        x: f32,
        /// Point Y coordinate.
        y: f32,
        /// Avoidance radius.
        radius: f32,
    },
    /// Interest in a heading with jitter.
    Wander {
        /// Current wander angle.
        angle: f32,
        /// Angular jitter factor.
        jitter: f32,
    },
    /// Interest in a fixed direction.
    Direction {
        /// Direction angle in radians.
        angle: f32,
    },
    /// Danger near world bounds.
    AvoidBounds {
        /// Minimum X bound.
        min_x: f32,
        /// Minimum Y bound.
        min_y: f32,
        /// Maximum X bound.
        max_x: f32,
        /// Maximum Y bound.
        max_y: f32,
        /// Margin distance before avoidance starts.
        margin: f32,
    },
}
/// Single behavior contribution to a context-steering ring.
#[derive(Clone)]
pub struct ContextBehavior {
    /// Behavior kind.
    pub kind: ContextBehaviorKind,
    /// Contribution weight.
    pub weight: f32,
    /// `true` for interest, `false` for danger.
    pub is_interest: bool,
    /// Whether this behavior participates in evaluation.
    pub enabled: bool,
}
/// Slot-based steering accumulator with interest, danger, and result rings.
pub struct ContextSteering {
    /// Number of angular slots in the ring.
    slot_count: usize,
    /// Interest weights by slot.
    interest: Vec<f32>,
    /// Danger weights by slot.
    danger: Vec<f32>,
    /// Final result weights by slot.
    result: Vec<f32>,
    /// Registered behaviors.
    behaviors: Vec<ContextBehavior>,
    /// Chosen heading in radians from the last evaluation.
    chosen_dir: f32,
    /// Chosen magnitude from the last evaluation.
    chosen_magnitude: f32,
    /// Internal wander angle accumulator.
    wander_angle: f32,
}
impl ContextSteering {
    /// Create a context-steering sampler with at least four slots.
    pub fn new(slot_count: usize) -> Self {
        let n = slot_count.max(4);
        Self {
            slot_count: n,
            interest: vec![0.0; n],
            danger: vec![0.0; n],
            result: vec![0.0; n],
            behaviors: Vec::new(),
            chosen_dir: 0.0,
            chosen_magnitude: 0.0,
            wander_angle: 0.0,
        }
    }
    /// Return the number of angular slots.
    pub fn slot_count(&self) -> usize {
        self.slot_count
    }
    /// Add an interest behavior.
    pub fn add_interest(&mut self, kind: ContextBehaviorKind, weight: f32) {
        self.behaviors.push(ContextBehavior {
            kind,
            weight,
            is_interest: true,
            enabled: true,
        });
    }
    /// Add a danger behavior.
    pub fn add_danger(&mut self, kind: ContextBehaviorKind, weight: f32) {
        self.behaviors.push(ContextBehavior {
            kind,
            weight,
            is_interest: false,
            enabled: true,
        });
    }
    /// Add a seek-target interest behavior.
    pub fn add_seek_target(&mut self, tx: f32, ty: f32, weight: f32) {
        self.add_interest(ContextBehaviorKind::SeekTarget { x: tx, y: ty }, weight);
    }
    /// Add a wander interest behavior.
    pub fn add_wander(&mut self, jitter: f32, weight: f32) {
        self.add_interest(
            ContextBehaviorKind::Wander {
                angle: self.wander_angle,
                jitter,
            },
            weight,
        );
    }
    /// Add a point-avoidance danger behavior.
    pub fn add_avoid_point(&mut self, x: f32, y: f32, radius: f32, weight: f32) {
        self.add_danger(ContextBehaviorKind::AvoidPoint { x, y, radius }, weight);
    }
    /// Add a world-bounds avoidance danger behavior.
    pub fn add_avoid_bounds(
        &mut self,
        min_x: f32,
        min_y: f32,
        max_x: f32,
        max_y: f32,
        margin: f32,
        weight: f32,
    ) {
        self.add_danger(
            ContextBehaviorKind::AvoidBounds {
                min_x,
                min_y,
                max_x,
                max_y,
                margin,
            },
            weight,
        );
    }
    /// Remove all registered behaviors.
    pub fn clear_behaviors(&mut self) {
        self.behaviors.clear();
    }
    /// Evaluate all behaviors and return the chosen steering direction vector.
    pub fn evaluate(&mut self, ax: f32, ay: f32, vx: f32, vy: f32) -> (f32, f32) {
        for v in &mut self.interest {
            *v = 0.0;
        }
        for v in &mut self.danger {
            *v = 0.0;
        }
        let n = self.slot_count;
        let slot_angle = TAU / n as f32;
        let behaviors: Vec<ContextBehavior> = self.behaviors.clone();
        for b in &behaviors {
            if !b.enabled {
                continue;
            }
            let ring = if b.is_interest {
                &mut self.interest
            } else {
                &mut self.danger
            };
            match &b.kind {
                ContextBehaviorKind::SeekTarget { x, y } => {
                    let dx = x - ax;
                    let dy = y - ay;
                    let angle = dy.atan2(dx);
                    fill_cone(ring, angle, slot_angle, b.weight, n);
                }
                ContextBehaviorKind::AvoidPoint { x, y, radius } => {
                    let dx = ax - x;
                    let dy = ay - y;
                    let dist = (dx * dx + dy * dy).sqrt();
                    if dist < *radius {
                        let angle = dy.atan2(dx);
                        let strength = ((radius - dist) / radius) * b.weight;
                        fill_cone(ring, angle, slot_angle, strength, n);
                    }
                }
                ContextBehaviorKind::Wander { jitter, .. } => {
                    let hash_jitter = ((ay * 7.3 + ax * 3.7 + vx + vy).sin() * 43_758.547) % 1.0;
                    self.wander_angle += (hash_jitter * 2.0 - 1.0) * jitter;
                    fill_cone(ring, self.wander_angle, slot_angle, b.weight, n);
                }
                ContextBehaviorKind::Direction { angle } => {
                    fill_cone(ring, *angle, slot_angle, b.weight, n);
                }
                ContextBehaviorKind::AvoidBounds {
                    min_x,
                    min_y,
                    max_x,
                    max_y,
                    margin,
                } => {
                    if ax - min_x < *margin {
                        fill_cone(
                            ring,
                            0.0,
                            slot_angle,
                            b.weight * (1.0 - (ax - min_x) / margin).clamp(0.0, 1.0),
                            n,
                        );
                    }
                    if max_x - ax < *margin {
                        fill_cone(
                            ring,
                            PI,
                            slot_angle,
                            b.weight * (1.0 - (max_x - ax) / margin).clamp(0.0, 1.0),
                            n,
                        );
                    }
                    if ay - min_y < *margin {
                        fill_cone(
                            ring,
                            PI / 2.0,
                            slot_angle,
                            b.weight * (1.0 - (ay - min_y) / margin).clamp(0.0, 1.0),
                            n,
                        );
                    }
                    if max_y - ay < *margin {
                        fill_cone(
                            ring,
                            -PI / 2.0,
                            slot_angle,
                            b.weight * (1.0 - (max_y - ay) / margin).clamp(0.0, 1.0),
                            n,
                        );
                    }
                }
            }
        }
        let mut best_idx = 0;
        let mut best_val = f32::NEG_INFINITY;
        for i in 0..n {
            self.result[i] = if self.danger[i] > self.interest[i] {
                0.0
            } else {
                self.interest[i] - self.danger[i]
            };
            if self.result[i] > best_val {
                best_val = self.result[i];
                best_idx = i;
            }
        }
        if best_val <= 0.0 {
            self.chosen_magnitude = 0.0;
            return (0.0, 0.0);
        }
        let chosen_angle = best_idx as f32 * slot_angle;
        self.chosen_dir = chosen_angle;
        self.chosen_magnitude = best_val;
        (chosen_angle.cos(), chosen_angle.sin())
    }
    pub fn chosen_direction(&self) -> f32 {
        self.chosen_dir
    }
    pub fn chosen_magnitude(&self) -> f32 {
        self.chosen_magnitude
    }
    pub fn interest_map(&self) -> Vec<f32> {
        self.interest.clone()
    }
    pub fn danger_map(&self) -> Vec<f32> {
        self.danger.clone()
    }
}
#[allow(clippy::needless_range_loop)]
fn fill_cone(ring: &mut [f32], target_angle: f32, slot_angle: f32, weight: f32, n: usize) {
    for i in 0..n {
        let slot_dir = i as f32 * slot_angle;
        let diff = angle_diff_f32(target_angle, slot_dir).abs();
        if diff < slot_angle * 2.0 {
            let score = (diff / (slot_angle * 2.0) * (std::f32::consts::PI / 2.0)).cos() * weight;
            ring[i] = ring[i].max(score);
        }
    }
}
fn angle_diff_f32(a: f32, b: f32) -> f32 {
    let mut d = a - b;
    while d > PI {
        d -= TAU;
    }
    while d <= -PI {
        d += TAU;
    }
    d
}
