//! Tests for the compute module.

use lurek2d::compute::array::{DataType, NdArray};
use lurek2d::compute::analytics::*;
use lurek2d::compute::fft::*;
use lurek2d::compute::linalg::*;
use lurek2d::compute::ops::*;
use lurek2d::compute::spatial::*;

// ── analytics ──────────────────────────────────────────────────────────────

mod analytics_tests {
    use super::*;

    fn arr(vals: &[f64]) -> NdArray {
        NdArray::from_slice(vals, &[vals.len()], DataType::Float32).unwrap()
    }

    #[test]
    fn cumsum_basic() {
        let a = arr(&[1.0, 2.0, 3.0, 4.0]);
        let c = cumsum(&a).unwrap();
        assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((c.get_f64(3) - 10.0).abs() < 1e-5);
    }

    #[test]
    fn diff_order1_and_2() {
        let a = arr(&[1.0, 4.0, 9.0, 16.0]);
        let d1 = diff(&a, 1).unwrap();
        assert_eq!(d1.size(), 3);
        assert!((d1.get_f64(0) - 3.0).abs() < 1e-5);
        let d2 = diff(&a, 2).unwrap();
        assert_eq!(d2.size(), 2);
        assert!((d2.get_f64(0) - 2.0).abs() < 1e-5);
    }

    #[test]
    fn histogram_basic() {
        let a = arr(&[0.5, 1.5, 2.5, 3.5]);
        let h = histogram(&a, 2, Some(0.0), Some(4.0)).unwrap();
        assert_eq!(h.len(), 2);
        assert_eq!(h[0].2, 2);
        assert_eq!(h[1].2, 2);
    }

    #[test]
    fn percentile_median() {
        let a = arr(&[1.0, 2.0, 3.0, 4.0, 5.0]);
        let p50 = percentile(&a, 50.0).unwrap();
        assert!((p50 - 3.0).abs() < 1e-5);
    }

    #[test]
    fn covariance_identical() {
        let a = arr(&[1.0, 2.0, 3.0]);
        let cov = covariance(&a, &a).unwrap();
        // population variance of [1,2,3] = 2/3
        assert!((cov - 2.0 / 3.0).abs() < 1e-5);
    }

    #[test]
    fn pearson_perfect_positive() {
        let a = arr(&[1.0, 2.0, 3.0]);
        let b = arr(&[2.0, 4.0, 6.0]);
        let r = pearson_corr(&a, &b).unwrap();
        assert!((r - 1.0).abs() < 1e-5);
    }

    #[test]
    fn normalize_range_basic() {
        let a = arr(&[0.0, 5.0, 10.0]);
        let n = normalize_range(&a, 0.0, 1.0).unwrap();
        assert!((n.get_f64(0) - 0.0).abs() < 1e-5);
        assert!((n.get_f64(1) - 0.5).abs() < 1e-5);
        assert!((n.get_f64(2) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn zscore_basic() {
        let a = arr(&[2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]);
        let z = zscore(&a).unwrap();
        // Mean should be ~5, std ~2
        let z_mean: f64 = (0..z.size()).map(|i| z.get_f64(i)).sum::<f64>() / z.size() as f64;
        assert!(z_mean.abs() < 1e-5);
    }

    #[test]
    fn convolve1d_identity_kernel() {
        let signal = arr(&[1.0, 2.0, 3.0]);
        let kernel = arr(&[1.0]);
        let out = convolve1d(&signal, &kernel).unwrap();
        assert_eq!(out.size(), 3);
        assert!((out.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((out.get_f64(2) - 3.0).abs() < 1e-5);
    }

    #[test]
    fn correlate1d_template_match() {
        let signal = arr(&[0.0, 1.0, 2.0, 1.0, 0.0]);
        let template = arr(&[1.0, 2.0, 1.0]);
        let out = correlate1d(&signal, &template).unwrap();
        // At position 1 (window [1,2,1]): 1*1 + 2*2 + 1*1 = 6
        assert_eq!(out.size(), 3);
        assert!((out.get_f64(1) - 6.0).abs() < 1e-5);
    }
}

// ── fft ────────────────────────────────────────────────────────────────────

mod fft_tests {
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

// ── array ──────────────────────────────────────────────────────────────────

mod array_tests {
    use super::*;

    #[test]
    fn dtype_from_str() {
        assert_eq!(DataType::parse("float32").unwrap(), DataType::Float32);
        assert_eq!(DataType::parse("float64").unwrap(), DataType::Float64);
        assert_eq!(DataType::parse("int32").unwrap(), DataType::Int32);
        assert!(DataType::parse("uint8").is_err());
    }

    #[test]
    fn dtype_byte_size() {
        assert_eq!(DataType::Float32.byte_size(), 4);
        assert_eq!(DataType::Float64.byte_size(), 8);
        assert_eq!(DataType::Int32.byte_size(), 4);
    }

    #[test]
    fn zeros() {
        let a = NdArray::zeros(&[3, 4], DataType::Float32).unwrap();
        assert_eq!(a.shape(), &[3, 4]);
        assert_eq!(a.size(), 12);
        assert_eq!(a.ndim(), 2);
        for i in 0..12 {
            assert!((a.get_f64(i) - 0.0).abs() < 1e-10);
        }
    }

    #[test]
    fn ones() {
        let a = NdArray::ones(&[2, 3], DataType::Float64).unwrap();
        for i in 0..6 {
            assert!((a.get_f64(i) - 1.0).abs() < 1e-10);
        }
    }

    #[test]
    fn range() {
        let a = NdArray::range(0.0, 5.0, 1.0, DataType::Float32).unwrap();
        assert_eq!(a.shape(), &[5]);
        for i in 0..5 {
            assert!((a.get_f64(i) - i as f64).abs() < 1e-5);
        }
    }

    #[test]
    fn from_slice() {
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let a = NdArray::from_slice(&vals, &[2, 3], DataType::Float32).unwrap();
        assert_eq!(a.shape(), &[2, 3]);
        assert!((a.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((a.get_f64(5) - 6.0).abs() < 1e-5);
    }

    #[test]
    fn flat_index() {
        let a = NdArray::zeros(&[3, 4], DataType::Float32).unwrap();
        assert_eq!(a.flat_index(&[0, 0]).unwrap(), 0);
        assert_eq!(a.flat_index(&[1, 0]).unwrap(), 4);
        assert_eq!(a.flat_index(&[2, 3]).unwrap(), 11);
        assert!(a.flat_index(&[3, 0]).is_err());
    }

    #[test]
    fn int32_access() {
        let mut a = NdArray::zeros(&[4], DataType::Int32).unwrap();
        a.set_i32(0, 42);
        a.set_i32(1, -7);
        assert_eq!(a.get_i32(0), 42);
        assert_eq!(a.get_i32(1), -7);
        assert!((a.get_f64(0) - 42.0).abs() < 1e-5);
    }

    #[test]
    fn strides() {
        assert_eq!(NdArray::compute_strides(&[5]), vec![1]);
        assert_eq!(NdArray::compute_strides(&[3, 4]), vec![4, 1]);
        assert_eq!(NdArray::compute_strides(&[2, 3, 4]), vec![12, 4, 1]);
    }

    #[test]
    fn shape_validation() {
        assert!(NdArray::zeros(&[], DataType::Float32).is_err());
        assert!(NdArray::zeros(&[1, 2, 3, 4], DataType::Float32).is_err());
        assert!(NdArray::zeros(&[0], DataType::Float32).is_err());
    }

    #[test]
    fn range_errors() {
        assert!(NdArray::range(0.0, 5.0, 0.0, DataType::Float32).is_err());
        assert!(NdArray::range(0.0, 5.0, -1.0, DataType::Float32).is_err());
    }

    #[test]
    fn from_slice_mismatch() {
        let vals = vec![1.0, 2.0, 3.0];
        assert!(NdArray::from_slice(&vals, &[2, 3], DataType::Float32).is_err());
    }
}

// ── linalg ─────────────────────────────────────────────────────────────────

mod linalg_tests {
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

// ── spatial ────────────────────────────────────────────────────────────────

mod spatial_tests {
    use super::*;

    fn arr_2d(vals: &[f64], rows: usize, cols: usize) -> NdArray {
        NdArray::from_slice(vals, &[rows, cols], DataType::Float32).unwrap()
    }

    fn arr_1d(vals: &[f64]) -> NdArray {
        NdArray::from_slice(vals, &[vals.len()], DataType::Float32).unwrap()
    }

    #[test]
    fn convolve2d_identity() {
        // Identity kernel: [[0,0,0],[0,1,0],[0,0,0]]
        let input = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0], 3, 3);
        let kernel = arr_2d(&[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
        let out = convolve2d(&input, &kernel).unwrap();
        for i in 0..9 {
            assert!((out.get_f64(i) - input.get_f64(i)).abs() < 1e-5);
        }
    }

    #[test]
    fn convolve2d_blur() {
        // Simple average kernel
        let input = arr_2d(&[0.0, 0.0, 0.0, 0.0, 9.0, 0.0, 0.0, 0.0, 0.0], 3, 3);
        let kernel = arr_2d(&[1.0 / 9.0; 9], 3, 3);
        let out = convolve2d(&input, &kernel).unwrap();
        // Center should be 9/9 = 1.0
        assert!((out.get_f64(4) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn dilate_basic() {
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
    fn erode_basic() {
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
    fn flood_fill_basic() {
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
    fn get_set_region() {
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
    fn matmul_basic() {
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
    fn matmul_nonsquare() {
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
    fn dot_basic() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let b = arr_1d(&[4.0, 5.0, 6.0]);
        let d = dot(&a, &b).unwrap();
        assert!((d - 32.0).abs() < 1e-5);
    }

    #[test]
    fn dot_length_mismatch() {
        let a = arr_1d(&[1.0, 2.0]);
        let b = arr_1d(&[1.0, 2.0, 3.0]);
        assert!(dot(&a, &b).is_err());
    }

    #[test]
    fn matmul_dim_mismatch() {
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0], 2, 2);
        let b = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 3, 2);
        assert!(matmul(&a, &b).is_err());
    }

    #[test]
    fn flood_fill_out_of_bounds() {
        let input = arr_2d(&[1.0; 4], 2, 2);
        assert!(flood_fill(&input, 5, 0, 1.0).is_err());
    }

    #[test]
    fn get_region_out_of_bounds() {
        let a = arr_2d(&[1.0; 4], 2, 2);
        assert!(get_region(&a, 1, 1, 2, 2).is_err());
    }
}

// ── ops ────────────────────────────────────────────────────────────────────

mod ops_tests {
    use super::*;

    fn arr_1d(vals: &[f64]) -> NdArray {
        NdArray::from_slice(vals, &[vals.len()], DataType::Float32).unwrap()
    }

    fn arr_2d(vals: &[f64], rows: usize, cols: usize) -> NdArray {
        NdArray::from_slice(vals, &[rows, cols], DataType::Float32).unwrap()
    }

    #[test]
    fn add_basic() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let b = arr_1d(&[4.0, 5.0, 6.0]);
        let c = add(&a, &b).unwrap();
        assert!((c.get_f64(0) - 5.0).abs() < 1e-5);
        assert!((c.get_f64(2) - 9.0).abs() < 1e-5);
    }

    #[test]
    fn add_scalar_basic() {
        let a = arr_1d(&[1.0, 2.0, 3.0]);
        let c = add_scalar(&a, 10.0).unwrap();
        assert!((c.get_f64(0) - 11.0).abs() < 1e-5);
    }

    #[test]
    fn sub_basic() {
        let a = arr_1d(&[10.0, 20.0]);
        let b = arr_1d(&[3.0, 7.0]);
        let c = sub(&a, &b).unwrap();
        assert!((c.get_f64(0) - 7.0).abs() < 1e-5);
        assert!((c.get_f64(1) - 13.0).abs() < 1e-5);
    }

    #[test]
    fn mul_div_basic() {
        let a = arr_1d(&[2.0, 3.0, 4.0]);
        let b = arr_1d(&[5.0, 6.0, 7.0]);
        let m = mul(&a, &b).unwrap();
        assert!((m.get_f64(0) - 10.0).abs() < 1e-5);
        let d = div(&a, &b).unwrap();
        assert!((d.get_f64(0) - 0.4).abs() < 1e-5);
    }

    #[test]
    fn pow_sqrt_abs_neg() {
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
    fn clamp_basic() {
        let a = arr_1d(&[1.0, 5.0, 10.0, -3.0]);
        let c = clamp(&a, 0.0, 7.0).unwrap();
        assert!((c.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((c.get_f64(1) - 5.0).abs() < 1e-5);
        assert!((c.get_f64(2) - 7.0).abs() < 1e-5);
        assert!((c.get_f64(3) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn comparisons() {
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
    fn threshold_where() {
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
    fn counting() {
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
    fn reductions_global() {
        let a = arr_1d(&[1.0, 2.0, 3.0, 4.0]);
        assert!((sum(&a) - 10.0).abs() < 1e-5);
        assert!((mean(&a) - 2.5).abs() < 1e-5);
        assert!((min_val(&a) - 1.0).abs() < 1e-5);
        assert!((max_val(&a) - 4.0).abs() < 1e-5);
    }

    #[test]
    fn sum_axis_basic() {
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
    fn mean_axis_basic() {
        let a = arr_2d(&[2.0, 4.0, 6.0, 8.0], 2, 2);
        let m = mean_axis(&a, 0).unwrap();
        assert!((m.get_f64(0) - 4.0).abs() < 1e-5);
        assert!((m.get_f64(1) - 6.0).abs() < 1e-5);
    }

    #[test]
    fn reshape_basic() {
        let a = arr_1d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
        let b = reshape(&a, &[2, 3]).unwrap();
        assert_eq!(b.shape(), &[2, 3]);
        assert!((b.get_f64(0) - 1.0).abs() < 1e-5);
        assert!((b.get_f64(5) - 6.0).abs() < 1e-5);
        assert!(reshape(&a, &[3, 3]).is_err());
    }

    #[test]
    fn transpose_2d_basic() {
        let a = arr_2d(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3);
        let t = transpose_2d(&a).unwrap();
        assert_eq!(t.shape(), &[3, 2]);
        // Original [0,1]=2.0 → transposed [1,0]=2.0
        assert!((t.get_f64(t.flat_index(&[1, 0]).unwrap()) - 2.0).abs() < 1e-5);
        // Original [1,2]=6.0 → transposed [2,1]=6.0
        assert!((t.get_f64(t.flat_index(&[2, 1]).unwrap()) - 6.0).abs() < 1e-5);
    }

    #[test]
    fn fill_basic() {
        let mut a = arr_1d(&[1.0, 2.0, 3.0]);
        fill(&mut a, 42.0);
        for i in 0..3 {
            assert!((a.get_f64(i) - 42.0).abs() < 1e-5);
        }
    }

    #[test]
    fn bitwise_ops() {
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
    fn bitwise_dtype_check() {
        let a = arr_1d(&[1.0, 2.0]);
        let b = arr_1d(&[3.0, 4.0]);
        assert!(bitwise_and(&a, &b).is_err());
    }

    #[test]
    fn shape_mismatch_error() {
        let a = arr_1d(&[1.0, 2.0]);
        let b = arr_1d(&[1.0, 2.0, 3.0]);
        assert!(add(&a, &b).is_err());
    }
}

// ── Lua-driven compute extensions ────────────────────────────────────────────

mod lua_ops_tests {
    use lurek2d::compute::array::{DataType, NdArray};

    #[test]
    fn ndarray_to_f64_vec_roundtrip() {
        let arr = NdArray::from_slice(&[1.0, 2.0, 3.0], &[3], DataType::Float64)
            .expect("from_slice");
        let v = arr.to_f64_vec();
        assert_eq!(v, vec![1.0, 2.0, 3.0]);
    }

    #[test]
    fn ndarray_get_set_f64() {
        let mut arr = NdArray::zeros(&[4], DataType::Float64).expect("zeros");
        arr.set_f64(2, 99.0);
        assert_eq!(arr.get_f64(2), 99.0);
    }
}
