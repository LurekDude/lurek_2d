//! Compute owns CPU numerical arrays and transforms used by lurek.compute.
//! It defines NdArray storage, element-wise ops, reductions, linear algebra,
//! spatial filters, and FFT helpers over row-major buffers.
//! This module does not schedule GPU kernels or async jobs.
//! Lua bindings live in src/lua_api/compute_api.rs and call into these files.

/// Export statistical reductions and 1D signal transforms.
pub mod analytics;
/// Export row-major typed array storage and indexing helpers.
pub mod array;
/// Export radix-2 FFT, inverse FFT, and magnitude helpers.
pub mod fft;
/// Export vector and matrix helpers, solvers, and decompositions.
pub mod linalg;
/// Export element-wise arithmetic, comparisons, and reductions.
pub mod ops;
/// Export 2D convolution, morphology, region copy, and matmul helpers.
pub mod spatial;

pub use array::{DataType, NdArray};
pub use fft::{fft, fft_magnitude, ifft};
pub use ops::{get_par_threshold, set_par_threshold};
