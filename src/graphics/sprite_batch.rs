//! Sprite batching for efficient rendering of many sprites sharing one texture.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for sprite batch-related operations and data management.
//! Key types exported from this module: `SpriteBatch`, `BatchEntry`.
//! Primary functions: `new()`, `add()`, `clear()`, `texture_key()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::engine::resource_keys::TextureKey;

/// A batch of sprites sharing a single texture, drawn in one GPU call.
///
/// Created via `lurek.gfx.newSpriteBatch(image_id, max_sprites?)`.
/// Use `add()` to queue sprites and the engine draws them all at once.
///
/// # Fields
/// - `e` — `:textures`.`.
/// - `texture_key` — `TextureKey`.
/// - `entries` — `Vec<BatchEntry>`.
/// - `max_entries` — `usize`.
pub struct SpriteBatch {
    /// Key into `SharedState::textures`.
    texture_key: TextureKey,
    /// Queued sprite entries.
    entries: Vec<BatchEntry>,
    /// Maximum number of entries (0 = unlimited).
    max_entries: usize,
}

/// A single sprite in a batch, describing position, region, and transform.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `quad_x` — `f32`.
/// - `quad_y` — `f32`.
/// - `quad_w` — `f32`.
/// - `quad_h` — `f32`.
/// - `rotation` — `f32`.
/// - `sx` — `f32`.
/// - `sy` — `f32`.
/// - `ox` — `f32`.
/// - `oy` — `f32`.
pub struct BatchEntry {
    /// Screen X position.
    pub x: f32,
    /// Screen Y position.
    pub y: f32,
    /// Source quad X in the texture (pixels).
    pub quad_x: f32,
    /// Source quad Y in the texture (pixels).
    pub quad_y: f32,
    /// Source quad width (pixels). 0 = full texture width.
    pub quad_w: f32,
    /// Source quad height (pixels). 0 = full texture height.
    pub quad_h: f32,
    /// Rotation in radians.
    pub rotation: f32,
    /// Horizontal scale.
    pub sx: f32,
    /// Vertical scale.
    pub sy: f32,
    /// Origin X offset.
    pub ox: f32,
    /// Origin Y offset.
    pub oy: f32,
}

impl SpriteBatch {
    /// Creates a new empty sprite batch for the given texture.
    ///
    /// # Parameters
    /// - `texture_key` — `TextureKey`.
    /// - `max_entries` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(texture_key: TextureKey, max_entries: usize) -> Self {
        let cap = if max_entries > 0 { max_entries } else { 256 };
        SpriteBatch {
            texture_key,
            entries: Vec::with_capacity(cap),
            max_entries,
        }
    }

    /// Adds a sprite entry to the batch. Returns the index of the added entry.
    ///
    /// # Parameters
    /// - `entry` — `BatchEntry`.
    ///
    /// # Returns
    /// `Option<usize>`.
    ///
    /// Returns `None` if the batch is full (and `max_entries > 0`).
    pub fn add(&mut self, entry: BatchEntry) -> Option<usize> {
        if self.max_entries > 0 && self.entries.len() >= self.max_entries {
            return None;
        }
        let idx = self.entries.len();
        self.entries.push(entry);
        Some(idx)
    }

    /// Removes all entries from the batch. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Returns the texture key this batch draws from.
    ///
    /// # Returns
    /// `TextureKey`.
    pub fn texture_key(&self) -> TextureKey {
        self.texture_key
    }

    /// Returns a slice of all batch entries. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&[BatchEntry]`.
    pub fn entries(&self) -> &[BatchEntry] {
        &self.entries
    }

    /// Returns the number of entries in the batch.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Returns true if the batch has no entries.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Returns the maximum number of entries (buffer size). 0 means unlimited.
    ///
    /// # Returns
    /// `usize`.
    pub fn buffer_size(&self) -> usize {
        self.max_entries
    }
}
