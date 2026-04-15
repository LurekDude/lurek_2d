//! Linear algebra extensions for NdArray.
//!
//! Provides vector and matrix utilities beyond the 2D spatial ops in `spatial.rs`.
//! All functions are **Foundations-tier** — no imports from Core Runtime or higher.
//!
//! Key functions: `linsolve`, `normalize_vec`, `cross2d`, `outer`, `rotate2d_matrix`,
//! `affine2d`, `transform_points`, `gaussian_kernel`, `sobel`.

use crate::compute::array::{DataType, NdArray};

// ---------------------------------------------------------------------------
// Vector utilities
// ---------------------------------------------------------------------------

/// L2-normalise a 1D vector.
///
/// Returns an `Err` if the vector has zero length.
///
/// # Parameters
/// - `v` — `&NdArray` 1D vector.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// 2D cross product (returns signed scalar area of the parallelogram).
///
/// `cross2d([ax, ay], [bx, by]) = ax*by - ay*bx`.
///
/// # Parameters
/// - `a` — `&NdArray` 1D array of length 2.
/// - `b` — `&NdArray` 1D array of length 2.
///
/// # Returns
/// `Result<f64, String>`.
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

/// Outer product of two 1D vectors: result shape is [m, n].
///
/// # Parameters
/// - `a` — `&NdArray` 1D vector of length m.
/// - `b` — `&NdArray` 1D vector of length n.
///
/// # Returns
/// `Result<NdArray, String>`.
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

// ---------------------------------------------------------------------------
// 2D transform matrices
// ---------------------------------------------------------------------------

/// Build a 2×2 rotation matrix for `angle_rad` radians.
///
/// ```text
/// [ cos θ  -sin θ ]
/// [ sin θ   cos θ ]
/// ```
///
/// # Parameters
/// - `angle_rad` — `f64` rotation angle in radians.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn rotate2d_matrix(angle_rad: f64) -> Result<NdArray, String> {
    let (s, c) = angle_rad.sin_cos();
    let vals = [c, -s, s, c];
    NdArray::from_slice(&vals, &[2, 2], DataType::Float64)
}

/// Build a 3×3 homogeneous affine matrix combining translation, rotation, and scale.
///
/// ```text
/// [ sx*cos θ  -sy*sin θ  tx ]
/// [ sx*sin θ   sy*cos θ  ty ]
/// [    0          0       1 ]
/// ```
///
/// # Parameters
/// - `tx`        — `f64` x translation.
/// - `ty`        — `f64` y translation.
/// - `angle_rad` — `f64` rotation angle in radians.
/// - `sx`        — `f64` x scale factor.
/// - `sy`        — `f64` y scale factor.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn affine2d(tx: f64, ty: f64, angle_rad: f64, sx: f64, sy: f64) -> Result<NdArray, String> {
    let (s, c) = angle_rad.sin_cos();
    let vals = [
        sx * c, -sy * s, tx,
        sx * s,  sy * c, ty,
        0.0,     0.0,    1.0,
    ];
    NdArray::from_slice(&vals, &[3, 3], DataType::Float64)
}

/// Apply a 2×2 or 3×3 (homogeneous) matrix to a list of 2D points.
///
/// `points` must be a 2D array of shape [N, 2].
/// `matrix` must be a 2×2 or 3×3 float array.
///
/// Returns a [N, 2] array.
///
/// # Parameters
/// - `matrix` — `&NdArray` shape [2,2] or [3,3].
/// - `points` — `&NdArray` shape [N, 2].
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn transform_points(matrix: &NdArray, points: &NdArray) -> Result<NdArray, String> {
    if points.ndim() != 2 || points.shape()[1] != 2 {
        return Err(format!(
            "transform_points: points must be [N,2], got {:?}",
            points.shape()
        ));
    }
    let n = points.shape()[0];
    let ms = matrix.shape();
    let is3x3 = ms == &[3, 3];
    let is2x2 = ms == &[2, 2];
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
            // 3×3 homogeneous — normalise by w
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

// ---------------------------------------------------------------------------
// Kernel generators
// ---------------------------------------------------------------------------

/// Generate a `size × size` Gaussian kernel with the given `sigma`.
///
/// `size` must be odd and ≥ 1. The kernel is normalised to sum to 1.0.
///
/// # Parameters
/// - `size`  — `usize` odd dimension of the square kernel.
/// - `sigma` — `f64` standard deviation.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn gaussian_kernel(size: usize, sigma: f64) -> Result<NdArray, String> {
    if size == 0 {
        return Err("gaussian_kernel: size must be ≥ 1".to_string());
    }
    if size % 2 == 0 {
        return Err(format!(
            "gaussian_kernel: size must be odd, got {size}"
        ));
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
    // Normalise
    let sum: f64 = vals.iter().sum();
    for v in &mut vals {
        *v /= sum;
    }
    NdArray::from_slice(&vals, &[size, size], DataType::Float64)
}

// ---------------------------------------------------------------------------
// Sobel edge detection
// ---------------------------------------------------------------------------

/// Apply Sobel edge detection to a 2D Float32/Float64 array.
///
/// Returns `(Gx, Gy)` — two arrays the same shape as the input,
/// representing horizontal and vertical gradients.
///
/// # Parameters
/// - `input` — `&NdArray` 2D array.
///
/// # Returns
/// `Result<(NdArray, NdArray), String>`.
pub fn sobel(input: &NdArray) -> Result<(NdArray, NdArray), String> {
    if input.ndim() != 2 {
        return Err(format!(
            "sobel: expected 2D array, got {}D",
            input.ndim()
        ));
    }
    let rows = input.shape()[0];
    let cols = input.shape()[1];

    // Sobel kernels
    // Gx: [[-1,0,1],[-2,0,2],[-1,0,1]]
    // Gy: [[-1,-2,-1],[0,0,0],[1,2,1]]
    let kx: [[f64; 3]; 3] = [[-1.0, 0.0, 1.0], [-2.0, 0.0, 2.0], [-1.0, 0.0, 1.0]];
    let ky: [[f64; 3]; 3] = [[-1.0, -2.0, -1.0], [0.0, 0.0, 0.0], [1.0, 2.0, 1.0]];

    let mut gx = NdArray::zeros(&[rows, cols], input.dtype())?;
    let mut gy = NdArray::zeros(&[rows, cols], input.dtype())?;

    for r in 0..rows {
        for c in 0..cols {
            let mut sx = 0.0_f64;
            let mut sy = 0.0_f64;
            for kr in 0..3_usize {
                for kc in 0..3_usize {
                    let row = r as isize + kr as isize - 1;
                    let col = c as isize + kc as isize - 1;
                    if row >= 0 && row < rows as isize && col >= 0 && col < cols as isize {
                        let v = input
                            .get_f64(input.flat_index(&[row as usize, col as usize]).unwrap());
                        sx += v * kx[kr][kc];
                        sy += v * ky[kr][kc];
                    }
                }
            }
            let flat = gx.flat_index(&[r, c]).unwrap();
            gx.set_f64(flat, sx);
            gy.set_f64(flat, sy);
        }
    }
    Ok((gx, gy))
}

// ---------------------------------------------------------------------------
// Linear solver
// ---------------------------------------------------------------------------

/// Solve the linear system A·x = b using Gaussian elimination with partial pivoting.
///
/// `a` must be a square [n×n] matrix; `b` must be a 1D vector of length n.
/// Returns `x` as a 1D vector of length n.
///
/// Returns `Err` if the matrix is singular (or near-singular by zero pivot).
///
/// # Parameters
/// - `a` — `&NdArray` shape [n, n].
/// - `b` — `&NdArray` shape [n].
///
/// # Returns
/// `Result<NdArray, String>`.
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

    // Build augmented matrix [A|b] as a flat Vec
    let mut mat: Vec<Vec<f64>> = (0..n)
        .map(|r| {
            let mut row: Vec<f64> = (0..n)
                .map(|c| a.get_f64(a.flat_index(&[r, c]).unwrap()))
                .collect();
            row.push(b.get_f64(r));
            row
        })
        .collect();

    // Forward elimination with partial pivoting
    for col in 0..n {
        // Find pivot
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

    // Back substitution
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

// ---------------------------------------------------------------------------
// LU Decomposition
// ---------------------------------------------------------------------------

/// Result of an LU decomposition with partial pivoting.
///
/// Stores the combined L and U factors as a flat row-major n×n buffer:
/// - the unit lower-triangular factor L occupies the strictly lower triangle,
/// - the upper-triangular factor U occupies the upper triangle and diagonal.
///
/// # Fields
/// - `lu_data` — flat n×n combined LU buffer.
/// - `perm` — row permutation applied during pivoting.
/// - `n` — dimension of the square matrix.
/// - `det_sign` — sign of the determinant (+1 or −1).
#[derive(Debug, Clone)]
pub struct LuDecomp {
    /// Combined L/U flat buffer (row-major, n×n).
    pub lu_data: Vec<f64>,
    /// Row permutation from partial pivoting.
    pub perm: Vec<usize>,
    /// Matrix dimension (n).
    pub n: usize,
    /// Sign of the determinant produced by the pivot sequence (+1 or −1).
    pub det_sign: i32,
}

/// Decomposes a square matrix `a` into P·A = L·U using partial pivoting.
///
/// The unit lower-triangular factor L (diagonal 1s, not stored) and upper-
/// triangular factor U are written into a single n×n buffer returned inside
/// [`LuDecomp`].
///
/// # Parameters
/// - `a` — a square 2D [`NdArray`] of shape `[n, n]`.
///
/// # Returns
/// `Result<LuDecomp, String>`.
///
/// # Design Rationale
/// Partial pivoting ensures numerical stability for near-singular matrices
/// that can realistically appear in game AI or physics calculations. The
/// combined LU buffer avoids two separate allocations.
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

    // Copy A into a mutable flat row-major buffer.
    let mut buf: Vec<f64> = (0..n * n).map(|i| a.get_f64(i)).collect();
    let mut perm: Vec<usize> = (0..n).collect();
    let mut det_sign = 1i32;

    for col in 0..n {
        // Find pivot (max absolute value in this column, rows col..n).
        let pivot_row = (col..n)
            .max_by(|&r1, &r2| {
                buf[r1 * n + col]
                    .abs()
                    .partial_cmp(&buf[r2 * n + col].abs())
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .unwrap();

        if pivot_row != col {
            // Swap rows.
            for k in 0..n {
                buf.swap(pivot_row * n + k, col * n + k);
            }
            perm.swap(pivot_row, col);
            det_sign = -det_sign;
        }

        let pivot = buf[col * n + col];
        if pivot.abs() < 1e-14 {
            // Singular — continue anyway (det will be ~0).
            continue;
        }

        // Eliminate below pivot.
        for row in (col + 1)..n {
            let factor = buf[row * n + col] / pivot;
            buf[row * n + col] = factor; // Store L multiplier in lower triangle.
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

// ---------------------------------------------------------------------------
// Power-Iteration Eigenvalue
// ---------------------------------------------------------------------------

/// Computes the dominant eigenvalue and its eigenvector of a square matrix
/// using the power-iteration method.
///
/// Converges to the eigenvalue with the largest absolute value. The returned
/// eigenvector is L2-normalised.
///
/// # Parameters
/// - `a`        — square 2D [`NdArray`] of shape `[n, n]`.
/// - `max_iter` — maximum iterations (default 1000 if 0).
/// - `tol`      — convergence tolerance (default 1e-10 if 0.0).
///
/// # Returns
/// `Result<(f64, Vec<f64>), String>` — dominant eigenvalue and eigenvector.
///
/// # Design Rationale
/// Power iteration is simple, allocation-efficient, and good enough for
/// game AI influence maps and graph centrality — which rarely need more
/// than the dominant mode. The caller controls iteration budget via
/// `max_iter` and `tol`.
pub fn eigenvalue_power(
    a: &NdArray,
    max_iter: u32,
    tol: f64,
) -> Result<(f64, Vec<f64>), String> {
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

    // Start with unit vector v = [1, 0, 0, …].
    let mut v: Vec<f64> = (0..n).map(|i| if i == 0 { 1.0 } else { 0.0 }).collect();
    let mut eigenvalue = 0.0_f64;

    for _ in 0..iters {
        // w = A · v
        let mut w = vec![0.0_f64; n];
        for row in 0..n {
            for col in 0..n {
                w[row] += a.get_f64(row * n + col) * v[col];
            }
        }

        // λ = v^T w  (Rayleigh quotient)
        let new_lambda: f64 = v.iter().zip(w.iter()).map(|(vi, wi)| vi * wi).sum();

        // Normalise w.
        let norm: f64 = w.iter().map(|x| x * x).sum::<f64>().sqrt();
        if norm < 1e-14 {
            break; // Zero vector — all eigenvalues ≈ 0.
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn arr(vals: &[f64], shape: &[usize]) -> NdArray {
        NdArray::from_slice(vals, shape, DataType::Float64).unwrap()
    }

    #[test]
    fn normalize_vec_unit_result() {
        let v = arr(&[3.0, 4.0], &[2]);
        let n = normalize_vec(&v).unwrap();
        assert!((n.get_f64(0) - 0.6).abs() < 1e-5);
        assert!((n.get_f64(1) - 0.8).abs() < 1e-5);
    }

    #[test]
    fn cross2d_basic() {
        let a = arr(&[1.0, 0.0], &[2]);
        let b = arr(&[0.0, 1.0], &[2]);
        assert!((cross2d(&a, &b).unwrap() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn outer_product_shape() {
        let a = arr(&[1.0, 2.0], &[2]);
        let b = arr(&[3.0, 4.0, 5.0], &[3]);
        let o = outer(&a, &b).unwrap();
        assert_eq!(o.shape(), &[2, 3]);
        // [0,0] = 1*3 = 3
        assert!((o.get_f64(o.flat_index(&[0, 0]).unwrap()) - 3.0).abs() < 1e-5);
        // [1,2] = 2*5 = 10
        assert!((o.get_f64(o.flat_index(&[1, 2]).unwrap()) - 10.0).abs() < 1e-5);
    }

    #[test]
    fn rotate2d_matrix_90deg() {
        let m = rotate2d_matrix(std::f64::consts::PI / 2.0).unwrap();
        // Rotate [1, 0] by 90° → [0, 1]
        let pts = arr(&[1.0, 0.0], &[1, 2]);
        let out = transform_points(&m, &pts).unwrap();
        assert!(out.get_f64(out.flat_index(&[0, 0]).unwrap()).abs() < 1e-5);
        assert!((out.get_f64(out.flat_index(&[0, 1]).unwrap()) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn gaussian_kernel_sums_to_one() {
        let k = gaussian_kernel(5, 1.0).unwrap();
        let s: f64 = (0..k.size()).map(|i| k.get_f64(i)).sum();
        assert!((s - 1.0).abs() < 1e-6);
    }

    #[test]
    fn linsolve_2x2() {
        // 2x + y = 5, x + 3y = 10 → x=1, y=3
        let a = arr(&[2.0, 1.0, 1.0, 3.0], &[2, 2]);
        let b = arr(&[5.0, 10.0], &[2]);
        let x = linsolve(&a, &b).unwrap();
        assert!((x.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((x.get_f64(1) - 3.0).abs() < 1e-5);
    }

    #[test]
    fn sobel_flat_input_zero_gradient() {
        let flat = NdArray::zeros(&[5, 5], DataType::Float64).unwrap();
        let (gx, gy) = sobel(&flat).unwrap();
        assert!((gx.get_f64(12) - 0.0).abs() < 1e-5); // centre pixel
        assert!((gy.get_f64(12) - 0.0).abs() < 1e-5);
    }
}
