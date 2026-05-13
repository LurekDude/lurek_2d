use std::f64::consts::PI;
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
#[inline]
fn bit_reverse(mut x: usize, bits: u32) -> usize {
    let mut y = 0usize;
    for _ in 0..bits {
        y = (y << 1) | (x & 1);
        x >>= 1;
    }
    y
}
fn to_complex_padded(data: &[f64]) -> Vec<Complex> {
    let n = next_power_of_two(data.len().max(1));
    let mut buf = vec![Complex::default(); n];
    for (i, &v) in data.iter().enumerate() {
        buf[i].re = v;
    }
    buf
}
#[inline]
pub fn next_power_of_two(n: usize) -> usize {
    if n.is_power_of_two() {
        n
    } else {
        n.next_power_of_two()
    }
}
fn fft_inplace(buf: &mut [Complex], inverse: bool) {
    let n = buf.len();
    debug_assert!(
        n.is_power_of_two(),
        "fft_inplace requires a power-of-two length"
    );
    let bits = n.trailing_zeros();
    for i in 0..n {
        let j = bit_reverse(i, bits);
        if i < j {
            buf.swap(i, j);
        }
    }
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
pub fn fft(data: &[f64]) -> Vec<(f64, f64)> {
    let mut buf = to_complex_padded(data);
    fft_inplace(&mut buf, false);
    buf.iter().map(|c| (c.re, c.im)).collect()
}
pub fn ifft(freqs: &[(f64, f64)]) -> Vec<f64> {
    let n = next_power_of_two(freqs.len().max(1));
    let mut buf: Vec<Complex> = freqs.iter().map(|&(re, im)| Complex::new(re, im)).collect();
    buf.resize(n, Complex::default());
    fft_inplace(&mut buf, true);
    buf.iter().map(|c| c.re).collect()
}
pub fn fft_magnitude(data: &[f64]) -> Vec<f64> {
    fft(data)
        .iter()
        .map(|(re, im)| (re * re + im * im).sqrt())
        .collect()
}
