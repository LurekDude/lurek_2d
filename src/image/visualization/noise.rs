//! - Noise function rendering as scaled grayscale.
//! - Raw noise mapping without range normalization.
//! - Terrain biome coloring from noise elevation bands.
//! - Heightmap slice visualization with elevation gradient.
//! - Noise comparison strip with multiple tiles side by side.

use crate::image::ImageData;
/// Render a noise function as a grayscale image, scaling range to full byte range.
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
/// Render a noise function as a raw unscaled grayscale image.
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
/// Render a noise function as a terrain color image with water, land, and mountain bands.
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
/// Render a pre-computed heightmap slice as a grayscale image.
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
/// Render terrain elevation data as a biome-colored image.
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
            img.set_pixel(x, y, r, g, b, 255);
        }
    }
    img
}
/// Render a noise map as a continuous-hue image.
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
/// Render multiple noise map tiles in a row for comparison into an image.
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
