//! Spring-physics simulation for smooth damped animation, used by `lurek.tween`.
//! Owns `SpringAxis` (single-axis spring) and `SpringSystem` (named multi-axis
//! container). Does not own easing or sequence logic. Consumed by tween bindings
//! and by `TweenEngine::active_springs`.

use std::collections::HashMap;

/// Single-axis spring simulation with configurable stiffness, damping, and settle precision.
#[derive(Debug, Clone)]
pub struct SpringAxis {
    /// Current animated position; updated each `update` call.
    pub position: f32,
    /// Current velocity in position units per second.
    pub velocity: f32,
    /// Target position the spring is converging toward.
    pub target: f32,
    /// Spring stiffness coefficient; higher values produce faster, stiffer motion.
    pub stiffness: f32,
    /// Damping coefficient; higher values reduce overshoot.
    pub damping: f32,
    /// Absolute distance threshold below which the spring is considered settled.
    pub precision: f32,
    /// True when both position error and velocity are within `precision`; update is skipped when true.
    pub settled: bool,
}

impl SpringAxis {
    /// Create a new spring axis; `settled` is set immediately if `|position - target| < precision`.
    pub fn new(position: f32, target: f32, stiffness: f32, damping: f32, precision: f32) -> Self {
        let settled = (position - target).abs() < precision;
        Self {
            position,
            velocity: 0.0,
            target,
            stiffness,
            damping,
            precision,
            settled,
        }
    }

    /// Advance the spring by `dt` seconds; snap to target and zero velocity when settled.
    pub fn update(&mut self, dt: f32) {
        if self.settled {
            return;
        }
        self.velocity += (self.target - self.position) * self.stiffness * dt;
        self.velocity *= 1.0 - self.damping * dt;
        self.position += self.velocity * dt;
        self.settled = (self.position - self.target).abs() < self.precision
            && self.velocity.abs() < self.precision;
        if self.settled {
            self.position = self.target;
            self.velocity = 0.0;
        }
    }

    /// Return true if the spring has settled within `precision` of its target.
    pub fn is_settled(&self) -> bool {
        self.settled
    }

    /// Teleport the spring to `position`, set a new `target`, and clear velocity.
    pub fn reset(&mut self, position: f32, target: f32) {
        self.position = position;
        self.target = target;
        self.velocity = 0.0;
        self.settled = (position - target).abs() < self.precision;
    }

    /// Update the target and mark the spring as unsettled so simulation resumes.
    pub fn set_target(&mut self, target: f32) {
        self.target = target;
        self.settled = false;
    }
}

/// Named collection of `SpringAxis` instances sharing default stiffness, damping, and precision.
#[derive(Debug, Clone)]
pub struct SpringSystem {
    /// Map of axis name to its `SpringAxis` state.
    pub axes: HashMap<String, SpringAxis>,
    /// Default stiffness applied when adding a new axis.
    pub stiffness: f32,
    /// Default damping applied when adding a new axis.
    pub damping: f32,
    /// Default precision applied when adding a new axis.
    pub precision: f32,
}

impl SpringSystem {
    /// Create a new spring system with the given default parameters and no axes.
    pub fn new(stiffness: f32, damping: f32, precision: f32) -> Self {
        Self {
            axes: HashMap::new(),
            stiffness,
            damping,
            precision,
        }
    }

    /// Add a named axis with `position` and `target`, using the system's default spring parameters.
    pub fn add_axis(&mut self, key: String, position: f32, target: f32) {
        self.axes.insert(
            key,
            SpringAxis::new(
                position,
                target,
                self.stiffness,
                self.damping,
                self.precision,
            ),
        );
    }

    /// Advance all axes by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        for axis in self.axes.values_mut() {
            axis.update(dt);
        }
    }

    /// Return true if every axis in the system has settled.
    pub fn is_settled(&self) -> bool {
        self.axes.values().all(|a| a.is_settled())
    }

    /// Set the target for the axis named `key`; no-op if the key does not exist.
    pub fn set_target(&mut self, key: &str, target: f32) {
        if let Some(axis) = self.axes.get_mut(key) {
            axis.set_target(target);
        }
    }

    /// Return the current position of the axis named `key`, or `None` if not found.
    pub fn get_position(&self, key: &str) -> Option<f32> {
        self.axes.get(key).map(|a| a.position)
    }
}
