use super::dda::Raycaster2D;
use super::lighting::{compute_lighting, PointLight};
use std::collections::HashSet;
#[derive(Debug, Clone)]
pub struct MinimapTileSample {
    pub x: u32,
    pub y: u32,
    pub blocked: bool,
    pub visible: bool,
    pub light: [f32; 3],
    pub luma: f32,
}
fn tile_line_of_sight(raycaster: &Raycaster2D, x0: i32, y0: i32, x1: i32, y1: i32) -> bool {
    let mut x = x0;
    let mut y = y0;
    let dx = (x1 - x0).abs();
    let dy = (y1 - y0).abs();
    let sx = if x0 < x1 { 1 } else { -1 };
    let sy = if y0 < y1 { 1 } else { -1 };
    let mut err = dx - dy;
    while !(x == x1 && y == y1) {
        let e2 = 2 * err;
        if e2 > -dy {
            err -= dy;
            x += sx;
        }
        if e2 < dx {
            err += dx;
            y += sy;
        }
        if (x != x1 || y != y1) && (x < 0 || y < 0 || raycaster.get_cell(x as u32, y as u32) > 0) {
            return false;
        }
    }
    true
}
pub fn compute_tile_light(
    raycaster: &Raycaster2D,
    x: u32,
    y: u32,
    ambient: f32,
    lights: &[PointLight],
) -> [f32; 3] {
    if x >= raycaster.width() || y >= raycaster.height() {
        let a = ambient.clamp(0.0, 1.0);
        return [a, a, a];
    }
    let wx = x as f32 + 0.5;
    let wy = y as f32 + 0.5;
    let wall_at = |cx: i32, cy: i32| -> bool {
        cx < 0 || cy < 0 || raycaster.get_cell(cx as u32, cy as u32) > 0
    };
    compute_lighting(wx, wy, ambient, lights, &wall_at)
}
pub fn build_minimap_tile_window(
    raycaster: &Raycaster2D,
    center_x: f32,
    center_y: f32,
    radius: u32,
    ambient: f32,
    lights: &[PointLight],
) -> Vec<MinimapTileSample> {
    let cx = center_x.floor() as i32;
    let cy = center_y.floor() as i32;
    let r = radius as i32;
    let mut out = Vec::new();
    for gy in (cy - r)..=(cy + r) {
        for gx in (cx - r)..=(cx + r) {
            if gx < 0 || gy < 0 {
                continue;
            }
            let ux = gx as u32;
            let uy = gy as u32;
            if ux >= raycaster.width() || uy >= raycaster.height() {
                continue;
            }
            let blocked = raycaster.get_cell(ux, uy) > 0;
            let visible = tile_line_of_sight(raycaster, cx, cy, gx, gy);
            let light = compute_tile_light(raycaster, ux, uy, ambient, lights);
            let luma = ((light[0] + light[1] + light[2]) / 3.0).clamp(0.0, 1.0);
            out.push(MinimapTileSample {
                x: ux,
                y: uy,
                blocked,
                visible,
                light,
                luma,
            });
        }
    }
    out
}
#[allow(clippy::too_many_arguments)]
pub fn reveal_cells_from_rays(
    raycaster: &Raycaster2D,
    ox: f32,
    oy: f32,
    angle: f32,
    fov: f32,
    count: u32,
    max_dist: f32,
    step: f32,
) -> Vec<(u32, u32)> {
    let step = step.max(0.05);
    let mut visited: HashSet<(u32, u32)> = HashSet::new();
    let mut cells = Vec::new();
    let add_cell =
        |visited: &mut HashSet<(u32, u32)>, cells: &mut Vec<(u32, u32)>, x: f32, y: f32| {
            if x.is_finite() && y.is_finite() && x >= 0.0 && y >= 0.0 {
                let gx = x.floor() as u32;
                let gy = y.floor() as u32;
                if gx < raycaster.width() && gy < raycaster.height() && visited.insert((gx, gy)) {
                    cells.push((gx, gy));
                }
            }
        };
    add_cell(&mut visited, &mut cells, ox, oy);
    let hits = raycaster.cast_rays(ox, oy, angle, fov, count, max_dist);
    for hit in hits {
        let hx = if hit.hit {
            hit.hit_x
        } else {
            ox + angle.cos() * max_dist
        };
        let hy = if hit.hit {
            hit.hit_y
        } else {
            oy + angle.sin() * max_dist
        };
        let dx = hx - ox;
        let dy = hy - oy;
        let dist = (dx * dx + dy * dy).sqrt();
        let steps = (dist / step).max(1.0).floor() as u32;
        for i in 0..=steps {
            let t = i as f32 / steps as f32;
            add_cell(&mut visited, &mut cells, ox + dx * t, oy + dy * t);
        }
    }
    cells
}
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
    let center_px = view_radius * cell_size + cell_size / 2;
    let center_py = view_radius * cell_size + cell_size / 2;
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
