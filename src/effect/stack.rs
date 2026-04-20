//! Post-processing effect stack.
//!
//! [`PostFxStack`] manages an ordered chain of effects that captures and
//! processes the rendered scene each frame.

use crate::runtime::log_messages::{FX01, FX02};
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
#[derive(Debug, Clone)]
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

    /// Removes duplicate effect indices from the chain, keeping the first occurrence
    /// of each index and discarding subsequent duplicates.
    ///
    /// This is useful for reducing redundant wgpu shader passes when the same effect
    /// has been added more than once.
    ///
    /// # Returns
    /// `usize` — the number of duplicate entries removed.
    pub fn dedup_indices(&mut self) -> usize {
        let mut seen = std::collections::HashSet::new();
        let before = self.effects.len();
        let mut new_effects = Vec::with_capacity(before);
        let mut new_enabled = Vec::with_capacity(before);
        for (idx, enabled) in self.effects.iter().zip(self.enabled.iter()) {
            if seen.insert(*idx) {
                new_effects.push(*idx);
                new_enabled.push(*enabled);
            }
        }
        let removed = before - new_effects.len();
        self.effects = new_effects;
        self.enabled = new_enabled;
        removed
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
    pub fn draw_info_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
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

    /// Render the stack state as two side-by-side column layouts.
    ///
    /// Shows the initial effect list on the left and the current
    /// (possibly modified) list on the right, with enabled/disabled
    /// indicators.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `labels` — `&[&str]`. Display name per effect slot.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_stack_management_to_image(
        &self,
        width: u32,
        height: u32,
        labels: &[&str],
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        img.draw_label("STACK OPS", (width / 2 - 30) as i32, 4, 200, 180, 255);

        for i in 0..self.effects.len() {
            let y = 24 + i as i32 * 22;
            let enabled = self.enabled.get(i).copied().unwrap_or(false);
            let (cr, cg, cb) = if enabled {
                (80u8, 200u8, 80u8)
            } else {
                (200u8, 80u8, 80u8)
            };
            img.draw_rect(10, y, (width - 20).min(300), 18, cr / 5, cg / 5, cb / 5, 255);
            let label = labels.get(i).copied().unwrap_or("FX");
            let text = format!("{} - {}", label, if enabled { "ON" } else { "OFF" });
            img.draw_label(&text, 14, y + 4, cr, cg, cb);
        }
        img
    }

    /// Render a catalog grid of effect types with representative visual patterns.
    ///
    /// Creates a 4-column grid of panels, one per effect type entry in `entries`.
    /// Each entry gets a label and a filled pattern block.
    ///
    /// # Parameters
    /// - `entries` — `&[(&str, (u8, u8, u8))]`. Effect name and color per slot.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_effect_catalog_to_image(
        entries: &[(&str, (u8, u8, u8))],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        img.draw_label("POSTFX CATALOG", (width / 2 - 40) as i32, 4, 220, 180, 255);

        let cols = 4u32;
        let cell_w = width / cols;
        let rows = (entries.len() as u32).div_ceil(cols);
        let cell_h = if rows > 0 {
            (height - 20) / rows
        } else {
            height
        };

        for (i, &(label, (cr, cg, cb))) in entries.iter().enumerate() {
            let col = (i as u32) % cols;
            let row = (i as u32) / cols;
            let px = col * cell_w;
            let py = 20 + row * cell_h;
            img.draw_rect(
                (px + 2) as i32, (py + 2) as i32,
                cell_w - 4, cell_h - 4,
                cr / 5, cg / 5, cb / 5, 200,
            );
            img.draw_label(label, (px + 4) as i32, (py + 4) as i32, cr, cg, cb);
        }
        img
    }

    /// Render a parameter showcase grid for PostFx effects.
    ///
    /// Each entry produces a row showing the effect label and its
    /// `(name, value)` parameter pairs.
    ///
    /// # Parameters
    /// - `entries` — `&[(&str, &[(&str, f32)])]`. Effect name and param list.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `crate::image::ImageData`.
    pub fn draw_effect_parameters_to_image(
        entries: &[(&str, &[(&str, f32)])],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        let title_x = width.saturating_sub(76) / 2;
        img.draw_label("POSTFX PARAMETERS", title_x as i32, 4, 200, 180, 255);

        let mut y = 24i32;
        for &(label, params) in entries {
            if y + 52 > height as i32 {
                break;
            }
            img.draw_rect(10, y, width - 20, 50, 30, 28, 42, 255);
            img.draw_label(label, 14, y + 4, 220, 180, 100);

            let mut px = 14i32;
            for &(name, val) in params {
                let text = format!("{}:{:.1}", name.to_uppercase(), val);
                img.draw_label(&text, px, y + 18, 100, 200, 100);
                px += (text.len() as i32 + 1) * 4;
            }
            y += 58;
        }
        img
    }

    /// Render a bar preview for a small set of PostFx effect types.
    ///
    /// Draws one coloured row per entry with dot markers for parameter count.
    /// Suitable for showing 4–8 built-in effect types side-by-side in evidence
    /// tests.
    ///
    /// # Parameters
    /// - `entries` — `&[(&str, (u8, u8, u8), usize)]`. (label, colour, param_count).
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `crate::image::ImageData`.
    pub fn draw_effect_type_bars_to_image(
        entries: &[(&str, (u8, u8, u8), usize)],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);
        img.draw_label("POSTFX EFFECT TYPES", (width / 2).saturating_sub(60) as i32, 4, 200, 180, 255);

        let row_h = if entries.is_empty() { height } else { (height - 20) / entries.len() as u32 };

        for (i, &(label, (cr, cg, cb), param_count)) in entries.iter().enumerate() {
            let y_base = (20 + i as u32 * row_h) as i32;
            let row_h_i = row_h.saturating_sub(4);
            img.draw_rect(20, y_base, width - 40, row_h_i, cr / 3, cg / 3, cb / 3, 200);
            img.draw_rect(20, y_base, width - 40, 2, cr, cg, cb, 255);
            img.draw_label(label, 28, y_base + 4, cr, cg, cb);
            for p in 0..param_count {
                let dot_x = 40 + p as i32 * 20;
                let dot_y = y_base + row_h as i32 / 2;
                img.draw_circle(dot_x, dot_y, 5, cr, cg, cb, 255);
            }
        }
        img
    }

    /// Render a bar preview for a list of PostFx effect types,
    /// auto-assigning colours and counting parameters.
    ///
    /// Each type is instantiated to query its parameter names, then
    /// drawn as a coloured row with dot indicators for parameter count.
    ///
    /// # Parameters
    /// - `types` — `&[PostFxEffectType]`. Effect types to visualise.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `crate::image::ImageData`.
    pub fn draw_effect_types_to_image(
        types: &[super::PostFxEffectType],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let palette: &[(u8, u8, u8)] = &[
            (180, 80, 80), (80, 180, 80), (80, 80, 180), (180, 180, 80),
            (180, 80, 180), (80, 180, 180), (200, 130, 60), (130, 60, 200),
        ];
        let entries: Vec<(&str, (u8, u8, u8), usize)> = types
            .iter()
            .enumerate()
            .map(|(i, t)| {
                let effect = super::PostFxEffect::new(*t);
                let param_count = effect.get_parameter_names().len();
                let label: &str = match t {
                    super::PostFxEffectType::Vignette => "VIGNETTE",
                    super::PostFxEffectType::Grayscale => "GRAYSCALE",
                    super::PostFxEffectType::Chromatic => "CHROMATIC",
                    super::PostFxEffectType::Blur => "BLUR",
                    super::PostFxEffectType::Pixelate => "PIXELATE",
                    super::PostFxEffectType::Invert => "INVERT",
                    super::PostFxEffectType::Sepia => "SEPIA",
                    super::PostFxEffectType::Scanlines => "SCANLINES",
                    super::PostFxEffectType::Bloom => "BLOOM",
                    super::PostFxEffectType::Crt => "CRT",
                    super::PostFxEffectType::Godrays => "GODRAYS",
                    super::PostFxEffectType::ColourGrade => "COLOUR_GRADE",
                    super::PostFxEffectType::EdgeDetect => "EDGE_DETECT",
                    super::PostFxEffectType::HueShift => "HUE_SHIFT",
                    super::PostFxEffectType::Noise => "NOISE",
                    super::PostFxEffectType::Custom => "CUSTOM",
                    super::PostFxEffectType::DepthOfField => "DEPTH_OF_FIELD",
                    super::PostFxEffectType::MotionBlur => "MOTION_BLUR",
                    super::PostFxEffectType::PaletteSwap => "PALETTE_SWAP",
                    super::PostFxEffectType::ColorLut => "COLOR_LUT",
                    super::PostFxEffectType::WaterDistort => "WATER_DISTORT",
                    super::PostFxEffectType::Sharpen => "SHARPEN",
                    super::PostFxEffectType::Dither => "DITHER",
                    super::PostFxEffectType::Outline => "OUTLINE",
                };
                let color = palette[i % palette.len()];
                (label, color, param_count)
            })
            .collect();
        Self::draw_effect_type_bars_to_image(&entries, width, height)
    }

}
