//! Channel-based globe state synchronization for multi-VM or network relays.

use crate::globe::registry::Globe;
use crate::globe::types::ProvinceId;
use std::collections::HashMap;
use std::sync::mpsc::{channel, Receiver, Sender};

/// Compact snapshot message for one globe.
#[derive(Debug, Clone)]
pub struct GlobeSyncSnapshot {
    /// Globe name.
    pub name: String,
    /// Camera tuple `(lat, lon, zoom)`.
    pub camera: (f32, f32, f32),
    /// Rotation in degrees.
    pub rotation_deg: f32,
    /// Time of day in hours.
    pub time_of_day: f32,
    /// Province ownership-style attrs for cheap sync.
    pub owner_attrs: HashMap<ProvinceId, String>,
}

/// Sender/receiver pair used by producer and consumer runtimes.
#[derive(Debug)]
pub struct GlobeSyncChannel {
    /// Sending endpoint.
    pub tx: Sender<GlobeSyncSnapshot>,
    /// Receiving endpoint.
    pub rx: Receiver<GlobeSyncSnapshot>,
}

impl GlobeSyncChannel {
    /// Create a new in-process sync channel.
    pub fn new() -> Self {
        let (tx, rx) = channel();
        Self { tx, rx }
    }
}

impl Default for GlobeSyncChannel {
    fn default() -> Self {
        Self::new()
    }
}

/// Build a sync snapshot from a globe.
pub fn build_snapshot(globe: &Globe) -> GlobeSyncSnapshot {
    let mut owner_attrs = HashMap::new();
    for p in globe.graph.iter() {
        if let Some(owner) = p.attrs.get("owner") {
            owner_attrs.insert(p.id, owner.clone());
        }
    }
    GlobeSyncSnapshot {
        name: globe.name.clone(),
        camera: (globe.camera.lat_deg, globe.camera.lon_deg, globe.camera.zoom),
        rotation_deg: globe.spec.rotation_deg,
        time_of_day: globe.spec.time_of_day,
        owner_attrs,
    }
}

/// Apply a sync snapshot onto an existing globe.
pub fn apply_snapshot(globe: &mut Globe, snap: &GlobeSyncSnapshot) {
    globe.camera.lat_deg = snap.camera.0;
    globe.camera.lon_deg = snap.camera.1;
    globe.camera.zoom = snap.camera.2;
    globe.camera.clamp();
    globe.spec.rotation_deg = snap.rotation_deg;
    globe.spec.time_of_day = snap.time_of_day;
    for (id, owner) in &snap.owner_attrs {
        if let Some(p) = globe.get_province_mut(*id) {
            p.attrs.insert("owner".to_string(), owner.clone());
        }
    }
}
