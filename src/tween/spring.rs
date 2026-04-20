//! Physics-based spring interpolation for the `lurek.tween` system.
//!
//! # Purpose
//!
//! Provides [`SpringAxis`] and [`SpringSystem`] for spring-driven value animation.
//! Springs simulate a damped harmonic oscillator, producing organic overshoot and
//! oscillation behaviour that no fixed-duration easing curve can replicate.
//!
//! # Differential equations (per frame)
//!
//! ```text
//! velocity += (target - position) * stiffness * dt
//! velocity *= 1 - damping * dt
//! position += velocity * dt
//! ```
//!
//! # Architecture note
//!
//! This module is **pure Rust** — no Lua or mlua dependencies. The Lua binding
//! lives in `src/lua_api/tween_api.rs` per the Thin Wrapper Rule.

use std::collections::HashMap;

// ─── SpringAxis ──────────────────────────────────────────────────────────────

/// Single-axis spring simulation driven by a damped differential equation.
///
/// Each call to [`update`](SpringAxis::update) advances the equation one timestep.
/// The axis is marked as [`settled`](SpringAxis::settled) when both
/// `|position - target| < precision` and `|velocity| < precision`.
///
/// # Fields
/// - `position` — Current interpolated value.
/// - `velocity` — Current velocity.
/// - `target` — Goal value the spring moves toward.
/// - `stiffness` — Spring force constant; higher = snappier response.
/// - `damping` — Velocity damping; critically damped ≈ `2 * sqrt(stiffness)`.
/// - `precision` — Convergence threshold for both position error and velocity.
/// - `settled` — `true` when both error and velocity are below `precision`.
#[derive(Debug, Clone)]
pub struct SpringAxis {
    /// Current interpolated position.
    pub position: f32,
    /// Current velocity.
    pub velocity: f32,
    /// Target the spring converges toward.
    pub target: f32,
    /// Spring force constant.
    pub stiffness: f32,
    /// Velocity damping coefficient.
    pub damping: f32,
    /// Precision threshold for declaring settlement.
    pub precision: f32,
    /// Whether the axis has settled within `precision` of the target.
    pub settled: bool,
}

impl SpringAxis {
    /// Creates a `SpringAxis` with the given initial position and target.
    ///
    /// The axis is immediately marked settled if the initial distance is already
    /// within `precision`.
    ///
    /// # Parameters
    /// - `position` — `f32` — Starting value.
    /// - `target` — `f32` — Goal value.
    /// - `stiffness` — `f32` — Spring force constant.
    /// - `damping` — `f32` — Damping coefficient.
    /// - `precision` — `f32` — Convergence threshold.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(position: f32, target: f32, stiffness: f32, damping: f32, precision: f32) -> Self {
        let settled = (position - target).abs() < precision;
        Self { position, velocity: 0.0, target, stiffness, damping, precision, settled }
    }

    /// Advances the spring simulation by `dt` seconds.
    ///
    /// No-op when already settled.
    ///
    /// # Parameters
    /// - `dt` — `f32` — Delta-time in seconds.
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

    /// Returns `true` when the axis has settled within `precision` of the target.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_settled(&self) -> bool {
        self.settled
    }

    /// Teleports to a new position and target, clearing velocity and the settled flag.
    ///
    /// # Parameters
    /// - `position` — `f32` — New starting value.
    /// - `target` — `f32` — New goal value.
    pub fn reset(&mut self, position: f32, target: f32) {
        self.position = position;
        self.target = target;
        self.velocity = 0.0;
        self.settled = (position - target).abs() < self.precision;
    }

    /// Updates the target without resetting velocity or position.
    ///
    /// Clears the settled flag so the spring responds to the new target.
    ///
    /// # Parameters
    /// - `target` — `f32` — New goal value.
    pub fn set_target(&mut self, target: f32) {
        self.target = target;
        self.settled = false;
    }
}

// ─── SpringSystem ────────────────────────────────────────────────────────────

/// Named collection of [`SpringAxis`] values that all share the same parameters.
///
/// `SpringSystem` drives multiple fields simultaneously (e.g. `x`, `y`, `opacity`)
/// with a single set of `stiffness`, `damping`, and `precision` values.
///
/// # Fields
/// - `axes` — Named spring axes; key = field name.
/// - `stiffness` — Shared spring constant applied to every axis.
/// - `damping` — Shared damping coefficient.
/// - `precision` — Shared convergence threshold.
#[derive(Debug, Clone)]
pub struct SpringSystem {
    /// Named spring axes.
    pub axes: HashMap<String, SpringAxis>,
    /// Spring force constant used when creating new axes.
    pub stiffness: f32,
    /// Damping coefficient used when creating new axes.
    pub damping: f32,
    /// Convergence threshold used when creating new axes.
    pub precision: f32,
}

impl SpringSystem {
    /// Creates an empty `SpringSystem` with the given parameters.
    ///
    /// Add axes after construction with [`add_axis`](SpringSystem::add_axis).
    ///
    /// # Parameters
    /// - `stiffness` — `f32`.
    /// - `damping` — `f32`.
    /// - `precision` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(stiffness: f32, damping: f32, precision: f32) -> Self {
        Self { axes: HashMap::new(), stiffness, damping, precision }
    }

    /// Adds a named axis with the given starting position and target.
    ///
    /// Overwrites any existing axis with the same key.
    ///
    /// # Parameters
    /// - `key` — `String` — Field name.
    /// - `position` — `f32` — Starting value.
    /// - `target` — `f32` — Goal value.
    pub fn add_axis(&mut self, key: String, position: f32, target: f32) {
        self.axes.insert(
            key,
            SpringAxis::new(position, target, self.stiffness, self.damping, self.precision),
        );
    }

    /// Advances all axes by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32` — Delta-time in seconds.
    pub fn update(&mut self, dt: f32) {
        for axis in self.axes.values_mut() {
            axis.update(dt);
        }
    }

    /// Returns `true` when every axis has settled.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_settled(&self) -> bool {
        self.axes.values().all(|a| a.is_settled())
    }

    /// Sets the target for a named axis without resetting velocity.
    ///
    /// No-op when the key does not exist.
    ///
    /// # Parameters
    /// - `key` — `&str` — Axis name.
    /// - `target` — `f32` — New goal value.
    pub fn set_target(&mut self, key: &str, target: f32) {
        if let Some(axis) = self.axes.get_mut(key) {
            axis.set_target(target);
        }
    }

    /// Returns the current position of a named axis, or `None` if not found.
    ///
    /// # Parameters
    /// - `key` — `&str` — Axis name.
    ///
    /// # Returns
    /// `Option<f32>`.
    pub fn get_position(&self, key: &str) -> Option<f32> {
        self.axes.get(key).map(|a| a.position)
    }
}
