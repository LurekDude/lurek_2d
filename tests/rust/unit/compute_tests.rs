//! INTERNAL ONLY: Rust-only tests for compute internals that are not directly asserted through
//! `lurek.compute.*`.
//!
//! Public ndarray/FFT/ops/spatial behaviour is covered by the Lua-first suite
//! in `tests/lua/unit/test_compute_unit.lua`. The remaining Rust coverage here
//! keeps lightweight type/layout invariants.

use lurek2d::compute::analytics;
use lurek2d::compute::array::{DataType, NdArray};
use lurek2d::compute::{linalg, ops, spatial};

// ── array ──────────────────────────────────────────────────────────────────

mod array_tests {
    use super::*;

    #[test]
    fn dtype_byte_size() {
        assert_eq!(DataType::Float32.byte_size(), 4);
        assert_eq!(DataType::Float64.byte_size(), 8);
        assert_eq!(DataType::Int32.byte_size(), 4);
    }

    #[test]
    fn strides() {
        assert_eq!(NdArray::compute_strides(&[5]), vec![1]);
        assert_eq!(NdArray::compute_strides(&[3, 4]), vec![4, 1]);
        assert_eq!(NdArray::compute_strides(&[2, 3, 4]), vec![12, 4, 1]);
        assert_eq!(NdArray::compute_strides(&[2, 3, 4, 5]), vec![60, 20, 5, 1]);
    }

    #[test]
    fn from_slice_shape_mismatch_errors() {
        let err = NdArray::from_slice(&[1.0, 2.0, 3.0], &[2, 2], DataType::Float32)
            .expect_err("expected shape mismatch");
        assert!(
            err.contains("data length") && err.contains("shape element count"),
            "unexpected error: {err}"
        );
    }

    #[test]
    fn range_zero_step_errors() {
        let err = NdArray::range(0.0, 10.0, 0.0, DataType::Float32)
            .expect_err("expected zero-step error");
        assert!(
            err.contains("step must not be zero"),
            "unexpected error: {err}"
        );
    }

    #[test]
    fn supports_four_dimensions() {
        let arr = NdArray::zeros(&[2, 2, 2, 2], DataType::Float32).expect("4D should be valid");
        assert_eq!(arr.ndim(), 4);
        assert_eq!(arr.size(), 16);
        assert_eq!(arr.shape(), &[2, 2, 2, 2]);
        let flat = arr.flat_index(&[1, 1, 1, 1]).expect("valid index");
        assert_eq!(flat, 15);
    }

    #[test]
    fn ndarray_fill_map_iter_work() {
        let mut arr = NdArray::zeros(&[4], DataType::Float32).expect("alloc");
        arr.fill(3.0);
        assert_eq!(arr.to_f64_vec(), vec![3.0, 3.0, 3.0, 3.0]);

        let mapped = arr.map(|x| x * 2.0).expect("map");
        assert_eq!(mapped.to_f64_vec(), vec![6.0, 6.0, 6.0, 6.0]);

        let collected: Vec<f64> = mapped.iter_f64().collect();
        assert_eq!(collected, vec![6.0, 6.0, 6.0, 6.0]);
    }
}

mod ops_tests {
    use super::*;

    #[test]
    fn add_supports_row_broadcast() {
        let a = NdArray::from_slice(
            &[1.0, 2.0, 3.0, 10.0, 20.0, 30.0],
            &[2, 3],
            DataType::Float32,
        )
        .expect("a");
        let b = NdArray::from_slice(&[100.0, 200.0, 300.0], &[3], DataType::Float32).expect("b");

        let out = ops::add(&a, &b).expect("broadcast add");
        assert_eq!(out.shape(), &[2, 3]);
        assert_eq!(
            out.to_f64_vec(),
            vec![101.0, 202.0, 303.0, 110.0, 220.0, 330.0]
        );
    }

    #[test]
    fn sub_supports_reverse_row_broadcast() {
        let a = NdArray::from_slice(&[100.0, 200.0, 300.0], &[3], DataType::Float32).expect("a");
        let b = NdArray::from_slice(
            &[1.0, 2.0, 3.0, 10.0, 20.0, 30.0],
            &[2, 3],
            DataType::Float32,
        )
        .expect("b");

        let out = ops::sub(&a, &b).expect("broadcast sub");
        assert_eq!(
            out.to_f64_vec(),
            vec![99.0, 198.0, 297.0, 90.0, 180.0, 270.0]
        );
    }

    #[test]
    fn inplace_add_supports_row_broadcast() {
        let mut a =
            NdArray::from_slice(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], &[2, 3], DataType::Float32)
                .expect("a");
        let b = NdArray::from_slice(&[10.0, 20.0, 30.0], &[3], DataType::Float32).expect("b");
        ops::add_inplace(&mut a, &b).expect("in-place add");
        assert_eq!(a.to_f64_vec(), vec![11.0, 22.0, 33.0, 14.0, 25.0, 36.0]);
    }

    #[test]
    fn inplace_rejects_unsupported_broadcast_direction() {
        let mut a = NdArray::from_slice(&[1.0, 2.0, 3.0], &[3], DataType::Float32).expect("a");
        let b = NdArray::from_slice(&[1.0, 2.0, 3.0, 4.0], &[2, 2], DataType::Float32).expect("b");
        let err = ops::add_inplace(&mut a, &b).expect_err("expected shape error");
        assert!(err.contains("shape mismatch"), "unexpected error: {err}");
    }
}

mod spatial_tests {
    use super::*;

    #[test]
    fn convolve2d_non_square_kernel() {
        let input =
            NdArray::from_slice(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], &[2, 3], DataType::Float32)
                .expect("input");
        let kernel = NdArray::from_slice(&[1.0, 0.0], &[1, 2], DataType::Float32).expect("kernel");

        let out = spatial::convolve2d(&input, &kernel).expect("convolution");
        assert_eq!(out.shape(), &[2, 3]);
        assert_eq!(out.get_by_indices(&[0, 0]).expect("idx"), 0.0);
        assert_eq!(out.get_by_indices(&[0, 1]).expect("idx"), 1.0);
        assert_eq!(out.get_by_indices(&[1, 2]).expect("idx"), 5.0);
    }
}

mod analytics_tests {
    use super::*;

    #[test]
    fn histogram_ignores_out_of_range_values() {
        let a = NdArray::from_slice(&[-10.0, 0.5, 1.5, 9.0], &[4], DataType::Float32).expect("a");
        let bins = analytics::histogram(&a, 2, Some(0.0), Some(2.0)).expect("histogram");
        assert_eq!(bins.len(), 2);
        assert_eq!(bins[0].2, 1);
        assert_eq!(bins[1].2, 1);
    }
}

mod linalg_tests {
    use super::*;

    #[test]
    fn lu_decompose_singular_matrix_has_zero_u_diagonal() {
        let singular =
            NdArray::from_slice(&[1.0, 2.0, 2.0, 4.0], &[2, 2], DataType::Float64).expect("matrix");
        let decomp = linalg::lu_decompose(&singular).expect("lu should still return factors");
        // For singular matrices, U has a near-zero pivot on the diagonal.
        let u11 = decomp.lu_data[decomp.n + 1];
        assert!(u11.abs() < 1e-12, "expected near-zero pivot, got {u11}");
    }

    #[test]
    fn eigenvalue_power_converges_known_3x3() {
        let a = NdArray::from_slice(
            &[4.0, 1.0, 0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 2.0],
            &[3, 3],
            DataType::Float64,
        )
        .expect("matrix");

        let (lambda, vec) = linalg::eigenvalue_power(&a, 500, 1e-12).expect("eigen");
        assert!((lambda - 4.618_033_988_7).abs() < 1e-6, "lambda={lambda}");
        assert_eq!(vec.len(), 3);
    }
}
