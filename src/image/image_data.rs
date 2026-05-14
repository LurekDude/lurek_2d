
use crate::log_msg;
use crate::runtime::log_messages::{IM01_IMAGE_LOADED, IM02_IMAGE_MISMATCH};
/// Mutable RGBA image buffer used across rendering, serialization, and analysis.
#[derive(Debug, Clone)]
pub struct ImageData {
    /// Image width in pixels.
    pub(super) width: u32,
    /// Image height in pixels.
    pub(super) height: u32,
    /// Packed RGBA bytes in row-major order.
    pub(super) pixels: Vec<u8>,
}
impl ImageData {
    /// Create a zero-filled RGBA image buffer of the given size.
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            width,
            height,
            pixels: vec![0; (width * height * 4) as usize],
        }
    }
    /// Load an image from disk and return decoded RGBA bytes, or an error on failure.
    pub fn from_file(path: &str) -> Result<Self, String> {
        let img =
            ::image::open(path).map_err(|e| format!("Failed to load image '{}': {}", path, e))?;
        let rgba = img.to_rgba8();
        let (w, h) = rgba.dimensions();
        log_msg!(debug, IM01_IMAGE_LOADED, "{}x{}", w, h);
        Ok(Self {
            width: w,
            height: h,
            pixels: rgba.into_raw(),
        })
    }
    /// Decode an image from memory and return RGBA bytes, or an error on failure.
    pub fn from_encoded_bytes(bytes: &[u8], label: &str) -> Result<Self, String> {
        let img = ::image::load_from_memory(bytes)
            .map_err(|e| format!("Failed to decode image '{}': {}", label, e))?;
        let rgba = img.to_rgba8();
        let (w, h) = rgba.dimensions();
        log_msg!(debug, IM01_IMAGE_LOADED, "{}x{}", w, h);
        Ok(Self {
            width: w,
            height: h,
            pixels: rgba.into_raw(),
        })
    }
    /// Build an image from exact RGBA bytes, or return an error on length mismatch.
    pub fn from_bytes(width: u32, height: u32, bytes: Vec<u8>) -> Result<Self, String> {
        let expected = (width * height * 4) as usize;
        if bytes.len() != expected {
            log_msg!(
                error,
                IM02_IMAGE_MISMATCH,
                "expected {} got {}",
                expected,
                bytes.len()
            );
            return Err(format!(
                "Expected {} bytes for {}x{} RGBA image, got {}",
                expected,
                width,
                height,
                bytes.len()
            ));
        }
        Ok(Self {
            width,
            height,
            pixels: bytes,
        })
    }
    /// Return the image width in pixels.
    pub fn width(&self) -> u32 {
        self.width
    }
    /// Return the image height in pixels.
    pub fn height(&self) -> u32 {
        self.height
    }
    /// Return the image dimensions as width and height.
    pub fn dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Return the RGBA pixel at a coordinate, or `None` when out of bounds.
    pub fn get_pixel(&self, x: u32, y: u32) -> Option<(u8, u8, u8, u8)> {
        if x >= self.width || y >= self.height {
            return None;
        }
        let idx = ((y * self.width + x) * 4) as usize;
        Some((
            self.pixels[idx],
            self.pixels[idx + 1],
            self.pixels[idx + 2],
            self.pixels[idx + 3],
        ))
    }
    /// Set a pixel at a coordinate and return false when the point is out of bounds.
    pub fn set_pixel(&mut self, x: u32, y: u32, r: u8, g: u8, b: u8, a: u8) -> bool {
        if x >= self.width || y >= self.height {
            return false;
        }
        let idx = ((y * self.width + x) * 4) as usize;
        self.pixels[idx] = r;
        self.pixels[idx + 1] = g;
        self.pixels[idx + 2] = b;
        self.pixels[idx + 3] = a;
        true
    }
    /// Copy pixels from a source image into this image at the given offset.
    pub fn paste(&mut self, source: &ImageData, dx: u32, dy: u32) {
        for sy in 0..source.height {
            for sx in 0..source.width {
                let tx = dx + sx;
                let ty = dy + sy;
                if tx < self.width && ty < self.height {
                    if let Some((r, g, b, a)) = source.get_pixel(sx, sy) {
                        self.set_pixel(tx, ty, r, g, b, a);
                    }
                }
            }
        }
    }
    /// Map every pixel through a callback in place.
    pub fn map_pixel<F>(&mut self, f: F)
    where
        F: Fn(u32, u32, u8, u8, u8, u8) -> (u8, u8, u8, u8),
    {
        for y in 0..self.height {
            for x in 0..self.width {
                let idx = ((y * self.width + x) * 4) as usize;
                let r = self.pixels[idx];
                let g = self.pixels[idx + 1];
                let b = self.pixels[idx + 2];
                let a = self.pixels[idx + 3];
                let (nr, ng, nb, na) = f(x, y, r, g, b, a);
                self.pixels[idx] = nr;
                self.pixels[idx + 1] = ng;
                self.pixels[idx + 2] = nb;
                self.pixels[idx + 3] = na;
            }
        }
    }
    #[allow(clippy::too_many_arguments)]
    /// Fill an axis-aligned rectangle with a solid color and alpha.
    pub fn draw_rect(&mut self, x: i32, y: i32, w: u32, h: u32, r: u8, g: u8, b: u8, a: u8) {
        let x0 = x.max(0) as u32;
        let y0 = y.max(0) as u32;
        let x1 = ((x as i64 + w as i64).min(self.width as i64)) as u32;
        let y1 = ((y as i64 + h as i64).min(self.height as i64)) as u32;
        for py in y0..y1 {
            for px in x0..x1 {
                self.set_pixel(px, py, r, g, b, a);
            }
        }
    }
    #[allow(clippy::too_many_arguments)]
    /// Fill a circle with a solid color and alpha.
    pub fn draw_circle(&mut self, cx: i32, cy: i32, radius: u32, r: u8, g: u8, b: u8, a: u8) {
        let rad = radius as i32;
        let y0 = (cy - rad).max(0) as u32;
        let y1 = ((cy + rad + 1).min(self.height as i32).max(0)) as u32;
        let x0_bound = (cx - rad).max(0) as u32;
        let x1_bound = ((cx + rad + 1).min(self.width as i32).max(0)) as u32;
        let r2 = (radius * radius) as i64;
        for py in y0..y1 {
            let dy = py as i32 - cy;
            for px in x0_bound..x1_bound {
                let dx = px as i32 - cx;
                if (dx as i64 * dx as i64 + dy as i64 * dy as i64) <= r2 {
                    self.set_pixel(px, py, r, g, b, a);
                }
            }
        }
    }
    #[allow(clippy::too_many_arguments)]
    /// Draw a line with Bresenham's algorithm using a solid color and alpha.
    pub fn draw_line(&mut self, x0: i32, y0: i32, x1: i32, y1: i32, r: u8, g: u8, b: u8, a: u8) {
        let mut cx = x0;
        let mut cy = y0;
        let dx = (x1 - x0).abs();
        let dy = -(y1 - y0).abs();
        let sx = if x0 < x1 { 1 } else { -1 };
        let sy = if y0 < y1 { 1 } else { -1 };
        let mut err = dx + dy;
        loop {
            if cx >= 0 && cy >= 0 && (cx as u32) < self.width && (cy as u32) < self.height {
                self.set_pixel(cx as u32, cy as u32, r, g, b, a);
            }
            if cx == x1 && cy == y1 {
                break;
            }
            let e2 = 2 * err;
            if e2 >= dy {
                err += dy;
                cx += sx;
            }
            if e2 <= dx {
                err += dx;
                cy += sy;
            }
        }
    }
    /// Draw a small bitmap label for digits, letters, and a few punctuation marks.
    pub fn draw_label(&mut self, text: &str, x: i32, y: i32, r: u8, g: u8, b: u8) {
        #[rustfmt::skip]
        let digit_font: [u64; 10] = [
            0b111_101_101_101_111,
            0b010_110_010_010_111,
            0b111_001_111_100_111,
            0b111_001_111_001_111,
            0b101_101_111_001_001,
            0b111_100_111_001_111,
            0b111_100_111_101_111,
            0b111_001_010_010_010,
            0b111_101_111_101_111,
            0b111_101_111_001_111,
        ];
        #[rustfmt::skip]
        let letter_font: [u64; 26] = [
            0b010_101_111_101_101,
            0b110_101_110_101_110,
            0b011_100_100_100_011,
            0b110_101_101_101_110,
            0b111_100_110_100_111,
            0b111_100_110_100_100,
            0b011_100_101_101_011,
            0b101_101_111_101_101,
            0b111_010_010_010_111,
            0b011_001_001_101_010,
            0b101_110_100_110_101,
            0b100_100_100_100_111,
            0b101_111_111_101_101,
            0b101_111_101_101_101,
            0b111_101_101_101_111,
            0b111_101_111_100_100,
            0b010_101_101_010_001,
            0b110_101_110_101_101,
            0b011_100_010_001_110,
            0b111_010_010_010_010,
            0b101_101_101_101_111,
            0b101_101_101_101_010,
            0b101_101_111_111_101,
            0b101_101_010_101_101,
            0b101_101_010_010_010,
            0b111_001_010_100_111,
        ];
        let w = self.width as i32;
        let h = self.height as i32;
        let mut cx = x;
        for ch in text.chars() {
            let bits = if let Some(digit) = ch.to_digit(10) {
                Some(digit_font[digit as usize])
            } else if ch.is_ascii_alphabetic() {
                let idx = (ch.to_ascii_uppercase() as u8 - b'A') as usize;
                Some(letter_font[idx])
            } else if ch == '-' {
                Some(0b000_000_111_000_000u64)
            } else if ch == '.' {
                Some(0b000_000_000_000_010u64)
            } else if ch == ':' {
                Some(0b000_010_000_010_000u64)
            } else if ch == '%' {
                Some(0b101_001_010_100_101u64)
            } else {
                None
            };
            if let Some(bits) = bits {
                for row in 0..5i32 {
                    for col in 0..3i32 {
                        let bit_idx = (4 - row) * 3 + (2 - col);
                        if (bits >> bit_idx) & 1 == 1 {
                            let px = cx + col;
                            let py = y + row;
                            if px >= 0 && py >= 0 && px < w && py < h {
                                self.set_pixel(px as u32, py as u32, r, g, b, 255);
                            }
                        }
                    }
                }
            }
            cx += 4;
        }
    }
    /// Encode the image as PNG bytes and return an error on encode failure.
    pub fn encode_png(&self) -> Result<Vec<u8>, String> {
        let img: ::image::ImageBuffer<::image::Rgba<u8>, Vec<u8>> =
            ::image::ImageBuffer::from_raw(self.width, self.height, self.pixels.clone())
                .ok_or_else(|| "Failed to create image buffer".to_string())?;
        let dynamic = ::image::DynamicImage::ImageRgba8(img);
        let mut buf = Vec::new();
        let mut cursor = std::io::Cursor::new(&mut buf);
        dynamic
            .write_to(&mut cursor, ::image::ImageOutputFormat::Png)
            .map_err(|e| format!("PNG encode error: {}", e))?;
        Ok(buf)
    }
    /// Return a slice of the raw RGBA pixel bytes.
    pub fn as_bytes(&self) -> &[u8] {
        &self.pixels
    }
    /// Return a cloned copy of the raw RGBA pixel bytes.
    pub fn get_string(&self) -> Vec<u8> {
        self.pixels.clone()
    }
    /// Replace pixel data with new raw bytes and return an error on length mismatch.
    pub fn set_raw_data(&mut self, bytes: &[u8]) -> Result<(), String> {
        let expected = (self.width * self.height * 4) as usize;
        if bytes.len() != expected {
            return Err(format!(
                "setRawData: expected {} bytes for {}x{} RGBA image, got {}",
                expected,
                self.width,
                self.height,
                bytes.len()
            ));
        }
        self.pixels.clear();
        self.pixels.extend_from_slice(bytes);
        Ok(())
    }
    /// Map every pixel through a callback in place using parallel rows above the threshold.
    pub fn map_pixel_par<F>(&mut self, f: F)
    where
        F: Fn(u32, u32, u8, u8, u8, u8) -> (u8, u8, u8, u8) + Send + Sync,
    {
        const PAR_THRESHOLD: u32 = 65_536;
        if self.width * self.height <= PAR_THRESHOLD {
            return self.map_pixel(f);
        }
        use rayon::prelude::*;
        let w = self.width;
        self.pixels
            .par_chunks_mut((w * 4) as usize)
            .enumerate()
            .for_each(|(y, row)| {
                for x in 0..w {
                    let idx = (x * 4) as usize;
                    let r = row[idx];
                    let g = row[idx + 1];
                    let b = row[idx + 2];
                    let a = row[idx + 3];
                    let (nr, ng, nb, na) = f(x, y as u32, r, g, b, a);
                    row[idx] = nr;
                    row[idx + 1] = ng;
                    row[idx + 2] = nb;
                    row[idx + 3] = na;
                }
            });
    }
}
