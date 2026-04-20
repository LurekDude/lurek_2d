//! Noise and terrain visualization helpers.
//!
//! Converts noise functions and heightmap buffers into CPU-side [`ImageData`]
//! renderings: grayscale, terrain-colored, and side-by-side comparisons.

use crate::image::ImageData;

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
            img.set_pixel(x, y, r, g, b, 255);
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
