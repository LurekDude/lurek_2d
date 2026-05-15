//! - Id-keyed label storage for globe map annotations.
//! - Insert, remove, move, and toggle visibility of positioned text labels.
//! - LOD-aware iteration filters labels by minimum detail tier.

use crate::globe::types::{Label, LabelStyle};
use std::collections::HashMap;
/// Label collection keyed by stable id.
#[derive(Debug, Clone, Default)]
pub struct LabelStore {
    /// Stored labels by id.
    labels: HashMap<u32, Label>,
    /// Next label id to assign.
    next_id: u32,
}
impl LabelStore {
    /// Create an empty label store. This function is part of the public API.
    pub fn new() -> Self {
        Self::default()
    }
    /// Insert a label and return its assigned id.
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
        self.labels.insert(
            id,
            Label {
                id,
                label_type: label_type.into(),
                lat_deg,
                lon_deg,
                text: text.into(),
                visible: true,
                style,
                min_lod,
            },
        );
        id
    }
    /// Remove a label by id and return it when found.
    pub fn remove(&mut self, id: u32) -> Option<Label> {
        self.labels.remove(&id)
    }
    /// Return a shared label reference when the id exists.
    pub fn get(&self, id: u32) -> Option<&Label> {
        self.labels.get(&id)
    }
    /// Return a mutable label reference when the id exists.
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Label> {
        self.labels.get_mut(&id)
    }
    /// Set label visibility and return true when the id exists.
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.visible = visible;
            true
        } else {
            false
        }
    }
    /// Replace label text and return true when the id exists.
    pub fn set_text(&mut self, id: u32, text: impl Into<String>) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.text = text.into();
            true
        } else {
            false
        }
    }
    /// Move a label to a new latitude and longitude and return true when it exists.
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.lat_deg = lat_deg;
            l.lon_deg = lon_deg;
            true
        } else {
            false
        }
    }
    /// Iterate over all stored labels.
    pub fn iter(&self) -> impl Iterator<Item = &Label> {
        self.labels.values()
    }
    /// Iterate over visible labels whose minimum LOD fits the supplied tier.
    pub fn iter_visible(&self, lod_tier: u8) -> impl Iterator<Item = &Label> {
        self.labels
            .values()
            .filter(move |l| l.visible && l.min_lod <= lod_tier)
    }
    /// Return the number of stored labels.
    pub fn len(&self) -> usize {
        self.labels.len()
    }
    /// Return true when no labels are stored.
    pub fn is_empty(&self) -> bool {
        self.labels.is_empty()
    }
}
