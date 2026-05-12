//! Virtual resolution viewport with manual transform application.
//!
//! Maps a fixed game resolution onto an arbitrary window size using
//! letterboxing, stretching, or pixel-perfect scaling.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for viewport-related operations and data management.
//! Key types exported from this module: `ScaleMode`, `Viewport`.
//! Primary functions: `new()`, `resize()`, `get_scale()`, `get_offset()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Scale mode for virtual resolution mapping.
///
/// # Variants
/// - `Letterbox` — Letterbox variant.
/// - `Stretch` — Stretch variant.
/// - `PixelPerfect` — PixelPerfect variant.
#[derive(Debug, Clone, PartialEq)]
pub enum ScaleMode {
    /// Uniform scale with black bars to preserve aspect ratio.
    Letterbox,
    /// Non-uniform scale that fills the entire window.
    Stretch,
    /// Integer-only scale for crisp pixel art.
    PixelPerfect,
}

impl ScaleMode {
    /// Computes scale and offset for this scale mode given game and window dimensions.
    ///
    /// # Parameters
    /// - `game_width` — Game-space width.
    /// - `game_height` — Game-space height.
    /// - `window_width` — Physical window width.
    /// - `window_height` — Physical window height.
    ///
    /// # Returns
    /// `(scale_x, scale_y, offset_x, offset_y)` tuple.
    ///
    /// This is a shared utility function used by both `Viewport` and `ViewportScale`
    /// to reduce code duplication and ensure consistent behavior.
    pub fn compute_transforms(
        &self,
        game_width: f32,
        game_height: f32,
        window_width: f32,
        window_height: f32,
    ) -> (f32, f32, f32, f32) {
        match self {
            ScaleMode::Letterbox => {
                let scale = (window_width / game_width).min(window_height / game_height);
                let offset_x = (window_width - game_width * scale) / 2.0;
                let offset_y = (window_height - game_height * scale) / 2.0;
                (scale, scale, offset_x, offset_y)
            }
            ScaleMode::Stretch => {
                let scale_x = window_width / game_width;
                let scale_y = window_height / game_height;
                (scale_x, scale_y, 0.0, 0.0)
            }
            ScaleMode::PixelPerfect => {
                let scale = (window_width / game_width)
                    .min(window_height / game_height)
                    .floor()
                    .max(1.0);
                let offset_x = (window_width - game_width * scale) / 2.0;
                let offset_y = (window_height - game_height * scale) / 2.0;
                (scale, scale, offset_x, offset_y)
            }
        }
    }
}

/// Virtual resolution with manual transform application.
///
/// # Fields
/// - `game_width` — `f32`.
/// - `game_height` — `f32`.
/// - `scale_mode` — `ScaleMode`.
/// - `scale_x` — `f32`.
/// - `scale_y` — `f32`.
/// - `offset_x` — `f32`.
/// - `offset_y` — `f32`.
///
/// Maintains a mapping between a fixed game coordinate space and the
/// actual window pixel dimensions. Call `resize()` whenever the window
/// size changes.
pub struct Viewport {
    /// Game-space width in virtual pixels.
    pub game_width: f32,
    /// Game-space height in virtual pixels.
    pub game_height: f32,
    /// Active scale mode.
    pub scale_mode: ScaleMode,
    /// Horizontal scale factor.
    pub scale_x: f32,
    /// Vertical scale factor.
    pub scale_y: f32,
    /// Horizontal offset in window pixels (for centering).
    pub offset_x: f32,
    /// Vertical offset in window pixels (for centering).
    pub offset_y: f32,
}

impl Viewport {
    /// Create a viewport with the given game dimensions and scale mode.
    ///
    /// # Parameters
    /// - `game_width` — `f32`.
    /// - `game_height` — `f32`.
    /// - `scale_mode` — `ScaleMode`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Initially assumes the window size equals the game size (scale 1:1).
    pub fn new(game_width: f32, game_height: f32, scale_mode: ScaleMode) -> Self {
        Self {
            game_width,
            game_height,
            scale_mode,
            scale_x: 1.0,
            scale_y: 1.0,
            offset_x: 0.0,
            offset_y: 0.0,
        }
    }

    /// Recompute scale and offset based on the current window size.
    ///
    /// # Parameters
    /// - `window_width` — `f32`.
    /// - `window_height` — `f32`.
    pub fn resize(&mut self, window_width: f32, window_height: f32) {
        let (scale_x, scale_y, offset_x, offset_y) = self.scale_mode.compute_transforms(
            self.game_width,
            self.game_height,
            window_width,
            window_height,
        );
        self.scale_x = scale_x;
        self.scale_y = scale_y;
        self.offset_x = offset_x;
        self.offset_y = offset_y;
    }

    /// Current scale factors `(scale_x, scale_y)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }

    /// Current offset `(offset_x, offset_y)`. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }

    /// Game dimensions `(game_width, game_height)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }

    /// Reference to the current scale mode. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&ScaleMode`.
    pub fn get_scale_mode(&self) -> &ScaleMode {
        &self.scale_mode
    }

    /// Set the scale mode. Call `resize()` afterwards to recompute.
    ///
    /// # Parameters
    /// - `mode` — `ScaleMode`.
    pub fn set_scale_mode(&mut self, mode: ScaleMode) {
        self.scale_mode = mode;
    }

    /// Convert screen coordinates to game coordinates.
    ///
    /// # Parameters
    /// - `screen_x` — `f32`.
    /// - `screen_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn to_game(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
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
    pub fn to_screen(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}
