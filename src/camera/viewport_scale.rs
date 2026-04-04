//! Virtual resolution viewport with automatic scaling and transform stack integration.
//!
//! Like `Viewport`, but also tracks the scaled content dimensions for
//! use with an automatic graphics transform stack.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for viewport scale-related operations and data management.
//! Key types exported from this module: `ViewportScale`.
//! Primary functions: `new()`, `resize()`, `get_game_dimensions()`, `get_scaled_dimensions()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::camera::viewport::ScaleMode;

/// Virtual resolution with automatic graphics stack management.
///
/// # Fields
/// - `game_width` — `f32`.
/// - `game_height` — `f32`.
/// - `mode` — `ScaleMode`.
/// - `scale_x` — `f32`.
/// - `scale_y` — `f32`.
/// - `offset_x` — `f32`.
/// - `offset_y` — `f32`.
/// - `scaled_width` — `f32`.
/// - `scaled_height` — `f32`.
///
/// Extends the basic viewport concept by also computing `scaled_width`
/// and `scaled_height`, which represent the game area in window pixels
/// after scaling.
pub struct ViewportScale {
    /// Game-space width in virtual pixels.
    pub game_width: f32,
    /// Game-space height in virtual pixels.
    pub game_height: f32,
    /// Active scale mode.
    pub mode: ScaleMode,
    /// Horizontal scale factor.
    pub scale_x: f32,
    /// Vertical scale factor.
    pub scale_y: f32,
    /// Horizontal offset in window pixels (for centering).
    pub offset_x: f32,
    /// Vertical offset in window pixels (for centering).
    pub offset_y: f32,
    /// Game width multiplied by scale_x.
    pub scaled_width: f32,
    /// Game height multiplied by scale_y.
    pub scaled_height: f32,
}

impl ViewportScale {
    /// Create a viewport scale with the given game dimensions and mode.
    ///
    /// # Parameters
    /// - `game_width` — `f32`.
    /// - `game_height` — `f32`.
    /// - `mode` — `ScaleMode`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Initially assumes the window equals the game size (scale 1:1).
    pub fn new(game_width: f32, game_height: f32, mode: ScaleMode) -> Self {
        Self {
            game_width,
            game_height,
            mode,
            scale_x: 1.0,
            scale_y: 1.0,
            offset_x: 0.0,
            offset_y: 0.0,
            scaled_width: game_width,
            scaled_height: game_height,
        }
    }

    /// Recompute all derived values from the current window size.
    ///
    /// # Parameters
    /// - `window_width` — `f32`.
    /// - `window_height` — `f32`.
    pub fn resize(&mut self, window_width: f32, window_height: f32) {
        match self.mode {
            ScaleMode::Letterbox => {
                let scale = (window_width / self.game_width).min(window_height / self.game_height);
                self.scale_x = scale;
                self.scale_y = scale;
                self.offset_x = (window_width - self.game_width * scale) / 2.0;
                self.offset_y = (window_height - self.game_height * scale) / 2.0;
            }
            ScaleMode::Stretch => {
                self.scale_x = window_width / self.game_width;
                self.scale_y = window_height / self.game_height;
                self.offset_x = 0.0;
                self.offset_y = 0.0;
            }
            ScaleMode::PixelPerfect => {
                let scale = (window_width / self.game_width)
                    .min(window_height / self.game_height)
                    .floor()
                    .max(1.0);
                self.scale_x = scale;
                self.scale_y = scale;
                self.offset_x = (window_width - self.game_width * scale) / 2.0;
                self.offset_y = (window_height - self.game_height * scale) / 2.0;
            }
        }
        self.scaled_width = self.game_width * self.scale_x;
        self.scaled_height = self.game_height * self.scale_y;
    }

    /// Game dimensions `(game_width, game_height)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }

    /// Scaled content dimensions `(scaled_width, scaled_height)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_scaled_dimensions(&self) -> (f32, f32) {
        (self.scaled_width, self.scaled_height)
    }

    /// Current offset `(offset_x, offset_y)`. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }

    /// Current scale factors `(scale_x, scale_y)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }

    /// Reference to the active scale mode. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&ScaleMode`.
    pub fn get_mode(&self) -> &ScaleMode {
        &self.mode
    }

    /// Convert screen coordinates to game coordinates.
    ///
    /// # Parameters
    /// - `screen_x` — `f32`.
    /// - `screen_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn to_game_coords(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }

    /// Convert game coordinates to screen coordinates.
    ///
    /// # Parameters
    /// - `game_x` — `f32`.
    /// - `game_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn to_screen_coords(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}
