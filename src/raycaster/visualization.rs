//! Debug visualization helpers for `Raycaster2D`: top-down map, software first-person
//! view, and depth-map image rendering. All three methods write into `ImageData`
//! pixel buffers and are intended for development, not production rendering.

use super::dda::Raycaster2D;
impl Raycaster2D {
    /// Render a top-down grid map with player dot and radial ray lines into an `ImageData`.
    pub fn draw_top_down_to_image(
        &self,
        player_x: f32,
        player_y: f32,
        player_angle: f32,
        scale: u32,
    ) -> crate::image::ImageData {
        let _ = player_angle;
        let w = self.width();
        let h = self.height();
        let mut img = crate::image::ImageData::new(w * scale, h * scale);
        img.fill(40, 40, 50, 255);
        for y in 0..h {
            for x in 0..w {
                let cell = self.get_cell(x, y);
                if cell > 0 {
                    let (r, g, b) = match cell {
                        1 => (120u8, 120u8, 130u8),
                        2 => (180, 80, 80),
                        3 => (80, 80, 180),
                        _ => (200, 200, 200),
                    };
                    for py in 0..scale {
                        for px in 0..scale {
                            img.set_pixel(x * scale + px, y * scale + py, r, g, b, 255);
                        }
                    }
                }
            }
        }
        img.draw_circle(
            (player_x * scale as f32) as i32,
            (player_y * scale as f32) as i32,
            4,
            255,
            255,
            0,
            255,
        );
        for angle_deg in (0..360).step_by(15) {
            let angle = (angle_deg as f32).to_radians();
            if let Some(hit) = self.cast_ray(player_x, player_y, angle, 20.0) {
                let ex = (hit.hit_x * scale as f32) as i32;
                let ey = (hit.hit_y * scale as f32) as i32;
                img.draw_line(
                    (player_x * scale as f32) as i32,
                    (player_y * scale as f32) as i32,
                    ex,
                    ey,
                    255,
                    200,
                    0,
                    180,
                );
            }
        }
        img
    }
    /// Render a software first-person view with cell-colour shading into an `ImageData`.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_view_to_image(
        &self,
        player_x: f32,
        player_y: f32,
        angle: f32,
        fov: f32,
        width: u32,
        height: u32,
        max_dist: f32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        let half_h = height / 2;
        for y in 0..half_h {
            let t = y as f32 / half_h as f32;
            let r = (20.0 + t * 30.0) as u8;
            let g = (30.0 + t * 40.0) as u8;
            let b = (80.0 + t * 100.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
        for y in half_h..height {
            let t = (y - half_h) as f32 / half_h as f32;
            let g = (80.0 - t * 40.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, g + 30, g + 10, g / 2 + 10, 255);
            }
        }
        let rays = self.cast_rays(player_x, player_y, angle, fov, width, max_dist);
        for (x, hit) in rays.iter().enumerate() {
            if hit.hit {
                let wall_h = (height as f32 / hit.distance.max(0.1)) as i32;
                let top = half_h as i32 - wall_h / 2;
                let bot = half_h as i32 + wall_h / 2;
                let shade = (1.0f32 - hit.distance / max_dist).max(0.15);
                let (cr, cg, cb) = match hit.cell_value {
                    1 => (200u8, 80, 80),
                    2 => (80, 180, 80),
                    3 => (80, 100, 200),
                    4 => (200, 180, 60),
                    5 => (180, 80, 200),
                    _ => (150, 150, 150),
                };
                let r = (cr as f32 * shade) as u8;
                let g = (cg as f32 * shade) as u8;
                let b = (cb as f32 * shade) as u8;
                img.draw_line(
                    x as i32,
                    top.max(0),
                    x as i32,
                    bot.min(height as i32 - 1),
                    r,
                    g,
                    b,
                    255,
                );
            }
        }
        img
    }
    /// Render a depth-map greyscale view where brighter = closer, into an `ImageData`.
    #[allow(clippy::too_many_arguments)]
    pub fn draw_depth_map_to_image(
        &self,
        player_x: f32,
        player_y: f32,
        player_angle: f32,
        fov: f32,
        num_rays: u32,
        width: u32,
        height: u32,
        max_dist: f32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);
        let half = height / 2;
        for y in 0..half {
            let t = y as f32 / half as f32;
            let r = (30.0 + t * 50.0) as u8;
            let g = (50.0 + t * 80.0) as u8;
            let b = (120.0 + t * 80.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
        for i in 0..num_rays {
            let ray_angle = player_angle - fov / 2.0 + (i as f32 / num_rays as f32) * fov;
            if let Some(hit) = self.cast_ray(player_x, player_y, ray_angle, max_dist) {
                let dist = hit.distance.max(0.1);
                let wall_h = ((height as f32 / dist) * 2.0).min(height as f32) as u32;
                let top = half.saturating_sub(wall_h / 2);
                let shade = ((1.0 - dist / max_dist).max(0.0) * 255.0) as u8;
                let (r, g, b) = match hit.cell_value {
                    1 => (shade, shade, shade),
                    2 => (shade, shade / 2, shade / 3),
                    3 => (shade / 3, shade / 2, shade),
                    _ => (shade, shade, shade),
                };
                for y in top..(top + wall_h).min(height) {
                    img.set_pixel(i.min(width - 1), y, r, g, b, 255);
                }
            }
        }
        img
    }
    #[allow(clippy::too_many_arguments)]
    pub fn draw_line_of_sight_to_image(
        &self,
        ax: f32,
        ay: f32,
        bx: f32,
        by: f32,
        scale: u32,
    ) -> crate::image::ImageData {
        let w = self.width();
        let h = self.height();
        let mut img = crate::image::ImageData::new(w * scale, h * scale);
        img.fill(40, 40, 50, 255);
        for y in 0..h {
            for x in 0..w {
                if self.get_cell(x, y) > 0 {
                    for py in 0..scale {
                        for px in 0..scale {
                            img.set_pixel(x * scale + px, y * scale + py, 120, 120, 130, 255);
                        }
                    }
                }
            }
        }
        let can_see = self.line_of_sight(ax, ay, bx, by);
        let color = if can_see {
            (0u8, 255u8, 0u8)
        } else {
            (255u8, 0u8, 0u8)
        };
        img.draw_line(
            (ax * scale as f32) as i32,
            (ay * scale as f32) as i32,
            (bx * scale as f32) as i32,
            (by * scale as f32) as i32,
            color.0,
            color.1,
            color.2,
            200,
        );
        img.draw_circle(
            (ax * scale as f32) as i32,
            (ay * scale as f32) as i32,
            4,
            0,
            255,
            255,
            255,
        );
        img.draw_circle(
            (bx * scale as f32) as i32,
            (by * scale as f32) as i32,
            4,
            255,
            255,
            0,
            255,
        );
        img
    }
    #[allow(clippy::too_many_arguments)]
    pub fn draw_camera_sweep_to_image(
        &self,
        x: f32,
        y: f32,
        fov: f32,
        max_dist: f32,
        num_frames: u32,
        frame_w: u32,
        frame_h: u32,
    ) -> crate::image::ImageData {
        let cols = 4u32;
        let rows = num_frames.div_ceil(cols);
        let mut img = crate::image::ImageData::new(cols * frame_w, rows * frame_h);
        img.fill(15, 15, 25, 255);
        for frame in 0..num_frames {
            let angle = frame as f32 * std::f32::consts::TAU / num_frames as f32;
            let col = frame % cols;
            let row = frame / cols;
            let ox = col * frame_w;
            let oy = row * frame_h;
            let rays = self.cast_rays(x, y, angle, fov, frame_w, max_dist);
            for (rx, hit) in rays.iter().enumerate() {
                if hit.hit {
                    let wall_h = (frame_h as f32 / hit.distance.max(0.1)) as i32;
                    let mid = frame_h as i32 / 2;
                    let top = mid - wall_h / 2;
                    let bot = mid + wall_h / 2;
                    let shade = (1.0 - hit.distance / max_dist).max(0.1);
                    let r = (180.0 * shade) as u8;
                    let g = (120.0 * shade) as u8;
                    let b = (255.0 * shade) as u8;
                    let px = (ox as i32 + rx as i32).min((ox + frame_w) as i32 - 1);
                    let py_top = (oy as i32 + top).max(oy as i32);
                    let py_bot = (oy as i32 + bot).min((oy + frame_h) as i32 - 1);
                    if py_top < py_bot {
                        img.draw_line(px, py_top, px, py_bot, r, g, b, 255);
                    }
                }
            }
        }
        img
    }
    #[allow(clippy::too_many_arguments)]
    pub fn draw_textured_view_to_image(
        &self,
        ox: f32,
        oy: f32,
        angle: f32,
        fov: f32,
        width: u32,
        height: u32,
        max_dist: f32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        let half_h = height / 2;
        for y in 0..half_h {
            let t = y as f32 / half_h as f32;
            let r = (10.0 + t * 20.0) as u8;
            let g = (15.0 + t * 30.0) as u8;
            let b = (40.0 + t * 80.0) as u8;
            for x in 0..width {
                img.set_pixel(x, y, r, g, b, 255);
            }
        }
        let star_positions: [(u32, u32); 10] = [
            (50, 20),
            (150, 40),
            (280, 15),
            (400, 35),
            (520, 25),
            (600, 45),
            (100, 60),
            (350, 55),
            (500, 70),
            (80, 90),
        ];
        for &(sx, sy) in &star_positions {
            if sx < width && sy < half_h {
                img.set_pixel(sx, sy, 255, 255, 240, 200);
            }
        }
        for y in half_h..height {
            let t = (y - half_h) as f32 / half_h as f32;
            let base_g = (60.0 - t * 30.0) as u8;
            for x in 0..width {
                let checker = (x / 40 + (y - half_h) / 20).is_multiple_of(2) as u8;
                let r = base_g + 15 + checker * 15;
                let g2 = base_g + 5 + checker * 10;
                let b = base_g / 2 + checker * 8;
                img.set_pixel(x, y, r, g2, b, 255);
            }
        }
        let rays = self.cast_rays(ox, oy, angle, fov, width, max_dist);
        for (x, hit) in rays.iter().enumerate() {
            if hit.hit {
                let wall_h = (300.0 / hit.distance.max(0.2)) as i32;
                let top = half_h as i32 - wall_h / 2;
                let bot = half_h as i32 + wall_h / 2;
                let shade = (1.0 - hit.distance / max_dist).max(0.2);
                for y in top.max(0)..bot.min(height as i32) {
                    let frac_y = (y - top) as f32 / (bot - top).max(1) as f32;
                    let frac_x = (hit.distance * 3.7) % 1.0;
                    let (tr, tg, tb) =
                        Self::procedural_texture_color(hit.cell_value, frac_y, frac_x);
                    let r = (tr as f32 * shade) as u8;
                    let g = (tg as f32 * shade) as u8;
                    let b = (tb as f32 * shade) as u8;
                    img.set_pixel(x as u32, y as u32, r, g, b, 255);
                }
            }
        }
        img.draw_label(
            "PROCEDURAL TEXTURED RAYCASTER",
            (width / 4) as i32,
            (height - 15) as i32,
            100,
            255,
            100,
        );
        img
    }
    fn procedural_texture_color(cell: u32, frac_y: f32, frac_x: f32) -> (u8, u8, u8) {
        match cell {
            1 => {
                let brick_y = (frac_y * 4.0) as u32;
                let offset = if brick_y.is_multiple_of(2) { 0 } else { 4 };
                let is_mortar =
                    frac_y * 4.0 % 1.0 < 0.1 || (frac_x * 8.0 + offset as f32) % 1.0 < 0.12;
                if is_mortar {
                    (120, 110, 100)
                } else {
                    (180, 60, 40)
                }
            }
            2 => {
                let block_x = (frac_x * 3.0) as u32;
                let block_y = (frac_y * 3.0) as u32;
                let noise = ((block_x * 37 + block_y * 59) % 30) as u8;
                (130 + noise, 130 + noise, 140 + noise)
            }
            3 => {
                let plank = (frac_x * 6.0) as u32;
                let grain = ((frac_y * 20.0).sin() * 15.0) as i32;
                let base = 100 + (plank * 12 % 40) as i32;
                let r = (base + grain).clamp(60, 200) as u8;
                let g = (base - 20 + grain).clamp(40, 150) as u8;
                let b = ((base - 50).max(20) as f32 * 0.5) as u8;
                (r, g, b)
            }
            4 => {
                let panel_y = (frac_y * 4.0) as u32;
                let is_seam = frac_y * 4.0 % 1.0 < 0.08;
                let rivet = frac_x > 0.45
                    && frac_x < 0.55
                    && frac_y * 4.0 % 1.0 > 0.4
                    && frac_y * 4.0 % 1.0 < 0.6;
                if rivet {
                    (200, 200, 210)
                } else if is_seam {
                    (60, 65, 75)
                } else {
                    let shade = 100 + (panel_y * 10 % 30) as u8;
                    (
                        shade,
                        (shade as u16 + 10).min(255) as u8,
                        (shade as u16 + 25).min(255) as u8,
                    )
                }
            }
            5 => {
                let vein = ((frac_y * 10.0 + frac_x * 5.0).sin() * 20.0) as i32;
                let base = 200 + vein;
                let r = base.clamp(160, 240) as u8;
                let g = (base - 10).clamp(150, 235) as u8;
                let b = (base - 5).clamp(155, 238) as u8;
                (r, g, b)
            }
            6 => {
                let tx = (frac_x * 5.0) as u32;
                let ty = (frac_y * 5.0) as u32;
                let tile_hue = ((tx * 73 + ty * 41) % 6) as f32 * 60.0;
                let h = tile_hue % 360.0;
                let s = 0.6f32;
                let v = 0.8f32;
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
            _ => (150, 150, 150),
        }
    }
}
