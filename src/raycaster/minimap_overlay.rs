//! Top-down minimap extraction from a raycaster grid.
//!
//! Provides functions to extract a pixel-based minimap from a [`super::Raycaster2D`]
//! grid, including player position and directional arrow rendering.

use super::dda::Raycaster2D;

/// Extracts a top-down minimap from a Raycaster2D grid.
///
/// Returns flat RGBA pixel data (4 bytes per pixel, row-major) centered on
/// the player position, with a configurable view radius and cell size.
///
/// # Parameters
/// - `raycaster` — `&Raycaster2D`.
/// - `player_x` — `f32`.
/// - `player_y` — `f32`.
/// - `player_angle` — `f32`.
/// - `view_radius` — `u32`.
/// - `cell_size` — `u32`.
/// - `wall_color` — `[u8; 4]`.
/// - `floor_color` — `[u8; 4]`.
/// - `player_color` — `[u8; 4]`.
///
/// # Returns
/// `(Vec<u8>, u32, u32)`.
///
/// Returns `(pixels, pixel_width, pixel_height)`.
#[allow(clippy::too_many_arguments)]
pub fn extract_minimap(
    raycaster: &Raycaster2D,
    player_x: f32,
    player_y: f32,
    player_angle: f32,
    view_radius: u32,
    cell_size: u32,
    wall_color: [u8; 4],
    floor_color: [u8; 4],
    player_color: [u8; 4],
) -> (Vec<u8>, u32, u32) {
    let diameter = view_radius * 2 + 1;
    let pixel_w = diameter * cell_size;
    let pixel_h = diameter * cell_size;
    let mut pixels = vec![0u8; (pixel_w * pixel_h * 4) as usize];

    let player_cell_x = player_x.floor() as i32;
    let player_cell_y = player_y.floor() as i32;

    for vy in 0..diameter {
        for vx in 0..diameter {
            let cell_x = player_cell_x - view_radius as i32 + vx as i32;
            let cell_y = player_cell_y - view_radius as i32 + vy as i32;

            let is_wall = if cell_x >= 0 && cell_y >= 0 {
                raycaster.get_cell(cell_x as u32, cell_y as u32) > 0
            } else {
                false
            };

            let color = if is_wall { wall_color } else { floor_color };

            // Fill the cell_size x cell_size block
            for py in 0..cell_size {
                for px in 0..cell_size {
                    let img_x = vx * cell_size + px;
                    let img_y = vy * cell_size + py;
                    let idx = ((img_y * pixel_w + img_x) * 4) as usize;
                    if idx + 3 < pixels.len() {
                        pixels[idx] = color[0];
                        pixels[idx + 1] = color[1];
                        pixels[idx + 2] = color[2];
                        pixels[idx + 3] = color[3];
                    }
                }
            }
        }
    }

    // Draw player dot at center
    let center_px = (view_radius * cell_size + cell_size / 2) as u32;
    let center_py = (view_radius * cell_size + cell_size / 2) as u32;
    draw_player_arrow(
        &mut pixels,
        pixel_w,
        center_px,
        center_py,
        player_angle,
        cell_size.max(3),
        player_color,
    );

    (pixels, pixel_w, pixel_h)
}

/// Renders a simple directional arrow for the player on the minimap.
///
/// Draws a small triangle pointing in the player's facing direction,
/// centered at `(center_x, center_y)` in the pixel buffer.
///
/// # Parameters
/// - `pixels` — `&mut [u8]`.
/// - `img_width` — `u32`.
/// - `center_x` — `u32`.
/// - `center_y` — `u32`.
/// - `angle` — `f32`.
/// - `size` — `u32`.
/// - `color` — `[u8; 4]`.
#[allow(clippy::too_many_arguments)]
pub fn draw_player_arrow(
    pixels: &mut [u8],
    img_width: u32,
    center_x: u32,
    center_y: u32,
    angle: f32,
    size: u32,
    color: [u8; 4],
) {
    let half = size as f32 / 2.0;

    // Draw a simple filled circle/dot for the player
    let radius = (half * 0.6).max(1.0);
    let r2 = radius * radius;

    for dy in -(radius as i32)..=(radius as i32) {
        for dx in -(radius as i32)..=(radius as i32) {
            if (dx * dx + dy * dy) as f32 <= r2 {
                let px = center_x as i32 + dx;
                let py = center_y as i32 + dy;
                if px >= 0 && py >= 0 && (px as u32) < img_width {
                    let idx = ((py as u32 * img_width + px as u32) * 4) as usize;
                    if idx + 3 < pixels.len() {
                        pixels[idx] = color[0];
                        pixels[idx + 1] = color[1];
                        pixels[idx + 2] = color[2];
                        pixels[idx + 3] = color[3];
                    }
                }
            }
        }
    }

    // Draw direction indicator line
    let line_len = half;
    let tip_x = center_x as f32 + angle.cos() * line_len;
    let tip_y = center_y as f32 + angle.sin() * line_len;

    let steps = (line_len * 2.0) as i32;
    for i in 0..=steps {
        let t = i as f32 / steps.max(1) as f32;
        let lx = center_x as f32 + (tip_x - center_x as f32) * t;
        let ly = center_y as f32 + (tip_y - center_y as f32) * t;
        let px = lx as u32;
        let py = ly as u32;
        if px < img_width {
            let idx = ((py * img_width + px) * 4) as usize;
            if idx + 3 < pixels.len() {
                pixels[idx] = color[0];
                pixels[idx + 1] = color[1];
                pixels[idx + 2] = color[2];
                pixels[idx + 3] = color[3];
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_minimap_dimensions() {
        let rc = Raycaster2D::new(16, 16);
        let (pixels, w, h) = extract_minimap(
            &rc,
            8.0,
            8.0,
            0.0,
            3,
            4,
            [255, 255, 255, 255],
            [50, 50, 50, 255],
            [255, 0, 0, 255],
        );
        // diameter = 2*3+1 = 7, pixel size = 7*4 = 28
        assert_eq!(w, 28);
        assert_eq!(h, 28);
        assert_eq!(pixels.len(), (28 * 28 * 4) as usize);
    }

    #[test]
    fn test_extract_minimap_wall_colors() {
        let mut rc = Raycaster2D::new(8, 8);
        // Fill all with walls
        for y in 0..8 {
            for x in 0..8 {
                rc.set_cell(x, y, 1);
            }
        }

        let (pixels, w, _h) = extract_minimap(
            &rc,
            4.0,
            4.0,
            0.0,
            1,
            2,
            [200, 200, 200, 255],
            [0, 0, 0, 255],
            [255, 0, 0, 255],
        );

        // Top-left pixel of the (0,0) cell should be wall color
        // unless player arrow overwrites it
        // diameter=3, pixel_w=6, check corner
        let idx = 0usize;
        assert!(idx + 3 < pixels.len());
        // The cell at grid offset should be wall color
        assert_eq!(pixels[idx], 200); // R
        assert_eq!(w, 6);
    }

    #[test]
    fn test_draw_player_arrow_no_panic() {
        let mut pixels = vec![0u8; 100 * 100 * 4];
        draw_player_arrow(&mut pixels, 100, 50, 50, 0.0, 8, [255, 0, 0, 255]);
        // Just verify it doesn't panic and writes some non-zero pixels
        let has_red = pixels.chunks(4).any(|c| c[0] == 255 && c[3] == 255);
        assert!(has_red);
    }
}
