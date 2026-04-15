//! Fast Fourier Transform (FFT) and Inverse FFT for the compute subsystem.
//!
//! Implements an iterative Cooley-Tukey radix-2 decimation-in-time algorithm.
//! Inputs are automatically zero-padded to the next power of two. This keeps
//! the implementation free of dynamic dispatch and external C libraries while
//! remaining accurate enough for game audio analysis, procedural waveforms,
//! and 2-D convolution via the convolution theorem.
//!
//! # Typical Usage
//! ```lua
//! local freqs = lurek.compute.fft({ 1, 0, -1, 0, 1, 0, -1, 0 })
//! -- freqs is an array of { re = ..., im = ... } tables
//! ```
//!
//! # Architecture Note
//! Part of the **Foundations** module group (`compute`). Has no render, audio,
//! input, or Lua dependencies.

use std::f64::consts::PI;

// ---------------------------------------------------------------------------
// Internal complex primitive
// ---------------------------------------------------------------------------

#[derive(Clone, Copy, Debug, Default)]
struct Complex {
    re: f64,
    im: f64,
}

impl Complex {
    #[inline]
    fn new(re: f64, im: f64) -> Self {
        Self { re, im }
    }

    #[inline]
    fn mul(self, rhs: Self) -> Self {
        Self {
            re: self.re * rhs.re - self.im * rhs.im,
            im: self.re * rhs.im + self.im * rhs.re,
        }
    }

    #[inline]
    fn add(self, rhs: Self) -> Self {
        Self {
            re: self.re + rhs.re,
            im: self.im + rhs.im,
        }
    }

    #[inline]
    fn sub(self, rhs: Self) -> Self {
        Self {
            re: self.re - rhs.re,
            im: self.im - rhs.im,
        }
    }
}

// ---------------------------------------------------------------------------
// Bit-reversal permutation
// ---------------------------------------------------------------------------

/// Computes bit-reversal permutation index for n bits.
#[inline]
fn bit_reverse(mut x: usize, bits: u32) -> usize {
    let mut y = 0usize;
    for _ in 0..bits {
        y = (y << 1) | (x & 1);
        x >>= 1;
    }
    y
}

/// Pads `data` to the next power of two and returns complex numbers.
fn to_complex_padded(data: &[f64]) -> Vec<Complex> {
    let n = next_power_of_two(data.len().max(1));
    let mut buf = vec![Complex::default(); n];
    for (i, &v) in data.iter().enumerate() {
        buf[i].re = v;
    }
    buf
}

/// Returns the smallest power of two ≥ `n`.
#[inline]
pub fn next_power_of_two(n: usize) -> usize {
    if n.is_power_of_two() {
        n
    } else {
        n.next_power_of_two()
    }
}

// ---------------------------------------------------------------------------
// Core iterative Cooley-Tukey FFT (in-place)
// ---------------------------------------------------------------------------

/// Performs an in-place decimation-in-time radix-2 FFT.
///
/// # Design Rationale
/// Iterative (bottom-up) Cooley-Tukey avoids recursion overhead. The input
/// buffer length **must** be a power of two.
///
/// # Parameters
/// - `buf` — mutable slice of [`Complex`] values; length must be a power of two.
/// - `inverse` — `true` for inverse transform (normalises by 1/N).
fn fft_inplace(buf: &mut [Complex], inverse: bool) {
    let n = buf.len();
    debug_assert!(n.is_power_of_two(), "fft_inplace requires a power-of-two length");
    let bits = n.trailing_zeros();

    // Bit-reversal permutation.
    for i in 0..n {
        let j = bit_reverse(i, bits);
        if i < j {
            buf.swap(i, j);
        }
    }

    // Butterfly stages.
    let sign = if inverse { 1.0_f64 } else { -1.0_f64 };
    let mut half_len = 1usize;
    while half_len < n {
        let len = half_len * 2;
        let w_angle = sign * PI / half_len as f64;
        let w_base = Complex::new(w_angle.cos(), w_angle.sin());
        let mut start = 0;
        while start < n {
            let mut w = Complex::new(1.0, 0.0);
            for k in 0..half_len {
                let u = buf[start + k];
                let v = buf[start + k + half_len].mul(w);
                buf[start + k] = u.add(v);
                buf[start + k + half_len] = u.sub(v);
                w = w.mul(w_base);
            }
            start += len;
        }
        half_len = len;
    }

    if inverse {
        let scale = 1.0 / n as f64;
        for c in buf.iter_mut() {
            c.re *= scale;
            c.im *= scale;
        }
    }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Computes the discrete Fourier transform (DFT) of `data`.
///
/// The input is zero-padded to the next power of two. Returns an array of
/// `(re, im)` complex pairs with the same length as the padded input.
///
/// # Parameters
/// - `data` — real-valued sample array (arbitrary length).
///
/// # Returns
/// `Vec<(f64, f64)>` — complex frequency-domain coefficients.
///
/// # Design Rationale
/// Returning `Vec<(f64, f64)>` keeps the domain layer Lua-agnostic. The Lua
/// API wrapper in `compute_api.rs` converts this to a table of `{re, im}` tables.
pub fn fft(data: &[f64]) -> Vec<(f64, f64)> {
    let mut buf = to_complex_padded(data);
    fft_inplace(&mut buf, false);
    buf.iter().map(|c| (c.re, c.im)).collect()
}

/// Computes the inverse discrete Fourier transform.
///
/// Accepts complex frequency-domain coefficients as `(re, im)` pairs and
/// returns real-valued time-domain samples. The output length equals the
/// input length (which must be a power of two).
///
/// # Parameters
/// - `freqs` — complex coefficient pairs from a previous call to [`fft`].
///
/// # Returns
/// `Vec<f64>` — real part of the reconstructed time-domain signal.
///
/// # Design Rationale
/// Only the real component of the inverse transform is returned because
/// a forward FFT of purely real input produces a Hermitian-symmetric
/// spectrum; rounding errors keep the imaginary part negligible.
pub fn ifft(freqs: &[(f64, f64)]) -> Vec<f64> {
    let n = next_power_of_two(freqs.len().max(1));
    let mut buf: Vec<Complex> = freqs
        .iter()
        .map(|&(re, im)| Complex::new(re, im))
        .collect();
    buf.resize(n, Complex::default());
    fft_inplace(&mut buf, true);
    buf.iter().map(|c| c.re).collect()
}

/// Returns the magnitude spectrum of `data` as `|X[k]|` values.
///
/// Convenience wrapper that calls [`fft`] and computes the absolute value of
/// each complex coefficient. Useful for audio-amplitude analysis.
///
/// # Parameters
/// - `data` — real-valued sample array.
///
/// # Returns
/// `Vec<f64>` — magnitude at each frequency bin.
pub fn fft_magnitude(data: &[f64]) -> Vec<f64> {
    fft(data)
        .iter()
        .map(|(re, im)| (re * re + im * im).sqrt())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fft_dc_signal_has_energy_in_bin0() {
        let data = vec![1.0; 8];
        let out = fft(&data);
        // DC bin should have magnitude ≈ 8, all others ≈ 0.
        let (re0, im0) = out[0];
        assert!((re0 - 8.0).abs() < 1e-9, "DC bin re should be 8.0, got {}", re0);
        assert!(im0.abs() < 1e-9);
        for (re, im) in out.iter().skip(1) {
            assert!((re * re + im * im).sqrt() < 1e-9);
        }
    }

    #[test]
    fn ifft_roundtrips_fft() {
        let data = vec![1.0, 0.5, -0.5, 0.0, 1.0, -1.0, 0.0, 0.25];
        let freqs = fft(&data);
        let recovered = ifft(&freqs);
        assert_eq!(recovered.len(), data.len());
        for (a, b) in data.iter().zip(recovered.iter()) {
            assert!((a - b).abs() < 1e-9, "roundtrip mismatch: {} vs {}", a, b);
        }
    }

    #[test]
    fn fft_zero_pads_non_power_of_two() {
        let data = vec![1.0; 5];
        let out = fft(&data);
        // Should be padded to 8.
        assert_eq!(out.len(), 8);
    }

    #[test]
    fn fft_magnitude_non_negative() {
        let data = vec![0.1, -0.2, 0.3, -0.4, 0.5, -0.6, 0.7, -0.8];
        let mag = fft_magnitude(&data);
        assert!(mag.iter().all(|&m| m >= 0.0));
    }
}
