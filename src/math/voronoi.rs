//! - Voronoi diagram generation from 2D point sets via Bowyer-Watson Delaunay triangulation.
//! - Circumcenter and circumcircle predicates for incremental insertion.
//! - Boundary-edge extraction and super-triangle cleanup.
//! - CCW vertex sorting and deduplication to produce closed polygonal cells.
//! - Input deduplication to handle coincident sites gracefully.

use std::collections::HashMap;

/// One Voronoi region around a seed site with its polygon vertices in CCW order.
#[derive(Debug, Clone)]
pub struct VoronoiCell {
    /// Seed point this cell surrounds.
    pub site: (f32, f32),
    /// Circumcenter vertices of adjacent Delaunay triangles, sorted CCW around the site.
    pub vertices: Vec<(f32, f32)>,
}

/// Return the circumcenter of triangle (ax,ay)-(bx,by)-(cx,cy), or `None` when collinear.
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

/// Return true when point `(px, py)` lies strictly inside the circumcircle of triangle (ax,ay)-(bx,by)-(cx,cy).
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

/// Index triple representing one Delaunay triangle by vertex indices into `pts`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Tri(usize, usize, usize);

/// Methods for querying edges and super-triangle membership of a Delaunay triangle.
impl Tri {
    /// Return the three directed edges of this triangle.
    fn edges(self) -> [(usize, usize); 3] {
        [(self.0, self.1), (self.1, self.2), (self.2, self.0)]
    }
    /// Return true when any vertex index belongs to the super-triangle (indices >= `n_real`).
    fn contains_super(self, n_real: usize) -> bool {
        self.0 >= n_real || self.1 >= n_real || self.2 >= n_real
    }
}

/// Return the canonical edge key with the smaller index first.
fn edge_key(a: usize, b: usize) -> (usize, usize) {
    if a < b {
        (a, b)
    } else {
        (b, a)
    }
}

/// Run Bowyer-Watson incremental Delaunay triangulation on `pts`; strips super-triangle faces.
fn bowyer_watson(pts: &[(f32, f32)], n_real: usize) -> Vec<Tri> {
    let n = pts.len();
    let mut tris: Vec<Tri> = vec![Tri(n - 3, n - 2, n - 1)];
    for i in 0..n_real {
        let (px, py) = pts[i];
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
        tris.retain(|t| !bad.contains(t));
        for (a, b) in boundary {
            tris.push(Tri(i, a, b));
        }
    }
    tris.into_iter()
        .filter(|t| !t.contains_super(n_real))
        .collect()
}

/// Compute Voronoi cells for `points`; deduplicates input and returns one cell per unique site.
pub fn voronoi_from_points(points: &[(f32, f32)]) -> Vec<VoronoiCell> {
    if points.is_empty() {
        return Vec::new();
    }
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
    if n_real < 3 {
        return pts
            .iter()
            .map(|&site| VoronoiCell {
                site,
                vertices: Vec::new(),
            })
            .collect();
    }
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
    pts.push((min_x - dy, min_y - dx));
    pts.push(((min_x + max_x) * 0.5, max_y + dx));
    pts.push((max_x + dy, min_y - dx));
    let triangles = bowyer_watson(&pts, n_real);
    let mut cells: Vec<VoronoiCell> = (0..n_real)
        .map(|i| VoronoiCell {
            site: pts[i],
            vertices: Vec::new(),
        })
        .collect();
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
