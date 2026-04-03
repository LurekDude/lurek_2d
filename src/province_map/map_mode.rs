//! Map mode colour resolution for province map rendering.
//!
//! Map modes assign colours to provinces for different visualisations —
//! political ownership, terrain type, economic value, etc. Colour data
//! is passed in directly (no dependency on an external property system).

use std::collections::HashMap;

use super::core::{ProvinceMap, Province};

/// A named map mode with its colour assignment function.
///
/// # Fields
/// - `name` — `String`.
/// - `color_fn` — `MapModeColorFn`.
#[derive(Debug, Clone)]
pub struct MapMode {
    /// Display name of this map mode (e.g. "Political", "Terrain").
    pub name: String,
    /// The colour assignment rule.
    pub color_fn: MapModeColorFn,
}

/// How colours are assigned to provinces. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Each` — Each variant.
/// - `Fixed` — Fixed variant.
/// - `SourceColor` — SourceColor variant.
/// - `Gradient` — Gradient variant.
/// - `The` — The variant.
/// - `Per` — Per variant.
/// - `Colour` — Colour variant.
/// - `Lower` — Lower variant.
/// - `Upper` — Upper variant.
/// - `Category` — Category variant.
/// - `Fallback` — Fallback variant.
#[derive(Debug, Clone)]
pub enum MapModeColorFn {
    /// Each province gets a specific fixed colour from the map.
    Fixed(HashMap<u32, [f32; 4]>),

    /// Each province uses its own source colour from the image data.
    SourceColor,

    /// Gradient colour between `min_color` and `max_color` based on a numeric
    /// value per province. The value is looked up in `values` and linearly
    /// interpolated in the `[min_val, max_val]` range.
    Gradient {
        /// Per-province numeric values to map into the gradient.
        values: HashMap<u32, f64>,
        /// Colour for the minimum value.
        min_color: [f32; 4],
        /// Colour for the maximum value.
        max_color: [f32; 4],
        /// Lower bound of the value range.
        min_val: f64,
        /// Upper bound of the value range.
        max_val: f64,
    },

    /// Category-based colouring: each province gets a category string, and
    /// each category maps to a specific colour.
    Category {
        /// Per-province category assignment.
        categories: HashMap<u32, String>,
        /// Colour for each category name.
        colors: HashMap<String, [f32; 4]>,
        /// Fallback colour for provinces with unknown or missing categories.
        default_color: [f32; 4],
    },
}

impl MapModeColorFn {
    /// Resolve the colour for a single province.
    ///
    /// # Parameters
    /// - `province` — `&Province`.
    ///
    /// # Returns
    /// `[f32`.
    pub fn resolve_color(&self, province: &Province) -> [f32; 4] {
        match self {
            Self::Fixed(map) => map
                .get(&province.id)
                .copied()
                .unwrap_or([0.5, 0.5, 0.5, 1.0]),

            Self::SourceColor => {
                let [r, g, b] = province.color;
                [r as f32 / 255.0, g as f32 / 255.0, b as f32 / 255.0, 1.0]
            }

            Self::Gradient {
                values,
                min_color,
                max_color,
                min_val,
                max_val,
            } => {
                let val = values
                    .get(&province.id)
                    .copied()
                    .unwrap_or(*min_val);
                let range = max_val - min_val;
                let t = if range.abs() < f64::EPSILON {
                    0.0
                } else {
                    ((val - min_val) / range).clamp(0.0, 1.0) as f32
                };
                [
                    min_color[0] + (max_color[0] - min_color[0]) * t,
                    min_color[1] + (max_color[1] - min_color[1]) * t,
                    min_color[2] + (max_color[2] - min_color[2]) * t,
                    min_color[3] + (max_color[3] - min_color[3]) * t,
                ]
            }

            Self::Category {
                categories,
                colors,
                default_color,
            } => {
                if let Some(cat) = categories.get(&province.id) {
                    colors.get(cat).copied().unwrap_or(*default_color)
                } else {
                    *default_color
                }
            }
        }
    }
}

/// Resolve colours for every pixel in the map, producing an RGBA pixel buffer.
///
/// Pixels that belong to province ID 0 (empty) are set to transparent black.
/// The returned buffer has length `width * height * 4`.
///
/// # Parameters
/// - `ap` — `&ProvinceMap`.
/// - `ode` — `&MapMode`.
///
/// # Returns
/// `Vec<u8>`.
pub fn resolve_colors(map: &ProvinceMap, mode: &MapMode) -> Vec<u8> {
    let w = map.width() as usize;
    let h = map.height() as usize;
    let mut buf = vec![0u8; w * h * 4];

    // Pre-resolve colours per province ID for fast lookup.
    let mut color_cache: HashMap<u32, [u8; 4]> = HashMap::new();
    for &id in &map.province_ids() {
        if let Some(province) = map.get_province(id) {
            let c = mode.color_fn.resolve_color(province);
            color_cache.insert(
                id,
                [
                    (c[0] * 255.0).clamp(0.0, 255.0) as u8,
                    (c[1] * 255.0).clamp(0.0, 255.0) as u8,
                    (c[2] * 255.0).clamp(0.0, 255.0) as u8,
                    (c[3] * 255.0).clamp(0.0, 255.0) as u8,
                ],
            );
        }
    }

    let pixel_lookup = map.pixel_lookup();
    for (i, &province_id) in pixel_lookup.iter().enumerate() {
        if province_id == 0 {
            continue; // transparent black
        }
        if let Some(rgba) = color_cache.get(&province_id) {
            let base = i * 4;
            buf[base] = rgba[0];
            buf[base + 1] = rgba[1];
            buf[base + 2] = rgba[2];
            buf[base + 3] = rgba[3];
        }
    }

    buf
}
