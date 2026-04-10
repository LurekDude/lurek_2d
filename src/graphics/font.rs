//! Bitmap font loading and glyph lookup for GPU text rendering.
//!
//! This module provides embedded bitmap/pixel fonts loaded from PNG sprite sheets.
//! Each font is a fixed-width grid of glyphs covering ASCII printable characters
//! and optionally Unicode box-drawing characters (U+2500–2580).
//!
//! Key types exported from this module: `Font`, `GlyphInfo`.
//! Primary functions: `from_png_bytes()`, `load_all_sizes()`, `glyph()`, `text_width()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::engine::error::{EngineError, EngineResult};

// ── Embedded bitmap font PNGs ────────────────────────────────────────────────────────────────────
const FONT_3X5: &[u8] = include_bytes!("../../assets/fonts/bitmap_3x5.png");
const FONT_5X7: &[u8] = include_bytes!("../../assets/fonts/bitmap_5x7.png");
const FONT_6X10: &[u8] = include_bytes!("../../assets/fonts/bitmap_6x10.png");
const FONT_8X14: &[u8] = include_bytes!("../../assets/fonts/bitmap_8x14.png");
const FONT_10X18: &[u8] = include_bytes!("../../assets/fonts/bitmap_10x18.png");
const FONT_12X22: &[u8] = include_bytes!("../../assets/fonts/bitmap_12x22.png");

/// Available font pixel heights, smallest to largest.
pub const AVAILABLE_HEIGHTS: [u32; 6] = [5, 7, 10, 14, 18, 22];

/// Available font cell sizes as `(width, height)` pairs, matching `AVAILABLE_HEIGHTS` order.
pub const AVAILABLE_CELL_SIZES: [(u32, u32); 6] = [
    (3, 5),
    (5, 7),
    (6, 10),
    (8, 14),
    (10, 18),
    (12, 22),
];

/// A bitmap font loaded from an embedded PNG sprite sheet.
///
/// Glyph positions are computed from grid coordinates — no HashMap cache needed.
/// The atlas bitmap is the decoded RGBA image data from the PNG.
///
/// # Fields
/// - `atlas_bitmap` — `Vec<u8>`. RGBA pixel data decoded from the PNG sprite sheet.
/// - `atlas_width` — `u32`. Width of the atlas in pixels.
/// - `atlas_height` — `u32`. Height of the atlas in pixels.
/// - `cell_width` — `u32`. Width of each glyph cell in pixels.
/// - `cell_height` — `u32`. Height of each glyph cell in pixels.
/// - `has_box_drawing` — `bool`. Whether this font includes box-drawing characters.
/// - `line_height_mul` — `f32`. Multiplier for line spacing (default 1.0).
/// - `dirty` — `bool`. True when atlas data needs GPU re-upload.
pub struct Font {
    atlas_bitmap: Vec<u8>,
    atlas_width: u32,
    atlas_height: u32,
    cell_width: u32,
    cell_height: u32,
    has_box_drawing: bool,
    line_height_mul: f32,
    dirty: bool,
}

/// Information about a single glyph in the atlas.
///
/// Contains UV coordinates for sampling the atlas texture and metric
/// data for text layout (advance width, baseline offset).
///
/// # Fields
/// - `uv_x` — `f32`. U coordinate of the glyph's left edge (normalized 0.0..1.0).
/// - `uv_y` — `f32`. V coordinate of the glyph's top edge (normalized 0.0..1.0).
/// - `uv_w` — `f32`. Width of the glyph region (normalized 0.0..1.0).
/// - `uv_h` — `f32`. Height of the glyph region (normalized 0.0..1.0).
/// - `width` — `u32`. Pixel width of the glyph.
/// - `height` — `u32`. Pixel height of the glyph.
/// - `advance_width` — `f32`. Horizontal advance after this glyph.
/// - `offset_x` — `f32`. Horizontal offset from cursor to glyph left edge.
/// - `offset_y` — `f32`. Vertical offset from baseline to glyph top edge.
#[derive(Debug, Clone, Copy)]
pub struct GlyphInfo {
    /// U coordinate of the glyph's left edge in the atlas (normalized 0.0..1.0).
    pub uv_x: f32,
    /// V coordinate of the glyph's top edge in the atlas (normalized 0.0..1.0).
    pub uv_y: f32,
    /// Width of the glyph region in the atlas (normalized 0.0..1.0).
    pub uv_w: f32,
    /// Height of the glyph region in the atlas (normalized 0.0..1.0).
    pub uv_h: f32,
    /// Pixel width of the glyph bitmap.
    pub width: u32,
    /// Pixel height of the glyph bitmap.
    pub height: u32,
    /// Horizontal advance (how far to move the cursor after this glyph).
    pub advance_width: f32,
    /// Horizontal offset from the cursor position to the glyph's left edge.
    pub offset_x: f32,
    /// Vertical offset from the baseline to the glyph's top edge.
    pub offset_y: f32,
}

impl Font {
    /// Creates a bitmap font from raw PNG bytes.
    ///
    /// Decodes the PNG into RGBA pixel data and stores it as the atlas bitmap.
    /// The sprite sheet must be a grid of `cell_w` x `cell_h` cells, 16 columns wide.
    ///
    /// # Parameters
    /// - `data` — Raw PNG file bytes.
    /// - `cell_w` — Width of each glyph cell in pixels.
    /// - `cell_h` — Height of each glyph cell in pixels.
    /// - `has_box` — Whether the sheet includes box-drawing rows.
    ///
    /// # Returns
    /// `EngineResult<Font>`.
    pub fn from_png_bytes(data: &[u8], cell_w: u32, cell_h: u32, has_box: bool) -> EngineResult<Font> {
        let img = image::load_from_memory(data)
            .map_err(|e| EngineError::RenderError(format!("Failed to decode bitmap font PNG: {}", e)))?
            .to_rgba8();

        let atlas_width = img.width();
        let atlas_height = img.height();
        let atlas_bitmap = img.into_raw();

        Ok(Font {
            atlas_bitmap,
            atlas_width,
            atlas_height,
            cell_width: cell_w,
            cell_height: cell_h,
            has_box_drawing: has_box,
            line_height_mul: 1.0,
            dirty: true,
        })
    }

    /// Loads all 6 built-in bitmap font sizes from embedded PNGs.
    ///
    /// # Returns
    /// `Vec<(Font, u32, u32)>` — Each entry is `(font, cell_width, cell_height)`.
    pub fn load_all_sizes() -> Vec<(Font, u32, u32)> {
        let specs: [(u32, u32, &[u8], bool); 6] = [
            (3, 5, FONT_3X5, false),
            (5, 7, FONT_5X7, false),
            (6, 10, FONT_6X10, true),
            (8, 14, FONT_8X14, true),
            (10, 18, FONT_10X18, true),
            (12, 22, FONT_12X22, true),
        ];

        specs
            .iter()
            .filter_map(|&(cw, ch, data, has_box)| {
                match Font::from_png_bytes(data, cw, ch, has_box) {
                    Ok(font) => Some((font, cw, ch)),
                    Err(e) => {
                        log::warn!("Failed to load bitmap font {}x{}: {}", cw, ch, e);
                        None
                    }
                }
            })
            .collect()
    }

    /// Returns the index into `AVAILABLE_HEIGHTS` for the nearest matching font size.
    ///
    /// # Parameters
    /// - `pixel_height` — Desired font height in pixels.
    ///
    /// # Returns
    /// Index into `AVAILABLE_HEIGHTS` / `AVAILABLE_CELL_SIZES`.
    pub fn nearest_size(pixel_height: u32) -> usize {
        let mut best = 0;
        let mut best_diff = u32::MAX;
        for (i, &h) in AVAILABLE_HEIGHTS.iter().enumerate() {
            let diff = pixel_height.abs_diff(h);
            if diff < best_diff {
                best_diff = diff;
                best = i;
            }
        }
        best
    }

    /// Returns the grid position `(col, row)` for a character in the sprite sheet.
    fn glyph_position(&self, ch: char) -> Option<(u32, u32)> {
        let cp = ch as u32;
        if (0x20..0x80).contains(&cp) {
            let idx = cp - 0x20;
            Some((idx % 16, idx / 16))
        } else if (0x2500..0x2580).contains(&cp) && self.has_box_drawing {
            let idx = cp - 0x2500;
            Some((idx % 16, 6 + idx / 16))
        } else {
            None
        }
    }

    /// Returns glyph information for a character by computing its UV from the grid position.
    ///
    /// # Parameters
    /// - `ch` — The character to look up.
    ///
    /// # Returns
    /// `Option<GlyphInfo>`, or `None` if the character is not in this font's sprite sheet.
    pub fn glyph(&self, ch: char) -> Option<GlyphInfo> {
        let (col, row) = self.glyph_position(ch)?;

        let px_x = col * self.cell_width;
        let px_y = row * self.cell_height;

        Some(GlyphInfo {
            uv_x: px_x as f32 / self.atlas_width as f32,
            uv_y: px_y as f32 / self.atlas_height as f32,
            uv_w: self.cell_width as f32 / self.atlas_width as f32,
            uv_h: self.cell_height as f32 / self.atlas_height as f32,
            width: self.cell_width,
            height: self.cell_height,
            advance_width: self.cell_width as f32,
            offset_x: 0.0,
            offset_y: 0.0,
        })
    }

    /// Returns the total advance width of the given text string in pixels.
    ///
    /// # Parameters
    /// - `text` — The text string to measure.
    ///
    /// # Returns
    /// The sum of advance widths for all characters. Unknown characters are skipped.
    pub fn text_width(&self, text: &str) -> f32 {
        let mut width = 0.0f32;
        for ch in text.chars() {
            if let Some(info) = self.glyph(ch) {
                width += info.advance_width;
            }
        }
        width
    }

    /// Returns the vertical line height in pixels (cell_height x line_height_mul).
    ///
    /// # Returns
    /// `f32`.
    pub fn line_height(&self) -> f32 {
        self.cell_height as f32 * self.line_height_mul
    }

    /// Sets the line height multiplier.
    ///
    /// # Parameters
    /// - `mul` — `f32`. Multiplier applied to `cell_height` for line spacing.
    pub fn set_line_height(&mut self, mul: f32) {
        self.line_height_mul = mul;
    }

    /// Returns the font's ascent (cell_height as f32, for backwards compatibility).
    ///
    /// # Returns
    /// `f32`.
    pub fn ascent(&self) -> f32 {
        self.cell_height as f32
    }

    /// Returns the font's descent (0.0 for bitmap fonts, for backwards compatibility).
    ///
    /// # Returns
    /// `f32`.
    pub fn descent(&self) -> f32 {
        0.0
    }

    /// Returns the atlas RGBA pixel data and its dimensions.
    ///
    /// # Returns
    /// A tuple of `(rgba_data, width, height)` suitable for GPU texture upload.
    pub fn atlas_data(&self) -> (&[u8], u32, u32) {
        (&self.atlas_bitmap, self.atlas_width, self.atlas_height)
    }

    /// Returns `true` if the atlas has been modified since the last `mark_clean()` call.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }

    /// Marks the atlas as clean (no pending changes to upload).
    pub fn mark_clean(&mut self) {
        self.dirty = false;
    }

    /// Returns the font cell height as f32 (the effective "size" of this bitmap font).
    ///
    /// # Returns
    /// `f32`.
    pub fn size(&self) -> f32 {
        self.cell_height as f32
    }

    /// Returns the glyph cell width in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn cell_width(&self) -> u32 {
        self.cell_width
    }

    /// Returns whether this font includes box-drawing characters.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_box_drawing(&self) -> bool {
        self.has_box_drawing
    }

    /// Breaks text into lines that fit within `limit` pixel width.
    ///
    /// # Parameters
    /// - `text` — `&str`.
    /// - `limit` — `f32`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn wrap_text(&self, text: &str, limit: f32) -> Vec<String> {
        let mut lines = Vec::new();
        for line in text.split('\n') {
            if line.is_empty() {
                lines.push(String::new());
                continue;
            }
            let words: Vec<&str> = line.split_whitespace().collect();
            if words.is_empty() {
                lines.push(String::new());
                continue;
            }
            let mut current_line = String::new();
            for word in words {
                let test = if current_line.is_empty() {
                    word.to_string()
                } else {
                    format!("{} {}", current_line, word)
                };
                let width = self.text_width(&test);
                if width > limit && !current_line.is_empty() {
                    lines.push(current_line);
                    current_line = word.to_string();
                } else {
                    current_line = test;
                }
            }
            if !current_line.is_empty() {
                lines.push(current_line);
            }
        }
        if lines.is_empty() {
            lines.push(String::new());
        }
        lines
    }
}
