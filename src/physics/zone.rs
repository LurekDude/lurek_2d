//! Physics zone system: gravity areas, attractor/repulsor regions, and zero-gravity pockets.
//!
//! A [`PhysicsZone`] defines a spatial region in which the per-body gravity is
//! overridden before each rapier pipeline step.  Unlike rigid bodies, zones have
//! no mass and are never simulated — they are pure metadata queried during
//! [`World::step`](super::world::World::step).
//!
//! # Architecture
//! - [`PhysicsZone`] is allocated inside [`World.zones`](super::world::World) and
//!   addressed by a stable [`ZoneId`] (monotonically increasing `usize`).
//! - Every call to `World::apply_zone_forces` iterates all enabled zones sorted by
//!   descending [`ZonePriority`].  The first zone that covers a body wins for
//!   gravity override; all matching zones contribute damping overrides cumulatively.
//! - [`ZoneEvent`]s are recorded during the same pass and made available via
//!   `World::get_zone_events`.
//!
//! # Typical usage sequence
//! 1. Call `World::add_zone(...)` to create a zone and obtain its `ZoneId`.
//! 2. Configure the zone via `World::zone_mut(id)`.
//! 3. `World::step(dt)` calls `apply_zone_forces` internally — no manual call needed.
//! 4. After each step, collect `World::get_zone_events()` for enter/leave handling.

use std::collections::{HashMap, HashSet};

// ── ZoneId ────────────────────────────────────────────────────────────────────

/// Stable integer handle for a [`PhysicsZone`].
///
/// Created by [`World::add_zone`](super::world::World::add_zone) and valid until
/// [`World::remove_zone`](super::world::World::remove_zone) is called with the same
/// value.
pub type ZoneId = usize;

// ── ZonePriority ─────────────────────────────────────────────────────────────

/// Ordering value used when multiple zones overlap the same body.
///
/// Higher numeric values take precedence.  The default value is `0`.
/// When two zones share the same priority the one with the lower [`ZoneId`]
/// (earlier creation) is preferred — i.e. insertion order acts as a
/// tie-breaker.
pub type ZonePriority = i32;

// ── ZoneGravityMode ───────────────────────────────────────────────────────────

/// Describes how a [`PhysicsZone`] overrides world gravity for bodies inside it.
///
/// # Variants
/// - `Directional` — Replaces body gravity with a constant vector `(gx, gy)`.
/// - `Point` — Attracts bodies toward a centre point with force proportional to
///   `strength / distance²`.  Clamped to a minimum distance of `1.0` to prevent
///   division by zero.
/// - `Repulsor` — Pushes bodies away from a centre point with the same formula
///   as `Point`.
/// - `Zero` — Sets effective gravity to zero inside the zone (gravity_scale = 0).
#[derive(Debug, Clone, PartialEq)]
pub enum ZoneGravityMode {
    /// Constant gravity vector that replaces world gravity inside the zone.
    ///
    /// # Fields
    /// - `gx` — Horizontal gravity component (pixels/s²).
    /// - `gy` — Vertical gravity component (positive = downward).
    Directional {
        /// Horizontal gravity component (pixels/s²).
        gx: f32,
        /// Vertical gravity component (positive = downward).
        gy: f32,
    },
    /// Point attractor: bodies are pulled toward `(cx, cy)` with strength `F = k / r²`.
    ///
    /// # Fields
    /// - `cx` — Centre X (world pixels).
    /// - `cy` — Centre Y (world pixels).
    /// - `strength` — Force constant `k`.  Larger values → stronger attraction.
    Point {
        /// Centre X (world pixels).
        cx: f32,
        /// Centre Y (world pixels).
        cy: f32,
        /// Force constant `k`.
        strength: f32,
    },
    /// Point repulsor: bodies are pushed away from `(cx, cy)` with `F = k / r²`.
    ///
    /// # Fields
    /// - `cx` — Centre X (world pixels).
    /// - `cy` — Centre Y (world pixels).
    /// - `strength` — Force constant `k`.
    Repulsor {
        /// Centre X (world pixels).
        cx: f32,
        /// Centre Y (world pixels).
        cy: f32,
        /// Force constant `k`.
        strength: f32,
    },
    /// Zero-gravity pocket: effective gravity is suppressed while a body is inside.
    Zero,
}

// ── ZoneBoundary ─────────────────────────────────────────────────────────────

/// Spatial boundary of a [`PhysicsZone`].
///
/// The default boundary is an axis-aligned rectangle.  Calling
/// [`PhysicsZone::set_circle`] replaces it with a circle.
///
/// # Variants
/// - `Rect` — Axis-aligned bounding box.
/// - `Circle` — Circle centred at `(cx, cy)`.
#[derive(Debug, Clone, PartialEq)]
pub enum ZoneBoundary {
    /// Axis-aligned bounding box.
    ///
    /// # Fields
    /// - `x`, `y` — Top-left corner (world pixels).
    /// - `width`, `height` — Dimensions in world pixels.
    Rect {
        /// Left edge (world pixels).
        x: f32,
        /// Top edge (world pixels).
        y: f32,
        /// Width (world pixels).
        width: f32,
        /// Height (world pixels).
        height: f32,
    },
    /// Circle boundary.
    ///
    /// # Fields
    /// - `cx`, `cy` — Centre (world pixels).
    /// - `radius` — Radius in world pixels.
    Circle {
        /// Centre X (world pixels).
        cx: f32,
        /// Centre Y (world pixels).
        cy: f32,
        /// Radius (world pixels).
        radius: f32,
    },
}

impl ZoneBoundary {
    /// Returns `true` when `(px, py)` lies inside this boundary.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// # Parameters
    /// - `px` — Point X (world pixels).
    /// - `py` — Point Y (world pixels).
    pub fn contains(&self, px: f32, py: f32) -> bool {
        match *self {
            ZoneBoundary::Rect {
                x,
                y,
                width,
                height,
            } => px >= x && px <= x + width && py >= y && py <= y + height,
            ZoneBoundary::Circle { cx, cy, radius } => {
                let dx = px - cx;
                let dy = py - cy;
                dx * dx + dy * dy <= radius * radius
            }
        }
    }
}

// ── ZoneEventKind ─────────────────────────────────────────────────────────────

/// Direction of a body-zone transition.
///
/// # Variants
/// - `Enter` — Body has moved into the zone since the last step.
/// - `Leave` — Body has moved out of the zone since the last step.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ZoneEventKind {
    /// Body has moved into the zone since the last step.
    Enter,
    /// Body has moved out of the zone since the last step.
    Leave,
}

// ── ZoneEvent ─────────────────────────────────────────────────────────────────

/// Records a body entering or leaving a [`PhysicsZone`] during a [`World::step`](super::world::World::step).
///
/// Available via [`World::get_zone_events`](super::world::World::get_zone_events)
/// immediately after each step.
///
/// # Fields
/// - `zone_id` — The zone that was entered/left.
/// - `body_id` — The body that transitioned.
/// - `kind` — Whether this is an enter or leave event.
#[derive(Debug, Clone)]
pub struct ZoneEvent {
    /// The zone that was entered or left.
    pub zone_id: ZoneId,
    /// The body that transitioned.
    pub body_id: usize,
    /// Whether the body entered or left the zone.
    pub kind: ZoneEventKind,
}

// ── PhysicsZone ───────────────────────────────────────────────────────────────

/// A spatial region that overrides gravity and damping for bodies inside it.
///
/// Zones are not simulated objects — they are metadata applied by
/// [`World::apply_zone_forces`](super::world::World::apply_zone_forces) before each
/// rapier pipeline step.
///
/// # Ownership
/// Zones are stored inside [`World.zones`](super::world::World) indexed by
/// [`ZoneId`].  A zone with `enabled = false` is skipped during the force-application
/// pass but retains its slot and configuration.
///
/// # Fields
/// - `id` — Stable identity assigned at creation.
/// - `boundary` — Spatial extent (AABB or circle).
/// - `gravity_mode` — How gravity is overridden inside this zone.
/// - `priority` — Ordering value; highest priority zone wins per body.
/// - `linear_damping_override` — Optional per-body linear damping inside zone.
/// - `angular_damping_override` — Optional per-body angular damping inside zone.
/// - `layer_mask` — Bitmask filter; only bodies whose `layer & mask != 0` are affected.
/// - `enabled` — When `false` the zone is skipped entirely.
pub struct PhysicsZone {
    /// Stable handle assigned at creation; must not be changed after insertion.
    pub id: ZoneId,
    /// Spatial extent of the zone.
    pub boundary: ZoneBoundary,
    /// Gravity override mode applied to bodies inside this zone.
    pub gravity_mode: ZoneGravityMode,
    /// Ordering value; highest priority zone wins per body for gravity override.
    pub priority: ZonePriority,
    /// If `Some(v)`, overrides linear damping for matching bodies while inside.
    pub linear_damping_override: Option<f32>,
    /// If `Some(v)`, overrides angular damping for matching bodies while inside.
    pub angular_damping_override: Option<f32>,
    /// Bitmask applied against `body.layer`: only bodies where `body.layer & layer_mask != 0`
    /// are affected.  Use `0xFF_FF_FF_FF` to affect all bodies.
    pub layer_mask: u32,
    /// When `false` the zone is bypassed during `apply_zone_forces`.
    pub enabled: bool,
}

impl PhysicsZone {
    /// Creates a new rectangular zone with zero-gravity mode, affecting all layers.
    ///
    /// # Parameters
    /// - `id` — Stable zone handle.
    /// - `x` — Left edge (world pixels).
    /// - `y` — Top edge (world pixels).
    /// - `width` — Width (world pixels).
    /// - `height` — Height (world pixels).
    ///
    /// # Returns
    /// A fully initialised `PhysicsZone` with `enabled = true`, `priority = 0`,
    /// `gravity_mode = ZoneGravityMode::Zero`, and `layer_mask = 0xFFFF_FFFF`.
    pub fn new_rect(id: ZoneId, x: f32, y: f32, width: f32, height: f32) -> Self {
        Self {
            id,
            boundary: ZoneBoundary::Rect {
                x,
                y,
                width,
                height,
            },
            gravity_mode: ZoneGravityMode::Zero,
            priority: 0,
            linear_damping_override: None,
            angular_damping_override: None,
            layer_mask: 0xFFFF_FFFF,
            enabled: true,
        }
    }

    /// Replaces the zone boundary with a circle.
    ///
    /// # Parameters
    /// - `cx` — Centre X (world pixels).
    /// - `cy` — Centre Y (world pixels).
    /// - `radius` — Radius (world pixels).
    pub fn set_circle(&mut self, cx: f32, cy: f32, radius: f32) {
        self.boundary = ZoneBoundary::Circle { cx, cy, radius };
    }

    /// Sets directional gravity inside the zone.
    ///
    /// Bodies inside the zone experience `(gx, gy)` as their effective gravity,
    /// ignoring the world gravity vector.
    ///
    /// # Parameters
    /// - `gx` — Horizontal gravity (pixels/s²).
    /// - `gy` — Vertical gravity (pixels/s²; positive = downward).
    pub fn set_gravity_directional(&mut self, gx: f32, gy: f32) {
        self.gravity_mode = ZoneGravityMode::Directional { gx, gy };
    }

    /// Sets point-attractor gravity inside the zone.
    ///
    /// Each body is accelerated toward `(cx, cy)` with magnitude `strength / r²`.
    ///
    /// # Parameters
    /// - `cx` — Attractor centre X (world pixels).
    /// - `cy` — Attractor centre Y (world pixels).
    /// - `strength` — Force constant.
    pub fn set_gravity_point(&mut self, cx: f32, cy: f32, strength: f32) {
        self.gravity_mode = ZoneGravityMode::Point { cx, cy, strength };
    }

    /// Sets point-repulsor gravity inside the zone.
    ///
    /// Each body is pushed away from `(cx, cy)` with magnitude `strength / r²`.
    ///
    /// # Parameters
    /// - `cx` — Repulsor centre X (world pixels).
    /// - `cy` — Repulsor centre Y (world pixels).
    /// - `strength` — Force constant.
    pub fn set_gravity_repulsor(&mut self, cx: f32, cy: f32, strength: f32) {
        self.gravity_mode = ZoneGravityMode::Repulsor { cx, cy, strength };
    }

    /// Sets the zone to suppress gravity (zero-gravity pocket).
    ///
    /// Bodies inside this zone are not accelerated by either the world gravity or any
    /// directional/point mode.
    pub fn set_gravity_zero(&mut self) {
        self.gravity_mode = ZoneGravityMode::Zero;
    }

    /// Returns `true` when position `(px, py)` lies inside the zone boundary.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// # Parameters
    /// - `px` — Query X (world pixels).
    /// - `py` — Query Y (world pixels).
    pub fn contains(&self, px: f32, py: f32) -> bool {
        self.enabled && self.boundary.contains(px, py)
    }
}

// ── ZoneTracker ───────────────────────────────────────────────────────────────

/// Tracks which zones each body is currently inside and produces [`ZoneEvent`]s
/// when the membership changes.
///
/// This is a pure change-detection structure with no rapier coupling.  The
/// [`World`](super::world::World) holds one instance and calls
/// [`ZoneTracker::update`] after computing the current coverage set.
///
/// # Fields
/// - `body_zones` — Live membership map from `body_id` to the set of
///   `ZoneId`s the body currently occupies.
pub struct ZoneTracker {
    /// Maps each body index to the set of zone IDs it is currently inside.
    body_zones: HashMap<usize, HashSet<ZoneId>>,
}

impl ZoneTracker {
    /// Creates an empty tracker.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            body_zones: HashMap::new(),
        }
    }

    /// Updates membership for `body_id` and returns any enter/leave events.
    ///
    /// Compares `new_zones` against the previously recorded set for this body and
    /// generates one [`ZoneEvent`] per changed zone.
    ///
    /// # Parameters
    /// - `body_id` — The body being updated.
    /// - `new_zones` — The complete set of zones the body is currently inside.
    ///
    /// # Returns
    /// A `Vec<ZoneEvent>` of enter/leave transitions that occurred since the last
    /// call for this body.
    pub fn update(&mut self, body_id: usize, new_zones: HashSet<ZoneId>) -> Vec<ZoneEvent> {
        let old = self.body_zones.entry(body_id).or_default();
        let mut events = Vec::new();

        for &zid in &new_zones {
            if !old.contains(&zid) {
                events.push(ZoneEvent {
                    zone_id: zid,
                    body_id,
                    kind: ZoneEventKind::Enter,
                });
            }
        }
        for &zid in old.iter() {
            if !new_zones.contains(&zid) {
                events.push(ZoneEvent {
                    zone_id: zid,
                    body_id,
                    kind: ZoneEventKind::Leave,
                });
            }
        }

        *old = new_zones;
        events
    }

    /// Removes all tracking state for a body.  Call when a body is destroyed.
    ///
    /// # Parameters
    /// - `body_id` — Body index to evict from the tracker.
    pub fn remove_body(&mut self, body_id: usize) {
        self.body_zones.remove(&body_id);
    }

    /// Purges all tracking state.  Call when the world is cleared.
    pub fn clear(&mut self) {
        self.body_zones.clear();
    }
}

impl Default for ZoneTracker {
    fn default() -> Self {
        Self::new()
    }
}
