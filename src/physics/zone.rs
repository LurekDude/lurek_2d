use std::collections::{HashMap, HashSet};
pub type ZoneId = usize;
pub type ZonePriority = i32;
#[derive(Debug, Clone, PartialEq)]
pub enum ZoneGravityMode {
    Directional { gx: f32, gy: f32 },
    Point { cx: f32, cy: f32, strength: f32 },
    Repulsor { cx: f32, cy: f32, strength: f32 },
    Zero,
}
#[derive(Debug, Clone, PartialEq)]
pub enum ZoneBoundary {
    Rect {
        x: f32,
        y: f32,
        width: f32,
        height: f32,
    },
    Circle {
        cx: f32,
        cy: f32,
        radius: f32,
    },
}
impl ZoneBoundary {
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
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ZoneEventKind {
    Enter,
    Leave,
}
#[derive(Debug, Clone)]
pub struct ZoneEvent {
    pub zone_id: ZoneId,
    pub body_id: usize,
    pub kind: ZoneEventKind,
}
pub struct PhysicsZone {
    pub id: ZoneId,
    pub boundary: ZoneBoundary,
    pub gravity_mode: ZoneGravityMode,
    pub priority: ZonePriority,
    pub linear_damping_override: Option<f32>,
    pub angular_damping_override: Option<f32>,
    pub layer_mask: u32,
    pub enabled: bool,
}
impl PhysicsZone {
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
    pub fn set_circle(&mut self, cx: f32, cy: f32, radius: f32) {
        self.boundary = ZoneBoundary::Circle { cx, cy, radius };
    }
    pub fn set_gravity_directional(&mut self, gx: f32, gy: f32) {
        self.gravity_mode = ZoneGravityMode::Directional { gx, gy };
    }
    pub fn set_gravity_point(&mut self, cx: f32, cy: f32, strength: f32) {
        self.gravity_mode = ZoneGravityMode::Point { cx, cy, strength };
    }
    pub fn set_gravity_repulsor(&mut self, cx: f32, cy: f32, strength: f32) {
        self.gravity_mode = ZoneGravityMode::Repulsor { cx, cy, strength };
    }
    pub fn set_gravity_zero(&mut self) {
        self.gravity_mode = ZoneGravityMode::Zero;
    }
    pub fn contains(&self, px: f32, py: f32) -> bool {
        self.enabled && self.boundary.contains(px, py)
    }
}
pub struct ZoneTracker {
    body_zones: HashMap<usize, HashSet<ZoneId>>,
}
impl ZoneTracker {
    pub fn new() -> Self {
        Self {
            body_zones: HashMap::new(),
        }
    }
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
    pub fn remove_body(&mut self, body_id: usize) {
        self.body_zones.remove(&body_id);
    }
    pub fn clear(&mut self) {
        self.body_zones.clear();
    }
}
impl Default for ZoneTracker {
    fn default() -> Self {
        Self::new()
    }
}
