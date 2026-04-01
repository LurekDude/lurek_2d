//! Trail renderer for fading ribbon effects.
//!
//! Stores a series of timestamped points that age out over a configurable
//! lifetime, producing a tapered ribbon from head to tail.

use crate::graphics::Color;

/// A point in a trail with age tracking.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `age` — `f32`.
#[derive(Debug, Clone)]
pub struct TrailPoint {
    /// X position in world space.
    pub x: f32,
    /// Y position in world space.
    pub y: f32,
    /// How long this point has existed (seconds).
    pub age: f32,
}

/// Fading textured ribbon renderer.
///
/// # Fields
/// - `points` — `Vec<TrailPoint>`.
/// - `lifetime` — `f32`.
/// - `start_width` — `f32`.
/// - `end_width` — `f32`.
/// - `head_color` — `Color`.
/// - `tail_color` — `Color`.
/// - `min_distance` — `f32`.
///
/// Points are pushed at the head and automatically removed once their
/// age exceeds the configured lifetime. Width tapers linearly from
/// `start_width` at the head to `end_width` at the tail.
pub struct Trail {
    /// Ordered list of trail points (newest first).
    pub points: Vec<TrailPoint>,
    /// Maximum age (seconds) before a point is removed.
    pub lifetime: f32,
    /// Width of the ribbon at the head (newest point).
    pub start_width: f32,
    /// Width of the ribbon at the tail (oldest point).
    pub end_width: f32,
    /// Color at the head of the trail.
    pub head_color: Color,
    /// Color at the tail of the trail.
    pub tail_color: Color,
    /// Minimum distance a new point must be from the last point to be added.
    pub min_distance: f32,
}

impl Trail {
    /// Creates a new trail with the given lifetime and starting width.
    ///
    /// # Parameters
    /// - `lifetime` — `f32`.
    /// - `start_width` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Defaults: end_width = 0.0, colors = white, min_distance = 1.0.
    pub fn new(lifetime: f32, start_width: f32) -> Self {
        Self {
            points: Vec::new(),
            lifetime,
            start_width,
            end_width: 0.0,
            head_color: Color::WHITE,
            tail_color: Color::WHITE,
            min_distance: 1.0,
        }
    }

    /// Pushes a new point at the head of the trail.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    ///
    /// The point is only added if the distance from the last point is at
    /// least `min_distance`, or if the trail is empty.
    pub fn push_point(&mut self, x: f32, y: f32) {
        if let Some(last) = self.points.first() {
            let dx = x - last.x;
            let dy = y - last.y;
            if (dx * dx + dy * dy) < self.min_distance * self.min_distance {
                return;
            }
        }
        self.points.insert(0, TrailPoint { x, y, age: 0.0 });
    }

    /// Advances point ages by `dt` seconds and removes expired points.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update(&mut self, dt: f32) {
        for point in &mut self.points {
            point.age += dt;
        }
        self.points.retain(|p| p.age < self.lifetime);
    }

    /// Sets the ribbon width. If `end` is `None`, the tail width is unchanged.
    ///
    /// # Parameters
    /// - `start` — `f32`.
    /// - `end` — `Option<f32>`.
    pub fn set_width(&mut self, start: f32, end: Option<f32>) {
        self.start_width = start;
        if let Some(e) = end {
            self.end_width = e;
        }
    }

    /// Sets the maximum point lifetime in seconds.
    ///
    /// # Parameters
    /// - `lifetime` — `f32`.
    pub fn set_lifetime(&mut self, lifetime: f32) {
        self.lifetime = lifetime;
    }

    /// Returns the maximum point lifetime in seconds.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_lifetime(&self) -> f32 {
        self.lifetime
    }

    /// Sets the minimum distance a new point must be from the last one.
    ///
    /// # Parameters
    /// - `distance` — `f32`.
    pub fn set_min_distance(&mut self, distance: f32) {
        self.min_distance = distance;
    }

    /// Removes all trail points.
    pub fn clear(&mut self) {
        self.points.clear();
    }

    /// Returns the current number of trail points.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_point_count(&self) -> usize {
        self.points.len()
    }

    /// Returns the ribbon width as `(start_width, end_width)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_width(&self) -> (f32, f32) {
        (self.start_width, self.end_width)
    }

    /// Sets the color at the head (newest) end of the trail.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_head_color(&mut self, color: Color) {
        self.head_color = color;
    }

    /// Sets the color at the tail (oldest) end of the trail.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_tail_color(&mut self, color: Color) {
        self.tail_color = color;
    }
}
