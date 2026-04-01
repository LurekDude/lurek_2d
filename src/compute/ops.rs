//! Element-wise, reduction, comparison, masking, shape, and bitwise operations on NdArray.

use crate::compute::array::{DataType, NdArray};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Validate two arrays have the same shape and dtype for element-wise ops.
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

/// Apply an element-wise binary op (array, array) → new array.
fn elementwise_binary(
    a: &NdArray,
    b: &NdArray,
    op: fn(f64, f64) -> f64,
) -> Result<NdArray, String> {
    check_same_shape_dtype(a, b)?;
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, op(a.get_f64(i), b.get_f64(i)));
    }
    Ok(out)
}

/// Apply an element-wise unary op → new array.
fn elementwise_unary(a: &NdArray, op: fn(f64) -> f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, op(a.get_f64(i)));
    }
    Ok(out)
}

/// Apply an element-wise (element, scalar) op → new array.
fn elementwise_scalar(a: &NdArray, s: f64, op: fn(f64, f64) -> f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, op(a.get_f64(i), s));
    }
    Ok(out)
}

/// Validate that axis is within the array's ndim.
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

/// Check that array has Int32 dtype, returning an error otherwise.
fn require_int32(a: &NdArray) -> Result<(), String> {
    if a.dtype() != DataType::Int32 {
        return Err(format!(
            "bitwise ops require int32 dtype, got {}",
            a.dtype().name()
        ));
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// Element-wise arithmetic
// ---------------------------------------------------------------------------

/// Element-wise addition of two arrays (same shape and dtype).
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn add(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x + y)
}

/// Add a scalar to every element.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn add_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x + y)
}

/// Element-wise subtraction of two arrays (same shape and dtype).
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn sub(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x - y)
}

/// Subtract a scalar from every element.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn sub_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x - y)
}

/// Element-wise multiplication of two arrays (same shape and dtype).
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn mul(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x * y)
}

/// Multiply every element by a scalar.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn mul_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x * y)
}

/// Element-wise division of two arrays (same shape and dtype).
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn div(a: &NdArray, b: &NdArray) -> Result<NdArray, String> {
    elementwise_binary(a, b, |x, y| x / y)
}

/// Divide every element by a scalar.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn div_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    elementwise_scalar(a, s, |x, y| x / y)
}

/// Raise every element to a scalar exponent.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `exp` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn pow_scalar(a: &NdArray, exp: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, a.get_f64(i).powf(exp));
    }
    Ok(out)
}

/// Element-wise square root.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn sqrt(a: &NdArray) -> Result<NdArray, String> {
    elementwise_unary(a, f64::sqrt)
}

/// Element-wise absolute value.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn abs(a: &NdArray) -> Result<NdArray, String> {
    elementwise_unary(a, f64::abs)
}

/// Element-wise negation.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn neg(a: &NdArray) -> Result<NdArray, String> {
    elementwise_unary(a, |x| -x)
}

/// Clamp every element to `[min_val, max_val]`.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `min_val` — `f64`.
/// - `max_val` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn clamp(a: &NdArray, min_val: f64, max_val: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), a.dtype())?;
    for i in 0..a.size() {
        out.set_f64(i, a.get_f64(i).clamp(min_val, max_val));
    }
    Ok(out)
}

// ---------------------------------------------------------------------------
// Comparison — returns Float32 array with 0.0 / 1.0 values
// ---------------------------------------------------------------------------

/// Element-wise equality comparison of two arrays. Returns Float32 with 0/1.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise equality comparison against a scalar. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise not-equal comparison of two arrays. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise not-equal comparison against a scalar. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise greater-than comparison of two arrays. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise greater-than comparison against a scalar. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn gt_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) > s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

/// Element-wise less-than comparison of two arrays. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise less-than comparison against a scalar. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn lt_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) < s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

/// Element-wise greater-than-or-equal comparison of two arrays. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise greater-than-or-equal comparison against a scalar. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn gte_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) >= s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

/// Element-wise less-than-or-equal comparison of two arrays. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Element-wise less-than-or-equal comparison against a scalar. Returns Float32.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `s` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn lte_scalar(a: &NdArray, s: f64) -> Result<NdArray, String> {
    let mut out = NdArray::zeros(a.shape(), DataType::Float32)?;
    for i in 0..a.size() {
        out.set_f64(i, if a.get_f64(i) <= s { 1.0 } else { 0.0 });
    }
    Ok(out)
}

// ---------------------------------------------------------------------------
// Masking
// ---------------------------------------------------------------------------

/// Threshold mask: returns Float32 array with 1.0 where `a >= val`, 0.0 otherwise.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `val` — `f64`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn threshold(a: &NdArray, val: f64) -> Result<NdArray, String> {
    gte_scalar(a, val)
}

/// Conditional selection: where `cond != 0`, choose from `a`; otherwise from `b`.
///
/// # Parameters
/// - `cond` — `&NdArray`.
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// All three arrays must have the same shape. `a` and `b` must have the same dtype.
/// `cond` is read as Float32.
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

// ---------------------------------------------------------------------------
// Counting
// ---------------------------------------------------------------------------

/// Count the number of non-zero elements.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `usize`.
pub fn count_nonzero(a: &NdArray) -> usize {
    let mut count = 0usize;
    for i in 0..a.size() {
        if a.get_f64(i) != 0.0 {
            count += 1;
        }
    }
    count
}

/// Return the flat index of the minimum element (0-based).
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `usize`.
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

/// Return the flat index of the maximum element (0-based).
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `usize`.
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

/// Returns `true` if any element is non-zero.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `bool`.
pub fn any(a: &NdArray) -> bool {
    for i in 0..a.size() {
        if a.get_f64(i) != 0.0 {
            return true;
        }
    }
    false
}

/// Returns `true` if all elements are non-zero.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `bool`.
pub fn all(a: &NdArray) -> bool {
    for i in 0..a.size() {
        if a.get_f64(i) == 0.0 {
            return false;
        }
    }
    true
}

// ---------------------------------------------------------------------------
// Reductions — global
// ---------------------------------------------------------------------------

/// Sum of all elements.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `f64`.
pub fn sum(a: &NdArray) -> f64 {
    let mut s = 0.0;
    for i in 0..a.size() {
        s += a.get_f64(i);
    }
    s
}

/// Mean of all elements.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `f64`.
pub fn mean(a: &NdArray) -> f64 {
    sum(a) / a.size() as f64
}

/// Minimum value across all elements.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `f64`.
pub fn min_val(a: &NdArray) -> f64 {
    let mut m = a.get_f64(0);
    for i in 1..a.size() {
        let v = a.get_f64(i);
        if v < m {
            m = v;
        }
    }
    m
}

/// Maximum value across all elements.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `f64`.
pub fn max_val(a: &NdArray) -> f64 {
    let mut m = a.get_f64(0);
    for i in 1..a.size() {
        let v = a.get_f64(i);
        if v > m {
            m = v;
        }
    }
    m
}

// ---------------------------------------------------------------------------
// Reductions — along axis
// ---------------------------------------------------------------------------

/// Compute the output shape when reducing along a given axis.
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

/// Helper: iterate over all multi-indices of a shape, calling `f(flat_index, multi_index)`.
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

/// Sum along a given axis, producing an array with that axis removed.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `axis` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Mean along a given axis.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `axis` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn mean_axis(a: &NdArray, axis: usize) -> Result<NdArray, String> {
    check_axis(a, axis)?;
    let mut out = sum_axis(a, axis)?;
    let axis_size = a.shape()[axis] as f64;
    for i in 0..out.size() {
        out.set_f64(i, out.get_f64(i) / axis_size);
    }
    Ok(out)
}

/// Minimum along a given axis.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `axis` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Maximum along a given axis.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `axis` — `usize`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

// ---------------------------------------------------------------------------
// Shape operations
// ---------------------------------------------------------------------------

/// Reshape an array to a new shape with the same total element count.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `new_shape` — `&[usize]`.
///
/// # Returns
/// `Result<NdArray, String>`.
///
/// Returns a new array with data copied from the original.
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
    if new_shape.is_empty() || new_shape.len() > 3 {
        return Err(format!("ndim must be 1, 2, or 3, got {}", new_shape.len()));
    }
    let mut out = a.clone();
    let strides = NdArray::compute_strides(new_shape);
    out.set_shape(new_shape.to_vec(), strides);
    Ok(out)
}

/// Transpose a 2D array (swap rows and columns).
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Fill all elements of an array with a value (in-place).
///
/// # Parameters
/// - `a` — `&mut NdArray`.
/// - `val` — `f64`.
pub fn fill(a: &mut NdArray, val: f64) {
    for i in 0..a.size() {
        a.set_f64(i, val);
    }
}

/// Clone an array (convenience wrapper).
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `NdArray`.
pub fn clone_array(a: &NdArray) -> NdArray {
    a.clone()
}

// ---------------------------------------------------------------------------
// Bitwise — Int32 only
// ---------------------------------------------------------------------------

/// Bitwise AND of two Int32 arrays.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Bitwise OR of two Int32 arrays.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Bitwise XOR of two Int32 arrays.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `b` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
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

/// Bitwise NOT of an Int32 array.
///
/// # Parameters
/// - `a` — `&NdArray`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn bitwise_not(a: &NdArray) -> Result<NdArray, String> {
    require_int32(a)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, !a.get_i32(i));
    }
    Ok(out)
}

/// Bitwise left shift of an Int32 array by `amount` bits.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `amount` — `u32`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn bitwise_lshift(a: &NdArray, amount: u32) -> Result<NdArray, String> {
    require_int32(a)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i).wrapping_shl(amount));
    }
    Ok(out)
}

/// Bitwise right shift (arithmetic) of an Int32 array by `amount` bits.
///
/// # Parameters
/// - `a` — `&NdArray`.
/// - `amount` — `u32`.
///
/// # Returns
/// `Result<NdArray, String>`.
pub fn bitwise_rshift(a: &NdArray, amount: u32) -> Result<NdArray, String> {
    require_int32(a)?;
    let mut out = NdArray::zeros(a.shape(), DataType::Int32)?;
    for i in 0..a.size() {
        out.set_i32(i, a.get_i32(i).wrapping_shr(amount));
    }
    Ok(out)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn arr_1d(vals: &[f64]) -> NdArray {
        NdArray::from_slice(vals, &[vals.len()], DataType::Float32).unwrap()
    }

    fn arr_2d(vals: &[f64], rows: usize, cols: usize) -> NdArray {
        NdArray::from_slice(vals, &[rows, cols], DataType::Float32).unwrap()
    }

    #[test]
    fn test_add() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let b = arr_1d(&[4.0, 5.0, 6.0]);
        let c = add(&a, &b).unwrap();
        assert!((c.get_f64(0) - 5.0).abs() < 1e-5);
        assert!((c.get_f64(2) - 9.0).abs() < 1e-5);
    }

    #[test]
    fn test_add_scalar() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let c = add_scalar(&a, 10.0).unwrap();
        assert!((c.get_f64(0) - 11.0).abs() < 1e-5);
    }

    #[test]
    fn test_sub() {
        let a = arr_1d(&[10.0, 20.0]);
        let b = arr_1d(&[3.0, 7.0]);
        let c = sub(&a, &b).unwrap();
        assert!((c.get_f64(0) - 7.0).abs() < 1e-5);
        assert!((c.get_f64(1) - 13.0).abs() < 1e-5);
    }

    #[test]
    fn test_mul_div() {
        let a = arr_1d(&[2.0, 3.0, 4.0]);
        let b = arr_1d(&[5.0, 6.0, 7.0]);
        let m = mul(&a, &b).unwrap();
        assert!((m.get_f64(0) - 10.0).abs() < 1e-5);
        let d = div(&a, &b).unwrap();
        assert!((d.get_f64(0) - 0.4).abs() < 1e-5);
    }

    #[test]
    fn test_pow_sqrt_abs_neg() {
        let a = arr_1d(&[4.0, 9.0, 16.0]);
        let s = sqrt(&a).unwrap();
        assert!((s.get_f64(0) - 2.0).abs() < 1e-5);
        assert!((s.get_f64(1) - 3.0).abs() < 1e-5);

        let n = neg(&a).unwrap();
        assert!((n.get_f64(0) - (-4.0)).abs() < 1e-5);

        let ab = abs(&n).unwrap();
        assert!((ab.get_f64(0) - 4.0).abs() < 1e-5);
    }

    #[test]
    fn test_clamp() {
        let a = arr_1d(&[1.0, 5.0, 10.0, -3.0]);
        let c = clamp(&a, 0.0, 7.0).unwrap();
        assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((c.get_f64(1) - 5.0).abs() < 1e-5);
        assert!((c.get_f64(2) - 7.0).abs() < 1e-5);
        assert!((c.get_f64(3) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_comparisons() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let b = arr_1d(&[2.0, 2.0, 1.0]);
        let r = gt(&a, &b).unwrap();
        assert!((r.get_f64(0) - 0.0).abs() < 1e-5);
        assert!((r.get_f64(1) - 0.0).abs() < 1e-5);
        assert!((r.get_f64(2) - 1.0).abs() < 1e-5);

        let r = lt_scalar(&a, 2.5).unwrap();
        assert!((r.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((r.get_f64(1) - 1.0).abs() < 1e-5);
        assert!((r.get_f64(2) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_threshold_where() {
        let a = arr_1d(&[0.0, 3.0, 7.0, 1.0]);
        let mask = threshold(&a, 2.0).unwrap();
        assert!((mask.get_f64(0) - 0.0).abs() < 1e-5);
        assert!((mask.get_f64(1) - 1.0).abs() < 1e-5);

        let hi = arr_1d(&[10.0, 10.0, 10.0, 10.0]);
        let lo = arr_1d(&[0.0, 0.0, 0.0, 0.0]);
        let w = where_mask(&mask, &hi, &lo).unwrap();
        assert!((w.get_f64(0) - 0.0).abs() < 1e-5);
        assert!((w.get_f64(1) - 10.0).abs() < 1e-5);
    }

    #[test]
    fn test_counting() {
        let a = arr_1d(&[0.0, 1.0, 0.0, 3.0, 5.0]);
        assert_eq!(count_nonzero(&a), 3);
        assert_eq!(argmin(&a), 0);
        assert_eq!(argmax(&a), 4);
        assert!(any(&a));
        assert!(!all(&a));

        let b = arr_1d(&[1.0, 2.0, 3.0]);
        assert!(all(&b));
    }

    #[test]
    fn test_reductions_global() {
        let a = arr_1d(&[1.0, 2.0, 3.0, 4.0]);
        assert!((sum(&a) - 10.0).abs() < 1e-5);
        assert!((mean(&a) - 2.5).abs() < 1e-5);
        assert!((min_val(&a) - 1.0).abs() < 1e-5);
        assert!((max_val(&a) - 4.0).abs() < 1e-5);
    }

    #[test]
    fn test_sum_axis() {
        // 2x3 array:
        // 1 2 3
        // 4 5 6
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);

        // Sum along axis 0 → [5, 7, 9]
        let s0 = sum_axis(&a, 0).unwrap();
        assert_eq!(s0.shape(), &[3]);
        assert!((s0.get_f64(0) - 5.0).abs() < 1e-5);
        assert!((s0.get_f64(1) - 7.0).abs() < 1e-5);
        assert!((s0.get_f64(2) - 9.0).abs() < 1e-5);

        // Sum along axis 1 → [6, 15]
        let s1 = sum_axis(&a, 1).unwrap();
        assert_eq!(s1.shape(), &[2]);
        assert!((s1.get_f64(0) - 6.0).abs() < 1e-5);
        assert!((s1.get_f64(1) - 15.0).abs() < 1e-5);
    }

    #[test]
    fn test_mean_axis() {
        let a = arr_2d(&[2.0, 4.0, 6.0, 8.0], 2, 2);
        let m = mean_axis(&a, 0).unwrap();
        assert!((m.get_f64(0) - 4.0).abs() < 1e-5);
        assert!((m.get_f64(1) - 6.0).abs() < 1e-5);
    }

    #[test]
    fn test_reshape() {
        let a = arr_1d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
        let b = reshape(&a, &[2, 3]).unwrap();
        assert_eq!(b.shape(), &[2, 3]);
        assert!((b.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((b.get_f64(5) - 6.0).abs() < 1e-5);
        assert!(reshape(&a, &[3, 3]).is_err());
    }

    #[test]
    fn test_transpose_2d() {
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
        let t = transpose_2d(&a).unwrap();
        assert_eq!(t.shape(), &[3, 2]);
        // Original [0,1]=2.0 → transposed [1,0]=2.0
        assert!((t.get_f64(t.flat_index(&[1, 0]).unwrap()) - 2.0).abs() < 1e-5);
        // Original [1,2]=6.0 → transposed [2,1]=6.0
        assert!((t.get_f64(t.flat_index(&[2, 1]).unwrap()) - 6.0).abs() < 1e-5);
    }

    #[test]
    fn test_fill() {
        let mut a = arr_1d(&[1.0, 2.0, 3.0]);
        fill(&mut a, 42.0);
        for i in 0..3 {
            assert!((a.get_f64(i) - 42.0).abs() < 1e-5);
        }
    }

    #[test]
    fn test_bitwise_ops() {
        let mut a = NdArray::zeros(&[4], DataType::Int32).unwrap();
        let mut b = NdArray::zeros(&[4], DataType::Int32).unwrap();
        for i in 0..4 {
            a.set_i32(i, 0b1010);
            b.set_i32(i, 0b1100);
        }
        let and = bitwise_and(&a, &b).unwrap();
        assert_eq!(and.get_i32(0), 0b1000);

        let or = bitwise_or(&a, &b).unwrap();
        assert_eq!(or.get_i32(0), 0b1110);

        let xor = bitwise_xor(&a, &b).unwrap();
        assert_eq!(xor.get_i32(0), 0b0110);

        let not = bitwise_not(&a).unwrap();
        assert_eq!(not.get_i32(0), !0b1010_i32);
    }

    #[test]
    fn test_bitwise_dtype_check() {
        let a = arr_1d(&[1.0, 2.0]);
        let b = arr_1d(&[3.0, 4.0]);
        assert!(bitwise_and(&a, &b).is_err());
    }

    #[test]
    fn test_shape_mismatch_error() {
        let a = arr_1d(&[1.0, 2.0]);
        let b = arr_1d(&[1.0, 2.0, 3.0]);
        assert!(add(&a, &b).is_err());
    }
}
