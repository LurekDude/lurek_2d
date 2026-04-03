//! CPU-side pixel-level image manipulation.
//!
//! Provides `ImageData` for reading and writing individual pixels in RGBA8 format.
//!
//! This module is part of Luna2D's `image` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// RGBA8 pixel buffer with per-pixel read/write access.
pub mod image_data;
pub use image_data::ImageData;
