use crate::runtime::shared_state::{FullscreenType, WindowState};
pub struct ModeInfo {
    pub fullscreen: bool,
    pub fullscreen_type: &'static str,
    pub vsync: i32,
}
pub fn set_title(ws: &mut WindowState, title: &str) {
    ws.pending_title = Some(title.to_owned());
}
pub fn set_fullscreen(ws: &mut WindowState, flag: bool, mode: &str) {
    ws.pending_fullscreen = Some(flag);
    ws.pending_fullscreen_type = if mode == "exclusive" {
        FullscreenType::Exclusive
    } else {
        FullscreenType::Desktop
    };
}
pub fn is_fullscreen(ws: &WindowState) -> bool {
    ws.fullscreen
}
pub fn set_vsync(ws: &mut WindowState, mode: i32) {
    ws.pending_vsync = Some(mode);
}
pub fn get_vsync(ws: &WindowState) -> i32 {
    ws.vsync_mode
}
pub fn get_dpi_scale(ws: &WindowState) -> f64 {
    ws.dpi_scale
}
pub fn get_position(ws: &WindowState) -> (i32, i32) {
    (ws.position_x, ws.position_y)
}
pub fn set_position(ws: &mut WindowState, x: i32, y: i32) {
    ws.pending_position = Some((x, y));
}
pub fn set_display(ws: &mut WindowState, display_index: i32) -> bool {
    if display_index < 0 {
        return false;
    }
    ws.pending_display_index = Some(display_index as usize);
    true
}
pub fn minimize(ws: &mut WindowState) {
    ws.pending_minimize = true;
}
pub fn maximize(ws: &mut WindowState) {
    ws.pending_maximize = true;
}
pub fn restore(ws: &mut WindowState) {
    ws.pending_restore = true;
}
pub fn is_minimized(ws: &WindowState) -> bool {
    ws.minimized
}
pub fn is_maximized(ws: &WindowState) -> bool {
    ws.maximized
}
pub fn has_focus(ws: &WindowState) -> bool {
    ws.focused
}
pub fn request_attention(ws: &mut WindowState) {
    ws.pending_attention = true;
}
pub fn flash(ws: &mut WindowState) {
    request_attention(ws);
}
pub fn close(ws: &mut WindowState) {
    ws.pending_close = true;
}
pub fn set_icon(ws: &mut WindowState, path: &str) {
    ws.pending_icon_path = Some(path.to_owned());
}
pub fn set_size(ws: &mut WindowState, w: u32, h: u32) {
    ws.pending_size = Some((w, h));
}
pub fn get_fullscreen_type_str(ws: &WindowState) -> &'static str {
    match ws.fullscreen_type {
        FullscreenType::Desktop => "desktop",
        FullscreenType::Exclusive => "exclusive",
    }
}
pub fn get_fullscreen(ws: &WindowState) -> (bool, &'static str) {
    (ws.fullscreen, get_fullscreen_type_str(ws))
}
pub fn is_visible(ws: &WindowState) -> bool {
    ws.visible
}
pub fn has_mouse_focus(ws: &WindowState) -> bool {
    ws.mouse_focused
}
pub fn to_dpi_pixels(ws: &WindowState, value: f64) -> f64 {
    value * ws.dpi_scale
}
pub fn from_dpi_pixels(ws: &WindowState, value: f64) -> f64 {
    if ws.dpi_scale > 0.0 {
        value / ws.dpi_scale
    } else {
        value
    }
}
pub fn get_pixel_dimensions(ws: &WindowState, win_w: u32, win_h: u32) -> (u32, u32) {
    let scale = ws.dpi_scale;
    (
        (win_w as f64 * scale).round() as u32,
        (win_h as f64 * scale).round() as u32,
    )
}
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
pub fn get_mode(ws: &WindowState) -> ModeInfo {
    ModeInfo {
        fullscreen: ws.fullscreen,
        fullscreen_type: get_fullscreen_type_str(ws),
        vsync: ws.vsync_mode,
    }
}
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
