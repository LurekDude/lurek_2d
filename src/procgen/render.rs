//! Periodic-Perlin `NoiseGrid` — noise data buffer with optional visualization.
//!
//! Use the `cells` field directly, call `to_rgba_bytes()` for a pixel buffer,
//! `generate_render_commands()` for GPU render commands, or `draw_to_image()`
//! for a CPU `ImageData` snapshot.

use crate::image::ImageData;
use crate::procgen::noise::perlin_noise_periodic;
use crate::render::renderer::{DrawMode, RenderCommand};

/// A precomputed 2-D noise grid sampled from periodic Perlin noise.
///
/// Values are normalised to `[0.0, 1.0]` before storage.
///
/// # Fields
/// - `width` — `u32`. Number of columns.
/// - `height` — `u32`. Number of rows.
/// - `cells` — `Vec<f32>`. Row-major noise values, each in `[0.0, 1.0]`.
pub struct NoiseGrid {
    /// Number of columns.
    pub width: u32,
    /// Number of rows.
    pub height: u32,
    /// Row-major noise values normalised to `[0.0, 1.0]`.
    pub cells: Vec<f32>,
}

impl NoiseGrid {
    /// Sample periodic Perlin noise onto a grid and return a plain data buffer.
    ///
    /// `scale` controls zoom: larger values stretch the pattern, smaller values
    /// compress it. The noise period equals `width * scale` × `height * scale`.
    ///
    /// # Parameters
    /// - `width` — `u32`. Grid width in cells.
    /// - `height` — `u32`. Grid height in cells.
    /// - `scale` — `f64`. Noise frequency scale (e.g. `0.1` = fine grain, `1.0` = coarse).
    ///
    /// # Returns
    /// `Self`.
    pub fn from_perlin(width: u32, height: u32, scale: f64) -> Self {
        let scale = scale.max(1e-6);
        let px = width as f64 * scale;
        let py = height as f64 * scale;
        let size = (width * height) as usize;
        let mut cells = Vec::with_capacity(size);

        for y in 0..height {
            for x in 0..width {
                let nx = x as f64 * scale;
                let ny = y as f64 * scale;
                let v = (perlin_noise_periodic(nx, ny, px, py) * 0.5 + 0.5).clamp(0.0, 1.0) as f32;
                cells.push(v);
            }
        }

        Self {
            width,
            height,
            cells,
        }
    }

    /// Return a greyscale RGBA byte buffer (4 bytes per pixel, `width * height * 4` total).
    ///
    /// # Returns
    /// `Vec<u8>` in RGBA order.
    pub fn to_rgba_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(self.cells.len() * 4);
        for &v in &self.cells {
            let g = (v * 255.0) as u8;
            buf.extend_from_slice(&[g, g, g, 255]);
        }
        buf
    }

    /// Generate render commands visualising the noise grid as a greyscale tile mosaic.
    ///
    /// # Parameters
    /// - `cell_size` — `f32`. Screen-space size of one noise cell in pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self, cell_size: f32) -> Vec<RenderCommand> {
        if self.cells.is_empty() {
            return Vec::new();
        }

        let mut cmds = Vec::with_capacity(self.cells.len() * 2);

        for (i, &v) in self.cells.iter().enumerate() {
            let col = i as u32;
            let row = i as u32 / self.width;
            let x = (col % self.width) as f32 * cell_size;
            let y = row as f32 * cell_size;
            cmds.push(RenderCommand::SetColor(v, v, v, 1.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x,
                y,
                w: cell_size,
                h: cell_size,
            });
        }

        cmds
    }

    /// Render the noise grid to a CPU image (one pixel per cell).
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self) -> ImageData {
        let mut img = ImageData::new(self.width, self.height);

        for y in 0..self.height {
            for x in 0..self.width {
                let v = self.cells[(y * self.width + x) as usize];
                let g = (v * 255.0) as u8;
                img.set_pixel(x, y, g, g, g, 255);
            }
        }

        img
    }
}
