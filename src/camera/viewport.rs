//! - Viewport scaling strategies for mapping a fixed game surface into variable window sizes.
//! - ScaleMode selects Letterbox (aspect-preserving), Stretch, or PixelPerfect scaling.
//! - Viewport struct holds computed scale factors and offsets after each window resize.
//! - Bidirectional coordinate conversion between screen pixels and game-space units.
//! - Recomputes transforms on resize without allocating new state.

#[derive(Debug, Clone, PartialEq)]
/// Selects how the game surface scales into a window surface.
pub enum ScaleMode {
    /// Preserves aspect ratio and pads unused space.
    Letterbox,
    /// Fills full window independently on each axis.
    Stretch,
    /// Preserves aspect ratio using integer scale factors.
    PixelPerfect,
}
impl ScaleMode {
    /// Compute scale and offset transforms and return (sx, sy, ox, oy).
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

/// Stores viewport scaling state used during window resize and conversion.
pub struct Viewport {
    /// Stores virtual game width in logical units.
    pub game_width: f32,
    /// Stores virtual game height in logical units.
    pub game_height: f32,
    /// Stores active scaling mode for transform computation.
    pub scale_mode: ScaleMode,
    /// Stores computed horizontal scale factor.
    pub scale_x: f32,
    /// Stores computed vertical scale factor.
    pub scale_y: f32,
    /// Stores computed horizontal screen offset in pixels.
    pub offset_x: f32,
    /// Stores computed vertical screen offset in pixels.
    pub offset_y: f32,
}
impl Viewport {
    /// Create viewport state and return it with identity scaling.
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
    /// Recompute scale and offsets from window size and return after updating state.
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
    /// Read current scale factors and return (scale_x, scale_y).
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }
    /// Read current screen offsets and return (offset_x, offset_y).
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }
    /// Read configured game dimensions and return (width, height).
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }
    /// Read active scale mode and return immutable reference to mode.
    pub fn get_scale_mode(&self) -> &ScaleMode {
        &self.scale_mode
    }
    /// Set active scale mode and return after replacing previous mode.
    pub fn set_scale_mode(&mut self, mode: ScaleMode) {
        self.scale_mode = mode;
    }
    /// Convert screen coordinates to game coordinates and return mapped pair.
    pub fn to_game(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }
    /// Convert game coordinates to screen coordinates and return mapped pair.
    pub fn to_screen(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}
