//! Map a fixed game resolution into window pixels.
//! Own scale and offset computation for letterbox, stretch, and pixel-perfect modes.
//! Keep window-to-game and game-to-window coordinate conversion in one place.

#[derive(Debug, Clone, PartialEq)]
/// Select how game coordinates scale into the window.
pub enum ScaleMode {
    /// Keep aspect ratio and add bars when needed.
    Letterbox,
    /// Fill window using independent x and y scales.
    Stretch,
    /// Use integer scale to keep pixel-art edges crisp.
    PixelPerfect,
}

impl ScaleMode {
    /// Compute `(scale_x, scale_y, offset_x, offset_y)` for game and window dimensions.
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

/// Store viewport mapping from virtual game space to window space.
pub struct Viewport {
    /// Store game-space width in virtual pixels.
    pub game_width: f32,
    /// Store game-space height in virtual pixels.
    pub game_height: f32,
    /// Store current scale mode.
    pub scale_mode: ScaleMode,
    /// Store horizontal scale factor.
    pub scale_x: f32,
    /// Store vertical scale factor.
    pub scale_y: f32,
    /// Store horizontal offset in window pixels.
    pub offset_x: f32,
    /// Store vertical offset in window pixels.
    pub offset_y: f32,
}

impl Viewport {
    /// Create a viewport with unit scale and zero offsets and return it.
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

    /// Recompute scale and offset from the current window dimensions.
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

    /// Return current scale factors `(scale_x, scale_y)`.
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }

    /// Return current pixel offsets `(offset_x, offset_y)`.
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }

    /// Return game dimensions `(game_width, game_height)`.
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }

    /// Return current scale mode by reference.
    pub fn get_scale_mode(&self) -> &ScaleMode {
        &self.scale_mode
    }

    /// Set scale mode; resized transform values update on next `resize` call.
    pub fn set_scale_mode(&mut self, mode: ScaleMode) {
        self.scale_mode = mode;
    }

    /// Convert window coordinates to game coordinates and return the pair.
    pub fn to_game(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }

    /// Convert game coordinates to window coordinates and return the pair.
    pub fn to_screen(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}

