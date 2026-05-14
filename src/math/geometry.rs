//! Geometric primitives and query functions: angle, point-in-shape, segment intersection,
//! polygon area/centroid, Bresenham rasterisation, convex hull, and Bowyer-Watson Delaunay
//! triangulation.  Used by physics debug, procgen, pathfinding, and Lua geometry bindings.
//! Does not own 2D transform math (see transform.rs) or polygon clipping (see polygon.rs).

/// Return the angle in radians from point (x1, y1) to point (x2, y2) via `atan2`.
pub fn angle_between(x1: f32, y1: f32, x2: f32, y2: f32) -> f32 {
    (y2 - y1).atan2(x2 - x1)
}

/// Return true when point (px, py) lies inside or on the boundary of circle (cx, cy, r).
pub fn circle_contains_point(cx: f32, cy: f32, r: f32, px: f32, py: f32) -> bool {
    let dx = px - cx;
    let dy = py - cy;
    dx * dx + dy * dy <= r * r
}

/// Return true when two circles overlap (touching counts as intersection).
pub fn circle_intersects_circle(x1: f32, y1: f32, r1: f32, x2: f32, y2: f32, r2: f32) -> bool {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let sum_r = r1 + r2;
    dx * dx + dy * dy <= sum_r * sum_r
}

/// Return whether an infinite line intersects a circle and the up to two intersection points.
#[allow(clippy::type_complexity)]
pub fn circle_intersects_line(
    cx: f32,
    cy: f32,
    r: f32,
    lx1: f32,
    ly1: f32,
    lx2: f32,
    ly2: f32,
) -> (bool, Option<(f32, f32)>, Option<(f32, f32)>) {
    let dx = lx2 - lx1;
    let dy = ly2 - ly1;
    let fx = lx1 - cx;
    let fy = ly1 - cy;
    let a = dx * dx + dy * dy;
    if a < 1e-10 {
        return (false, None, None);
    }
    let b = 2.0 * (fx * dx + fy * dy);
    let c = fx * fx + fy * fy - r * r;
    let discriminant = b * b - 4.0 * a * c;
    if discriminant < 0.0 {
        return (false, None, None);
    }
    let sqrt_d = discriminant.sqrt();
    let t1 = (-b - sqrt_d) / (2.0 * a);
    let t2 = (-b + sqrt_d) / (2.0 * a);
    let p1 = Some((lx1 + t1 * dx, ly1 + t1 * dy));
    let p2 = if discriminant > 1e-10 {
        Some((lx1 + t2 * dx, ly1 + t2 * dy))
    } else {
        None
    };
    (true, p1, p2)
}

/// Return whether a finite segment intersects a circle and the intersection points within `[0,1]` range.
#[allow(clippy::type_complexity)]
pub fn circle_intersects_segment(
    cx: f32,
    cy: f32,
    r: f32,
    sx1: f32,
    sy1: f32,
    sx2: f32,
    sy2: f32,
) -> (bool, Option<(f32, f32)>, Option<(f32, f32)>) {
    let dx = sx2 - sx1;
    let dy = sy2 - sy1;
    let fx = sx1 - cx;
    let fy = sy1 - cy;
    let a = dx * dx + dy * dy;
    if a < 1e-10 {
        return (false, None, None);
    }
    let b = 2.0 * (fx * dx + fy * dy);
    let c = fx * fx + fy * fy - r * r;
    let discriminant = b * b - 4.0 * a * c;
    if discriminant < 0.0 {
        return (false, None, None);
    }
    let sqrt_d = discriminant.sqrt();
    let t1 = (-b - sqrt_d) / (2.0 * a);
    let t2 = (-b + sqrt_d) / (2.0 * a);
    let p1 = if (0.0..=1.0).contains(&t1) {
        Some((sx1 + t1 * dx, sy1 + t1 * dy))
    } else {
        None
    };
    let p2 = if discriminant > 1e-10 && (0.0..=1.0).contains(&t2) {
        Some((sx1 + t2 * dx, sy1 + t2 * dy))
    } else {
        None
    };
    let any_hit = p1.is_some() || p2.is_some();
    (any_hit, p1, p2)
}

/// Return the signed area of a flat vertex array `[x0, y0, x1, y1, ...]`; positive = CCW.
pub fn polygon_area(vertices: &[f32]) -> f32 {
    let n = vertices.len() / 2;
    if n < 3 {
        return 0.0;
    }
    let mut area = 0.0;
    for i in 0..n {
        let j = (i + 1) % n;
        let xi = vertices[i * 2];
        let yi = vertices[i * 2 + 1];
        let xj = vertices[j * 2];
        let yj = vertices[j * 2 + 1];
        area += xi * yj - xj * yi;
    }
    area * 0.5
}

/// Return the centroid (cx, cy) of a flat vertex array; falls back to arithmetic mean for degenerate polygons.
pub fn polygon_centroid(vertices: &[f32]) -> (f32, f32) {
    let n = vertices.len() / 2;
    if n == 0 {
        return (0.0, 0.0);
    }
    let mut cx = 0.0;
    let mut cy = 0.0;
    let mut signed_area = 0.0;
    for i in 0..n {
        let j = (i + 1) % n;
        let xi = vertices[i * 2];
        let yi = vertices[i * 2 + 1];
        let xj = vertices[j * 2];
        let yj = vertices[j * 2 + 1];
        let cross = xi * yj - xj * yi;
        signed_area += cross;
        cx += (xi + xj) * cross;
        cy += (yi + yj) * cross;
    }
    signed_area *= 0.5;
    if signed_area.abs() < 1e-10 {
        let mut sx = 0.0;
        let mut sy = 0.0;
        for i in 0..n {
            sx += vertices[i * 2];
            sy += vertices[i * 2 + 1];
        }
        return (sx / n as f32, sy / n as f32);
    }
    let factor = 1.0 / (6.0 * signed_area);
    (cx * factor, cy * factor)
}

/// Return whether two line segments intersect and the intersection point when they do.
#[allow(clippy::too_many_arguments)]
pub fn segment_intersects_segment(
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
    x3: f32,
    y3: f32,
    x4: f32,
    y4: f32,
) -> (bool, Option<(f32, f32)>) {
    let d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if d.abs() < 1e-10 {
        return (false, None);
    }
    let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / d;
    let u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / d;
    if (0.0..=1.0).contains(&t) && (0.0..=1.0).contains(&u) {
        let ix = x1 + t * (x2 - x1);
        let iy = y1 + t * (y2 - y1);
        (true, Some((ix, iy)))
    } else {
        (false, None)
    }
}

/// Return the closest point on segment (x1,y1)-(x2,y2) to point (px, py), clamped to segment endpoints.
pub fn closest_point_on_segment(
    px: f32,
    py: f32,
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
) -> (f32, f32) {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let len_sq = dx * dx + dy * dy;
    if len_sq < 1e-10 {
        return (x1, y1);
    }
    let t = ((px - x1) * dx + (py - y1) * dy) / len_sq;
    let t = t.clamp(0.0, 1.0);
    (x1 + t * dx, y1 + t * dy)
}

/// Return true when point (px, py) is inside the polygon described by flat vertex array using ray casting.
pub fn point_in_polygon(vertices: &[f32], px: f32, py: f32) -> bool {
    let n = vertices.len() / 2;
    if n < 3 {
        return false;
    }
    let mut inside = false;
    let mut j = n - 1;
    for i in 0..n {
        let xi = vertices[i * 2];
        let yi = vertices[i * 2 + 1];
        let xj = vertices[j * 2];
        let yj = vertices[j * 2 + 1];
        if ((yi > py) != (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
            inside = !inside;
        }
        j = i;
    }
    inside
}

/// Return the intersection point of two infinite lines, or `None` when parallel.
#[allow(clippy::too_many_arguments)]
pub fn line_intersect(
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
    x3: f32,
    y3: f32,
    x4: f32,
    y4: f32,
) -> Option<(f32, f32)> {
    let d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if d.abs() < 1e-10 {
        return None;
    }
    let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / d;
    Some((x1 + t * (x2 - x1), y1 + t * (y2 - y1)))
}

/// Return all integer grid cells on the line from (x1, y1) to (x2, y2) using Bresenham's algorithm.
pub fn bresenham(x1: i32, y1: i32, x2: i32, y2: i32) -> Vec<(i32, i32)> {
    let mut points = Vec::new();
    let mut x = x1;
    let mut y = y1;
    let dx = (x2 - x1).abs();
    let dy = -(y2 - y1).abs();
    let sx = if x1 < x2 { 1 } else { -1 };
    let sy = if y1 < y2 { 1 } else { -1 };
    let mut err = dx + dy;
    loop {
        points.push((x, y));
        if x == x2 && y == y2 {
            break;
        }
        let e2 = 2 * err;
        if e2 >= dy {
            err += dy;
            x += sx;
        }
        if e2 <= dx {
            err += dx;
            y += sy;
        }
    }
    points
}

/// Return the convex hull of a flat vertex array `[x0, y0, ...]` as a flat CCW result using Andrew monotone chain.
pub fn convex_hull(points: &[f32]) -> Vec<f32> {
    let n = points.len() / 2;
    if n < 3 {
        return points.to_vec();
    }
    let mut pts: Vec<(f32, f32)> = (0..n).map(|i| (points[i * 2], points[i * 2 + 1])).collect();
    pts.sort_by(|a, b| {
        a.0.partial_cmp(&b.0)
            .expect("partial_cmp on finite f32")
            .then(a.1.partial_cmp(&b.1).expect("partial_cmp on finite f32"))
    });
    let cross = |o: (f32, f32), a: (f32, f32), b: (f32, f32)| -> f32 {
        (a.0 - o.0) * (b.1 - o.1) - (a.1 - o.1) * (b.0 - o.0)
    };
    let mut lower: Vec<(f32, f32)> = Vec::new();
    for &p in &pts {
        while lower.len() >= 2 && cross(lower[lower.len() - 2], lower[lower.len() - 1], p) <= 0.0 {
            lower.pop();
        }
        lower.push(p);
    }
    let mut upper: Vec<(f32, f32)> = Vec::new();
    for &p in pts.iter().rev() {
        while upper.len() >= 2 && cross(upper[upper.len() - 2], upper[upper.len() - 1], p) <= 0.0 {
            upper.pop();
        }
        upper.push(p);
    }
    lower.pop();
    upper.pop();
    lower.extend(upper);
    let mut result = Vec::with_capacity(lower.len() * 2);
    for (x, y) in lower {
        result.push(x);
        result.push(y);
    }
    result
}

/// Return Delaunay triangulation of `points` as flat `[x0,y0, x1,y1, x2,y2]` triangle arrays using Bowyer-Watson.
pub fn delaunay_triangulate(points: &[(f64, f64)]) -> Vec<[f64; 6]> {
    if points.len() < 3 {
        return Vec::new();
    }
    let mut min_x = f64::MAX;
    let mut min_y = f64::MAX;
    let mut max_x = f64::MIN;
    let mut max_y = f64::MIN;
    for &(x, y) in points {
        if x < min_x {
            min_x = x;
        }
        if y < min_y {
            min_y = y;
        }
        if x > max_x {
            max_x = x;
        }
        if y > max_y {
            max_y = y;
        }
    }
    let dx = max_x - min_x;
    let dy = max_y - min_y;
    let delta = dx.max(dy);
    let mid_x = (min_x + max_x) / 2.0;
    let mid_y = (min_y + max_y) / 2.0;
    let st0 = (mid_x - 20.0 * delta, mid_y - delta);
    let st1 = (mid_x, mid_y + 20.0 * delta);
    let st2 = (mid_x + 20.0 * delta, mid_y - delta);
    let mut all_points: Vec<(f64, f64)> = vec![st0, st1, st2];
    all_points.extend_from_slice(points);
    let mut triangles: Vec<[usize; 3]> = vec![[0, 1, 2]];
    for pi in 3..all_points.len() {
        let p = all_points[pi];
        let mut bad_triangles = Vec::new();
        for (ti, tri) in triangles.iter().enumerate() {
            if in_circumcircle(
                p,
                all_points[tri[0]],
                all_points[tri[1]],
                all_points[tri[2]],
            ) {
                bad_triangles.push(ti);
            }
        }
        let mut polygon: Vec<[usize; 2]> = Vec::new();
        for &bi in &bad_triangles {
            let tri = triangles[bi];
            let edges = [[tri[0], tri[1]], [tri[1], tri[2]], [tri[2], tri[0]]];
            for edge in &edges {
                let shared = bad_triangles.iter().any(|&oi| {
                    if oi == bi {
                        return false;
                    }
                    let ot = triangles[oi];
                    let oe = [[ot[0], ot[1]], [ot[1], ot[2]], [ot[2], ot[0]]];
                    oe.iter().any(|e| {
                        (e[0] == edge[0] && e[1] == edge[1]) || (e[0] == edge[1] && e[1] == edge[0])
                    })
                });
                if !shared {
                    polygon.push(*edge);
                }
            }
        }
        bad_triangles.sort_unstable();
        for &bi in bad_triangles.iter().rev() {
            triangles.swap_remove(bi);
        }
        for edge in &polygon {
            triangles.push([edge[0], edge[1], pi]);
        }
    }
    triangles.retain(|tri| tri[0] >= 3 && tri[1] >= 3 && tri[2] >= 3);
    triangles
        .iter()
        .map(|tri| {
            let (x0, y0) = all_points[tri[0]];
            let (x1, y1) = all_points[tri[1]];
            let (x2, y2) = all_points[tri[2]];
            [x0, y0, x1, y1, x2, y2]
        })
        .collect()
}

/// Return true when point `p` lies inside the circumcircle of triangle (a, b, c).
fn in_circumcircle(p: (f64, f64), a: (f64, f64), b: (f64, f64), c: (f64, f64)) -> bool {
    let ax = a.0 - p.0;
    let ay = a.1 - p.1;
    let bx = b.0 - p.0;
    let by = b.1 - p.1;
    let cx = c.0 - p.0;
    let cy = c.1 - p.1;
    let det = ax * (by * (cx * cx + cy * cy) - cy * (bx * bx + by * by))
        - ay * (bx * (cx * cx + cy * cy) - cx * (bx * bx + by * by))
        + (ax * ax + ay * ay) * (bx * cy - by * cx);
    det > 0.0
}
