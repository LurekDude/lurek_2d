//! Post-processing effect stack.
//!
//! [`PostFxStack`] manages an ordered chain of effects that captures and
//! processes the rendered scene each frame.

use crate::engine::log_messages::{FX01, FX02};
use crate::log_msg;
/// An ordered chain of effects that captures and processes the rendered scene.
///
/// The full lifecycle every draw frame is:
/// 1. Call `beginCapture()` (Lua) — the GPU redirects draw calls to an
///    internal canvas.
/// 2. Draw the scene normally.
/// 3. Call `endCapture()` (Lua) — stops capture.
/// 4. Call `apply()` (Lua) — runs each enabled effect in insertion order
///    through ping-pong canvases and blits the final result to the screen.
///
/// Effects are referenced by numeric index into the local `effects` vector
/// in `LuaPostFxStack`. The `PostFxStack` itself is agnostic to the
/// concrete effect objects and only tracks indices, enabled states, and
/// canvas dimensions.
///
/// # Fields
/// - `effects` — Ordered list of effect indices (referencing external storage).
/// - `enabled` — Per-effect enable flag, parallel to `effects`.
/// - `width` — Internal canvas width in pixels.
/// - `height` — Internal canvas height in pixels.
///
/// The stack manages ping-pong canvases internally for multi-pass rendering.
/// During `lurek.draw`, the user calls `beginCapture()` → draws scene →
/// `endCapture()` → `apply()` to render the post-processed result.
pub struct PostFxStack {
    /// Ordered effect indices referencing external effect storage.
    pub effects: Vec<usize>,
    /// Per-effect enabled state (same length as `effects`).
    pub enabled: Vec<bool>,
    /// Width of the internal canvases in pixels.
    pub width: u32,
    /// Height of the internal canvases in pixels.
    pub height: u32,
    /// Whether the stack is currently capturing.
    pub capturing: bool,
}

impl PostFxStack {
    /// Creates a new post-processing stack with the given canvas dimensions.
    ///
    /// Starts empty with no effects, `capturing = false`, and the internal
    /// canvas dimensions set to `width` × `height`. Call `add` to append
    /// effects before the first `apply`.
    ///
    /// # Parameters
    /// - `width` — `u32` — Width of the internal capture canvas in pixels.
    /// - `height` — `u32` — Height of the internal capture canvas in pixels.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, FX01);
        Self {
            effects: Vec::new(),
            enabled: Vec::new(),
            width,
            height,
            capturing: false,
        }
    }

    /// Appends an effect index to the end of the chain.
    ///
    /// Effects are applied in insertion order during `apply()` — the first
    /// effect added is the first shader pass executed. The new effect is
    /// enabled by default.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize` — Index into the caller's effect storage.
    pub fn add(&mut self, effect_idx: usize) {
        log_msg!(debug, FX02);
        self.effects.push(effect_idx);
        self.enabled.push(true);
    }

    /// Removes an effect index from the chain.
    ///
    /// After removal all subsequent effects shift down by one position.
    /// The `enabled` parallel array is updated accordingly. If the same
    /// effect is in the chain multiple times, only the first occurrence is
    /// removed.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize` — Index to remove.
    ///
    /// # Returns
    /// `bool` — `true` if the effect was present and removed.
    pub fn remove(&mut self, effect_idx: usize) -> bool {
        if let Some(pos) = self.effects.iter().position(|&e| e == effect_idx) {
            self.effects.remove(pos);
            self.enabled.remove(pos);
            true
        } else {
            false
        }
    }

    /// Inserts an effect at a specific 1-based position.
    ///
    /// A `position` of 1 places the effect at the front of the chain
    /// (first to be applied). Values beyond the current chain length are
    /// clamped to the end — equivalent to `add`. The new effect is
    /// enabled by default.
    ///
    /// # Parameters
    /// - `position` — `usize` — 1-based insertion index; clamped to `[1, len+1]`.
    /// - `effect_idx` — `usize` — Index into the caller's effect storage.
    pub fn insert(&mut self, position: usize, effect_idx: usize) {
        let idx = (position.saturating_sub(1)).min(self.effects.len());
        self.effects.insert(idx, effect_idx);
        self.enabled.insert(idx, true);
    }

    /// Sets the enabled state for an effect in the chain.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize`.
    /// - `is_enabled` — `bool`.
    pub fn set_enabled(&mut self, effect_idx: usize, is_enabled: bool) {
        if let Some(pos) = self.effects.iter().position(|&e| e == effect_idx) {
            self.enabled[pos] = is_enabled;
        }
    }

    /// Gets the enabled state for an effect in the chain.
    ///
    /// # Parameters
    /// - `effect_idx` — `usize`.
    ///
    /// # Returns
    /// `bool` — `false` if the effect is not in the chain.
    pub fn is_enabled(&self, effect_idx: usize) -> bool {
        self.effects
            .iter()
            .position(|&e| e == effect_idx)
            .map(|pos| self.enabled[pos])
            .unwrap_or(false)
    }

    /// Returns the number of effects in the chain.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_effect_count(&self) -> usize {
        self.effects.len()
    }

    /// Returns the effect index at a 1-based position.
    ///
    /// # Parameters
    /// - `index` — `usize` — 1-based.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn get_effect(&self, index: usize) -> Option<usize> {
        if index >= 1 && index <= self.effects.len() {
            Some(self.effects[index - 1])
        } else {
            None
        }
    }

    /// Returns the indices of all enabled effects in order.
    ///
    /// Called by the `lua_api` GPU layer during `apply()` to determine
    /// which shader passes to execute. Only effects with their per-position
    /// `enabled` flag set to `true` are included; disabled effects are
    /// skipped entirely without affecting their position in the chain.
    ///
    /// # Returns
    /// `Vec<usize>` — Effect indices in application order.
    pub fn enabled_effects(&self) -> Vec<usize> {
        self.effects
            .iter()
            .zip(self.enabled.iter())
            .filter(|(_, &en)| en)
            .map(|(&idx, _)| idx)
            .collect()
    }

    /// Resizes the internal canvas dimensions.
    ///
    /// Call this when the window or render target is resized so that the
    /// ping-pong canvases can be recreated at the correct resolution by the
    /// GPU layer. Does not affect any effects in the chain.
    ///
    /// # Parameters
    /// - `width` — `u32` — New canvas width in pixels.
    /// - `height` — `u32` — New canvas height in pixels.
    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }

    /// Returns the canvas width.
    ///
    /// Reflects the last value set via `new` or `resize`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Returns the canvas height.
    ///
    /// Reflects the last value set via `new` or `resize`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_height(&self) -> u32 {
        self.height
    }

    /// Returns both canvas dimensions as `(width, height)`.
    ///
    /// Convenience accessor combining `get_width()` and `get_height()`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Returns the number of effects currently in the chain.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.effects.len()
    }

    /// Returns `true` if the chain contains no effects.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.effects.is_empty()
    }

    /// Removes all effects from the chain.
    pub fn clear(&mut self) {
        self.effects.clear();
        self.enabled.clear();
    }

    // ── CPU rendering ──

    /// Renders a diagnostic image showing the effect stack layout.
    ///
    /// Each effect slot is drawn as a labelled box: green when enabled,
    /// red with an X when disabled. Useful for evidence tests.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn render_info_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);

        let count = self.effects.len();
        if count == 0 {
            img.draw_label("EMPTY STACK", 10, 10, 180, 180, 190);
            return img;
        }

        let box_gap = 10u32;
        let total_gap = box_gap * (count as u32 + 1);
        let box_w = if count > 0 {
            (width.saturating_sub(total_gap)) / count as u32
        } else {
            60
        };
        let box_h = height.saturating_sub(60).min(100);
        let box_y = (height - box_h) / 2;

        for (i, &_effect_idx) in self.effects.iter().enumerate() {
            let bx = box_gap + i as u32 * (box_w + box_gap);
            let enabled = self.enabled.get(i).copied().unwrap_or(false);

            let (r, g, b) = if enabled {
                (80u8, 200u8, 80u8)
            } else {
                (200u8, 60u8, 60u8)
            };

            // Box background
            img.draw_rect(bx as i32, box_y as i32, box_w, box_h, r / 3, g / 3, b / 3, 200);
            // Top/bottom borders
            img.draw_rect(bx as i32, box_y as i32, box_w, 2, r, g, b, 255);
            img.draw_rect(
                bx as i32,
                (box_y + box_h - 2) as i32,
                box_w,
                2,
                r,
                g,
                b,
                255,
            );

            // X on disabled
            if !enabled {
                img.draw_line(
                    bx as i32 + 10,
                    box_y as i32 + 10,
                    (bx + box_w) as i32 - 10,
                    (box_y + box_h) as i32 - 10,
                    200,
                    60,
                    60,
                    255,
                );
                img.draw_line(
                    (bx + box_w) as i32 - 10,
                    box_y as i32 + 10,
                    bx as i32 + 10,
                    (box_y + box_h) as i32 - 10,
                    200,
                    60,
                    60,
                    255,
                );
            }

            // Index label
            let label = format!("FX{}", i);
            img.draw_label(&label, bx as i32 + 4, box_y as i32 + 4, r, g, b);
        }

        img
    }
}
