//! Texture implementation for the `graphics` subsystem.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for texture-related operations and data management.
//! Key types exported from this module: `Texture`.
//! Primary functions: `load()`, `from_rgba()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
use crate::runtime::error::{EngineError, EngineResult};
use crate::runtime::log_messages::TX01_TEX_DECODED;
use crate::runtime::resource_keys::TextureKey;
use crate::render::renderer::TextureData;
use crate::log_msg;
use slotmap::SlotMap;
use std::path::Path;

/// A loaded image asset referenced by its index into the renderer's texture list.
///
/// `Texture` is a lightweight handle; the actual pixel data lives in `TextureData`
/// inside `Renderer::textures` (or `SharedState::textures`).
///
/// # Fields
/// - `id` — Index into the renderer's `TextureData` list.
/// - `width` — Image width in pixels.
/// - `height` — Image height in pixels.
pub struct Texture {
    pub key: TextureKey,
    pub width: u32,
    pub height: u32,
}

impl Texture {
    /// Loads an image from `path`, premultiplies alpha, and appends it to `textures`.
    ///
    /// Supports PNG, JPEG, BMP, and any format handled by the `image` crate.
    /// Alpha is premultiplied because the GPU renderer expects premultiplied color space.
    ///
    /// # Parameters
    /// - `path` — Filesystem path to the image file.
    /// - `textures` — Mutable texture list; the decoded `TextureData` is pushed here.
    ///
    /// # Returns
    /// `Ok(Texture)` — Handle with the new id, width, and height.
    /// `Err(EngineError)` — Resource not found or image decode error.
    pub fn load<P: AsRef<Path>>(
        path: P,
        textures: &mut SlotMap<TextureKey, TextureData>,
    ) -> EngineResult<Self> {
        let img = ::image::open(&path).map_err(|e| {
            let path_str = path.as_ref().display().to_string();
            if path_str.contains("No such file") || matches!(e, ::image::ImageError::IoError(_)) {
                EngineError::ResourceNotFound(format!("{}: {}", path_str, e))
            } else {
                EngineError::RenderError(format!("Failed to decode image '{}': {}", path_str, e))
            }
        })?;
        let rgba = img.to_rgba8();
        let (width, height) = rgba.dimensions();

        // GPU renderer expects premultiplied alpha RGBA
        let mut pixels = rgba.into_raw();
        // Premultiply alpha
        for chunk in pixels.chunks_exact_mut(4) {
            let a = chunk[3] as f32 / 255.0;
            chunk[0] = (chunk[0] as f32 * a) as u8;
            chunk[1] = (chunk[1] as f32 * a) as u8;
            chunk[2] = (chunk[2] as f32 * a) as u8;
        }

        let key = textures.insert(TextureData {
            pixels,
            width,
            height,
        });

        log_msg!(debug, TX01_TEX_DECODED, "{}x{}", width, height);
        Ok(Texture { key, width, height })
    }

    /// Creates a texture from raw RGBA pixel data (not premultiplied).
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `pixels` — `Vec<u8>`.
    /// - `textures` — `&mut SlotMap<TextureKey, TextureData>`.
    ///
    /// # Returns
    /// `EngineResult<Self>`.
    ///
    /// The data is premultiplied in-place before insertion.
    pub fn from_rgba(
        width: u32,
        height: u32,
        mut pixels: Vec<u8>,
        textures: &mut SlotMap<TextureKey, TextureData>,
    ) -> EngineResult<Self> {
        let expected = (width * height * 4) as usize;
        if pixels.len() != expected {
            return Err(EngineError::RenderError(format!(
                "Expected {} bytes for {}x{} RGBA, got {}",
                expected,
                width,
                height,
                pixels.len()
            )));
        }
        for chunk in pixels.chunks_exact_mut(4) {
            let a = chunk[3] as f32 / 255.0;
            chunk[0] = (chunk[0] as f32 * a) as u8;
            chunk[1] = (chunk[1] as f32 * a) as u8;
            chunk[2] = (chunk[2] as f32 * a) as u8;
        }
        let key = textures.insert(TextureData {
            pixels,
            width,
            height,
        });
        Ok(Texture { key, width, height })
    }
}
