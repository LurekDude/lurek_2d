//! Color palette lookup table for shader-based palette swapping.
//!
//! [`PaletteLUT`] maps source colours to target colours, allowing sprites to be
//! re-coloured at render time without modifying the original texture.  Each entry
//! pairs a "from" [`Color`] with a "to" [`Color`]; a shader (or the CPU
//! [`PaletteLUT::apply`] path) replaces matching pixels in a single pass.
//!
//! This module is part of Lurek2D's `image` subsystem (Platform Services tier).
//!
//! All public items are documented.  See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::math::Color;
use std::collections::HashMap;

/// Color palette lookup table mapping source colors to target colors.
///
/// # Fields
/// - `from_colors` — `Vec<Color>`.
/// - `to_colors` — `Vec<Color>`.
///
/// Each entry pairs a "from" color with a "to" color. At render time a
/// shader can replace pixels matching a source color with the
/// corresponding target color.
pub struct PaletteLUT {
    /// Source colors to match against.
    pub from_colors: Vec<Color>,
    /// Replacement colors in the same order as `from_colors`.
    pub to_colors: Vec<Color>,
}

impl PaletteLUT {
    /// Creates an empty palette lookup table. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            from_colors: Vec::new(),
            to_colors: Vec::new(),
        }
    }

    /// Returns the number of color mappings. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_color_count(&self) -> usize {
        self.from_colors.len()
    }

    /// Sets the color mapping at the given 0-based index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    /// - `from` — `Color`.
    /// - `to` — `Color`.
    ///
    /// If `index` is beyond the current length, both vectors are extended
    /// with `Color::WHITE` entries to fill the gap.
    pub fn set_color(&mut self, index: usize, from: Color, to: Color) {
        while self.from_colors.len() <= index {
            self.from_colors.push(Color::WHITE);
            self.to_colors.push(Color::WHITE);
        }
        self.from_colors[index] = from;
        self.to_colors[index] = to;
    }

    /// Returns the source color at the given 0-based index, if it exists.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<Color>`.
    pub fn get_from_color(&self, index: usize) -> Option<Color> {
        self.from_colors.get(index).copied()
    }

    /// Returns the target color at the given 0-based index, if it exists.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<Color>`.
    pub fn get_to_color(&self, index: usize) -> Option<Color> {
        self.to_colors.get(index).copied()
    }

    /// Removes all color mappings. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.from_colors.clear();
        self.to_colors.clear();
    }

    /// Applies this palette lookup table to an image in place.
    ///
    /// For every pixel in `img` whose RGBA byte values (0–255) match a `from_colors[i]`
    /// entry (exact comparison after converting from `f32 * 255.0`), the pixel is
    /// replaced with the corresponding `to_colors[i]` value.
    ///
    /// The first matching mapping is applied and the rest are skipped for that pixel.
    ///
    /// # Parameters
    /// - `img` — `&mut ImageData` — image modified in place.
    pub fn apply(&self, img: &mut crate::image::image_data::ImageData) {
        if self.from_colors.is_empty() {
            return;
        }

        let to_rgba_key = |c: &Color| -> u32 {
            let r = (c.r * 255.0).round() as u8;
            let g = (c.g * 255.0).round() as u8;
            let b = (c.b * 255.0).round() as u8;
            let a = (c.a * 255.0).round() as u8;
            (u32::from(r) << 24) | (u32::from(g) << 16) | (u32::from(b) << 8) | u32::from(a)
        };

        let to_rgba = |c: &Color| -> [u8; 4] {
            [
                (c.r * 255.0).round() as u8,
                (c.g * 255.0).round() as u8,
                (c.b * 255.0).round() as u8,
                (c.a * 255.0).round() as u8,
            ]
        };

        let use_hash = self.from_colors.len() > 16;
        let map = if use_hash {
            let mut m = HashMap::with_capacity(self.from_colors.len());
            for (i, from) in self.from_colors.iter().enumerate() {
                m.entry(to_rgba_key(from)).or_insert(i);
            }
            Some(m)
        } else {
            None
        };

        let w = img.width();
        let h = img.height();
        for y in 0..h {
            for x in 0..w {
                if let Some((r, g, b, a)) = img.get_pixel(x, y) {
                    let index = if let Some(m) = &map {
                        let key =
                            (u32::from(r) << 24) | (u32::from(g) << 16) | (u32::from(b) << 8) | u32::from(a);
                        m.get(&key).copied()
                    } else {
                        let mut idx = None;
                        for (i, from) in self.from_colors.iter().enumerate() {
                            let [fr, fg, fb, fa] = to_rgba(from);
                            if r == fr && g == fg && b == fb && a == fa {
                                idx = Some(i);
                                break;
                            }
                        }
                        idx
                    };

                    if let Some(i) = index {
                        let to = &self.to_colors[i];
                        let [tr, tg, tb, ta] = to_rgba(to);
                        img.set_pixel(x, y, tr, tg, tb, ta);
                    }
                }
            }
        }
    }
}

impl Default for PaletteLUT {
    fn default() -> Self {
        Self::new()
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────
