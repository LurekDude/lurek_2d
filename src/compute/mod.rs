//! - N-dimensional array container, element-wise and reduction operations
//! - FFT, linear algebra, spatial filtering, and statistical analytics
//! - Configurable parallel dispatch threshold for large arrays

/// Exposes analytics helpers for cumulative and statistical operations.
pub mod analytics;
/// Exposes typed n-dimensional array container and constructors.
pub mod array;
/// Exposes fast Fourier transform and inverse transform helpers.
pub mod fft;
/// Exposes linear algebra and transformation helpers.
pub mod linalg;
/// Exposes element-wise and reduction operations over NdArray values.
pub mod ops;
/// Exposes spatial operators such as convolution and morphology.
pub mod spatial;
pub use array::{DataType, NdArray};
pub use fft::{fft, fft_magnitude, ifft};
pub use ops::{get_par_threshold, set_par_threshold};
