//! Stress tests for the compute module — large array operations.

use luna2d::compute::ops;
use luna2d::compute::*;

#[test]
fn stress_large_1d_array_creation() {
    let a = NdArray::new(&[100_000], DataType::Float64).unwrap();
    assert_eq!(a.shape(), &[100_000]);
    assert_eq!(a.size(), 100_000);
}

#[test]
fn stress_large_2d_array_creation() {
    let a = NdArray::new(&[1000, 1000], DataType::Float32).unwrap();
    assert_eq!(a.size(), 1_000_000);
    assert_eq!(a.ndim(), 2);
}

#[test]
fn stress_ones_large_sum() {
    let a = NdArray::ones(&[50_000], DataType::Float64).unwrap();
    let sum: f64 = (0..a.size()).map(|i| a.get_f64(i)).sum();
    assert!((sum - 50_000.0).abs() < 1e-3, "sum of 50K ones = 50000");
}

#[test]
fn stress_range_large() {
    let a = NdArray::range(0.0, 10_000.0, 1.0, DataType::Float64).unwrap();
    assert_eq!(a.size(), 10_000);
    assert!((a.get_f64(0) - 0.0).abs() < 1e-5);
    assert!((a.get_f64(9999) - 9999.0).abs() < 1e-5);
}

#[test]
fn stress_elementwise_add() {
    let a = NdArray::ones(&[100_000], DataType::Float64).unwrap();
    let b = NdArray::ones(&[100_000], DataType::Float64).unwrap();
    let c = ops::add(&a, &b).unwrap();
    assert_eq!(c.size(), 100_000);
    // Spot-check
    assert!((c.get_f64(0) - 2.0).abs() < 1e-5);
    assert!((c.get_f64(99_999) - 2.0).abs() < 1e-5);
}

#[test]
fn stress_elementwise_mul() {
    let mut a = NdArray::new(&[10_000], DataType::Float64).unwrap();
    let mut b = NdArray::new(&[10_000], DataType::Float64).unwrap();
    for i in 0..10_000 {
        a.set_f64(i, i as f64);
        b.set_f64(i, 2.0);
    }
    let c = ops::mul(&a, &b).unwrap();
    assert!((c.get_f64(5000) - 10_000.0).abs() < 1e-5);
}

#[test]
fn stress_set_get_roundtrip() {
    let mut arr = NdArray::new(&[1000, 1000], DataType::Float32).unwrap();
    // Set diagonal
    for i in 0..1000 {
        let flat = arr.flat_index(&[i, i]).unwrap();
        arr.set_f64(flat, (i + 1) as f64);
    }
    // Read back diagonal
    for i in 0..1000 {
        let flat = arr.flat_index(&[i, i]).unwrap();
        let val = arr.get_f64(flat);
        assert!(
            (val - (i + 1) as f64).abs() < 1e-3,
            "diagonal [{i}] = {} (expected {})",
            val,
            i + 1
        );
    }
}
