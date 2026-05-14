//! Multi-touch point state: active touches, per-frame start/end deltas, and pressure.
//! Owns the touch-point map and per-frame delta sets.
//! Does not own OS touch event delivery; the runtime event loop calls mutation methods each frame.
//! Consumed by `src/lua_api/input_api.rs`.

use std::collections::{HashMap, HashSet};

/// A single active touch contact point with its position and pressure.
#[derive(Debug, Clone, Copy)]
pub struct TouchPoint {
    /// OS-assigned touch identifier; unique per active contact.
    pub id: u64,
    /// Horizontal position in window pixels.
    pub x: f64,
    /// Vertical position in window pixels.
    pub y: f64,
    /// Contact pressure in [0.0, 1.0]; 0.0 when unsupported by the hardware.
    pub pressure: f64,
}

/// Per-frame state for all active touch contacts.
#[derive(Debug, Default)]
pub struct TouchState {
    /// Currently active touch contacts keyed by their OS-assigned id.
    touches: HashMap<u64, TouchPoint>,
    /// Touch ids that first contacted the screen this frame.
    touches_pressed: HashSet<u64>,
    /// Touch ids that lifted from the screen this frame.
    touches_released: HashSet<u64>,
}

/// Provide `Default` via the derive; `new` delegates to it.
impl TouchState {
    /// Create an empty touch state with no active contacts.
    pub fn new() -> Self {
        Self::default()
    }

    /// Clear per-frame delta sets; call at the start of each game frame.
    pub fn begin_frame(&mut self) {
        self.touches_pressed.clear();
        self.touches_released.clear();
    }

    /// Record a new touch contact at `(x, y)` with the given `pressure`; adds `id` to pressed delta.
    pub fn touch_start(&mut self, id: u64, x: f64, y: f64, pressure: f64) {
        self.touches_pressed.insert(id);
        self.touches.insert(id, TouchPoint { id, x, y, pressure });
    }

    /// Update position and pressure for an existing contact `id`; no-op when `id` is unknown.
    pub fn touch_move(&mut self, id: u64, x: f64, y: f64, pressure: f64) {
        if let Some(touch) = self.touches.get_mut(&id) {
            touch.x = x;
            touch.y = y;
            touch.pressure = pressure;
        }
    }

    /// Remove a contact `id` and add it to the released delta set.
    pub fn touch_end(&mut self, id: u64) {
        self.touches_released.insert(id);
        self.touches.remove(&id);
    }

    /// Return true when touch `id` first contacted the screen this frame.
    pub fn was_pressed(&self, id: u64) -> bool {
        self.touches_pressed.contains(&id)
    }

    /// Return true when touch `id` lifted from the screen this frame.
    pub fn was_released(&self, id: u64) -> bool {
        self.touches_released.contains(&id)
    }

    /// Return all currently active touch contacts as a `Vec`.
    pub fn get_touches(&self) -> Vec<TouchPoint> {
        self.touches.values().copied().collect()
    }

    /// Return the `TouchPoint` for `id`, or `None` when that contact is not active.
    pub fn get_touch(&self, id: u64) -> Option<TouchPoint> {
        self.touches.get(&id).copied()
    }

    /// Return the count of currently active touch contacts.
    pub fn get_touch_count(&self) -> usize {
        self.touches.len()
    }
}

