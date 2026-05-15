//! - Named layer storage keyed by string, with insert, remove, and lookup.
//! - Per-province color overrides, visibility toggling, and alpha clamping.
//! - Z-order–aware color resolution across all visible layers.

use crate::globe::types::{Layer, ProvinceId};
use std::collections::HashMap;
/// Named layer collection keyed by layer name.
#[derive(Debug, Clone, Default)]
pub struct LayerStore {
    /// Stored layers by name.
    layers: HashMap<String, Layer>,
}
impl LayerStore {
    /// Create an empty layer store. This function is part of the public API.
    pub fn new() -> Self {
        Self::default()
    }
    /// Insert a layer and return true when a layer with the same name was replaced.
    pub fn add(&mut self, layer: Layer) -> bool {
        self.layers.insert(layer.name.clone(), layer).is_some()
    }
    /// Remove a layer by name and return it when found.
    pub fn remove(&mut self, name: &str) -> Option<Layer> {
        self.layers.remove(name)
    }
    /// Return a shared layer reference when the name exists.
    pub fn get(&self, name: &str) -> Option<&Layer> {
        self.layers.get(name)
    }
    /// Return a mutable layer reference when the name exists.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Layer> {
        self.layers.get_mut(name)
    }
    /// Set a province color override for a layer and return true when the layer exists.
    pub fn set_province_color(&mut self, layer: &str, id: ProvinceId, color: [f32; 4]) -> bool {
        if let Some(l) = self.layers.get_mut(layer) {
            l.province_colors.insert(id, color);
            true
        } else {
            false
        }
    }
    /// Clear all province color overrides from a layer.
    pub fn clear_province_colors(&mut self, layer: &str) {
        if let Some(l) = self.layers.get_mut(layer) {
            l.province_colors.clear();
        }
    }
    /// Set layer visibility and return true when the layer exists.
    pub fn set_visible(&mut self, name: &str, visible: bool) -> bool {
        if let Some(l) = self.layers.get_mut(name) {
            l.visible = visible;
            true
        } else {
            false
        }
    }
    /// Set layer alpha and clamp it to the 0..=1 range.
    pub fn set_alpha(&mut self, name: &str, alpha: f32) -> bool {
        if let Some(l) = self.layers.get_mut(name) {
            l.alpha = alpha.clamp(0.0, 1.0);
            true
        } else {
            false
        }
    }
    /// Resolve the effective province color by applying visible layers in z-order.
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
    /// Return visible layers sorted by z-order.
    pub fn visible_sorted(&self) -> Vec<&Layer> {
        let mut sorted: Vec<&Layer> = self.layers.values().filter(|l| l.visible).collect();
        sorted.sort_by_key(|l| l.z_order);
        sorted
    }
    /// Return the number of stored layers.
    pub fn len(&self) -> usize {
        self.layers.len()
    }
    /// Return true when no layers are stored.
    pub fn is_empty(&self) -> bool {
        self.layers.is_empty()
    }
}
