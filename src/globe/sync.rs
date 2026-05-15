//! - Snapshot serialization of globe state for cross-thread transfer.
//! - Channel pair for sending and receiving globe snapshots.
//! - Build and apply helpers to capture or restore globe state.

use crate::globe::registry::Globe;
use crate::globe::types::ProvinceId;
use std::collections::HashMap;
use std::sync::mpsc::{channel, Receiver, Sender};
/// Serializable globe state used for snapshot transfer.
#[derive(Debug, Clone)]
pub struct GlobeSyncSnapshot {
    /// Globe name included in the snapshot.
    pub name: String,
    /// Camera latitude, longitude, and zoom.
    pub camera: (f32, f32, f32),
    /// Globe rotation in degrees.
    pub rotation_deg: f32,
    /// Time of day captured in the snapshot.
    pub time_of_day: f32,
    /// Province owner strings keyed by province id.
    pub owner_attrs: HashMap<ProvinceId, String>,
}
/// Channel pair used to send and receive globe snapshots.
#[derive(Debug)]
pub struct GlobeSyncChannel {
    /// Sender side of the snapshot channel.
    pub tx: Sender<GlobeSyncSnapshot>,
    /// Receiver side of the snapshot channel.
    pub rx: Receiver<GlobeSyncSnapshot>,
}
impl GlobeSyncChannel {
    /// Create a new snapshot channel pair.
    pub fn new() -> Self {
        let (tx, rx) = channel();
        Self { tx, rx }
    }
}
/// Create a default snapshot channel pair.
impl Default for GlobeSyncChannel {
    /// Delegate to `GlobeSyncChannel::new`.
    fn default() -> Self {
        Self::new()
    }
}
/// Build a snapshot from the current globe state.
pub fn build_snapshot(globe: &Globe) -> GlobeSyncSnapshot {
    let mut owner_attrs = HashMap::new();
    for p in globe.graph.iter() {
        if let Some(owner) = p.attrs.get("owner") {
            owner_attrs.insert(p.id, owner.clone());
        }
    }
    GlobeSyncSnapshot {
        name: globe.name.clone(),
        camera: (
            globe.camera.lat_deg,
            globe.camera.lon_deg,
            globe.camera.zoom,
        ),
        rotation_deg: globe.spec.rotation_deg,
        time_of_day: globe.spec.time_of_day,
        owner_attrs,
    }
}
/// Apply a snapshot to a mutable globe instance.
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
