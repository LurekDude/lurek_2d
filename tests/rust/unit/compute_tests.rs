//! Integration tests for `lurek2d::compute` — N-dimensional array operations.

use lurek2d::compute::ops;
use lurek2d::compute::spatial;
use lurek2d::compute::*;

// ===========================================================================
// Helpers
// ===========================================================================

fn arr_1d(vals: &[f64]) -> NdArray {
    NdArray::from_slice(vals, &[vals.len()], DataType::Float32).unwrap()
}

fn arr_2d(vals: &[f64], rows: usize, cols: usize) -> NdArray {
    NdArray::from_slice(vals, &[rows, cols], DataType::Float32).unwrap()
}

// ===========================================================================
// NdArray creation and metadata (src/compute/array.rs)
// ===========================================================================

#[test]
fn test_new_creates_zero_initialized_array() {
    let a = NdArray::new(&[3, 4], DataType::Float64).unwrap();
    assert_eq!(a.shape(), &[3, 4]);
    assert_eq!(a.dtype(), DataType::Float64);
    assert_eq!(a.size(), 12);
    assert_eq!(a.ndim(), 2);
    for i in 0..a.size() {
        assert!((a.get_f64(i) - 0.0).abs() < 1e-5);
    }
}

#[test]
fn test_zeros_1d() {
    let a = NdArray::zeros(&[5], DataType::Float32).unwrap();
    assert_eq!(a.shape(), &[5]);
    assert_eq!(a.size(), 5);
    assert_eq!(a.ndim(), 1);
    for i in 0..5 {
        assert!((a.get_f64(i) - 0.0).abs() < 1e-5);
    }
}

#[test]
fn test_ones_fills_with_one() {
    let a = NdArray::ones(&[2, 3], DataType::Float32).unwrap();
    assert_eq!(a.size(), 6);
    for i in 0..6 {
        assert!((a.get_f64(i) - 1.0).abs() < 1e-5);
    }
}

#[test]
fn test_ones_int32() {
    let a = NdArray::ones(&[4], DataType::Int32).unwrap();
    for i in 0..4 {
        assert_eq!(a.get_i32(i), 1);
    }
}

#[test]
fn test_range_ascending() {
    let a = NdArray::range(0.0, 5.0, 1.0, DataType::Float64).unwrap();
    assert_eq!(a.ndim(), 1);
    assert_eq!(a.size(), 5);
    for i in 0..5 {
        assert!((a.get_f64(i) - i as f64).abs() < 1e-5);
    }
}

#[test]
fn test_range_with_fractional_step() {
    let a = NdArray::range(0.0, 1.0, 0.25, DataType::Float64).unwrap();
    assert_eq!(a.size(), 4);
    assert!((a.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((a.get_f64(1) - 0.25).abs() < 1e-5);
    assert!((a.get_f64(3) - 0.75).abs() < 1e-5);
}

#[test]
fn test_range_zero_step_error() {
    let r = NdArray::range(0.0, 10.0, 0.0, DataType::Float32);
    assert!(r.is_err());
}

#[test]
fn test_from_slice_2d() {
    let a =
        NdArray::from_slice(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], &[2, 3], DataType::Float32).unwrap();
    assert_eq!(a.shape(), &[2, 3]);
    assert!((a.get_f64(0) - 1.0).abs() < 1e-5);
    assert!((a.get_f64(5) - 6.0).abs() < 1e-5);
}

#[test]
fn test_from_slice_length_mismatch_error() {
    let r = NdArray::from_slice(&[1.0, 2.0, 3.0], &[2, 3], DataType::Float32);
    assert!(r.is_err());
}

#[test]
fn test_get_set_f64() {
    let mut a = NdArray::zeros(&[3], DataType::Float64).unwrap();
    a.set_f64(1, 42.5);
    assert!((a.get_f64(1) - 42.5).abs() < 1e-5);
    assert!((a.get_f64(0) - 0.0).abs() < 1e-5);
}

#[test]
fn test_get_set_i32() {
    let mut a = NdArray::zeros(&[4], DataType::Int32).unwrap();
    a.set_i32(2, -99);
    assert_eq!(a.get_i32(2), -99);
    assert_eq!(a.get_i32(0), 0);
}

#[test]
fn test_strides_row_major() {
    let a = NdArray::zeros(&[3, 4], DataType::Float32).unwrap();
    // Row-major: last axis stride=1, first axis stride=cols
    assert_eq!(a.strides(), &[4, 1]);
}

#[test]
fn test_strides_3d() {
    let a = NdArray::zeros(&[2, 3, 4], DataType::Float32).unwrap();
    assert_eq!(a.strides(), &[12, 4, 1]);
    assert_eq!(a.ndim(), 3);
    assert_eq!(a.size(), 24);
}

#[test]
fn test_flat_index_2d() {
    let a = arr_2d(&[10.0, 20.0, 30.0, 40.0, 50.0, 60.0], 2, 3);
    // Row 0, Col 2 → flat 2
    assert_eq!(a.flat_index(&[0, 2]).unwrap(), 2);
    // Row 1, Col 0 → flat 3
    assert_eq!(a.flat_index(&[1, 0]).unwrap(), 3);
    // Verify value through flat_index
    let idx = a.flat_index(&[1, 1]).unwrap();
    assert!((a.get_f64(idx) - 50.0).abs() < 1e-5);
}

#[test]
fn test_flat_index_out_of_bounds_error() {
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    assert!(a.flat_index(&[2, 0]).is_err());
    assert!(a.flat_index(&[0, 2]).is_err());
}

#[test]
fn test_flat_index_wrong_ndim_error() {
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    assert!(a.flat_index(&[0]).is_err());
    assert!(a.flat_index(&[0, 0, 0]).is_err());
}

#[test]
fn test_datatype_byte_size() {
    assert_eq!(DataType::Float32.byte_size(), 4);
    assert_eq!(DataType::Float64.byte_size(), 8);
    assert_eq!(DataType::Int32.byte_size(), 4);
}

#[test]
fn test_datatype_parse() {
    assert_eq!(DataType::parse("float32").unwrap(), DataType::Float32);
    assert_eq!(DataType::parse("float64").unwrap(), DataType::Float64);
    assert_eq!(DataType::parse("int32").unwrap(), DataType::Int32);
    assert!(DataType::parse("uint8").is_err());
}

// ===========================================================================
// Element-wise arithmetic (src/compute/ops.rs)
// ===========================================================================

#[test]
fn test_add_arrays() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let b = arr_1d(&[10.0, 20.0, 30.0]);
    let c = ops::add(&a, &b).unwrap();
    assert!((c.get_f64(0) - 11.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 22.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 33.0).abs() < 1e-5);
}

#[test]
fn test_add_scalar() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let c = ops::add_scalar(&a, 100.0).unwrap();
    assert!((c.get_f64(0) - 101.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 103.0).abs() < 1e-5);
}

#[test]
fn test_sub_arrays() {
    let a = arr_1d(&[10.0, 20.0, 30.0]);
    let b = arr_1d(&[1.0, 5.0, 10.0]);
    let c = ops::sub(&a, &b).unwrap();
    assert!((c.get_f64(0) - 9.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 15.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 20.0).abs() < 1e-5);
}

#[test]
fn test_mul_arrays() {
    let a = arr_1d(&[2.0, 3.0, 4.0]);
    let b = arr_1d(&[5.0, 6.0, 7.0]);
    let c = ops::mul(&a, &b).unwrap();
    assert!((c.get_f64(0) - 10.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 18.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 28.0).abs() < 1e-5);
}

#[test]
fn test_mul_scalar() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let c = ops::mul_scalar(&a, 3.0).unwrap();
    assert!((c.get_f64(0) - 3.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 9.0).abs() < 1e-5);
}

#[test]
fn test_div_arrays() {
    let a = arr_1d(&[10.0, 20.0, 30.0]);
    let b = arr_1d(&[2.0, 5.0, 10.0]);
    let c = ops::div(&a, &b).unwrap();
    assert!((c.get_f64(0) - 5.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 4.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 3.0).abs() < 1e-5);
}

#[test]
fn test_div_scalar() {
    let a = arr_1d(&[10.0, 20.0, 30.0]);
    let c = ops::div_scalar(&a, 10.0).unwrap();
    assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 3.0).abs() < 1e-5);
}

#[test]
fn test_pow_scalar() {
    let a = arr_1d(&[2.0, 3.0, 4.0]);
    let c = ops::pow_scalar(&a, 2.0).unwrap();
    assert!((c.get_f64(0) - 4.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 9.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 16.0).abs() < 1e-5);
}

#[test]
fn test_sqrt() {
    let a = arr_1d(&[4.0, 9.0, 16.0]);
    let c = ops::sqrt(&a).unwrap();
    assert!((c.get_f64(0) - 2.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 3.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 4.0).abs() < 1e-5);
}

#[test]
fn test_abs_negative_values() {
    let a = arr_1d(&[-3.0, 0.0, 5.0]);
    let c = ops::abs(&a).unwrap();
    assert!((c.get_f64(0) - 3.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 5.0).abs() < 1e-5);
}

#[test]
fn test_neg() {
    let a = arr_1d(&[1.0, -2.0, 0.0]);
    let c = ops::neg(&a).unwrap();
    assert!((c.get_f64(0) - (-1.0)).abs() < 1e-5);
    assert!((c.get_f64(1) - 2.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 0.0).abs() < 1e-5);
}

#[test]
fn test_clamp() {
    let a = arr_1d(&[-5.0, 0.5, 3.0, 10.0]);
    let c = ops::clamp(&a, 0.0, 2.0).unwrap();
    assert!((c.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 0.5).abs() < 1e-5);
    assert!((c.get_f64(2) - 2.0).abs() < 1e-5);
    assert!((c.get_f64(3) - 2.0).abs() < 1e-5);
}

// ===========================================================================
// Reductions (src/compute/ops.rs)
// ===========================================================================

#[test]
fn test_sum_reduction() {
    let a = arr_1d(&[1.0, 2.0, 3.0, 4.0]);
    assert!((ops::sum(&a) - 10.0).abs() < 1e-5);
}

#[test]
fn test_mean_reduction() {
    let a = arr_1d(&[2.0, 4.0, 6.0, 8.0]);
    assert!((ops::mean(&a) - 5.0).abs() < 1e-5);
}

#[test]
fn test_min_val() {
    let a = arr_1d(&[5.0, -3.0, 7.0, 1.0]);
    assert!((ops::min_val(&a) - (-3.0)).abs() < 1e-5);
}

#[test]
fn test_max_val() {
    let a = arr_1d(&[5.0, -3.0, 7.0, 1.0]);
    assert!((ops::max_val(&a) - 7.0).abs() < 1e-5);
}

#[test]
fn test_sum_axis_rows() {
    // 2x3 array, sum along axis 0 (rows) → 1D length 3
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
    let s = ops::sum_axis(&a, 0).unwrap();
    assert_eq!(s.shape(), &[3]);
    assert!((s.get_f64(0) - 5.0).abs() < 1e-5); // 1+4
    assert!((s.get_f64(1) - 7.0).abs() < 1e-5); // 2+5
    assert!((s.get_f64(2) - 9.0).abs() < 1e-5); // 3+6
}

#[test]
fn test_sum_axis_cols() {
    // 2x3 array, sum along axis 1 (cols) → 1D length 2
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
    let s = ops::sum_axis(&a, 1).unwrap();
    assert_eq!(s.shape(), &[2]);
    assert!((s.get_f64(0) - 6.0).abs() < 1e-5); // 1+2+3
    assert!((s.get_f64(1) - 15.0).abs() < 1e-5); // 4+5+6
}

#[test]
fn test_mean_axis() {
    let a = arr_2d(&[2.0, 4.0, 6.0, 8.0], 2, 2);
    let m = ops::mean_axis(&a, 0).unwrap();
    assert_eq!(m.shape(), &[2]);
    assert!((m.get_f64(0) - 4.0).abs() < 1e-5); // (2+6)/2
    assert!((m.get_f64(1) - 6.0).abs() < 1e-5); // (4+8)/2
}

// ===========================================================================
// Comparisons (src/compute/ops.rs)
// ===========================================================================

#[test]
fn test_eq_scalar() {
    let a = arr_1d(&[1.0, 2.0, 3.0, 2.0]);
    let c = ops::eq_scalar(&a, 2.0).unwrap();
    assert!((c.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(3) - 1.0).abs() < 1e-5);
}

#[test]
fn test_neq_scalar() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let c = ops::neq_scalar(&a, 2.0).unwrap();
    assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 1.0).abs() < 1e-5);
}

#[test]
fn test_gt_scalar() {
    let a = arr_1d(&[1.0, 5.0, 10.0]);
    let c = ops::gt_scalar(&a, 4.0).unwrap();
    assert!((c.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 1.0).abs() < 1e-5);
}

#[test]
fn test_lt_scalar() {
    let a = arr_1d(&[1.0, 5.0, 10.0]);
    let c = ops::lt_scalar(&a, 5.0).unwrap();
    assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 0.0).abs() < 1e-5);
}

#[test]
fn test_gte_scalar() {
    let a = arr_1d(&[1.0, 5.0, 10.0]);
    let c = ops::gte_scalar(&a, 5.0).unwrap();
    assert!((c.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 1.0).abs() < 1e-5);
}

#[test]
fn test_lte_scalar() {
    let a = arr_1d(&[1.0, 5.0, 10.0]);
    let c = ops::lte_scalar(&a, 5.0).unwrap();
    assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 0.0).abs() < 1e-5);
}

// ===========================================================================
// Masking and counting (src/compute/ops.rs)
// ===========================================================================

#[test]
fn test_threshold() {
    let a = arr_1d(&[0.1, 0.5, 0.9, 1.5]);
    let c = ops::threshold(&a, 0.5).unwrap();
    assert!((c.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((c.get_f64(1) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(2) - 1.0).abs() < 1e-5);
    assert!((c.get_f64(3) - 1.0).abs() < 1e-5);
}

#[test]
fn test_where_mask() {
    let cond = arr_1d(&[1.0, 0.0, 1.0]);
    let a = arr_1d(&[10.0, 20.0, 30.0]);
    let b = arr_1d(&[100.0, 200.0, 300.0]);
    let c = ops::where_mask(&cond, &a, &b).unwrap();
    assert!((c.get_f64(0) - 10.0).abs() < 1e-5); // cond=1 → a
    assert!((c.get_f64(1) - 200.0).abs() < 1e-5); // cond=0 → b
    assert!((c.get_f64(2) - 30.0).abs() < 1e-5); // cond=1 → a
}

#[test]
fn test_count_nonzero() {
    let a = arr_1d(&[0.0, 1.0, 0.0, 3.0, -2.0]);
    assert_eq!(ops::count_nonzero(&a), 3);
}

#[test]
fn test_count_nonzero_all_zeros() {
    let a = NdArray::zeros(&[5], DataType::Float32).unwrap();
    assert_eq!(ops::count_nonzero(&a), 0);
}

#[test]
fn test_argmin() {
    let a = arr_1d(&[5.0, 1.0, 3.0, 2.0]);
    assert_eq!(ops::argmin(&a), 1);
}

#[test]
fn test_argmax() {
    let a = arr_1d(&[5.0, 1.0, 9.0, 2.0]);
    assert_eq!(ops::argmax(&a), 2);
}

#[test]
fn test_any_true() {
    let a = arr_1d(&[0.0, 0.0, 1.0]);
    assert!(ops::any(&a));
}

#[test]
fn test_any_false_all_zero() {
    let a = NdArray::zeros(&[4], DataType::Float32).unwrap();
    assert!(!ops::any(&a));
}

#[test]
fn test_all_true() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    assert!(ops::all(&a));
}

#[test]
fn test_all_false_with_zero() {
    let a = arr_1d(&[1.0, 0.0, 3.0]);
    assert!(!ops::all(&a));
}

// ===========================================================================
// Shape operations (src/compute/ops.rs)
// ===========================================================================

#[test]
fn test_reshape_1d_to_2d() {
    let a = arr_1d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
    let b = ops::reshape(&a, &[2, 3]).unwrap();
    assert_eq!(b.shape(), &[2, 3]);
    assert_eq!(b.size(), 6);
    // Data order preserved
    assert!((b.get_f64(0) - 1.0).abs() < 1e-5);
    assert!((b.get_f64(5) - 6.0).abs() < 1e-5);
}

#[test]
fn test_reshape_invalid_size_error() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let r = ops::reshape(&a, &[2, 2]);
    assert!(r.is_err());
}

#[test]
fn test_reshape_too_many_dims_error() {
    let a = arr_1d(&[1.0, 2.0, 3.0, 4.0]);
    let r = ops::reshape(&a, &[1, 1, 2, 2]);
    assert!(r.is_err());
}

#[test]
fn test_transpose_2d() {
    // [[1,2,3],[4,5,6]] → [[1,4],[2,5],[3,6]]
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
    let t = ops::transpose_2d(&a).unwrap();
    assert_eq!(t.shape(), &[3, 2]);
    let idx = t.flat_index(&[0, 0]).unwrap();
    assert!((t.get_f64(idx) - 1.0).abs() < 1e-5);
    let idx = t.flat_index(&[0, 1]).unwrap();
    assert!((t.get_f64(idx) - 4.0).abs() < 1e-5);
    let idx = t.flat_index(&[2, 0]).unwrap();
    assert!((t.get_f64(idx) - 3.0).abs() < 1e-5);
    let idx = t.flat_index(&[2, 1]).unwrap();
    assert!((t.get_f64(idx) - 6.0).abs() < 1e-5);
}

#[test]
fn test_transpose_non_2d_error() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let r = ops::transpose_2d(&a);
    assert!(r.is_err());
}

#[test]
fn test_fill() {
    let mut a = NdArray::zeros(&[4], DataType::Float32).unwrap();
    ops::fill(&mut a, 7.0);
    for i in 0..4 {
        assert!((a.get_f64(i) - 7.0).abs() < 1e-5);
    }
}

#[test]
fn test_clone_array() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let b = ops::clone_array(&a);
    assert_eq!(b.shape(), a.shape());
    assert_eq!(b.dtype(), a.dtype());
    for i in 0..a.size() {
        assert!((b.get_f64(i) - a.get_f64(i)).abs() < 1e-5);
    }
}

// ===========================================================================
// Spatial ops (src/compute/spatial.rs)
// ===========================================================================

#[test]
fn test_convolve2d_identity_kernel() {
    let input = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0], 3, 3);
    let kernel = arr_2d(&[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
    let out = spatial::convolve2d(&input, &kernel).unwrap();
    assert_eq!(out.shape(), &[3, 3]);
    for i in 0..9 {
        assert!((out.get_f64(i) - input.get_f64(i)).abs() < 1e-5);
    }
}

#[test]
fn test_matmul_2x2() {
    // [[1,2],[3,4]] × [[5,6],[7,8]] = [[19,22],[43,50]]
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    let b = arr_2d(&[5.0, 6.0, 7.0, 8.0], 2, 2);
    let c = spatial::matmul(&a, &b).unwrap();
    assert_eq!(c.shape(), &[2, 2]);
    let idx00 = c.flat_index(&[0, 0]).unwrap();
    let idx01 = c.flat_index(&[0, 1]).unwrap();
    let idx10 = c.flat_index(&[1, 0]).unwrap();
    let idx11 = c.flat_index(&[1, 1]).unwrap();
    assert!((c.get_f64(idx00) - 19.0).abs() < 1e-5);
    assert!((c.get_f64(idx01) - 22.0).abs() < 1e-5);
    assert!((c.get_f64(idx10) - 43.0).abs() < 1e-5);
    assert!((c.get_f64(idx11) - 50.0).abs() < 1e-5);
}

#[test]
fn test_matmul_dimension_mismatch_error() {
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
    let b = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    let r = spatial::matmul(&a, &b);
    assert!(r.is_err());
}

#[test]
fn test_dot_product() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let b = arr_1d(&[4.0, 5.0, 6.0]);
    let d = spatial::dot(&a, &b).unwrap();
    // 1*4 + 2*5 + 3*6 = 32
    assert!((d - 32.0).abs() < 1e-5);
}

#[test]
fn test_dot_length_mismatch_error() {
    let a = arr_1d(&[1.0, 2.0]);
    let b = arr_1d(&[1.0, 2.0, 3.0]);
    let r = spatial::dot(&a, &b);
    assert!(r.is_err());
}

#[test]
fn test_dilate_single_pixel() {
    // 5x5 grid with single pixel at center
    let mut data = vec![0.0; 25];
    data[12] = 1.0; // (2,2)
    let input = arr_2d(&data, 5, 5);
    let out = spatial::dilate(&input, 1).unwrap();
    // Center and 4-connected neighbors should be 1.0
    assert!((out.get_f64(out.flat_index(&[2, 2]).unwrap()) - 1.0).abs() < 1e-5);
    assert!((out.get_f64(out.flat_index(&[1, 2]).unwrap()) - 1.0).abs() < 1e-5);
    assert!((out.get_f64(out.flat_index(&[3, 2]).unwrap()) - 1.0).abs() < 1e-5);
    assert!((out.get_f64(out.flat_index(&[2, 1]).unwrap()) - 1.0).abs() < 1e-5);
    assert!((out.get_f64(out.flat_index(&[2, 3]).unwrap()) - 1.0).abs() < 1e-5);
    // Corner should remain 0
    assert!((out.get_f64(out.flat_index(&[0, 0]).unwrap()) - 0.0).abs() < 1e-5);
}

#[test]
fn test_erode_all_ones_3x3() {
    // 3x3 all ones → erode with radius 1 → only center survives
    let input = arr_2d(&[1.0; 9], 3, 3);
    let out = spatial::erode(&input, 1).unwrap();
    assert!((out.get_f64(out.flat_index(&[1, 1]).unwrap()) - 1.0).abs() < 1e-5);
    // Edge cells eroded away (diamond extends beyond array at borders)
    assert!((out.get_f64(out.flat_index(&[0, 0]).unwrap()) - 0.0).abs() < 1e-5);
    assert!((out.get_f64(out.flat_index(&[0, 1]).unwrap()) - 0.0).abs() < 1e-5);
}

#[test]
fn test_get_region() {
    // 4x4 array, extract 2x2 sub-region at (1,1)
    let data: Vec<f64> = (1..=16).map(|x| x as f64).collect();
    let a = arr_2d(&data, 4, 4);
    let r = spatial::get_region(&a, 1, 1, 2, 2).unwrap();
    assert_eq!(r.shape(), &[2, 2]);
    // (1,1)=6, (1,2)=7, (2,1)=10, (2,2)=11
    assert!((r.get_f64(r.flat_index(&[0, 0]).unwrap()) - 6.0).abs() < 1e-5);
    assert!((r.get_f64(r.flat_index(&[0, 1]).unwrap()) - 7.0).abs() < 1e-5);
    assert!((r.get_f64(r.flat_index(&[1, 0]).unwrap()) - 10.0).abs() < 1e-5);
    assert!((r.get_f64(r.flat_index(&[1, 1]).unwrap()) - 11.0).abs() < 1e-5);
}

#[test]
fn test_set_region() {
    let mut target = NdArray::zeros(&[4, 4], DataType::Float32).unwrap();
    let src = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    spatial::set_region(&mut target, 1, 1, &src).unwrap();
    assert!((target.get_f64(target.flat_index(&[1, 1]).unwrap()) - 1.0).abs() < 1e-5);
    assert!((target.get_f64(target.flat_index(&[1, 2]).unwrap()) - 2.0).abs() < 1e-5);
    assert!((target.get_f64(target.flat_index(&[2, 1]).unwrap()) - 3.0).abs() < 1e-5);
    assert!((target.get_f64(target.flat_index(&[2, 2]).unwrap()) - 4.0).abs() < 1e-5);
    // Untouched region remains zero
    assert!((target.get_f64(target.flat_index(&[0, 0]).unwrap()) - 0.0).abs() < 1e-5);
}

#[test]
fn test_flood_fill_connected_region() {
    // 3x3: top-left 2x2 block of 1s, rest 0s
    let input = arr_2d(&[1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
    let out = spatial::flood_fill(&input, 0, 0, 5.0).unwrap();
    // Connected 1-region filled with 5
    assert!((out.get_f64(0) - 5.0).abs() < 1e-5);
    assert!((out.get_f64(1) - 5.0).abs() < 1e-5);
    assert!((out.get_f64(3) - 5.0).abs() < 1e-5);
    assert!((out.get_f64(4) - 5.0).abs() < 1e-5);
    // Non-connected 0-region untouched
    assert!((out.get_f64(2) - 0.0).abs() < 1e-5);
    assert!((out.get_f64(8) - 0.0).abs() < 1e-5);
}

#[test]
fn test_flood_fill_same_value_noop() {
    let input = arr_2d(&[3.0; 4], 2, 2);
    let out = spatial::flood_fill(&input, 0, 0, 3.0).unwrap();
    // Fill value equals target → no change
    for i in 0..4 {
        assert!((out.get_f64(i) - 3.0).abs() < 1e-5);
    }
}

// ===========================================================================
// Error handling
// ===========================================================================

#[test]
fn test_add_shape_mismatch_error() {
    let a = arr_1d(&[1.0, 2.0]);
    let b = arr_1d(&[1.0, 2.0, 3.0]);
    let r = ops::add(&a, &b);
    assert!(r.is_err());
}

#[test]
fn test_sum_axis_invalid_axis_error() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let r = ops::sum_axis(&a, 1); // 1D array, axis 1 invalid
    assert!(r.is_err());
}

#[test]
fn test_convolve2d_non_2d_error() {
    let a = arr_1d(&[1.0, 2.0, 3.0]);
    let k = arr_1d(&[1.0]);
    assert!(spatial::convolve2d(&a, &k).is_err());
}

#[test]
fn test_matmul_non_2d_error() {
    let a = arr_1d(&[1.0, 2.0]);
    let b = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    assert!(spatial::matmul(&a, &b).is_err());
}

#[test]
fn test_dot_non_1d_error() {
    let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    let b = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
    assert!(spatial::dot(&a, &b).is_err());
}

#[test]
fn test_flood_fill_out_of_bounds_error() {
    let a = arr_2d(&[1.0; 4], 2, 2);
    assert!(spatial::flood_fill(&a, 5, 0, 1.0).is_err());
}

// ===========================================================================
// Bitwise shift (src/compute/ops.rs)
// ===========================================================================

#[test]
fn test_bitwise_lshift() {
    let a = NdArray::from_slice(&[1.0, 2.0, 4.0], &[3], DataType::Int32).unwrap();
    let r = ops::bitwise_lshift(&a, 2).unwrap();
    assert_eq!(r.get_f64(0) as i32, 4);
    assert_eq!(r.get_f64(1) as i32, 8);
    assert_eq!(r.get_f64(2) as i32, 16);
}

#[test]
fn test_bitwise_rshift() {
    let a = NdArray::from_slice(&[16.0, 8.0, 4.0], &[3], DataType::Int32).unwrap();
    let r = ops::bitwise_rshift(&a, 2).unwrap();
    assert_eq!(r.get_f64(0) as i32, 4);
    assert_eq!(r.get_f64(1) as i32, 2);
    assert_eq!(r.get_f64(2) as i32, 1);
}
