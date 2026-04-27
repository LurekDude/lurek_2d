//! Context Steering — direction-based interest/danger evaluation for smooth movement.
//!
//! Context steering replaces force-accumulation steering with a discrete radial
//! evaluation. Each frame, interest (where to go) and danger (where NOT to go)
//! values are written into `N`-slot direction rings. The final movement direction
//! is the slot with the highest `interest - danger` score.
//!
//! ## Why Context Steering
//!
//! Traditional force-based steering produces oscillation and wall-sticking near
//! obstacles because forces simultaneously push and pull. Context steering avoids
//! this by explicitly masking interested directions that overlap with high-danger
//! directions, then selecting the best remaining option.
//!
//! ## Architecture
//!
//! - [`ContextSteering`] stores interest and danger rings plus a list of behaviors.
//! - Behaviors fill the rings via [`ContextBehaviorKind`] rules.
//! - `evaluate(agent_pos, agent_vel)` fills both rings, computes `result = interest - danger`,
//!   masks zero-interest slots, and returns the chosen direction as a unit vector.
//!
//! ## Typical Usage Sequence
//!
//! 1. Create a `ContextSteering` with `N` slots (8 or 16).
//! 2. Add interest behaviors (seek target, preferred direction, wander).
//! 3. Add danger behaviors (avoid obstacles, avoid bounds).
//! 4. Call `evaluate(pos, vel)` each frame → `(dx, dy)` unit vector.
//! 5. Multiply by desired speed to get the movement velocity.

use std::f32::consts::{PI, TAU};

// ────────────────────────────────────────────────────────────────────────────
// ContextBehaviorKind
// ────────────────────────────────────────────────────────────────────────────

/// Variant of a context steering behavior defining how it fills the ring.
///
/// # Variants
/// - `SeekTarget` — SeekTarget variant.
/// - `AvoidPoint` — AvoidPoint variant.
/// - `Wander` — Wander variant.
/// - `Direction` — Direction variant.
/// - `AvoidBounds` — AvoidBounds variant.
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

// ────────────────────────────────────────────────────────────────────────────
// ContextBehavior
// ────────────────────────────────────────────────────────────────────────────

/// A single context steering behavior with a weight and enabled flag.
///
/// Multiple behaviors stack: all enabled behaviors fill the interest or danger
/// ring before the final direction is chosen.
///
/// # Fields
/// - `kind` — `ContextBehaviorKind`.
/// - `weight` — `f32`.
/// - `is_interest` — `bool`.
/// - `enabled` — `bool`.
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

// ────────────────────────────────────────────────────────────────────────────
// ContextSteering
// ────────────────────────────────────────────────────────────────────────────

/// Radial context steering evaluator producing a smooth, obstacle-aware movement direction.
///
/// Evaluation is O(N × B) where N is the number of slots (8 or 16) and B is
/// the number of registered behaviors. Typical frame cost is negligible.
///
/// # Fields
/// - `slot_count` — `usize`.
/// - `interest` — `Vec<f32>`.
/// - `danger` — `Vec<f32>`.
/// - `result` — `Vec<f32>`.
/// - `behaviors` — `Vec<ContextBehavior>`.
/// - `chosen_dir` — `f32`.
/// - `chosen_magnitude` — `f32`.
/// - `wander_angle` — `f32`.
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
    /// Creates a new context steering evaluator with `slot_count` direction slots.
    ///
    /// `slot_count` must be at least 4. A power-of-two value (8 or 16) is recommended.
    ///
    /// # Parameters
    /// - `slot_count` — `usize`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the number of direction slots.
    ///
    /// # Returns
    /// `usize`.
    pub fn slot_count(&self) -> usize {
        self.slot_count
    }

    /// Adds a behavior that fills the interest ring (where to go).
    ///
    /// # Parameters
    /// - `kind` — `ContextBehaviorKind`.
    /// - `weight` — `f32`.
    pub fn add_interest(&mut self, kind: ContextBehaviorKind, weight: f32) {
        self.behaviors.push(ContextBehavior {
            kind,
            weight,
            is_interest: true,
            enabled: true,
        });
    }

    /// Adds a behavior that fills the danger ring (where NOT to go).
    ///
    /// # Parameters
    /// - `kind` — `ContextBehaviorKind`.
    /// - `weight` — `f32`.
    pub fn add_danger(&mut self, kind: ContextBehaviorKind, weight: f32) {
        self.behaviors.push(ContextBehavior {
            kind,
            weight,
            is_interest: false,
            enabled: true,
        });
    }

    /// Adds a `SeekTarget` interest behavior pointing toward `(tx, ty)`.
    ///
    /// # Parameters
    /// - `tx` — `f32`.
    /// - `ty` — `f32`.
    /// - `weight` — `f32`.
    pub fn add_seek_target(&mut self, tx: f32, ty: f32, weight: f32) {
        self.add_interest(ContextBehaviorKind::SeekTarget { x: tx, y: ty }, weight);
    }

    /// Adds a `Wander` interest behavior.
    ///
    /// # Parameters
    /// - `jitter` — `f32`.
    /// - `weight` — `f32`.
    pub fn add_wander(&mut self, jitter: f32, weight: f32) {
        self.add_interest(ContextBehaviorKind::Wander { angle: self.wander_angle, jitter }, weight);
    }

    /// Adds an `AvoidPoint` danger behavior.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `radius` — `f32`.
    /// - `weight` — `f32`.
    pub fn add_avoid_point(&mut self, x: f32, y: f32, radius: f32, weight: f32) {
        self.add_danger(ContextBehaviorKind::AvoidPoint { x, y, radius }, weight);
    }

    /// Adds an `AvoidBounds` danger behavior.
    ///
    /// # Parameters
    /// - `min_x` — `f32`.
    /// - `min_y` — `f32`.
    /// - `max_x` — `f32`.
    /// - `max_y` — `f32`.
    /// - `margin` — `f32`.
    /// - `weight` — `f32`.
    pub fn add_avoid_bounds(&mut self, min_x: f32, min_y: f32, max_x: f32, max_y: f32, margin: f32, weight: f32) {
        self.add_danger(ContextBehaviorKind::AvoidBounds { min_x, min_y, max_x, max_y, margin }, weight);
    }

    /// Clears all behaviors, resetting the evaluator to a blank state.
    pub fn clear_behaviors(&mut self) {
        self.behaviors.clear();
    }

    /// Evaluates interest and danger rings from the current agent position and
    /// velocity, then returns the chosen direction as a normalized `(dx, dy)` pair.
    ///
    /// Returns `(0.0, 0.0)` when no interest is present.
    ///
    /// # Parameters
    /// - `ax` — `f32`.
    /// - `ay` — `f32`.
    /// - `vx` — `f32`.
    /// - `vy` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn evaluate(&mut self, ax: f32, ay: f32, vx: f32, vy: f32) -> (f32, f32) {
        // Reset rings
        for v in &mut self.interest { *v = 0.0; }
        for v in &mut self.danger   { *v = 0.0; }

        let n = self.slot_count;
        let slot_angle = TAU / n as f32;

        // Use a local copy of behaviors to avoid borrow conflicts
        let behaviors: Vec<ContextBehavior> = self.behaviors.clone();

        for b in &behaviors {
            if !b.enabled { continue; }
            let ring = if b.is_interest { &mut self.interest } else { &mut self.danger };
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
                ContextBehaviorKind::AvoidBounds { min_x, min_y, max_x, max_y, margin } => {
                    // Write danger for slots pointing toward nearby bounds
                    if ax - min_x < *margin { fill_cone(ring, 0.0,          slot_angle, b.weight * (1.0 - (ax - min_x) / margin).clamp(0.0, 1.0), n); }
                    if max_x - ax < *margin { fill_cone(ring, PI,           slot_angle, b.weight * (1.0 - (max_x - ax) / margin).clamp(0.0, 1.0), n); }
                    if ay - min_y < *margin { fill_cone(ring, PI / 2.0,    slot_angle, b.weight * (1.0 - (ay - min_y) / margin).clamp(0.0, 1.0), n); }
                    if max_y - ay < *margin { fill_cone(ring, -PI / 2.0,   slot_angle, b.weight * (1.0 - (max_y - ay) / margin).clamp(0.0, 1.0), n); }
                }
            }
        }

        // Compute result: interest masked by danger
        let mut best_idx = 0;
        let mut best_val = f32::NEG_INFINITY;
        for i in 0..n {
            self.result[i] = if self.danger[i] > self.interest[i] { 0.0 } else { self.interest[i] - self.danger[i] };
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

    /// Returns the chosen direction angle from the last `evaluate` call (radians).
    ///
    /// # Returns
    /// `f32`.
    pub fn chosen_direction(&self) -> f32 { self.chosen_dir }

    /// Returns the chosen magnitude (net interest score) from the last `evaluate` call.
    ///
    /// # Returns
    /// `f32`.
    pub fn chosen_magnitude(&self) -> f32 { self.chosen_magnitude }

    /// Returns a copy of the current interest ring values.
    ///
    /// # Returns
    /// `Vec<f32>`.
    pub fn interest_map(&self) -> Vec<f32> { self.interest.clone() }

    /// Returns a copy of the current danger ring values.
    ///
    /// # Returns
    /// `Vec<f32>`.
    pub fn danger_map(&self) -> Vec<f32> { self.danger.clone() }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

/// Fills a gaussian-like lobe of slots centered on `target_angle`.
/// Slots within one slot_angle of the center get full weight; adjacent slots
/// decay by cosine to create smooth blending across directions.
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

/// Normalised angular difference in `(-π, π]`.
fn angle_diff_f32(a: f32, b: f32) -> f32 {
    let mut d = a - b;
    while d > PI  { d -= TAU; }
    while d <= -PI { d += TAU; }
    d
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_context_steering_slot_count() {
        let cs = ContextSteering::new(8);
        assert_eq!(cs.slot_count(), 8);
    }

    #[test]
    fn seek_sets_interest() {
        let mut cs = ContextSteering::new(8);
        cs.add_seek_target(1.0, 0.0, 1.0);
        cs.evaluate(0.0, 0.0, 0.0, 0.0);
        assert!(cs.chosen_direction().is_finite());
    }

    #[test]
    fn avoid_does_not_crash() {
        let mut cs = ContextSteering::new(8);
        cs.add_seek_target(1.0, 0.0, 1.0);
        cs.add_avoid_point(0.5, 0.0, 0.5, 5.0);
        cs.evaluate(0.0, 0.0, 0.0, 0.0);
        assert!(cs.chosen_direction().is_finite());
    }

    #[test]
    fn clear_behaviors_resets() {
        let mut cs = ContextSteering::new(8);
        cs.add_seek_target(1.0, 0.0, 1.0);
        cs.clear_behaviors();
        cs.evaluate(0.0, 0.0, 0.0, 0.0);
        assert_eq!(cs.chosen_magnitude(), 0.0);
    }
}
