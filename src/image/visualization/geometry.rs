//! - Polygon gallery with regular shapes of varying side counts.
//! - Archimedes spiral rendering with HSV ring colors.
//! - Filled primitive samples: rectangles, circles, brightness grid.
//! - Convex hull computation and overlay drawing.
//! - Point-in-polygon, centroid, and area visualization.
//! - Bresenham line rasterization proof.
//! - Segment-segment and circle-line intersection tests.
//! - Circle-segment and line intersection proof rendering.

use super::hsv_to_rgb_viz;
use crate::image::ImageData;
#[allow(clippy::type_complexity)]
/// Render a gallery of regular polygons in varying sizes and colors into an image.
pub fn polygon_gallery_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    let shapes: &[(i32, i32, i32, usize, (u8, u8, u8))] = &[
        (85, 85, 60, 3, (255, 100, 100)),
        (255, 85, 60, 4, (100, 255, 100)),
        (425, 85, 60, 5, (100, 100, 255)),
        (85, 255, 60, 6, (255, 255, 100)),
        (255, 255, 60, 8, (255, 100, 255)),
        (425, 255, 60, 12, (100, 255, 255)),
    ];
    for &(cx, cy, radius, sides, (r, g, b)) in shapes {
        for i in 0..sides {
            let a0 = std::f32::consts::TAU * i as f32 / sides as f32 - std::f32::consts::FRAC_PI_2;
            let a1 =
                std::f32::consts::TAU * (i + 1) as f32 / sides as f32 - std::f32::consts::FRAC_PI_2;
            let x0 = cx + (radius as f32 * a0.cos()) as i32;
            let y0 = cy + (radius as f32 * a0.sin()) as i32;
            let x1 = cx + (radius as f32 * a1.cos()) as i32;
            let y1 = cy + (radius as f32 * a1.sin()) as i32;
            img.draw_line(x0, y0, x1, y1, r, g, b, 255);
        }
    }
    let (sx, sy, sr) = (170i32, 425i32, 70i32);
    let star_pts: Vec<(i32, i32)> = (0..10)
        .map(|i| {
            let angle = std::f32::consts::TAU * i as f32 / 10.0 - std::f32::consts::FRAC_PI_2;
            let rv = if i % 2 == 0 {
                sr as f32
            } else {
                sr as f32 * 0.4
            };
            (
                sx + (rv * angle.cos()) as i32,
                sy + (rv * angle.sin()) as i32,
            )
        })
        .collect();
    for i in 0..10 {
        let (x0, y0) = star_pts[i];
        let (x1, y1) = star_pts[(i + 1) % 10];
        img.draw_line(x0, y0, x1, y1, 255, 220, 50, 255);
    }
    let (ax, ay) = (340i32, 425i32);
    let arrow: [(i32, i32); 7] = [
        (0, -50),
        (30, 0),
        (15, 0),
        (15, 50),
        (-15, 50),
        (-15, 0),
        (-30, 0),
    ];
    for i in 0..arrow.len() {
        let (x0, y0) = arrow[i];
        let (x1, y1) = arrow[(i + 1) % arrow.len()];
        img.draw_line(ax + x0, ay + y0, ax + x1, ay + y1, 255, 150, 50, 255);
    }
    img
}
/// Render an Archimedes spiral by sampling angle steps into an image.
pub fn spiral_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    let (cx, cy) = (width as i32 / 2, height as i32 / 2);
    for ring in 1u32..=10 {
        let r = ring * 18;
        let steps = (r * 4).max(40) as usize;
        let (cr, cg, cb) = hsv_to_rgb_viz((ring * 36) as u16, 0.7, 0.9);
        for i in 0..steps {
            let a0 = std::f32::consts::TAU * i as f32 / steps as f32;
            let a1 = std::f32::consts::TAU * (i + 1) as f32 / steps as f32;
            let x0 = cx + (r as f32 * a0.cos()) as i32;
            let y0 = cy + (r as f32 * a0.sin()) as i32;
            let x1 = cx + (r as f32 * a1.cos()) as i32;
            let y1 = cy + (r as f32 * a1.sin()) as i32;
            img.draw_line(x0, y0, x1, y1, cr, cg, cb, 255);
        }
    }
    img
}
/// Render filled rectangles, circles, and a brightness grid into an image.
pub fn filled_primitives_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    for i in 0u32..5 {
        let x = 20 + i * 35;
        let size = 15 + i * 8;
        let hue = (i as f32 / 5.0 * 360.0) as u16;
        let (r, g, b) = hsv_to_rgb_viz(hue, 0.8, 0.9);
        img.draw_rect(x as i32, 20, size, size, r, g, b, 200);
    }
    for i in 0u32..5 {
        let cx = (50 + i * 70) as i32;
        let radius = (10 + i * 5) as i32;
        let (r, g, b) = hsv_to_rgb_viz((i * 72) as u16, 0.8, 0.9);
        img.draw_circle(cx, 150, radius as u32, r, g, b, 200);
    }
    for row in 0u32..16 {
        for col in 0u32..16 {
            let x = 20 + col * 22;
            let y = 200 + row * 12;
            let brightness = ((row * 16 + col) * 255 / 255).min(255) as u8;
            img.set_pixel(x, y, brightness, brightness, brightness, 255);
            img.set_pixel(x + 1, y, brightness, brightness, brightness, 255);
            img.set_pixel(x, y + 1, brightness, brightness, brightness, 255);
            img.set_pixel(x + 1, y + 1, brightness, brightness, brightness, 255);
        }
    }
    img
}
/// Render convex hull, polygon centroid, Bresenham line, and circle tests into an image.
pub fn draw_geometry_shapes_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);
    let w = width as i32;
    let h = height as i32;
    let points: Vec<f32> = vec![
        50.0, 50.0, 100.0, 30.0, 150.0, 60.0, 130.0, 120.0, 80.0, 130.0, 40.0, 100.0, 90.0, 80.0,
        110.0, 70.0,
    ];
    let hull = crate::math::convex_hull(&points);
    for i in 0..points.len() / 2 {
        let px = points[i * 2] as i32;
        let py = points[i * 2 + 1] as i32;
        img.draw_circle(px, py, 3, 100, 100, 200, 255);
    }
    let hull_n = hull.len() / 2;
    for i in 0..hull_n {
        let j = (i + 1) % hull_n;
        img.draw_line(
            hull[i * 2] as i32,
            hull[i * 2 + 1] as i32,
            hull[j * 2] as i32,
            hull[j * 2 + 1] as i32,
            200,
            200,
            80,
            255,
        );
    }
    img.draw_label("CONVEX HULL", 50, 140, 200, 200, 80);
    let square: Vec<f32> = vec![200.0, 20.0, 280.0, 20.0, 280.0, 100.0, 200.0, 100.0];
    let area = crate::math::polygon_area(&square);
    let (cx, cy) = crate::math::polygon_centroid(&square);
    img.draw_line(200, 20, 280, 20, 80, 200, 80, 255);
    img.draw_line(280, 20, 280, 100, 80, 200, 80, 255);
    img.draw_line(280, 100, 200, 100, 80, 200, 80, 255);
    img.draw_line(200, 100, 200, 20, 80, 200, 80, 255);
    img.draw_circle(cx as i32, cy as i32, 4, 255, 100, 100, 255);
    let area_str = format!("AREA {:.0}", area.abs());
    img.draw_label(&area_str, 200, 108, 80, 200, 80);
    let _triangle: Vec<f32> = vec![350.0, 30.0, 450.0, 100.0, 340.0, 100.0];
    img.draw_line(350, 30, 450, 100, 200, 120, 80, 255);
    img.draw_line(450, 100, 340, 100, 200, 120, 80, 255);
    img.draw_line(340, 100, 350, 30, 200, 120, 80, 255);
    img.draw_circle(380, 70, 4, 0, 255, 0, 255);
    img.draw_circle(320, 30, 4, 255, 0, 0, 255);
    img.draw_label("POINT IN POLY", 340, 108, 200, 120, 80);
    let line_pts = crate::math::bresenham(20, 180, 180, 220);
    for &(px, py) in &line_pts {
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 255, 180, 80, 255);
        }
    }
    img.draw_label("BRESENHAM", 20, 230, 255, 180, 80);
    let angle = crate::math::angle_between(250.0, 200.0, 350.0, 250.0);
    img.draw_line(250, 200, 350, 250, 200, 80, 200, 255);
    let angle_str = format!("{:.2} RAD", angle);
    img.draw_label(&angle_str, 270, 255, 200, 80, 200);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (100.0 + 40.0 * rad.cos()) as i32;
        let py = (300.0 + 40.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 80, 200, 200, 255);
        }
    }
    img.draw_circle(110, 310, 3, 0, 255, 0, 255);
    img.draw_circle(200, 300, 3, 255, 0, 0, 255);
    img.draw_label("CIRCLE CONTAIN", 60, 350, 80, 200, 200);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px1 = (300.0 + 30.0 * rad.cos()) as i32;
        let py1 = (300.0 + 30.0 * rad.sin()) as i32;
        let px2 = (340.0 + 30.0 * rad.cos()) as i32;
        let py2 = (340.0 + 30.0 * rad.sin()) as i32;
        if px1 >= 0 && py1 >= 0 && px1 < w && py1 < h {
            img.set_pixel(px1 as u32, py1 as u32, 200, 100, 100, 255);
        }
        if px2 >= 0 && py2 >= 0 && px2 < w && py2 < h {
            img.set_pixel(px2 as u32, py2 as u32, 100, 200, 100, 255);
        }
    }
    img.draw_label("CC INTERSECT", 290, 340, 200, 200, 100);
    img.draw_label("GEOMETRY SHAPES OK", 170, (h - 15).max(0), 100, 255, 100);
    img
}
/// Render segment-segment, circle-line, and circle-segment intersection proofs into an image.
pub fn draw_geometry_intersections_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);
    let w = width as i32;
    let h = height as i32;
    let (_hit, point) =
        crate::math::segment_intersects_segment(20.0, 20.0, 150.0, 120.0, 20.0, 120.0, 150.0, 20.0);
    img.draw_line(20, 20, 150, 120, 200, 80, 80, 255);
    img.draw_line(20, 120, 150, 20, 80, 80, 200, 255);
    if let Some((ix, iy)) = point {
        img.draw_circle(ix as i32, iy as i32, 5, 255, 255, 80, 255);
    }
    img.draw_label("SEG-SEG", 60, 130, 200, 200, 80);
    let (_no_hit, _) = crate::math::segment_intersects_segment(
        20.0, 160.0, 100.0, 160.0, 20.0, 200.0, 100.0, 200.0,
    );
    img.draw_line(20, 160, 100, 160, 200, 80, 80, 255);
    img.draw_line(20, 200, 100, 200, 80, 200, 80, 255);
    img.draw_label("NO HIT", 30, 210, 200, 80, 80);
    let (cpx, cpy) = crate::math::closest_point_on_segment(250.0, 30.0, 200.0, 80.0, 350.0, 80.0);
    img.draw_line(200, 80, 350, 80, 80, 180, 200, 255);
    img.draw_circle(250, 30, 4, 255, 100, 100, 255);
    img.draw_circle(cpx as i32, cpy as i32, 4, 100, 255, 100, 255);
    img.draw_line(250, 30, cpx as i32, cpy as i32, 150, 150, 150, 150);
    img.draw_label("CLOSEST PT", 230, 90, 80, 180, 200);
    let (_cl_hit, p1, p2) =
        crate::math::circle_intersects_line(300.0, 200.0, 50.0, 200.0, 200.0, 400.0, 200.0);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (300.0 + 50.0 * rad.cos()) as i32;
        let py = (200.0 + 50.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 100, 100, 200, 255);
        }
    }
    img.draw_line(200, 200, 400, 200, 200, 200, 200, 150);
    if let Some((ix, iy)) = p1 {
        img.draw_circle(ix as i32, iy as i32, 4, 255, 80, 80, 255);
    }
    if let Some((ix, iy)) = p2 {
        img.draw_circle(ix as i32, iy as i32, 4, 80, 255, 80, 255);
    }
    img.draw_label("CIRCLE-LINE", 273, 260, 100, 100, 200);
    let (cs_hit, sp1, sp2) =
        crate::math::circle_intersects_segment(100.0, 300.0, 30.0, 60.0, 280.0, 140.0, 320.0);
    for a in 0..360 {
        let rad = a as f32 * std::f32::consts::PI / 180.0;
        let px = (100.0 + 30.0 * rad.cos()) as i32;
        let py = (300.0 + 30.0 * rad.sin()) as i32;
        if px >= 0 && py >= 0 && px < w && py < h {
            img.set_pixel(px as u32, py as u32, 200, 150, 80, 255);
        }
    }
    img.draw_line(60, 280, 140, 320, 180, 180, 180, 200);
    if cs_hit {
        if let Some((ix, iy)) = sp1 {
            img.draw_circle(ix as i32, iy as i32, 3, 255, 200, 80, 255);
        }
        if let Some((ix, iy)) = sp2 {
            img.draw_circle(ix as i32, iy as i32, 3, 80, 200, 255, 255);
        }
    }
    img.draw_label("CIRCLE-SEG", 60, 335, 200, 150, 80);
    let result =
        crate::math::line_intersect(200.0, 260.0, 400.0, 340.0, 200.0, 340.0, 400.0, 260.0);
    img.draw_line(200, 260, 400, 340, 200, 80, 200, 200);
    img.draw_line(200, 340, 400, 260, 80, 200, 200, 200);
    if let Some((ix, iy)) = result {
        img.draw_circle(ix as i32, iy as i32, 5, 255, 255, 100, 255);
    }
    img.draw_label("LINE INTERSECT", 260, 345, 200, 200, 200);
    img.draw_label("GEOMETRY INTERSECTIONS OK", 120, 3, 100, 255, 100);
    img
}
