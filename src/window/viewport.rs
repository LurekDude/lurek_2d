//! Viewport and coordinate-space utilities — logical game dimensions, scale mode,
//! and pixel ↔ game-space coordinate conversion.
//!
//! `viewport_scale_x / _y` and `viewport_offset_x / _y` are computed by `engine::app` whenever
//! the window is resized or the scale mode changes.  These functions treat the pre-computed
//! values as read-only; callers should use [`set_scale_mode`] to request a change.

use crate::runtime::shared_state::WindowState;

/// Returns the logical game width in virtual pixels.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `f32`.
pub fn get_width(ws: &WindowState) -> f32 {
    ws.game_width
}

/// Returns the logical game height in virtual pixels.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `f32`.
pub fn get_height(ws: &WindowState) -> f32 {
    ws.game_height
}

/// Returns the current viewport scale mode string.
///
/// One of `"none"`, `"letterbox"`, `"stretch"`, or `"pixel"`.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `&str`.
pub fn get_scale_mode(ws: &WindowState) -> &str {
    &ws.scale_mode_str
}

/// Schedules a viewport scale mode change.
///
/// Accepted values: `"none"`, `"letterbox"`, `"stretch"`, `"pixel"`.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `mode` — `&str`.
pub fn set_scale_mode(ws: &mut WindowState, mode: &str) {
    ws.pending_scale_mode = Some(mode.to_owned());
}

/// Converts game-space coordinates `(x, y)` to window pixel coordinates.
///
/// Applies the pre-computed viewport scale and offset produced by `engine::app` during
/// the last resize event.  Returns `(0.0, 0.0)` if no viewport transform has been set.
///
/// # Parameters
/// - `ws` — `&WindowState`.
/// - `x` — `f32`.
/// - `y` — `f32`.
///
/// # Returns
/// `(f32, f32)`.
pub fn to_pixels(ws: &WindowState, x: f32, y: f32) -> (f32, f32) {
    (
        x * ws.viewport_scale_x + ws.viewport_offset_x,
        y * ws.viewport_scale_y + ws.viewport_offset_y,
    )
}

/// Converts window pixel coordinates `(x, y)` back to game-space coordinates.
///
/// Returns `(0.0, 0.0)` on either axis where the viewport scale is zero to avoid division
/// by zero during early frames before the first resize event.
///
/// # Parameters
/// - `ws` — `&WindowState`.
/// - `x` — `f32`.
/// - `y` — `f32`.
///
/// # Returns
/// `(f32, f32)`.
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

/// Viewport scale and offset information.
///
/// # Fields
/// - `scale_x` — `f32`.
/// - `scale_y` — `f32`.
/// - `offset_x` — `f32`.
/// - `offset_y` — `f32`.
/// - `game_width` — `f32`.
/// - `game_height` — `f32`.
pub struct ScaleInfo {
    /// Horizontal scale factor from game space to window pixels.
    pub scale_x: f32,
    /// Vertical scale factor from game space to window pixels.
    pub scale_y: f32,
    /// Horizontal offset in window pixels.
    pub offset_x: f32,
    /// Vertical offset in window pixels.
    pub offset_y: f32,
    /// Logical game width.
    pub game_width: f32,
    /// Logical game height.
    pub game_height: f32,
}

/// Returns the current viewport scale and offset information.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `ScaleInfo`.
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

/// Validates and schedules a viewport scale mode change.
///
/// Returns `true` if the mode was valid and set, `false` otherwise.
/// Logs a warning on invalid mode.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `mode` — `&str`.
///
/// # Returns
/// `bool`.
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
