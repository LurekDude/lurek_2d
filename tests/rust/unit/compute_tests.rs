//! INTERNAL ONLY: Rust-only tests for compute internals that are not directly asserted through
//! `lurek.compute.*`.
//!
//! Public ndarray/FFT/ops/spatial behaviour is covered by the Lua-first suite
//! in `tests/lua/unit/test_compute_unit.lua`. The remaining Rust coverage here
//! keeps lightweight type/layout invariants.

use lurek2d::compute::array::{DataType, NdArray};

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
    }
}
