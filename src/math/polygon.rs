//! Polygon utilities: ear-clipping triangulation and convexity testing.
//!
//! This module is part of Lurek2D's `math` subsystem and provides the implementation
//! details for polygon-related operations and data management.
//! Primary functions: `triangulate()`, `is_convex()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::math::vec2::Vec2;

/// Triangulate a simple polygon using the ear-clipping algorithm.
///
/// # Parameters
/// - `polygon` — slice of `Vec2` vertices forming a simple (non-self-intersecting) polygon;
///   must have at least 3 vertices
///
/// # Returns
/// `Ok(triangles)` — a `Vec` of `[Vec2; 3]` triangle triples covering the polygon area.
/// `Err(String)` — if triangulation fails (e.g. self-intersecting or degenerate input).
pub fn triangulate(polygon: &[Vec2]) -> Result<Vec<[Vec2; 3]>, String> {
    let n = polygon.len();
    if n < 3 {
        return Err("Polygon needs at least 3 vertices".to_string());
    }
    if n == 3 {
        return Ok(vec![[polygon[0], polygon[1], polygon[2]]]);
    }

    // Ensure counter-clockwise winding
    let area = signed_area(polygon);
    let ccw: Vec<Vec2> = if area < 0.0 {
        polygon.iter().rev().copied().collect()
    } else {
        polygon.to_vec()
    };

    let mut indices: Vec<usize> = (0..n).collect();
    let mut triangles = Vec::new();

    while indices.len() > 3 {
        let mut ear_found = false;
        let len = indices.len();
        for i in 0..len {
            let prev = (i + len - 1) % len;
            let next = (i + 1) % len;

            let pi = indices[prev];
            let ci = indices[i];
            let ni = indices[next];

            if is_ear(&ccw, &indices, pi, ci, ni) {
                triangles.push([ccw[pi], ccw[ci], ccw[ni]]);
                indices.remove(i);
                ear_found = true;
                break;
            }
        }
        if !ear_found {
            return Err("Failed to triangulate: polygon may be self-intersecting".to_string());
        }
    }

    if indices.len() == 3 {
        triangles.push([ccw[indices[0]], ccw[indices[1]], ccw[indices[2]]]);
    }

    Ok(triangles)
}

/// Check if a polygon is convex. This accessor incurs no allocation; call it freely in hot paths.
///
/// Uses cross-product sign consistency at each vertex to determine convexity.
///
/// # Parameters
/// - `polygon` — slice of `Vec2` vertices
///
/// # Returns
/// `true` if the polygon is convex; `false` if concave, self-intersecting, or fewer than 3 vertices.
pub fn is_convex(polygon: &[Vec2]) -> bool {
    let n = polygon.len();
    if n < 3 {
        return false;
    }

    let mut sign = 0i32;
    for i in 0..n {
        let a = polygon[i];
        let b = polygon[(i + 1) % n];
        let c = polygon[(i + 2) % n];
        let cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
        let s = if cross > 0.0 {
            1
        } else if cross < 0.0 {
            -1
        } else {
            0
        };
        if s != 0 {
            if sign != 0 && s != sign {
                return false;
            }
            sign = s;
        }
    }
    true
}

/// Compute signed area of a polygon (positive = CCW, negative = CW).
fn signed_area(polygon: &[Vec2]) -> f32 {
    let n = polygon.len();
    let mut area = 0.0;
    for i in 0..n {
        let j = (i + 1) % n;
        area += polygon[i].x * polygon[j].y;
        area -= polygon[j].x * polygon[i].y;
    }
    area / 2.0
}

/// Check if the vertex at `curr` is an ear (convex and no other vertex inside the triangle).
fn is_ear(polygon: &[Vec2], indices: &[usize], prev: usize, curr: usize, next: usize) -> bool {
    let a = polygon[prev];
    let b = polygon[curr];
    let c = polygon[next];

    // Must be a convex vertex (positive cross product for CCW winding)
    let cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if cross <= 0.0 {
        return false;
    }

    // No other vertex inside this triangle
    for &idx in indices {
        if idx == prev || idx == curr || idx == next {
            continue;
        }
        if point_in_triangle(polygon[idx], a, b, c) {
            return false;
        }
    }
    true
}

/// Point-in-triangle test using barycentric sign method.
fn point_in_triangle(p: Vec2, a: Vec2, b: Vec2, c: Vec2) -> bool {
    let d1 = cross_sign(p, a, b);
    let d2 = cross_sign(p, b, c);
    let d3 = cross_sign(p, c, a);
    let has_neg = (d1 < 0.0) || (d2 < 0.0) || (d3 < 0.0);
    let has_pos = (d1 > 0.0) || (d2 > 0.0) || (d3 > 0.0);
    !(has_neg && has_pos)
}

/// Sign of the cross product for point-in-triangle test.
fn cross_sign(p1: Vec2, p2: Vec2, p3: Vec2) -> f32 {
    (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::math::vec2::Vec2;

    // ── Triangulate ─────────────────────────────────────────────────────────

    #[test]
    fn triangulate_triangle_gives_one_result() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(0.0, 1.0),
        ];
        let tris = triangulate(&pts).expect("valid polygon triangulates without error");
        assert_eq!(tris.len(), 1);
    }

    #[test]
    fn triangulate_square_gives_two_triangles() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ];
        let tris = triangulate(&pts).expect("valid polygon triangulates without error");
        assert_eq!(tris.len(), 2);
    }

    #[test]
    fn triangulate_too_few_points_returns_err() {
        let pts = vec![Vec2::new(0.0, 0.0), Vec2::new(1.0, 0.0)];
        assert!(triangulate(&pts).is_err());
    }

    // ── Convexity ────────────────────────────────────────────────────────────

    #[test]
    fn is_convex_square_true() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ];
        assert!(is_convex(&pts));
    }

    #[test]
    fn is_convex_triangle_true() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(2.0, 0.0),
            Vec2::new(1.0, 2.0),
        ];
        assert!(is_convex(&pts));
    }

    #[test]
    fn is_convex_less_than_three_false() {
        let pts = vec![Vec2::new(0.0, 0.0), Vec2::new(1.0, 0.0)];
        assert!(!is_convex(&pts));
    }
}
