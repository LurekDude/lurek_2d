use crate::globe::types::{Label, LabelStyle};
use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
pub struct LabelStore {
    labels: HashMap<u32, Label>,
    next_id: u32,
}
impl LabelStore {
    pub fn new() -> Self {
        Self::default()
    }
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
    pub fn remove(&mut self, id: u32) -> Option<Label> {
        self.labels.remove(&id)
    }
    pub fn get(&self, id: u32) -> Option<&Label> {
        self.labels.get(&id)
    }
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Label> {
        self.labels.get_mut(&id)
    }
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.visible = visible;
            true
        } else {
            false
        }
    }
    pub fn set_text(&mut self, id: u32, text: impl Into<String>) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.text = text.into();
            true
        } else {
            false
        }
    }
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(l) = self.labels.get_mut(&id) {
            l.lat_deg = lat_deg;
            l.lon_deg = lon_deg;
            true
        } else {
            false
        }
    }
    pub fn iter(&self) -> impl Iterator<Item = &Label> {
        self.labels.values()
    }
    pub fn iter_visible(&self, lod_tier: u8) -> impl Iterator<Item = &Label> {
        self.labels
            .values()
            .filter(move |l| l.visible && l.min_lod <= lod_tier)
    }
    pub fn len(&self) -> usize {
        self.labels.len()
    }
    pub fn is_empty(&self) -> bool {
        self.labels.is_empty()
    }
}
