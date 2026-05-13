//! Element-wise, reduction, comparison, masking, shape, and bitwise helpers on NdArray.

use crate::compute::array::{DataType, NdArray};
use rayon::prelude::*;
use std::sync::OnceLock;
use std::sync::{Arc, Mutex};

/// Configurable parallelization threshold for element-wise and reduction ops.
/// Element count above this threshold uses Rayon thread pool; below uses serial computation.
static PAR_THRESHOLD_CONFIG: OnceLock<Arc<Mutex<usize>>> = OnceLock::new();

// ---- Helper Functions: Parallelization Config ----

fn get_par_threshold_config() -> &'static Arc<Mutex<usize>> {
    PAR_THRESHOLD_CONFIG.get_or_init(|| Arc::new(Mutex::new(10_000)))
}

/// Get the current parallel threshold in elements; default is 10,000.
pub fn get_par_threshold() -> usize {
    *get_par_threshold_config().lock().unwrap()
}

/// Set the parallel threshold in elements and return the previous value; clamp values below 1 to 1.
pub fn set_par_threshold(threshold: usize) -> usize {
    let mut config = get_par_threshold_config().lock().unwrap();
    let prev = *config;
    *config = threshold.max(1); // Ensure minimum value of 1
    prev
}

// ---- Helper Functions: Helpers ----

/// Run an index-based operation either serially or with Rayon above the threshold.
fn dispatch_parallel(size: usize, op: impl Fn(usize) -> f64 + Sync + Send) -> Vec<f64> {
    if size > get_par_threshold() {
        (0..size).into_par_iter().map(op).collect()
    } else {
        (0..size).map(op).collect()
    }
}

/// Check that two arrays share shape and dtype for element-wise ops.
fn check_same_shape_dtype(a: &NdArray, b: &NdArray) -> Result<(), String> {
    if a.shape() != b.shape() {
        return Err(format!(
            "shape mismatch: {:?} vs {:?}",
            a.shape(),
            b.shape()
        ));
    }
    if a.dtype() != b.dtype() {
        return Err(format!(
            "dtype mismatch: {} vs {}",
            a.dtype().name(),
            b.dtype().name()
        ));
    }
    Ok(())
}

/// Apply a binary op to matching arrays or supported row broadcasts and return the new array.
fn elementwise_binary(
    a: &NdArray,
    b: &NdArray,
    op: fn(f64, f64) -> f64,
) -> Result<NdArray, String> {
    if a.dtype() != b.dtype() {
        return Err(format!(
            "dtype mismatch: {} vs {}",
            a.dtype().name(),
            b.dtype().name()
        ));
    }

    // Fast path: identical shape.
    if a.shape() == b.shape() {
        let mut out = NdArray::zeros(a.shape(), a.dtype())?;
        let vals = dispatch_parallel(a.size(), |i| op(a.get_f64(i), b.get_f64(i)));
        for (i, v) in vals.into_iter().enumerate() {
            out.set_f64(i, v);
        }
        return Ok(out);
    }

    // Row broadcast: [rows, cols] OP [cols].
    if a.ndim() == 2 && b.ndim() == 1 && a.shape()[1] == b.shape()[0] {
        let rows = a.shape()[0];
        let cols = a.shape()[1];
        let mut out = NdArray::zeros(a.shape(), a.dtype())?;
        for r in 0..rows {
            for c in 0..cols {
                let af = a.flat_index(&[r, c]).expect("index in bounds");
                let of = out.flat_index(&[r, c]).expect("index in bounds");
                out.set_f64(of, op(a.get_f64(af), b.get_f64(c)));
            }
        }
        return Ok(out);
    }

    // Row broadcast: [cols] OP [rows, cols].
    if a.ndim() == 1 && b.ndim() == 2 && a.shape()[0] == b.shape()[1] {
        let rows = b.shape()[0];
        let cols = b.shape()[1];
        let mut out = NdArray::zeros(b.shape(), b.dtype())?;
        for r in 0..rows {
            for c in 0..cols {
                let bf = b.flat_index(&[r, c]).expect("index in bounds");
                let of = out.flat_index(&[r, c]).expect("index in bounds");
                out.set_f64(of, op(a.get_f64(c), b.get_f64(bf)));
            }
        }
        return Ok(out);
    }

    Err(format!(
        "shape mismatch: {:?} vs {:?}; expected equal shapes or 2D<->1D row broadcast",
        a.shape(),
        b.shape()
    ))
}

/// Apply a unary op to every element and return the new array.
fn elementwise_unary(a: &NdArray, op: fn(f64) -> f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    let vals = dispatch_parallel(a.size(), |i| op(a.get_f64(i)));
    for (i, v) in vals.into_iter().enumerate() {
        out.set_f64(i, v);
    }
    Ok(out)
}

/// Apply a binary op between each element and scalar s and return the new array.
fn elementwise_scalar(a: &NdArray, s: f64, op: fn(f64, f64) -> f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    let vals = dispatch_parallel(a.size(), |i| op(a.get_f64(i), s));
    for (i, v) in vals.into_iter().enumerate() {
        out.set_f64(i, v);
    }
    Ok(out)
}

/// Apply a binary op in place with equal shapes or [rows, cols] OP [cols] row broadcasting.
fn elementwise_binary_inplace(
    a: &mut NdArray,
    b: &NdArray,
    op: fn(f64, f64) -> f64,
) -> Result<(), String> {
    if a.dtype() != b.dtype() {
        return Err(format!(
            "dtype mismatch: {} vs {}",
            a.dtype().name(),
            b.dtype().name()
        ));
    }

    if a.shape() == b.shape() {
        for i in 0..a.size() {
            a.set_f64(i, op(a.get_f64(i), b.get_f64(i)));
        }
        return Ok(());
    }

    if a.ndim() == 2 && b.ndim() == 1 && a.shape()[1] == b.shape()[0] {
        let rows = a.shape()[0];
        let cols = a.shape()[1];
        for r in 0..rows {
            for c in 0..cols {
                let af = a.flat_index(&[r, c]).expect("index in bounds");
                a.set_f64(af, op(a.get_f64(af), b.get_f64(c)));
            }
        }
        return Ok(());
    }

    Err(format!(
        "shape mismatch: {:?} vs {:?}; expected equal shapes or [rows, cols] OP [cols]",
        a.shape(),
        b.shape()
    ))
}

/// Check that axis is within the array rank.
fn check_axis(a: &NdArray, axis: usize) -> Result<(), String> {
    if axis >= a.ndim() {
        return Err(format!(
            "axis {} out of bounds for array with {} dimensions",
            axis,
            a.ndim()
        ));
    }
    Ok(())
}

/// Check that the array dtype is Int32 for bitwise ops.
fn require_int32(a: &NdArray) -> Result<(), String> {
    if a.dtype() != DataType::Int32 {
        return Err(format!(
            "bitwise ops require int32 dtype, got {}",
            a.dtype().name()
        ));
    }
    Ok(())
}

// ---- Helper Functions: Element Wise Arithmetic ----

/// Add two arrays of the same shape and dtype and return the result array.
pub fn add(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x + y)
}

/// Add scalar s to every element and return the result array.
pub fn add_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x + y)
}

/// Subtract two arrays of the same shape and dtype and return the result array.
pub fn sub(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x - y)
}

/// Subtract scalar s from every element and return the result array.
pub fn sub_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x - y)
}

/// Multiply two arrays of the same shape and dtype and return the result array.
pub fn mul(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x * y)
}

/// Multiply every element by scalar s and return the result array.
pub fn mul_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x * y)
}

/// Divide two arrays of the same shape and dtype and return the result array.
pub fn div(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x / y)
}

/// Divide every element by scalar s and return the result array.
pub fn div_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x / y)
}

/// Raise every element to exponent exp and return the result array.
pub fn pow_scalar(a: &NdArray, exp: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, a.get_f64(i).powf(exp));
    }
    Ok(out)
}

/// Take the square root of every element and return the result array.
pub fn sqrt(a: &NdArray) -> Result<NdArray, String> {
    elementwise_unary(a, f64::sqrt)
}

/// Take the absolute value of every element and return the result array.
pub fn abs(a: &NdArray) -> Result<NdArray, String> {
    elementwise_unary(a, f64::abs)
}

/// Negate every element and return the result array.
pub fn neg(a: &NdArray) -> Result<NdArray, String> {
    elementwise_unary(a, |x| -x)
}

/// Clamp every element to [min_val, max_val] and return the result array.
pub fn clamp(a: &NdArray, min_val: f64, max_val: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, a.get_f64(i).clamp(min_val, max_val));
    }
    Ok(out)
}

// ---- Helper Functions: Comparison Operators ----

/// Compare two arrays element-wise for equality and return a Float32 0/1 mask.
pub fn eq(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        let v = if (a.get_f64(i) - b.get_f64(i)).abs() < f64::EPSILON {
            1.0
        } else {
            0.0
        };
        out.set_f64(i, v);
    }
    Ok(out)
}

/// Compare every element against scalar s for equality and return a Float32 0/1 mask.
pub fn eq_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        let v = if (a.get_f64(i) - s).abs() < f64::EPSILON {
            1.0
        } else {
            0.0
        };
        out.set_f64(i, v);
    }
    Ok(out)
}

/// Compare two arrays element-wise for inequality and return a Float32 0/1 mask.
pub fn neq(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        let v = if (a.get_f64(i) - b.get_f64(i)).abs() >= f64::EPSILON {
            1.0
        } else {
            0.0
        };
        out.set_f64(i, v);
    }
    Ok(out)
}

/// Compare every element against scalar s for inequality and return a Float32 0/1 mask.
pub fn neq_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        let v = if (a.get_f64(i) - s).abs() >= f64::EPSILON {
            1.0
        } else {
            0.0
        };
        out.set_f64(i, v);
    }
    Ok(out)
}

/// Compare two arrays element-wise with greater-than and return a Float32 0/1 mask.
pub fn gt(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(
            i,
            if a.get_f64(i) > b.get_f64(i) {
                1.0
            } else {
                0.0
            },
        );
    }
    Ok(out)
}

/// Compare every element against scalar s with greater-than and return a Float32 0/1 mask.
pub fn gt_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) > s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

/// Compare two arrays element-wise with less-than and return a Float32 0/1 mask.
pub fn lt(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(
            i,
            if a.get_f64(i) < b.get_f64(i) {
                1.0
            } else {
                0.0
            },
        );
    }
    Ok(out)
}

/// Compare every element against scalar s with less-than and return a Float32 0/1 mask.
pub fn lt_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) < s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

/// Compare two arrays element-wise with greater-than-or-equal and return a Float32 0/1 mask.
pub fn gte(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(
            i,
            if a.get_f64(i) >= b.get_f64(i) {
                1.0
            } else {
                0.0
            },
        );
    }
    Ok(out)
}

/// Compare every element against scalar s with greater-than-or-equal and return a Float32 0/1 mask.
pub fn gte_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) >= s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

/// Compare two arrays element-wise with less-than-or-equal and return a Float32 0/1 mask.
pub fn lte(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(
            i,
            if a.get_f64(i) <= b.get_f64(i) {
                1.0
            } else {
                0.0
            },
        );
    }
    Ok(out)
}

/// Compare every element against scalar s with less-than-or-equal and return a Float32 0/1 mask.
pub fn lte_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) <= s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

// ---- Helper Functions: Masking ----

/// Build a Float32 mask with 1.0 where a >= val and 0.0 elsewhere.
pub fn threshold(a: &NdArray, val: f64) -> Result<NdArray, String> {
    gte_scalar(a, val)
}

/// Select from a when cond is non-zero and from b otherwise; require matching shapes and matching a/b dtypes.
pub fn where_mask(cond: &NdArray, a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    if cond.shape() != a.shape() || a.shape() != b.shape() {
        return Err(format!(
            "where_mask: shape mismatch: cond={:?}, a={:?}, b={:?}",
            cond.shape(),
            a.shape(),
            b.shape()
        ));
    }
    if a.dtype() != b.dtype() {
        return Err(format!(
            "where_mask: dtype mismatch: a={}, b={}",
            a.dtype().name(),
            b.dtype().name()
        ));
    }
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        let c = cond.get_f64(i);
        out.set_f64(i, if c != 0.0 { a.get_f64(i) } else { b.get_f64(i) });
    }
    Ok(out)
}

// Counting

/// Count the number of non-zero elements.
pub fn count_nonzero(a: &NdArray) -> usize {
    let mut count = 0usize;
    for i in 0..a.size() {
        if a.get_f64(i) != 0.0 {
            count += 1;
        }
    }
    count
}

/// Get the flat index of the minimum element.
pub fn argmin(a: &NdArray) -> usize {
    let mut best_idx = 0;
    let mut best_val = a.get_f64(0);
    for i in 1..a.size() {
        let v = a.get_f64(i);
        if v < best_val {
            best_val = v;
            best_idx = i;
        }
    }
    best_idx
}

/// Get the flat index of the maximum element.
pub fn argmax(a: &NdArray) -> usize {
    let mut best_idx = 0;
    let mut best_val = a.get_f64(0);
    for i in 1..a.size() {
        let v = a.get_f64(i);
        if v > best_val {
            best_val = v;
            best_idx = i;
        }
    }
    best_idx
}

/// Return true when any element is non-zero.
pub fn any(a: &NdArray) -> bool {
    for i in 0..a.size() {
        if a.get_f64(i) != 0.0 {
            return true;
        }
    }
    false
}

/// Return true when every element is non-zero.
pub fn all(a: &NdArray) -> bool {
    for i in 0..a.size() {
        if a.get_f64(i) == 0.0 {
            return false;
        }
    }
    true
}

// Reductions â€” global

/// Sum all elements.
pub fn sum(a: &NdArray) -> f64 {
    if a.size() > get_par_threshold() {
        (0..a.size()).into_par_iter().map(|i| a.get_f64(i)).sum()
    } else {
        let mut s = 0.0;
        for i in 0..a.size() {
            s += a.get_f64(i);
        }
        s
    }
}

/// Compute the mean of all elements.
pub fn mean(a: &NdArray) -> f64 {
    sum(a) / a.size() as f64
}

/// Get the minimum element value.
pub fn min_val(a: &NdArray) -> f64 {
    if a.size() > get_par_threshold() {
        (0..a.size())
            .into_par_iter()
            .map(|i| a.get_f64(i))
            .reduce_with(f64::min)
            .unwrap_or(f64::NAN)
    } else {
        let mut m = a.get_f64(0);
        for i in 1..a.size() {
            let v = a.get_f64(i);
            if v < m {
                m = v;
            }
        }
        m
    }
}

/// Get the maximum element value.
pub fn max_val(a: &NdArray) -> f64 {
    if a.size() > get_par_threshold() {
        (0..a.size())
            .into_par_iter()
            .map(|i| a.get_f64(i))
            .reduce_with(f64::max)
            .unwrap_or(f64::NAN)
    } else {
        let mut m = a.get_f64(0);
        for i in 1..a.size() {
            let v = a.get_f64(i);
            if v > m {
                m = v;
            }
        }
        m
    }
}

// ---- Helper Functions: Reductions Along Axis ----

/// Build the output shape after removing axis and promote 1D reductions to [1].
fn reduced_shape(shape: &[usize], axis: usize) -> Vec<usize> {
    let mut out = Vec::with_capacity(shape.len() - 1);
    for (i, &dim) in shape.iter().enumerate() {
        if i != axis {
            out.push(dim);
        }
    }
    // If reducing a 1D array, result is a 1-element 1D array.
    if out.is_empty() {
        out.push(1);
    }
    out
}

/// Visit every multi-index of shape and call f with the flat and multi-index values.
fn for_each_index(shape: &[usize], mut f: impl FnMut(usize, &[usize])) {
    let ndim = shape.len();
    let total: usize = shape.iter().product();
    let strides = NdArray::compute_strides(shape);
    let mut indices = vec![0usize; ndim];
    for flat in 0..total {
        f(flat, &indices);
        // Increment multi-index (odometer style, last axis fastest)
        for d in (0..ndim).rev() {
            indices[d] += 1;
            if indices[d] < shape[d] {
                break;
            }
            indices[d] = 0;
        }
        let _ = strides; // suppress unused warning
    }
}

/// Sum along axis and return the reduced array.
pub fn sum_axis(a: &NdArray, axis: usize) -> Result<NdArray, String> {
    check_axis(a, axis)?;
    let out_shape = reduced_shape(a.shape(), axis);
    let mut out = NdArray::zeros(&out_shape, a.dtype())?;
    let out_strides = NdArray::compute_strides(&out_shape);

    for_each_index(a.shape(), |_flat, indices| {
        // Compute output flat index by skipping the reduced axis
        let mut out_flat = 0usize;
        let mut out_dim = 0;
        for (i, &idx) in indices.iter().enumerate() {
            if i != axis {
                out_flat += idx * out_strides[out_dim];
                out_dim += 1;
            }
        }
        // For 1D reduction to [1], out_flat is always 0
        let cur = out.get_f64(out_flat);
        out.set_f64(out_flat, cur + a.get_f64(a.flat_index(indices).unwrap()));
    });

    Ok(out)
}

/// Compute the mean along axis and return the reduced array.
pub fn mean_axis(a: &NdArray, axis: usize) -> Result<NdArray, String> {
    check_axis(a, axis)?;
    let mut out = sum_axis(a, axis)?;
    let axis_size = a.shape()[axis] as f64;
    for i in 0..out.size() {
        out.set_f64(i, out.get_f64(i) / axis_size);
    }
    Ok(out)
}

/// Get per-axis minima and return the reduced array.
pub fn min_axis(a: &NdArray, axis: usize) -> Result<NdArray, String> {
    check_axis(a, axis)?;
    let out_shape = reduced_shape(a.shape(), axis);
    let mut out = NdArray::zeros(&out_shape, a.dtype())?;
    let out_strides = NdArray::compute_strides(&out_shape);
    // Initialize with f64::MAX
    for i in 0..out.size() {
        out.set_f64(i, f64::MAX);
    }

    for_each_index(a.shape(), |_flat, indices| {
        let mut out_flat = 0usize;
        let mut out_dim = 0;
        for (i, &idx) in indices.iter().enumerate() {
            if i != axis {
                out_flat += idx * out_strides[out_dim];
                out_dim += 1;
            }
        }
        let val = a.get_f64(a.flat_index(indices).unwrap());
        if val < out.get_f64(out_flat) {
            out.set_f64(out_flat, val);
        }
    });

    Ok(out)
}

/// Get per-axis maxima and return the reduced array.
pub fn max_axis(a: &NdArray, axis: usize) -> Result<NdArray, String> {
    check_axis(a, axis)?;
    let out_shape = reduced_shape(a.shape(), axis);
    let mut out = NdArray::zeros(&out_shape, a.dtype())?;
    let out_strides = NdArray::compute_strides(&out_shape);
    // Initialize with f64::MIN
    for i in 0..out.size() {
        out.set_f64(i, f64::MIN);
    }

    for_each_index(a.shape(), |_flat, indices| {
        let mut out_flat = 0usize;
        let mut out_dim = 0;
        for (i, &idx) in indices.iter().enumerate() {
            if i != axis {
                out_flat += idx * out_strides[out_dim];
                out_dim += 1;
            }
        }
        let val = a.get_f64(a.flat_index(indices).unwrap());
        if val > out.get_f64(out_flat) {
            out.set_f64(out_flat, val);
        }
    });

    Ok(out)
}

// Shape operations

/// Reshape a to new_shape with the same element count; return an error when sizes differ or new_shape is empty.
pub fn reshape(a: &NdArray, new_shape: &[usize]) -> Result<NdArray, String> {
    let new_total: usize = new_shape.iter().product();
    if new_total != a.size() {
        return Err(format!(
            "cannot reshape array of size {} into shape {:?} (size {})",
            a.size(),
            new_shape,
            new_total,
        ));
    }
    if new_shape.is_empty() {
        return Err("ndim must be >= 1".to_string());
    }
    let mut out = a.clone();
    let strides = NdArray::compute_strides(new_shape);
    out.set_shape(new_shape.to_vec(), strides);
    Ok(out)
}

/// Transpose a 2D array and return the swapped array.
pub fn transpose_2d(a: &NdArray) -> Result<NdArray, String> {
    if a.ndim() != 2 {
        return Err(format!(
            "transpose_2d requires a 2D array, got {}D",
            a.ndim()
        ));
    }
    let rows = a.shape()[0];
    let cols = a.shape()[1];
    let mut out = NdArray::zeros(&[cols, rows], a.dtype())?;
    for r in 0..rows {
        for c in 0..cols {
            let src = a.flat_index(&[r, c]).unwrap();
            let dst = out.flat_index(&[c, r]).unwrap();
            out.set_f64(dst, a.get_f64(src));
        }
    }
    Ok(out)
}

/// Fill every element of a with val.
pub fn fill(a: &mut NdArray, val: f64) {
    a.fill(val);
}

/// Add in place with equal shapes or [rows, cols] + [cols] row broadcasting.
pub fn add_inplace(a: &mut NdArray, b: &NdArray) -> Result<(), String> {
    elementwise_binary_inplace(a, b, |x, y| x + y)
}

/// Subtract in place with equal shapes or [rows, cols] - [cols] row broadcasting.
pub fn sub_inplace(a: &mut NdArray, b: &NdArray) -> Result<(), String> {
    elementwise_binary_inplace(a, b, |x, y| x - y)
}

/// Multiply in place with equal shapes or [rows, cols] * [cols] row broadcasting.
pub fn mul_inplace(a: &mut NdArray, b: &NdArray) -> Result<(), String> {
    elementwise_binary_inplace(a, b, |x, y| x * y)
}

/// Divide in place with equal shapes or [rows, cols] / [cols] row broadcasting.
pub fn div_inplace(a: &mut NdArray, b: &NdArray) -> Result<(), String> {
    elementwise_binary_inplace(a, b, |x, y| x / y)
}

/// Clone a and return the new array.
pub fn clone_array(a: &NdArray) -> NdArray {
    a.clone()
}

// Bitwise â€” Int32 only

/// Compute bitwise AND for two Int32 arrays and return the result array.
pub fn bitwise_and(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    require_int32(a)?;
    require_int32(b)?;
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i) & b.get_i32(i));
    }
    Ok(out)
}

/// Compute bitwise OR for two Int32 arrays and return the result array.
pub fn bitwise_or(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    require_int32(a)?;
    require_int32(b)?;
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i) | b.get_i32(i));
    }
    Ok(out)
}

/// Compute bitwise XOR for two Int32 arrays and return the result array.
pub fn bitwise_xor(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    require_int32(a)?;
    require_int32(b)?;
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i) ^ b.get_i32(i));
    }
    Ok(out)
}

/// Compute bitwise NOT for an Int32 array and return the result array.
pub fn bitwise_not(a: &NdArray) -> Result<NdArray, String> {
    require_int32(a)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, !a.get_i32(i));
    }
    Ok(out)
}

/// Shift an Int32 array left by amount bits and return the result array.
pub fn bitwise_lshift(a: &NdArray, amount: u32) -> Result<NdArray, String> {
    require_int32(a)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i).wrapping_shl(amount));
    }
    Ok(out)
}

/// Shift an Int32 array right by amount bits and return the result array.
pub fn bitwise_rshift(a: &NdArray, amount: u32) -> Result<NdArray, String> {
    require_int32(a)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i).wrapping_shr(amount));
    }
    Ok(out)
}
