//! Extend viewport mapping with scaled content dimensions.
//! Keep transform-stack consumers synchronized with current scale and offsets.
//! Share scaling behavior with `ScaleMode::compute_transforms`.

use crate::camera::viewport::ScaleMode;

/// Store viewport mapping plus precomputed scaled game dimensions.
pub struct ViewportScale {
    /// Store game-space width in virtual pixels.
    pub game_width: f32,
    /// Store game-space height in virtual pixels.
    pub game_height: f32,
    /// Store active scale mode.
    pub mode: ScaleMode,
    /// Store horizontal scale factor.
    pub scale_x: f32,
    /// Store vertical scale factor.
    pub scale_y: f32,
    /// Store horizontal offset in window pixels.
    pub offset_x: f32,
    /// Store vertical offset in window pixels.
    pub offset_y: f32,
    /// Store `game_width * scale_x`.
    pub scaled_width: f32,
    /// Store `game_height * scale_y`.
    pub scaled_height: f32,
}

impl ViewportScale {
    /// Create viewport-scale state with unit scale and return it.
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

    /// Recompute scales, offsets, and scaled dimensions from current window size.
    pub fn resize(&mut self, window_width: f32, window_height: f32) {
        let (scale_x, scale_y, offset_x, offset_y) = self.mode.compute_transforms(
            self.game_width,
            self.game_height,
            window_width,
            window_height,
        );
        self.scale_x = scale_x;
        self.scale_y = scale_y;
        self.offset_x = offset_x;
        self.offset_y = offset_y;
        self.scaled_width = self.game_width * self.scale_x;
        self.scaled_height = self.game_height * self.scale_y;
    }

    /// Return game dimensions `(game_width, game_height)`.
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }

    /// Return scaled dimensions `(scaled_width, scaled_height)`.
    pub fn get_scaled_dimensions(&self) -> (f32, f32) {
        (self.scaled_width, self.scaled_height)
    }

    /// Return current pixel offsets `(offset_x, offset_y)`.
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }

    /// Return current scale factors `(scale_x, scale_y)`.
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }

    /// Return active scale mode by reference.
    pub fn get_mode(&self) -> &ScaleMode {
        &self.mode
    }

    /// Convert window coordinates to game coordinates and return the pair.
    pub fn to_game_coords(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }

    /// Convert game coordinates to window coordinates and return the pair.
    pub fn to_screen_coords(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}

