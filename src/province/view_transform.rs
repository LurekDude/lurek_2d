pub fn fit_camera_to_screen(
    map_w: u32,
    map_h: u32,
    pixel_size: f32,
    screen_w: f32,
    screen_h: f32,
) -> (f32, f32, f32) {
    let safe_pixel = pixel_size.max(0.0001);
    let sw = map_w as f32 * safe_pixel;
    let sh = map_h as f32 * safe_pixel;
    if sw <= 0.0 || sh <= 0.0 || screen_w <= 0.0 || screen_h <= 0.0 {
        return (0.0, 0.0, 1.0);
    }
    let zoom = (screen_w / sw).min(screen_h / sh).max(0.0001);
    let cam_x = (screen_w - sw * zoom) * 0.5;
    let cam_y = (screen_h - sh * zoom) * 0.5;
    (cam_x, cam_y, zoom)
}
pub fn screen_to_map(
    screen_x: f32,
    screen_y: f32,
    cam_x: f32,
    cam_y: f32,
    zoom: f32,
    pixel_size: f32,
) -> (f32, f32) {
    let denom = (zoom * pixel_size).max(0.0001);
    ((screen_x - cam_x) / denom, (screen_y - cam_y) / denom)
}
pub fn map_to_cell(map_x: f32, map_y: f32, map_w: u32, map_h: u32) -> Option<(u32, u32)> {
    if !map_x.is_finite() || !map_y.is_finite() {
        return None;
    }
    let cell_x = map_x.floor();
    let cell_y = map_y.floor();
    if cell_x < 0.0 || cell_y < 0.0 {
        return None;
    }
    let x = cell_x as u32;
    let y = cell_y as u32;
    if x < map_w && y < map_h {
        Some((x, y))
    } else {
        None
    }
}
pub fn zoom_camera_at(
    anchor_x: f32,
    anchor_y: f32,
    cam_x: f32,
    cam_y: f32,
    old_zoom: f32,
    new_zoom: f32,
) -> (f32, f32) {
    if old_zoom.abs() < 0.0001 {
        return (cam_x, cam_y);
    }
    let scale = new_zoom / old_zoom;
    (
        anchor_x - (anchor_x - cam_x) * scale,
        anchor_y - (anchor_y - cam_y) * scale,
    )
}
