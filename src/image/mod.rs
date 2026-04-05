//! CPU-side pixel-level image manipulation.
//!
//! Provides `ImageData` for reading and writing individual pixels in RGBA8 format,
//! and `CompressedImageData` for holding DDS/DXT compressed GPU texture data.
//!
//! This module is part of Luna2D's `image` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// RGBA8 pixel buffer with per-pixel read/write access.
pub mod image_data;
pub use image_data::ImageData;

/// DDS/DXT compressed GPU texture data, loaded without CPU decompression.
pub mod compressed;
pub use compressed::{CompressedFormat, CompressedImageData};

/// Color palette lookup table mapping source colors to target colors for shader-based palette swapping.
pub mod palette_lut;
pub use palette_lut::PaletteLUT;
