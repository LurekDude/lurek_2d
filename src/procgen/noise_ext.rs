//! Periodic Perlin noise for tileable textures.
//!
//! Produces smooth noise that wraps seamlessly over a given period in both axes.

/// Periodic Perlin noise that tiles over period (px, py).
///
/// # Parameters
/// - `x` — `f64`.
/// - `y` — `f64`.
/// - `px` — `f64`.
/// - `py` — `f64`.
///
/// # Returns
/// `f64`.
///
/// Returns a value roughly in [-1, 1].
pub fn perlin_noise_periodic(x: f64, y: f64, px: f64, py: f64) -> f64 {
    let px = px.max(1.0) as i64;
    let py = py.max(1.0) as i64;

    let xi = x.floor() as i64;
    let yi = y.floor() as i64;
    let xf = x - x.floor();
    let yf = y - y.floor();

    let fade = |t: f64| t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    let u = fade(xf);
    let v = fade(yf);

    let wrap_x = |i: i64| ((i % px) + px) % px;
    let wrap_y = |i: i64| ((i % py) + py) % py;

    let grad = |hash: i64, x: f64, y: f64| -> f64 {
        match hash & 3 {
            0 => x + y,
            1 => -x + y,
            2 => x - y,
            3 => -x - y,
            _ => 0.0,
        }
    };

    let perm_hash = |ix: i64, iy: i64| -> i64 {
        // Simple hash combining wrapped coordinates
        let h = (wrap_x(ix).wrapping_mul(374761393) as u64)
            .wrapping_add(wrap_y(iy).wrapping_mul(668265263) as u64);
        let h = h.wrapping_mul(h).wrapping_mul(h).wrapping_mul(60493);
        (h >> 13) as i64
    };

    let n00 = grad(perm_hash(xi, yi), xf, yf);
    let n10 = grad(perm_hash(xi + 1, yi), xf - 1.0, yf);
    let n01 = grad(perm_hash(xi, yi + 1), xf, yf - 1.0);
    let n11 = grad(perm_hash(xi + 1, yi + 1), xf - 1.0, yf - 1.0);

    let lerp = |t: f64, a: f64, b: f64| a + t * (b - a);
    let x1 = lerp(u, n00, n10);
    let x2 = lerp(u, n01, n11);
    lerp(v, x1, x2)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_perlin_noise_periodic() {
        // Value at x should equal value at x + period
        let v1 = perlin_noise_periodic(1.5, 2.3, 4.0, 4.0);
        let v2 = perlin_noise_periodic(5.5, 2.3, 4.0, 4.0);
        assert!(
            (v1 - v2).abs() < 1e-10,
            "Periodic noise not tiling: {v1} vs {v2}"
        );

        let v3 = perlin_noise_periodic(1.5, 6.3, 4.0, 4.0);
        assert!(
            (v1 - v3).abs() < 1e-10,
            "Periodic noise not tiling Y: {v1} vs {v3}"
        );
    }
}
