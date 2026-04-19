//! Generic marker store for the globe module.
//!
//! Markers are points of interest placed on the globe surface. All semantics
//! (city, base, UFO, fleet, etc.) are user-defined via the `marker_type` string.
//! The engine provides the storage and lifecycle primitives only.

use std::collections::HashMap;
use crate::globe::types::{Marker, MarkerStyle};

/// Store and lifecycle manager for globe markers.
///
/// Markers are indexed by a user-assigned `u32` ID.
#[derive(Debug, Clone, Default)]
pub struct MarkerStore {
    markers: HashMap<u32, Marker>,
    next_id: u32,
}

impl MarkerStore {
    /// Create an empty store.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a marker, assigning the next available ID. Returns the assigned ID.
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
        self.markers.insert(id, Marker {
            id,
            marker_type: marker_type.into(),
            lat_deg,
            lon_deg,
            label,
            visible: true,
            style,
            attrs: HashMap::new(),
        });
        id
    }

    /// Remove a marker by ID. Returns the removed marker or `None`.
    pub fn remove(&mut self, id: u32) -> Option<Marker> {
        self.markers.remove(&id)
    }

    /// Get an immutable reference to a marker.
    pub fn get(&self, id: u32) -> Option<&Marker> {
        self.markers.get(&id)
    }

    /// Get a mutable reference to a marker.
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Marker> {
        self.markers.get_mut(&id)
    }

    /// Move a marker to a new lat/lon.
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.lat_deg = lat_deg;
            m.lon_deg = lon_deg;
            true
        } else {
            false
        }
    }

    /// Set marker visibility.
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.visible = visible;
            true
        } else {
            false
        }
    }

    /// Set a user attribute on a marker.
    pub fn set_attr(&mut self, id: u32, key: String, value: String) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.attrs.insert(key, value);
            true
        } else {
            false
        }
    }

    /// Get a user attribute from a marker.
    pub fn get_attr(&self, id: u32, key: &str) -> Option<&str> {
        self.markers.get(&id)?.attrs.get(key).map(String::as_str)
    }

    /// Iterate over all markers.
    pub fn iter(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values()
    }

    /// Iterate over visible markers only.
    pub fn iter_visible(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values().filter(|m| m.visible)
    }

    /// All markers of a given type.
    pub fn by_type(&self, marker_type: &str) -> Vec<&Marker> {
        self.markers.values().filter(|m| m.marker_type == marker_type).collect()
    }

    /// Number of markers.
    pub fn len(&self) -> usize {
        self.markers.len()
    }

    /// True if no markers are stored.
    pub fn is_empty(&self) -> bool {
        self.markers.is_empty()
    }
}
