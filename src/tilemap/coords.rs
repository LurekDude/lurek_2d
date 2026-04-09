//! Coordinate conversion functions for isometric and hexagonal tile grids.
//!
//! This module is part of Lurek2D's `tilemap` subsystem and provides the implementation
//! details for coords-related operations and data management.
//! Primary functions: `to_screen_iso()`, `from_screen_iso()`, `iso_rotate()`, `iso_direction_name()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::f32::consts::PI;

use crate::math::Vec2;

// ---------------------------------------------------------------------------
// Isometric (diamond projection)
// ---------------------------------------------------------------------------

/// Converts tile coordinates to screen position using diamond isometric projection.
///
/// # Parameters
/// - `tx` — `f32`.
/// - `ty` — `f32`.
/// - `tile_w` — `f32`.
/// - `tile_h` — `f32`.
///
/// # Returns
/// `Vec2`.
///
/// - `screen.x = (tx - ty) * tile_w / 2`
/// - `screen.y = (tx + ty) * tile_h / 2`
pub fn to_screen_iso(tx: f32, ty: f32, tile_w: f32, tile_h: f32) -> Vec2 {
    Vec2::new((tx - ty) * tile_w / 2.0, (tx + ty) * tile_h / 2.0)
}

/// Converts screen position back to tile coordinates for diamond isometric projection.
///
/// # Parameters
/// - `sx` — `f32`.
/// - `sy` — `f32`.
/// - `tile_w` — `f32`.
/// - `tile_h` — `f32`.
///
/// # Returns
/// `Vec2`.
pub fn from_screen_iso(sx: f32, sy: f32, tile_w: f32, tile_h: f32) -> Vec2 {
    let tx = (sx / tile_w * 2.0 + sy / tile_h * 2.0) / 2.0;
    let ty = (sy / tile_h * 2.0 - sx / tile_w * 2.0) / 2.0;
    Vec2::new(tx, ty)
}

/// Rotates an isometric direction (1–4) clockwise by `steps`.
///
/// # Parameters
/// - `direction` — `i32`.
/// - `steps` — `i32`.
///
/// # Returns
/// `i32`.
///
/// Directions: 1=south, 2=west, 3=north, 4=east.
pub fn iso_rotate(direction: i32, steps: i32) -> i32 {
    (direction - 1 + steps).rem_euclid(4) + 1
}

/// Returns the name of an isometric direction (1–4).
///
/// # Parameters
/// - `direction` — `i32`.
///
/// # Returns
/// `&'static str`.
///
/// Returns `"unknown"` for out-of-range values.
pub fn iso_direction_name(direction: i32) -> &'static str {
    match direction {
        1 => "south",
        2 => "west",
        3 => "north",
        4 => "east",
        _ => "unknown",
    }
}

/// Snaps an angle (in radians) to the nearest isometric direction (1–4).
///
/// # Parameters
/// - `angle` — `f32`.
///
/// # Returns
/// `i32`.
///
/// - south (down, π/2) → 1
/// - west (left, π) → 2
/// - north (up, -π/2) → 3
/// - east (right, 0) → 4
pub fn iso_direction_from_angle(angle: f32) -> i32 {
    // Normalize angle to [0, 2π)
    let a = ((angle % (2.0 * PI)) + 2.0 * PI) % (2.0 * PI);
    // Quadrant snap: east=[−π/4..π/4), south=[π/4..3π/4), west=[3π/4..5π/4), north=[5π/4..7π/4)
    if !(PI / 4.0..7.0 * PI / 4.0).contains(&a) {
        4 // east
    } else if a < 3.0 * PI / 4.0 {
        1 // south
    } else if a < 5.0 * PI / 4.0 {
        2 // west
    } else {
        3 // north
    }
}

// ---------------------------------------------------------------------------
// Hexagonal (axial coordinates, pointy-top)
// ---------------------------------------------------------------------------

/// Converts axial hex coordinates to screen position (pointy-top layout).
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
/// - `size` — `f32`.
///
/// # Returns
/// `Vec2`.
///
/// - `x = size * √3 * (q + r/2)`
/// - `y = size * 3/2 * r`
pub fn to_screen_hex(q: i32, r: i32, size: f32) -> Vec2 {
    let x = size * 3.0_f32.sqrt() * (q as f32 + r as f32 / 2.0);
    let y = size * 1.5 * r as f32;
    Vec2::new(x, y)
}

/// Converts screen position back to axial hex coordinates (pointy-top layout).
///
/// # Parameters
/// - `sx` — `f32`.
/// - `sy` — `f32`.
/// - `size` — `f32`.
///
/// # Returns
/// `(i32, i32)`.
///
/// Uses fractional axial reverse, then rounds with [`hex_round`].
pub fn from_screen_hex(sx: f32, sy: f32, size: f32) -> (i32, i32) {
    let q = (sx * 3.0_f32.sqrt() / 3.0 - sy / 3.0) / size;
    let r = sy * 2.0 / 3.0 / size;
    hex_round(q, r)
}

/// Returns the six axial neighbor offsets for pointy-top hexagonal grids.
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
///
/// # Returns
/// `[(i32, i32); 6]`.
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

/// Returns the hex distance between two axial coordinates using cube distance.
///
/// # Parameters
/// - `q1` — `i32`.
/// - `r1` — `i32`.
/// - `q2` — `i32`.
/// - `r2` — `i32`.
///
/// # Returns
/// `i32`.
pub fn hex_distance(q1: i32, r1: i32, q2: i32, r2: i32) -> i32 {
    let s1 = -q1 - r1;
    let s2 = -q2 - r2;
    let dq = (q1 - q2).abs();
    let dr = (r1 - r2).abs();
    let ds = (s1 - s2).abs();
    dq.max(dr).max(ds)
}

/// Rounds fractional axial coordinates to the nearest hex cell using cube rounding.
///
/// # Parameters
/// - `q` — `f32`.
/// - `r` — `f32`.
///
/// # Returns
/// `(i32, i32)`.
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
    // else: rs gets corrected, but we derive from q,r so it's implicit

    (rq as i32, rr as i32)
}

/// Returns all hex cells along a line between two axial coordinates.
///
/// # Parameters
/// - `q1` — `i32`.
/// - `r1` — `i32`.
/// - `q2` — `i32`.
/// - `r2` — `i32`.
///
/// # Returns
/// `Vec<(i32, i32)>`.
///
/// Uses linear interpolation in cube space with [`hex_round`] at each step.
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

/// Returns all cells at exactly `radius` distance from `(q, r)`.
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
/// - `radius` — `i32`.
///
/// # Returns
/// `Vec<(i32, i32)>`.
///
/// For radius 0, returns just the center cell.
pub fn hex_ring(q: i32, r: i32, radius: i32) -> Vec<(i32, i32)> {
    if radius == 0 {
        return vec![(q, r)];
    }
    let directions: [(i32, i32); 6] = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)];
    let mut results = Vec::with_capacity(6 * radius as usize);
    // Start at the "top" of the ring
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

/// Returns all hex cells from center outward to `radius`, ring by ring.
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
/// - `radius` — `i32`.
///
/// # Returns
/// `Vec<(i32, i32)>`.
pub fn hex_spiral(q: i32, r: i32, radius: i32) -> Vec<(i32, i32)> {
    let mut results = vec![(q, r)];
    for k in 1..=radius {
        results.extend(hex_ring(q, r, k));
    }
    results
}

/// Returns all hex cells within `radius` distance (filled hex circle).
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
/// - `radius` — `i32`.
///
/// # Returns
/// `Vec<(i32, i32)>`.
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

/// Rotates hex coordinates `(q, r)` around `(center_q, center_r)` by `steps × 60°` clockwise.
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
/// - `center_q` — `i32`.
/// - `center_r` — `i32`.
/// - `steps` — `i32`.
///
/// # Returns
/// `(i32, i32)`.
///
/// Uses cube coordinate rotation.
pub fn hex_rotate(q: i32, r: i32, center_q: i32, center_r: i32, steps: i32) -> (i32, i32) {
    // Convert to cube, offset from center
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
    let _ = cs; // s is derived from q and r

    (cq + center_q, cr + center_r)
}

/// Reflects hex coordinates across an axis through the center.
///
/// # Parameters
/// - `q` — `i32`.
/// - `r` — `i32`.
/// - `center_q` — `i32`.
/// - `center_r` — `i32`.
/// - `axis` — `&str`.
///
/// # Returns
/// `(i32, i32)`.
///
/// Axis must be `"q"`, `"r"`, or `"s"`. Uses cube coordinate reflection.
pub fn hex_reflect(q: i32, r: i32, center_q: i32, center_r: i32, axis: &str) -> (i32, i32) {
    let cq = q - center_q;
    let cr = r - center_r;
    let cs = -cq - cr;

    let (nq, nr) = match axis {
        "q" => (cq, cs), // swap r and s, keep q
        "r" => (cs, cr), // swap q and s, keep r
        "s" => (cr, cq), // swap q and r, keep s
        _ => (cq, cr),   // identity for unknown axis
    };

    (nq + center_q, nr + center_r)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn iso_roundtrip() {
        let tile_w = 64.0;
        let tile_h = 32.0;
        let screen = to_screen_iso(3.0, 2.0, tile_w, tile_h);
        let back = from_screen_iso(screen.x, screen.y, tile_w, tile_h);
        assert!((back.x - 3.0).abs() < 1e-5);
        assert!((back.y - 2.0).abs() < 1e-5);
    }

    #[test]
    fn iso_rotate_wraps() {
        assert_eq!(iso_rotate(1, 0), 1);
        assert_eq!(iso_rotate(1, 1), 2);
        assert_eq!(iso_rotate(1, 4), 1);
        assert_eq!(iso_rotate(4, 1), 1);
        assert_eq!(iso_rotate(3, -1), 2);
    }

    #[test]
    fn iso_direction_name_all_four() {
        assert_eq!(iso_direction_name(1), "south");
        assert_eq!(iso_direction_name(2), "west");
        assert_eq!(iso_direction_name(3), "north");
        assert_eq!(iso_direction_name(4), "east");
        assert_eq!(iso_direction_name(0), "unknown");
    }

    #[test]
    fn iso_direction_from_angle_cardinals() {
        assert_eq!(iso_direction_from_angle(0.0), 4); // east
        assert_eq!(iso_direction_from_angle(PI / 2.0), 1); // south
        assert_eq!(iso_direction_from_angle(PI), 2); // west
        assert_eq!(iso_direction_from_angle(-PI / 2.0), 3); // north
    }

    #[test]
    fn hex_distance_cases() {
        assert_eq!(hex_distance(0, 0, 0, 0), 0);
        assert_eq!(hex_distance(0, 0, 1, 0), 1);
        assert_eq!(hex_distance(0, 0, 2, -1), 2);
        assert_eq!(hex_distance(0, 0, 3, -3), 3);
    }

    #[test]
    fn hex_round_exact() {
        assert_eq!(hex_round(1.0, 2.0), (1, 2));
        assert_eq!(hex_round(0.1, -0.1), (0, 0));
        assert_eq!(hex_round(0.9, 0.1), (1, 0));
    }

    #[test]
    fn hex_neighbors_count() {
        let n = hex_neighbors(0, 0);
        assert_eq!(n.len(), 6);
        // All should be distance 1 from origin
        for (q, r) in &n {
            assert_eq!(hex_distance(0, 0, *q, *r), 1);
        }
    }

    #[test]
    fn hex_line_length() {
        let line = hex_line(0, 0, 3, 0);
        assert_eq!(line.len(), 4); // 0,1,2,3 → 4 cells
        assert_eq!(line[0], (0, 0));
        assert_eq!(line[3], (3, 0));
    }

    #[test]
    fn hex_ring_radius_0_returns_center() {
        let ring = hex_ring(2, 3, 0);
        assert_eq!(ring, vec![(2, 3)]);
    }

    #[test]
    fn hex_ring_radius_1_returns_6() {
        let ring = hex_ring(0, 0, 1);
        assert_eq!(ring.len(), 6);
        for (q, r) in &ring {
            assert_eq!(hex_distance(0, 0, *q, *r), 1);
        }
    }

    #[test]
    fn hex_ring_radius_2_returns_12() {
        let ring = hex_ring(0, 0, 2);
        assert_eq!(ring.len(), 12);
        for (q, r) in &ring {
            assert_eq!(hex_distance(0, 0, *q, *r), 2);
        }
    }

    #[test]
    fn hex_spiral_includes_center() {
        let spiral = hex_spiral(1, 1, 1);
        assert!(spiral.contains(&(1, 1)));
        assert_eq!(spiral.len(), 7); // 1 center + 6 ring-1
    }

    #[test]
    fn hex_area_superset_of_ring() {
        let area = hex_area(0, 0, 2);
        let ring = hex_ring(0, 0, 2);
        for cell in &ring {
            assert!(area.contains(cell));
        }
        // Area of radius 2: 1 + 6 + 12 = 19
        assert_eq!(area.len(), 19);
    }

    #[test]
    fn hex_rotate_60_degrees() {
        // Rotate (1,0) around origin by 1 step → (0,1)
        let (rq, rr) = hex_rotate(1, 0, 0, 0, 1);
        assert_eq!((rq, rr), (0, 1));
    }

    #[test]
    fn hex_rotate_full_circle() {
        let (rq, rr) = hex_rotate(2, -1, 0, 0, 6);
        assert_eq!((rq, rr), (2, -1));
    }

    #[test]
    fn hex_reflect_q_axis() {
        let (rq, rr) = hex_reflect(1, 2, 0, 0, "q");
        // cube: (1, 2, -3) → reflect q-axis: keep q, swap r↔s → (1, -3, 2) → axial (1, -3)
        assert_eq!((rq, rr), (1, -3));
    }

    #[test]
    fn hex_screen_roundtrip() {
        let size = 20.0;
        let screen = to_screen_hex(3, -2, size);
        let (rq, rr) = from_screen_hex(screen.x, screen.y, size);
        assert_eq!((rq, rr), (3, -2));
    }
}
