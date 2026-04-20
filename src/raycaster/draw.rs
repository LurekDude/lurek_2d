//! CPU software-rendering fallback for raycaster scenes.
//!
//! Provides [`RaycasterScene::draw_to_image`] for headless testing and
//! screenshot generation. Rasterizes each quad type as a solid-coloured
//! rectangle using the pre-computed per-polygon `light` tint — no texture
//! sampling occurs since no GPU is available. Pure CPU — no wgpu, winit, or mlua.

use crate::image::ImageData;
use crate::raycaster::scene::RaycasterScene;

/// Fills an axis-aligned rectangle on `img` with a solid RGBA colour derived from `light`.
///
/// Clamps coordinates to image bounds.
///
/// # Parameters
/// - `img` — `&mut ImageData`. Target image to paint into.
/// - `x0` — `f32`. Left edge (screen-space, may be fractional).
/// - `y0` — `f32`. Top edge.
/// - `x1` — `f32`. Right edge (exclusive).
/// - `y1` — `f32`. Bottom edge (exclusive).
/// - `light` — `[f32; 4]`. RGBA multiplier clamped to `[0.0, 1.0]`.
fn fill_rect(img: &mut ImageData, x0: f32, y0: f32, x1: f32, y1: f32, light: [f32; 4]) {
    let w = img.width();
    let h = img.height();

    let r = (light[0].clamp(0.0, 1.0) * 255.0) as u8;
    let g = (light[1].clamp(0.0, 1.0) * 255.0) as u8;
    let b = (light[2].clamp(0.0, 1.0) * 255.0) as u8;
    let a = (light[3].clamp(0.0, 1.0) * 255.0) as u8;

    let px0 = (x0 as i32).max(0) as u32;
    let py0 = (y0 as i32).max(0) as u32;
    let px1 = ((x1 as i32).min(w as i32)).max(0) as u32;
    let py1 = ((y1 as i32).min(h as i32)).max(0) as u32;

    for py in py0..py1 {
        for px in px0..px1 {
            img.set_pixel(px, py, r, g, b, a);
        }
    }
}

impl RaycasterScene {
    /// Renders the scene to a CPU image for headless testing and screenshots.
    ///
    /// Each quad is rasterized as a solid-coloured rectangle using its
    /// per-polygon `light` tint. Texture sampling is not performed (no GPU).
    /// Draw order matches [`generate_render_commands`](Self::generate_render_commands):
    /// ceilings → floors → walls → sprites.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height); // solid transparent-black

        // ── Ceilings ──
        for ceil in &self.ceilings {
            fill_rect(
                &mut img,
                ceil.corners[0].x,
                ceil.corners[0].y,
                ceil.corners[2].x,
                ceil.corners[2].y,
                ceil.light,
            );
        }

        // ── Floors ──
        for floor in &self.floors {
            fill_rect(
                &mut img,
                floor.corners[0].x,
                floor.corners[0].y,
                floor.corners[2].x,
                floor.corners[2].y,
                floor.light,
            );
        }

        // ── Walls ──
        for wall in &self.walls {
            fill_rect(
                &mut img,
                wall.corners[0].x,
                wall.corners[0].y,
                wall.corners[2].x,
                wall.corners[2].y,
                wall.light,
            );
        }

        // ── Sprites ──
        for sprite in &self.sprites {
            fill_rect(
                &mut img,
                sprite.corners[0].x,
                sprite.corners[0].y,
                sprite.corners[2].x,
                sprite.corners[2].y,
                sprite.light,
            );
        }

        img
    }
}
