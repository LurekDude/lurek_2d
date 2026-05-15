//! - Stable-id marker collection for globe pin management.
//! - Insert, remove, move, and query markers by id or type.
//! - Per-marker visibility toggle and arbitrary string attributes.

use crate::globe::types::{Marker, MarkerStyle};
use std::collections::HashMap;
/// Marker collection keyed by stable id.
#[derive(Debug, Clone, Default)]
pub struct MarkerStore {
    /// Stored markers by id.
    markers: HashMap<u32, Marker>,
    /// Next marker id to assign.
    next_id: u32,
}
impl MarkerStore {
    /// Create an empty marker store.
    pub fn new() -> Self {
        Self::default()
    }
    /// Insert a marker and return its assigned id.
    pub fn add(
        &mut self,
        marker_type: impl Into<String>,
        lat_deg: f32,
        lon_deg: f32,
        label: Option<String>,
        style: MarkerStyle,
    ) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.markers.insert(
            id,
            Marker {
                id,
                marker_type: marker_type.into(),
                lat_deg,
                lon_deg,
                label,
                visible: true,
                style,
                attrs: HashMap::new(),
            },
        );
        id
    }
    /// Remove a marker by id and return it when found.
    pub fn remove(&mut self, id: u32) -> Option<Marker> {
        self.markers.remove(&id)
    }
    /// Return a shared marker reference when the id exists.
    pub fn get(&self, id: u32) -> Option<&Marker> {
        self.markers.get(&id)
    }
    /// Return a mutable marker reference when the id exists.
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Marker> {
        self.markers.get_mut(&id)
    }
    /// Move a marker and return true when the id exists.
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.lat_deg = lat_deg;
            m.lon_deg = lon_deg;
            true
        } else {
            false
        }
    }
    /// Set marker visibility and return true when the id exists.
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.visible = visible;
            true
        } else {
            false
        }
    }
    /// Set a string attribute and return true when the id exists.
    pub fn set_attr(&mut self, id: u32, key: String, value: String) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.attrs.insert(key, value);
            true
        } else {
            false
        }
    }
    /// Return a string attribute for a marker when it exists.
    pub fn get_attr(&self, id: u32, key: &str) -> Option<&str> {
        self.markers.get(&id)?.attrs.get(key).map(String::as_str)
    }
    /// Iterate over all stored markers.
    pub fn iter(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values()
    }
    /// Iterate over visible markers only.
    pub fn iter_visible(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values().filter(|m| m.visible)
    }
    /// Return all markers whose type matches the supplied string.
    pub fn by_type(&self, marker_type: &str) -> Vec<&Marker> {
        self.markers
            .values()
            .filter(|m| m.marker_type == marker_type)
            .collect()
    }
    /// Return the number of stored markers.
    pub fn len(&self) -> usize {
        self.markers.len()
    }
    /// Return true when no markers are stored.
    pub fn is_empty(&self) -> bool {
        self.markers.is_empty()
    }
}
