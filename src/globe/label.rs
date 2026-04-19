//! Generic label store for the globe module.
//!
//! Labels are text annotations on the globe surface. All semantics (country, region,
//! capital, note, etc.) are user-defined via `label_type`. Nothing is hardcoded.

use std::collections::HashMap;
use crate::globe::types::{Label, LabelStyle};

/// Store and lifecycle manager for globe labels.
///
/// Labels are indexed by a user-assigned `u32` ID.
#[derive(Debug, Clone, Default)]
pub struct LabelStore {
    labels: HashMap<u32, Label>,
    next_id: u32,
}

impl LabelStore {
    /// Create an empty store.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a label. Returns the assigned ID.
    pub fn add(
        &mut self,
        label_type: impl Into<String>,
        lat_deg: f32,
        lon_deg: f32,
        text: impl Into<String>,
        style: LabelStyle,
        min_lod: u8,
    ) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.labels.insert(id, Label {
            id,
            label_type: label_type.into(),
            lat_deg,
            lon_deg,
            text: text.into(),
            visible: true,
            style,
            min_lod,
        });
        id
    }

    /// Remove a label by ID.
    pub fn remove(&mut self, id: u32) -> Option<Label> {
        self.labels.remove(&id)
    }

    /// Get an immutable reference.
    pub fn get(&self, id: u32) -> Option<&Label> {
        self.labels.get(&id)
    }

    /// Get a mutable reference.
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Label> {
        self.labels.get_mut(&id)
    }

    /// Set label visibility.
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.visible = visible;
            true
        } else {
            false
        }
    }

    /// Update label text.
    pub fn set_text(&mut self, id: u32, text: impl Into<String>) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.text = text.into();
            true
        } else {
            false
        }
    }

    /// Move label to a new position.
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.lat_deg = lat_deg;
            l.lon_deg = lon_deg;
            true
        } else {
            false
        }
    }

    /// Iterate over all labels.
    pub fn iter(&self) -> impl Iterator<Item = &Label> {
        self.labels.values()
    }

    /// Iterate over visible labels at or above the given LOD tier.
    pub fn iter_visible(&self, lod_tier: u8) -> impl Iterator<Item = &Label> {
        self.labels.values().filter(move |l| l.visible && l.min_lod <= lod_tier)
    }

    /// Number of labels.
    pub fn len(&self) -> usize {
        self.labels.len()
    }

    /// True if empty.
    pub fn is_empty(&self) -> bool {
        self.labels.is_empty()
    }
}
