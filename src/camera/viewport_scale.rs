//! - Viewport scale state object used by the engine resize flow.
//! - Stores computed scale, offset, and scaled dimensions after each resize.
//! - Provides bidirectional game/screen coordinate conversion helpers.

use crate::camera::viewport::ScaleMode;

/// Stores runtime viewport scaling values for game and window surfaces.
pub struct ViewportScale {
    /// Stores logical game width used as scaling source.
    pub game_width: f32,
    /// Stores logical game height used as scaling source.
    pub game_height: f32,
    /// Stores active mode controlling transform behavior.
    pub mode: ScaleMode,
    /// Stores computed horizontal scale factor.
    pub scale_x: f32,
    /// Stores computed vertical scale factor.
    pub scale_y: f32,
    /// Stores computed horizontal offset in screen space.
    pub offset_x: f32,
    /// Stores computed vertical offset in screen space.
    pub offset_y: f32,
    /// Stores scaled game width in screen units.
    pub scaled_width: f32,
    /// Stores scaled game height in screen units.
    pub scaled_height: f32,
}
impl ViewportScale {
    /// Create viewport scale state and return it with identity transforms.
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
    /// Recompute transforms from window dimensions and return after updating fields.
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
    /// Read logical game dimensions and return (width, height).
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }
    /// Read scaled dimensions and return (scaled_width, scaled_height).
    pub fn get_scaled_dimensions(&self) -> (f32, f32) {
        (self.scaled_width, self.scaled_height)
    }
    /// Read viewport offset and return (offset_x, offset_y).
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }
    /// Read scale factors and return (scale_x, scale_y).
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }
    /// Read active scale mode and return immutable reference to it.
    pub fn get_mode(&self) -> &ScaleMode {
        &self.mode
    }
    /// Convert screen coordinates into game-space coordinates and return mapped pair.
    pub fn to_game_coords(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }
    /// Convert game coordinates into screen-space coordinates and return mapped pair.
    pub fn to_screen_coords(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}
