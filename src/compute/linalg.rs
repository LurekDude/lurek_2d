use crate::compute::array::{DataType, NdArray};
use crate::compute::spatial;
pub fn normalize_vec(v: &NdArray) -> Result<NdArray, String> {
    if v.ndim() != 1 {
        return Err(format!(
            "normalize_vec: expected 1D array, got {}D",
            v.ndim()
        ));
    }
    let sq_sum: f64 = (0..v.size()).map(|i| v.get_f64(i).powi(2)).sum();
    let len = sq_sum.sqrt();
    if len == 0.0 {
        return Err("normalize_vec: zero-length vector".to_string());
    }
    let mut out = NdArray::zeros(&[v.size()], v.dtype())?;
    for i in 0..v.size() {
        out.set_f64(i, v.get_f64(i) / len);
    }
    Ok(out)
}
pub fn cross2d(a: &NdArray, b: &NdArray) -> Result<f64, String> {
    if a.size() != 2 || b.size() != 2 {
        return Err(format!(
            "cross2d: need two length-2 vectors, got {} and {}",
            a.size(),
            b.size()
        ));
    }
    Ok(a.get_f64(0) * b.get_f64(1) - a.get_f64(1) * b.get_f64(0))
}
pub fn outer(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    if a.ndim() != 1 || b.ndim() != 1 {
        return Err("outer: both inputs must be 1D".to_string());
    }
    let m = a.size();
    let n = b.size();
    let mut out = NdArray::zeros(&[m, n], a.dtype())?;
    for i in 0..m {
        for j in 0..n {
            let flat = out.flat_index(&[i, j]).unwrap();
            out.set_f64(flat, a.get_f64(i) * b.get_f64(j));
        }
    }
    Ok(out)
}
pub fn rotate2d_matrix(angle_rad: f64) -> Result<NdArray, String> {
    let (s, c) = angle_rad.sin_cos();
    let vals = [c, -s, s, c];
    NdArray::from_slice(&vals, &[2, 2], DataType::Float64)
}
pub fn affine2d(tx: f64, ty: f64, angle_rad: f64, sx: f64, sy: f64) -> Result<NdArray, String> {
    let (s, c) = angle_rad.sin_cos();
    let vals = [sx * c, -sy * s, tx, sx * s, sy * c, ty, 0.0, 0.0, 1.0];
    NdArray::from_slice(&vals, &[3, 3], DataType::Float64)
}
pub fn transform_points(matrix: &NdArray, points: &NdArray) -> Result<NdArray, String> {
    if points.ndim() != 2 || points.shape()[1] != 2 {
        return Err(format!(
            "transform_points: points must be [N,2], got {:?}",
            points.shape()
        ));
    }
    let n = points.shape()[0];
    let ms = matrix.shape();
    let is3x3 = ms == [3, 3];
    let is2x2 = ms == [2, 2];
    if !is2x2 && !is3x3 {
        return Err(format!(
            "transform_points: matrix must be [2,2] or [3,3], got {:?}",
            ms
        ));
    }
    let mut out = NdArray::zeros(&[n, 2], points.dtype())?;
    for i in 0..n {
        let px = points.get_f64(points.flat_index(&[i, 0]).unwrap());
        let py = points.get_f64(points.flat_index(&[i, 1]).unwrap());
        let (ox, oy) = if is2x2 {
            let m00 = matrix.get_f64(matrix.flat_index(&[0, 0]).unwrap());
            let m01 = matrix.get_f64(matrix.flat_index(&[0, 1]).unwrap());
            let m10 = matrix.get_f64(matrix.flat_index(&[1, 0]).unwrap());
            let m11 = matrix.get_f64(matrix.flat_index(&[1, 1]).unwrap());
            (m00 * px + m01 * py, m10 * px + m11 * py)
        } else {
            let m00 = matrix.get_f64(matrix.flat_index(&[0, 0]).unwrap());
            let m01 = matrix.get_f64(matrix.flat_index(&[0, 1]).unwrap());
            let m02 = matrix.get_f64(matrix.flat_index(&[0, 2]).unwrap());
            let m10 = matrix.get_f64(matrix.flat_index(&[1, 0]).unwrap());
            let m11 = matrix.get_f64(matrix.flat_index(&[1, 1]).unwrap());
            let m12 = matrix.get_f64(matrix.flat_index(&[1, 2]).unwrap());
            let m20 = matrix.get_f64(matrix.flat_index(&[2, 0]).unwrap());
            let m21 = matrix.get_f64(matrix.flat_index(&[2, 1]).unwrap());
            let m22 = matrix.get_f64(matrix.flat_index(&[2, 2]).unwrap());
            let w = m20 * px + m21 * py + m22;
            let w = if w == 0.0 { 1.0 } else { w };
            (
                (m00 * px + m01 * py + m02) / w,
                (m10 * px + m11 * py + m12) / w,
            )
        };
        out.set_f64(out.flat_index(&[i, 0]).unwrap(), ox);
        out.set_f64(out.flat_index(&[i, 1]).unwrap(), oy);
    }
    Ok(out)
}
pub fn gaussian_kernel(size: usize, sigma: f64) -> Result<NdArray, String> {
    if size == 0 {
        return Err("gaussian_kernel: size must be >= 1".to_string());
    }
    if size.is_multiple_of(2) {
        return Err(format!("gaussian_kernel: size must be odd, got {size}"));
    }
    if sigma <= 0.0 {
        return Err(format!(
            "gaussian_kernel: sigma must be positive, got {sigma}"
        ));
    }
    let half = (size / 2) as isize;
    let two_sig2 = 2.0 * sigma * sigma;
    let mut vals = vec![0.0_f64; size * size];
    for r in 0..size {
        for c in 0..size {
            let dr = (r as isize - half) as f64;
            let dc = (c as isize - half) as f64;
            vals[r * size + c] = (-(dr * dr + dc * dc) / two_sig2).exp();
        }
    }
    let sum: f64 = vals.iter().sum();
    for v in &mut vals {
        *v /= sum;
    }
    NdArray::from_slice(&vals, &[size, size], DataType::Float64)
}
pub fn sobel(input: &NdArray) -> Result<(NdArray, NdArray), String> {
    if input.ndim() != 2 {
        return Err(format!("sobel: expected 2D array, got {}D", input.ndim()));
    }
    let gx_kernel = NdArray::from_slice(
        &[-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0],
        &[3, 3],
        DataType::Float64,
    )?;
    let gy_kernel = NdArray::from_slice(
        &[-1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0],
        &[3, 3],
        DataType::Float64,
    )?;
    let gx = spatial::convolve2d(input, &gx_kernel)?;
    let gy = spatial::convolve2d(input, &gy_kernel)?;
    Ok((gx, gy))
}
#[allow(clippy::needless_range_loop)]
pub fn linsolve(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    if a.ndim() != 2 || a.shape()[0] != a.shape()[1] {
        return Err(format!(
            "linsolve: a must be a square [n,n] matrix, got {:?}",
            a.shape()
        ));
    }
    let n = a.shape()[0];
    if b.ndim() != 1 || b.size() != n {
        return Err(format!(
            "linsolve: b must be a 1D vector of length {n}, got {:?}",
            b.shape()
        ));
    }
    let mut mat: Vec<Vec<f64>> = (0..n)
        .map(|r| {
            let mut row: Vec<f64> = (0..n)
                .map(|c| a.get_f64(a.flat_index(&[r, c]).unwrap()))
                .collect();
            row.push(b.get_f64(r));
            row
        })
        .collect();
    for col in 0..n {
        let pivot_row = (col..n)
            .max_by(|&i, &j| {
                mat[i][col]
                    .abs()
                    .partial_cmp(&mat[j][col].abs())
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .unwrap();
        mat.swap(col, pivot_row);
        let pivot = mat[col][col];
        if pivot.abs() < 1e-12 {
            return Err("linsolve: matrix is singular or near-singular".to_string());
        }
        for row in (col + 1)..n {
            let factor = mat[row][col] / pivot;
            for k in col..=n {
                let sub = factor * mat[col][k];
                mat[row][k] -= sub;
            }
        }
    }
    let mut x = vec![0.0_f64; n];
    for i in (0..n).rev() {
        let mut rhs = mat[i][n];
        for j in (i + 1)..n {
            rhs -= mat[i][j] * x[j];
        }
        x[i] = rhs / mat[i][i];
    }
    let mut out = NdArray::zeros(&[n], b.dtype())?;
    for (i, v) in x.into_iter().enumerate() {
        out.set_f64(i, v);
    }
    Ok(out)
}
#[derive(Debug, Clone)]
pub struct LuDecomp {
    pub lu_data: Vec<f64>,
    pub perm: Vec<usize>,
    pub n: usize,
    pub det_sign: i32,
}
pub fn lu_decompose(a: &NdArray) -> Result<LuDecomp, String> {
    let shape = a.shape();
    if shape.len() != 2 || shape[0] != shape[1] {
        return Err(format!(
            "lu_decompose: expected square 2D matrix, got shape {:?}",
            shape
        ));
    }
    let n = shape[0];
    if n == 0 {
        return Ok(LuDecomp {
            lu_data: vec![],
            perm: vec![],
            n: 0,
            det_sign: 1,
        });
    }
    let mut buf: Vec<f64> = (0..n * n).map(|i| a.get_f64(i)).collect();
    let mut perm: Vec<usize> = (0..n).collect();
    let mut det_sign = 1i32;
    for col in 0..n {
        let pivot_row = (col..n)
            .max_by(|&r1, &r2| {
                buf[r1 * n + col]
                    .abs()
                    .partial_cmp(&buf[r2 * n + col].abs())
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .unwrap();
        if pivot_row != col {
            for k in 0..n {
                buf.swap(pivot_row * n + k, col * n + k);
            }
            perm.swap(pivot_row, col);
            det_sign = -det_sign;
        }
        let pivot = buf[col * n + col];
        if pivot.abs() < 1e-14 {
            continue;
        }
        for row in (col + 1)..n {
            let factor = buf[row * n + col] / pivot;
            buf[row * n + col] = factor;
            for k in (col + 1)..n {
                buf[row * n + k] -= factor * buf[col * n + k];
            }
        }
    }
    Ok(LuDecomp {
        lu_data: buf,
        perm,
        n,
        det_sign,
    })
}
#[allow(clippy::needless_range_loop)]
pub fn eigenvalue_power(a: &NdArray, max_iter: u32, tol: f64) -> Result<(f64, Vec<f64>), String> {
    let shape = a.shape();
    if shape.len() != 2 || shape[0] != shape[1] {
        return Err(format!(
            "eigenvalue_power: expected square 2D matrix, got shape {:?}",
            shape
        ));
    }
    let n = shape[0];
    if n == 0 {
        return Err("eigenvalue_power: matrix is empty".to_string());
    }
    let iters = if max_iter == 0 { 1000 } else { max_iter };
    let epsilon = if tol <= 0.0 { 1e-10 } else { tol };
    let mut v: Vec<f64> = (0..n).map(|i| if i == 0 { 1.0 } else { 0.0 }).collect();
    let mut eigenvalue = 0.0_f64;
    for _ in 0..iters {
        let mut w = vec![0.0_f64; n];
        for row in 0..n {
            for col in 0..n {
                w[row] += a.get_f64(row * n + col) * v[col];
            }
        }
        let new_lambda: f64 = v.iter().zip(w.iter()).map(|(vi, wi)| vi * wi).sum();
        let norm: f64 = w.iter().map(|x| x * x).sum::<f64>().sqrt();
        if norm < 1e-14 {
            break;
        }
        for x in w.iter_mut() {
            *x /= norm;
        }
        let delta = (new_lambda - eigenvalue).abs();
        eigenvalue = new_lambda;
        v = w;
        if delta < epsilon {
            break;
        }
    }
    Ok((eigenvalue, v))
}
