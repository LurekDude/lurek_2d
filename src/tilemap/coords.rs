//! Tile-space coordinate conversion helpers: isometric screen↔tile and hex grid math.
//! Owns all standalone conversion, neighbor, distance, ring, spiral, and rotate functions.
//! Does not own tile storage or rendering; callers apply results to their own data.
//! Depends on `math`.

use crate::math::Vec2;
use std::f32::consts::PI;

/// Convert tile coordinates `(tx, ty)` to isometric screen position for a tile of `tile_w`×`tile_h`.
pub fn to_screen_iso(tx: f32, ty: f32, tile_w: f32, tile_h: f32) -> Vec2 {
    Vec2::new((tx - ty) * tile_w / 2.0, (tx + ty) * tile_h / 2.0)
}
/// Convert isometric screen position `(sx, sy)` back to tile coordinates for a tile of `tile_w`×`tile_h`.
pub fn from_screen_iso(sx: f32, sy: f32, tile_w: f32, tile_h: f32) -> Vec2 {
    let tx = (sx / tile_w * 2.0 + sy / tile_h * 2.0) / 2.0;
    let ty = (sy / tile_h * 2.0 - sx / tile_w * 2.0) / 2.0;
    Vec2::new(tx, ty)
}
/// Rotate `direction` (1–4, cardinal) by `steps` clockwise; wraps within the 4-direction cycle.
pub fn iso_rotate(direction: i32, steps: i32) -> i32 {
    (direction - 1 + steps).rem_euclid(4) + 1
}
/// Return the name string for `direction` (1=south, 2=west, 3=north, 4=east); returns `"unknown"` for any other value.
pub fn iso_direction_name(direction: i32) -> &'static str {
    match direction {
        1 => "south",
        2 => "west",
        3 => "north",
        4 => "east",
        _ => "unknown",
    }
}
/// Convert a radian `angle` to the nearest of the 4 isometric cardinal directions (1–4).
pub fn iso_direction_from_angle(angle: f32) -> i32 {
    let a = ((angle % (2.0 * PI)) + 2.0 * PI) % (2.0 * PI);
    if !(PI / 4.0..7.0 * PI / 4.0).contains(&a) {
        4
    } else if a < 3.0 * PI / 4.0 {
        1
    } else if a < 5.0 * PI / 4.0 {
        2
    } else {
        3
    }
}
/// Convert hex axial coordinates `(q, r)` to flat-top screen position for a hex of the given `size`.
pub fn to_screen_hex(q: i32, r: i32, size: f32) -> Vec2 {
    let x = size * 3.0_f32.sqrt() * (q as f32 + r as f32 / 2.0);
    let y = size * 1.5 * r as f32;
    Vec2::new(x, y)
}
/// Convert screen position `(sx, sy)` to hex axial coordinates for a hex of the given `size`.
pub fn from_screen_hex(sx: f32, sy: f32, size: f32) -> (i32, i32) {
    let q = (sx * 3.0_f32.sqrt() / 3.0 - sy / 3.0) / size;
    let r = sy * 2.0 / 3.0 / size;
    hex_round(q, r)
}
/// Return the 6 axial-coordinate neighbors of hex `(q, r)` in ring order.
pub fn hex_neighbors(q: i32, r: i32) -> [(i32, i32); 6] {
    [
        (q + 1, r),
        (q + 1, r - 1),
        (q, r - 1),
        (q - 1, r),
        (q - 1, r + 1),
        (q, r + 1),
    ]
}
/// Return the hex-grid Chebyshev distance between `(q1,r1)` and `(q2,r2)`.
pub fn hex_distance(q1: i32, r1: i32, q2: i32, r2: i32) -> i32 {
    let s1 = -q1 - r1;
    let s2 = -q2 - r2;
    let dq = (q1 - q2).abs();
    let dr = (r1 - r2).abs();
    let ds = (s1 - s2).abs();
    dq.max(dr).max(ds)
}
/// Round fractional axial coordinates `(q, r)` to the nearest integer hex.
pub fn hex_round(q: f32, r: f32) -> (i32, i32) {
    let s = -q - r;
    let mut rq = q.round();
    let mut rr = r.round();
    let rs = s.round();
    let dq = (rq - q).abs();
    let dr = (rr - r).abs();
    let ds = (rs - s).abs();
    if dq > dr && dq > ds {
        rq = -rr - rs;
    } else if dr > ds {
        rr = -rq - rs;
    }
    (rq as i32, rr as i32)
}
/// Return all hex cells on a straight line from `(q1,r1)` to `(q2,r2)` inclusive.
pub fn hex_line(q1: i32, r1: i32, q2: i32, r2: i32) -> Vec<(i32, i32)> {
    let n = hex_distance(q1, r1, q2, r2);
    if n == 0 {
        return vec![(q1, r1)];
    }
    let mut results = Vec::with_capacity(n as usize + 1);
    let fq1 = q1 as f32;
    let fr1 = r1 as f32;
    let fq2 = q2 as f32;
    let fr2 = r2 as f32;
    for i in 0..=n {
        let t = i as f32 / n as f32;
        let q = fq1 + (fq2 - fq1) * t;
        let r = fr1 + (fr2 - fr1) * t;
        results.push(hex_round(q, r));
    }
    results
}
/// Return all cells on the ring of the given `radius` around `(q, r)`.
pub fn hex_ring(q: i32, r: i32, radius: i32) -> Vec<(i32, i32)> {
    if radius == 0 {
        return vec![(q, r)];
    }
    let directions: [(i32, i32); 6] = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)];
    let mut results = Vec::with_capacity(6 * radius as usize);
    let mut hq = q + radius * directions[4].0;
    let mut hr = r + radius * directions[4].1;
    for dir in &directions {
        for _ in 0..radius {
            results.push((hq, hr));
            hq += dir.0;
            hr += dir.1;
        }
    }
    results
}
/// Return all cells in expanding rings from `(q, r)` out to `radius`, center first.
pub fn hex_spiral(q: i32, r: i32, radius: i32) -> Vec<(i32, i32)> {
    let mut results = vec![(q, r)];
    for k in 1..=radius {
        results.extend(hex_ring(q, r, k));
    }
    results
}
/// Return all hex cells within `radius` steps of `(q, r)`, including the center.
pub fn hex_area(q: i32, r: i32, radius: i32) -> Vec<(i32, i32)> {
    let mut results = Vec::new();
    for dq in -radius..=radius {
        let r_min = (-radius).max(-dq - radius);
        let r_max = radius.min(-dq + radius);
        for dr in r_min..=r_max {
            results.push((q + dq, r + dr));
        }
    }
    results
}
/// Rotate hex `(q, r)` around `(center_q, center_r)` by `steps` of 60° clockwise.
pub fn hex_rotate(q: i32, r: i32, center_q: i32, center_r: i32, steps: i32) -> (i32, i32) {
    let mut cq = q - center_q;
    let mut cr = r - center_r;
    let mut cs = -cq - cr;
    let effective = steps.rem_euclid(6);
    for _ in 0..effective {
        let nq = -cr;
        let nr = -cs;
        let ns = -cq;
        cq = nq;
        cr = nr;
        cs = ns;
    }
    let _ = cs;
    (cq + center_q, cr + center_r)
}
/// Reflect hex `(q, r)` through `(center_q, center_r)` across the named cube axis (`"q"`, `"r"`, or `"s"`).
pub fn hex_reflect(q: i32, r: i32, center_q: i32, center_r: i32, axis: &str) -> (i32, i32) {
    let cq = q - center_q;
    let cr = r - center_r;
    let cs = -cq - cr;
    let (nq, nr) = match axis {
        "q" => (cq, cs),
        "r" => (cs, cr),
        "s" => (cr, cq),
        _ => (cq, cr),
    };
    (nq + center_q, nr + center_r)
}
