//! Fog-of-war masks and per-viewer fog storage for globe provinces.
//!
//! Stores compact visibility state and per-viewer mask collections.
//! Encoding helpers stay local to this module.

use crate::globe::types::{FogState, ProvinceId, MAX_PROVINCES};
use base64::Engine;
use std::collections::HashMap;
/// Compact fog state for all supported provinces.
#[derive(Debug, Clone)]
pub struct FogMask {
    /// Packed fog state per province id.
    states: Vec<u8>,
}
impl FogMask {
    /// Create a mask with every province hidden.
    pub fn all_hidden() -> Self {
        Self {
            states: vec![FogState::Hidden as u8; MAX_PROVINCES],
        }
    }
    /// Create a mask with every province visible.
    pub fn all_visible() -> Self {
        Self {
            states: vec![FogState::Visible as u8; MAX_PROVINCES],
        }
    }
    /// Return true when the province is visible.
    pub fn is_visible(&self, id: ProvinceId) -> bool {
        let id = id as usize;
        if id >= MAX_PROVINCES {
            return false;
        }
        self.states[id] == FogState::Visible as u8
    }
    /// Return the stored fog state for a province id.
    pub fn state(&self, id: ProvinceId) -> FogState {
        let id = id as usize;
        if id >= MAX_PROVINCES {
            return FogState::Hidden;
        }
        match self.states[id] {
            2 => FogState::Visible,
            1 => FogState::Explored,
            _ => FogState::Hidden,
        }
    }
    /// Set the fog state for a province id when it is in range.
    pub fn set_state(&mut self, id: ProvinceId, state: FogState) {
        let id = id as usize;
        if id < MAX_PROVINCES {
            self.states[id] = state as u8;
        }
    }
    /// Mark a province as visible.
    pub fn reveal(&mut self, id: ProvinceId) {
        self.set_state(id, FogState::Visible);
    }
    /// Mark a province as hidden.
    pub fn hide(&mut self, id: ProvinceId) {
        self.set_state(id, FogState::Hidden);
    }
    /// Mark a province as explored.
    pub fn explore(&mut self, id: ProvinceId) {
        self.set_state(id, FogState::Explored);
    }
    /// Toggle a province between visible and hidden.
    pub fn toggle(&mut self, id: ProvinceId) {
        let idu = id as usize;
        if idu < MAX_PROVINCES {
            self.states[idu] = if self.states[idu] == FogState::Visible as u8 {
                FogState::Hidden as u8
            } else {
                FogState::Visible as u8
            };
        }
    }
    /// Reveal every province in the supplied iterator.
    pub fn reveal_batch(&mut self, ids: impl Iterator<Item = ProvinceId>) {
        for id in ids {
            self.reveal(id);
        }
    }
    /// Return all visible province ids in ascending order.
    pub fn visible_ids(&self) -> Vec<ProvinceId> {
        self.states
            .iter()
            .enumerate()
            .filter_map(|(i, s)| {
                if *s == FogState::Visible as u8 {
                    Some(i as ProvinceId)
                } else {
                    None
                }
            })
            .collect()
    }
    /// Return all explored province ids in ascending order.
    pub fn explored_ids(&self) -> Vec<ProvinceId> {
        self.states
            .iter()
            .enumerate()
            .filter_map(|(i, s)| {
                if *s == FogState::Explored as u8 {
                    Some(i as ProvinceId)
                } else {
                    None
                }
            })
            .collect()
    }
    /// Build a mask that reveals the supplied province ids.
    pub fn from_visible_ids(ids: &[ProvinceId]) -> Self {
        let mut mask = Self::all_hidden();
        for &id in ids {
            mask.reveal(id);
        }
        mask
    }
    /// Count visible provinces in the mask.
    pub fn count_visible(&self) -> usize {
        self.states
            .iter()
            .filter(|s| **s == FogState::Visible as u8)
            .count()
    }
    /// Count explored provinces in the mask.
    pub fn count_explored(&self) -> usize {
        self.states
            .iter()
            .filter(|s| **s == FogState::Explored as u8)
            .count()
    }
    /// Encode the fog mask as base64 packed two-bit states.
    pub fn to_base64(&self) -> String {
        let packed_len = (MAX_PROVINCES * 2).div_ceil(8);
        let mut packed = vec![0u8; packed_len];
        for (i, s) in self.states.iter().enumerate() {
            let two_bits = (*s).min(2);
            let bit = i * 2;
            let byte_idx = bit / 8;
            let shift = (bit % 8) as u8;
            packed[byte_idx] |= two_bits << shift;
            if shift > 6 {
                packed[byte_idx + 1] |= two_bits >> (8 - shift);
            }
        }
        base64::engine::general_purpose::STANDARD.encode(packed)
    }
    /// Decode a base64 encoded fog mask or return an error on invalid input.
    pub fn from_base64(s: &str) -> Result<Self, String> {
        let bytes = base64::engine::general_purpose::STANDARD
            .decode(s)
            .map_err(|e| format!("fog base64 decode failed: {e}"))?;
        let mut states = vec![FogState::Hidden as u8; MAX_PROVINCES];
        for (i, state) in states.iter_mut().enumerate() {
            let bit = i * 2;
            let byte_idx = bit / 8;
            if byte_idx >= bytes.len() {
                break;
            }
            let shift = (bit % 8) as u8;
            let mut two_bits = (bytes[byte_idx] >> shift) & 0b11;
            if shift > 6 && byte_idx + 1 < bytes.len() {
                let spill = bytes[byte_idx + 1] << (8 - shift);
                two_bits = (two_bits | spill) & 0b11;
            }
            *state = two_bits.min(2);
        }
        Ok(Self { states })
    }
}
/// Per-viewer fog mask store keyed by viewer name.
#[derive(Debug, Clone, Default)]
pub struct FogStore {
    /// Viewer name to fog mask mapping.
    masks: HashMap<String, FogMask>,
}
impl FogStore {
    /// Create an empty fog store.
    pub fn new() -> Self {
        Self::default()
    }
    /// Return the mask for a viewer, inserting a hidden mask when absent.
    pub fn get_or_insert(&mut self, viewer: &str) -> &mut FogMask {
        self.masks
            .entry(viewer.to_string())
            .or_insert_with(FogMask::all_hidden)
    }
    /// Return the mask for a viewer when it exists.
    pub fn get(&self, viewer: &str) -> Option<&FogMask> {
        self.masks.get(viewer)
    }
    /// Return true when the viewer can see the province.
    pub fn is_visible(&self, viewer: &str, id: ProvinceId) -> bool {
        match self.masks.get(viewer) {
            Some(mask) => mask.is_visible(id),
            None => true,
        }
    }
    /// Reveal a province for a viewer.
    pub fn reveal(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).reveal(id);
    }
    /// Mark a province as explored for a viewer.
    pub fn explore(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).explore(id);
    }
    /// Hide a province for a viewer.
    pub fn hide(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).hide(id);
    }
    /// Return the visible province ids for a viewer when the viewer exists.
    pub fn visible_ids(&self, viewer: &str) -> Option<Vec<ProvinceId>> {
        self.masks.get(viewer).map(FogMask::visible_ids)
    }
    /// Return the explored province ids for a viewer when the viewer exists.
    pub fn explored_ids(&self, viewer: &str) -> Option<Vec<ProvinceId>> {
        self.masks.get(viewer).map(FogMask::explored_ids)
    }
    /// Return the state for a viewer or visible when the viewer has no mask.
    pub fn state(&self, viewer: &str, id: ProvinceId) -> FogState {
        self.masks
            .get(viewer)
            .map(|m| m.state(id))
            .unwrap_or(FogState::Visible)
    }
    /// Set the fog state for a viewer and province.
    pub fn set_state(&mut self, viewer: &str, id: ProvinceId, state: FogState) {
        self.get_or_insert(viewer).set_state(id, state);
    }
    /// Serialize a viewer mask to base64 when it exists.
    pub fn to_base64(&self, viewer: &str) -> Option<String> {
        self.masks.get(viewer).map(FogMask::to_base64)
    }
    /// Load a viewer mask from base64 or return an error on invalid input.
    pub fn load_base64(&mut self, viewer: &str, encoded: &str) -> Result<(), String> {
        let mask = FogMask::from_base64(encoded)?;
        self.masks.insert(viewer.to_string(), mask);
        Ok(())
    }
    /// Replace a viewer mask with one built from visible province ids.
    pub fn load(&mut self, viewer: &str, ids: &[ProvinceId]) {
        self.masks
            .insert(viewer.to_string(), FogMask::from_visible_ids(ids));
    }
    /// Remove the viewer mask if it exists.
    pub fn remove(&mut self, viewer: &str) {
        self.masks.remove(viewer);
    }
    /// Return all viewer names in arbitrary order.
    pub fn viewers(&self) -> Vec<String> {
        self.masks.keys().cloned().collect()
    }
}
