use crate::compute::array::NdArray;

/// Compute cumulative sum and return a 1D array with running totals.
pub fn cumsum(a: &NdArray) -> Result<NdArray, String> {
    let n = a.size();
    let mut out = NdArray::zeros(&[n], a.dtype())?;
    let mut acc = 0.0_f64;
    for i in 0..n {
        acc += a.get_f64(i);
        out.set_f64(i, acc);
    }
    Ok(out)
}
/// Compute finite difference of requested order and return derived 1D array.
pub fn diff(a: &NdArray, order: usize) -> Result<NdArray, String> {
    if order == 0 {
        return Ok(a.clone());
    }
    let n = a.size();
    if order >= n {
        return Err(format!(
            "diff order {} >= array size {}; result would be empty",
            order, n
        ));
    }
    let mut vals: Vec<f64> = (0..n).map(|i| a.get_f64(i)).collect();
    for _ in 0..order {
        vals = vals.windows(2).map(|w| w[1] - w[0]).collect();
    }
    let shape = [vals.len()];
    let mut out = NdArray::zeros(&shape, a.dtype())?;
    for (i, v) in vals.into_iter().enumerate() {
        out.set_f64(i, v);
    }
    Ok(out)
}
/// Compute histogram bins and return (lo, hi, count) tuples for each bin.
pub fn histogram(
    a: &NdArray,
    bins: usize,
    range_lo: Option<f64>,
    range_hi: Option<f64>,
) -> Result<Vec<(f64, f64, u64)>, String> {
    if bins == 0 {
        return Err("histogram: bins must be >= 1".to_string());
    }
    let n = a.size();
    if n == 0 {
        return Err("histogram: empty array".to_string());
    }
    let lo = range_lo.unwrap_or_else(|| {
        let mut m = a.get_f64(0);
        for i in 1..n {
            let v = a.get_f64(i);
            if v < m {
                m = v;
            }
        }
        m
    });
    let hi = range_hi.unwrap_or_else(|| {
        let mut m = a.get_f64(0);
        for i in 1..n {
            let v = a.get_f64(i);
            if v > m {
                m = v;
            }
        }
        m
    });
    if hi <= lo {
        return Err(format!(
            "histogram: range_hi ({hi}) must be > range_lo ({lo})"
        ));
    }
    let width = (hi - lo) / bins as f64;
    let mut counts = vec![0u64; bins];
    for i in 0..n {
        let v = a.get_f64(i);
        if v < lo || v > hi {
            continue;
        }
        let mut bin = ((v - lo) / width) as usize;
        if bin >= bins {
            bin = bins - 1;
        }
        counts[bin] += 1;
    }
    let result = (0..bins)
        .map(|b| {
            let bin_lo = lo + b as f64 * width;
            let bin_hi = lo + (b + 1) as f64 * width;
            (bin_lo, bin_hi, counts[b])
        })
        .collect();
    Ok(result)
}
/// Compute percentile value and return interpolated sample at p in [0, 100].
pub fn percentile(a: &NdArray, p: f64) -> Result<f64, String> {
    if !(0.0..=100.0).contains(&p) {
        return Err(format!("percentile p must be in [0, 100], got {p}"));
    }
    let n = a.size();
    if n == 0 {
        return Err("percentile: empty array".to_string());
    }
    let mut vals: Vec<f64> = (0..n).map(|i| a.get_f64(i)).collect();
    vals.sort_by(|x, y| x.partial_cmp(y).unwrap_or(std::cmp::Ordering::Equal));
    let idx = (p / 100.0) * (n - 1) as f64;
    let lo = idx.floor() as usize;
    let hi = idx.ceil() as usize;
    if lo == hi {
        return Ok(vals[lo]);
    }
    let frac = idx - lo as f64;
    Ok(vals[lo] * (1.0 - frac) + vals[hi] * frac)
}
/// Compute population covariance and return scalar covariance between arrays.
pub fn covariance(a: &NdArray, b: &NdArray) -> Result<f64, String> {
    let n = a.size();
    if n != b.size() {
        return Err(format!("covariance: size mismatch {} vs {}", n, b.size()));
    }
    if n == 0 {
        return Err("covariance: empty arrays".to_string());
    }
    let mean_a: f64 = (0..n).map(|i| a.get_f64(i)).sum::<f64>() / n as f64;
    let mean_b: f64 = (0..n).map(|i| b.get_f64(i)).sum::<f64>() / n as f64;
    let cov: f64 = (0..n)
        .map(|i| (a.get_f64(i) - mean_a) * (b.get_f64(i) - mean_b))
        .sum::<f64>()
        / n as f64;
    Ok(cov)
}
/// Compute Pearson correlation and return normalized linear correlation coefficient.
pub fn pearson_corr(a: &NdArray, b: &NdArray) -> Result<f64, String> {
    let n = a.size();
    if n != b.size() {
        return Err(format!("pearson_corr: size mismatch {} vs {}", n, b.size()));
    }
    if n < 2 {
        return Err("pearson_corr: need at least 2 elements".to_string());
    }
    let mean_a: f64 = (0..n).map(|i| a.get_f64(i)).sum::<f64>() / n as f64;
    let mean_b: f64 = (0..n).map(|i| b.get_f64(i)).sum::<f64>() / n as f64;
    let mut num = 0.0_f64;
    let mut ss_a = 0.0_f64;
    let mut ss_b = 0.0_f64;
    for i in 0..n {
        let da = a.get_f64(i) - mean_a;
        let db = b.get_f64(i) - mean_b;
        num += da * db;
        ss_a += da * da;
        ss_b += db * db;
    }
    let denom = (ss_a * ss_b).sqrt();
    if denom == 0.0 {
        return Err("pearson_corr: zero variance in one or both arrays".to_string());
    }
    Ok(num / denom)
}
/// Normalize values to output range and return scaled 1D array.
pub fn normalize_range(a: &NdArray, out_min: f64, out_max: f64) -> Result<NdArray, String> {
    if out_max <= out_min {
        return Err(format!(
            "normalize_range: out_max ({out_max}) must be > out_min ({out_min})"
        ));
    }
    let n = a.size();
    let mut lo = a.get_f64(0);
    let mut hi = a.get_f64(0);
    for i in 1..n {
        let v = a.get_f64(i);
        if v < lo {
            lo = v;
        }
        if v > hi {
            hi = v;
        }
    }
    let span = hi - lo;
    let out_span = out_max - out_min;
    let mut out = NdArray::zeros(&[n], a.dtype())?;
    for i in 0..n {
        let norm = if span == 0.0 {
            0.5
        } else {
            (a.get_f64(i) - lo) / span
        };
        out.set_f64(i, out_min + norm * out_span);
    }
    Ok(out)
}
/// Normalize values to z-scores and return array with mean-zero unit variance.
pub fn zscore(a: &NdArray) -> Result<NdArray, String> {
    let n = a.size();
    if n == 0 {
        return Err("zscore: empty array".to_string());
    }
    let mean: f64 = (0..n).map(|i| a.get_f64(i)).sum::<f64>() / n as f64;
    let var: f64 = (0..n).map(|i| (a.get_f64(i) - mean).powi(2)).sum::<f64>() / n as f64;
    let std = var.sqrt();
    if std == 0.0 {
        return Err("zscore: zero standard deviation".to_string());
    }
    let mut out = NdArray::zeros(&[n], a.dtype())?;
    for i in 0..n {
        out.set_f64(i, (a.get_f64(i) - mean) / std);
    }
    Ok(out)
}
#[allow(clippy::needless_range_loop)]
/// Compute full 1D convolution and return output signal array.
pub fn convolve1d(signal: &NdArray, kernel: &NdArray) -> Result<NdArray, String> {
    if signal.ndim() != 1 {
        return Err(format!(
            "convolve1d: signal must be 1D, got {}D",
            signal.ndim()
        ));
    }
    if kernel.ndim() != 1 {
        return Err(format!(
            "convolve1d: kernel must be 1D, got {}D",
            kernel.ndim()
        ));
    }
    let sn = signal.size();
    let kn = kernel.size();
    let out_len = sn + kn - 1;
    let mut out = NdArray::zeros(&[out_len], signal.dtype())?;
    let kflip: Vec<f64> = (0..kn).rev().map(|i| kernel.get_f64(i)).collect();
    for o in 0..out_len {
        let mut acc = 0.0_f64;
        for k in 0..kn {
            let s_idx = o as isize - k as isize;
            if s_idx >= 0 && (s_idx as usize) < sn {
                acc += signal.get_f64(s_idx as usize) * kflip[k];
            }
        }
        out.set_f64(o, acc);
    }
    Ok(out)
}
/// Compute valid 1D correlation and return sliding dot-product array.
pub fn correlate1d(signal: &NdArray, template: &NdArray) -> Result<NdArray, String> {
    if signal.ndim() != 1 {
        return Err(format!(
            "correlate1d: signal must be 1D, got {}D",
            signal.ndim()
        ));
    }
    if template.ndim() != 1 {
        return Err(format!(
            "correlate1d: template must be 1D, got {}D",
            template.ndim()
        ));
    }
    let sn = signal.size();
    let tn = template.size();
    if tn > sn {
        return Err(format!(
            "correlate1d: template length {tn} > signal length {sn}"
        ));
    }
    let out_len = sn - tn + 1;
    let mut out = NdArray::zeros(&[out_len], signal.dtype())?;
    for o in 0..out_len {
        let mut acc = 0.0_f64;
        for k in 0..tn {
            acc += signal.get_f64(o + k) * template.get_f64(k);
        }
        out.set_f64(o, acc);
    }
    Ok(out)
}
