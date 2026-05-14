//! SpriteBatch: deferred draw-call accumulation for grouped sprite rendering from a single texture.
//! Owns SpriteBatch and BatchEntry; accumulates entries until clear() resets the buffer each frame.
//! Does not own rendering commands — callers iterate entries() to emit draw calls from the render pipeline.
//! Key dependencies: TextureKey for the shared source texture.

use crate::runtime::resource_keys::TextureKey;

/// Deferred sprite draw-call collector bound to a single texture.
pub struct SpriteBatch {
    /// Texture all entries in this batch draw from.
    texture_key: TextureKey,
    /// Accumulated draw entries for this frame.
    entries: Vec<BatchEntry>,
    /// Upper bound on entries; 0 means unlimited, otherwise add() returns None when full.
    max_entries: usize,
}
/// A single sprite draw entry with world position, source quad, transform, and origin offset.
pub struct BatchEntry {
    /// World-space X position of this sprite.
    pub x: f32,
    /// World-space Y position of this sprite.
    pub y: f32,
    /// Source quad X in the texture, in pixels.
    pub quad_x: f32,
    /// Source quad Y in the texture, in pixels.
    pub quad_y: f32,
    /// Source quad width in pixels.
    pub quad_w: f32,
    /// Source quad height in pixels.
    pub quad_h: f32,
    /// Rotation in radians counter-clockwise around the origin offset.
    pub rotation: f32,
    /// Horizontal scale factor; 1.0 = no scale.
    pub sx: f32,
    /// Vertical scale factor; 1.0 = no scale.
    pub sy: f32,
    /// X origin offset used as pivot for rotation and scale.
    pub ox: f32,
    /// Y origin offset used as pivot for rotation and scale.
    pub oy: f32,
}
/// Construction and entry management for SpriteBatch.
impl SpriteBatch {
    /// Create a batch for texture_key with the given max_entries cap; 0 uses a default capacity of 256.
    pub fn new(texture_key: TextureKey, max_entries: usize) -> Self {
        let cap = if max_entries > 0 { max_entries } else { 256 };
        SpriteBatch {
            texture_key,
            entries: Vec::with_capacity(cap),
            max_entries,
        }
    }
    /// Append a BatchEntry and return its index; returns None when the max_entries limit is reached.
    pub fn add(&mut self, entry: BatchEntry) -> Option<usize> {
        if self.max_entries > 0 && self.entries.len() >= self.max_entries {
            return None;
        }
        let idx = self.entries.len();
        self.entries.push(entry);
        Some(idx)
    }
    /// Remove all entries without releasing the underlying allocation.
    pub fn clear(&mut self) {
        self.entries.clear();
    }
    /// Return the TextureKey this batch is bound to.
    pub fn texture_key(&self) -> TextureKey {
        self.texture_key
    }
    /// Return the accumulated entry slice for this frame.
    pub fn entries(&self) -> &[BatchEntry] {
        &self.entries
    }
    /// Return the current number of entries in the batch.
    pub fn len(&self) -> usize {
        self.entries.len()
    }
    /// Return true when the batch contains no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
    /// Return the configured max_entries cap; 0 means unlimited.
    pub fn buffer_size(&self) -> usize {
        self.max_entries
    }
}
