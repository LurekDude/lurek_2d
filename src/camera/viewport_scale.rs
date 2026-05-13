use crate::camera::viewport::ScaleMode;
pub struct ViewportScale {
    pub game_width: f32,
    pub game_height: f32,
    pub mode: ScaleMode,
    pub scale_x: f32,
    pub scale_y: f32,
    pub offset_x: f32,
    pub offset_y: f32,
    pub scaled_width: f32,
    pub scaled_height: f32,
}
impl ViewportScale {
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
    pub fn get_game_dimensions(&self) -> (f32, f32) {
        (self.game_width, self.game_height)
    }
    pub fn get_scaled_dimensions(&self) -> (f32, f32) {
        (self.scaled_width, self.scaled_height)
    }
    pub fn get_offset(&self) -> (f32, f32) {
        (self.offset_x, self.offset_y)
    }
    pub fn get_scale(&self) -> (f32, f32) {
        (self.scale_x, self.scale_y)
    }
    pub fn get_mode(&self) -> &ScaleMode {
        &self.mode
    }
    pub fn to_game_coords(&self, screen_x: f32, screen_y: f32) -> (f32, f32) {
        (
            (screen_x - self.offset_x) / self.scale_x,
            (screen_y - self.offset_y) / self.scale_y,
        )
    }
    pub fn to_screen_coords(&self, game_x: f32, game_y: f32) -> (f32, f32) {
        (
            game_x * self.scale_x + self.offset_x,
            game_y * self.scale_y + self.offset_y,
        )
    }
}
