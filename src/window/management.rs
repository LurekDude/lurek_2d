//! OS window control helpers for `lurek.window` — title, size, position, fullscreen,
//! vsync, DPI conversion, focus, icon, minimize/maximize/restore, and message boxes.
//! All functions stage changes on `WindowState`; the event loop applies them next frame.
//! Depends on `crate::runtime::shared_state` and `rfd` for native dialogs.

use crate::runtime::shared_state::{FullscreenType, WindowState};
/// Snapshot of the window's current mode returned by `get_mode`.
pub struct ModeInfo {
    /// `true` when the window is currently in any fullscreen mode.
    pub fullscreen: bool,
    /// String name of the active fullscreen type: `"desktop"` or `"exclusive"`.
    pub fullscreen_type: &'static str,
    /// Current vsync mode integer (0 = off, 1 = on, -1 = adaptive).
    pub vsync: i32,
}
/// Stage a window title change to `title`; applied by the event loop next frame.
pub fn set_title(ws: &mut WindowState, title: &str) {
    ws.pending_title = Some(title.to_owned());
}
/// Stage a fullscreen toggle; `mode` is `"exclusive"` or `"desktop"`; applied next frame.
pub fn set_fullscreen(ws: &mut WindowState, flag: bool, mode: &str) {
    ws.pending_fullscreen = Some(flag);
    ws.pending_fullscreen_type = if mode == "exclusive" {
        FullscreenType::Exclusive
    } else {
        FullscreenType::Desktop
    };
}
/// Return `true` when the window is currently in fullscreen.
pub fn is_fullscreen(ws: &WindowState) -> bool {
    ws.fullscreen
}
/// Stage a vsync mode change (0 = off, 1 = on, -1 = adaptive); applied next frame.
pub fn set_vsync(ws: &mut WindowState, mode: i32) {
    ws.pending_vsync = Some(mode);
}
/// Return the current vsync mode integer.
pub fn get_vsync(ws: &WindowState) -> i32 {
    ws.vsync_mode
}
/// Return the DPI scaling factor reported by the OS.
pub fn get_dpi_scale(ws: &WindowState) -> f64 {
    ws.dpi_scale
}
/// Return the window's current `(x, y)` screen position in physical pixels.
pub fn get_position(ws: &WindowState) -> (i32, i32) {
    (ws.position_x, ws.position_y)
}
/// Stage a window position move to `(x, y)` in physical pixels; applied next frame.
pub fn set_position(ws: &mut WindowState, x: i32, y: i32) {
    ws.pending_position = Some((x, y));
}
/// Stage a move to `display_index`; return `false` when index is negative.
pub fn set_display(ws: &mut WindowState, display_index: i32) -> bool {
    if display_index < 0 {
        return false;
    }
    ws.pending_display_index = Some(display_index as usize);
    true
}
/// Stage a minimize request; applied next frame.
pub fn minimize(ws: &mut WindowState) {
    ws.pending_minimize = true;
}
/// Stage a maximize request; applied next frame.
pub fn maximize(ws: &mut WindowState) {
    ws.pending_maximize = true;
}
/// Stage a restore-from-min/max request; applied next frame.
pub fn restore(ws: &mut WindowState) {
    ws.pending_restore = true;
}
/// Return `true` when the window is currently minimized.
pub fn is_minimized(ws: &WindowState) -> bool {
    ws.minimized
}
/// Return `true` when the window is currently maximized.
pub fn is_maximized(ws: &WindowState) -> bool {
    ws.maximized
}
/// Return `true` when the window has keyboard focus.
pub fn has_focus(ws: &WindowState) -> bool {
    ws.focused
}
/// Stage a taskbar attention request on platforms that support it.
pub fn request_attention(ws: &mut WindowState) {
    ws.pending_attention = true;
}
/// Alias for `request_attention` for platforms that use flash semantics.
pub fn flash(ws: &mut WindowState) {
    request_attention(ws);
}
/// Stage a close request; the event loop will process it and stop the run loop.
pub fn close(ws: &mut WindowState) {
    ws.pending_close = true;
}
/// Stage a window icon change from image file `path`; applied next frame.
pub fn set_icon(ws: &mut WindowState, path: &str) {
    ws.pending_icon_path = Some(path.to_owned());
}
/// Stage a resize to `(w, h)` in logical pixels; applied next frame.
pub fn set_size(ws: &mut WindowState, w: u32, h: u32) {
    ws.pending_size = Some((w, h));
}
/// Return the current fullscreen type string (`"desktop"` or `"exclusive"`).
pub fn get_fullscreen_type_str(ws: &WindowState) -> &'static str {
    match ws.fullscreen_type {
        FullscreenType::Desktop => "desktop",
        FullscreenType::Exclusive => "exclusive",
    }
}
/// Return `(is_fullscreen, fullscreen_type_str)` as a convenience pair.
pub fn get_fullscreen(ws: &WindowState) -> (bool, &'static str) {
    (ws.fullscreen, get_fullscreen_type_str(ws))
}
/// Return `true` when the window is visible (not hidden).
pub fn is_visible(ws: &WindowState) -> bool {
    ws.visible
}
/// Return `true` when the mouse cursor is inside the window client area.
pub fn has_mouse_focus(ws: &WindowState) -> bool {
    ws.mouse_focused
}
/// Scale a logical `value` to physical pixels using the window's DPI factor.
pub fn to_dpi_pixels(ws: &WindowState, value: f64) -> f64 {
    value * ws.dpi_scale
}
/// Convert physical `value` back to logical pixels; return `value` unchanged when DPI scale is zero.
pub fn from_dpi_pixels(ws: &WindowState, value: f64) -> f64 {
    if ws.dpi_scale > 0.0 {
        value / ws.dpi_scale
    } else {
        value
    }
}
/// Return `(width, height)` in physical pixels by scaling logical dimensions by the DPI factor.
pub fn get_pixel_dimensions(ws: &WindowState, win_w: u32, win_h: u32) -> (u32, u32) {
    let scale = ws.dpi_scale;
    (
        (win_w as f64 * scale).round() as u32,
        (win_h as f64 * scale).round() as u32,
    )
}
/// Stage a combined mode update: size, optional fullscreen flag, optional fullscreen type, optional vsync.
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
/// Return a `ModeInfo` snapshot of the current fullscreen and vsync state.
pub fn get_mode(ws: &WindowState) -> ModeInfo {
    ModeInfo {
        fullscreen: ws.fullscreen,
        fullscreen_type: get_fullscreen_type_str(ws),
        vsync: ws.vsync_mode,
    }
}
/// Show a native OS dialog with `title`, `message`, `box_type` (`"info"`,`"warning"`,`"error"`), and `btn_type` (`"ok"`,`"okcancel"`,`"yesno"`); return the button string.
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
