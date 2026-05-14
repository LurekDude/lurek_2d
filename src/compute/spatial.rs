use crate::compute::array::{DataType, NdArray};
use std::collections::VecDeque;

/// Convolve 2D input with 2D kernel and return same-sized output array.
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
/// Apply binary dilation with Manhattan radius and return dilated mask array.
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
/// Apply binary erosion with Manhattan radius and return eroded mask array.
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
/// Flood fill from seed coordinate and return array with replaced connected region.
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
/// Copy a 2D sub-region and return extracted array of requested size.
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
/// Write source 2D region into target array and return success or bounds error.
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
/// Multiply two 2D matrices and return matrix product array.
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
            "matmul: inner dimensions mismatch: ({m},{k_a}) x ({k_b},{n})"
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
/// Compute dot product of two 1D vectors and return scalar sum.
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
