const CULL_MARGIN_TILES: f32 = 1.5;
const MAX_TILED_POSITIONS: usize = 16_384;
pub fn collect_tiled_positions(
    start_x: f32,
    start_y: f32,
    step_x: f32,
    step_y: f32,
    repeat_x: bool,
    repeat_y: bool,
    screen_size: [f32; 2],
) -> Vec<(f32, f32)> {
    let [screen_w, screen_h] = screen_size;
    let margin_x = step_x.abs() * CULL_MARGIN_TILES;
    let margin_y = step_y.abs() * CULL_MARGIN_TILES;
    let min_x = -margin_x;
    let max_x = screen_w + margin_x;
    let min_y = -margin_y;
    let max_y = screen_h + margin_y;
    let x_values = axis_positions(start_x, step_x, repeat_x, min_x, max_x);
    let y_values = axis_positions(start_y, step_y, repeat_y, min_y, max_y);
    let mut out = Vec::with_capacity((x_values.len() * y_values.len()).min(MAX_TILED_POSITIONS));
    for &x in &x_values {
        for &y in &y_values {
            out.push((x, y));
            if out.len() >= MAX_TILED_POSITIONS {
                return out;
            }
        }
    }
    out
}
fn axis_positions(start: f32, step: f32, repeat: bool, min_v: f32, max_v: f32) -> Vec<f32> {
    if !repeat || step <= 0.0 {
        return vec![start];
    }
    let mut values = Vec::new();
    let mut cur = start;
    while cur > min_v {
        cur -= step;
    }
    while cur + step < min_v {
        cur += step;
    }
    while cur <= max_v {
        values.push(cur);
        if values.len() >= MAX_TILED_POSITIONS {
            break;
        }
        cur += step;
    }
    if values.is_empty() {
        values.push(start);
    }
    values
}
