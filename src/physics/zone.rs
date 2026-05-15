//! - Spatial trigger zones with boundary containment (rect or circle).
//! - Gravity overrides per zone: directional, point-attractor, repulsor, or zero-g.
//! - Priority-based zone layering with bitmask filtering.
//! - Damping overrides (linear and angular) for bodies inside a zone.
//! - Enter/leave event tracking via diffing per-body zone sets each step.

use std::collections::{HashMap, HashSet};

/// Alias for a zone's numeric identifier.
pub type ZoneId = usize;
/// Alias for zone processing priority (higher wins).
pub type ZonePriority = i32;

/// Gravity behaviour applied to bodies inside the zone.
#[derive(Debug, Clone, PartialEq)]
pub enum ZoneGravityMode {
    /// Constant directional gravity `(gx, gy)`.
    Directional { gx: f32, gy: f32 },
    /// Gravity pulls toward point `(cx, cy)` with given `strength`.
    Point { cx: f32, cy: f32, strength: f32 },
    /// Gravity pushes away from point `(cx, cy)` with given `strength`.
    Repulsor { cx: f32, cy: f32, strength: f32 },
    /// Zero gravity — bodies float freely.
    Zero,
}
/// Spatial boundary shape for a zone.
#[derive(Debug, Clone, PartialEq)]
pub enum ZoneBoundary {
    /// Axis-aligned rectangle with top-left `(x, y)` and size.
    Rect {
        /// Left edge x.
        x: f32,
        /// Top edge y.
        y: f32,
        /// Rectangle width.
        width: f32,
        /// Rectangle height.
        height: f32,
    },
    /// Circle centred at `(cx, cy)` with given `radius`.
    Circle {
        /// Centre x.
        cx: f32,
        /// Centre y.
        cy: f32,
        /// Circle radius.
        radius: f32,
    },
}
/// `ZoneBoundary` containment test.
impl ZoneBoundary {
    /// Return true if point `(px, py)` is inside this boundary.
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
/// Zone enter/exit event discriminant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ZoneEventKind {
    /// A body entered the zone.
    Enter,
    /// A body left the zone.
    Leave,
}
/// A zone crossing event emitted by `ZoneTracker::update`.
#[derive(Debug, Clone)]
pub struct ZoneEvent {
    /// Id of the zone that was crossed.
    pub zone_id: ZoneId,
    /// Body id that crossed the boundary.
    pub body_id: usize,
    /// Whether the body entered or left.
    pub kind: ZoneEventKind,
}
/// A trigger zone that applies gravity and damping overrides to bodies inside it.
pub struct PhysicsZone {
    /// Unique numeric id assigned by `World`.
    pub id: ZoneId,
    /// Spatial boundary for containment tests.
    pub boundary: ZoneBoundary,
    /// Gravity behaviour inside this zone.
    pub gravity_mode: ZoneGravityMode,
    /// Processing priority; higher priority zones override lower ones.
    pub priority: ZonePriority,
    /// Optional linear damping override applied while inside.
    pub linear_damping_override: Option<f32>,
    /// Optional angular damping override applied while inside.
    pub angular_damping_override: Option<f32>,
    /// Bitmask: only bodies whose `layer & layer_mask != 0` are affected.
    pub layer_mask: u32,
    /// When false the zone is skipped entirely.
    pub enabled: bool,
}
/// `PhysicsZone` constructors and mutators.
impl PhysicsZone {
    /// Create a rectangular zone with zero gravity and default layer mask.
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
    /// Replace the boundary with a circle centred at `(cx, cy)` with given `radius`.
    pub fn set_circle(&mut self, cx: f32, cy: f32, radius: f32) {
        self.boundary = ZoneBoundary::Circle { cx, cy, radius };
    }
    /// Set constant directional gravity `(gx, gy)` for this zone.
    pub fn set_gravity_directional(&mut self, gx: f32, gy: f32) {
        self.gravity_mode = ZoneGravityMode::Directional { gx, gy };
    }
    /// Set point-attractor gravity centred at `(cx, cy)` with given `strength`.
    pub fn set_gravity_point(&mut self, cx: f32, cy: f32, strength: f32) {
        self.gravity_mode = ZoneGravityMode::Point { cx, cy, strength };
    }
    /// Set repulsor gravity pushing away from `(cx, cy)` with given `strength`.
    pub fn set_gravity_repulsor(&mut self, cx: f32, cy: f32, strength: f32) {
        self.gravity_mode = ZoneGravityMode::Repulsor { cx, cy, strength };
    }
    /// Set zero gravity for this zone.
    pub fn set_gravity_zero(&mut self) {
        self.gravity_mode = ZoneGravityMode::Zero;
    }
    /// Return true if the zone is enabled and the point `(px, py)` is inside its boundary.
    pub fn contains(&self, px: f32, py: f32) -> bool {
        self.enabled && self.boundary.contains(px, py)
    }
}
/// Tracks which bodies are inside which zones to generate enter/exit events.
pub struct ZoneTracker {
    /// Per-body set of zone ids currently containing that body.
    body_zones: HashMap<usize, HashSet<ZoneId>>,
}
/// `ZoneTracker` construction and per-step update.
impl ZoneTracker {
    /// Create an empty tracker. This function is part of the public API.
    pub fn new() -> Self {
        Self {
            body_zones: HashMap::new(),
        }
    }
    /// Diff `new_zones` against stored state for `body_id`; emit enter/leave events and update.
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
    /// Remove all zone tracking state for `body_id`.
    pub fn remove_body(&mut self, body_id: usize) {
        self.body_zones.remove(&body_id);
    }
    /// Clear all per-body zone state.
    pub fn clear(&mut self) {
        self.body_zones.clear();
    }
}
/// Delegates to `ZoneTracker::new`.
impl Default for ZoneTracker {
    /// Delegate to `ZoneTracker::new`.
    fn default() -> Self {
        Self::new()
    }
}
