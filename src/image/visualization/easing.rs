//! - Easing curve gallery rendered in a labeled grid layout.
//! - Overlaid easing comparison chart with colored traces.
//! - Bézier curve rendering with control-point markers.
//! - Advanced Bézier demo with derivatives, segments, and edit operations.
//! - Grid background and axis rendering for chart context.

use crate::image::ImageData;
/// Render a gallery of easing curves in a grid into an image.
pub fn easing_gallery_to_image(
    curves: &[(&str, &dyn Fn(f32) -> f32)],
    chart_w: u32,
    chart_h: u32,
) -> ImageData {
    let cols = 4u32;
    let rows = (curves.len() as u32).div_ceil(cols);
    let pad = 10u32;
    let img_w = cols * (chart_w + pad) + pad;
    let img_h = rows * (chart_h + pad + 16) + pad;
    let mut img = ImageData::new(img_w, img_h);
    img.fill(20, 20, 30, 255);
    for (idx, (_name, func)) in curves.iter().enumerate() {
        let col = (idx as u32) % cols;
        let row = (idx as u32) / cols;
        let ox = pad + col * (chart_w + pad);
        let oy = pad + row * (chart_h + pad + 16) + 14;
        img.draw_rect(ox as i32, oy as i32, chart_w, chart_h, 35, 35, 50, 255);
        let mut prev_x = 0i32;
        let mut prev_y = 0i32;
        for step in 0..=100 {
            let t = step as f32 / 100.0;
            let v = func(t);
            let px = ox as i32 + (t * (chart_w - 1) as f32) as i32;
            let py = oy as i32 + chart_h as i32
                - 1
                - (v.clamp(0.0, 1.5) / 1.5 * (chart_h - 1) as f32) as i32;
            if step > 0 {
                img.draw_line(prev_x, prev_y, px, py, 100, 220, 160, 255);
            }
            prev_x = px;
            prev_y = py;
        }
    }
    img
}
#[allow(clippy::type_complexity)]
/// Render multiple easing curves overlaid on a single chart into an image.
pub fn easing_comparison_to_image(
    curves: &[(&str, (u8, u8, u8), fn(f32) -> f32)],
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(20, 20, 30, 255);
    let step = 32;
    for i in (0..width).step_by(step) {
        img.draw_line(i as i32, 0, i as i32, height as i32 - 1, 35, 35, 45, 255);
    }
    for i in (0..height).step_by(step) {
        img.draw_line(0, i as i32, width as i32 - 1, i as i32, 35, 35, 45, 255);
    }
    for (_name, (r, g, b), func) in curves {
        let mut prev = (0i32, height as i32 - 1);
        for step in 1..=200 {
            let t = step as f32 / 200.0;
            let v = func(t);
            let px = (t * (width - 1) as f32) as i32;
            let py = (height - 1) as i32 - (v.clamp(-0.2, 1.3) * 170.0 + 20.0) as i32;
            img.draw_line(prev.0, prev.1, px, py, *r, *g, *b, 220);
            prev = (px, py);
        }
    }
    img
}
#[allow(clippy::type_complexity)]
/// Render a set of Bezier curves with control points into an image.
pub fn bezier_curves_to_image(
    curves: &[(Vec<crate::math::vec2::Vec2>, (u8, u8, u8))],
    width: u32,
    height: u32,
) -> ImageData {
    use crate::math::bezier::BezierCurve;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    for (pts, (cr, cg, cb)) in curves {
        let bez = BezierCurve::new(pts.clone());
        for i in 0..pts.len().saturating_sub(1) {
            img.draw_line(
                pts[i].x as i32,
                pts[i].y as i32,
                pts[i + 1].x as i32,
                pts[i + 1].y as i32,
                cr / 3,
                cg / 3,
                cb / 3,
                100,
            );
        }
        let steps = 100;
        for i in 0..steps {
            let t0 = i as f32 / steps as f32;
            let t1 = (i + 1) as f32 / steps as f32;
            let pt0 = bez.evaluate(t0);
            let pt1 = bez.evaluate(t1);
            img.draw_line(
                pt0.x as i32,
                pt0.y as i32,
                pt1.x as i32,
                pt1.y as i32,
                *cr,
                *cg,
                *cb,
                255,
            );
        }
        for pt in pts {
            img.draw_circle(pt.x as i32, pt.y as i32, 4, *cr, *cg, *cb, 255);
        }
    }
    img
}
/// Render an advanced Bezier demo with derivatives, segments, and edit operations into an image.
pub fn draw_bezier_advanced_to_image(width: u32, height: u32) -> ImageData {
    use crate::math::bezier::BezierCurve;
    use crate::math::vec2::Vec2;
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);
    let curve = BezierCurve::new(vec![
        Vec2::new(50.0, 200.0),
        Vec2::new(150.0, 50.0),
        Vec2::new(300.0, 50.0),
        Vec2::new(400.0, 200.0),
    ]);
    let pts = curve.render(60);
    for i in 1..pts.len() {
        img.draw_line(
            pts[i - 1].x as i32,
            pts[i - 1].y as i32,
            pts[i].x as i32,
            pts[i].y as i32,
            200,
            120,
            80,
            255,
        );
    }
    let deriv = curve.get_derivative();
    let dpts = deriv.render(40);
    for i in 1..dpts.len() {
        let x1 = 50 + (dpts[i - 1].x * 0.3) as i32;
        let y1 = 350 + (dpts[i - 1].y * 0.3) as i32;
        let x2 = 50 + (dpts[i].x * 0.3) as i32;
        let y2 = 350 + (dpts[i].y * 0.3) as i32;
        if x1 >= 0
            && y1 >= 0
            && x2 < width as i32
            && y2 < height as i32
            && x1 < width as i32
            && y1 < height as i32
        {
            img.draw_line(x1, y1, x2, y2, 80, 200, 200, 200);
        }
    }
    img.draw_label("DERIVATIVE", 10, 330, 80, 200, 200);
    let seg_pts = curve.render_segment(0.2, 0.8, 30);
    for i in 1..seg_pts.len() {
        img.draw_line(
            seg_pts[i - 1].x as i32,
            (seg_pts[i - 1].y + 5.0) as i32,
            seg_pts[i].x as i32,
            (seg_pts[i].y + 5.0) as i32,
            255,
            255,
            80,
            255,
        );
    }
    img.draw_label("SEGMENT 0.2-0.8", 150, 210, 255, 255, 80);
    let mut editable = BezierCurve::new(vec![
        Vec2::new(300.0, 280.0),
        Vec2::new(350.0, 230.0),
        Vec2::new(450.0, 280.0),
    ]);
    for i in 0..editable.get_control_point_count() {
        if let Some(cp) = editable.get_control_point(i) {
            img.draw_circle(cp.x as i32, cp.y as i32, 4, 200, 200, 200, 255);
        }
    }
    let orig_pts = editable.render(20);
    for i in 1..orig_pts.len() {
        img.draw_line(
            orig_pts[i - 1].x as i32,
            orig_pts[i - 1].y as i32,
            orig_pts[i].x as i32,
            orig_pts[i].y as i32,
            150,
            150,
            150,
            200,
        );
    }
    editable.set_control_point(1, Vec2::new(350.0, 200.0));
    editable.insert_control_point(Vec2::new(400.0, 250.0), Some(2));
    let edited_pts = editable.render(20);
    for i in 1..edited_pts.len() {
        img.draw_line(
            edited_pts[i - 1].x as i32,
            edited_pts[i - 1].y as i32,
            edited_pts[i].x as i32,
            edited_pts[i].y as i32,
            80,
            200,
            80,
            255,
        );
    }
    editable.remove_control_point(3);
    let mut transform_curve = BezierCurve::new(vec![
        Vec2::new(300.0, 320.0),
        Vec2::new(350.0, 300.0),
        Vec2::new(400.0, 320.0),
    ]);
    let t_pts = transform_curve.render(15);
    for i in 1..t_pts.len() {
        img.draw_line(
            t_pts[i - 1].x as i32,
            t_pts[i - 1].y as i32,
            t_pts[i].x as i32,
            t_pts[i].y as i32,
            200,
            80,
            80,
            180,
        );
    }
    transform_curve.translate(0.0, 20.0);
    let tt_pts = transform_curve.render(15);
    for i in 1..tt_pts.len() {
        img.draw_line(
            tt_pts[i - 1].x as i32,
            tt_pts[i - 1].y as i32,
            tt_pts[i].x as i32,
            tt_pts[i].y as i32,
            80,
            80,
            200,
            180,
        );
    }
    let len = curve.length();
    let len_str = format!("LEN {:.0}", len);
    img.draw_label(&len_str, 300, 215, 200, 200, 200);
    let (ix, iy) = curve.get_interpolated_position(0.5);
    img.draw_circle(ix as i32, iy as i32, 5, 255, 100, 255, 255);
    let angle = curve.get_interpolated_angle(0.5);
    let angle_str = format!("A {:.2}", angle);
    img.draw_label(&angle_str, ix as i32 + 8, iy as i32, 255, 100, 255);
    img.draw_label(
        "BEZIER ADVANCED OK",
        150,
        (height - 15) as i32,
        100,
        255,
        100,
    );
    img
}
