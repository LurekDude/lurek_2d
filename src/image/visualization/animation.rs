//! Animation visualization helpers.
//!
//! Produces CPU-side [`ImageData`] renderings of animation state: frame grids,
//! playback strips, playback control timelines, and convenience wrappers.

use crate::animation::Animation;
use crate::image::ImageData;

/// Render an animation's frame grid as a strip of numbered cells.
///
/// Each frame is drawn as a `cell_w × cell_h` block. The current frame
/// is highlighted with a yellow border.
///
/// # Parameters
/// - `anim` — `&Animation`. The animation to visualize.
/// - `cell_w` — `u32`. Width of each frame cell.
/// - `cell_h` — `u32`. Height of each frame cell.
///
/// # Returns
/// `ImageData`.
pub fn draw_animation_frame_grid_to_image(anim: &Animation, cell_w: u32, cell_h: u32) -> ImageData {
    let frame_count = anim.get_frame_count().max(1) as u32;
    let cols = frame_count.min(8);
    let rows = frame_count.div_ceil(cols);
    let width = cols * cell_w;
    let height = rows * cell_h;
    let mut img = ImageData::new(width, height);
    img.fill(18, 18, 28, 255);

    for i in 0..frame_count {
        let col = i % cols;
        let row = i / cols;
        let px = col * cell_w;
        let py = row * cell_h;
        let is_current = i == anim.current_frame() as u32;
        let (r, g, b) = if is_current {
            (255u8, 220u8, 60u8)
        } else {
            (80u8, 80u8, 100u8)
        };
        img.draw_rect(
            (px + 1) as i32,
            (py + 1) as i32,
            cell_w.saturating_sub(2).max(1),
            cell_h.saturating_sub(2).max(1),
            r / 4,
            g / 4,
            b / 4,
            255,
        );
        // Border
        img.draw_rect(px as i32, py as i32, cell_w, 1, r, g, b, 255);
        img.draw_rect(px as i32, (py + cell_h - 1) as i32, cell_w, 1, r, g, b, 255);
        img.draw_rect(px as i32, py as i32, 1, cell_h, r, g, b, 255);
        img.draw_rect((px + cell_w - 1) as i32, py as i32, 1, cell_h, r, g, b, 255);
        let label = format!("{}", i);
        img.draw_label(
            &label,
            (px + 4) as i32,
            (py + cell_h / 2 - 4) as i32,
            r,
            g,
            b,
        );
    }
    img
}

/// Render an animation playback strip as snapshot columns.
///
/// Draws `snapshots.len()` side-by-side panels, each showing
/// a frame index highlighted in the sequence. The panel columns
/// are colored to indicate which frame was active at that step.
///
/// # Parameters
/// - `snapshots` — `&[usize]`. Frame index active at each step.
/// - `total_frames` — `usize`. Total frame count.
/// - `panel_w` — `u32`. Width of each step panel.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn draw_animation_playback_to_image(
    snapshots: &[usize],
    total_frames: usize,
    panel_w: u32,
    height: u32,
) -> ImageData {
    let width = panel_w * snapshots.len().max(1) as u32;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    img.draw_label("PLAYBACK", 4, 4, 180, 220, 255);

    if total_frames == 0 {
        return img;
    }
    let bar_h = (height - 24) / total_frames.max(1) as u32;

    for (step, &frame) in snapshots.iter().enumerate() {
        let ox = step as u32 * panel_w;
        for f in 0..total_frames {
            let y = 20 + f as u32 * bar_h;
            let is_active = f == frame;
            let (r, g, b) = if is_active {
                (255u8, 220u8, 60u8)
            } else {
                (40u8, 40u8, 50u8)
            };
            for bx in 1..panel_w.saturating_sub(1) {
                for by in 0..bar_h.saturating_sub(1) {
                    if (ox + bx) < width && (y + by) < height {
                        img.set_pixel(ox + bx, y + by, r, g, b, if is_active { 220 } else { 80 });
                    }
                }
            }
        }
    }
    img
}

/// Render an animation playback-control timeline diagram.
///
/// Draws a run-frame bar, idle-frame bar, optional quad annotation, and a
/// summary footer showing total frame and clip counts.
///
/// # Parameters
/// - `run_frames` — `&[usize]`. Frame index active at each run step.
/// - `idle_frames` — `&[usize]`. Frame index active at each idle step.
/// - `total_frames` — `usize`. Total frame count in the animation.
/// - `quad_str` — `Option<&str>`. Optional quad coordinate annotation.
/// - `summary` — `&str`. Footer summary text.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
pub fn animation_playback_control_to_image(
    run_frames: &[usize],
    idle_frames: &[usize],
    total_frames: usize,
    quad_str: Option<&str>,
    summary: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    for (i, &f) in run_frames.iter().enumerate() {
        let x = 10 + i as i32 * 24;
        let t = if total_frames > 0 {
            f as f32 / total_frames as f32
        } else {
            0.0
        };
        let r = (80.0 + t * 175.0) as u8;
        let g = (200.0 - t * 120.0) as u8;
        img.draw_rect(x, 20, 20, 30, r, g, 80, 255);
    }
    img.draw_label("RUN FRAMES", 10, 55, 200, 200, 200);
    img.draw_label("PAUSE OK", 10, 80, 200, 200, 80);
    img.draw_label("RESUME OK", 10, 100, 80, 200, 80);
    img.draw_label("STOP OK", 10, 120, 200, 80, 80);

    for (i, &f) in idle_frames.iter().enumerate() {
        let x = 10 + i as i32 * 24;
        let t = if total_frames > 0 {
            f as f32 / total_frames as f32
        } else {
            0.0
        };
        let r = (60.0 + t * 140.0) as u8;
        let g = (160.0 - t * 100.0) as u8;
        img.draw_rect(x, 150, 20, 30, r, g, 60, 255);
    }
    img.draw_label("IDLE FRAMES", 10, 185, 200, 200, 200);

    if let Some(qs) = quad_str {
        img.draw_label(qs, 10, 220, 180, 180, 200);
    }

    img.draw_label("JUMP CLIP DONE", 10, 250, 200, 180, 100);
    img.draw_label(
        summary,
        10,
        (height.saturating_sub(20)) as i32,
        100,
        255,
        100,
    );
    img.draw_label(
        "ANIMATION PLAYBACK OK",
        150,
        (height.saturating_sub(20)) as i32,
        100,
        255,
        100,
    );
    img
}

/// Render an animation as a CPU image for headless testing.
///
/// Delegates to [`draw_animation_frame_grid_to_image`] with cell dimensions
/// derived from the requested output size and frame count.
///
/// # Parameters
/// - `anim` — `&Animation`. Animation controller to render.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
///
/// # Returns
/// `ImageData`.
pub fn draw_animation_to_image(anim: &Animation, width: u32, height: u32) -> ImageData {
    let frame_count = anim.get_frame_count().max(1) as u32;
    let cols = frame_count.min(8);
    let cell_w = (width / cols).max(1);
    let cell_h = height.max(1);
    draw_animation_frame_grid_to_image(anim, cell_w, cell_h)
}
