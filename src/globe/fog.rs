//! Per-faction fog-of-war for the globe module.
//!
//! Each viewer (player, faction, etc.) has a bit-vector of length `MAX_PROVINCES`
//! where `1` = province is visible and `0` = province is hidden (dark / unexplored).
//!
//! The fog store is keyed by viewer ID (`String`). Viewer IDs are fully user-defined.
//! The store exposes simple get/set/reveal/hide operations and is serializable as a
//! flat list of visible province IDs (compatible with `lurek.save.*` primitives).

use std::collections::HashMap;
use crate::globe::types::{ProvinceId, MAX_PROVINCES};

/// Per-faction visibility bit-vector.
///
/// Bit index = `ProvinceId`. Province IDs beyond `MAX_PROVINCES` are silently ignored.
#[derive(Debug, Clone)]
pub struct FogMask {
    bits: Vec<u64>,
}

impl FogMask {
    /// Create a new fog mask with all provinces hidden.
    pub fn all_hidden() -> Self {
        let words = (MAX_PROVINCES + 63) / 64;
        Self { bits: vec![0u64; words] }
    }

    /// Create a new fog mask with all provinces visible.
    pub fn all_visible() -> Self {
        let words = (MAX_PROVINCES + 63) / 64;
        let mut bits = vec![!0u64; words];
        // Clear bits beyond MAX_PROVINCES.
        let trailing = MAX_PROVINCES % 64;
        if trailing != 0 {
            if let Some(last) = bits.last_mut() {
                *last = (1u64 << trailing) - 1;
            }
        }
        Self { bits }
    }

    /// Return whether province `id` is visible.
    pub fn is_visible(&self, id: ProvinceId) -> bool {
        let id = id as usize;
        if id >= MAX_PROVINCES {
            return false;
        }
        (self.bits[id / 64] >> (id % 64)) & 1 == 1
    }

    /// Mark province `id` as visible.
    pub fn reveal(&mut self, id: ProvinceId) {
        let id = id as usize;
        if id < MAX_PROVINCES {
            self.bits[id / 64] |= 1u64 << (id % 64);
        }
    }

    /// Hide province `id`.
    pub fn hide(&mut self, id: ProvinceId) {
        let id = id as usize;
        if id < MAX_PROVINCES {
            self.bits[id / 64] &= !(1u64 << (id % 64));
        }
    }

    /// Toggle province `id`.
    pub fn toggle(&mut self, id: ProvinceId) {
        let id = id as usize;
        if id < MAX_PROVINCES {
            self.bits[id / 64] ^= 1u64 << (id % 64);
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
        let mut out = Vec::new();
        for (word_idx, &word) in self.bits.iter().enumerate() {
            let mut w = word;
            while w != 0 {
                let bit = w.trailing_zeros() as usize;
                let id = word_idx * 64 + bit;
                if id < MAX_PROVINCES {
                    out.push(id as ProvinceId);
                }
                w &= w - 1;
            }
        }
        out
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
        self.bits.iter().map(|w| w.count_ones() as usize).sum()
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

    /// Hide province `id` for viewer.
    pub fn hide(&mut self, viewer: &str, id: ProvinceId) {
        self.get_or_insert(viewer).hide(id);
    }

    /// Return visible province IDs for viewer, or `None` if viewer has no mask.
    pub fn visible_ids(&self, viewer: &str) -> Option<Vec<ProvinceId>> {
        self.masks.get(viewer).map(FogMask::visible_ids)
    }

    /// Load visible IDs from save data.
    pub fn load(&mut self, viewer: &str, ids: &[ProvinceId]) {
        self.masks.insert(viewer.to_string(), FogMask::from_visible_ids(ids));
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
