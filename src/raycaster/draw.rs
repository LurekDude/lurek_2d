//! CPU-side software rasterizer for `RaycasterScene`. Rasterizes scene quads
//! (floors, ceilings, walls, sprites) into an `ImageData` pixel buffer using
//! flat-colored rectangles. Used for headless testing and CPU fallback paths.
//! Does not own scene construction or GPU upload.

use crate::image::ImageData;
use crate::raycaster::scene::RaycasterScene;
/// Fill a screen-space rectangle with the given RGBA `light` color; clamps to image bounds.
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
    /// Rasterize this scene into a new `ImageData` of `width × height`; draws ceilings, floors, walls, then sprites back-to-front.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
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
