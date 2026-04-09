//! 2D spatial operations and linear algebra for NdArray.
//!
//! This module is part of Lurek2D's `compute` subsystem and provides the implementation
//! details for spatial-related operations and data management.
//! Primary functions: `convolve2d()`, `dilate()`, `erode()`, `flood_fill()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::VecDeque;

use crate::compute::array::{DataType, NdArray};

/// 2D convolution with zero-padding (same-size output).
///
/// # Parameters
/// - `input` — `&NdArray`.
/// - `kernel` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// The kernel center is at `(kR/2, kC/2)`. Both input and kernel must
/// be 2D arrays. Output shape equals input shape.
pub fn convolve2d(input: &NdArray, kernel: &NdArray) -> Result<NdArray, String> {
    if input.ndim() != 2 {
        return Err(format!(
            "convolve2d: input must be 2D, got {}D",
            input.ndim()
        ));
    }
    if kernel.ndim() != 2 {
        return Err(format!(
            "convolve2d: kernel must be 2D, got {}D",
            kernel.ndim()
        ));
    }

    let in_rows = input.shape()[0];
    let in_cols = input.shape()[1];
    let k_rows = kernel.shape()[0];
    let k_cols = kernel.shape()[1];
    let kr_half = k_rows / 2;
    let kc_half = k_cols / 2;

    let mut out = NdArray::zeros(&[in_rows, in_cols], input.dtype())?;

    for r in 0..in_rows {
        for c in 0..in_cols {
            let mut acc = 0.0f64;
            for kr in 0..k_rows {
                for kc in 0..k_cols {
                    let ir = r as isize + kr as isize - kr_half as isize;
                    let ic = c as isize + kc as isize - kc_half as isize;
                    if ir >= 0 && ir < in_rows as isize && ic >= 0 && ic < in_cols as isize {
                        let in_val = input.get_f64(
                            input
                                .flat_index(&[ir as usize, ic as usize])
                                .expect("index in bounds"),
                        );
                        let k_val =
                            kernel.get_f64(kernel.flat_index(&[kr, kc]).expect("index in bounds"));
                        acc += in_val * k_val;
                    }
                }
            }
            out.set_f64(out.flat_index(&[r, c]).expect("index in bounds"), acc);
        }
    }

    Ok(out)
}

/// Morphological dilation with a Manhattan-diamond structuring element.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `radius` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// For each cell, output is 1.0 if any cell within Manhattan distance `radius`
/// is non-zero in the input, 0.0 otherwise. Input must be 2D.
pub fn dilate(a: &NdArray, radius: usize) -> Result<NdArray, String> {
    if a.ndim() != 2 {
        return Err(format!("dilate: input must be 2D, got {}D", a.ndim()));
    }
    let rows = a.shape()[0];
    let cols = a.shape()[1];
    let mut out = NdArray::zeros(&[rows, cols], a.dtype())?;

    for r in 0..rows {
        for c in 0..cols {
            let mut found = false;
            let r_min = r.saturating_sub(radius);
            let r_max = (r + radius).min(rows - 1);
            for dr in r_min..=r_max {
                let remaining = radius - r.abs_diff(dr);
                let c_min = c.saturating_sub(remaining);
                let c_max = (c + remaining).min(cols - 1);
                for dc in c_min..=c_max {
                    if a.get_f64(a.flat_index(&[dr, dc]).expect("index in bounds")) != 0.0 {
                        found = true;
                        break;
                    }
                }
                if found {
                    break;
                }
            }
            if found {
                out.set_f64(out.flat_index(&[r, c]).expect("index in bounds"), 1.0);
            }
        }
    }

    Ok(out)
}

/// Morphological erosion with a Manhattan-diamond structuring element.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `radius` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// For each cell, output is 1.0 only if all cells within Manhattan distance
/// `radius` are non-zero in the input, 0.0 otherwise. Input must be 2D.
pub fn erode(a: &NdArray, radius: usize) -> Result<NdArray, String> {
    if a.ndim() != 2 {
        return Err(format!("erode: input must be 2D, got {}D", a.ndim()));
    }
    let rows = a.shape()[0];
    let cols = a.shape()[1];
    let mut out = NdArray::zeros(&[rows, cols], a.dtype())?;

    for r in 0..rows {
        for c in 0..cols {
            let mut all_nonzero = true;
            let ri = r as isize;
            let ci = c as isize;
            let rad = radius as isize;
            'outer: for dr in -rad..=rad {
                let remaining = rad - dr.abs();
                for dc in -remaining..=remaining {
                    let nr = ri + dr;
                    let nc = ci + dc;
                    if nr < 0 || nr >= rows as isize || nc < 0 || nc >= cols as isize {
                        all_nonzero = false;
                        break 'outer;
                    }
                    if a.get_f64(
                        a.flat_index(&[nr as usize, nc as usize])
                            .expect("index in bounds"),
                    ) == 0.0
                    {
                        all_nonzero = false;
                        break 'outer;
                    }
                }
            }
            if all_nonzero {
                out.set_f64(out.flat_index(&[r, c]).expect("index in bounds"), 1.0);
            }
        }
    }

    Ok(out)
}

/// Flood fill using BFS with 4-connectivity.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `row` — `usize`.
/// - `col` — `usize`.
/// - `val` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// Starting from `(row, col)`, fills all connected cells that have the same
/// value as the starting cell with `val`. Returns a new array (does not
/// mutate the original). Indices are 0-based.
pub fn flood_fill(a: &NdArray, row: usize, col: usize, val: f64) -> Result<NdArray, String> {
    if a.ndim() != 2 {
        return Err(format!("flood_fill: input must be 2D, got {}D", a.ndim()));
    }
    let rows = a.shape()[0];
    let cols = a.shape()[1];
    if row >= rows || col >= cols {
        return Err(format!(
            "flood_fill: ({row}, {col}) out of bounds for shape ({rows}, {cols})"
        ));
    }

    let mut out = a.clone();
    let target = out.get_f64(out.flat_index(&[row, col]).expect("index in bounds"));

    // If fill value equals target, nothing to do.
    if (target - val).abs() < f64::EPSILON {
        return Ok(out);
    }

    let mut queue = VecDeque::new();
    queue.push_back((row, col));
    out.set_f64(out.flat_index(&[row, col]).expect("index in bounds"), val);

    while let Some((r, c)) = queue.pop_front() {
        let neighbors: [(isize, isize); 4] = [(-1, 0), (1, 0), (0, -1), (0, 1)];
        for (dr, dc) in neighbors {
            let nr = r as isize + dr;
            let nc = c as isize + dc;
            if nr >= 0 && nr < rows as isize && nc >= 0 && nc < cols as isize {
                let nr = nr as usize;
                let nc = nc as usize;
                let idx = out.flat_index(&[nr, nc]).expect("index in bounds");
                if (out.get_f64(idx) - target).abs() < f64::EPSILON {
                    out.set_f64(idx, val);
                    queue.push_back((nr, nc));
                }
            }
        }
    }

    Ok(out)
}

/// Extract a rectangular sub-region from a 2D array.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `row` — `usize`.
/// - `col` — `usize`.
/// - `sub_rows` — `usize`.
/// - `sub_cols` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// Returns a new 2D array of shape `(sub_rows, sub_cols)` starting at `(row, col)`.
/// All indices are 0-based.
pub fn get_region(
    a: &NdArray,
    row: usize,
    col: usize,
    sub_rows: usize,
    sub_cols: usize,
) -> Result<NdArray, String> {
    if a.ndim() != 2 {
        return Err(format!("get_region: input must be 2D, got {}D", a.ndim()));
    }
    let rows = a.shape()[0];
    let cols = a.shape()[1];
    if row + sub_rows > rows || col + sub_cols > cols {
        return Err(format!(
            "get_region: region ({row},{col})+({sub_rows},{sub_cols}) exceeds bounds ({rows},{cols})"
        ));
    }
    if sub_rows == 0 || sub_cols == 0 {
        return Err("get_region: sub-region must have positive dimensions".to_string());
    }

    let mut out = NdArray::zeros(&[sub_rows, sub_cols], a.dtype())?;
    for r in 0..sub_rows {
        for c in 0..sub_cols {
            let src = a.flat_index(&[row + r, col + c]).expect("index in bounds");
            let dst = out.flat_index(&[r, c]).expect("index in bounds");
            out.set_f64(dst, a.get_f64(src));
        }
    }
    Ok(out)
}

/// Copy a source 2D array into a target 2D array at position `(row, col)`.
///
/// # Parameters
/// - `a` — `&mut NdArray`.
/// - `row` — `usize`.
/// - `col` — `usize`.
/// - `src` — `&NdArray`.
///
/// # Returns
/// `Result<(), String>`.
///
/// Modifies `a` in-place. All indices are 0-based.
pub fn set_region(a: &mut NdArray, row: usize, col: usize, src: &NdArray) -> Result<(), String> {
    if a.ndim() != 2 {
        return Err(format!("set_region: target must be 2D, got {}D", a.ndim()));
    }
    if src.ndim() != 2 {
        return Err(format!(
            "set_region: source must be 2D, got {}D",
            src.ndim()
        ));
    }
    let rows = a.shape()[0];
    let cols = a.shape()[1];
    let sr = src.shape()[0];
    let sc = src.shape()[1];
    if row + sr > rows || col + sc > cols {
        return Err(format!(
            "set_region: region ({row},{col})+({sr},{sc}) exceeds bounds ({rows},{cols})"
        ));
    }

    for r in 0..sr {
        for c in 0..sc {
            let s_idx = src.flat_index(&[r, c]).expect("index in bounds");
            let d_idx = a.flat_index(&[row + r, col + c]).expect("index in bounds");
            a.set_f64(d_idx, src.get_f64(s_idx));
        }
    }
    Ok(())
}

/// Matrix multiplication of two 2D arrays: (m,k) × (k,n) → (m,n).
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// Uses a naive triple loop. Both arrays must be 2D with compatible inner dimensions.
pub fn matmul(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    if a.ndim() != 2 {
        return Err(format!(
            "matmul: first operand must be 2D, got {}D",
            a.ndim()
        ));
    }
    if b.ndim() != 2 {
        return Err(format!(
            "matmul: second operand must be 2D, got {}D",
            b.ndim()
        ));
    }
    let m = a.shape()[0];
    let k_a = a.shape()[1];
    let k_b = b.shape()[0];
    let n = b.shape()[1];
    if k_a != k_b {
        return Err(format!(
            "matmul: inner dimensions mismatch: ({m},{k_a}) × ({k_b},{n})"
        ));
    }

    let out_dtype = if a.dtype() == DataType::Float64 || b.dtype() == DataType::Float64 {
        DataType::Float64
    } else {
        a.dtype()
    };

    let mut out = NdArray::zeros(&[m, n], out_dtype)?;
    for i in 0..m {
        for j in 0..n {
            let mut acc = 0.0f64;
            for k in 0..k_a {
                acc += a.get_f64(a.flat_index(&[i, k]).expect("index in bounds"))
                    * b.get_f64(b.flat_index(&[k, j]).expect("index in bounds"));
            }
            out.set_f64(out.flat_index(&[i, j]).expect("index in bounds"), acc);
        }
    }
    Ok(out)
}

/// Dot product of two 1D arrays (same length). Returns a scalar.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<f64, String>`.
pub fn dot(a: &NdArray, b: &NdArray) -> Result<f64, String> {
    if a.ndim() != 1 {
        return Err(format!("dot: first operand must be 1D, got {}D", a.ndim()));
    }
    if b.ndim() != 1 {
        return Err(format!("dot: second operand must be 1D, got {}D", b.ndim()));
    }
    if a.shape()[0] != b.shape()[0] {
        return Err(format!(
            "dot: length mismatch: {} vs {}",
            a.shape()[0],
            b.shape()[0]
        ));
    }

    let mut acc = 0.0f64;
    for i in 0..a.shape()[0] {
        acc += a.get_f64(i) * b.get_f64(i);
    }
    Ok(acc)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn arr_2d(vals: &[f64], rows: usize, cols: usize) -> NdArray {
        NdArray::from_slice(vals, &[rows, cols], DataType::Float32).unwrap()
    }

    fn arr_1d(vals: &[f64]) -> NdArray {
        NdArray::from_slice(vals, &[vals.len()], DataType::Float32).unwrap()
    }

    #[test]
    fn test_convolve2d_identity() {
        // Identity kernel: [[0,0,0],[0,1,0],[0,0,0]]
        let input = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0], 3, 3);
        let kernel = arr_2d(&[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
        let out = convolve2d(&input, &kernel).unwrap();
        for i in 0..9 {
            assert!((out.get_f64(i) - input.get_f64(i)).abs() < 1e-5);
        }
    }

    #[test]
    fn test_convolve2d_blur() {
        // Simple average kernel
        let input = arr_2d(&[0.0, 0.0, 0.0, 0.0, 9.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
        let kernel = arr_2d(&[1.0 / 9.0; 9], 3, 3);
        let out = convolve2d(&input, &kernel).unwrap();
        // Center should be 9/9 = 1.0
        assert!((out.get_f64(4) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_dilate() {
        let input = arr_2d(
            &[
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            ],
            5,
            5,
        );
        let out = dilate(&input, 1).unwrap();
        // Center and 4-neighbors should be 1.0
        assert!(
            (out.get_f64(out.flat_index(&[2, 2]).expect("index in bounds")) - 1.0).abs() < 1e-5
        );
        assert!(
            (out.get_f64(out.flat_index(&[1, 2]).expect("index in bounds")) - 1.0).abs() < 1e-5
        );
        assert!(
            (out.get_f64(out.flat_index(&[3, 2]).expect("index in bounds")) - 1.0).abs() < 1e-5
        );
        assert!(
            (out.get_f64(out.flat_index(&[2, 1]).expect("index in bounds")) - 1.0).abs() < 1e-5
        );
        assert!(
            (out.get_f64(out.flat_index(&[2, 3]).expect("index in bounds")) - 1.0).abs() < 1e-5
        );
        // Corners should remain 0
        assert!(
            (out.get_f64(out.flat_index(&[0, 0]).expect("index in bounds")) - 0.0).abs() < 1e-5
        );
    }

    #[test]
    fn test_erode() {
        // 3x3 all ones → erode with radius 1 → only center survives
        let input = arr_2d(&[1.0; 9], 3, 3);
        let out = erode(&input, 1).unwrap();
        assert!(
            (out.get_f64(out.flat_index(&[1, 1]).expect("index in bounds")) - 1.0).abs() < 1e-5
        );
        // Edges should be 0 because the diamond extends beyond the array
        assert!(
            (out.get_f64(out.flat_index(&[0, 0]).expect("index in bounds")) - 0.0).abs() < 1e-5
        );
    }

    #[test]
    fn test_flood_fill() {
        let input = arr_2d(&[1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
        let out = flood_fill(&input, 0, 0, 5.0).unwrap();
        assert!((out.get_f64(0) - 5.0).abs() < 1e-5);
        assert!((out.get_f64(1) - 5.0).abs() < 1e-5);
        assert!((out.get_f64(3) - 5.0).abs() < 1e-5);
        assert!((out.get_f64(4) - 5.0).abs() < 1e-5);
        // The 0-region should remain 0
        assert!((out.get_f64(2) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_get_set_region() {
        let a = arr_2d(
            &[
                1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0,
            ],
            3,
            4,
        );
        let sub = get_region(&a, 0, 1, 2, 2).unwrap();
        assert_eq!(sub.shape(), &[2, 2]);
        assert!((sub.get_f64(0) - 2.0).abs() < 1e-5);
        assert!((sub.get_f64(1) - 3.0).abs() < 1e-5);
        assert!((sub.get_f64(2) - 6.0).abs() < 1e-5);
        assert!((sub.get_f64(3) - 7.0).abs() < 1e-5);

        let mut target = NdArray::zeros(&[3, 4], DataType::Float32).unwrap();
        let patch = arr_2d(&[99.0, 88.0, 77.0, 66.0], 2, 2);
        set_region(&mut target, 1, 2, &patch).unwrap();
        assert!(
            (target.get_f64(target.flat_index(&[1, 2]).expect("index in bounds")) - 99.0).abs()
                < 1e-5
        );
        assert!(
            (target.get_f64(target.flat_index(&[2, 3]).expect("index in bounds")) - 66.0).abs()
                < 1e-5
        );
    }

    #[test]
    fn test_matmul() {
        // [1 2] × [5 6] = [1*5+2*7  1*6+2*8] = [19 22]
        // [3 4]   [7 8]   [3*5+4*7  3*6+4*8]   [43 50]
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
        let b = arr_2d(&[5.0, 6.0, 7.0, 8.0], 2, 2);
        let c = matmul(&a, &b).unwrap();
        assert_eq!(c.shape(), &[2, 2]);
        assert!((c.get_f64(0) - 19.0).abs() < 1e-5);
        assert!((c.get_f64(1) - 22.0).abs() < 1e-5);
        assert!((c.get_f64(2) - 43.0).abs() < 1e-5);
        assert!((c.get_f64(3) - 50.0).abs() < 1e-5);
    }

    #[test]
    fn test_matmul_nonsquare() {
        // (2,3) × (3,2) → (2,2)
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
        let b = arr_2d(&[7.0, 8.0, 9.0, 10.0, 11.0, 12.0], 3, 2);
        let c = matmul(&a, &b).unwrap();
        assert_eq!(c.shape(), &[2, 2]);
        // [1*7+2*9+3*11, 1*8+2*10+3*12] = [58, 64]
        assert!((c.get_f64(0) - 58.0).abs() < 1e-5);
        assert!((c.get_f64(1) - 64.0).abs() < 1e-5);
    }

    #[test]
    fn test_dot() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let b = arr_1d(&[4.0, 5.0, 6.0]);
        let d = dot(&a, &b).unwrap();
        assert!((d - 32.0).abs() < 1e-5);
    }

    #[test]
    fn test_dot_length_mismatch() {
        let a = arr_1d(&[1.0, 2.0]);
        let b = arr_1d(&[1.0, 2.0, 3.0]);
        assert!(dot(&a, &b).is_err());
    }

    #[test]
    fn test_matmul_dim_mismatch() {
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
        let b = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 3, 2);
        assert!(matmul(&a, &b).is_err());
    }

    #[test]
    fn test_flood_fill_out_of_bounds() {
        let input = arr_2d(&[1.0; 4], 2, 2);
        assert!(flood_fill(&input, 5, 0, 1.0).is_err());
    }

    #[test]
    fn test_get_region_out_of_bounds() {
        let a = arr_2d(&[1.0; 4], 2, 2);
        assert!(get_region(&a, 1, 1, 2, 2).is_err());
    }
}
