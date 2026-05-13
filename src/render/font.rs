use crate::runtime::error::{EngineError, EngineResult};
const FONT_3X5: &[u8] = include_bytes!("../../assets/fonts/bitmap_3x5.png");
const FONT_5X7: &[u8] = include_bytes!("../../assets/fonts/bitmap_5x7.png");
const FONT_6X10: &[u8] = include_bytes!("../../assets/fonts/bitmap_6x10.png");
const FONT_8X14: &[u8] = include_bytes!("../../assets/fonts/bitmap_8x14.png");
const FONT_10X18: &[u8] = include_bytes!("../../assets/fonts/bitmap_10x18.png");
const FONT_12X22: &[u8] = include_bytes!("../../assets/fonts/bitmap_12x22.png");
pub const AVAILABLE_HEIGHTS: [u32; 6] = [5, 7, 10, 14, 18, 22];
pub const AVAILABLE_CELL_SIZES: [(u32, u32); 6] =
    [(3, 5), (5, 7), (6, 10), (8, 14), (10, 18), (12, 22)];
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
#[derive(Debug, Clone, Copy)]
pub struct GlyphInfo {
    pub uv_x: f32,
    pub uv_y: f32,
    pub uv_w: f32,
    pub uv_h: f32,
    pub width: u32,
    pub height: u32,
    pub advance_width: f32,
    pub offset_x: f32,
    pub offset_y: f32,
}
impl Font {
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
    pub fn text_width(&self, text: &str) -> f32 {
        let mut width = 0.0f32;
        for ch in text.chars() {
            if let Some(info) = self.glyph(ch) {
                width += info.advance_width;
            }
        }
        width
    }
    pub fn line_height(&self) -> f32 {
        self.cell_height as f32 * self.line_height_mul
    }
    pub fn set_line_height(&mut self, mul: f32) {
        self.line_height_mul = mul;
    }
    pub fn ascent(&self) -> f32 {
        self.cell_height as f32
    }
    pub fn descent(&self) -> f32 {
        0.0
    }
    pub fn atlas_data(&self) -> (&[u8], u32, u32) {
        (&self.atlas_bitmap, self.atlas_width, self.atlas_height)
    }
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }
    pub fn mark_clean(&mut self) {
        self.dirty = false;
    }
    pub fn size(&self) -> f32 {
        self.cell_height as f32
    }
    pub fn cell_width(&self) -> u32 {
        self.cell_width
    }
    pub fn has_box_drawing(&self) -> bool {
        self.has_box_drawing
    }
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
