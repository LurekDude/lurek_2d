//! CPU-side RGBA8 pixel buffer for image manipulation.
//!
//! This module is part of Lurek2D's `image` subsystem and provides the implementation
//! details for image data-related operations and data management.
//! Key types exported from this module: `ImageData`.
//! Primary functions: `new()`, `from_file()`, `from_bytes()`, `width()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::runtime::log_messages::{IM01_IMAGE_LOADED, IM02_IMAGE_MISMATCH};
use crate::log_msg;

/// CPU-side pixel buffer in RGBA8 format.
///
/// Stores pixel data in row-major order, 4 bytes per pixel (R, G, B, A).
/// Can be created empty, from a file, or from raw bytes.
///
/// # Fields
/// - `width` — `u32`. Image width in pixels.
/// - `height` — `u32`. Image height in pixels.
/// - `pixels` — `Vec<u8>`. Raw RGBA8 pixel data in row-major order (4 bytes per pixel).
#[derive(Debug, Clone)]
pub struct ImageData {
    /// Image width in pixels.
    pub(super) width: u32,
    /// Image height in pixels.
    pub(super) height: u32,
    /// Raw RGBA8 pixel data in row-major order (4 bytes per pixel).
    pub(super) pixels: Vec<u8>,
}

impl ImageData {
    /// Create a new blank (transparent black) image.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            width,
            height,
            pixels: vec![0; (width * height * 4) as usize],
        }
    }

    /// Load an image from a file path. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
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

    /// Create from raw RGBA bytes. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `bytes` — `Vec<u8>`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
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

    /// Get the width of the image.
    ///
    /// # Returns
    /// `u32`.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Get the height of the image.
    ///
    /// # Returns
    /// `u32`.
    pub fn height(&self) -> u32 {
        self.height
    }

    /// Get both dimensions.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Get the RGBA values of a pixel at (x, y). Values are 0-255.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Option<(u8, u8, u8, u8)>`.
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

    /// Set the RGBA values of a pixel at (x, y). Values are 0-255.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `r` — `u8`.
    /// - `g` — `u8`.
    /// - `b` — `u8`.
    /// - `a` — `u8`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Paste source image onto self at position (dx, dy).
    ///
    /// # Parameters
    /// - `source` — `&ImageData`.
    /// - `dx` — `u32`.
    /// - `dy` — `u32`.
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

    /// Apply a function to every pixel, replacing each (r,g,b,a) with the return value.
    ///
    /// # Parameters
    /// - `f` — `F`.
    ///
    /// # Returns
    /// `(u8, u8, u8, u8),`.
    ///
    /// The function receives `(x, y, r, g, b, a)` and returns `(r, g, b, a)`.
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

    /// Draw a filled rectangle onto the image.
    ///
    /// Pixels outside the image bounds are silently clipped.
    ///
    /// # Parameters
    /// - `x` — `i32`. Left edge (can be negative for partial off-screen rects).
    /// - `y` — `i32`. Top edge.
    /// - `w` — `u32`. Width in pixels.
    /// - `h` — `u32`. Height in pixels.
    /// - `r` — `u8`. Red channel.
    /// - `g` — `u8`. Green channel.
    /// - `b` — `u8`. Blue channel.
    /// - `a` — `u8`. Alpha channel.
    #[allow(clippy::too_many_arguments)]
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

    /// Draw a filled circle onto the image using the midpoint algorithm.
    ///
    /// Pixels outside the image bounds are silently clipped.
    ///
    /// # Parameters
    /// - `cx` — `i32`. Centre X.
    /// - `cy` — `i32`. Centre Y.
    /// - `radius` — `u32`. Radius in pixels.
    /// - `r` — `u8`. Red channel.
    /// - `g` — `u8`. Green channel.
    /// - `b` — `u8`. Blue channel.
    /// - `a` — `u8`. Alpha channel.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_circle_safe(&mut self, cx: i32, cy: i32, r: i32, red: u8, g: u8, b: u8, a: u8) {
        let w = self.width() as i32;
        let h = self.height() as i32;
        let y0 = (cy - r).max(0);
        let y1 = (cy + r + 1).min(h);
        let x0 = (cx - r).max(0);
        let x1 = (cx + r + 1).min(w);
        let r2 = (r * r) as i64;
        for py in y0..y1 {
            let dy = (py - cy) as i64;
            for px in x0..x1 {
                let dx = (px - cx) as i64;
                if dx * dx + dy * dy <= r2 {
                    self.set_pixel(px as u32, py as u32, red, g, b, a);
                }
            }
        }
    }

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

    /// Draw a line using Bresenham's algorithm.
    ///
    /// Pixels outside the image bounds are silently clipped.
    ///
    /// # Parameters
    /// - `x0` — `i32`. Start X.
    /// - `y0` — `i32`. Start Y.
    /// - `x1` — `i32`. End X.
    /// - `y1` — `i32`. End Y.
    /// - `r` — `u8`. Red channel.
    /// - `g` — `u8`. Green channel.
    /// - `b` — `u8`. Blue channel.
    /// - `a` — `u8`. Alpha channel.
    #[allow(clippy::too_many_arguments)]
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

    /// Draw a text label using a built-in 3×5 pixel font.
    ///
    /// Supports digits 0–9, letters A–Z (case-insensitive), and a few
    /// punctuation characters (`-`, `.`, `:`, `%`). Unknown characters
    /// produce a blank space. Each glyph is 3 pixels wide with 1-pixel
    /// spacing, so a character cell is 4 pixels wide.
    ///
    /// # Parameters
    /// - `text` — `&str`. The string to draw.
    /// - `x` — `i32`. Left edge of the first character.
    /// - `y` — `i32`. Top edge of the text.
    /// - `r` — `u8`. Red channel.
    /// - `g` — `u8`. Green channel.
    /// - `b` — `u8`. Blue channel.
    pub fn draw_label(&mut self, text: &str, x: i32, y: i32, r: u8, g: u8, b: u8) {
        #[rustfmt::skip]
        let digit_font: [u64; 10] = [
            0b111_101_101_101_111, // 0
            0b010_110_010_010_111, // 1
            0b111_001_111_100_111, // 2
            0b111_001_111_001_111, // 3
            0b101_101_111_001_001, // 4
            0b111_100_111_001_111, // 5
            0b111_100_111_101_111, // 6
            0b111_001_010_010_010, // 7
            0b111_101_111_101_111, // 8
            0b111_101_111_001_111, // 9
        ];
        #[rustfmt::skip]
        let letter_font: [u64; 26] = [
            0b010_101_111_101_101, // A
            0b110_101_110_101_110, // B
            0b011_100_100_100_011, // C
            0b110_101_101_101_110, // D
            0b111_100_110_100_111, // E
            0b111_100_110_100_100, // F
            0b011_100_101_101_011, // G
            0b101_101_111_101_101, // H
            0b111_010_010_010_111, // I
            0b011_001_001_101_010, // J
            0b101_110_100_110_101, // K
            0b100_100_100_100_111, // L
            0b101_111_111_101_101, // M
            0b101_111_101_101_101, // N
            0b111_101_101_101_111, // O
            0b111_101_111_100_100, // P
            0b010_101_101_010_001, // Q
            0b110_101_110_101_101, // R
            0b011_100_010_001_110, // S
            0b111_010_010_010_010, // T
            0b101_101_101_101_111, // U
            0b101_101_101_101_010, // V
            0b101_101_111_111_101, // W
            0b101_101_010_101_101, // X
            0b101_101_010_010_010, // Y
            0b111_001_010_100_111, // Z
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

    /// Encode the image as PNG bytes.
    ///
    /// # Returns
    /// `Result<Vec<u8>, String>`.
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

    /// Get a reference to the raw pixel bytes.
    ///
    /// # Returns
    /// `&[u8]`.
    pub fn as_bytes(&self) -> &[u8] {
        &self.pixels
    }

    /// Get the raw pixel bytes as a vector (for Lua getString() compatibility).
    ///
    /// # Returns
    /// `Vec<u8>`.
    pub fn get_string(&self) -> Vec<u8> {
        self.pixels.clone()
    }
}

