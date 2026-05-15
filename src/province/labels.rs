//! - Compute pixel-weighted centroids from province span data.
//! - Map province IDs to their geometric center for label placement.

use std::collections::HashMap;

/// Compute the pixel-weighted centroid (x, y) for each province id present in the span slice;.
/// spans with id == 0 or x1 <= x0 are skipped; provinces with zero pixel area are omitted.
pub fn centroids_from_spans(spans: &[(u32, u32, u32, u32)]) -> HashMap<u32, (f32, f32)> {
    let mut sum_x: HashMap<u32, f64> = HashMap::new();
    let mut sum_y: HashMap<u32, f64> = HashMap::new();
    let mut sum_n: HashMap<u32, f64> = HashMap::new();
    for &(id, y, x0, x1) in spans {
        if id == 0 || x1 <= x0 {
            continue;
        }
        let n = (x1 - x0) as f64;
        let center_x = ((x0 + x1 - 1) as f64) * 0.5;
        *sum_x.entry(id).or_insert(0.0) += center_x * n;
        *sum_y.entry(id).or_insert(0.0) += (y as f64) * n;
        *sum_n.entry(id).or_insert(0.0) += n;
    }
    let mut out = HashMap::new();
    for (id, n) in sum_n {
        if n > 0.0 {
            out.insert(id, ((sum_x[&id] / n) as f32, (sum_y[&id] / n) as f32));
        }
    }
    out
}
