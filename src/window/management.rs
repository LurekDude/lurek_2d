//! Window management commands — title, fullscreen, vsync, position, size, minimize, maximize,
//! close, icon, focus query, and DPI scale.
//!
//! Every function takes `&WindowState` or `&mut WindowState` directly.  No winit calls are
//! made here.  Deferred operations are stored in `pending_*` fields and executed by
//! `engine::app::App` at the start of the next frame.

use crate::engine::shared_state::{FullscreenType, WindowState};

/// Information about the current window mode.
///
/// # Fields
/// - `fullscreen` — `bool`.
/// - `fullscreen_type` — `&'static str`.
/// - `vsync` — `i32`.
pub struct ModeInfo {
    /// Whether the window is in fullscreen mode.
    pub fullscreen: bool,
    /// The fullscreen type (`"desktop"` or `"exclusive"`).
    pub fullscreen_type: &'static str,
    /// The VSync mode integer.
    pub vsync: i32,
}

/// Schedules a window title change for the next frame.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `title` — `&str`.
pub fn set_title(ws: &mut WindowState, title: &str) {
    ws.pending_title = Some(title.to_owned());
}

/// Schedules a fullscreen mode change.
///
/// `flag` = `true` to enter fullscreen, `false` to exit.
/// `mode` = `"exclusive"` for exclusive fullscreen; anything else uses borderless desktop mode.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `flag` — `bool`.
/// - `mode` — `&str`.
pub fn set_fullscreen(ws: &mut WindowState, flag: bool, mode: &str) {
    ws.pending_fullscreen = Some(flag);
    ws.pending_fullscreen_type = if mode == "exclusive" {
        FullscreenType::Exclusive
    } else {
        FullscreenType::Desktop
    };
}

/// Returns whether the window is currently in fullscreen mode.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `bool`.
pub fn is_fullscreen(ws: &WindowState) -> bool {
    ws.fullscreen
}

/// Schedules a VSync mode change.
///
/// `1` = Fifo (vsync on), `0` = Immediate (vsync off), `-1` = Mailbox (adaptive vsync).
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `mode` — `i32`.
pub fn set_vsync(ws: &mut WindowState, mode: i32) {
    ws.pending_vsync = Some(mode);
}

/// Returns the current VSync mode integer.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `i32`.
pub fn get_vsync(ws: &WindowState) -> i32 {
    ws.vsync_mode
}

/// Returns the DPI scale factor of the display the window is on.
///
/// `1.0` on standard displays; `2.0` or higher on HiDPI / Retina displays.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `f64`.
pub fn get_dpi_scale(ws: &WindowState) -> f64 {
    ws.dpi_scale
}

/// Returns the current window position in screen coordinates as `(x, y)`.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `(i32, i32)`.
pub fn get_position(ws: &WindowState) -> (i32, i32) {
    (ws.position_x, ws.position_y)
}

/// Schedules a window position change to `(x, y)` in screen coordinates.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `x` — `i32`.
/// - `y` — `i32`.
pub fn set_position(ws: &mut WindowState, x: i32, y: i32) {
    ws.pending_position = Some((x, y));
}

/// Schedules a window minimize (iconify) operation.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
pub fn minimize(ws: &mut WindowState) {
    ws.pending_minimize = true;
}

/// Schedules a window maximize operation.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
pub fn maximize(ws: &mut WindowState) {
    ws.pending_maximize = true;
}

/// Schedules a window restore from minimized or maximized state.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
pub fn restore(ws: &mut WindowState) {
    ws.pending_restore = true;
}

/// Returns whether the window is currently minimized.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `bool`.
pub fn is_minimized(ws: &WindowState) -> bool {
    ws.minimized
}

/// Returns whether the window is currently maximized.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `bool`.
pub fn is_maximized(ws: &WindowState) -> bool {
    ws.maximized
}

/// Returns whether the window currently has keyboard focus.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `bool`.
pub fn has_focus(ws: &WindowState) -> bool {
    ws.focused
}

/// Schedules a user-attention request (taskbar flash on Windows / dock bounce on macOS).
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
pub fn request_attention(ws: &mut WindowState) {
    ws.pending_attention = true;
}

/// Schedules window closure on the next frame, exiting the game loop.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
pub fn close(ws: &mut WindowState) {
    ws.pending_close = true;
}

/// Schedules a window icon change from the given file path.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `path` — `&str`.
pub fn set_icon(ws: &mut WindowState, path: &str) {
    ws.pending_icon_path = Some(path.to_owned());
}

/// Schedules a window resize to `(w, h)` logical pixels.
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `w` — `u32`.
/// - `h` — `u32`.
pub fn set_size(ws: &mut WindowState, w: u32, h: u32) {
    ws.pending_size = Some((w, h));
}

/// Returns the fullscreen type as a lowercase string.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `&'static str`.
pub fn get_fullscreen_type_str(ws: &WindowState) -> &'static str {
    match ws.fullscreen_type {
        FullscreenType::Desktop => "desktop",
        FullscreenType::Exclusive => "exclusive",
    }
}

/// Returns the fullscreen state and type as a `(bool, &str)` pair.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `(bool, &'static str)`.
pub fn get_fullscreen(ws: &WindowState) -> (bool, &'static str) {
    (ws.fullscreen, get_fullscreen_type_str(ws))
}

/// Returns whether the window is currently visible.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `bool`.
pub fn is_visible(ws: &WindowState) -> bool {
    ws.visible
}

/// Returns whether the mouse cursor is inside the window.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `bool`.
pub fn has_mouse_focus(ws: &WindowState) -> bool {
    ws.mouse_focused
}

/// Converts a device-independent value to physical pixels using the DPI scale.
///
/// # Parameters
/// - `ws` — `&WindowState`.
/// - `value` — `f64`.
///
/// # Returns
/// `f64`.
pub fn to_dpi_pixels(ws: &WindowState, value: f64) -> f64 {
    value * ws.dpi_scale
}

/// Converts a physical pixel value to device-independent coordinates.
///
/// Returns the input unchanged if the DPI scale is zero.
///
/// # Parameters
/// - `ws` — `&WindowState`.
/// - `value` — `f64`.
///
/// # Returns
/// `f64`.
pub fn from_dpi_pixels(ws: &WindowState, value: f64) -> f64 {
    if ws.dpi_scale > 0.0 {
        value / ws.dpi_scale
    } else {
        value
    }
}

/// Returns the window dimensions in physical pixels (logical size × DPI scale).
///
/// # Parameters
/// - `ws` — `&WindowState`.
/// - `win_w` — `u32`.
/// - `win_h` — `u32`.
///
/// # Returns
/// `(u32, u32)`.
pub fn get_pixel_dimensions(ws: &WindowState, win_w: u32, win_h: u32) -> (u32, u32) {
    let scale = ws.dpi_scale;
    (
        (win_w as f64 * scale).round() as u32,
        (win_h as f64 * scale).round() as u32,
    )
}

/// Schedules a combined window mode change (size + optional fullscreen + optional vsync).
///
/// # Parameters
/// - `ws` — `&mut WindowState`.
/// - `w` — `u32`.
/// - `h` — `u32`.
/// - `fullscreen` — `Option<bool>`.
/// - `fstype` — `Option<&str>`.
/// - `vsync` — `Option<i32>`.
pub fn set_mode(
    ws: &mut WindowState,
    w: u32,
    h: u32,
    fullscreen: Option<bool>,
    fstype: Option<&str>,
    vsync: Option<i32>,
) {
    set_size(ws, w, h);
    if let Some(fs) = fullscreen {
        set_fullscreen(ws, fs, fstype.unwrap_or("desktop"));
    }
    if let Some(v) = vsync {
        set_vsync(ws, v);
    }
}

/// Returns the current window mode settings.
///
/// # Parameters
/// - `ws` — `&WindowState`.
///
/// # Returns
/// `ModeInfo`.
pub fn get_mode(ws: &WindowState) -> ModeInfo {
    ModeInfo {
        fullscreen: ws.fullscreen,
        fullscreen_type: get_fullscreen_type_str(ws),
        vsync: ws.vsync_mode,
    }
}

/// Shows a platform-native message box dialog.
///
/// `box_type`: `"info"`, `"warning"`, or `"error"` (default `"info"`).
/// `btn_type`: `"ok"`, `"okcancel"`, or `"yesno"` (default `"ok"`).
///
/// Returns the button the user pressed: `"ok"`, `"yes"`, `"no"`, or `"cancel"`.
///
/// # Parameters
/// - `title` — `&str`.
/// - `message` — `&str`.
/// - `box_type` — `&str`.
/// - `btn_type` — `&str`.
///
/// # Returns
/// `&'static str`.
pub fn show_message_box(
    title: &str,
    message: &str,
    box_type: &str,
    btn_type: &str,
) -> &'static str {
    let level = match box_type {
        "warning" => rfd::MessageLevel::Warning,
        "error" => rfd::MessageLevel::Error,
        _ => rfd::MessageLevel::Info,
    };
    let buttons = match btn_type {
        "okcancel" => rfd::MessageButtons::OkCancel,
        "yesno" => rfd::MessageButtons::YesNo,
        _ => rfd::MessageButtons::Ok,
    };
    let result = rfd::MessageDialog::new()
        .set_title(title)
        .set_description(message)
        .set_level(level)
        .set_buttons(buttons)
        .show();
    match result {
        rfd::MessageDialogResult::Ok => "ok",
        rfd::MessageDialogResult::Yes => "yes",
        rfd::MessageDialogResult::No => "no",
        rfd::MessageDialogResult::Cancel => "cancel",
        rfd::MessageDialogResult::Custom(_) => "ok",
    }
}
