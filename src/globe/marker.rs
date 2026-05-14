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
    /// Remove a marker by id and return it when found.
                id,
                marker_type: marker_type.into(),
                lat_deg,
    /// Return a shared marker reference when the id exists.
                lon_deg,
                label,
                visible: true,
    /// Return a mutable marker reference when the id exists.
                style,
                attrs: HashMap::new(),
            },
    /// Move a marker and return true when the id exists.
        );
        id
    }
    pub fn remove(&mut self, id: u32) -> Option<Marker> {
        self.markers.remove(&id)
    }
    pub fn get(&self, id: u32) -> Option<&Marker> {
        self.markers.get(&id)
    }
    /// Set marker visibility and return true when the id exists.
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Marker> {
        self.markers.get_mut(&id)
    }
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.lat_deg = lat_deg;
            m.lon_deg = lon_deg;
            true
    /// Set a string attribute and return true when the id exists.
        } else {
            false
        }
    }
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.visible = visible;
            true
    /// Return a string attribute for a marker when it exists.
        } else {
            false
        }
    /// Iterate over all stored markers.
    }
    pub fn set_attr(&mut self, id: u32, key: String, value: String) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
    /// Iterate over visible markers only.
            m.attrs.insert(key, value);
            true
        } else {
    /// Return all markers whose type matches the supplied string.
            false
        }
    }
    pub fn get_attr(&self, id: u32, key: &str) -> Option<&str> {
        self.markers.get(&id)?.attrs.get(key).map(String::as_str)
    }
    /// Return the number of stored markers.
    pub fn iter(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values()
    }
    /// Return true when no markers are stored.
    pub fn iter_visible(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values().filter(|m| m.visible)
    }
    pub fn by_type(&self, marker_type: &str) -> Vec<&Marker> {
        self.markers
            .values()
            .filter(|m| m.marker_type == marker_type)
            .collect()
    }
    pub fn len(&self) -> usize {
        self.markers.len()
    }
    pub fn is_empty(&self) -> bool {
        self.markers.is_empty()
    }
}
