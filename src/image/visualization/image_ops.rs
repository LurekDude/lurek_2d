use super::hsv_to_rgb_viz;
use crate::image::ImageData;
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
    let max_h = height.saturating_sub(30);
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
pub fn draw_pixel_transform_grid_to_image(col_w: u32, col_h: u32) -> ImageData {
    let width = col_w * 4;
    let height = col_h;
    let mut img = ImageData::new(width, height);
    for y in 0..col_h {
        for x in 0..col_w {
            let r = (x * 255 / col_w) as u8;
            let g = (y * 255 / col_h) as u8;
            let b = 128u8;
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    for y in 0..col_h {
        for x in 0..col_w {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                img.set_pixel(col_w + x, y, 255 - r, 255 - g, 255 - b, 255);
            }
        }
    }
    for y in 0..col_h {
        for x in 0..col_w {
            if let Some((r, g, b, _a)) = img.get_pixel(x, y) {
                let gray = ((r as u16 + g as u16 + b as u16) / 3) as u8;
                img.set_pixel(col_w * 2 + x, y, gray, gray, gray, 255);
            }
        }
    }
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
