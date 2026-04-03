//! Color palette lookup table for shader-based palette swapping.
//!
//! Maps source colors to target colors, allowing sprites to be
//! re-colored at render time without modifying the original texture.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for palette lut-related operations and data management.
//! Key types exported from this module: `PaletteLUT`.
//! Primary functions: `new()`, `get_color_count()`, `set_color()`, `get_from_color()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::graphics::Color;

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
}

impl Default for PaletteLUT {
    fn default() -> Self {
        Self::new()
    }
}
