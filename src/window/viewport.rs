use crate::runtime::shared_state::WindowState;
pub fn get_width(ws: &WindowState) -> f32 {
    ws.game_width
}
pub fn get_height(ws: &WindowState) -> f32 {
    ws.game_height
}
pub fn get_scale_mode(ws: &WindowState) -> &str {
    &ws.scale_mode_str
}
pub fn set_scale_mode(ws: &mut WindowState, mode: &str) {
    ws.pending_scale_mode = Some(mode.to_owned());
}
pub fn to_pixels(ws: &WindowState, x: f32, y: f32) -> (f32, f32) {
    (
        x * ws.viewport_scale_x + ws.viewport_offset_x,
        y * ws.viewport_scale_y + ws.viewport_offset_y,
    )
}
pub fn from_pixels(ws: &WindowState, x: f32, y: f32) -> (f32, f32) {
    let sx = if ws.viewport_scale_x.abs() > f32::EPSILON {
        (x - ws.viewport_offset_x) / ws.viewport_scale_x
    } else {
        0.0
    };
    let sy = if ws.viewport_scale_y.abs() > f32::EPSILON {
        (y - ws.viewport_offset_y) / ws.viewport_scale_y
    } else {
        0.0
    };
    (sx, sy)
}
pub struct ScaleInfo {
    pub scale_x: f32,
    pub scale_y: f32,
    pub offset_x: f32,
    pub offset_y: f32,
    pub game_width: f32,
    pub game_height: f32,
}
pub fn get_scale_info(ws: &WindowState) -> ScaleInfo {
    ScaleInfo {
        scale_x: ws.viewport_scale_x,
        scale_y: ws.viewport_scale_y,
        offset_x: ws.viewport_offset_x,
        offset_y: ws.viewport_offset_y,
        game_width: ws.game_width,
        game_height: ws.game_height,
    }
}
pub fn set_scale_mode_validated(ws: &mut WindowState, mode: &str) -> bool {
    let m = mode.to_lowercase();
    if matches!(m.as_str(), "none" | "letterbox" | "stretch" | "pixel") {
        ws.pending_scale_mode = Some(m);
        true
    } else {
        log::warn!("Unknown scale mode: {}", mode);
        false
    }
}
