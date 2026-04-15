//! Dense N-dimensional numerical arrays with NumPy-style operations.
//!
//! Provides [`array::NdArray`] for 1D/2D/3D row-major arrays with `f32`, `f64`,
//! and `i32` element types. Used by the `lurek.gpu` Lua module. Despite the GPU namespace,
//! all computation is CPU-bound; the name reflects the intended use for heavy
//! numerical workloads (signal processing, matrix math, convolution).
//!
//! ## Subsystem inventory
//! - [`array`] — [`NdArray`]: storage, shape, slice, reshape, element access
//! - [`ops`] — element-wise arithmetic and axis reductions (sum, mean, min, max)
//! - [`spatial`] — 2D convolution, max/average pooling, distance transforms
//! - [`analytics`] — autocorrelation, moving average, normalization, histogram
//! - [`linalg`] — dot/matmul, Gaussian solver, LU decomposition, eigenvalue (power iteration)
//! - [`fft`] — iterative Cooley-Tukey radix-2 FFT and inverse FFT
//!
//! Lua bridge: `src/lua_api/compute_api.rs` as `lurek.gpu.*`.


/// N-dimensional array storage with typed element access.
pub mod array;
/// Element-wise and reduction operations on NdArray.
pub mod ops;
/// Spatial operations: convolution, pooling, distance transforms.
pub mod spatial;
/// Statistical analytics, signal processing, and normalisation.
pub mod analytics;
/// Linear algebra: solvers, kernels, transforms, Sobel, LU decomp, eigenvalue.
pub mod linalg;
/// Fast Fourier Transform and inverse FFT (iterative Cooley-Tukey radix-2).
pub mod fft;

pub use array::{DataType, NdArray};
pub use fft::{fft, fft_magnitude, ifft};
