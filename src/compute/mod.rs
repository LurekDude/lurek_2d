//! Dense N-dimensional numerical arrays with NumPy-style operations.
//!
//! Provides `NdArray` for 1D/2D/3D row-major arrays with float32, float64,
//! and int32 element types. Used by the `lurek.gpu` Lua module.

/// N-dimensional array storage with typed element access.
pub mod array;
/// Element-wise and reduction operations on NdArray.
pub mod ops;
/// Spatial operations: convolution, pooling, distance transforms.
pub mod spatial;

pub use array::{DataType, NdArray};
