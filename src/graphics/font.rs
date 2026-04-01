//! TTF/OTF font loading, glyph rasterization, and atlas packing for GPU text rendering.

use crate::engine::error::{EngineError, EngineResult};
use std::collections::HashMap;

/// Initial atlas dimensions in pixels.
const INITIAL_ATLAS_SIZE: u32 = 512;
/// Maximum atlas dimensions in pixels.
const MAX_ATLAS_SIZE: u32 = 2048;
/// Padding between glyphs in the atlas to prevent bleeding.
const GLYPH_PADDING: u32 = 1;

/// A loaded TTF/OTF font with a glyph atlas for GPU rendering.
///
/// Wraps a `fontdue::Font` for parsing and rasterization, caches rasterized
/// glyphs in a HashMap, and packs them into a row-based RGBA atlas bitmap.
pub struct Font {
    inner: fontdue::Font,
    size: f32,
    glyphs: HashMap<char, GlyphInfo>,
    atlas_bitmap: Vec<u8>,
    atlas_width: u32,
    atlas_height: u32,
    cursor_x: u32,
    cursor_y: u32,
    row_height: u32,
    line_height: f32,
    ascent: f32,
    descent: f32,
    dirty: bool,
}

/// Information about a single rasterized glyph in the atlas.
///
/// # Fields
/// - `uv_x` — `f32`.
/// - `uv_y` — `f32`.
/// - `uv_w` — `f32`.
/// - `uv_h` — `f32`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `advance_width` — `f32`.
/// - `offset_x` — `f32`.
/// - `offset_y` — `f32`.
///
/// Contains UV coordinates for sampling the atlas texture and metric
/// data for text layout (advance width, baseline offset).
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
    /// Parses a TTF/OTF font from raw bytes and pre-rasterizes printable ASCII glyphs.
    ///
    /// # Parameters
    /// - `data` — Raw font file bytes (TTF or OTF).
    /// - `size` — Font size in pixels.
    ///
    /// # Returns
    /// A `Font` with printable ASCII (32..=126) pre-rasterized, or an error string.
    pub fn from_bytes(data: &[u8], size: f32) -> EngineResult<Font> {
        let settings = fontdue::FontSettings {
            scale: size,
            ..fontdue::FontSettings::default()
        };
        let inner = fontdue::Font::from_bytes(data, settings)
            .map_err(|e| EngineError::RenderError(format!("Failed to parse font: {}", e)))?;

        let atlas_width = INITIAL_ATLAS_SIZE;
        let atlas_height = INITIAL_ATLAS_SIZE;
        let atlas_bitmap = vec![0u8; (atlas_width * atlas_height * 4) as usize];

        let metrics = inner.horizontal_line_metrics(size);
        let line_height = metrics
            .map(|m| m.ascent - m.descent + m.line_gap)
            .unwrap_or(size * 1.2);
        let ascent = metrics.map(|m| m.ascent).unwrap_or(size);
        let descent = metrics.map(|m| m.descent).unwrap_or(-size * 0.2);

        let mut font = Font {
            inner,
            size,
            glyphs: HashMap::new(),
            atlas_bitmap,
            atlas_width,
            atlas_height,
            cursor_x: 0,
            cursor_y: 0,
            row_height: 0,
            line_height,
            ascent,
            descent,
            dirty: true,
        };

        // Pre-rasterize printable ASCII
        for ch in ' '..='~' {
            font.ensure_glyph(ch);
        }

        Ok(font)
    }

    /// Ensures a glyph is rasterized and present in the atlas cache.
    ///
    /// If the character has already been rasterized, this is a no-op.
    /// Otherwise the glyph is rasterized via fontdue and packed into the atlas.
    ///
    /// # Parameters
    /// - `ch` — The character to rasterize.
    pub fn ensure_glyph(&mut self, ch: char) {
        if self.glyphs.contains_key(&ch) {
            return;
        }

        let (metrics, bitmap) = self.inner.rasterize(ch, self.size);

        let glyph_w = metrics.width as u32;
        let glyph_h = metrics.height as u32;

        // Handle zero-size glyphs (e.g. space)
        if glyph_w == 0 || glyph_h == 0 {
            let info = GlyphInfo {
                uv_x: 0.0,
                uv_y: 0.0,
                uv_w: 0.0,
                uv_h: 0.0,
                width: 0,
                height: 0,
                advance_width: metrics.advance_width,
                offset_x: metrics.xmin as f32,
                offset_y: metrics.ymin as f32,
            };
            self.glyphs.insert(ch, info);
            return;
        }

        // Check if glyph fits in current row
        if self.cursor_x + glyph_w + GLYPH_PADDING > self.atlas_width {
            // Move to next row
            self.cursor_y += self.row_height + GLYPH_PADDING;
            self.cursor_x = 0;
            self.row_height = 0;
        }

        // Check if we need to grow the atlas vertically
        if self.cursor_y + glyph_h > self.atlas_height {
            self.grow_atlas();
        }

        // Blit the single-channel alpha bitmap into the RGBA atlas
        let x0 = self.cursor_x;
        let y0 = self.cursor_y;
        for row in 0..glyph_h {
            for col in 0..glyph_w {
                let src_idx = (row * glyph_w + col) as usize;
                let alpha = bitmap[src_idx];
                let dst_x = x0 + col;
                let dst_y = y0 + row;
                let dst_idx = ((dst_y * self.atlas_width + dst_x) * 4) as usize;
                self.atlas_bitmap[dst_idx] = 255; // R
                self.atlas_bitmap[dst_idx + 1] = 255; // G
                self.atlas_bitmap[dst_idx + 2] = 255; // B
                self.atlas_bitmap[dst_idx + 3] = alpha; // A
            }
        }

        let info = GlyphInfo {
            uv_x: x0 as f32 / self.atlas_width as f32,
            uv_y: y0 as f32 / self.atlas_height as f32,
            uv_w: glyph_w as f32 / self.atlas_width as f32,
            uv_h: glyph_h as f32 / self.atlas_height as f32,
            width: glyph_w,
            height: glyph_h,
            advance_width: metrics.advance_width,
            offset_x: metrics.xmin as f32,
            offset_y: metrics.ymin as f32,
        };

        self.cursor_x += glyph_w + GLYPH_PADDING;
        if glyph_h > self.row_height {
            self.row_height = glyph_h;
        }

        self.glyphs.insert(ch, info);
        self.dirty = true;
    }

    /// Returns the total advance width of the given text string in pixels.
    ///
    /// Ensures all characters are rasterized before measuring.
    ///
    /// # Parameters
    /// - `text` — The text string to measure.
    ///
    /// # Returns
    /// The sum of advance widths for all characters.
    pub fn text_width(&mut self, text: &str) -> f32 {
        let mut width = 0.0;
        for ch in text.chars() {
            self.ensure_glyph(ch);
            if let Some(info) = self.glyphs.get(&ch) {
                width += info.advance_width;
            }
        }
        width
    }

    /// Returns the vertical line height (ascent - descent + line gap) in pixels.
    ///
    /// # Returns
    /// `f32`.
    pub fn line_height(&self) -> f32 {
        self.line_height
    }

    /// Sets the vertical line height in pixels.
    ///
    /// # Parameters
    /// - `height` — `f32`.
    pub fn set_line_height(&mut self, height: f32) {
        self.line_height = height;
    }

    /// Returns the font's ascent (distance from baseline to top) in pixels.
    ///
    /// # Returns
    /// `f32`.
    pub fn ascent(&self) -> f32 {
        self.ascent
    }

    /// Returns the font's descent (distance from baseline to bottom, typically negative) in pixels.
    ///
    /// # Returns
    /// `f32`.
    pub fn descent(&self) -> f32 {
        self.descent
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

    /// Returns glyph information for a character, rasterizing it on demand if needed.
    ///
    /// # Parameters
    /// - `ch` — The character to look up.
    ///
    /// # Returns
    /// A reference to the `GlyphInfo`, or `None` if rasterization fails.
    pub fn glyph(&mut self, ch: char) -> Option<&GlyphInfo> {
        self.ensure_glyph(ch);
        self.glyphs.get(&ch)
    }

    /// Returns the font size in pixels that this font was created with.
    ///
    /// # Returns
    /// `f32`.
    pub fn size(&self) -> f32 {
        self.size
    }

    /// Break text into lines that fit within `limit` pixel width.
    ///
    /// # Parameters
    /// - `text` — `&str`.
    /// - `limit` — `f32`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn wrap_text(&mut self, text: &str, limit: f32) -> Vec<String> {
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

    /// Doubles the atlas dimensions (up to `MAX_ATLAS_SIZE`) and copies existing data.
    fn grow_atlas(&mut self) {
        let new_width = (self.atlas_width * 2).min(MAX_ATLAS_SIZE);
        let new_height = (self.atlas_height * 2).min(MAX_ATLAS_SIZE);

        if new_width == self.atlas_width && new_height == self.atlas_height {
            log::warn!(
                "Font atlas at maximum size {}x{}, cannot grow further",
                MAX_ATLAS_SIZE,
                MAX_ATLAS_SIZE
            );
            return;
        }

        let mut new_bitmap = vec![0u8; (new_width * new_height * 4) as usize];

        // Copy existing rows into the new bitmap
        for row in 0..self.atlas_height {
            let src_start = (row * self.atlas_width * 4) as usize;
            let src_end = src_start + (self.atlas_width * 4) as usize;
            let dst_start = (row * new_width * 4) as usize;
            let dst_end = dst_start + (self.atlas_width * 4) as usize;
            new_bitmap[dst_start..dst_end].copy_from_slice(&self.atlas_bitmap[src_start..src_end]);
        }

        // Recalculate UVs for existing glyphs
        for info in self.glyphs.values_mut() {
            info.uv_x = info.uv_x * self.atlas_width as f32 / new_width as f32;
            info.uv_y = info.uv_y * self.atlas_height as f32 / new_height as f32;
            info.uv_w = info.uv_w * self.atlas_width as f32 / new_width as f32;
            info.uv_h = info.uv_h * self.atlas_height as f32 / new_height as f32;
        }

        self.atlas_bitmap = new_bitmap;
        self.atlas_width = new_width;
        self.atlas_height = new_height;
        self.dirty = true;
    }
}
