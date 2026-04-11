//! Standalone visualization helpers for Tier 1 modules.
//!
//! Because Tier 1 modules (animation, camera) cannot import `crate::image`,
//! render helpers that produce `ImageData` from their structs live here,
//! accepting the domain object by reference.

use super::ImageData;
use crate::animation::Animation;
use crate::camera::Camera2D;

/// Render an animation's frame grid as a strip of numbered cells.
///
/// Each frame is drawn as a `cell_w × cell_h` block. The current frame
/// is highlighted with a yellow border.
///
/// # Parameters
/// - `anim` — `&Animation`. The animation to visualize.
/// - `cell_w` — `u32`. Width of each frame cell.
/// - `cell_h` — `u32`. Height of each frame cell.
///
/// # Returns
/// `ImageData`.
pub fn draw_animation_frame_grid_to_image(anim: &Animation, cell_w: u32, cell_h: u32) -> ImageData {
    let frame_count = anim.get_frame_count().max(1) as u32;
    let cols = frame_count.min(8);
    let rows = (frame_count + cols - 1) / cols;
    let width = cols * cell_w;
    let height = rows * cell_h;
    let mut img = ImageData::new(width, height);
    img.fill(18, 18, 28, 255);

    for i in 0..frame_count {
        let col = i % cols;
        let row = i / cols;
        let px = col * cell_w;
        let py = row * cell_h;
        let is_current = i == anim.current_frame() as u32;
        let (r, g, b) = if is_current {
            (255u8, 220u8, 60u8)
        } else {
            (80u8, 80u8, 100u8)
        };
        img.draw_rect(
            (px + 1) as i32,
            (py + 1) as i32,
            cell_w - 2,
            cell_h - 2,
            r / 4,
            g / 4,
            b / 4,
            255,
        );
        // Border
        img.draw_rect(px as i32, py as i32, cell_w, 1, r, g, b, 255);
        img.draw_rect(px as i32, (py + cell_h - 1) as i32, cell_w, 1, r, g, b, 255);
        img.draw_rect(px as i32, py as i32, 1, cell_h, r, g, b, 255);
        img.draw_rect((px + cell_w - 1) as i32, py as i32, 1, cell_h, r, g, b, 255);
        let label = format!("{}", i);
        img.draw_label(
            &label,
            (px + 4) as i32,
            (py + cell_h / 2 - 4) as i32,
            r,
            g,
            b,
        );
    }
    img
}

/// Render an animation playback strip as snapshot columns.
///
/// Draws `snapshots.len()` side-by-side panels, each showing
/// a frame index highlighted in the sequence. The panel columns
/// are colored to indicate which frame was active at that step.
///
/// # Parameters
/// - `snapshots` — `&[usize]`. Frame index active at each step.
/// - `total_frames` — `usize`. Total frame count.
/// - `panel_w` — `u32`. Width of each step panel.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_animation_playback_to_image(
    snapshots: &[usize],
    total_frames: usize,
    panel_w: u32,
    height: u32,
) -> ImageData {
    let width = panel_w * snapshots.len().max(1) as u32;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    img.draw_label("PLAYBACK", 4, 4, 180, 220, 255);

    if total_frames == 0 {
        return img;
    }
    let bar_h = (height - 24) / total_frames.max(1) as u32;

    for (step, &frame) in snapshots.iter().enumerate() {
        let ox = step as u32 * panel_w;
        for f in 0..total_frames {
            let y = 20 + f as u32 * bar_h;
            let is_active = f == frame;
            let (r, g, b) = if is_active {
                (255u8, 220u8, 60u8)
            } else {
                (40u8, 40u8, 50u8)
            };
            for bx in 1..panel_w.saturating_sub(1) {
                for by in 0..bar_h.saturating_sub(1) {
                    if (ox + bx) < width && (y + by) < height {
                        img.set_pixel(ox + bx, y + by, r, g, b, if is_active { 220 } else { 80 });
                    }
                }
            }
        }
    }
    img
}

/// Render a camera debug visualization showing viewport, position, and zoom.
///
/// Draws a world grid in the background with the camera viewport
/// overlaid as a yellow rectangle indicating the visible area.
///
/// # Parameters
/// - `cam` — `&Camera2D`. Camera to visualize.
/// - `world_w` — `u32`. World width for background.
/// - `world_h` — `u32`. World height for background.
/// - `img_w` — `u32`. Output image width.
/// - `img_h` — `u32`. Output image height.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_debug_to_image(
    cam: &Camera2D,
    world_w: f32,
    world_h: f32,
    img_w: u32,
    img_h: u32,
) -> ImageData {
    let mut img = ImageData::new(img_w, img_h);
    img.fill(20, 20, 30, 255);

    // Draw grid
    let grid = 32.0f32;
    let sx = img_w as f32 / world_w;
    let sy = img_h as f32 / world_h;
    let mut gx = 0.0f32;
    while gx < world_w {
        let px = (gx * sx) as i32;
        img.draw_line(px, 0, px, img_h as i32, 35, 35, 45, 100);
        gx += grid;
    }
    let mut gy = 0.0f32;
    while gy < world_h {
        let py = (gy * sy) as i32;
        img.draw_line(0, py, img_w as i32, py, 35, 35, 45, 100);
        gy += grid;
    }

    // Viewport rectangle
    let (cx, cy) = cam.get_position();
    let zoom = cam.get_zoom();
    let vw = (cam.viewport.width / zoom) as u32;
    let vh = (cam.viewport.height / zoom) as u32;
    let vx = cx as i32 - vw as i32 / 2;
    let vy = cy as i32 - vh as i32 / 2;
    let rx = (vx as f32 * sx) as i32;
    let ry = (vy as f32 * sy) as i32;
    let rw = (vw as f32 * sx) as u32;
    let rh = (vh as f32 * sy) as u32;
    img.draw_rect(rx, ry, rw, 1, 255, 220, 60, 255);
    img.draw_rect(rx, ry + rh as i32, rw, 1, 255, 220, 60, 255);
    img.draw_rect(rx, ry, 1, rh, 255, 220, 60, 255);
    img.draw_rect(rx + rw as i32, ry, 1, rh, 255, 220, 60, 255);

    // Center crosshair
    let pcx = (cx * sx) as i32;
    let pcy = (cy * sy) as i32;
    img.draw_line(pcx - 8, pcy, pcx + 8, pcy, 255, 100, 100, 200);
    img.draw_line(pcx, pcy - 8, pcx, pcy + 8, 255, 100, 100, 200);

    let info = format!("zoom:{:.1}", zoom);
    img.draw_label(&info, 4, 4, 200, 200, 255);
    img
}

/// Render a zoom comparison showing the world at multiple zoom levels.
///
/// Creates a horizontal strip of panels, each showing the camera viewport
/// area at a different zoom level drawn over a dot grid.
///
/// # Parameters
/// - `cam` — `&Camera2D`. Camera to copy baseline from.
/// - `zoom_levels` — `&[f32]`. Zoom values to visualize.
/// - `panel_w` — `u32`.
/// - `panel_h` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_zoom_comparison_to_image(
    cam: &Camera2D,
    zoom_levels: &[f32],
    panel_w: u32,
    panel_h: u32,
) -> ImageData {
    let width = panel_w * zoom_levels.len().max(1) as u32;
    let mut img = ImageData::new(width, panel_h);
    img.fill(15, 15, 25, 255);
    img.draw_label("ZOOM COMPARE", 4, 4, 200, 200, 255);

    for (i, &z) in zoom_levels.iter().enumerate() {
        let ox = i as u32 * panel_w;
        // Dot grid
        let spacing = (16.0 * z.max(0.1)) as u32;
        let spacing = spacing.max(4).min(panel_w);
        for dy in (20..panel_h).step_by(spacing as usize) {
            for dx in (0..panel_w).step_by(spacing as usize) {
                if (ox + dx) < width {
                    img.set_pixel(ox + dx, dy, 60, 60, 80, 180);
                }
            }
        }
        // Viewport box
        let vw = (cam.viewport.width / z.max(0.01)) as u32;
        let vh = (cam.viewport.height / z.max(0.01)) as u32;
        let scale_x = panel_w as f32 / (cam.viewport.width * 2.0);
        let scale_y = (panel_h - 20) as f32 / (cam.viewport.height * 2.0);
        let rw = (vw as f32 * scale_x).min(panel_w as f32 - 4.0) as u32;
        let rh = (vh as f32 * scale_y).min((panel_h - 24) as f32) as u32;
        let rx = ox + panel_w / 2 - rw / 2;
        let ry = 20 + (panel_h - 20) / 2 - rh / 2;
        let brightness = (z * 80.0).min(255.0) as u8;
        img.draw_rect(rx as i32, ry as i32, rw, 1, 255, brightness, 60, 220);
        img.draw_rect(rx as i32, (ry + rh) as i32, rw, 1, 255, brightness, 60, 220);
        img.draw_rect(rx as i32, ry as i32, 1, rh, 255, brightness, 60, 220);
        img.draw_rect((rx + rw) as i32, ry as i32, 1, rh, 255, brightness, 60, 220);

        let lbl = format!("x{:.1}", z);
        img.draw_label(&lbl, (ox + 2) as i32, 20, 200, 200, 255);
    }
    img
}

// ── Noise visualization ──────────────────────────────────────────

/// Render a 2D noise function to a grayscale image.
///
/// Samples `noise_fn` at each pixel scaled by `scale`, normalises the
/// result from `[-1,1]` to `[0,255]`, and writes it as a grayscale pixel.
///
/// # Parameters
/// - `noise_fn` — `impl Fn(f64, f64) -> f64`. Noise sampling function.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `scale` — `f64`. Coordinate multiplier before sampling.
///
/// # Returns
/// `ImageData`.
pub fn noise_to_image(
    noise_fn: impl Fn(f64, f64) -> f64,
    width: u32,
    height: u32,
    scale: f64,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let val = noise_fn(x as f64 * scale, y as f64 * scale);
            let v = ((val * 0.5 + 0.5).clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    img
}

/// Render a 2D noise function where the output is already in `[0,1]` range.
///
/// Unlike [`noise_to_image`], this does NOT apply the `*0.5+0.5` normalisation.
///
/// # Parameters
/// - `noise_fn` — `impl Fn(f64, f64) -> f64`. Noise sampling function returning `[0,1]`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `scale` — `f64`. Coordinate multiplier before sampling.
///
/// # Returns
/// `ImageData`.
pub fn noise_raw_to_image(
    noise_fn: impl Fn(f64, f64) -> f64,
    width: u32,
    height: u32,
    scale: f64,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let val = noise_fn(x as f64 * scale, y as f64 * scale);
            let v = (val.clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    img
}

/// Render a 2D noise function as a terrain-colored image.
///
/// Maps noise values to biome colors: deep water, shallow water, beach,
/// grass, mountain, and snow.
///
/// # Parameters
/// - `noise_fn` — `impl Fn(f64, f64) -> f64`. Noise function returning `[-1,1]`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `scale` — `f64`. Coordinate multiplier.
///
/// # Returns
/// `ImageData`.
pub fn noise_terrain_to_image(
    noise_fn: impl Fn(f64, f64) -> f64,
    width: u32,
    height: u32,
    scale: f64,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let val = noise_fn(x as f64 * scale, y as f64 * scale);
            let h = val * 0.5 + 0.5;
            let (r, g, b) = if h < 0.3 {
                (30u8, 80u8, 180u8)
            } else if h < 0.4 {
                (60, 130, 200)
            } else if h < 0.45 {
                (210, 200, 150)
            } else if h < 0.65 {
                (50, 160, 50)
            } else if h < 0.8 {
                (100, 80, 50)
            } else {
                (220, 220, 230)
            };
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    img
}

/// Render a flat heightmap buffer as a colored elevation image.
///
/// Maps normalised `[-1,1]` values through a blue→green→brown→white gradient.
///
/// # Parameters
/// - `data` — `&[f64]`. Row-major height values, length = `width * height`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn heightmap_to_image(data: &[f64], width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let raw = data[(y * width + x) as usize] as f32;
            let h = (raw * 0.5 + 0.5).clamp(0.0, 1.0);
            let (r, g, b) = if h < 0.35 {
                let t = h / 0.35;
                (
                    (20.0 + t * 40.0) as u8,
                    (60.0 + t * 70.0) as u8,
                    (140.0 + t * 60.0) as u8,
                )
            } else if h < 0.6 {
                let t = (h - 0.35) / 0.25;
                (
                    (60.0 - t * 10.0) as u8,
                    (130.0 + t * 30.0) as u8,
                    (60.0 - t * 20.0) as u8,
                )
            } else if h < 0.8 {
                let t = (h - 0.6) / 0.2;
                (
                    (80.0 + t * 60.0) as u8,
                    (100.0 - t * 30.0) as u8,
                    (40.0 + t * 20.0) as u8,
                )
            } else {
                let t = (h - 0.8) / 0.2;
                (
                    (180.0 + t * 60.0) as u8,
                    (180.0 + t * 60.0) as u8,
                    (190.0 + t * 50.0) as u8,
                )
            };
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    img
}

/// Render a flat heightmap buffer with terrain-band coloring.
///
/// Maps normalised `[0,1]` values to elevation bands: deep water, shallow
/// water, beach, grass, hills, snow.
///
/// # Parameters
/// - `data` — `&[f64]`. Row-major values pre-normalised to `[0,1]` via `*0.5+0.5`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn terrain_elevation_to_image(data: &[f64], width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let raw = data[(y * width + x) as usize] as f32;
            let v = (raw * 0.5 + 0.5).clamp(0.0, 1.0);
            let (r, g, b) = if v < 0.3 {
                (30u8, 50, (120.0 + v * 200.0) as u8)
            } else if v < 0.4 {
                (60, 100, (180.0 + v * 100.0).min(255.0) as u8)
            } else if v < 0.45 {
                (200, 190, 130)
            } else if v < 0.65 {
                (40, (100.0 + v * 150.0) as u8, 40)
            } else if v < 0.8 {
                let g = (80.0 + v * 80.0) as u8;
                (g, (g as f32 * 0.8) as u8, g / 2)
            } else {
                let s = (200.0 + v * 55.0).min(255.0) as u8;
                (s, s, s)
            };
            img.set_pixel(x as u32, y as u32, r, g, b, 255);
        }
    }
    img
}

// ── Easing visualization ─────────────────────────────────────────

/// Render a gallery of easing curves as a grid of small charts.
///
/// Each entry in `curves` is a `(name, easing_fn)` pair. Charts are
/// arranged in a 4-column grid with named labels. The easing function
/// receives `t` in `[0,1]` and returns the eased value.
///
/// # Parameters
/// - `curves` — `&[(&str, &dyn Fn(f32) -> f32)]`. Named easing functions.
/// - `chart_w` — `u32`. Width of each chart cell.
/// - `chart_h` — `u32`. Height of each chart cell.
///
/// # Returns
/// `ImageData`.
pub fn easing_gallery_to_image(
    curves: &[(&str, &dyn Fn(f32) -> f32)],
    chart_w: u32,
    chart_h: u32,
) -> ImageData {
    let cols = 4u32;
    let rows = (curves.len() as u32 + cols - 1) / cols;
    let pad = 10u32;
    let img_w = cols * (chart_w + pad) + pad;
    let img_h = rows * (chart_h + pad + 16) + pad;
    let mut img = ImageData::new(img_w, img_h);
    img.fill(20, 20, 30, 255);

    for (idx, (_name, func)) in curves.iter().enumerate() {
        let col = (idx as u32) % cols;
        let row = (idx as u32) / cols;
        let ox = pad + col * (chart_w + pad);
        let oy = pad + row * (chart_h + pad + 16) + 14;

        img.draw_rect(ox as i32, oy as i32, chart_w, chart_h, 35, 35, 50, 255);

        let mut prev_x = 0i32;
        let mut prev_y = 0i32;
        for step in 0..=100 {
            let t = step as f32 / 100.0;
            let v = func(t);
            let px = ox as i32 + (t * (chart_w - 1) as f32) as i32;
            let py = oy as i32 + chart_h as i32
                - 1
                - (v.clamp(0.0, 1.5) / 1.5 * (chart_h - 1) as f32) as i32;
            if step > 0 {
                img.draw_line(prev_x, prev_y, px, py, 100, 220, 160, 255);
            }
            prev_x = px;
            prev_y = py;
        }
    }
    img
}

/// Render multiple easing curves overlaid on a single chart.
///
/// Each entry provides a name, color, and easing function. A background
/// grid is drawn at 32-pixel intervals.
///
/// # Parameters
/// - `curves` — `&[(&str, (u8,u8,u8), fn(f32) -> f32)]`. Named, colored easings.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn easing_comparison_to_image(
    curves: &[(&str, (u8, u8, u8), fn(f32) -> f32)],
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(20, 20, 30, 255);
    // Grid
    let step = 32;
    for i in (0..width).step_by(step) {
        img.draw_line(i as i32, 0, i as i32, height as i32 - 1, 35, 35, 45, 255);
    }
    for i in (0..height).step_by(step) {
        img.draw_line(0, i as i32, width as i32 - 1, i as i32, 35, 35, 45, 255);
    }

    for (_name, (r, g, b), func) in curves {
        let mut prev = (0i32, height as i32 - 1);
        for step in 1..=200 {
            let t = step as f32 / 200.0;
            let v = func(t);
            let px = (t * (width - 1) as f32) as i32;
            let py = (height - 1) as i32 - (v.clamp(-0.2, 1.3) * 170.0 + 20.0) as i32;
            img.draw_line(prev.0, prev.1, px, py, *r, *g, *b, 220);
            prev = (px, py);
        }
    }
    img
}

// ── Bezier visualization ─────────────────────────────────────────

/// Render multiple cubic Bezier curves with control-point overlays.
///
/// Each entry is `(control_points, (r,g,b))`. Control polygons are drawn
/// dimmed, control points as small circles, and the curve in full color.
///
/// # Parameters
/// - `curves` — `&[(Vec<crate::math::vec2::Vec2>, (u8,u8,u8))]`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn bezier_curves_to_image(
    curves: &[(Vec<crate::math::vec2::Vec2>, (u8, u8, u8))],
    width: u32,
    height: u32,
) -> ImageData {
    use crate::math::bezier::BezierCurve;

    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    for (pts, (cr, cg, cb)) in curves {
        let bez = BezierCurve::new(pts.clone());

        // Control polygon
        for i in 0..pts.len().saturating_sub(1) {
            img.draw_line(
                pts[i].x as i32,
                pts[i].y as i32,
                pts[i + 1].x as i32,
                pts[i + 1].y as i32,
                cr / 3,
                cg / 3,
                cb / 3,
                100,
            );
        }

        // Curve
        let steps = 100;
        for i in 0..steps {
            let t0 = i as f32 / steps as f32;
            let t1 = (i + 1) as f32 / steps as f32;
            let pt0 = bez.evaluate(t0);
            let pt1 = bez.evaluate(t1);
            img.draw_line(
                pt0.x as i32,
                pt0.y as i32,
                pt1.x as i32,
                pt1.y as i32,
                *cr,
                *cg,
                *cb,
                255,
            );
        }

        // Control points
        for pt in pts {
            img.draw_circle(pt.x as i32, pt.y as i32, 4, *cr, *cg, *cb, 255);
        }
    }
    img
}

// ── Procgen visualization ────────────────────────────────────────

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
/// - `num_sites` — `usize`. Number of Voronoi sites.
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

/// Render a noise map buffer as a grayscale image (normalised `[-1,1]` → `[0,255]`).
///
/// # Parameters
/// - `data` — `&[f64]`. Row-major noise values.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn noise_map_to_image(data: &[f64], width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    for y in 0..height {
        for x in 0..width {
            let val = data[(y * width + x) as usize];
            let v = ((val * 0.5 + 0.5).clamp(0.0, 1.0) * 255.0) as u8;
            img.set_pixel(x, y, v, v, v, 255);
        }
    }
    img
}

/// Render multiple noise maps side by side as a horizontal strip.
///
/// Each tile is `tile_w × tile_h` pixels. Data slices must each have
/// `tile_w * tile_h` elements.
///
/// # Parameters
/// - `maps` — `&[&[f64]]`. One data slice per tile.
/// - `tile_w` — `u32`.
/// - `tile_h` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn noise_comparison_to_image(maps: &[&[f64]], tile_w: u32, tile_h: u32) -> ImageData {
    let count = maps.len() as u32;
    let mut img = ImageData::new(tile_w * count, tile_h);
    for (i, data) in maps.iter().enumerate() {
        let ox = i as u32 * tile_w;
        for y in 0..tile_h {
            for x in 0..tile_w {
                let v = ((data[(y * tile_w + x) as usize] as f32 * 0.5 + 0.5) * 255.0)
                    .clamp(0.0, 255.0) as u8;
                img.set_pixel(ox + x, y, v, v, v, 255);
            }
        }
    }
    img
}

// ── Standalone shape and UI visualization helpers ─────────────────────────

/// Convert HSV colour to RGB bytes.
fn hsv_to_rgb_viz(h: u16, s: f32, v: f32) -> (u8, u8, u8) {
    let h = (h % 360) as f32;
    let c = v * s;
    let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
    let m = v - c;
    let (r, g, b) = match (h / 60.0) as u8 {
        0 => (c, x, 0.0f32),
        1 => (x, c, 0.0),
        2 => (0.0, c, x),
        3 => (0.0, x, c),
        4 => (x, 0.0, c),
        _ => (c, 0.0, x),
    };
    (
        ((r + m) * 255.0) as u8,
        ((g + m) * 255.0) as u8,
        ((b + m) * 255.0) as u8,
    )
}

/// Render a gallery of regular polygons (triangle→dodecagon), a five-pointed
/// star, and an arrow shape using `draw_line`.
///
/// # Parameters
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
///
/// # Returns
/// `ImageData`.
pub fn polygon_gallery_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    let shapes: &[(i32, i32, i32, usize, (u8, u8, u8))] = &[
        (85, 85, 60, 3, (255, 100, 100)),
        (255, 85, 60, 4, (100, 255, 100)),
        (425, 85, 60, 5, (100, 100, 255)),
        (85, 255, 60, 6, (255, 255, 100)),
        (255, 255, 60, 8, (255, 100, 255)),
        (425, 255, 60, 12, (100, 255, 255)),
    ];
    for &(cx, cy, radius, sides, (r, g, b)) in shapes {
        for i in 0..sides {
            let a0 = std::f32::consts::TAU * i as f32 / sides as f32 - std::f32::consts::FRAC_PI_2;
            let a1 =
                std::f32::consts::TAU * (i + 1) as f32 / sides as f32 - std::f32::consts::FRAC_PI_2;
            let x0 = cx + (radius as f32 * a0.cos()) as i32;
            let y0 = cy + (radius as f32 * a0.sin()) as i32;
            let x1 = cx + (radius as f32 * a1.cos()) as i32;
            let y1 = cy + (radius as f32 * a1.sin()) as i32;
            img.draw_line(x0, y0, x1, y1, r, g, b, 255);
        }
    }

    // Five-pointed star
    let (sx, sy, sr) = (170i32, 425i32, 70i32);
    let star_pts: Vec<(i32, i32)> = (0..10)
        .map(|i| {
            let angle = std::f32::consts::TAU * i as f32 / 10.0 - std::f32::consts::FRAC_PI_2;
            let rv = if i % 2 == 0 {
                sr as f32
            } else {
                sr as f32 * 0.4
            };
            (
                sx + (rv * angle.cos()) as i32,
                sy + (rv * angle.sin()) as i32,
            )
        })
        .collect();
    for i in 0..10 {
        let (x0, y0) = star_pts[i];
        let (x1, y1) = star_pts[(i + 1) % 10];
        img.draw_line(x0, y0, x1, y1, 255, 220, 50, 255);
    }

    // Arrow shape
    let (ax, ay) = (340i32, 425i32);
    let arrow: [(i32, i32); 7] = [
        (0, -50),
        (30, 0),
        (15, 0),
        (15, 50),
        (-15, 50),
        (-15, 0),
        (-30, 0),
    ];
    for i in 0..arrow.len() {
        let (x0, y0) = arrow[i];
        let (x1, y1) = arrow[(i + 1) % arrow.len()];
        img.draw_line(ax + x0, ay + y0, ax + x1, ay + y1, 255, 150, 50, 255);
    }

    img
}

/// Render concentric colored circles to demonstrate angular segment drawing.
///
/// # Parameters
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
///
/// # Returns
/// `ImageData`.
pub fn spiral_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    let (cx, cy) = (width as i32 / 2, height as i32 / 2);
    for ring in 1u32..=10 {
        let r = ring * 18;
        let steps = (r * 4).max(40) as usize;
        let (cr, cg, cb) = hsv_to_rgb_viz((ring * 36) as u16, 0.7, 0.9);
        for i in 0..steps {
            let a0 = std::f32::consts::TAU * i as f32 / steps as f32;
            let a1 = std::f32::consts::TAU * (i + 1) as f32 / steps as f32;
            let x0 = cx + (r as f32 * a0.cos()) as i32;
            let y0 = cy + (r as f32 * a0.sin()) as i32;
            let x1 = cx + (r as f32 * a1.cos()) as i32;
            let y1 = cy + (r as f32 * a1.sin()) as i32;
            img.draw_line(x0, y0, x1, y1, cr, cg, cb, 255);
        }
    }

    img
}

/// Render filled rectangle and circle primitives with HSV-coloured fills.
///
/// # Parameters
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
///
/// # Returns
/// `ImageData`.
pub fn filled_primitives_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    // Filled rectangles of increasing size
    for i in 0u32..5 {
        let x = 20 + i * 35;
        let size = 15 + i * 8;
        let hue = (i as f32 / 5.0 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb_viz(hue, 0.8, 0.9);
        img.draw_rect(x as i32, 20, size, size, r, g, b, 200);
    }

    // Filled circles of increasing size
    for i in 0u32..5 {
        let cx = (50 + i * 70) as i32;
        let radius = (10 + i * 5) as i32;
        let (r, g, b) = hsv_to_rgb_viz((i * 72) as u16, 0.8, 0.9);
        img.draw_circle(cx, 150, radius as u32, r, g, b, 200);
    }

    // Grid of small brightness dots
    for row in 0u32..16 {
        for col in 0u32..16 {
            let x = 20 + col * 22;
            let y = 200 + row * 12;
            let brightness = ((row * 16 + col) as u32 * 255 / 255).min(255) as u8;
            img.set_pixel(x, y, brightness, brightness, brightness, 255);
            img.set_pixel(x + 1, y, brightness, brightness, brightness, 255);
            img.set_pixel(x, y + 1, brightness, brightness, brightness, 255);
            img.set_pixel(x + 1, y + 1, brightness, brightness, brightness, 255);
        }
    }

    img
}

/// Render a mock settings panel with title bar, sliders, checkboxes, radio
/// buttons, progress bar, colour swatches, and action buttons.
///
/// # Parameters
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
///
/// # Returns
/// `ImageData`.
pub fn panel_layout_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(35, 35, 45, 255);

    let px = 30i32;
    let py = 20i32;
    let pw = 340i32;
    let ph = 300i32;

    // Shadow + body
    img.draw_rect(px + 3, py + 3, pw as u32, ph as u32, 15, 15, 20, 255);
    img.draw_rect(px, py, pw as u32, ph as u32, 55, 55, 65, 255);
    // Title bar
    img.draw_rect(px, py, pw as u32, 24, 70, 100, 160, 255);
    img.draw_label("SETTINGS PANEL", px + 8, py + 8, 220, 230, 240);
    // Close button
    let cbx = px + pw - 20;
    img.draw_rect(cbx, py + 4, 16, 16, 200, 60, 60, 255);
    img.draw_label("X", cbx + 5, py + 9, 255, 255, 255);

    let cy = py + 36;

    // Checkbox row
    img.draw_label("SOUND", px + 12, cy, 180, 180, 190);
    img.draw_rect(px + 80, cy - 2, 12, 12, 40, 40, 50, 255);
    img.draw_line(px + 82, cy + 3, px + 85, cy + 7, 100, 220, 100, 255);
    img.draw_line(px + 85, cy + 7, px + 90, cy, 100, 220, 100, 255);
    img.draw_label("ON", px + 96, cy, 100, 220, 100);

    // Volume slider
    let sy = cy + 20;
    img.draw_label("VOLUME", px + 12, sy, 180, 180, 190);
    let sl_x = px + 80;
    let sl_w = 200i32;
    img.draw_rect(sl_x, sy + 2, sl_w as u32, 4, 40, 40, 50, 255);
    let knob_x = sl_x + (sl_w as f32 * 0.7) as i32;
    img.draw_circle(knob_x, sy + 4, 5, 100, 160, 230, 255);
    img.draw_label("70%", knob_x + 8, sy - 2, 130, 180, 240);

    // Brightness slider
    let sy2 = sy + 24;
    img.draw_label("BRIGHT", px + 12, sy2, 180, 180, 190);
    img.draw_rect(sl_x, sy2 + 2, sl_w as u32, 4, 40, 40, 50, 255);
    let knob2_x = sl_x + (sl_w as f32 * 0.45) as i32;
    img.draw_circle(knob2_x, sy2 + 4, 5, 100, 160, 230, 255);
    img.draw_label("45%", knob2_x + 8, sy2 - 2, 130, 180, 240);

    // Dropdown
    let dy = sy2 + 28;
    img.draw_label("MODE", px + 12, dy, 180, 180, 190);
    img.draw_rect(sl_x, dy - 2, 120, 14, 45, 45, 55, 255);
    img.draw_label("FULLSCREEN", sl_x + 4, dy, 200, 200, 210);
    img.draw_line(sl_x + 108, dy + 2, sl_x + 112, dy + 6, 150, 150, 160, 255);
    img.draw_line(sl_x + 112, dy + 6, sl_x + 116, dy + 2, 150, 150, 160, 255);

    // Separator
    let sep_y = dy + 22;
    img.draw_line(px + 8, sep_y, px + pw - 8, sep_y, 70, 70, 80, 255);

    // Radio buttons
    let ry = sep_y + 8;
    img.draw_label("QUALITY", px + 12, ry, 180, 180, 190);
    let options = ["LOW", "MED", "HIGH"];
    for (i, &opt) in options.iter().enumerate() {
        let ox = sl_x + i as i32 * 56;
        for angle in 0..32i32 {
            let a = angle as f32 * std::f32::consts::PI / 16.0;
            let rx = ox + 5 + (a.cos() * 5.0) as i32;
            let ry_px = ry + 3 + (a.sin() * 5.0) as i32;
            if rx >= 0 && ry_px >= 0 && (rx as u32) < width && (ry_px as u32) < height {
                img.set_pixel(rx as u32, ry_px as u32, 140, 140, 150, 255);
            }
        }
        if i == 1 {
            img.draw_circle(ox + 5, ry + 3, 2, 100, 180, 230, 255);
        }
        img.draw_label(opt, ox + 14, ry, 170, 170, 180);
    }

    // Progress bar
    let pby = ry + 24;
    img.draw_label("LOADING", px + 12, pby, 180, 180, 190);
    img.draw_rect(sl_x, pby, sl_w as u32, 10, 40, 40, 50, 255);
    let fill_w = (sl_w as f32 * 0.65) as u32;
    img.draw_rect(sl_x, pby, fill_w, 10, 70, 160, 90, 255);
    img.draw_label("65%", sl_x + fill_w as i32 + 4, pby + 2, 130, 200, 140);

    // Colour swatches
    let csy = pby + 22;
    img.draw_label("THEME", px + 12, csy, 180, 180, 190);
    let swatch_colors: [(u8, u8, u8); 5] = [
        (200, 60, 60),
        (60, 160, 200),
        (60, 180, 80),
        (200, 180, 60),
        (160, 80, 200),
    ];
    for (i, &(cr, cg, cb)) in swatch_colors.iter().enumerate() {
        let sx = sl_x + i as i32 * 22;
        img.draw_rect(sx, csy - 2, 18, 14, cr, cg, cb, 255);
        if i == 1 {
            for edge in 0..18i32 {
                img.set_pixel((sx + edge) as u32, (csy - 2) as u32, 255, 255, 255, 255);
                img.set_pixel((sx + edge) as u32, (csy + 11) as u32, 255, 255, 255, 255);
            }
        }
    }

    // Action buttons
    let btn_y = py + ph - 30;
    img.draw_rect(px + pw - 80, btn_y, 60, 22, 60, 140, 60, 255);
    img.draw_label("OK", px + pw - 62, btn_y + 8, 220, 240, 220);
    img.draw_rect(px + pw - 150, btn_y, 60, 22, 160, 60, 60, 255);
    img.draw_label("CANCEL", px + pw - 144, btn_y + 8, 240, 220, 220);

    img
}

/// Render a game HUD with HP/MP/Stamina/XP bars and skill cooldown indicators.
///
/// # Parameters
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
///
/// # Returns
/// `ImageData`.
pub fn hud_bars_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 30, 255);

    let hx = 20i32;

    // HP bar
    let hy = 30i32;
    img.draw_label("HP", hx, hy - 10, 200, 80, 80);
    img.draw_rect(hx, hy, 300, 20, 40, 15, 15, 255);
    img.draw_rect(hx, hy, (300.0 * 0.75) as u32, 20, 200, 50, 50, 255);
    img.draw_rect(hx, hy, (300.0 * 0.75) as u32, 3, 240, 100, 100, 255);
    img.draw_label("75%", hx + 230, hy + 7, 255, 200, 200);

    // MP bar
    let my = hy + 36;
    img.draw_label("MP", hx, my - 10, 80, 120, 220);
    img.draw_rect(hx, my, 300, 20, 15, 15, 40, 255);
    img.draw_rect(hx, my, (300.0 * 0.40) as u32, 20, 50, 80, 200, 255);
    img.draw_rect(hx, my, (300.0 * 0.40) as u32, 3, 100, 140, 240, 255);
    img.draw_label("40%", hx + 124, my + 7, 180, 200, 255);

    // Stamina bar
    let sy = my + 36;
    img.draw_label("ST", hx, sy - 10, 80, 200, 80);
    img.draw_rect(hx, sy, 300, 14, 15, 30, 15, 255);
    img.draw_rect(hx, sy, (300.0 * 0.90) as u32, 14, 50, 180, 50, 255);
    img.draw_rect(hx, sy, (300.0 * 0.90) as u32, 2, 100, 220, 100, 255);
    img.draw_label("90%", hx + 275, sy + 4, 180, 255, 180);

    // XP bar
    let xy = sy + 30;
    img.draw_label("XP", hx, xy - 10, 220, 200, 80);
    img.draw_rect(hx, xy, 300, 8, 30, 25, 10, 255);
    img.draw_rect(hx, xy, (300.0 * 0.55) as u32, 8, 200, 180, 50, 255);
    img.draw_label("55% TO LVL 12", hx + 170, xy - 2, 230, 210, 120);

    // Skill cooldowns
    let cd_y = xy + 30;
    img.draw_label("SKILLS", hx, cd_y - 10, 180, 180, 190);
    let skill_pcts = [1.0f32, 0.7, 0.3, 0.0];
    let skill_colors: [(u8, u8, u8); 4] =
        [(80, 200, 80), (200, 200, 80), (200, 120, 60), (100, 40, 40)];
    for (i, (&pct, &(cr, cg, cb))) in skill_pcts.iter().zip(skill_colors.iter()).enumerate() {
        let scx = hx + 40 + i as i32 * 50;
        let scy = cd_y + 10;
        img.draw_circle(scx, scy, 16, 30, 30, 40, 255);
        if pct > 0.0 {
            let end_angle = -std::f32::consts::FRAC_PI_2 + pct * 2.0 * std::f32::consts::PI;
            for iy in (scy - 15)..=(scy + 15) {
                for ix in (scx - 15)..=(scx + 15) {
                    let dx = ix as f32 - scx as f32;
                    let dy = iy as f32 - scy as f32;
                    if dx * dx + dy * dy > 14.0 * 14.0 {
                        continue;
                    }
                    let mut a = dy.atan2(dx);
                    if a < -std::f32::consts::FRAC_PI_2 {
                        a += 2.0 * std::f32::consts::PI;
                    }
                    if a <= end_angle {
                        if ix >= 0 && iy >= 0 && (ix as u32) < width && (iy as u32) < height {
                            img.set_pixel(ix as u32, iy as u32, cr, cg, cb, 220);
                        }
                    }
                }
            }
        }
        img.draw_label(&format!("{}", i + 1), scx - 2, scy - 2, 255, 255, 255);
    }

    img.draw_label("GAME HUD", (width / 2 - 20) as i32, 10, 220, 220, 230);
    img
}

// ── Camera rotation visualization ───────────────────────────────

/// Render six camera rotation steps in a 3-column grid.
///
/// Each panel shows 8 world objects projected through a Camera2D with the
/// given rotation angle.
///
/// # Parameters
/// - `rotations` — `&[f32]`. Rotation angles in radians.
/// - `labels` — `&[&str]`. Short label for each panel.
/// - `panel_w` — `u32`. Width of each column panel.
/// - `panel_h` — `u32`. Height of each row panel.
///
/// # Returns
/// `ImageData`.
pub fn camera_rotation_to_image(
    rotations: &[f32],
    labels: &[&str],
    panel_w: u32,
    panel_h: u32,
) -> ImageData {
    let cols = 3u32;
    let rows = ((rotations.len() as u32) + cols - 1) / cols;
    let width = panel_w * cols;
    let height = panel_h * rows;
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    for (i, (&rot, &label)) in rotations.iter().zip(labels.iter()).enumerate() {
        let ox = (i % 3) as i32 * panel_w as i32;
        let oy = (i / 3) as i32 * panel_h as i32;
        let cx = panel_w as f32 / 2.0;
        let cy = panel_h as f32 / 2.0;

        let mut cam = Camera2D::new(panel_w as f32, panel_h as f32);
        cam.set_position(cx, cy);
        cam.set_rotation(rot);

        for step in 0..8u32 {
            let a = step as f32 * std::f32::consts::TAU / 8.0;
            let wx = cx + a.cos() * 35.0;
            let wy = cy + a.sin() * 35.0;
            let (sx, sy) = cam.to_screen_coords(wx, wy);
            let px = ox as f32 + sx;
            let py = oy as f32 + sy;
            let t = step as f32 / 8.0;
            let r = (80.0 + t * 175.0) as u8;
            let g = (200.0 - t * 120.0) as u8;
            if px >= 0.0 && px < width as f32 && py >= 0.0 && py < height as f32 {
                img.draw_circle(px as i32, py as i32, 5, r, g, 120, 220);
            }
        }

        // Frame border
        for bx in 0..panel_w as i32 {
            if ox + bx < width as i32 {
                img.set_pixel((ox + bx) as u32, oy.max(0) as u32, 60, 60, 80, 255);
                if (oy + panel_h as i32 - 1) >= 0 && (oy + panel_h as i32 - 1) < height as i32 {
                    img.set_pixel(
                        (ox + bx) as u32,
                        (oy + panel_h as i32 - 1) as u32,
                        60,
                        60,
                        80,
                        255,
                    );
                }
            }
        }
        img.draw_label(label, ox + 4, oy + 4, 200, 200, 200);
    }

    img.draw_label(
        "CAMERA ROTATION",
        (width / 2).saturating_sub(56) as i32,
        (height.saturating_sub(15)) as i32,
        100,
        200,
        100,
    );
    img
}

// ── Camera bounds visualization ──────────────────────────────────

/// Render a camera bounds-clamping summary panel.
///
/// Draws the world boundary box on the left and lists camera positions
/// with labels on the right to verify that look_at clamping works.
///
/// # Parameters
/// - `positions` — `&[(f32, f32, &str, u8, u8, u8)]`. (x, y, label, r, g, b).
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn camera_bounds_to_image(
    positions: &[(f32, f32, &str, u8, u8, u8)],
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    img.draw_rect(10, 10, 180, 180, 60, 60, 100, 255);
    img.draw_label("BOUNDS 0-400", 20, 14, 100, 100, 200);

    for (i, &(px, py, label, r, g, b)) in positions.iter().enumerate() {
        let y = 20 + i as i32 * 50;
        img.draw_rect(210, y, 180, 40, 40, 40, 55, 255);
        img.draw_label(label, 215, y + 5, r, g, b);
        let pos_str = format!("{:.0} {:.0}", px, py);
        img.draw_label(&pos_str, 215, y + 20, 180, 180, 180);
    }

    img.draw_label(
        "CAMERA BOUNDS",
        (width / 2).saturating_sub(48) as i32,
        (height.saturating_sub(15)) as i32,
        100,
        200,
        100,
    );
    img
}

// ── Camera follow / deadzone visualization ───────────────────────

/// Render a camera follow-and-deadzone trail diagram.
///
/// Draws the camera movement trail, coloured target markers, and the
/// deadzone rectangle centred on the final camera position.
///
/// # Parameters
/// - `trail` — `&[(f32, f32)]`. Camera position history.
/// - `targets` — `&[(f32, f32)]`. Target positions visited.
/// - `cam_pos` — `(f32, f32)`. Final camera position for deadzone centre.
/// - `dz_size` — `(f32, f32)`. Dead-zone (width, height).
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn camera_follow_to_image(
    trail: &[(f32, f32)],
    targets: &[(f32, f32)],
    cam_pos: (f32, f32),
    dz_size: (f32, f32),
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    for i in 1..trail.len() {
        let (x1, y1) = trail[i - 1];
        let (x2, y2) = trail[i];
        let t = i as f32 / trail.len().max(1) as f32;
        let r = (100.0 + t * 155.0) as u8;
        let g = (200.0 - t * 100.0) as u8;
        img.draw_line(x1 as i32, y1 as i32, x2 as i32, y2 as i32, r, g, 120, 200);
    }

    let tgt_colors: [(u8, u8, u8); 5] = [
        (255, 80, 80),
        (80, 255, 80),
        (80, 80, 255),
        (255, 255, 80),
        (200, 80, 255),
    ];
    for (i, &(tx, ty)) in targets.iter().enumerate() {
        let (r, g, b) = tgt_colors[i % tgt_colors.len()];
        img.draw_circle(tx as i32, ty as i32, 6, r, g, b, 255);
    }

    img.draw_rect(
        (cam_pos.0 - dz_size.0 / 2.0) as i32,
        (cam_pos.1 - dz_size.1 / 2.0) as i32,
        dz_size.0 as u32,
        dz_size.1 as u32,
        255,
        255,
        100,
        80,
    );

    img.draw_label(
        "FOLLOW AND DEADZONE",
        (width / 2).saturating_sub(72) as i32,
        (height.saturating_sub(15)) as i32,
        100,
        200,
        100,
    );
    img
}

// ── Camera shake visualization ───────────────────────────────────

/// Render a camera shake trail and move-by result.
///
/// Draws per-frame screen positions as fading red circles, marks the world
/// centre, and annotates the post-move-by camera position.
///
/// # Parameters
/// - `positions` — `&[(f32, f32)]`. Screen coordinates sampled each frame.
/// - `center` — `(f32, f32)`. World reference point.
/// - `moved` — `(f32, f32)`. Camera position after move_by.
/// - `area_info` — `&str`. Visible-area string to annotate.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn camera_shake_to_image(
    positions: &[(f32, f32)],
    center: (f32, f32),
    moved: (f32, f32),
    area_info: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    let n = positions.len().max(1) as f32;
    for (i, &(sx, sy)) in positions.iter().enumerate() {
        let t = i as f32 / n;
        let alpha = (255.0 * (1.0 - t)) as u8;
        let r = (200.0 + t * 55.0) as u8;
        img.draw_circle(sx as i32, sy as i32, 3, r, 80, 80, alpha);
    }

    img.draw_circle(center.0 as i32, center.1 as i32, 4, 255, 255, 255, 255);
    img.draw_label(
        "CENTER",
        (center.0 as i32 - 25).max(0),
        (center.1 as i32 - 16).max(0),
        255,
        255,
        255,
    );

    img.draw_circle(moved.0 as i32, moved.1 as i32, 4, 80, 255, 80, 255);
    img.draw_label(
        "MOVED BY",
        (moved.0 as i32 + 8).min(width as i32 - 60),
        (moved.1 as i32).min(height as i32 - 10),
        80,
        255,
        80,
    );

    img.draw_label(
        area_info,
        10,
        (height.saturating_sub(20)) as i32,
        180,
        180,
        200,
    );
    img.draw_label("CAMERA SHAKE AND MOVE", 100, 5, 100, 200, 100);
    img
}

// ── Animation playback-control visualization ─────────────────────

/// Render an animation playback-control timeline diagram.
///
/// Draws a run-frame bar, idle-frame bar, optional quad annotation, and a
/// summary footer showing total frame and clip counts.
///
/// # Parameters
/// - `run_frames` — `&[usize]`. Frame index active at each run step.
/// - `idle_frames` — `&[usize]`. Frame index active at each idle step.
/// - `total_frames` — `usize`. Total frame count in the animation.
/// - `quad_str` — `Option<&str>`. Optional quad coordinate annotation.
/// - `summary` — `&str`. Footer summary text.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn animation_playback_control_to_image(
    run_frames: &[usize],
    idle_frames: &[usize],
    total_frames: usize,
    quad_str: Option<&str>,
    summary: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    for (i, &f) in run_frames.iter().enumerate() {
        let x = 10 + i as i32 * 24;
        let t = if total_frames > 0 {
            f as f32 / total_frames as f32
        } else {
            0.0
        };
        let r = (80.0 + t * 175.0) as u8;
        let g = (200.0 - t * 120.0) as u8;
        img.draw_rect(x, 20, 20, 30, r, g, 80, 255);
    }
    img.draw_label("RUN FRAMES", 10, 55, 200, 200, 200);
    img.draw_label("PAUSE OK", 10, 80, 200, 200, 80);
    img.draw_label("RESUME OK", 10, 100, 80, 200, 80);
    img.draw_label("STOP OK", 10, 120, 200, 80, 80);

    for (i, &f) in idle_frames.iter().enumerate() {
        let x = 10 + i as i32 * 24;
        let t = if total_frames > 0 {
            f as f32 / total_frames as f32
        } else {
            0.0
        };
        let r = (60.0 + t * 140.0) as u8;
        let g = (160.0 - t * 100.0) as u8;
        img.draw_rect(x, 150, 20, 30, r, g, 60, 255);
    }
    img.draw_label("IDLE FRAMES", 10, 185, 200, 200, 200);

    if let Some(qs) = quad_str {
        img.draw_label(qs, 10, 220, 180, 180, 200);
    }

    img.draw_label("JUMP CLIP DONE", 10, 250, 200, 180, 100);
    img.draw_label(
        summary,
        10,
        (height.saturating_sub(20)) as i32,
        100,
        255,
        100,
    );
    img.draw_label(
        "ANIMATION PLAYBACK OK",
        150,
        (height.saturating_sub(20)) as i32,
        100,
        255,
        100,
    );
    img
}

/// Render audio samples as a waveform visualization.
///
/// Draws a waveform with a dark background, grid lines, center-zero line,
/// auto-scaled amplitude, and a blue waveform trace. Handles both oversampled
/// (min/max per pixel column) and undersampled (single sample) cases.
///
/// # Parameters
/// - `samples` — `&[f32]`. Audio samples, range typically –1.0..=1.0.
/// - `_sample_rate` — `u32`. Not currently used; reserved for future time-axis labels.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn waveform_to_image(samples: &[f32], _sample_rate: u32, width: u32, height: u32) -> ImageData {
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let plot_h = height - margin * 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    // Grid lines (horizontal)
    for i in 0..=4 {
        let y = margin as i32 + (plot_h as i32 * i / 4);
        for x in margin..width - margin {
            img.set_pixel(x, y as u32, 35, 35, 50, 255);
        }
    }
    // Grid lines (vertical, time markers)
    for i in 0..=8 {
        let x = margin as i32 + (plot_w as i32 * i / 8);
        for y in margin..height - margin {
            img.set_pixel(x as u32, y, 35, 35, 50, 255);
        }
    }
    // Center line (zero crossing)
    let center_y = margin + plot_h / 2;
    for x in margin..width - margin {
        img.set_pixel(x, center_y, 60, 60, 80, 255);
    }

    let peak = samples
        .iter()
        .map(|s| s.abs())
        .fold(0.0f32, f32::max)
        .max(0.01);
    let scale = 0.9 / peak;

    let samples_per_pixel = samples.len().max(1) / plot_w as usize;
    if samples_per_pixel > 0 {
        for x in 0..plot_w {
            let start = x as usize * samples_per_pixel;
            let end = (start + samples_per_pixel).min(samples.len());
            let mut min_val = f32::MAX;
            let mut max_val = f32::MIN;
            for &s in &samples[start..end] {
                let scaled = (s * scale).clamp(-1.0, 1.0);
                min_val = min_val.min(scaled);
                max_val = max_val.max(scaled);
            }
            let y_top = (margin as f32 + (1.0 - max_val) * 0.5 * plot_h as f32) as i32;
            let y_bot = (margin as f32 + (1.0 - min_val) * 0.5 * plot_h as f32) as i32;
            let px = (margin + x) as i32;
            img.draw_line(
                px,
                y_top.max(margin as i32),
                px,
                y_bot.min((height - margin) as i32),
                80,
                180,
                255,
                255,
            );
        }
    }

    // Border
    for x in margin..width - margin {
        img.set_pixel(x, margin, 60, 60, 80, 255);
        img.set_pixel(x, height - margin - 1, 60, 60, 80, 255);
    }
    for y in margin..height - margin {
        img.set_pixel(margin, y, 60, 60, 80, 255);
        img.set_pixel(width - margin - 1, y, 60, 60, 80, 255);
    }
    img
}

/// Render interleaved stereo audio samples as a two-channel waveform.
///
/// Splits interleaved L/R samples into two panels stacked vertically.
/// Left channel is cyan, right channel is orange. Both channels are
/// auto-scaled together based on the global peak amplitude.
///
/// # Parameters
/// - `samples` — `&[f32]`. Interleaved stereo samples (L, R, L, R …).
/// - `_sample_rate` — `u32`. Reserved for future time-axis labels.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn waveform_stereo_to_image(
    samples: &[f32],
    _sample_rate: u32,
    width: u32,
    height: u32,
) -> ImageData {
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let ch_height = (height - margin * 2) / 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    let left: Vec<f32> = samples.iter().step_by(2).copied().collect();
    let right: Vec<f32> = samples.iter().skip(1).step_by(2).copied().collect();

    let peak = samples
        .iter()
        .map(|s| s.abs())
        .fold(0.0f32, f32::max)
        .max(0.01);
    let scale = 0.85 / peak;

    let sep_y = margin + ch_height;
    for x in margin..width - margin {
        img.set_pixel(x, sep_y, 80, 80, 100, 255);
    }

    for ch in 0..2 {
        let base_y = margin + ch * ch_height;
        let center_y = base_y + ch_height / 2;
        for x in margin..width - margin {
            img.set_pixel(x, center_y, 40, 40, 55, 255);
        }
    }

    for (ch_idx, ch_samples) in [&left, &right].iter().enumerate() {
        let base_y = margin as f32 + ch_idx as f32 * ch_height as f32;
        let spp = ch_samples.len().max(1) / plot_w as usize;
        if spp == 0 {
            continue;
        }
        let (cr, cg, cb) = if ch_idx == 0 {
            (80, 200, 255)
        } else {
            (255, 160, 60)
        };
        for x in 0..plot_w {
            let start = x as usize * spp;
            let end = (start + spp).min(ch_samples.len());
            let mut min_val = f32::MAX;
            let mut max_val = f32::MIN;
            for &s in &ch_samples[start..end] {
                let sc = (s * scale).clamp(-1.0, 1.0);
                min_val = min_val.min(sc);
                max_val = max_val.max(sc);
            }
            let y_top = (base_y + (1.0 - max_val) * 0.5 * ch_height as f32) as i32;
            let y_bot = (base_y + (1.0 - min_val) * 0.5 * ch_height as f32) as i32;
            let px = (margin + x) as i32;
            let yt = y_top.max(margin as i32).min((height - margin) as i32);
            let yb = y_bot.max(margin as i32).min((height - margin) as i32);
            img.draw_line(px, yt, px, yb, cr, cg, cb, 255);
        }
    }
    img
}

/// Render a zoomed-in waveform showing individual sample cycles.
///
/// Only the first `max_samples` samples are rendered, enabling close
/// inspection of individual wave cycles. Uses linear interpolation
/// between adjacent samples and draws lines from the center to each
/// sample value.
///
/// # Parameters
/// - `samples` — `&[f32]`. Audio samples to visualize.
/// - `max_samples` — `usize`. Maximum number of samples to show (leading window).
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn waveform_zoomed_to_image(
    samples: &[f32],
    max_samples: usize,
    width: u32,
    height: u32,
) -> ImageData {
    let zoomed: Vec<f32> = samples.iter().take(max_samples).copied().collect();
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let plot_h = height - margin * 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);

    for i in 0..=4 {
        let y = margin as i32 + (plot_h as i32 * i / 4);
        for x in margin..width - margin {
            img.set_pixel(x, y as u32, 35, 35, 50, 255);
        }
    }
    for i in 0..=8 {
        let x = margin as i32 + (plot_w as i32 * i / 8);
        for y in margin..height - margin {
            img.set_pixel(x as u32, y, 35, 35, 50, 255);
        }
    }
    let center_y = margin + plot_h / 2;
    for x in margin..width - margin {
        img.set_pixel(x, center_y, 60, 60, 80, 255);
    }

    let peak = zoomed
        .iter()
        .map(|s| s.abs())
        .fold(0.0f32, f32::max)
        .max(0.01);
    let scale = 0.9 / peak;

    let n = zoomed.len();
    if n > 1 {
        for x in 0..plot_w {
            let sample_f = x as f32 / plot_w as f32 * (n - 1) as f32;
            let idx = sample_f as usize;
            let frac = sample_f - idx as f32;
            let s = if idx + 1 < n {
                zoomed[idx] * (1.0 - frac) + zoomed[idx + 1] * frac
            } else {
                zoomed[idx]
            };
            let scaled = (s * scale).clamp(-1.0, 1.0);
            let y = (margin as f32 + (1.0 - scaled) * 0.5 * plot_h as f32) as i32;
            let px = (margin + x) as i32;
            let cy = center_y as i32;
            let (y0, y1) = if y < cy { (y, cy) } else { (cy, y) };
            img.draw_line(
                px,
                y0.max(margin as i32),
                px,
                y1.min((height - margin) as i32),
                80,
                180,
                255,
                255,
            );
            if y >= margin as i32 && y < (height - margin) as i32 {
                img.set_pixel(px as u32, y as u32, 140, 220, 255, 255);
            }
        }
    }

    for x in margin..width - margin {
        img.set_pixel(x, margin, 60, 60, 80, 255);
        img.set_pixel(x, height - margin - 1, 60, 60, 80, 255);
    }
    for y in margin..height - margin {
        img.set_pixel(margin, y, 60, 60, 80, 255);
        img.set_pixel(width - margin - 1, y, 60, 60, 80, 255);
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

/// Render a grid of camera rotation panels, each showing 8 coloured dots
/// transformed through the rotation.
///
/// # Parameters
/// - `rotations` — `&[(f32, &str)]`. (angle, label) pairs.
/// - `viewport_w` — `f32`.
/// - `viewport_h` — `f32`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_rotation_grid_to_image(
    rotations: &[(f32, &str)],
    viewport_w: f32,
    viewport_h: f32,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    let cols = 3usize;
    let cell_w = (width / cols as u32) as i32;
    let cell_h = 150i32;

    for (i, &(rot, label)) in rotations.iter().enumerate() {
        let mut cam = Camera2D::new(viewport_w, viewport_h);
        cam.set_position(viewport_w / 2.0, viewport_h / 2.0);
        cam.set_rotation(rot);

        let ox = (i % cols) as i32 * cell_w;
        let oy = (i / cols) as i32 * cell_h;

        for step in 0..8 {
            let a = step as f32 * std::f32::consts::TAU / 8.0;
            let wx = viewport_w / 2.0 + a.cos() * 35.0;
            let wy = viewport_h / 2.0 + a.sin() * 35.0;
            let (sx, sy) = cam.to_screen_coords(wx, wy);
            let px = ox as f32 + sx;
            let py = oy as f32 + sy;
            if px >= 0.0 && px < width as f32 && py >= 0.0 && py < height as f32 {
                let hue = (step as f32 / 8.0 * 360.0) as u16;
                let (r, g, b) = hsv_to_rgb_viz(hue, 0.9, 1.0);
                img.draw_circle(px as i32, py as i32, 5, r, g, b, 220);
            }
        }

        // Frame border
        for bx in 0..viewport_w as i32 {
            if ox + bx < width as i32 {
                if oy >= 0 {
                    img.set_pixel((ox + bx) as u32, oy.max(0) as u32, 60, 60, 80, 255);
                }
                if oy + viewport_h as i32 - 1 < height as i32 && oy + viewport_h as i32 - 1 >= 0 {
                    img.set_pixel(
                        (ox + bx) as u32,
                        (oy + viewport_h as i32 - 1) as u32,
                        60,
                        60,
                        80,
                        255,
                    );
                }
            }
        }
        img.draw_label(label, ox + 4, oy + 4, 200, 200, 200);
    }

    img.draw_label(
        "CAMERA ROTATION",
        (width / 2 - 50) as i32,
        (height - 15) as i32,
        100,
        200,
        100,
    );
    img
}

/// Render a set of camera positions as labelled coloured rectangles.
///
/// # Parameters
/// - `positions` — `&[(f32, f32, &str, u8, u8, u8)]`. (x, y, label, r, g, b).
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_bounds_to_image(
    positions: &[(f32, f32, &str, u8, u8, u8)],
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // World bounds box
    img.draw_rect(10, 10, 180, 180, 60, 60, 100, 255);
    img.draw_label("BOUNDS 0-400", 20, 14, 100, 100, 200);

    for (i, &(px, py, label, r, g, b)) in positions.iter().enumerate() {
        let y = 20 + i as i32 * 50;
        img.draw_rect(210, y, 180, 40, 40, 40, 55, 255);
        img.draw_label(label, 215, y + 5, r, g, b);
        let pos_str = format!("{:.0} {:.0}", px, py);
        img.draw_label(&pos_str, 215, y + 20, 180, 180, 180);
    }

    img.draw_label(
        "CAMERA BOUNDS",
        (width / 2 - 40) as i32,
        (height - 15) as i32,
        100,
        200,
        100,
    );
    img
}

/// Render a camera follow trail with target points and dead-zone rectangle.
///
/// # Parameters
/// - `trail` — `&[(f32, f32)]`. Recorded camera positions.
/// - `targets` — `&[(f32, f32)]`. Target locations.
/// - `dead_zone` — `(f32, f32)`. Width and height of dead zone.
/// - `cam_pos` — `(f32, f32)`. Final camera position.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_follow_trail_to_image(
    trail: &[(f32, f32)],
    targets: &[(f32, f32)],
    dead_zone: (f32, f32),
    cam_pos: (f32, f32),
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // Draw the trail
    for i in 1..trail.len() {
        let (x1, y1) = trail[i - 1];
        let (x2, y2) = trail[i];
        let t = i as f32 / trail.len() as f32;
        let r = (100.0 + t * 155.0) as u8;
        let g = (200.0 - t * 100.0) as u8;
        let b = 120u8;
        img.draw_line(x1 as i32, y1 as i32, x2 as i32, y2 as i32, r, g, b, 200);
    }

    // Draw target points
    for (i, &(tx, ty)) in targets.iter().enumerate() {
        let hue = (i as f32 / targets.len().max(1) as f32 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb_viz(hue, 0.9, 1.0);
        img.draw_circle(tx as i32, ty as i32, 6, r, g, b, 255);
    }

    // Dead zone rectangle
    let (cx, cy) = cam_pos;
    let (dw, dh) = dead_zone;
    img.draw_rect(
        (cx - dw / 2.0) as i32,
        (cy - dh / 2.0) as i32,
        dw as u32,
        dh as u32,
        255,
        255,
        100,
        80,
    );

    img.draw_label(
        "FOLLOW AND DEADZONE",
        (width / 2 - 60) as i32,
        (height - 15) as i32,
        100,
        200,
        100,
    );
    img
}

/// Render a camera shake trail with fading circles and reference markers.
///
/// # Parameters
/// - `positions` — `&[(f32, f32)]`. Screen-coords of centre point each frame.
/// - `moved_pos` — `(f32, f32)`. Position after `move_by`.
/// - `visible_area` — `(f32, f32, f32, f32)`. (x, y, w, h) from `get_visible_area`.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_shake_trail_to_image(
    positions: &[(f32, f32)],
    moved_pos: (f32, f32),
    visible_area: (f32, f32, f32, f32),
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    let n = positions.len().max(1) as f32;
    for (i, &(sx, sy)) in positions.iter().enumerate() {
        let t = i as f32 / n;
        let alpha = (255.0 * (1.0 - t)) as u8;
        let r = (200.0 + t * 55.0) as u8;
        img.draw_circle(sx as i32, sy as i32, 3, r, 80, 80, alpha);
    }

    // Reference center
    img.draw_circle(
        (width / 2) as i32,
        (height / 2) as i32,
        4,
        255,
        255,
        255,
        255,
    );
    img.draw_label(
        "CENTER",
        (width / 2 - 20) as i32,
        (height / 2 - 16) as i32,
        255,
        255,
        255,
    );

    // Move-by indicator
    let (mx, my) = moved_pos;
    img.draw_circle(mx as i32, my as i32, 4, 80, 255, 80, 255);
    img.draw_label("MOVED BY", (mx as i32) + 10, (my as i32) + 10, 80, 255, 80);

    // Visible area info
    let (vx, vy, vw, vh) = visible_area;
    let info = format!("{:.0} {:.0} {:.0}X{:.0}", vx, vy, vw, vh);
    img.draw_label(&info, 10, (height - 20) as i32, 180, 180, 200);

    img.draw_label(
        "CAMERA SHAKE AND MOVE",
        (width / 2 - 70) as i32,
        5,
        100,
        200,
        100,
    );
    img
}

/// Render a graph with explicit node positions, labels, edge list, and stats.
///
/// # Parameters
/// - `positions` — `&[(f32, f32)]`. Node positions.
/// - `labels` — `&[&str]`. Node labels.
/// - `colors` — `&[(u8, u8, u8)]`. Node colours.
/// - `edges` — `&[(usize, usize)]`. Active edge index pairs.
/// - `removed_edges` — `&[(usize, usize)]`. Dashed/dim edge pairs.
/// - `stats_text` — `&str`. Stats string to draw at bottom-left.
/// - `title` — `&str`. Title text.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_graph_operations_to_image(
    positions: &[(f32, f32)],
    labels: &[&str],
    colors: &[(u8, u8, u8)],
    edges: &[(usize, usize)],
    removed_edges: &[(usize, usize)],
    stats_text: &str,
    title: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // Draw active edges
    for &(a, b) in edges {
        if a < positions.len() && b < positions.len() {
            let (ax, ay) = positions[a];
            let (bx, by) = positions[b];
            img.draw_line(
                ax as i32, ay as i32, bx as i32, by as i32, 80, 120, 180, 200,
            );
        }
    }

    // Draw removed edges (dimmed)
    for &(a, b) in removed_edges {
        if a < positions.len() && b < positions.len() {
            let (ax, ay) = positions[a];
            let (bx, by) = positions[b];
            img.draw_line(ax as i32, ay as i32, bx as i32, by as i32, 80, 40, 40, 100);
        }
    }

    // Draw nodes
    for (i, &(px, py)) in positions.iter().enumerate() {
        let (r, g, b) = if i < colors.len() {
            colors[i]
        } else {
            (180, 180, 180)
        };
        img.draw_circle(px as i32, py as i32, 14, r, g, b, 255);
        if i < labels.len() {
            img.draw_label(labels[i], (px - 30.0) as i32, (py + 18.0) as i32, r, g, b);
        }
    }

    img.draw_label(stats_text, 10, (height - 20) as i32, 200, 200, 200);
    img.draw_label(title, (width / 2 - 40) as i32, 5, 100, 255, 100);
    img
}

/// Render a pipeline graph with nodes, directional pipes, and item indicators.
///
/// # Parameters
/// - `node_pos` — `&[(f32, f32)]`. Node centre positions.
/// - `node_names` — `&[&str]`. Node labels drawn below each node.
/// - `node_colors` — `&[(u8, u8, u8)]`. Node fill colours.
/// - `items` — `&[(i32, i32, u8, u8, u8, &str)]`. (x, y, r, g, b, label) for item dots.
/// - `stats_text` — `&str`. Bottom-left stats string.
/// - `title` — `&str`. Top title.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_graph_item_flow_to_image(
    node_pos: &[(f32, f32)],
    node_names: &[&str],
    node_colors: &[(u8, u8, u8)],
    items: &[(i32, i32, u8, u8, u8, &str)],
    stats_text: &str,
    title: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // Draw pipes between consecutive nodes
    for i in 0..node_pos.len().saturating_sub(1) {
        let (ax, ay) = node_pos[i];
        let (bx, by) = node_pos[i + 1];
        let start_x = ax as i32 + 30;
        let end_x = bx as i32 - 30;
        img.draw_line(start_x, ay as i32, end_x, by as i32, 100, 150, 200, 200);
        // Arrow head
        img.draw_line(
            end_x - 10,
            by as i32 - 5,
            end_x,
            by as i32,
            100,
            150,
            200,
            200,
        );
        img.draw_line(
            end_x - 10,
            by as i32 + 5,
            end_x,
            by as i32,
            100,
            150,
            200,
            200,
        );
    }

    // Draw nodes
    for (i, &(px, py)) in node_pos.iter().enumerate() {
        let (r, g, b) = if i < node_colors.len() {
            node_colors[i]
        } else {
            (180, 180, 180)
        };
        img.draw_circle(px as i32, py as i32, 20, r, g, b, 255);
        if i < node_names.len() {
            img.draw_label(
                node_names[i],
                (px - 22.0) as i32,
                (py + 25.0) as i32,
                r,
                g,
                b,
            );
        }
    }

    // Draw items
    for &(ix, iy, ir, ig, ib, label) in items {
        img.draw_circle(ix, iy, 6, ir, ig, ib, 255);
        img.draw_label(label, ix - 10, iy - 15, ir, ig, ib);
    }

    img.draw_label(title, (width / 2 - 40) as i32, 5, 100, 255, 100);
    img.draw_label(stats_text, 10, (height - 20) as i32, 200, 200, 200);
    img
}

// ── Batch D: Geometry, Image, and Layer visualization helpers ────────────────

/// Draw a comprehensive geometry shapes & queries visualization.
///
/// Renders convex hull, polygon area/centroid, point-in-polygon test,
/// Bresenham line, angle measurement, circle containment, and circle-circle
/// intersection — all in a single composite image.
///
/// # Parameters
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_geometry_shapes_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);
    let w = width as i32;
    let h = height as i32;

    // 1. Convex hull
    let points: Vec<f32> = vec![
        50.0, 50.0, 100.0, 30.0, 150.0, 60.0, 130.0, 120.0, 80.0, 130.0, 40.0, 100.0, 90.0, 80.0,
        110.0, 70.0,
    ];
    let hull = crate::math::convex_hull(&points);
    for i in 0..points.len() / 2 {
        let px = points[i * 2] as i32;
        let py = points[i * 2 + 1] as i32;
        img.draw_circle(px, py, 3, 100, 100, 200, 255);
    }
    let hull_n = hull.len() / 2;
    for i in 0..hull_n {
        let j = (i + 1) % hull_n;
        img.draw_line(
            hull[i * 2] as i32,
            hull[i * 2 + 1] as i32,
            hull[j * 2] as i32,
            hull[j * 2 + 1] as i32,
            200,
            200,
            80,
            255,
        );
    }
    img.draw_label("CONVEX HULL", 50, 140, 200, 200, 80);

    // 2. Polygon area and centroid
    let square: Vec<f32> = vec![200.0, 20.0, 280.0, 20.0, 280.0, 100.0, 200.0, 100.0];
    let area = crate::math::polygon_area(&square);
    let (cx, cy) = crate::math::polygon_centroid(&square);
    img.draw_line(200, 20, 280, 20, 80, 200, 80, 255);
    img.draw_line(280, 20, 280, 100, 80, 200, 80, 255);
    img.draw_line(280, 100, 200, 100, 80, 200, 80, 255);
    img.draw_line(200, 100, 200, 20, 80, 200, 80, 255);
    img.draw_circle(cx as i32, cy as i32, 4, 255, 100, 100, 255);
    let area_str = format!("AREA {:.0}", area.abs());
    img.draw_label(&area_str, 200, 108, 80, 200, 80);

    // 3. Point-in-polygon
    let _triangle: Vec<f32> = vec![350.0, 30.0, 450.0, 100.0, 340.0, 100.0];
    img.draw_line(350, 30, 450, 100, 200, 120, 80, 255);
    img.draw_line(450, 100, 340, 100, 200, 120, 80, 255);
    img.draw_line(340, 100, 350, 30, 200, 120, 80, 255);
    // inside = green, outside = red
    img.draw_circle(380, 70, 4, 0, 255, 0, 255);
    img.draw_circle(320, 30, 4, 255, 0, 0, 255);
    img.draw_label("POINT IN POLY", 340, 108, 200, 120, 80);

    // 4. Bresenham line
    let line_pts = crate::math::bresenham(20, 180, 180, 220);
    for &(px, py) in &line_pts {
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 255, 180, 80, 255);
        }
    }
    img.draw_label("BRESENHAM", 20, 230, 255, 180, 80);

    // 5. Angle between
    let angle = crate::math::angle_between(250.0, 200.0, 350.0, 250.0);
    img.draw_line(250, 200, 350, 250, 200, 80, 200, 255);
    let angle_str = format!("{:.2} RAD", angle);
    img.draw_label(&angle_str, 270, 255, 200, 80, 200);

    // 6. Circle containment
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (100.0 + 40.0 * rad.cos()) as i32;
        let py = (300.0 + 40.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 80, 200, 200, 255);
        }
    }
    img.draw_circle(110, 310, 3, 0, 255, 0, 255);
    img.draw_circle(200, 300, 3, 255, 0, 0, 255);
    img.draw_label("CIRCLE CONTAIN", 60, 350, 80, 200, 200);

    // 7. Circle-circle intersection
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px1 = (300.0 + 30.0 * rad.cos()) as i32;
        let py1 = (300.0 + 30.0 * rad.sin()) as i32;
        let px2 = (340.0 + 30.0 * rad.cos()) as i32;
        let py2 = (340.0 + 30.0 * rad.sin()) as i32;
        if px1 >= 0 && py1 >= 0 && px1 < w && py1 < h {
            img.set_pixel(px1 as u32, py1 as u32, 200, 100, 100, 255);
        }
        if px2 >= 0 && py2 >= 0 && px2 < w && py2 < h {
            img.set_pixel(px2 as u32, py2 as u32, 100, 200, 100, 255);
        }
    }
    img.draw_label("CC INTERSECT", 290, 340, 200, 200, 100);

    img.draw_label("GEOMETRY SHAPES OK", 170, (h - 15).max(0), 100, 255, 100);
    img
}

/// Draw geometry intersection tests visualization.
///
/// Renders segment-segment, closest-point, circle-line, circle-segment,
/// and line-line intersections in a single composite image.
///
/// # Parameters
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_geometry_intersections_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);
    let w = width as i32;
    let h = height as i32;

    // 1. Segment-segment intersection
    let (_hit, point) =
        crate::math::segment_intersects_segment(20.0, 20.0, 150.0, 120.0, 20.0, 120.0, 150.0, 20.0);
    img.draw_line(20, 20, 150, 120, 200, 80, 80, 255);
    img.draw_line(20, 120, 150, 20, 80, 80, 200, 255);
    if let Some((ix, iy)) = point {
        img.draw_circle(ix as i32, iy as i32, 5, 255, 255, 80, 255);
    }
    img.draw_label("SEG-SEG", 60, 130, 200, 200, 80);

    // 2. No intersection
    let (_no_hit, _) = crate::math::segment_intersects_segment(
        20.0, 160.0, 100.0, 160.0, 20.0, 200.0, 100.0, 200.0,
    );
    img.draw_line(20, 160, 100, 160, 200, 80, 80, 255);
    img.draw_line(20, 200, 100, 200, 80, 200, 80, 255);
    img.draw_label("NO HIT", 30, 210, 200, 80, 80);

    // 3. Closest point on segment
    let (cpx, cpy) = crate::math::closest_point_on_segment(250.0, 30.0, 200.0, 80.0, 350.0, 80.0);
    img.draw_line(200, 80, 350, 80, 80, 180, 200, 255);
    img.draw_circle(250, 30, 4, 255, 100, 100, 255);
    img.draw_circle(cpx as i32, cpy as i32, 4, 100, 255, 100, 255);
    img.draw_line(250, 30, cpx as i32, cpy as i32, 150, 150, 150, 150);
    img.draw_label("CLOSEST PT", 230, 90, 80, 180, 200);

    // 4. Circle-line intersection
    let (_cl_hit, p1, p2) =
        crate::math::circle_intersects_line(300.0, 200.0, 50.0, 200.0, 200.0, 400.0, 200.0);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (300.0 + 50.0 * rad.cos()) as i32;
        let py = (200.0 + 50.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 100, 100, 200, 255);
        }
    }
    img.draw_line(200, 200, 400, 200, 200, 200, 200, 150);
    if let Some((ix, iy)) = p1 {
        img.draw_circle(ix as i32, iy as i32, 4, 255, 80, 80, 255);
    }
    if let Some((ix, iy)) = p2 {
        img.draw_circle(ix as i32, iy as i32, 4, 80, 255, 80, 255);
    }
    img.draw_label("CIRCLE-LINE", 273, 260, 100, 100, 200);

    // 5. Circle-segment intersection
    let (cs_hit, sp1, sp2) =
        crate::math::circle_intersects_segment(100.0, 300.0, 30.0, 60.0, 280.0, 140.0, 320.0);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (100.0 + 30.0 * rad.cos()) as i32;
        let py = (300.0 + 30.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 200, 150, 80, 255);
        }
    }
    img.draw_line(60, 280, 140, 320, 180, 180, 180, 200);
    if cs_hit {
        if let Some((ix, iy)) = sp1 {
            img.draw_circle(ix as i32, iy as i32, 3, 255, 200, 80, 255);
        }
        if let Some((ix, iy)) = sp2 {
            img.draw_circle(ix as i32, iy as i32, 3, 80, 200, 255, 255);
        }
    }
    img.draw_label("CIRCLE-SEG", 60, 335, 200, 150, 80);

    // 6. Line intersection (infinite lines)
    let result =
        crate::math::line_intersect(200.0, 260.0, 400.0, 340.0, 200.0, 340.0, 400.0, 260.0);
    img.draw_line(200, 260, 400, 340, 200, 80, 200, 200);
    img.draw_line(200, 340, 400, 260, 80, 200, 200, 200);
    if let Some((ix, iy)) = result {
        img.draw_circle(ix as i32, iy as i32, 5, 255, 255, 100, 255);
    }
    img.draw_label("LINE INTERSECT", 260, 345, 200, 200, 200);

    img.draw_label("GEOMETRY INTERSECTIONS OK", 120, 3, 100, 255, 100);
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

/// Draw a side-by-side comparison of multiple images.
///
/// Places each input image horizontally with a label below, with 5px padding.
///
/// # Parameters
/// - `images` — `&[&ImageData]`. Images to display side-by-side.
/// - `labels` — `&[&str]`. Labels for each column.
/// - `width` — `u32`. Total output width.
/// - `height` — `u32`. Total output height.
///
/// # Returns
/// `ImageData`.
pub fn draw_image_comparison_to_image(
    images: &[&ImageData],
    labels: &[&str],
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    if images.is_empty() {
        return img;
    }

    let count = images.len() as u32;
    let padding = 5u32;
    let slot_w = (width - padding * (count + 1)) / count;
    let max_h = height.saturating_sub(30); // leave room for labels

    for (idx, &src) in images.iter().enumerate() {
        let x_off = padding + idx as u32 * (slot_w + padding);
        let y_off = 10u32;
        let src_w = src.width().min(slot_w);
        let src_h = src.height().min(max_h);
        for sy in 0..src_h {
            for sx in 0..src_w {
                if let Some((r, g, b, a)) = src.get_pixel(sx, sy) {
                    img.set_pixel(x_off + sx, y_off + sy, r, g, b, a);
                }
            }
        }
        if idx < labels.len() {
            let lx = x_off as i32 + (slot_w as i32 / 2) - 20;
            let ly = (y_off + src_h + 3) as i32;
            img.draw_label(labels[idx], lx, ly, 200, 200, 200);
        }
    }
    img
}

/// Draw a 4-column pixel transform grid: original, invert, grayscale, sepia.
///
/// Takes a source pattern (100×height) and produces a 4-column display.
///
/// # Parameters
/// - `col_w` — `u32`. Width of each column.
/// - `col_h` — `u32`. Height of each column.
///
/// # Returns
/// `ImageData`.
pub fn draw_pixel_transform_grid_to_image(col_w: u32, col_h: u32) -> ImageData {
    let width = col_w * 4;
    let height = col_h;
    let mut img = ImageData::new(width, height);

    // Column 1: original red-green gradient
    for y in 0..col_h {
        for x in 0..col_w {
            let r = (x as u32 * 255 / col_w) as u8;
            let g = (y as u32 * 255 / col_h) as u8;
            let b = 128u8;
            img.set_pixel(x, y, r, g, b, 255);
        }
    }

    // Column 2: invert
    for y in 0..col_h {
        for x in 0..col_w {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                img.set_pixel(col_w + x, y, 255 - r, 255 - g, 255 - b, 255);
            }
        }
    }

    // Column 3: grayscale
    for y in 0..col_h {
        for x in 0..col_w {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                let gray = ((r as u16 + g as u16 + b as u16) / 3) as u8;
                img.set_pixel(col_w * 2 + x, y, gray, gray, gray, 255);
            }
        }
    }

    // Column 4: sepia tone
    for y in 0..col_h {
        for x in 0..col_w {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                let gray = ((r as u16 + g as u16 + b as u16) / 3) as u8;
                let sr = (gray as u16)
                    .saturating_mul(255)
                    .saturating_div(200)
                    .min(255) as u8;
                let sg = (gray as u16)
                    .saturating_mul(200)
                    .saturating_div(200)
                    .min(255) as u8;
                let sb = (gray as u16)
                    .saturating_mul(150)
                    .saturating_div(200)
                    .min(255) as u8;
                img.set_pixel(col_w * 3 + x, y, sr, sg, sb, 255);
            }
        }
    }
    img
}

/// Draw an HSV colour wheel.
///
/// Generates radial hue-saturation gradient in a circle centred in the image.
///
/// # Parameters
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_color_wheel_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    let cx = width as f32 / 2.0;
    let cy = height as f32 / 2.0;
    let radius = cx.min(cy) * 0.9;
    for y in 0..height {
        for x in 0..width {
            let dx = x as f32 - cx;
            let dy = y as f32 - cy;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist < radius {
                let angle = dy.atan2(dx);
                let hue = ((angle + std::f32::consts::PI) / std::f32::consts::TAU * 360.0) as u16;
                let sat = dist / radius;
                let (r, g, b) = hsv_to_rgb_viz(hue, sat, 1.0);
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
    }
    img
}

/// Draw a single waveform as a colored plot on a dark background.
///
/// # Parameters
/// - `samples` — `&[f32]`. Audio sample data.
/// - `label` — `&str`. Title text drawn at bottom.
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
/// - `color` — `(u8, u8, u8)`. Line colour.
///
/// # Returns
/// `ImageData`.
pub fn draw_sound_waveform_to_image(
    samples: &[f32],
    label: &str,
    width: u32,
    height: u32,
    color: (u8, u8, u8),
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    let margin = 10u32;
    let plot_w = width.saturating_sub(margin * 2);
    let mid_y = (height / 2) as i32;

    // Center line
    img.draw_line(
        margin as i32,
        mid_y,
        (width - margin) as i32,
        mid_y,
        60,
        60,
        80,
        150,
    );

    let step = if plot_w == 0 {
        1
    } else {
        samples.len().max(1) / plot_w as usize
    };
    let step = step.max(1);
    let h_half = (height / 2) as f32 * 0.8;

    for x in 0..plot_w {
        let idx = x as usize * step;
        if idx < samples.len() {
            let val = samples[idx];
            let y = (mid_y as f32 - val * h_half) as i32;
            let y = y.clamp(0, height as i32 - 1);
            let t = x as f32 / plot_w as f32;
            let r = ((color.0 as f32) * (0.6 + t * 0.4)) as u8;
            let g = ((color.1 as f32) * (1.0 - t * 0.3)) as u8;
            let b = color.2;
            img.draw_circle((x + margin) as i32, y, 1, r, g, b, 255);
        }
    }

    img.draw_label(label, margin as i32, (height - 15) as i32, 100, 255, 100);
    img
}

/// Draw a bezier advanced operations overview.
///
/// Renders the original curve, its derivative, a segment highlight,
/// control point editing, and transform operations.
///
/// # Parameters
/// - `width` — `u32`. Image width.
/// - `height` — `u32`. Image height.
///
/// # Returns
/// `ImageData`.
pub fn draw_bezier_advanced_to_image(width: u32, height: u32) -> ImageData {
    use crate::math::bezier::BezierCurve;
    use crate::math::vec2::Vec2;

    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // 1. Main curve + derivative
    let curve = BezierCurve::new(vec![
        Vec2::new(50.0, 200.0),
        Vec2::new(150.0, 50.0),
        Vec2::new(300.0, 50.0),
        Vec2::new(400.0, 200.0),
    ]);
    let pts = curve.render(60);
    for i in 1..pts.len() {
        img.draw_line(
            pts[i - 1].x as i32,
            pts[i - 1].y as i32,
            pts[i].x as i32,
            pts[i].y as i32,
            200,
            120,
            80,
            255,
        );
    }

    // Derivative (scaled + offset)
    let deriv = curve.get_derivative();
    let dpts = deriv.render(40);
    for i in 1..dpts.len() {
        let x1 = 50 + (dpts[i - 1].x * 0.3) as i32;
        let y1 = 350 + (dpts[i - 1].y * 0.3) as i32;
        let x2 = 50 + (dpts[i].x * 0.3) as i32;
        let y2 = 350 + (dpts[i].y * 0.3) as i32;
        if x1 >= 0
            && y1 >= 0
            && x2 < width as i32
            && y2 < height as i32
            && x1 < width as i32
            && y1 < height as i32
        {
            img.draw_line(x1, y1, x2, y2, 80, 200, 200, 200);
        }
    }
    img.draw_label("DERIVATIVE", 10, 330, 80, 200, 200);

    // 2. render_segment highlight
    let seg_pts = curve.render_segment(0.2, 0.8, 30);
    for i in 1..seg_pts.len() {
        img.draw_line(
            seg_pts[i - 1].x as i32,
            (seg_pts[i - 1].y + 5.0) as i32,
            seg_pts[i].x as i32,
            (seg_pts[i].y + 5.0) as i32,
            255,
            255,
            80,
            255,
        );
    }
    img.draw_label("SEGMENT 0.2-0.8", 150, 210, 255, 255, 80);

    // 3. Control point manipulation
    let mut editable = BezierCurve::new(vec![
        Vec2::new(300.0, 280.0),
        Vec2::new(350.0, 230.0),
        Vec2::new(450.0, 280.0),
    ]);

    // Draw original control points
    for i in 0..editable.get_control_point_count() {
        if let Some(cp) = editable.get_control_point(i) {
            img.draw_circle(cp.x as i32, cp.y as i32, 4, 200, 200, 200, 255);
        }
    }
    let orig_pts = editable.render(20);
    for i in 1..orig_pts.len() {
        img.draw_line(
            orig_pts[i - 1].x as i32,
            orig_pts[i - 1].y as i32,
            orig_pts[i].x as i32,
            orig_pts[i].y as i32,
            150,
            150,
            150,
            200,
        );
    }

    editable.set_control_point(1, Vec2::new(350.0, 200.0));
    editable.insert_control_point(Vec2::new(400.0, 250.0), Some(2));

    let edited_pts = editable.render(20);
    for i in 1..edited_pts.len() {
        img.draw_line(
            edited_pts[i - 1].x as i32,
            edited_pts[i - 1].y as i32,
            edited_pts[i].x as i32,
            edited_pts[i].y as i32,
            80,
            200,
            80,
            255,
        );
    }

    editable.remove_control_point(3);

    // 4. Transform operations
    let mut transform_curve = BezierCurve::new(vec![
        Vec2::new(300.0, 320.0),
        Vec2::new(350.0, 300.0),
        Vec2::new(400.0, 320.0),
    ]);
    let t_pts = transform_curve.render(15);
    for i in 1..t_pts.len() {
        img.draw_line(
            t_pts[i - 1].x as i32,
            t_pts[i - 1].y as i32,
            t_pts[i].x as i32,
            t_pts[i].y as i32,
            200,
            80,
            80,
            180,
        );
    }
    transform_curve.translate(0.0, 20.0);
    let tt_pts = transform_curve.render(15);
    for i in 1..tt_pts.len() {
        img.draw_line(
            tt_pts[i - 1].x as i32,
            tt_pts[i - 1].y as i32,
            tt_pts[i].x as i32,
            tt_pts[i].y as i32,
            80,
            80,
            200,
            180,
        );
    }

    // Length + midpoint
    let len = curve.length();
    let len_str = format!("LEN {:.0}", len);
    img.draw_label(&len_str, 300, 215, 200, 200, 200);

    let (ix, iy) = curve.get_interpolated_position(0.5);
    img.draw_circle(ix as i32, iy as i32, 5, 255, 100, 255, 255);
    let angle = curve.get_interpolated_angle(0.5);
    let angle_str = format!("A {:.2}", angle);
    img.draw_label(&angle_str, ix as i32 + 8, iy as i32, 255, 100, 255);

    img.draw_label(
        "BEZIER ADVANCED OK",
        150,
        (height - 15) as i32,
        100,
        255,
        100,
    );
    img
}

// ── draw_to_image entry points ────────────────────────────────────────────────
//
// `Animation` and `Camera2D` cannot import `crate::image` (circular dependency:
// `crate::image::visualization` already imports those types). These free functions
// provide the standard `draw_to_image(width, height) -> ImageData` interface for
// callers that have an `&Animation` or `&Camera2D` but need a CPU pixel buffer.

/// Render an animation as a CPU image for headless testing.
///
/// Delegates to [`draw_animation_frame_grid_to_image`] with cell dimensions
/// derived from the requested output size and frame count.
///
/// # Parameters
/// - `anim` — `&Animation`. Animation controller to render.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn draw_animation_to_image(anim: &Animation, width: u32, height: u32) -> ImageData {
    let frame_count = anim.get_frame_count().max(1) as u32;
    let cols = frame_count.min(8);
    let cell_w = (width / cols).max(1);
    let cell_h = height.max(1);
    draw_animation_frame_grid_to_image(anim, cell_w, cell_h)
}

/// Render a camera as a CPU image for headless testing.
///
/// Delegates to [`draw_camera_debug_to_image`] using the output dimensions as
/// world dimensions, producing a 1:1 grid with the camera viewport overlaid.
///
/// # Parameters
/// - `cam` — `&Camera2D`. Camera to visualize.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn draw_camera_to_image(cam: &Camera2D, width: u32, height: u32) -> ImageData {
    draw_camera_debug_to_image(cam, width as f32, height as f32, width, height)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::animation::Animation;

    fn make_anim_with_frames(count: usize) -> Animation {
        let mut anim = Animation::new();
        for _ in 0..count {
            anim.add_frame(crate::math::Rect::new(0.0, 0.0, 16.0, 16.0));
        }
        anim
    }

    #[test]
    fn draw_animation_frame_grid_produces_correct_dimensions() {
        // 3 frames, cell 4x4 → strip: min(3,8)=3 cols, 1 row → 12x4 image
        let anim = make_anim_with_frames(3);
        let img = draw_animation_frame_grid_to_image(&anim, 4, 4);
        assert_eq!(img.width(), 12);
        assert_eq!(img.height(), 4);
    }

    #[test]
    fn draw_animation_frame_grid_zero_frames_uses_one_cell() {
        let anim = make_anim_with_frames(0);
        let img = draw_animation_frame_grid_to_image(&anim, 8, 8);
        // max(0,1)=1 frame → 1 col, 1 row → 8x8
        assert_eq!(img.width(), 8);
        assert_eq!(img.height(), 8);
    }
}
