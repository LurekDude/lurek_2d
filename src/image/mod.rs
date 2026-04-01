//! CPU-side pixel-level image manipulation.
//!
//! Provides `ImageData` for reading and writing individual pixels in RGBA8 format.

/// RGBA8 pixel buffer with per-pixel read/write access.
pub mod image_data;
pub use image_data::ImageData;
