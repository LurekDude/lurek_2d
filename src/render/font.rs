//! Bitmap font loader, glyph atlas wrapper, and text metrics for the render layer.
//! Bundles six fixed-size PNG bitmap fonts (3×5 – 12×22), provides glyph UV lookup,
//! pixel-width measurement, and word-wrap. Does not own GPU texture state.

use crate::runtime::error::{EngineError, EngineResult};
/// Embedded PNG data for the 3×5 bitmap font.
const FONT_3X5: &[u8] = include_bytes!("../../assets/fonts/bitmap_3x5.png");
/// Embedded PNG data for the 5×7 bitmap font.
const FONT_5X7: &[u8] = include_bytes!("../../assets/fonts/bitmap_5x7.png");
/// Embedded PNG data for the 6×10 bitmap font.
const FONT_6X10: &[u8] = include_bytes!("../../assets/fonts/bitmap_6x10.png");
/// Embedded PNG data for the 8×14 bitmap font.
const FONT_8X14: &[u8] = include_bytes!("../../assets/fonts/bitmap_8x14.png");
/// Embedded PNG data for the 10×18 bitmap font.
const FONT_10X18: &[u8] = include_bytes!("../../assets/fonts/bitmap_10x18.png");
/// Embedded PNG data for the 12×22 bitmap font.
const FONT_12X22: &[u8] = include_bytes!("../../assets/fonts/bitmap_12x22.png");
/// Cell heights (pixels) for each bundled bitmap font size.
pub const AVAILABLE_HEIGHTS: [u32; 6] = [5, 7, 10, 14, 18, 22];
/// `(cell_width, cell_height)` pairs for each bundled bitmap font size.
pub const AVAILABLE_CELL_SIZES: [(u32, u32); 6] =
    [(3, 5), (5, 7), (6, 10), (8, 14), (10, 18), (12, 22)];
/// Bitmap font atlas loaded from a PNG sprite sheet; queried for per-character UV rects.
pub struct Font {
    /// Raw RGBA pixel data for the glyph atlas texture.
    atlas_bitmap: Vec<u8>,
    /// Width of the atlas texture in pixels.
    atlas_width: u32,
    /// Height of the atlas texture in pixels.
    atlas_height: u32,
    /// Width of a single character cell in pixels.
    cell_width: u32,
    /// Height of a single character cell in pixels.
    cell_height: u32,
    /// True when this font atlas includes Unicode box-drawing glyphs (U+2500–U+257F).
    has_box_drawing: bool,
    /// Multiplier applied to `cell_height` when computing line height; default 1.0.
    line_height_mul: f32,
    /// True when atlas pixel data has not yet been uploaded to the GPU.
    dirty: bool,
}
/// UV-space coordinates and pixel metrics for a single bitmap glyph.
#[derive(Debug, Clone, Copy)]
pub struct GlyphInfo {
    /// Left UV edge of the glyph cell in the atlas, 0.0..1.0.
    pub uv_x: f32,
    /// Top UV edge of the glyph cell in the atlas, 0.0..1.0.
    pub uv_y: f32,
    /// UV width of the glyph cell, 0.0..1.0.
    pub uv_w: f32,
    /// UV height of the glyph cell, 0.0..1.0.
    pub uv_h: f32,
    /// Pixel width of the glyph.
    pub width: u32,
    /// Pixel height of the glyph.
    pub height: u32,
    /// Pixel advance width (kerning step after this glyph).
    pub advance_width: f32,
    /// Pixel X offset from pen position to glyph origin.
    pub offset_x: f32,
    /// Pixel Y offset from pen baseline to glyph top.
    pub offset_y: f32,
}
impl Font {
    /// Load and decode `data` as a PNG bitmap font atlas with `cell_w`×`cell_h` cells; return error on decode failure.
    pub fn from_png_bytes(
        data: &[u8],
        cell_w: u32,
        cell_h: u32,
        has_box: bool,
    ) -> EngineResult<Font> {
        let img = image::load_from_memory(data)
            .map_err(|e| {
                EngineError::RenderError(format!("Failed to decode bitmap font PNG: {}", e))
            })?
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
    /// Load all six bundled bitmap font sizes; silently skip any that fail to decode.
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
    /// Return the index into `AVAILABLE_HEIGHTS` whose cell height is closest to `pixel_height`.
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
    /// Return the atlas `(col, row)` grid position for `ch`, or `None` if unsupported.
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
    /// Return `GlyphInfo` for `ch`, or `None` if the character is not in the atlas.
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
            advance_width: self.cell_width as f32 + 1.0,
            offset_x: 0.0,
            offset_y: 0.0,
        })
    }
    /// Return the pixel advance-width sum for all glyphs in `text`.
    pub fn text_width(&self, text: &str) -> f32 {
        let mut width = 0.0f32;
        for ch in text.chars() {
            if let Some(info) = self.glyph(ch) {
                width += info.advance_width;
            }
        }
        width
    }
    /// Return `cell_height * line_height_mul` as the vertical line spacing in pixels.
    pub fn line_height(&self) -> f32 {
        self.cell_height as f32 * self.line_height_mul
    }
    /// Set the line-height multiplier applied over `cell_height`.
    pub fn set_line_height(&mut self, mul: f32) {
        self.line_height_mul = mul;
    }
    /// Return `cell_height` as the ascent value in pixels.
    pub fn ascent(&self) -> f32 {
        self.cell_height as f32
    }
    /// Return 0.0; bitmap fonts have no descender in this implementation.
    pub fn descent(&self) -> f32 {
        0.0
    }
    /// Return `(pixel_data, width, height)` for the atlas texture upload.
    pub fn atlas_data(&self) -> (&[u8], u32, u32) {
        (&self.atlas_bitmap, self.atlas_width, self.atlas_height)
    }
    /// Return true when the atlas pixel data has not yet been uploaded to the GPU.
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }
    /// Clear the dirty flag after a successful GPU texture upload.
    pub fn mark_clean(&mut self) {
        self.dirty = false;
    }
    /// Return the pixel height of one character cell.
    pub fn size(&self) -> f32 {
        self.cell_height as f32
    }
    /// Return the pixel width of one character cell.
    pub fn cell_width(&self) -> u32 {
        self.cell_width
    }
    /// Return true when this font atlas contains Unicode box-drawing glyphs.
    pub fn has_box_drawing(&self) -> bool {
        self.has_box_drawing
    }
    /// Break `text` into lines that each fit within `limit` pixels, honouring existing newlines.
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
