//! Noise-grid rendering helpers for `src/procgen`.
//! Owns `NoiseGrid` and its tiling-Perlin construction, RGBA export, render-command
//! generation, and `ImageData` export. Does not own general noise primitives or
//! dungeon rendering — those live in `noise.rs`, `rooms.rs`, and `bsp.rs`.

use crate::image::ImageData;
use crate::procgen::noise::perlin_noise_periodic;
use crate::procgen::scalar_map_to_rgba_bytes;
use crate::render::renderer::{DrawMode, RenderCommand};

/// Flat noise grid with tiling-Perlin cell values in 0.0–1.0.
pub struct NoiseGrid {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Row-major cell values; index = `y * width + x`.
    pub cells: Vec<f32>,
}

impl NoiseGrid {
    /// Build a tileable Perlin noise grid at the given `scale`; scale is clamped to >= 1e-6.
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
    /// Convert the cell grid to a flat grayscale RGBA byte buffer at 4 bytes per cell.
    pub fn to_rgba_bytes(&self) -> Vec<u8> {
        scalar_map_to_rgba_bytes(&self.cells)
    }
    /// Generate `SetColor` + `Rectangle` render commands for each cell at `cell_size` pixels; returns an empty vec for empty grids.
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
    /// Render the grid into a new `ImageData` as grayscale RGBA pixels.
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
