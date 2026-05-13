use crate::globe::types::{Marker, MarkerStyle};
use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
pub struct MarkerStore {
    markers: HashMap<u32, Marker>,
    next_id: u32,
}
impl MarkerStore {
    pub fn new() -> Self {
        Self::default()
    }
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
    pub fn remove(&mut self, id: u32) -> Option<Marker> {
        self.markers.remove(&id)
    }
    pub fn get(&self, id: u32) -> Option<&Marker> {
        self.markers.get(&id)
    }
    pub fn get_mut(&mut self, id: u32) -> Option<&mut Marker> {
        self.markers.get_mut(&id)
    }
    pub fn move_to(&mut self, id: u32, lat_deg: f32, lon_deg: f32) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.lat_deg = lat_deg;
            m.lon_deg = lon_deg;
            true
        } else {
            false
        }
    }
    pub fn set_visible(&mut self, id: u32, visible: bool) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.visible = visible;
            true
        } else {
            false
        }
    }
    pub fn set_attr(&mut self, id: u32, key: String, value: String) -> bool {
        if let Some(m) = self.markers.get_mut(&id) {
            m.attrs.insert(key, value);
            true
        } else {
            false
        }
    }
    pub fn get_attr(&self, id: u32, key: &str) -> Option<&str> {
        self.markers.get(&id)?.attrs.get(key).map(String::as_str)
    }
    pub fn iter(&self) -> impl Iterator<Item = &Marker> {
        self.markers.values()
    }
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
