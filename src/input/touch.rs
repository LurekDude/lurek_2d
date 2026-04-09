//! Touch input state tracking for Lurek2D.
//!
//! This module is part of Lurek2D's `input` subsystem and provides the implementation
//! details for touch-related operations and data management.
//! Key types exported from this module: `TouchPoint`, `TouchState`.
//! Primary functions: `new()`, `touch_start()`, `touch_move()`, `touch_end()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::HashMap;

/// Information about a single touch point. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `id` — `u64`.
/// - `x` — `f64`.
/// - `y` — `f64`.
/// - `pressure` — `f64`.
#[derive(Debug, Clone, Copy)]
pub struct TouchPoint {
    /// Unique ID of this touch.
    pub id: u64,
    /// X position in window coordinates.
    pub x: f64,
    /// Y position in window coordinates.
    pub y: f64,
    /// Pressure (0.0 to 1.0, if available).
    pub pressure: f64,
}

/// Tracks active touch points. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `touches` — `HashMap<u64`.
#[derive(Debug, Default)]
pub struct TouchState {
    /// Currently active touch points, keyed by touch ID.
    touches: HashMap<u64, TouchPoint>,
}

impl TouchState {
    /// Creates a new empty touch state. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Registers or updates a touch point. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `x` — `f64`.
    /// - `y` — `f64`.
    /// - `pressure` — `f64`.
    pub fn touch_start(&mut self, id: u64, x: f64, y: f64, pressure: f64) {
        self.touches.insert(id, TouchPoint { id, x, y, pressure });
    }

    /// Updates the position of an existing touch point.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `x` — `f64`.
    /// - `y` — `f64`.
    /// - `pressure` — `f64`.
    pub fn touch_move(&mut self, id: u64, x: f64, y: f64, pressure: f64) {
        if let Some(touch) = self.touches.get_mut(&id) {
            touch.x = x;
            touch.y = y;
            touch.pressure = pressure;
        }
    }

    /// Removes a touch point. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    pub fn touch_end(&mut self, id: u64) {
        self.touches.remove(&id);
    }

    /// Returns all active touch points. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<TouchPoint>`.
    pub fn get_touches(&self) -> Vec<TouchPoint> {
        self.touches.values().copied().collect()
    }

    /// Returns a specific touch point by ID. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `Option<TouchPoint>`.
    pub fn get_touch(&self, id: u64) -> Option<TouchPoint> {
        self.touches.get(&id).copied()
    }

    /// Returns the number of active touches. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_touch_count(&self) -> usize {
        self.touches.len()
    }
}
