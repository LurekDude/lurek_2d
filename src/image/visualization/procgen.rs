//! Procedural generation visualization helpers.
//!
//! Renders cellular automata grids, Voronoi regions, point sets, BSP dungeons,
//! colored point fields, and Delaunay triangulations as CPU-side [`ImageData`].

use crate::image::ImageData;
use super::hsv_to_rgb_viz;

/// Render a cellular automata grid (1=alive, 0=dead) as a scaled image.
///
/// # Parameters
/// - `grid` — `&[u8]`. Flat row-major grid, 1=alive, 0=dead.
/// - `grid_w` — `u32`. Grid width.
/// - `grid_h` — `u32`. Grid height.
/// - `cell_size` — `u32`. Pixels per cell.
/// - `alive_color` — `(u8,u8,u8)`. Color for alive cells.
/// - `dead_color` — `(u8,u8,u8)`. Color for dead cells.
///
/// # Returns
/// `ImageData`.
pub fn cellular_grid_to_image(
    grid: &[u8],
    grid_w: u32,
    grid_h: u32,
    cell_size: u32,
    alive_color: (u8, u8, u8),
    dead_color: (u8, u8, u8),
) -> ImageData {
    let mut img = ImageData::new(grid_w * cell_size, grid_h * cell_size);
    for y in 0..grid_h {
        for x in 0..grid_w {
            let alive = grid[(y * grid_w + x) as usize] == 1;
            let (r, g, b) = if alive { alive_color } else { dead_color };
            for py in 0..cell_size {
                for px in 0..cell_size {
                    img.set_pixel(x * cell_size + px, y * cell_size + py, r, g, b, 255);
                }
            }
        }
    }
    img
}

/// Render a Voronoi region map as a colored image.
///
/// Each region index is mapped to a deterministic palette color.
///
/// # Parameters
/// - `regions` — `&[u32]`. Flat row-major region indices.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `palette` — `&[(u8,u8,u8)]`. Color palette (indexed by region mod len).
///
/// # Returns
/// `ImageData`.
pub fn voronoi_to_image(
    regions: &[u32],
    width: u32,
    height: u32,
    palette: &[(u8, u8, u8)],
) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let region = regions[(y * width + x) as usize] as usize;
            let (r, g, b) = palette[region % palette.len()];
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    img
}

/// Render a set of 2D points as dots on a dark background.
///
/// # Parameters
/// - `points` — `&[(f64, f64)]`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `radius` — `u32`. Circle radius per point.
/// - `color` — `(u8,u8,u8)`.
///
/// # Returns
/// `ImageData`.
pub fn points_to_image(
    points: &[(f64, f64)],
    width: u32,
    height: u32,
    radius: u32,
    color: (u8, u8, u8),
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(20, 25, 35, 255);
    for &(px, py) in points {
        if px >= 0.0 && py >= 0.0 && px < width as f64 && py < height as f64 {
            img.draw_circle(px as i32, py as i32, radius, color.0, color.1, color.2, 255);
        }
    }
    img
}

/// Render a BSP dungeon grid (0=floor, 1=wall) as a scaled tile image.
///
/// # Parameters
/// - `grid` — `&[u8]`. Flat row-major grid, 0=floor, 1=wall.
/// - `grid_w` — `u32`.
/// - `grid_h` — `u32`.
/// - `cell_size` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn dungeon_grid_to_image(grid: &[u8], grid_w: u32, grid_h: u32, cell_size: u32) -> ImageData {
    let mut img = ImageData::new(grid_w * cell_size, grid_h * cell_size);
    img.fill(15, 15, 25, 255);
    for y in 0..grid_h {
        for x in 0..grid_w {
            let (r, g, b) = if grid[(y * grid_w + x) as usize] == 0 {
                (80u8, 70, 60)
            } else {
                (40, 35, 30)
            };
            img.draw_rect(
                (x * cell_size) as i32,
                (y * cell_size) as i32,
                cell_size,
                cell_size,
                r,
                g,
                b,
                255,
            );
        }
    }
    img
}

/// Render a set of 2-D points, each colored by its index in the list.
///
/// Each point is a single pixel. The color is derived from the point index
/// using three independent linear hash functions so nearby indices have
/// visually distinct colors. Background is dark blue-grey.
///
/// # Parameters
/// - `points` — `&[(f32, f32)]`. Point positions in `[0, width) × [0, height)` space.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn colored_points_to_image(points: &[(f32, f32)], width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    for (i, &(px, py)) in points.iter().enumerate() {
        if px >= 0.0 && py >= 0.0 && px < width as f32 && py < height as f32 {
            let r = ((i * 37) % 200 + 55) as u8;
            let g = ((i * 73) % 200 + 55) as u8;
            let b = ((i * 111) % 200 + 55) as u8;
            img.set_pixel(px as u32, py as u32, r, g, b, 255);
        }
    }
    img
}

/// Draw Delaunay triangulation visualization.
///
/// Renders triangles with HSV-colored edges and highlighted input points.
///
/// # Parameters
/// - `points` — `&[(f64, f64)]`. Input point coordinates.
/// - `triangles` — `&[[f64; 6]]`. Triangle vertex pairs from `delaunay_triangulate`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_delaunay_to_image(
    points: &[(f64, f64)],
    triangles: &[[f64; 6]],
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    let tri_count = triangles.len();
    for (i, tri) in triangles.iter().enumerate() {
        let hue = if tri_count > 0 {
            ((i as f32 / tri_count as f32) * 360.0) as u16
        } else {
            0
        };
        let (r, g, b) = hsv_to_rgb_viz(hue, 0.5, 0.7);
        img.draw_line(
            tri[0] as i32,
            tri[1] as i32,
            tri[2] as i32,
            tri[3] as i32,
            r,
            g,
            b,
            200,
        );
        img.draw_line(
            tri[2] as i32,
            tri[3] as i32,
            tri[4] as i32,
            tri[5] as i32,
            r,
            g,
            b,
            200,
        );
        img.draw_line(
            tri[4] as i32,
            tri[5] as i32,
            tri[0] as i32,
            tri[1] as i32,
            r,
            g,
            b,
            200,
        );
    }

    for &(px, py) in points {
        img.draw_circle(px as i32, py as i32, 4, 255, 200, 80, 255);
    }

    let count_str = format!("{} TRIANGLES", tri_count);
    img.draw_label(
        &count_str,
        10,
        (height.saturating_sub(20)) as i32,
        100,
        200,
        100,
    );
    img.draw_label("DELAUNAY TRIANGULATION", 80, 5, 100, 255, 100);
    img
}
