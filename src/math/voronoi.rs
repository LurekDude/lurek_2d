//! Voronoi tessellation from a set of 2-D seed points.
//!
//! ## Algorithm
//! 1. **Bowyer–Watson** incremental Delaunay triangulation builds a triangle
//!    mesh from the input points plus a temporary super-triangle.
//! 2. The **Voronoi diagram** is derived as the topological dual: each
//!    Delaunay triangle becomes a Voronoi vertex (its circumcenter), and each
//!    pair of adjacent triangles shares one Voronoi edge.
//!
//! ## Limitations
//! - Points closer than `1 × 10⁻⁵` apart are deduplicated before
//!   triangulation.
//! - Convex-hull sites produce **open cells**: infinite rays at the boundary
//!   are not emitted.
//! - Intended for hundreds to low thousands of input points.
//!
//! ## Parallelism
//! The public API is single-threaded (`f32` arithmetic only).  Callers that
//! need parallel generation of many independent diagrams should use
//! `rayon::par_iter` at the call site.

use std::collections::HashMap;

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// One cell of a Voronoi diagram.
///
/// # Fields
/// - `site` — The input seed point `(x, y)` that owns this cell.
/// - `vertices` — Circumcenters of the adjacent Delaunay triangles, ordered
///   by increasing angle around the site (counter-clockwise in standard maths
///   coordinates).  May be empty for near-duplicate inputs or isolated sites.
#[derive(Debug, Clone)]
pub struct VoronoiCell {
    /// The input seed point `(x, y)`.
    pub site: (f32, f32),
    /// Cell vertices ordered CCW by angle around `site`.
    pub vertices: Vec<(f32, f32)>,
}

// ---------------------------------------------------------------------------
// Internal geometry helpers
// ---------------------------------------------------------------------------

/// Circumcenter of triangle (ax,ay)–(bx,by)–(cx,cy).
/// Returns `None` for degenerate (collinear) triangles.
fn circumcenter(ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32) -> Option<(f32, f32)> {
    let d = 2.0 * ((bx - ax) * (cy - ay) - (by - ay) * (cx - ax));
    if d.abs() < 1e-10 {
        return None;
    }
    let ax2 = ax * ax + ay * ay;
    let bx2 = bx * bx + by * by;
    let cx2 = cx * cx + cy * cy;
    let ux = ((bx2 - ax2) * (cy - ay) - (cx2 - ax2) * (by - ay)) / d;
    let uy = ((bx - ax) * (cx2 - ax2) - (cx - ax) * (bx2 - ax2)) / d;
    Some((ux, uy))
}

/// Return `true` if point `(px, py)` lies strictly inside the circumcircle
/// of triangle `(ax,ay)–(bx,by)–(cx,cy)`.
#[allow(clippy::too_many_arguments)]
fn in_circumcircle(ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32, px: f32, py: f32) -> bool {
    let d = 2.0 * ((bx - ax) * (cy - ay) - (by - ay) * (cx - ax));
    if d.abs() < 1e-10 {
        return false;
    }
    let ax2 = ax * ax + ay * ay;
    let bx2 = bx * bx + by * by;
    let cx2 = cx * cx + cy * cy;
    let ux = ((bx2 - ax2) * (cy - ay) - (cx2 - ax2) * (by - ay)) / d;
    let uy = ((bx - ax) * (cx2 - ax2) - (cx - ax) * (bx2 - ax2)) / d;
    let r2 = (ax - ux) * (ax - ux) + (ay - uy) * (ay - uy);
    let dp2 = (px - ux) * (px - ux) + (py - uy) * (py - uy);
    dp2 < r2
}

// ---------------------------------------------------------------------------
// Internal triangulation
// ---------------------------------------------------------------------------

/// A Delaunay triangle referenced by point indices.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Tri(usize, usize, usize);

impl Tri {
    /// The three directed edges as `(from, to)` pairs.
    fn edges(self) -> [(usize, usize); 3] {
        [(self.0, self.1), (self.1, self.2), (self.2, self.0)]
    }

    /// `true` if any vertex index belongs to the super-triangle.
    fn contains_super(self, n_real: usize) -> bool {
        self.0 >= n_real || self.1 >= n_real || self.2 >= n_real
    }
}

/// Canonical (sorted) edge key for deduplication.
fn edge_key(a: usize, b: usize) -> (usize, usize) {
    if a < b {
        (a, b)
    } else {
        (b, a)
    }
}

/// Bowyer–Watson incremental Delaunay triangulation.
///
/// Inserts each real point one at a time. For each insertion, finds all
/// triangles whose circumcircle contains the new point (“bad” triangles),
/// computes the boundary polygon of the hole they leave, and re-triangulates
/// the hole by connecting the new point to each boundary edge.
///
/// `pts` must contain all real input points followed by the 3 super-triangle
/// vertices.  `n_real` is the count of real points.
fn bowyer_watson(pts: &[(f32, f32)], n_real: usize) -> Vec<Tri> {
    let n = pts.len(); // n_real + 3
    let mut tris: Vec<Tri> = vec![Tri(n - 3, n - 2, n - 1)];

    for i in 0..n_real {
        let (px, py) = pts[i];

        // Collect bad triangles whose circumcircle contains the new point.
        let bad: Vec<Tri> = tris
            .iter()
            .filter(|&&t| {
                let (ax, ay) = pts[t.0];
                let (bx, by) = pts[t.1];
                let (cx, cy) = pts[t.2];
                in_circumcircle(ax, ay, bx, by, cx, cy, px, py)
            })
            .copied()
            .collect();

        if bad.is_empty() {
            continue;
        }

        // Boundary = edges shared by exactly one bad triangle.
        let mut edge_count: HashMap<(usize, usize), usize> = HashMap::new();
        for &t in &bad {
            for (a, b) in t.edges() {
                *edge_count.entry(edge_key(a, b)).or_insert(0) += 1;
            }
        }
        let boundary: Vec<(usize, usize)> = edge_count
            .into_iter()
            .filter(|(_, c)| *c == 1)
            .map(|(e, _)| e)
            .collect();

        // Remove bad triangles from the mesh.
        tris.retain(|t| !bad.contains(t));

        // Re-triangulate the hole by connecting the new point to each
        // boundary edge.
        for (a, b) in boundary {
            tris.push(Tri(i, a, b));
        }
    }

    // Discard triangles that share a vertex with the super-triangle.
    tris.into_iter()
        .filter(|t| !t.contains_super(n_real))
        .collect()
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Compute the Voronoi diagram for `points`.
///
/// One [`VoronoiCell`] is returned per unique input point.  Cells whose site
/// lies on the convex hull are open (no infinite rays emitted).  Near-duplicate
/// points (distance < `1 × 10⁻⁵`) are treated as one site.
///
/// # Parameters
/// - `points` — Slice of `(x, y)` seed coordinates.
///
/// # Returns
/// `Vec<VoronoiCell>` with one entry per unique input point.
pub fn voronoi_from_points(points: &[(f32, f32)]) -> Vec<VoronoiCell> {
    if points.is_empty() {
        return Vec::new();
    }

    // Deduplicate nearly-coincident points before triangulation.
    let mut pts: Vec<(f32, f32)> = Vec::with_capacity(points.len());
    'outer: for &p in points {
        for &q in &pts {
            let dx = p.0 - q.0;
            let dy = p.1 - q.1;
            if dx * dx + dy * dy < 1e-10 {
                continue 'outer;
            }
        }
        pts.push(p);
    }
    let n_real = pts.len();

    // Need at least 3 non-collinear points for a triangulation.
    if n_real < 3 {
        return pts
            .iter()
            .map(|&site| VoronoiCell {
                site,
                vertices: Vec::new(),
            })
            .collect();
    }

    // Build a super-triangle that contains all points with a large margin.
    let (mut min_x, mut min_y, mut max_x, mut max_y) = pts.iter().fold(
        (f32::MAX, f32::MAX, f32::MIN, f32::MIN),
        |(lx, ly, hx, hy), &(x, y)| (lx.min(x), ly.min(y), hx.max(x), hy.max(y)),
    );
    let dx = (max_x - min_x).max(1.0);
    let dy = (max_y - min_y).max(1.0);
    let delta = dx.max(dy) * 10.0;
    min_x -= delta;
    min_y -= delta;
    max_x += delta;
    max_y += delta;
    // Three vertices for a triangle that fully encloses the bounding box.
    pts.push((min_x - dy, min_y - dx));
    pts.push(((min_x + max_x) * 0.5, max_y + dx));
    pts.push((max_x + dy, min_y - dx));

    let triangles = bowyer_watson(&pts, n_real);

    // Initialise one cell per real site.
    let mut cells: Vec<VoronoiCell> = (0..n_real)
        .map(|i| VoronoiCell {
            site: pts[i],
            vertices: Vec::new(),
        })
        .collect();

    // For each Delaunay triangle, distribute its circumcenter to every real
    // vertex it touches — those circumcenters are the Voronoi cell vertices.
    for &t in &triangles {
        let (ax, ay) = pts[t.0];
        let (bx, by) = pts[t.1];
        let (cx, cy) = pts[t.2];
        if let Some(cc) = circumcenter(ax, ay, bx, by, cx, cy) {
            for &vi in &[t.0, t.1, t.2] {
                if vi < n_real {
                    cells[vi].vertices.push(cc);
                }
            }
        }
    }

    // Sort each cell's circumcenters CCW by angle around the site so the
    // vertices form a proper polygon, then deduplicate near-coincident
    // vertices introduced by floating-point rounding in shared circumcircles.
    for cell in &mut cells {
        let (sx, sy) = cell.site;
        cell.vertices.sort_by(|&(ax, ay), &(bx, by)| {
            let a_ang = (ay - sy).atan2(ax - sx);
            let b_ang = (by - sy).atan2(bx - sx);
            a_ang
                .partial_cmp(&b_ang)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        cell.vertices.dedup_by(|a, b| {
            let ddx = a.0 - b.0;
            let ddy = a.1 - b.1;
            ddx * ddx + ddy * ddy < 1e-8
        });
    }

    cells
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
