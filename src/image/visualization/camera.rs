use super::hsv_to_rgb_viz;
use crate::camera::Camera2D;
use crate::image::ImageData;
pub fn draw_camera_debug_to_image(
    cam: &Camera2D,
    world_w: f32,
    world_h: f32,
    img_w: u32,
    img_h: u32,
) -> ImageData {
    let mut img = ImageData::new(img_w, img_h);
    img.fill(20, 20, 30, 255);
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
    let pcx = (cx * sx) as i32;
    let pcy = (cy * sy) as i32;
    img.draw_line(pcx - 8, pcy, pcx + 8, pcy, 255, 100, 100, 200);
    img.draw_line(pcx, pcy - 8, pcx, pcy + 8, 255, 100, 100, 200);
    let info = format!("zoom:{:.1}", zoom);
    img.draw_label(&info, 4, 4, 200, 200, 255);
    img
}
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
        let spacing = (16.0 * z.max(0.1)) as u32;
        let spacing = spacing.max(4).min(panel_w);
        for dy in (20..panel_h).step_by(spacing as usize) {
            for dx in (0..panel_w).step_by(spacing as usize) {
                if (ox + dx) < width {
                    img.set_pixel(ox + dx, dy, 60, 60, 80, 180);
                }
            }
        }
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
pub fn camera_rotation_to_image(
    rotations: &[f32],
    labels: &[&str],
    panel_w: u32,
    panel_h: u32,
) -> ImageData {
    let cols = 3u32;
    let rows = (rotations.len() as u32).div_ceil(cols);
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
        for bx in 0..viewport_w as i32 {
            if ox + bx < width as i32 {
                if oy >= 0 {
                    img.set_pixel((ox + bx) as u32, oy.max(0) as u32, 60, 60, 80, 255);
                }
                if oy + viewport_h as i32 - 1 < height as i32 && oy + viewport_h as i32 > 0 {
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
pub fn draw_camera_bounds_to_image(
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
        (width / 2 - 40) as i32,
        (height - 15) as i32,
        100,
        200,
        100,
    );
    img
}
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
    for i in 1..trail.len() {
        let (x1, y1) = trail[i - 1];
        let (x2, y2) = trail[i];
        let t = i as f32 / trail.len() as f32;
        let r = (100.0 + t * 155.0) as u8;
        let g = (200.0 - t * 100.0) as u8;
        let b = 120u8;
        img.draw_line(x1 as i32, y1 as i32, x2 as i32, y2 as i32, r, g, b, 200);
    }
    for (i, &(tx, ty)) in targets.iter().enumerate() {
        let hue = (i as f32 / targets.len().max(1) as f32 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb_viz(hue, 0.9, 1.0);
        img.draw_circle(tx as i32, ty as i32, 6, r, g, b, 255);
    }
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
    let (mx, my) = moved_pos;
    img.draw_circle(mx as i32, my as i32, 4, 80, 255, 80, 255);
    img.draw_label("MOVED BY", (mx as i32) + 10, (my as i32) + 10, 80, 255, 80);
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
pub fn draw_camera_to_image(cam: &Camera2D, width: u32, height: u32) -> ImageData {
    draw_camera_debug_to_image(cam, width as f32, height as f32, width, height)
}
