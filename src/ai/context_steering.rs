//! radial context-steering evaluator using interest and danger rings.
use std::f32::consts::{PI, TAU};

// ---- Type: ContextBehaviorKind ----

/// Variant of a context steering behavior defining how it fills the ring.
#[derive(Clone)]
pub enum ContextBehaviorKind {
    /// Fill interest slots pointing toward `(x, y)` from the agent position.
    SeekTarget {
        /// Target world position x.
        x: f32,
        /// Target world position y.
        y: f32,
    },
    /// Fill danger slots pointing away from a point within a given radius.
    AvoidPoint {
        /// Danger source position x.
        x: f32,
        /// Danger source position y.
        y: f32,
        /// Radius within which this danger is relevant.
        radius: f32,
    },
    /// Fill interest toward slightly randomised directions for wandering.
    Wander {
        /// Current wander angle in radians (updated each `evaluate` call).
        angle: f32,
        /// Maximum angle change per `evaluate` call in radians.
        jitter: f32,
    },
    /// Fill interest in a fixed world-space direction (compass heading).
    Direction {
        /// Direction in radians.
        angle: f32,
    },
    /// Fill danger for slots pointing toward world bounds.
    AvoidBounds {
        /// Left world boundary.
        min_x: f32,
        /// Bottom world boundary.
        min_y: f32,
        /// Right world boundary.
        max_x: f32,
        /// Top world boundary.
        max_y: f32,
        /// Distance from boundary at which danger begins.
        margin: f32,
    },
}

// ---- Type: ContextBehavior ----

/// A single context steering behavior with a weight and enabled flag.
#[derive(Clone)]
pub struct ContextBehavior {
    /// What kind of fill this behavior performs.
    pub kind: ContextBehaviorKind,
    /// Multiplier applied to scores written by this behavior.
    pub weight: f32,
    /// If `true`, fills the interest ring; if `false`, fills the danger ring.
    pub is_interest: bool,
    /// When `false`, the behavior is ignored during evaluation.
    pub enabled: bool,
}

// ---- Type: ContextSteering ----

/// Radial context steering evaluator producing a smooth, obstacle-aware movement direction.
pub struct ContextSteering {
    slot_count: usize,
    /// Interest ring: N slots, value = desire to go in that direction.
    interest: Vec<f32>,
    /// Danger ring: N slots, value = danger of going in that direction.
    danger: Vec<f32>,
    /// Result ring: interest - danger.
    result: Vec<f32>,
    /// All registered behaviors.
    behaviors: Vec<ContextBehavior>,
    /// Chosen direction angle in radians from last evaluate call.
    chosen_dir: f32,
    /// Chosen magnitude (0 if no interest).
    chosen_magnitude: f32,
    /// Running wander direction angle, mutated per evaluate.
    wander_angle: f32,
}

impl ContextSteering {
    /// Create a new context steering evaluator with `slot_count` direction slots.
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

    /// Return the number of direction slots.
    pub fn slot_count(&self) -> usize {
        self.slot_count
    }

    /// Add a behavior that fills the interest ring (where to go).
    pub fn add_interest(&mut self, kind: ContextBehaviorKind, weight: f32) {
        self.behaviors.push(ContextBehavior {
            kind,
            weight,
            is_interest: true,
            enabled: true,
        });
    }

    /// Add a behavior that fills the danger ring (where NOT to go).
    pub fn add_danger(&mut self, kind: ContextBehaviorKind, weight: f32) {
        self.behaviors.push(ContextBehavior {
            kind,
            weight,
            is_interest: false,
            enabled: true,
        });
    }

    /// Add a `SeekTarget` interest behavior pointing toward `(tx, ty)`.
    pub fn add_seek_target(&mut self, tx: f32, ty: f32, weight: f32) {
        self.add_interest(ContextBehaviorKind::SeekTarget { x: tx, y: ty }, weight);
    }

    /// Add a `Wander` interest behavior.
    pub fn add_wander(&mut self, jitter: f32, weight: f32) {
        self.add_interest(
            ContextBehaviorKind::Wander {
                angle: self.wander_angle,
                jitter,
            },
            weight,
        );
    }

    /// Add an `AvoidPoint` danger behavior.
    pub fn add_avoid_point(&mut self, x: f32, y: f32, radius: f32, weight: f32) {
        self.add_danger(ContextBehaviorKind::AvoidPoint { x, y, radius }, weight);
    }

    /// Add an `AvoidBounds` danger behavior.
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

    /// Clears all behaviors, resetting the evaluator to a blank state.
    pub fn clear_behaviors(&mut self) {
        self.behaviors.clear();
    }

    /// Evaluates interest and danger rings from the current agent position and
    pub fn evaluate(&mut self, ax: f32, ay: f32, vx: f32, vy: f32) -> (f32, f32) {
        // Reset rings
        for v in &mut self.interest {
            *v = 0.0;
        }
        for v in &mut self.danger {
            *v = 0.0;
        }

        let n = self.slot_count;
        let slot_angle = TAU / n as f32;

        // Use a local copy of behaviors to avoid borrow conflicts
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
                    // Perturb wander angle each evaluation
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
                    // Write danger for slots pointing toward nearby bounds
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

        // Compute result: interest masked by danger
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

    /// Return the chosen direction angle from the last `evaluate` call (radians).
    pub fn chosen_direction(&self) -> f32 {
        self.chosen_dir
    }

    /// Return the chosen magnitude (net interest score) from the last `evaluate` call.
    pub fn chosen_magnitude(&self) -> f32 {
        self.chosen_magnitude
    }

    /// Return a copy of the current interest ring values.
    pub fn interest_map(&self) -> Vec<f32> {
        self.interest.clone()
    }

    /// Return a copy of the current danger ring values.
    pub fn danger_map(&self) -> Vec<f32> {
        self.danger.clone()
    }
}

// ---- Type: Helpers ----

/// Fills a gaussian-like lobe of slots centered on `target_angle`.
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

/// Normalised angular difference in `(-, ]`.
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

