use crate::globe::types::{Layer, ProvinceId};
use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
pub struct LayerStore {
    layers: HashMap<String, Layer>,
}
impl LayerStore {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn add(&mut self, layer: Layer) -> bool {
        self.layers.insert(layer.name.clone(), layer).is_some()
    }
    pub fn remove(&mut self, name: &str) -> Option<Layer> {
        self.layers.remove(name)
    }
    pub fn get(&self, name: &str) -> Option<&Layer> {
        self.layers.get(name)
    }
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Layer> {
        self.layers.get_mut(name)
    }
    pub fn set_province_color(&mut self, layer: &str, id: ProvinceId, color: [f32; 4]) -> bool {
        if let Some(l) = self.layers.get_mut(layer) {
            l.province_colors.insert(id, color);
            true
        } else {
            false
        }
    }
    pub fn clear_province_colors(&mut self, layer: &str) {
        if let Some(l) = self.layers.get_mut(layer) {
            l.province_colors.clear();
        }
    }
    pub fn set_visible(&mut self, name: &str, visible: bool) -> bool {
        if let Some(l) = self.layers.get_mut(name) {
            l.visible = visible;
            true
        } else {
            false
        }
    }
    pub fn set_alpha(&mut self, name: &str, alpha: f32) -> bool {
        if let Some(l) = self.layers.get_mut(name) {
            l.alpha = alpha.clamp(0.0, 1.0);
            true
        } else {
            false
        }
    }
    pub fn effective_color(&self, id: ProvinceId) -> Option<[f32; 4]> {
        let mut sorted: Vec<&Layer> = self.layers.values().filter(|l| l.visible).collect();
        sorted.sort_by_key(|l| l.z_order);
        let mut result: Option<[f32; 4]> = None;
        for layer in sorted {
            if let Some(&color) = layer.province_colors.get(&id) {
                let alpha = color[3] * layer.alpha;
                result = Some([color[0], color[1], color[2], alpha]);
            }
        }
        result
    }
    pub fn visible_sorted(&self) -> Vec<&Layer> {
        let mut sorted: Vec<&Layer> = self.layers.values().filter(|l| l.visible).collect();
        sorted.sort_by_key(|l| l.z_order);
        sorted
    }
    pub fn len(&self) -> usize {
        self.layers.len()
    }
    pub fn is_empty(&self) -> bool {
        self.layers.is_empty()
    }
}
