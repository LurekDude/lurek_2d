#[derive(Debug, Clone, PartialEq)]
pub enum ScaleMode {
    Letterbox,
    Stretch,
    PixelPerfect,
}
impl ScaleMode {
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
pub struct Viewport {
    pub game_width: f32,
    pub game_height: f32,
    pub scale_mode: ScaleMode,
    pub scale_x: f32,
    pub scale_y: f32,
    pub offset_x: f32,
    pub offset_y: f32,
}
impl Viewport {
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
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }
    pub fn get_scale_mode(&self) -> &ScaleMode {
        &self.scale_mode
    }
    pub fn set_scale_mode(&mut self, mode: ScaleMode) {
        self.scale_mode = mode;
    }
    pub fn to_game(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }
    pub fn to_screen(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}
