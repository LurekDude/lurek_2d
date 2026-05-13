//! Per-faction fog-of-war for the globe module.
//!
//! Each viewer (player, faction, etc.) has a bit-vector of length `MAX_PROVINCES`
//! where `1` = province is visible and `0` = province is hidden (dark / unexplored).
//!
//! The fog store is keyed by viewer ID (`String`). Viewer IDs are fully user-defined.
//! The store exposes simple get/set/reveal/hide operations and is serializable as a
//! flat list of visible province IDs (compatible with `lurek.save.*` primitives).

use crate::globe::types::{FogState, ProvinceId, MAX_PROVINCES};
use base64::Engine;
use std::collections::HashMap;

/// Per-faction visibility bit-vector.
///
/// Bit index = `ProvinceId`. Province IDs beyond `MAX_PROVINCES` are silently ignored.
#[derive(Debug, Clone)]
pub struct FogMask {
    states: Vec<u8>,
}

impl FogMask {
    /// Create a new fog mask with all provinces hidden.
    pub fn all_hidden() -> Self {
        Self {
            states: vec![FogState::Hidden as u8; MAX_PROVINCES],
        }
    }

    /// Create a new fog mask with all provinces visible.
    pub fn all_visible() -> Self {
        Self {
            states: vec![FogState::Visible as u8; MAX_PROVINCES],
        }
    }

    /// Return whether province `id` is visible.
    pub fn is_visible(&self, id: ProvinceId) -> bool {
        let id = id as usize;
        if id >= MAX_PROVINCES {
            return false;
        }
        self.states[id] == FogState::Visible as u8
    }

    /// Return the exact fog state for a province.
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

    /// Set fog state for a province.
    pub fn set_state(&mut self, id: ProvinceId, state: FogState) {
        let id = id as usize;
        if id < MAX_PROVINCES {
            self.states[id] = state as u8;
        }
    }

    /// Mark province `id` as visible.
    pub fn reveal(&mut self, id: ProvinceId) {
        self.set_state(id, FogState::Visible);
    }

    /// Hide province `id`.
    pub fn hide(&mut self, id: ProvinceId) {
        self.set_state(id, FogState::Hidden);
    }

    /// Mark province as explored but not currently visible.
    pub fn explore(&mut self, id: ProvinceId) {
        self.set_state(id, FogState::Explored);
    }

    /// Toggle province `id`.
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

    /// Reveal all provinces in the iterator.
    pub fn reveal_batch(&mut self, ids: impl Iterator<Item = ProvinceId>) {
        for id in ids {
            self.reveal(id);
        }
    }

    /// Return all currently-visible province IDs.
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

    /// Return all provinces marked as explored.
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

    /// Deserialize from a list of visible province IDs (for `lurek.save.*` integration).
    pub fn from_visible_ids(ids: &[ProvinceId]) -> Self {
        let mut mask = Self::all_hidden();
        for &id in ids {
            mask.reveal(id);
        }
        mask
    }

    /// Count visible provinces.
    pub fn count_visible(&self) -> usize {
        self.states
            .iter()
            .filter(|s| **s == FogState::Visible as u8)
            .count()
    }

    /// Count explored (not currently visible) provinces.
    pub fn count_explored(&self) -> usize {
        self.states
            .iter()
            .filter(|s| **s == FogState::Explored as u8)
            .count()
    }

    /// Serialize fog states to base64 (2 bits per province).
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

    /// Deserialize fog states from base64 generated by [`FogMask::to_base64`].
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

/// Store of fog masks keyed by viewer ID.
#[derive(Debug, Clone, Default)]
pub struct FogStore {
    masks: HashMap<String, FogMask>,
}

impl FogStore {
    /// Create an empty store.
    pub fn new() -> Self {
        Self::default()
    }

    /// Get or create the fog mask for a viewer.
    /// A newly-created mask has all provinces hidden.
    pub fn get_or_insert(&mut self, viewer: &str) -> &mut FogMask {
        self.masks
            .entry(viewer.to_string())
            .or_insert_with(FogMask::all_hidden)
    }

    /// Get an immutable fog mask for a viewer. Returns `None` if not registered.
    pub fn get(&self, viewer: &str) -> Option<&FogMask> {
        self.masks.get(viewer)
    }

    /// Check if province `id` is visible to viewer `viewer`.
    /// Returns `true` if the viewer has no mask (no fog) or the mask reveals the province.
    pub fn is_visible(&self, viewer: &str, id: ProvinceId) -> bool {
        match self.masks.get(viewer) {
            Some(mask) => mask.is_visible(id),
            None => true, // No mask = full visibility.
        }
    }

    /// Reveal province `id` for viewer.
    pub fn reveal(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).reveal(id);
    }

    /// Mark province as explored for viewer.
    pub fn explore(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).explore(id);
    }

    /// Hide province `id` for viewer.
    pub fn hide(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).hide(id);
    }

    /// Return visible province IDs for viewer, or `None` if viewer has no mask.
    pub fn visible_ids(&self, viewer: &str) -> Option<Vec<ProvinceId>> {
        self.masks.get(viewer).map(FogMask::visible_ids)
    }

    /// Return explored IDs for viewer, or `None` if viewer has no mask.
    pub fn explored_ids(&self, viewer: &str) -> Option<Vec<ProvinceId>> {
        self.masks.get(viewer).map(FogMask::explored_ids)
    }

    /// Return fog state for a viewer/province pair.
    pub fn state(&self, viewer: &str, id: ProvinceId) -> FogState {
        self.masks
            .get(viewer)
            .map(|m| m.state(id))
            .unwrap_or(FogState::Visible)
    }

    /// Set fog state for a viewer/province pair.
    pub fn set_state(&mut self, viewer: &str, id: ProvinceId, state: FogState) {
        self.get_or_insert(viewer).set_state(id, state);
    }

    /// Serialize one viewer fog mask to base64.
    pub fn to_base64(&self, viewer: &str) -> Option<String> {
        self.masks.get(viewer).map(FogMask::to_base64)
    }

    /// Load one viewer fog mask from base64.
    pub fn load_base64(&mut self, viewer: &str, encoded: &str) -> Result<(), String> {
        let mask = FogMask::from_base64(encoded)?;
        self.masks.insert(viewer.to_string(), mask);
        Ok(())
    }

    /// Load visible IDs from save data.
    pub fn load(&mut self, viewer: &str, ids: &[ProvinceId]) {
        self.masks
            .insert(viewer.to_string(), FogMask::from_visible_ids(ids));
    }

    /// Remove a viewer's fog mask.
    pub fn remove(&mut self, viewer: &str) {
        self.masks.remove(viewer);
    }

    /// List all registered viewer IDs.
    pub fn viewers(&self) -> Vec<String> {
        self.masks.keys().cloned().collect()
    }
}
