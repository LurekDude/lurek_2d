//! Province map loader: parses colour-coded PNG images into [`ProvinceMap`].
//!
//! Converts each pixel's RGB colour to a province ID via [`color_to_id`], then
//! accumulates area, centroid, and bounding-box statistics in a single pass.

use std::collections::HashMap;
use std::path::Path;

use crate::math::{Rect, Vec2};

use super::core::{Province, ProvinceError, ProvinceMap};

/// Convert an RGB colour triple to a province ID.
///
/// The encoding is `(r << 16) | (g << 8) | b`, giving up to ~16 M unique IDs.
pub fn color_to_id(r: u8, g: u8, b: u8) -> u32 {
    (u32::from(r) << 16) | (u32::from(g) << 8) | u32::from(b)
}

/// Per-province accumulator used during the loading scan.
struct ProvinceAccum {
    color: [u8; 3],
    area: u32,
    sum_x: u64,
    sum_y: u64,
    min_x: u32,
    min_y: u32,
    max_x: u32,
    max_y: u32,
}

impl ProvinceAccum {
    fn new(color: [u8; 3], x: u32, y: u32) -> Self {
        Self {
            color,
            area: 1,
            sum_x: u64::from(x),
            sum_y: u64::from(y),
            min_x: x,
            min_y: y,
            max_x: x,
            max_y: y,
        }
    }

    fn add(&mut self, x: u32, y: u32) {
        self.area += 1;
        self.sum_x += u64::from(x);
        self.sum_y += u64::from(y);
        self.min_x = self.min_x.min(x);
        self.min_y = self.min_y.min(y);
        self.max_x = self.max_x.max(x);
        self.max_y = self.max_y.max(y);
    }
}

impl ProvinceMap {
    /// Load a province map from a colour-coded PNG file.
    ///
    /// Each unique RGB colour in the image becomes a province. Province ID `0`
    /// (black, `#000000`) is reserved for empty/background pixels and is skipped.
    pub fn from_file(path: &str) -> Result<ProvinceMap, ProvinceError> {
        let img = image::open(Path::new(path))
            .map_err(|e| ProvinceError::LoadError(format!("{path}: {e}")))?
            .into_rgba8();

        let width = img.width();
        let height = img.height();
        let pixels = img.into_raw();

        Self::from_image_data(width, height, &pixels)
    }

    /// Build a province map from raw RGBA pixel data.
    ///
    /// `pixels` must contain exactly `width * height * 4` bytes in row-major
    /// RGBA order. Province ID `0` (black) is treated as empty and skipped.
    pub fn from_image_data(
        width: u32,
        height: u32,
        pixels: &[u8],
    ) -> Result<ProvinceMap, ProvinceError> {
        let expected_len = (width as usize) * (height as usize) * 4;
        if pixels.len() != expected_len {
            return Err(ProvinceError::InvalidData(format!(
                "Expected {} bytes for {}×{} RGBA image, got {}",
                expected_len,
                width,
                height,
                pixels.len()
            )));
        }

        let mut map = ProvinceMap::new(width, height);
        let mut accums: HashMap<u32, ProvinceAccum> = HashMap::new();

        for y in 0..height {
            for x in 0..width {
                let base = ((y as usize) * (width as usize) + (x as usize)) * 4;
                let r = pixels[base];
                let g = pixels[base + 1];
                let b = pixels[base + 2];

                let id = color_to_id(r, g, b);

                map.set_pixel(x, y, id);

                // Skip empty/black pixels
                if id == 0 {
                    continue;
                }

                accums
                    .entry(id)
                    .and_modify(|acc| acc.add(x, y))
                    .or_insert_with(|| ProvinceAccum::new([r, g, b], x, y));
            }
        }

        for (id, acc) in &accums {
            let cx = acc.sum_x as f32 / acc.area as f32;
            let cy = acc.sum_y as f32 / acc.area as f32;
            let centroid = Vec2::new(cx, cy);

            let mut province = Province::new(*id, acc.color);
            province.area = acc.area;
            province.centroid = centroid;
            province.center = centroid;
            province.bounding_box = Rect::new(
                acc.min_x as f32,
                acc.min_y as f32,
                (acc.max_x - acc.min_x + 1) as f32,
                (acc.max_y - acc.min_y + 1) as f32,
            );

            map.insert_province(province);
        }

        log::info!(
            "Loaded province map: {} provinces from {}×{} image",
            map.province_count(),
            width,
            height
        );

        Ok(map)
    }
}
