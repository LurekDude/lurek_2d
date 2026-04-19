//! Named layer registry for the globe module.
//!
//! Layers sit above the base province map and can carry per-province color overrides,
//! visibility flags, and opacity. All layer semantics are user-defined.

use std::collections::HashMap;
use crate::globe::types::{Layer, ProvinceId};

/// Registry and lifecycle manager for globe layers.
///
/// Layers are keyed by name and sorted by `z_order` at draw time.
#[derive(Debug, Clone, Default)]
pub struct LayerStore {
    layers: HashMap<String, Layer>,
}

impl LayerStore {
    /// Create an empty store.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add or replace a layer. Returns `true` if an existing layer was replaced.
    pub fn add(&mut self, layer: Layer) -> bool {
        self.layers.insert(layer.name.clone(), layer).is_some()
    }

    /// Remove a layer by name.
    pub fn remove(&mut self, name: &str) -> Option<Layer> {
        self.layers.remove(name)
    }

    /// Get an immutable reference to a layer.
    pub fn get(&self, name: &str) -> Option<&Layer> {
        self.layers.get(name)
    }

    /// Get a mutable reference to a layer.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Layer> {
        self.layers.get_mut(name)
    }

    /// Set province color override in a layer.
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

    /// Set layer visibility.
    pub fn set_visible(&mut self, name: &str, visible: bool) -> bool {
        if let Some(l) = self.layers.get_mut(name) {
            l.visible = visible;
            true
        } else {
            false
        }
    }

    /// Set layer opacity.
    pub fn set_alpha(&mut self, name: &str, alpha: f32) -> bool {
        if let Some(l) = self.layers.get_mut(name) {
            l.alpha = alpha.clamp(0.0, 1.0);
            true
        } else {
            false
        }
    }

    /// Get the effective color for a province across all visible layers.
    ///
    /// Layers are blended in z_order, with higher z_order on top.
    /// Returns `None` if no layer has a color for this province.
    pub fn effective_color(&self, id: ProvinceId) -> Option<[f32; 4]> {
        let mut sorted: Vec<&Layer> = self.layers.values()
            .filter(|l| l.visible)
            .collect();
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

    /// Return all visible layers sorted by z_order.
    pub fn visible_sorted(&self) -> Vec<&Layer> {
        let mut sorted: Vec<&Layer> = self.layers.values()
            .filter(|l| l.visible)
            .collect();
        sorted.sort_by_key(|l| l.z_order);
        sorted
    }

    /// Number of layers.
    pub fn len(&self) -> usize {
        self.layers.len()
    }

    /// True if empty.
    pub fn is_empty(&self) -> bool {
        self.layers.is_empty()
    }
}
