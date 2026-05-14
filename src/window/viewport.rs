//! Virtual viewport coordinate-mapping helpers for `lurek.window`.
//! Translates between logical game coordinates and physical screen pixels using
//! scale factors and letter-box offsets stored on `WindowState`.
//! Scale mode is staged here and applied by the event loop; valid modes: `none`, `letterbox`, `stretch`, `pixel`.

use crate::runtime::shared_state::WindowState;
/// Return the logical game viewport width in pixels.
pub fn get_width(ws: &WindowState) -> f32 {
    ws.game_width
}
/// Return the logical game viewport height in pixels.
pub fn get_height(ws: &WindowState) -> f32 {
    ws.game_height
}
/// Return the current scale mode string (`"none"`, `"letterbox"`, `"stretch"`, or `"pixel"`).
pub fn get_scale_mode(ws: &WindowState) -> &str {
    &ws.scale_mode_str
}
/// Stage a scale mode change to `mode`; validated and applied by the event loop next frame.
pub fn set_scale_mode(ws: &mut WindowState, mode: &str) {
    ws.pending_scale_mode = Some(mode.to_owned());
}
/// Convert logical game `(x, y)` to physical screen pixels using current scale and letterbox offset.
pub fn to_pixels(ws: &WindowState, x: f32, y: f32) -> (f32, f32) {
    (
        x * ws.viewport_scale_x + ws.viewport_offset_x,
        y * ws.viewport_scale_y + ws.viewport_offset_y,
    )
}
/// Convert physical screen `(x, y)` back to logical game coordinates; return `(0, 0)` when scale is near-zero.
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
/// Snapshot of all viewport scale and offset values returned by `get_scale_info`.
pub struct ScaleInfo {
    /// Horizontal scale factor from game to screen pixels.
    pub scale_x: f32,
    /// Vertical scale factor from game to screen pixels.
    pub scale_y: f32,
    /// Horizontal letterbox offset in screen pixels.
    pub offset_x: f32,
    /// Vertical letterbox offset in screen pixels.
    pub offset_y: f32,
    /// Logical game viewport width.
    pub game_width: f32,
    /// Logical game viewport height.
    pub game_height: f32,
}
/// Return a `ScaleInfo` snapshot of the current viewport transform.
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
/// Stage a scale mode change; return `false` and log a warning when `mode` is not a recognised value.
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
