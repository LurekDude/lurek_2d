use super::emitter::ParticleSystem;
use super::math::{interpolate_alphas, interpolate_colors, interpolate_sizes};
use crate::image::ImageData;
pub fn draw_to_image(ps: &ParticleSystem, width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    let w = width as i32;
    let h = height as i32;
    for p in &ps.particles {
        if p.life > 0.0 {
            let px = (p.x + ps.emitter_x) as i32;
            let py = (p.y + ps.emitter_y) as i32;
            if px < -10 || px > w + 10 || py < -10 || py > h + 10 {
                continue;
            }
            let t = 1.0 - (p.life / p.max_life);
            let [cr, cg, cb, ca] = interpolate_colors(&ps.config.colors, t);
            let alpha = if !ps.config.alpha_keyframes.is_empty() {
                interpolate_alphas(&ps.config.alpha_keyframes, t)
            } else {
                ca
            };
            let size = interpolate_sizes(&ps.config.sizes, t, p.size_variation).max(1.0) as i32;
            let ri = (cr * 255.0) as u8;
            let gi = (cg * 255.0) as u8;
            let bi = (cb * 255.0) as u8;
            let ai = (alpha * 255.0) as u8;
            let y0 = (py - size).max(0);
            let y1 = (py + size + 1).min(h);
            let x0 = (px - size).max(0);
            let x1 = (px + size + 1).min(w);
            let r2 = (size * size) as i64;
            for sy in y0..y1 {
                let dy = (sy - py) as i64;
                for sx in x0..x1 {
                    let dx = (sx - px) as i64;
                    if dx * dx + dy * dy <= r2 {
                        img.set_pixel(sx as u32, sy as u32, ri, gi, bi, ai);
                    }
                }
            }
        }
    }
    img.draw_circle(
        ps.emitter_x as i32,
        ps.emitter_y as i32,
        3,
        255,
        255,
        255,
        255,
    );
    img
}
pub fn draw_explosion_to_image(ps: &ParticleSystem, width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(10, 8, 15, 255);
    for p in &ps.particles {
        let t = p.life / p.max_life;
        let r = 255u8;
        let g = (t * 200.0) as u8;
        let b = (t * 60.0) as u8;
        let size = (3.0 + t * 4.0) as u32;
        img.draw_circle(p.x as i32, p.y as i32, size, r, g, b, (t * 255.0) as u8);
    }
    img.draw_label("EXPLOSION", 4, 4, 255, 160, 60);
    img
}
pub fn draw_rain_to_image(ps: &ParticleSystem, width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(30, 35, 50, 255);
    for p in &ps.particles {
        let t = p.life / p.max_life;
        let alpha = (t * 200.0) as u8 + 30;
        img.draw_line(
            p.x as i32,
            p.y as i32,
            p.x as i32,
            p.y as i32 + 6,
            140,
            160,
            220,
            alpha,
        );
    }
    img.draw_label("RAIN", 4, 4, 140, 180, 255);
    img
}
pub fn draw_spark_trail_to_image(ps: &ParticleSystem, width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(10, 8, 12, 255);
    for p in &ps.particles {
        let t = p.life / p.max_life;
        let r = 255u8;
        let g = (80.0 + t * 150.0) as u8;
        let b = (t * 50.0) as u8;
        img.draw_circle(p.x as i32, p.y as i32, 2, r, g, b, (t * 255.0) as u8);
        img.draw_line(
            p.x as i32,
            p.y as i32,
            p.x as i32 - 3,
            p.y as i32 + 3,
            r / 2,
            g / 2,
            b / 2,
            (t * 128.0) as u8,
        );
    }
    img.draw_label("SPARKS", 4, 4, 255, 200, 80);
    img
}
pub fn draw_over_image(ps: &ParticleSystem, mut bg: ImageData) -> ImageData {
    let w = bg.width() as i32;
    let h = bg.height() as i32;
    for p in &ps.particles {
        if p.life <= 0.0 {
            continue;
        }
        let px = (p.x + ps.emitter_x) as i32;
        let py = (p.y + ps.emitter_y) as i32;
        if px < -10 || px > w + 10 || py < -10 || py > h + 10 {
            continue;
        }
        let t = 1.0 - (p.life / p.max_life);
        let r = (255.0 * (1.0 - t * 0.5)) as u8;
        let g = (128.0 * (1.0 - t)) as u8;
        let b = 0u8;
        let size = (4.0f32 * (1.0 - t)).max(1.0) as i32;
        let y0 = (py - size).max(0);
        let y1 = (py + size + 1).min(h);
        let x0 = (px - size).max(0);
        let x1 = (px + size + 1).min(w);
        let r2 = (size * size) as i64;
        for sy in y0..y1 {
            let dy = (sy - py) as i64;
            for sx in x0..x1 {
                let dx = (sx - px) as i64;
                if dx * dx + dy * dy <= r2 {
                    bg.set_pixel(sx as u32, sy as u32, r, g, b, 200);
                }
            }
        }
    }
    bg.draw_circle(
        ps.emitter_x as i32,
        ps.emitter_y as i32,
        3,
        255,
        255,
        255,
        255,
    );
    bg
}
pub fn paint_onto(ps: &ParticleSystem, img: &mut ImageData) {
    let w = img.width() as i32;
    let h = img.height() as i32;
    for p in &ps.particles {
        if p.life <= 0.0 {
            continue;
        }
        let px = p.x as i32;
        let py = p.y as i32;
        if px < 0 || px >= w || py < 0 || py >= h {
            continue;
        }
        let age_frac = 1.0 - p.life / p.max_life;
        let r = 255u8;
        let g = (220.0 * (1.0 - age_frac)) as u8;
        let b = (80.0 * (1.0 - age_frac * 0.8)) as u8;
        img.set_pixel(px as u32, py as u32, r, g, b, 255);
    }
}
pub fn draw_lifecycle_to_image(
    snapshots: &[(u32, usize)],
    max_particles: usize,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    img.draw_label("LIFECYCLE", 4, 4, 180, 220, 255);
    if snapshots.is_empty() || max_particles == 0 {
        return img;
    }
    let bar_w = (width as f32 / snapshots.len().max(1) as f32) as u32;
    let plot_h = height - 24;
    for (i, &(_step, count)) in snapshots.iter().enumerate() {
        let t = count as f32 / max_particles as f32;
        let bar_h = (t * plot_h as f32) as u32;
        let x = i as u32 * bar_w;
        let y = height - bar_h;
        let r = (t * 200.0) as u8 + 40;
        let g = ((1.0 - t) * 200.0) as u8 + 40;
        for bx in 0..bar_w.saturating_sub(1) {
            for by in 0..bar_h {
                if (x + bx) < width && (y + by) < height {
                    img.set_pixel(x + bx, y + by, r, g, 80, 200);
                }
            }
        }
    }
    img
}
