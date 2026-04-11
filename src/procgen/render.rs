//! Procedural generation visualization helpers.
//!
//! Provides `NoiseGrid` — a precomputed 2-D noise buffer that can be visualised
//! as both a sequence of `RenderCommand`s (for screen overlay) and as a CPU
//! `ImageData` (for headless testing or export).

use crate::image::ImageData;
use crate::procgen::noise_ext::perlin_noise_periodic;
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
    /// Sample periodic Perlin noise onto a grid.
    ///
    /// `scale` controls zoom: larger values stretch the pattern, smaller values
    /// compress it.  The noise period equals `width * scale` × `height * scale`.
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
                // perlin_noise_periodic returns roughly [-1, 1]; remap to [0, 1]
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

    /// Generate render commands visualising the noise grid as a greyscale tile mosaic.
    ///
    /// Each cell is drawn as a filled rectangle whose grey level matches the
    /// normalised noise value.  Dark cells have low noise; bright cells have high noise.
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

    /// Render the noise grid to a CPU image.
    ///
    /// Each noise cell maps to one pixel; the grey level is `(value * 255) as u8`.
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

// ── Tests ──────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_perlin_correct_dimensions() {
        let grid = NoiseGrid::from_perlin(8, 6, 0.1);
        assert_eq!(grid.width, 8);
        assert_eq!(grid.height, 6);
        assert_eq!(grid.cells.len(), 48);
    }

    #[test]
    fn from_perlin_values_in_range() {
        let grid = NoiseGrid::from_perlin(16, 16, 0.2);
        for &v in &grid.cells {
            assert!(v >= 0.0 && v <= 1.0, "value out of [0,1]: {v}");
        }
    }

    #[test]
    fn generate_render_commands_count() {
        let grid = NoiseGrid::from_perlin(4, 4, 0.1);
        // 16 cells × 2 commands each
        assert_eq!(grid.generate_render_commands(8.0).len(), 32);
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let grid = NoiseGrid::from_perlin(8, 6, 0.1);
        let img = grid.draw_to_image();
        assert_eq!(img.width(), 8);
        assert_eq!(img.height(), 6);
    }

    #[test]
    fn empty_grid_returns_no_commands() {
        let grid = NoiseGrid {
            width: 0,
            height: 0,
            cells: Vec::new(),
        };
        assert!(grid.generate_render_commands(8.0).is_empty());
    }
}
